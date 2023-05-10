`ifndef _pause_gen_
`include "header.sv"

//module pause_gen #(parameter
//	SYS_CLOCK = 72_000_000
//)(
//	input clk, aclr,
//	output reg led
//);
//	localparam MAX = SYS_CLOCK / 2 - 1;
//	localparam WIDTH = `GET_WIDTH(MAX);
//	reg [WIDTH-1:0] cnt;
//	wire max;	
//	
//	always_ff @(posedge clk, posedge aclr)
//		if (aclr)
//			cnt <= '0;
//		else if (max)
//			cnt <= '0;
//		else
//			cnt <= cnt + 1'b1;
//			
//	assign max = cnt >= MAX;
//	
//	always_ff @(posedge clk, posedge aclr)
//		if (aclr)
//			led <= 1'b1;
//		else if (max)
//			led <= !led;
//	
//endmodule :pause_gen

`endif // _pause_gen_
