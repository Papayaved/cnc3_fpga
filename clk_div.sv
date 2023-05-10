`ifndef _clk_div_
`define _clk_div_

`include "header.sv"

module clk_div #(parameter CLK_DIV = 5)(
	input clk, aclr, sclr,
	output reg clk_ena
);
	localparam CNT_WIDTH = `GET_WIDTH(CLK_DIV);
	localparam bit [CNT_WIDTH - 1:0] CNT_MAX = CNT_WIDTH'(CLK_DIV - 1);
	
	reg [CNT_WIDTH-1:0] cnt = CNT_MAX;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			cnt <= CNT_MAX;
		else if (sclr)
			cnt <= CNT_MAX;
		else if (cnt == '0)
			cnt <= CNT_MAX;
		else
			cnt <= cnt - 1'b1;
	
	always_ff @(posedge clk, posedge aclr)
		clk_ena <= aclr ? 1'b0 : (sclr ? 1'b0 : cnt == 'h0);

endmodule :clk_div

`endif
