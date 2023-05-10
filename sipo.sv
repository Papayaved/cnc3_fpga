`ifndef _sipo_
`define _sipo_

`include "header.sv"
`include "clk_div.sv"

module sipo_reg #(parameter
	WIDTH = 16,
	CLK_DIV = 10
)(
	input clk, aclr, sclr,
	
	output load_n, sclk,
	input sdi,	

	output reg [WIDTH-1:0] data
);

	wire [WIDTH-1:0] l_data;
	wire valid;

	sipo #(.WIDTH(WIDTH), .CLK_DIV(CLK_DIV)) sipo_inst(
		.clk, .aclr,
		.sync(sclr),
		.load_n, .sclk, .sdi,
		.data(l_data), .valid
	);
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			data <= '0;
		else if (sclr)
			data <= '0;
		else if (valid)
			data <= l_data;
	
endmodule :sipo_reg

// 74HC165
module sipo #(parameter
	WIDTH = 16,
	CLK_DIV = 10
)(
	input clk, aclr,	
	input sync,
	
	output reg load_n, sclk,
	input sdi,
	
	output reg [WIDTH-1:0] data,
	output reg valid
);
	localparam CNT_WIDTH = `GET_WIDTH(WIDTH);
	localparam bit [CNT_WIDTH-1:0] CNT_MAX = CNT_WIDTH'(WIDTH - 1'b1);
	
	wire sclk_ena;
	
	clk_div #(.CLK_DIV(CLK_DIV/2)) clk_div_inst(.clk, .aclr, .sclr(sync), .clk_ena(sclk_ena));
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			sclk <= 1'b0;
		else if (sync)
			sclk <= 1'b0;
		else if (sclk_ena)
			sclk <= !sclk;
			
//	wire sclk_rise = sclk_ena && !sclk;
	wire sclk_fall = sclk_ena && sclk;	
	
	reg [CNT_WIDTH-1:0] bit_cnt = '0;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			bit_cnt <= '0;
		else if (sync)
			bit_cnt <= '0;
		else if (sclk_fall)
			if (bit_cnt == CNT_MAX)
				bit_cnt <= '0;
			else
				bit_cnt <= bit_cnt + 1'b1;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			data <= '0;
		else if (sync)
			data <= '0;
		else if (sclk_fall)
			data <= {data[WIDTH-2:0], sdi};
			
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			load_n <= 1'b1;
		else if (sync)
			load_n <= 1'b1;
		else if (sclk_fall)
			load_n <= bit_cnt != '0;
	
	reg ena = 1'b0;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			ena <= 1'b0;
		else if (sync)
			ena <= 1'b0;
		else if (sclk_fall && bit_cnt == '0)
			ena <= 1'b1;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			valid <= 1'b0;
		else
			valid <= sync || !ena ? 1'b0 : sclk_fall && bit_cnt == '0;
	
endmodule :sipo

`endif
