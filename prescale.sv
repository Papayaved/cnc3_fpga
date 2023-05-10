`ifndef _prescale_
`define _prescale_

module prescale_oi(
	input clk, aclr, sclr,
	input [15:0] T_scale,
	input oi,
	output clk_ena
);
	reg [15:0] T_reg, cnt;
	reg oi_reg;
	
	always_ff @(posedge clk, posedge aclr)
		oi_reg <= aclr ? 1'b0 : oi;
		
	wire oi_clk = oi && !oi_reg;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			cnt <= '0;
		else if (sclr)
			cnt <= '0;
		else if (oi_clk)
			cnt <= T_scale;
		else if (cnt == '0)	
			cnt <= T_reg;
		else if (cnt != '0)
			cnt <= cnt - 1'b1;
	
	assign clk_ena = cnt == '0;
	
	always @(posedge clk, posedge aclr)
		if (aclr)
			T_reg <= '0;
		else if (sclr)
			T_reg <= '0;
		else if (oi_clk)
			T_reg <= T_scale;

endmodule :prescale_oi

module prescale(
	input clk, aclr, sclr,
	input [15:0] T_scale,
	input enable,
	output reg clk_ena
);
	reg [15:0] cnt;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			cnt <= '0;
		else if (sclr || !enable)
			cnt <= '0;
		else if (cnt == '0)	
			cnt <= T_scale;
		else
			cnt <= cnt - 1'b1;
	
	always_ff @(posedge clk, posedge aclr)
		clk_ena <= aclr ? 1'b0 : !sclr && enable && cnt == 'h1;
	
endmodule :prescale

`endif // _prescale
