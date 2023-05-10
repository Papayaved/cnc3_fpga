`ifndef _SN74HC165_
`define _SN74HC165_

module SN74HC165(
	input LDn,
	input [7:0] data,
	input clk, clk_inh,
	input ser,
	output q
);
	
	reg [7:0] data_reg = '0;
	
	always_ff @(posedge clk, negedge LDn)
		if (!LDn)
			data_reg <= data;
		else if (!clk_inh)
			data_reg <= {data_reg[6:0], ser};
			
	assign q = data_reg[7];

endmodule :SN74HC165

module SN74HC165_2x(
	input [15:0] data,
	input load_n, sclk,
	output sdi
);

	wire [1:0] q;
	
	SN74HC165 inst0(
		.LDn(load_n),
		.data(data[7:0]),
		.clk(sclk), .clk_inh(1'b0),
		.ser(1'b0),
		.q(q[0])
	);
	
	SN74HC165 inst1(
		.LDn(load_n),
		.data(data[15:8]),
		.clk(sclk), .clk_inh(1'b0),
		.ser(q[0]),
		.q(q[1])
	);
	
	assign sdi = q[1];
	
endmodule :SN74HC165_2x

module SN74HC165_4x(
	input [31:0] data,
	input load_n, sclk,
	output sdi
);

	wire [3:0] q;
	
	SN74HC165 inst0(
		.LDn(load_n),
		.data(data[7:0]),
		.clk(sclk), .clk_inh(1'b0),
		.ser(1'b0),
		.q(q[0])
	);
	
	SN74HC165 inst1(
		.LDn(load_n),
		.data(data[15:8]),
		.clk(sclk), .clk_inh(1'b0),
		.ser(q[0]),
		.q(q[1])
	);
	
	SN74HC165 inst2(
		.LDn(load_n),
		.data(data[23:16]),
		.clk(sclk), .clk_inh(1'b0),
		.ser(q[1]),
		.q(q[2])
	);
	
	SN74HC165 inst3(
		.LDn(load_n),
		.data(data[31:24]),
		.clk(sclk), .clk_inh(1'b0),
		.ser(q[2]),
		.q(q[3])
	);
	
	assign sdi = q[3];
	
endmodule :SN74HC165_4x

`endif
