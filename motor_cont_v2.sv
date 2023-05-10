`ifndef _motor_cont_
`define _motor_cont_

`include "header.sv"
`include "parser.sv"
`include "pls_cont.sv"

module motor_cont #(parameter
	TS_WIDTH = `TS_WIDTH,
	N_WIDTH = `N_WIDTH,
	T_WIDTH = `T_WIDTH,
	GPO_WIDTH = `GPO_WIDTH
)(
	input clk, aclr,
	input [31:0] cmd_q,
	input cmd_empty,
	output cmd_rdreq,
	
	// Current parameters
	output TaskParam par,	
	
	input start_req, stop_req,
	output reg run, braking,
	
	input [GPO_WIDTH-1:0] gpo_value,
	input gpo_we,
	
	output [8:0] error,
	
	output [7:0] dir, pls,
	output reg [GPO_WIDTH-1:0] gpo,
	
	output reg cmd_cnt_ena
);

	reg oi = 1'b0;

	typedef enum {IDLE, PARSE, PAUSE, OI, BR_OI, STEP, END, ERR} State;
	State state = IDLE;

	wire abort = error != '0;

	wire [7:0] pls_full, pls_fin;
	wire [7:0] pls_sop, pls_eop;
	PlsData [7:0] pls_data;
	PlsContext [7:0] cur_data;
	wire [7:0] pls_wrreq;

	wire gpo_mask = par.mode[8];
	wire [7:0] oi_req;

	reg step_req = 1'b0;
	wire step_ack;
	reg calc_fin = 1'b0;
	wire task_empty;
	wire [7:0] stopped; reg [7:0] stopped_reg = '0;
	wire [7:0] pls_run;
	reg brake_clk = 1'b0;
	reg [TS_WIDTH-1:0] ts_cnt = '0;

	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			begin
				step_req <= 1'b0;
				oi <= 1'b0;
				cmd_cnt_ena <= 1'b0;
				state <= IDLE;
			end
		else if (abort)
			begin
				step_req <= 1'b0;
				oi <= 1'b0;
				cmd_cnt_ena <= 1'b0;
				state <= ERR;
			end
		else if (brake_clk)
			begin
				step_req <= 1'b0;
				oi <= 1'b0;
				cmd_cnt_ena <= 1'b0;
				state <= BR_OI;
			end
		else
			case (state)
				IDLE:
					if (!cmd_empty && start_req && !stop_req)
						state <= PARSE;
				PARSE: // run
					if (stop_req)
						state <= IDLE;
					else if (!task_empty)
						begin
							step_req <= 1'b1;
							state <= PAUSE;
						end
				PAUSE:
					state <= OI;
				OI, BR_OI:
					if (oi_req == '1 && ts_cnt == '0)
						begin
							step_req <= 1'b0;
							oi <= 1'b1;
							cmd_cnt_ena <= state == OI; // don't count BR_OI
							state <= STEP;
						end
				STEP:
					begin
						oi <= 1'b0;
						cmd_cnt_ena <= 1'b0;
						
						if (calc_fin && pls_fin == '1 && ts_cnt <= 'd100) // calculated and read // todo increase 100
							if (task_empty)
								state <= END;
							else if (braking && stopped_reg == '1)
								state <= END;
							else
								begin
									step_req <= 1'b1;
									state <= OI;
								end
					end
				END:
					if (pls_run == '0)
						state <= IDLE;
				ERR:;
			endcase

	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			ts_cnt <= '0;
		else if (braking)
			ts_cnt <= '0;
		else if (oi)
			ts_cnt <= (par.ts == '0) ? '0 : par.ts - 1'b1;
		else if (ts_cnt != 0)
			ts_cnt <= ts_cnt - 1'b1;

	wire state_run = state != IDLE;
	always_ff @(posedge clk, posedge aclr)
		run <= (aclr) ? 1'b0 : state_run;

	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			braking <= 1'b0;
		else if (!state_run)
			braking <= 1'b0;
		else if (stop_req)
			braking <= 1'b1;

	always_ff @(posedge clk, posedge aclr)
		brake_clk <= (aclr) ? 1'b0 : state_run && stop_req && !braking;

	parser parse(
		.clk, .aclr, .abort, .enable(run),
		.cmd_q, .cmd_empty(cmd_empty), .cmd_rdreq,
		
		.par,
		
		.step_req, .braking, .brake_clk,
		.task_empty,
		.step_ack,
		.stopped,
		
		.pls_full, .pls_sop, .pls_eop, .pls_data, .pls_wrreq,
		.cur_data,
		
		.error
	);

	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			calc_fin <= 1'b0;
		else if (step_req || brake_clk || !run)
			calc_fin <= 1'b0;
		else if (step_ack)
			calc_fin <= 1'b1;

	genvar i;
	generate for (i = 0; i < 8; i++)
		begin :gen
			pls_cont pls_cont_inst(
				.clk, .aclr, .abort,
				.oi,
				.sop_in(pls_sop[i]), .eop_in(pls_eop[i]), .data_in(pls_data[i]), .wrreq(pls_wrreq[i]),
				.full(pls_full[i]), .ready(pls_fin[i]),
				.run(pls_run[i]), .oi_req(oi_req[i]), .pls_clk(),
				.pls(pls[i]), .dir(dir[i]),
				.brake_clk, .cur_data(cur_data[i])
			);
		
			always_ff @(posedge clk, posedge aclr)
				if (aclr)
					stopped_reg[i] <= 1'b0;
				else if (!braking || brake_clk || !run)
					stopped_reg[i] <= 1'b0;
				else if (stopped[i])
					stopped_reg[i] <= 1'b1;
		end
	endgenerate

	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			gpo <= '0;
		else if (oi && gpo_mask)
			gpo <= par.gpo[GPO_WIDTH-1:0];
		else if (gpo_we)
			gpo <= gpo_value;

endmodule :motor_cont

`endif
