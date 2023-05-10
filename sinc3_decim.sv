/*
sinc3 filter with decimator
*/

`ifndef _sinc3_decim_
`define _sinc3_decim_

//`include "round.sv"

module sinc3_decim #(parameter
	OSR_WIDTH = 8, // 2**OSR_WIDTH - over sampling ratio	
	RES_WIDTH = 1 + 3 * OSR_WIDTH,
	WIDTH = RES_WIDTH + 1,
	bit signed [WIDTH-1:0] MAX = {{2{1'b0}}, {(WIDTH-2){1'b1}}},
	bit signed [WIDTH-1:0] MIN = ~MAX
)(
	input aclr,
	// Sigma-delta ADC
	input clock, sdi,
	input [OSR_WIDTH-1:0] osr, // OSR minus 1
	output signed [RES_WIDTH-1:0] data,
	output reg valid
);

	wire signed [WIDTH-1:0] d_in;
	
	assign d_in = (sdi) ? WIDTH'('sh1): WIDTH'('sh0 -'sh1);
	
	// Integrators
	reg signed [WIDTH-1:0] i1, i2, i3;	
	// Combs
	reg signed [WIDTH-1:0] c0, c0_reg, c1, c1_reg, c2, c2_reg, c3;
	
	reg [OSR_WIDTH-1:0] osr_reg = '0, cnt = '0;
	wire hit;
	reg hit_reg = 1'b0;  // clock enable signal for comb working at output rate
	
	// Integrators
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			{i1, i2, i3} <= '0;
		else
			begin				
				i1 <= i1 + d_in;
				i2 <= i2 + i1;
				i3 <= i3 + i2;
			end
	
	assign hit = cnt == osr_reg;
	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			osr_reg <= '0;
		else if (hit)
			osr_reg <= osr;	
	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			cnt <= '0;
		else if (hit)
			cnt <= '0;
		else
			cnt <= cnt + 1'b1;
	
	always_ff @(posedge clock, posedge aclr)
		hit_reg <= (aclr) ? 1'b0 : hit;		

	// Decimation	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			c0 <= '0;
		else if (hit)
			c0 <= i3;
	
	// Comb section working at output rate
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			{c1, c2, c3, c0_reg, c1_reg, c2_reg} <= '0;
		else
			if (hit_reg)
				begin
					c0_reg <= c0;
					
					c1 <= c0 - c0_reg;
					c1_reg <= c1;
					
					c2 <= c1 - c1_reg;
					c2_reg <= c2;
					
					c3 <= c2 - c2_reg;
				end
	
	assign data = (c3 > MAX) ? MAX[RES_WIDTH-1:0] : c3[RES_WIDTH-1:0];
	
	always_ff @(posedge clock, posedge aclr)
		valid <= (aclr) ? 1'b0 : hit_reg;		
	
endmodule :sinc3_decim

`endif
