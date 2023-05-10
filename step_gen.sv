`ifndef _step_gen_
`define _step_gen_

`include "header.sv"

module step_gen #(
	input aclr, clk,
	input sclr,
	input start_clk,
	input dir_req,
	input [31:0] T,
	output run,
	output loaded,
	output reg pls, dir,
	
	output start_rdy,
	output pls_clk
);



endmodule :step_gen

`endif
