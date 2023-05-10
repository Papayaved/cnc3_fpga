`ifndef _start_stop_timer_
`define _start_stop_timer_

module start_stop_timer #(
	parameter WIDTH = 16,
	PRE_WIDTH = 16
)(
	input clk, aclr, sclr,
	input sig,
	input [PRE_WIDTH-1:0] scale,
	input [WIDTH-1:0] length,
	output enabled
);
	reg [1:0] sig_reg;
	wire sig_clk;	

	reg [PRE_WIDTH-1:0] timer;
	wire clk_ena;
	
	reg [WIDTH-1:0] cnt;
	
	always_ff @(posedge clk, posedge aclr)
		sig_reg <= (aclr) ? 1'b0 : (sclr) ? 1'b0 : {sig_reg[0], sig};
	
	assign sig_clk = sig_reg == 2'b01;
	
	reg pause_reg;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			pause_reg <= 1'b0;
		else if (sclr || !sig_reg[0])
			pause_reg <= 1'b0;
		else if (sig_clk)
			pause_reg <= 1'b1;
		else if (clk_ena && cnt == length)
			pause_reg <= 1'b0;
			
	assign pause = sig && (pause_reg || (sig && !sig_reg[0]) || sig_clk);

	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			timer <= '0;
		else if (sclr || !pause || clk_ena)
			timer <= '0;
		else
			timer <= timer + 1'b1;
	
	assign clk_ena = timer == scale;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			cnt <= '0;
		else if (sclr || !pause)
			cnt <= '0;
		else if (clk_ena)
			cnt <= cnt + 1'b1;
	
endmodule :start_stop_timer

`endif
