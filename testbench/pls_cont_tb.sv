timeunit 1ns;
timeprecision 1ps;

module pls_cont_tb;

	bit clk = 0, clk_ena = 1, aclr = 1, abort = 1;
	bit oi = 0;
	bit signed [31:0] N = 0;
	bit [31:0] T = '1;
	bit empty = 1;
	bit permit = 0;	
	wire run, oi_req;
	
	wire pls, dir, cnt_end;
	
	always #6.944ns clk++;
	
	initial begin
		repeat(10) @(posedge clk);
		aclr = 0;
		abort = 0;
		repeat(10) @(posedge clk);
		
//		test1();
//		test2();
//		test3();
//		test_pause();
//		test_pause1(10000);
		test_abort();
		
		repeat(100) @(posedge clk);
		$stop(2);
	end
	
	always #300us $stop(2);
	always
		begin
			#2.758us abort = 1;
			#10us abort = 0;
		end
	
	pls_cont dut(.*);
	
//	task test1();
//		N = -1;
//		T = 300;
//		empty = 0;
//		wait(rdack);
//		empty = 1;
//		
//		wait(oi_req);
//		oi = 1;
//		@(posedge clk);
//		oi = 0;
//		
//		repeat(20) @(posedge clk);
//		permit = 1;
//		
//		wait(!run);
//	endtask
//	
//	task test2();
//		N = -2;
//		T = 300;
//		empty = 0;
//		wait(rdack);
//		empty = 1;
//		
//		wait(oi_req);
//		oi = 1;
//		@(posedge clk);
//		oi = 0;
//		
//		repeat(20) @(posedge clk);
//		permit = 1;
//		
//		wait(!run);
//	endtask
//	
//	task test3();
//		N = -2;
//		T = 300;
//		empty = 0;
//		wait(rdack);
//		N = 3;
//		T = 200;
//		
//		wait(oi_req);
//		oi = 1;
//		@(posedge clk);
//		oi = 0;
//		
//		repeat(20) @(posedge clk);
//		permit = 1;
//		
//		wait(rdack);
//		empty = 1;
//		
//		wait(oi_req);
//		oi = 1;
//		@(posedge clk);
//		oi = 0;
//		
//		wait(!run);
//	endtask
	
//	task test_pause();
//		N = -2;
//		T = 300;
//		empty = 0;
//		
//		//
//		wait(oi_req);
//		oi = 1;
//		@(posedge clk);
//		oi = 0;
//		@(posedge clk);
//		
//		repeat(20) @(posedge clk);
//		permit = 1;
//
//		//
//		N = 0;
//		T = 500;
//		
//		wait(oi_req);
//		oi = 1;
//		@(posedge clk);
//		oi = 0;
//		@(posedge clk);
//		
//		//		
//		N = 3;
//		T = 200;
//		
//		wait(oi_req);
//		oi = 1;
//		@(posedge clk);
//		oi = 0;
//		
//		empty = 1;
//		
//		wait(!run);
//	endtask
	
	task test_abort();
		N = -2;
		T = 300;
		empty = 0;
		
		//
		wait(oi_req);
		oi = 1;
		@(posedge clk);
		oi = 0;
		@(posedge clk);
		
		repeat(20) @(posedge clk);
		permit = 1;

		//
		N = 0;
		T = 500;
		
		wait(oi_req);
		oi = 1;
		@(posedge clk);
		oi = 0;
		@(posedge clk);
		
		//		
		N = 3;
		T = 200;
		
		wait(oi_req);
		oi = 1;
		@(posedge clk);
		oi = 0;
		
		empty = 1;
		
		wait(!run);
	endtask

endmodule :pls_cont_tb
	