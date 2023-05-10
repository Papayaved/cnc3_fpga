timeunit 1ns;
timeprecision 1ps;

`include "SN74HC165.sv"

module sipo_tb;

	localparam WIDTH = 16;
	localparam CLK_DIV = 10;
	
	bit clk = 0, aclr = 1, sync = 0;
	
	wire load_n, sclk;
	wire sdi;
	
	wire [WIDTH-1:0] data;
	wire valid;
	
	bit [15:0] test_data = 0;
	reg [15:0] res;
	
	always #6.944ns clk++;
	
	initial begin
		repeat(10) @(posedge clk);
		aclr = 0;
		repeat(10) @(posedge clk);
		
		test_task(16'h1234);
		wait(valid);
		@(posedge clk);
		
		test_task(16'h55AA);
		wait(valid);
		@(posedge clk);
		
		repeat(10) @(posedge clk);
		$stop(2);
	end
	
	always_ff @(posedge clk)
		if (valid)
			res = data;
	
	always #100us $stop(2);
	
	sipo #(.WIDTH(WIDTH), .CLK_DIV(CLK_DIV)) dut(.*);
	
	wire q0;
	
	SN74HC165 inst0(
		.LDn(load_n),
		.data(test_data[7:0]),
		.clk(sclk), .clk_inh(1'b0),
		.ser(1'b0),
		.q(q0)
	);
	
	SN74HC165 inst1(
		.LDn(load_n),
		.data(test_data[15:8]),
		.clk(sclk), .clk_inh(1'b0),
		.ser(q0),
		.q(sdi)
	);
	
	task test_task(bit [15:0] d);
		wait(!load_n);
		test_data = d;		
		wait(load_n);		
		@(posedge clk);
	endtask
	
endmodule :sipo_tb
