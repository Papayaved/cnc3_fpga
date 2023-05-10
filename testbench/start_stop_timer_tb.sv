timeunit 1ns;
timeprecision 1ps;

module start_stop_timer_tb #(parameter
	PRE_WIDTH = 16,
	WIDTH = 16
);
	reg clk = 0, aclr = 1, sclr = 1;
	reg sig = 0;
	reg [PRE_WIDTH-1:0] scale = 7_200 - 1; // 0.1 ms
	reg [WIDTH-1:0] length = 100 - 1; // 0.01 sec
	wire pause;
	
	always #6.944ns clk++;
	
	initial begin
		repeat(10) @(posedge clk);
		aclr = 0;
		sclr = 0;
		repeat(10) @(posedge clk);
		sig = 1;
		repeat(100) @(posedge clk);
		sig = 0;
		repeat(100) @(posedge clk);
		
		// test 2
		sig = 1;
		repeat(10) @(posedge clk);
		wait (!pause)
			@(posedge clk);
		
		repeat(10) @(posedge clk);
		sig = 0;
		repeat(10) @(posedge clk);
		$stop(2);
	end
	
	always #11ms $stop(2);
	
	start_stop_timer dut(.*);

endmodule :start_stop_timer_tb
