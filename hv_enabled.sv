`ifndef _hv_enabled_
`define _hv_enabled_

module hv_enabled #(parameter
	PRESCALE_WIDTH = 16,
	WIDTH = 16	
)(
	input clk, aclr, sclr,
	input hv, permit,
	input [PRESCALE_WIDTH-1:0] prescale,
	input [WIDTH-1:0] length,
	output enabled
);
	reg [1:0] hv_reg;
	wire hv_clk;

	reg [PRESCALE_WIDTH-1:0] timer;
	wire clk_ena;
	
	reg [WIDTH-1:0] cnt;
	wire cnt_end = clk_ena && cnt == length;
	
	always_ff @(posedge clk, posedge aclr)
		hv_reg <= (aclr) ? 1'b0 : (sclr) ? 1'b0 : {hv_reg[0], hv};
	
	assign hv_clk = hv_reg == 2'b01;
	
	reg dly_reg;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			dly_reg <= 1'b0;
		else if (sclr || !hv_reg[0] || permit)
			dly_reg <= 1'b0;
		else if (hv_clk)
			dly_reg <= 1'b1;
		else if (cnt_end)
			dly_reg <= 1'b0;
			
	assign enabled = hv && !(dly_reg || hv_clk || (hv && !hv_reg[0]));

	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			timer <= '0;
		else if (sclr || hv_clk || clk_ena)
			timer <= '0;
		else
			timer <= timer + 1'b1;
	
	assign clk_ena = timer == prescale;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			cnt <= '0;
		else if (sclr || hv_clk || cnt_end)
			cnt <= '0;
		else if (clk_ena)
			cnt <= cnt + 1'b1;
	
endmodule :hv_enabled

`endif
