timeunit 1ns;
timeprecision 100ps;

module imit_enc_tb;
	bit clk = 0, aclr = 1, sclr = 1;
	bit step = 0, dir = 0;	
	wire A, B;

	always #10ns clk++;
	
	initial begin
		repeat(10) @(posedge clk);
		aclr = 0;
		
		repeat(10) @(posedge clk);		
		sclr = 0;
		
		repeat(5_000) @(posedge clk);
		dir = 1;
		
		repeat(10_000) @(posedge clk);
		$stop(2);		
	end
	
	
	reg [3:0] cnt = 0;
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			cnt <= 0;
		else if (sclr)
			cnt <= 0;
		else
			cnt <= cnt + 1;
			
	always_ff @(posedge clk, posedge aclr)
		step <= (aclr) ? 1'b0 : (sclr) ? 1'b0 : cnt[3];
	
	imit_enc dut(.clk, .aclr, .sclr, .step(cnt[3]), .dir, .A, .B);

endmodule :imit_enc_tb
