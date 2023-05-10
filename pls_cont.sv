`ifndef _pls_cont_
`define _pls_cont_
`include "pls_gen.sv"
`include "pause_gen.sv"

module pls_cont(
	input clk, clk_ena, aclr, abort,
	input oi, // all ready
	input signed [31:0] N,
	input [31:0] T,
	input empty,
	
	input permit,
	
	output run, oi_req, // oi_req - ready
	
	output pls, dir,
	output cnt_end
);

	reg start_clk = 1'b0, stop_clk = 1'b0, pause_req = 1'b0;
	wire loaded, stop_req, start_rdy;

	enum {IDLE, OI, LOAD, PAUSE, RUN} state = IDLE;
	
	reg [30:0] N_cnt = '0;
	reg [31:0] T_reg = '1;
	reg dir_reg = 1'b0;
	
	task reset();
		start_clk <= 1'b0;
		stop_clk <= 1'b0;
		pause_req <= 1'b0;
		N_cnt <= '0;
		T_reg <= '1;
		dir_reg <= 1'b0;
		state <= IDLE;
	endtask
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			reset();
		else if (abort)
			reset();
		else
			case (state)
				IDLE:
					begin
						stop_clk <= 1'b0;
						
						if (start_rdy && !empty)
							begin
								N_cnt <= N[31] ? 31'(32'sh0 - N) : N[30:0];
								T_reg <= T;
								dir_reg <= N[31];
								state <= OI;
							end
					end
				OI:
					if (oi)
						if (N_cnt == '0)
							if (T_reg == '0) // M command
								state <= IDLE;
							else // pause
								begin
									start_clk <= 1'b1;
									pause_req <= 1'b1;
									state <= PAUSE;
								end
						else
							begin
								start_clk <= 1'b1;
								state <= LOAD;
							end
				LOAD:
					begin
						start_clk <= 1'b0;
						
						if (loaded) begin
							N_cnt <= N_cnt - 1'b1;
							state <= RUN;
						end
					end
				PAUSE:
					begin
						start_clk <= 1'b0;
						pause_req <= 1'b0;						
						
						if (loaded)
							state <= RUN;
					end
				RUN:
					if (stop_req)
						if (N_cnt == '0)
							begin
								stop_clk <= 1'b1;
								state <= IDLE;
							end
						else
							state <= LOAD;
				default:
					reset();
			endcase

	assign oi_req = state == OI && start_rdy;

	pls_gen pls_inst(
		.clk, .clk_ena, .aclr, .abort,
		.permit,
		.start_clk, .stop_clk,
		.dir_req(dir_reg), .T(T_reg),
		.pause_req,
		.run, .loaded,
		.pls, .dir,
		.stop_req, .start_rdy,
		.cnt_end
	);

endmodule :pls_cont

`endif
