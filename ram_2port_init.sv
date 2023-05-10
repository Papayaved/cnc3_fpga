`ifndef _ram_2port_init_
`define _ram_2port_init_

`include "header.sv"

module ram_2port #(parameter
	DATA_WIDTH = 16,
	ADDR_WIDTH = 4
)(
	input clk_a, write_a,
	input [ADDR_WIDTH-1:0] addr_a,
	input [DATA_WIDTH-1:0] data_a,
	output reg [DATA_WIDTH-1:0] q_a,
	
	input clk_b,
	input [ADDR_WIDTH-1:0] addr_b,
	output reg [DATA_WIDTH-1:0] q_b
);
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH];
			
	always_ff @(posedge clk_a)
		if (write_a)
			ram[addr_a] <= data_a;
		else
			q_a <= ram[addr_a];
	
	always_ff @(posedge clk_b)
		q_b <= ram[addr_b];
		
endmodule :ram_2port

module ram_2port_init #(
	parameter DATA_WIDTH = 16,
	parameter ADDR_WIDTH = 4,
	parameter bit [DATA_WIDTH-1:0] INIT_VALUE = '0
)(
	input set,
	input clk_a, write_a,
	input [ADDR_WIDTH-1:0] addr_a,
	input [DATA_WIDTH-1:0] data_a,
	output [DATA_WIDTH-1:0] q_a,
	output ready,
	
	input clk_b,
	input [ADDR_WIDTH-1:0] addr_b,
	output [DATA_WIDTH-1:0] q_b
);
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH];
	reg [ADDR_WIDTH-1:0] addr = '0;
	reg [DATA_WIDTH-1:0] data = INIT_VALUE;
	reg init = 1'b1, write = 1'b1;
	
	always_ff @(posedge clk_a)
		if (set)
			init <= 1'b1;
		else if (addr == '1)
			init <= 1'b0;
	
	always_ff @(posedge clk_a)
		if (set)
			addr <= '0;
		else if (init)
			addr <= addr + 1'b1;
		else
			addr <= addr_a;
			
	always_ff @(posedge clk_a) begin
		data	<= (set || init) ? INIT_VALUE : data_a;
		write	<= (set || init) ? 1'b1 : write_a;
	end
			
	assign ready = !(set || init);
	
	ram_2port #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) ram_inst(
		.clk_a, .write_a(write), .addr_a(addr), .data_a(data), .q_a,
		.clk_b, .addr_b, .q_b
	);
	
endmodule :ram_2port_init

`endif
