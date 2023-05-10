timeunit 1ns;
timeprecision 1ps;

module hv_enabled_tb #(parameter
	PRE_WIDTH = 16,
	WIDTH = 16
);
	reg clk = 0, aclr = 1, sclr = 1;
	reg hv = 0, permit = 0;
	reg [PRE_WIDTH-1:0] prescale = 7_200 - 1; // 0.1 ms
	reg [WIDTH-1:0] length = 100 - 1; // 0.01 sec
	wire enabled;
	
	always #6.944ns clk++;
	
	initial begin
		repeat(10) @(posedge clk);
		aclr = 0;
		sclr = 0;
		repeat(10) @(posedge clk);
		
		// test 1
		hv = 1;
		repeat(100) @(posedge clk);
		hv = 0;
		repeat(100) @(posedge clk);
		
		// test 2
		hv = 1;
		repeat(100) @(posedge clk);
		
		permit = 1;		
		repeat(100) @(posedge clk);
		permit = 0;		
		repeat(100) @(posedge clk);
		
		hv = 0;		
		repeat(100) @(posedge clk);
		
		// test 3
		hv = 1;
		repeat(10) @(posedge clk);
		wait (enabled)
			@(posedge clk);			
		
		repeat(10) @(posedge clk);
		hv = 0;
		repeat(100) @(posedge clk);
		
		$stop(2);
	end
	
	always #11ms $stop(2);
	
	hv_enabled dut(.*);

endmodule :hv_enabled_tb
