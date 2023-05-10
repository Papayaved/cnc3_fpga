/*
sinc3 filter with decimator version 2
*/

`ifndef _u_sinc3_decim_
`define _u_sinc3_decim_

//`include "round.sv"

module u_sinc3_decim #(parameter
	OSR_WIDTH = 7, // 2**OSR_WIDTH - over sampling ratio	
	RES_WIDTH = 3 * OSR_WIDTH,
	WIDTH = RES_WIDTH + 1,
	bit [OSR_WIDTH-1:0] OSR = '1, // OSR minus 1
	bit [WIDTH-1:0] MAX = {1'b0, {(WIDTH-1){1'b1}}}
)(
	input sclr,
	// Sigma-delta ADC
	input clock, sdi,
	output [RES_WIDTH-1:0] data,
	output reg valid
);
	// Integrators
	reg [3:1][WIDTH-1:0] i;
	// Combs
	reg [3:0][WIDTH-1:0] c;
	reg [2:0][WIDTH-1:0] c_reg;
	
	reg [OSR_WIDTH-1:0] cnt = '0;
	wire hit;
	reg hit_reg = 1'b0;  // clock enable signal for comb working at output rate
	
	// Integrators
	always_ff @(posedge clock)
		if (sclr)
			i <= '0;
		else
			begin				
				i[1] <= i[1] + sdi;
				i[2] <= i[2] + i[1];
				i[3] <= i[3] + i[2];
			end
	
	assign hit = cnt == OSR;
	
	always_ff @(posedge clock)
		if (sclr)
			cnt <= '0;
		else if (hit)
			cnt <= '0;
		else
			cnt <= cnt + 1'b1;
	
	always_ff @(posedge clock)
		hit_reg <= (sclr) ? 1'b0 : hit;		

	// Decimation	
	always_ff @(posedge clock)
		if (sclr)
			c[0] <= '0;
		else if (hit)
			c[0] <= i[3];
	
	// Comb section working at output rate
	always_ff @(posedge clock)
		if (sclr)
			{c[3:1], c_reg} <= '0;
		else
			if (hit_reg)
				begin
					c_reg[0] <= c[0];
					
					c[1] <= c[0] - c_reg[0];
					c_reg[1] <= c[1];
					
					c[2] <= c[1] - c_reg[1];
					c_reg[2] <= c[2];
					
					c[3] <= c[2] - c_reg[2];
				end
	
	assign data = (c[3] > MAX) ? MAX[RES_WIDTH-1:0] : c[3][RES_WIDTH-1:0];
	
	always_ff @(posedge clock)
		valid <= (sclr) ? 1'b0 : hit_reg;		
	
endmodule :u_sinc3_decim

`endif
