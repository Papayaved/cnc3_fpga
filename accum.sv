`ifndef _accum_
`define _accum_

`include "delay_line.sv"

module accum #(parameter
	DATA_WIDTH = 10,
	ACC_POW = 7,	
	RES_WIDTH = DATA_WIDTH + ACC_POW // or DATA_WIDTH
)(
	input aclr, clock, sclr,
	input [DATA_WIDTH-1:0] data_in,
	input valid_in,
	output [RES_WIDTH-1:0] data_out,
	output valid_out
);

	localparam ACC_WIDTH = DATA_WIDTH + ACC_POW;

	wire [DATA_WIDTH-1:0] data_dly;
	reg [ACC_WIDTH - 1:0] acc;
	reg [1:0] valid_reg = '0;
	
	always_ff @(posedge clock, posedge aclr)
		valid_reg <= aclr ? 2'b00 : ( sclr ? 2'b00 : {valid_reg[0], valid_in} );
	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			acc <= '0;
		else if (sclr)
			acc <= '0;
		else if (valid_reg[0])
			acc <= acc + (data_in - data_dly);
	
	assign data_out = acc[ACC_WIDTH - 1:ACC_WIDTH - RES_WIDTH];
	
	assign valid_out = valid_reg[1];
	
	delay_line #(.DATA_WIDTH(DATA_WIDTH), .DELAY(2**ACC_POW), .DELAY_WIDTH(ACC_POW)) delay_inst(
		.aclr, .clock, .sclr, .clock_ena(valid_in),
		.data(data_in),
		.q(data_dly)
	);
	
endmodule :accum

module accum_var #(parameter
	DATA_WIDTH = 10,
	ACC_POW = 7,	
	RES_WIDTH = DATA_WIDTH + ACC_POW // or DATA_WIDTH
)(
	input aclr, clock, sclr,
	input [ACC_POW-1:0] delay,
	input [DATA_WIDTH-1:0] data_in,
	input valid_in,
	output [RES_WIDTH-1:0] data_out,
	output valid_out
);

	localparam ACC_WIDTH = DATA_WIDTH + ACC_POW;

	wire [DATA_WIDTH-1:0] data_dly;
	reg [ACC_WIDTH - 1:0] acc;
	reg [1:0] valid_reg = '0;
	
	always_ff @(posedge clock, posedge aclr)
		valid_reg <= aclr ? 2'b00 : ( sclr ? 2'b00 : {valid_reg[0], valid_in} );
	
	always_ff @(posedge clock, posedge aclr)
		if (aclr)
			acc <= '0;
		else if (sclr)
			acc <= '0;
		else if (valid_reg[0])
			acc <= acc + (data_in - data_dly);
	
	assign data_out = acc[ACC_WIDTH - 1:ACC_WIDTH - RES_WIDTH];
	
	assign valid_out = valid_reg[1];
	
	delay_line_var #(.DATA_WIDTH(DATA_WIDTH), .DELAY_WIDTH(ACC_POW)) delay_inst(
		.aclr, .clock, .sclr,
		.delay,
		.clock_ena(valid_in),
		.data(data_in),
		.q(data_dly)
	);
	
endmodule :accum_var

`endif
