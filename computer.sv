`ifndef _computer_
`define _computer_
`include "header.sv"
`include "calc_sched.sv"

module computer #(parameter
	TS_WIDTH = `TS_WIDTH,
	N_WIDTH = `N_WIDTH
)(
	input clk, clk2x, aclr, sclr,
	input braking, brake_clk,
	input MotorParam[7:0] m_par,
	input load,
	
	output [7:0] ready, stopped,
	
	input [7:0] pls_full,
	output [7:0] pls_sop, pls_eop,
	output PlsData [7:0] pls_data,
	output [7:0] pls_wrreq,
	
	input PlsContext [7:0] cur_data,
	output error
);

	reg areset = 1'b1;
	always_ff @(posedge clk, posedge aclr)
		areset <= (aclr) ? 1'b1 : sclr;
	
	MotorParam[7:0] par_reg;
	wire [7:0] calc_req;
	
	wire [7:0][TS_WIDTH-1:0] T;
	wire [7:0][31:0] V1;
	wire [7:0] isV1;
	wire [7:0] valid;
	
	genvar i;
	generate for (i = 0; i < 8; i++)
		begin :gen
			T_comp T_inst(
				.clk, .areset, .brake_clk,
				.par(m_par[i]),
				.load, .ready(ready[i]), .stopped(stopped[i]),
				.full(pls_full[i]),
				.sop(pls_sop[i]), .eop(pls_eop[i]), .data(pls_data[i]), .wrreq(pls_wrreq[i]),
				
				.par_reg(par_reg[i]),
				.calc_req(calc_req[i]),
				.T(T[i]), .V1(V1[i]), .isV1(isV1[i]), .valid(valid[i]),
				
				.cur_data(cur_data[i])
			);
		end
	endgenerate
	
	calc_sched sched_inst(
		.clk, .clk2x, .aclr(areset), .braking, .brake_clk,
		.par(par_reg),
		.calc_req,
		.T, .V1, .isV1, .valid, .error
	);
	
endmodule :computer
	
