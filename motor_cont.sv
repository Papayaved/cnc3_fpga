`ifndef _motor_cont_
`define _motor_cont_

`include "pls_cont.sv"
`include "prescale.sv"

module motor_cont #(
	parameter MOTORS = 8
)(
	input clk, aclr, sclr, abort,
	input permit,
	input [MOTORS-1:0][31:0] N, T,
	input [31:0] task_id,
	input [MOTORS-1:0] write,
	output reg [MOTORS-1:0] wrreq,
	output [MOTORS-1:0] run,
	output reg [31:0] cur_task_id,
	
	output [MOTORS-1:0] step, dir,
	
	input [15:0] T_scale,
	output reg oi_reg
);
	wire clk_ena;
//	wire [MOTORS-1:0] cnt_end;
	wire [MOTORS-1:0] oi_req;
	
	wire oi = wrreq != '0 && (oi_req & wrreq) == wrreq;

	genvar i;
	
	generate for (i = 0; i < MOTORS; i++)
		begin :gen
			always_ff @(posedge clk, posedge aclr)
				if (aclr)
					wrreq[i] <= 1'b0;
				else if (sclr || abort || oi)
					wrreq[i] <= 1'b0;
				else if (wrreq == '0 && write[i])
					wrreq[i] <= 1'b1;
			
			pls_cont step_inst(
				.clk, .clk_ena, .aclr, .abort(sclr || abort),
				.permit, .oi,
				.N(N[i]), .T(T[i]), .empty(!wrreq[i]),
				.run(run[i]), .oi_req(oi_req[i]),
				.pls(step[i]), .dir(dir[i]),
				.cnt_end()
			);
		end
	endgenerate
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			cur_task_id <= '0;
		else if (sclr)
			cur_task_id <= '0;
		else if (wrreq == '0 && write != '0)
			cur_task_id <= task_id;
			
	prescale_oi prescale_inst(
		.clk, .aclr, .sclr(sclr || abort),
		.T_scale,
		.oi,
		.clk_ena
	);
	
	always_ff @(posedge clk, posedge aclr)
		oi_reg <= aclr ? 1'b0 : ( sclr ? 1'b0 : oi );

endmodule :motor_cont

`endif
