`ifndef _cic_decim_osr_
`define _cic_decim_osr_

module cic_decim_osr #(parameter
	DATA_WIDTH = 10,
	OSR_WIDTH = 7, // 2**OSR_WIDTH - over sampling ratio	
	RES_WIDTH = DATA_WIDTH,
	WIDTH = 3 * OSR_WIDTH + DATA_WIDTH
)(
	input aclr, sclr,
	// Sigma-delta ADC
	input clock, clock_ena,
	input [DATA_WIDTH-1:0] data,
	input [OSR_WIDTH-1:0] osr, // OSR minus 1
	output [RES_WIDTH-1:0] res,
	output reg valid
);
//	localparam bit [WIDTH-1:0] MAX = {1'b0, {(WIDTH-1){1'b1}}};
	
	// Integrators
	reg [3:1][WIDTH-1:0] i;
	// Combs
	reg [3:0][WIDTH-1:0] c;
	reg [2:0][WIDTH-1:0] c_reg;
	
	reg [OSR_WIDTH-1:0] osr_reg = '0, cnt = '0;
	wire hit;
	reg hit_reg = 1'b0;  // clock enable signal for comb working at output rate
	
	// Integrators
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			i <= '0;
		else if (sclr)
			i <= '0;
		else if (clock_ena)
			begin				
				i[1] <= i[1] + data;
				i[2] <= i[2] + i[1];
				i[3] <= i[3] + i[2];
			end
	
	assign hit = cnt == osr_reg;
	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			osr_reg <= '0;
		else if (sclr)
			osr_reg <= '0;
		else if (clock_ena && hit)
			osr_reg <= osr;	
	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			cnt <= '0;
		else if (sclr)
			cnt <= '0;
		else if (clock_ena)
			if (hit)
				cnt <= '0;
			else
				cnt <= cnt + 1'b1;
	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			hit_reg <= 1'b0;
		else if (sclr)
			hit_reg <= 1'b0;
		else if (clock_ena)
			hit_reg <= hit;

	// Decimation	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			c[0] <= '0;
		else if (sclr)
			c[0] <= '0;
		else if (clock_ena && hit)
			c[0] <= i[3];
	
	// Comb section working at output rate
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			{c[3:1], c_reg} <= '0;
		else if (sclr)
			{c[3:1], c_reg} <= '0;
		else if (clock_ena && hit_reg)
			begin
				c_reg[0] <= c[0];
				
				c[1] <= c[0] - c_reg[0];
				c_reg[1] <= c[1];
				
				c[2] <= c[1] - c_reg[1];
				c_reg[2] <= c[2];
				
				c[3] <= c[2] - c_reg[2];
			end
	
	assign res = c[3][(WIDTH-1):(WIDTH-RES_WIDTH)];
	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			valid <= 1'b0;
		else if (sclr)
			valid <= 1'b0;
		else
			valid <= hit_reg && clock_ena;
	
endmodule :cic_decim_osr

`endif
