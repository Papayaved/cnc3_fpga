`ifndef _keyboard_
`define _keyboard_

`include "sipo.sv"
`include "lpf_cap.sv"

module keyboard #(parameter
	NUM = 16,
	CLK_DIV = 18
)(
	input clk, aclr, sclr,
	
	input sdi,
	output sclk, load_n,

	input [NUM-1:0] key_level,
	output [NUM-1:0] key, ready, timeout
);

	wire [NUM-1:0] data;
	wire data_valid;

	sipo #(.WIDTH(NUM), .CLK_DIV(CLK_DIV)) sipo_inst(
		.clk, .aclr, .sync(1'b0),
		.sclk, .load_n, .sdi,
		.data, .valid(data_valid)
	);
	
	genvar i;
	
	generate for (i = 0; i < NUM; i++)
		begin :gen
			lpf_cap_full #(8) lpf_inst(.clock(clk), .aclr, .sclr, .clock_ena(data_valid), .in(data[i] ^ key_level[i]), .out(key[i]), .ready(ready[i]), .timeout(timeout[i]));
		end
	endgenerate
	
endmodule :keyboard

`endif