module T_comp #(parameter
	TS_WIDTH = `TS_WIDTH,
	N_WIDTH = `N_WIDTH,
	T_MIN = `T_MIN/2,
	T_MAX = `T_MAX
)(
	input clk, areset,
	input brake_clk,
	input MotorParam par,
	input load,
	
	output ready,
	output reg stopped,
	
	input full,
	output sop,
	output reg eop,
	output PlsData data,
	output reg wrreq,
	
	// Calculator
	output MotorParam par_reg,
	output reg calc_req,
	
	input [TS_WIDTH-1:0] T,
	input [31:0] V1,
	input isV1,
	input valid,
	
	input PlsContext cur_data
);
	
	typedef enum {IDLE, LOAD[2], WAIT, RES, WRITE, CALC[2], END, BR_LOAD} State;
	State state;
	
	reg rdy = 1'b0, sop_reg = 1'b0, braking = 1'b0;
	reg [TS_WIDTH-1:0] ts_cnt = '0;
	reg [N_WIDTH-1:0] N_cnt = '0;
	reg dir = 1'b0;
	reg [31:0] V0 = '0;
	
	always_ff @(posedge clk, posedge areset)
		if (areset)
			Reset();
		else if (brake_clk)
			begin			
				rdy <= 1'b0;
				calc_req <= 1'b0;
				wrreq <= 1'b0;
				state <= BR_LOAD;
			end
		else
			case (state)
				IDLE:
					if (rdy && load && !full)
						begin
							rdy <= 1'b0;
							sop_reg <= 1'b1;
							state <= LOAD0;
						end
					else
						rdy <= 1'b1;
				LOAD0:
					begin
						ts_cnt <= par.ts;
						N_cnt <= par.N;
						V0 <= par.V0;
						data.isV = 1'b0;
						par_reg.mode <= par.mode;
						par_reg.m2A <= par.m2A;
						par_reg.R <= par.R;
						par_reg.sinH1s <= par.sinH1s;					
						dir <= par.dir;
						
						state <= LOAD1;
					end
				LOAD1:
						if (par.mask)
							begin
								if (N_cnt == '0 || ts_cnt == '0 || par_reg.m2A == '0)
									begin
										eop <= 1'b1;
										data.mask <= 1'b0;
										wrreq <= 1'b1;
										stopped <= braking;
										state <= END;
									end
								else if (braking)
									begin										
										calc_req <= 1'b1;
										data.mask <= 1'b1;
										state <= WAIT;
									end
								else if (N_cnt == 1'b1)
									begin
										data.T <= (ts_cnt < T_MIN) ? T_MIN : ts_cnt;
										data.isV <= ts_cnt > T_MAX;
										N_cnt <= '0;
										eop <= 1'b1;	
										data.mask <= 1'b1;
										wrreq <= 1'b1;
										state <= END;
									end
								else
									begin
										calc_req <= 1'b1;
										data.mask <= 1'b1;
										state <= WAIT;
									end
							end
						else
							begin
								eop <= 1'b1;
								data.mask <= 1'b0;
								wrreq <= 1'b1;
								stopped <= braking;
								state <= END;
							end
				WAIT:
					if (!valid) state <= RES;
				RES:
					if (valid)
						begin
							calc_req <= 1'b0;
							data.T <= T;
							V0 <= V1;
							data.isV = isV1;
							N_cnt <= (N_cnt == '0) ? '0 : N_cnt - 1'b1;
							ts_cnt <= (T >= ts_cnt) ? '0 : ts_cnt - T;
							state <= WRITE;
						end
				WRITE:
					if (!full) begin
						wrreq <= 1'b1;
						
						if (braking)
							if (!isV1 || N_cnt == '0) // stopped or finished plss
								begin
									data.T <= (isV1 == 1'b0) ? T_MAX : data.T;
									data.isV <= isV1;
									eop <= 1'b1;
									data.mask <= isV1; // don't form pls
									stopped <= !isV1;
									state <= END;
								end
							else
								state <= CALC0;
						else
							state <= CALC0;
					end
				CALC0: // pause for set full signal
					begin
						sop_reg <= 1'b0;
						wrreq <= 1'b0;
						state <= CALC1;
					end
				CALC1:
					if (braking)
						begin
							calc_req <= 1'b1;
							state <= WAIT;
						end				
					else if (N_cnt == 'h1)
						if (!full)
							begin
								data.T <= (ts_cnt < T_MIN) ? T_MIN : ts_cnt;
								data.isV <= ts_cnt > T_MAX;
								N_cnt <= '0;
								eop <= 1'b1;
								wrreq <= 1'b1;
								state <= END;
							end
						else;
					else
						begin
							calc_req <= 1'b1;
							state <= WAIT;
						end
				BR_LOAD:
					begin
						rdy <= 1'b0;
						sop_reg <= 1'b1;
						
						if (cur_data.id != data.id) // stop_req interrapt last step or was oi but no pls - reload
							state <= LOAD0;
						else
							begin
								N_cnt <= cur_data.N;
								V0 <= cur_data.V;
								data.isV = cur_data.isV;							
								
								if (cur_data.N == '0 || cur_data.isV == '0)
									begin
										eop <= 1'b1;
										data.mask <= 1'b0;
										wrreq <= 1'b1;
										stopped <= cur_data.isV == '0;
										state <= END;
									end
								else
									begin
										eop <= 1'b0;							
										data.mask <= 1'b1;
										calc_req <= 1'b1;
										state <= WAIT;
									end
							end
					end
				default: // END
					Reset();
			endcase
	
	assign sop = sop_reg && wrreq;
	
	assign ready = !brake_clk && rdy && !load && !full;
	
	always_ff @(posedge clk, posedge areset)
		if (areset)
			braking <= 1'b0;
		else if (brake_clk)
			braking <= 1'b1;
		else if (stopped)
			braking <= 1'b0;
	
	always_ff @(posedge clk, posedge areset)
		if (areset)
			data.id <= 1'b0;
		else if (load)
			data.id <= !data.id;
	
	always_comb begin
		data.N = N_cnt;
		data.dir = dir;
		data.V = V0;
	end
	
	always_comb begin
		par_reg.mask = 1'b1;
		par_reg.ts = ts_cnt;
		par_reg.N = N_cnt;
		par_reg.dir = dir;
		par_reg.V0 = V0;
	end
	
	task Reset();
		rdy <= 1'b0;
		calc_req <= 1'b0;
		sop_reg <= 1'b0;
		eop <= 1'b0;
		wrreq <= 1'b0;
		stopped <= 1'b0;
		
		data.mask <= 1'b0;
		data.T <= '0;
		data.isV <= 1'b0;
		
		ts_cnt <= '0;
		N_cnt <= '0;
		V0 <= '0;
		
		par_reg.m2A <= '0;
		par_reg.R <= '0;
		par_reg.sinH1s <= '0;
		par_reg.mode <= 1'b0;
		
		state <= IDLE;
	endtask

endmodule :T_comp

`endif
