`ifndef _step_dir_
`define _step_dir_

`include "header.sv"

module step_dir #(
	parameter WIDTH = 5
)(
	input clk, aclr, sclr,
	input step, dir,
	output reg [WIDTH-1:0] phase,
	output reg changed
);

	localparam CNT_MAX = 2 * WIDTH - 1;
	localparam CNT_WIDTH = CNT_MAX < 2**$clog2(CNT_MAX) ? $clog2(CNT_MAX) : $clog2(CNT_MAX) + 1;

	reg [CNT_WIDTH-1:0] cnt = '0;
	
	reg step_reg = 1'b0;
	
	always_ff @(posedge clk, posedge aclr)
		step_reg <= (aclr) ? 1'b0 : step;
	
	wire step_clk = step && !step_reg;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			cnt <= '0;
		else if (sclr)
			cnt <= '0;
		else if (step_clk)
			if (dir == 1'b0)
				if (cnt == CNT_MAX[CNT_WIDTH-1:0])
					cnt <= '0;
				else
					cnt <= cnt + 1'b1;
			else
				if (cnt == 'd0)
					cnt <= CNT_MAX[CNT_WIDTH-1:0];
				else
					cnt <= cnt - 1'b1;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			phase <= '0;
		else if (sclr)
			phase <= '0;
		else
			phase <= WIDTH'( 1 << (cnt >> 1) | ( cnt == CNT_MAX ? 1 : (cnt & 1 ? 1 << ((cnt >> 1) + 1) : 0) ) );
	
	reg sclr_reg = 1'b1;
	
	always_ff @(posedge clk, posedge aclr)
		sclr_reg <= aclr ? 1'b1 : sclr;
	
	always_ff @(posedge clk, posedge aclr)
		changed <= aclr ? 1'b0 : (!sclr && step_clk) || (sclr ^ sclr_reg);

endmodule :step_dir

`endif
