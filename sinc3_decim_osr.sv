`ifndef _sinc3_decim_osr_
`define _sinc3_decim_osr_

module sinc3_decim_osr #(parameter
	OSR_WIDTH = 7, // 2**OSR_WIDTH - over sampling ratio	
	RES_WIDTH = 3 * OSR_WIDTH,
	WIDTH = RES_WIDTH + 1,
	
	bit [WIDTH-1:0] MAX = {1'b0, {(WIDTH-1){1'b1}}}
)(
	input aclr, sclr,
	// Sigma-delta ADC
	input clock, sdi,
	input [OSR_WIDTH-1:0] osr, // OSR minus 1
	output signed [RES_WIDTH-1:0] data,
	output reg valid
);
	// Integrators
	reg [3:1][WIDTH-1:0] i;
	// Combs
	reg [3:0][WIDTH-1:0] c;
	reg [2:0][WIDTH-1:0] c_reg;
	
	reg [OSR_WIDTH-1:0] osr_reg = '0, cnt = '0;
	wire hit;
	reg hit_reg = 1'b0;  // clock enable signal for comb working at output rate
	
	// Integrators
	always_ff @(posedge clock)
		if (aclr)
			i <= '0;
		else if (sclr)
			i <= '0;
		else
			begin				
				i[1] <= i[1] + sdi;
				i[2] <= i[2] + i[1];
				i[3] <= i[3] + i[2];
			end
	
	assign hit = cnt == osr_reg;
	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			osr_reg <= '0;
		else if (sclr)
			osr_reg <= '0;
		else if (hit)
			osr_reg <= osr;	
	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			cnt <= '0;
		else if (sclr || hit)
			cnt <= '0;
		else
			cnt <= cnt + 1'b1;
	
	always_ff @(posedge clock, posedge aclr)
		hit_reg <= aclr ? 1'b0 : (sclr ? 1'b0 : hit);		

	// Decimation	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			c[0] <= '0;
		else if (sclr)
			c[0] <= '0;
		else if (hit)
			c[0] <= i[3];
	
	// Comb section working at output rate
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			{c[3:1], c_reg} <= '0;
		else if (sclr)
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
	
endmodule :sinc3_decim_osr

`endif
