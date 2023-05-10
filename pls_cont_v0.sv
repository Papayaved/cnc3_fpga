`ifndef _pls_cont_
`define _pls_cont_

`include "pls_gen.sv"

module pls_cont(
	input clk, aclr, abort,
	input oi, // all ready
	input [31:0] N, T,
	input empty,
	output reg rdack, ready,
	
	input green,
	
	output run, oi_req, pls_clk, // oi_req - ready
	
	output pls, dir,
	
	input brake_clk
);

	reg start_clk = 1'b0, stop_clk = 1'b0;
	wire loaded, stop_req, start_rdy;
	reg pls_reg = 1'b0;

	typedef enum {IDLE, WAIT[2], OI, RUN, LOAD, ERR} State;
	State state;
	
	reg [31:0] N_cnt = '0, T_reg = '1;
	reg dir_reg = 1'b0;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			begin
				start_clk <= 1'b0;
				stop_clk <= 1'b0;
				rdack <= 1'b0;
				N_cnt <= '0;
				T_reg <= '1;
				dir_reg <= 1'b0;
				state <= IDLE;
			end
		else if (abort)
			begin
				start_clk <= 1'b0;
				stop_clk <= 1'b0;
				rdack <= 1'b0;
				N_cnt <= '0;
				T_reg <= '1;
				dir_reg <= 1'b0;
				state <= ERR;
			end
		else if (brake_clk)
			begin
				start_clk <= 1'b0;
				stop_clk <= 1'b0;
				rdack <= 1'b0;
				N_cnt <= '0;
				T_reg <= '1;
				dir_reg <= 1'b0;
				state <= IDLE;
			end
		else
			case (state)
				IDLE:
					begin
						stop_clk <= 1'b0;
						
						if (start_rdy && !empty)
							begin
								N_cnt <= N;
								T_reg <= T;
								dir_reg <= dir;
								rdack <= 1'b1;
								state <= WAIT0;
							end
					end
				WAIT0:
					begin
						rdack <= 1'b0;
						state <= OI;
					end
				OI:
					if (oi)
						if (N_cnt != 0)
							begin
								start_clk <= 1'b1;
								state <= LOAD;
							end
						else // empty data
							state <= IDLE;
				LOAD:
					begin
						start_clk <= 1'b0;
						
						if (loaded) begin
							N_cnt <= N_cnt - 1'b1;
							state <= RUN;
						end
					end
				RUN:
					if (N_cnt == '0)
						begin
							stop_clk <= 1'b1;
							state <= IDLE;
						end
					else if (N_cnt != '0 && pls_reg) // waiting to store cur_data at pls_clk
						begin
							state <= WAIT1;
						end
					else if (empty && stop_req) begin // not enough time for read from fifo
						stop_clk <= 1'b1;
						state <= IDLE;
					end
				WAIT1:
					begin
						state <= LOAD;
					end
				ERR:;
			endcase

	assign oi_req = state == OI && start_rdy;

	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			pls_reg <= 1'b0;
		else if (loaded)
			pls_reg <= 1'b0;
		else if (pls_clk)
			pls_reg <= 1'b1;

	pls_gen pls_gen_inst(
		.clk, .aclr,
		.green,
		.start_clk, .stop_clk(stop_clk || abort), .brake_clk,
		.dir_req(dir_reg), .T(T_reg),
		.run, .loaded,
		.pls, .dir,
		.stop_req, .start_rdy, .pls_clk
	);

	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			ready <= 1'b1;
		else if (brake_clk)
			ready <= 1'b1;
		else if (oi_req && oi && N_cnt != '0)
			ready <= 1'b0;
		else if ((N_cnt == '0 && pls_clk) || (empty && stop_req))
			ready <= 1'b1;

endmodule :pls_cont

`endif
