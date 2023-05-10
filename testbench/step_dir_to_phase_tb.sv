timeunit 1ns;
timeprecision 1ps;

module step_dir_to_phase_tb;
	parameter PHASE_WIDTH = 5;
	
	bit clk = 0, aclr = 1, sclr = 1;
	bit step = 0, dir = 0;
	wire [PHASE_WIDTH-1:0] phase;
	
	always #6.944ns clk++;
	
	initial begin
		repeat(10) @(posedge clk);
		aclr = 0;
		sclr = 0;
		repeat(10) @(posedge clk);
		
		for (int i = 0; i < 35; i++)
			to_step(0);
			
		for (int i = 0; i < 35; i++)
			to_step(1);
		
		#100ns;
		
		$stop(2);
	end
	
	always #100us $stop(2);
	
	step_dir_to_phase #(.PHASE_WIDTH(PHASE_WIDTH)) dut(.*);
	
	task to_step(bit direction);
		step = 1;
		dir = direction;
		#100ns;
		step = 0;
		#100ns;
	endtask
	
endmodule :step_dir_to_phase_tb
