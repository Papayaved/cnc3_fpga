`ifndef _ser_step_dir_
`define _ser_step_dir_

`include "step_dir.sv"
`include "piso.sv"

module ser_step_dir(
	input clk, aclr, sclr,
	input [3:0] step, dir,
	
	output mtr_sclk, mtr_sdo, mtr_lock,
	
	output busy
);
	wire [1:0][4:0] phase5;
	wire [1:0][2:0] phase3;
	
	wire [3:0] changed;
	
	genvar i;
	
	generate for (i = 0; i < 2; i++)
		begin :gen	
			step_dir #(.WIDTH(5)) sd5_inst(
				.clk, .aclr, .sclr,
				.step(step[i]), .dir(dir[i]),
				.phase(phase5[i]),
				.changed(changed[i])
			);
			
			step_dir #(.WIDTH(3)) sd3_inst(
				.aclr, .clk, .sclr,
				.step(step[2 + i]), .dir(dir[2 + i]),
				.phase(phase3[i]),
				.changed(changed[2 + i])
			);
		end
	endgenerate
	
	piso #(.WIDTH(2 * (5 + 3)), .CLK_DIV(10)) piso_inst(
		.clk, .aclr, .sclr(1'b0),
		.data({phase5, phase3}),
		.wrreq(!busy && |changed),
		.busy, .wrack(),
		.sclk(mtr_sclk), .sdo(mtr_sdo), .lock(mtr_lock)
	);

endmodule :ser_step_dir

`endif
