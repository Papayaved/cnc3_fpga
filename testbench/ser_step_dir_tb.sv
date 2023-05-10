`include "SN74HC595.sv"

module ser_step_dir_tb;
	bit clk = 0, aclr = 1, sclr = 0;
	bit [3:0] step = 0, dir = 0;
	
	wire mtr_sclk, mtr_sdo, mtr_lock;
	
	wire busy;
	
	always #6.944ns clk++;
	
	initial begin
		repeat(10) @(posedge clk);
		aclr = 0;
		sclr = 0;
		repeat(10) @(posedge clk);
		
		for (int i = 0; i < 35; i++)
			motor_step(0, 0);
			
		for (int i = 0; i < 35; i++)
			motor_step(0, 1);
		
		#100ns $stop(2);
	end
	
	always #100us $stop(2);
	
	ser_step_dir dut(.*);
	
	wire d_out7;
	
	wire [15:0] phase;
	
	SN74HC595 SN74HC595_inst0(
		.oen(1'b0), .rclk(mtr_lock), .srclrn(1'b1), .srclk(mtr_sclk), .ser(mtr_sdo),
		.q(phase[7:0]), .d_out7(d_out7)
	);
	
	SN74HC595 SN74HC595_inst1(
		.oen(1'b0), .rclk(mtr_lock), .srclrn(1'b1), .srclk(mtr_sclk), .ser(d_out7),
		.q(phase[15:8]), .d_out7()
	);
	
	task motors_step(bit [3:0] _step, bit [3:0] _dir);
		wait(!busy);
		
		step = _step;
		dir = _dir;
		#100ns;
		step = 0;
		#100ns;
	endtask
	
	task motor_step(int num, bit direction);
		if (num >= 0 && num < 4) begin
			wait(!busy);
			
			step[num] = 1;
			dir[num] = direction;
			#100ns;
			step[num] = 0;
			#100ns;
		end
	endtask

endmodule :ser_step_dir_tb
