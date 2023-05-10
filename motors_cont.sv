`ifndef _motor_cont_
`define _motor_cont_

module motors_cont(
	input aclr, clk,
	input [7:0][31:0] N, T,
	input [7:0] dir_req,
	input steps_req,
	input green,
	output [7:0] step, dir,
	output read_ack, ready
);
	
	assign ready = state == IDLE;
	always_ff @(posedge clk) read_ack <= step_clk;
	

	step_clk = steps_req && green && &start_rdy;
	
	genvar i;
	
	generate for (i = 0; i < 8; i++)
		begin
			motor_cont(
				.aclr, .clk,
				.N(N[i]), .T(T[i]),
				.dir_req(dir_req[i]),
				.steps_req(steps_req[i]),
				.green,
				.step(step[i]), .dir(dir[i]),
				.ready
			);
		end
	endgenerate
	
	
	step_gen step_inst(
		input aclr, clk,
		input start_clk, stop_clk, brake_clk,
		input dir_req,
		input [31:0] T,
		output run,
		output loaded,
		output reg pls, dir,
		
		output stop_req, start_rdy,
		output pls_clk
	);

endmodule : motors_cont

module motor_cont(
	input aclr, clk,
	input [31:0] N, T,
	input dir_req,
	input steps_req,
	input green,
	output step, dir,
	output read_ack, ready
);
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
		
		else
			case (state)
				IDLE:
					if (step_req && N != 0)
						start_clk <= 1'b1;
						read_ack <= 1'b1;
						N_cnt <= N;
						state <= STEP;
				STEP:
					start_clk <= 1'b0;
					
					if (pls_clk)
						
			endcase
	
	
	step_gen step_inst(
		input aclr, clk,
		input start_clk, stop_clk, brake_clk,
		input dir_req,
		input [31:0] T,
		output run,
		output loaded,
		output reg pls, dir,
		
		output stop_req, start_rdy,
		output pls_clk
	);

endmodule : motor_cont

`endif
