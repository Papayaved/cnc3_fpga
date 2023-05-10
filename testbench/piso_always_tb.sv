timeunit 1ns;
timeprecision 1ps;

`include "SN74HC595.sv"

module piso_always_tb;

	localparam WIDTH = 16;
	localparam CLK_DIV = 10;

	bit clk = 0, aclr = 1, sclr = 0;
	bit [WIDTH-1:0] data = 0;
	wire [WIDTH-1:0] data_old;
	wire sclk, sdo, lock, sdi;

	wire [15:0] q;
	
	always #6.944ns clk++;
	
	initial begin
		repeat(10) @(posedge clk);
		aclr = 0;
		sclr = 0;
		
		repeat(10) @(posedge clk);
		
		#48us;
		data = 48'h1234;
		
		#48us;
		data = 48'h5678;
		
		#48us;
		data = 48'h0;
		
		#48us;
				
		$stop(2);
	end
	
//	always #200us $stop(2);
	
	piso_always #(.WIDTH(WIDTH), .CLK_DIV(CLK_DIV)) dut(.*);
	
	wire d_out7;
	
	SN74HC595 SN74HC595_inst0(
		.oen(1'b0), .rclk(lock), .srclrn(1'b1), .srclk(sclk), .ser(sdo),
		.q(q[7:0]), .d_out7(d_out7)
	);
	
	SN74HC595 SN74HC595_inst1(
		.oen(1'b0), .rclk(lock), .srclrn(1'b1), .srclk(sclk), .ser(d_out7),
		.q(q[15:8]), .d_out7(sdi)
	);
	
endmodule :piso_always_tb
