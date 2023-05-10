`ifndef _motor_bus_
`define _motor_bus_
`include "motor_cont.sv"
`include "step_dir.sv"
`include "prescale.sv"

module motor_bus #(parameter
	MOTORS = 4,
	BAR = 'h0,
	MASK = 'hFF
)(
	input clk, aclr, sclr,
	input [15:0] rdaddr, wraddr,
	input [1:0] be,
	input write,
	input [15:0] wrdata,
	output reg [15:0] rddata,
	
	input permit, cstop, hv_enabled, alarm,
	
	output reg [7:0] step, dir,
	output reg sd_oe_n, sd_ena,
	
	output reg [4:0] X, Y,
	output reg [2:0] U, V,
	
	output reg mtr_timeout,
	output oi, any_run,
	
	output reg global_snapshot,
	input [1:0] enc_changed,
	
	output [1:0] imit_enc_step, imit_enc_dir
);
	wire rdhit = (rdaddr & ~MASK) == BAR;
	wire wrhit = (wraddr & ~MASK) == BAR;
	
	wire [15:0] l_rdaddr = rdaddr & MASK[15:0];
	wire [15:0] l_wraddr = wraddr & MASK[15:0];
	
	reg [31:0] task_id = '0;
	wire [31:0] cur_task_id;
	reg [31:0] task_id_snap = '0;
	
	reg [19:0] timer, timeout;
	reg timeout_ena;
	
	reg [15:0] T_scale;	
	
	reg [MOTORS-1:0][31:0] N, T;
(* keep *) wire [MOTORS-1:0] wrreq;
(* keep *) wire [MOTORS-1:0] run;
	assign any_run = |run;
	
	reg [MOTORS-1:0] main_dir = '0;
	reg swap_xy = 1'b0, swap_uv = 1'b0; // swap motors 0 and 1
	reg oe = 1'b0;
	wire [MOTORS-1:0] gen_step, gen_dir;
	wire [MOTORS-1:0][31:0] coord, coord_enc;
	
	task reset();
		N			<= {MOTORS{32'h0}};
		T			<= {MOTORS{~32'h0}};		
		main_dir	<= '0;
		swap_xy <= 1'b0;
		swap_uv <= 1'b0;
		oe <= 1'b0;
		task_id <= '0;
		timeout <= 'd300_000; // 30 sec
		timeout_ena <= 1'b1;
		T_scale <= 'd7_199; // 10 kHz
		sd_oe_n <= 1'b1;
		sd_ena <= 1'b0;
	endtask
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			reset();
		else if (sclr)
			reset();
		else if (write && wrhit)
			if (l_wraddr < 'h20)
				case (l_wraddr[2:1])
					'h0:	begin
								if (be[0]) N[l_wraddr[4:3]][7:0] <= wrdata[7:0];
								if (be[1]) N[l_wraddr[4:3]][15:8] <= wrdata[15:8];
							end
					'h1:	begin
								if (be[0]) N[l_wraddr[4:3]][23:16] <= wrdata[7:0];
								if (be[1]) N[l_wraddr[4:3]][31:24] <= wrdata[15:8];
							end
					'h2:	begin
								if (be[0]) T[l_wraddr[4:3]][7:0] <= wrdata[7:0];
								if (be[1]) T[l_wraddr[4:3]][15:8] <= wrdata[15:8];
							end
					'h3:	begin
								if (be[0]) T[l_wraddr[4:3]][23:16] <= wrdata[7:0];
								if (be[1]) T[l_wraddr[4:3]][31:24] <= wrdata[15:8];
							end
				endcase
			else
				case (l_wraddr)
					'h40:	begin
								if (be[0]) main_dir <= wrdata[MOTORS-1:0];
								if (be[1]) {swap_uv, swap_xy} <= wrdata[9:8];
							end
					'h42:	if (be[0]) oe <= wrdata[0];
					'h44:	begin
								if (be[0]) task_id[7:0] <= wrdata[7:0];
								if (be[1]) task_id[15:8] <= wrdata[15:8];
							end
					'h46:	begin
								if (be[0]) task_id[23:16] <= wrdata[7:0];
								if (be[1]) task_id[31:24] <= wrdata[15:8];
							end
					
					'h4C:	begin
								if (be[0]) timeout[7:0] <= wrdata[7:0];
								if (be[1]) timeout[15:8] <= wrdata[15:8];
							end
					'h4E:	begin
								if (be[0]) timeout[19:16] <= wrdata[3:0];
							end
					'h50: if (be[0]) timeout_ena <= wrdata[0];
									
					'h54: if (be[0]) T_scale <= wrdata;
					
					'h58: if (be[0]) sd_oe_n <= !wrdata[0];
					'h5A: if (be[0]) sd_ena <= wrdata[0];
				endcase

	wire timeout_clr		= write && wrhit && l_wraddr == 'h4A && be[0] && wrdata[0];
	wire abort				= write && wrhit && l_wraddr == 'h4A && be[0] && wrdata[1];
	
	always_ff @(posedge clk, posedge aclr)
		begin
			global_snapshot	<= (aclr) ? 1'b0 : write && wrhit && l_wraddr == 'h4A && be[0] && wrdata[2];
		end
		
	// Read
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			rddata <= '0;
		else if (sclr)
			rddata <= '0;
		else if (rdhit)
			if (l_rdaddr < 'h20)
				case (l_rdaddr[2:1])
					'h0: rddata <= N[l_rdaddr[4:3]][15:0];
					'h1: rddata <= N[l_rdaddr[4:3]][31:16];
					'h2: rddata <= T[l_rdaddr[4:3]][15:0];
					'h3: rddata <= T[l_rdaddr[4:3]][31:16];
				endcase
			else if (l_rdaddr < 'h40)
				rddata <= '0;
			else if (l_rdaddr < 'h80)
				case (l_rdaddr)
					'h40: rddata <= {{6'h0, swap_uv, swap_xy}, 8'(main_dir)};
					'h42: rddata <= {15'h0, oe};
					'h44: rddata <= task_id_snap[15:0];
					'h46: rddata <= task_id_snap[31:16];
					'h48: rddata <= {8'(run), 8'(wrreq)};
					'h4A:	rddata <= {15'h0, mtr_timeout};
					'h4C:	rddata <= timeout[15:0];
					'h4E:	rddata <= {12'h0, timeout[19:16]};
					'h50: rddata <= {15'h0, timeout_ena};
					'h54: rddata <= T_scale;
					'h58: rddata <= {15'h0, !sd_oe_n};
					'h5A: rddata <= {15'h0, sd_ena};
					default: rddata <= '0;
				endcase
			else if (l_rdaddr < 'hA0) // 4 motors
				case (l_rdaddr[2:1])
					'h0: rddata <= coord[l_rdaddr[4:3]][15:0];
					'h1: rddata <= coord[l_rdaddr[4:3]][31:16];
					'h2: rddata <= coord_enc[l_rdaddr[4:3]][15:0];
					'h3: rddata <= coord_enc[l_rdaddr[4:3]][31:16];
				endcase
			else
				rddata <= '0;
		else
			rddata <= '0;
	
	motor_cont #(MOTORS) cont_inst(
		.clk, .aclr, .sclr, .abort(abort || cstop),
		.permit(permit && !alarm),
		.N, .T, .task_id,
		.write({MOTORS{write && wrhit && l_wraddr == 'h48 && be[0]}} & wrdata[MOTORS-1:0]),
		.wrreq, .run,
		.cur_task_id,		
		.step(gen_step), .dir(gen_dir),
		.T_scale,
		.oi_reg(oi)
	);
	
	logic [MOTORS-1:0] step_comb, dir_comb;
	
	always_comb begin
		step_comb = oe ? gen_step : '0;
		dir_comb = (oe ? gen_dir : '0) ^ main_dir;
	end
	
	always @(posedge clk) begin
		step[0] <= swap_xy ? step_comb[1] : step_comb[0];
		step[1] <= swap_xy ? step_comb[0] : step_comb[1];
		step[2] <= swap_uv ? step_comb[3] : step_comb[2];
		step[3] <= swap_uv ? step_comb[2] : step_comb[3];
		step[4] <= 1'b0;
		step[7:5] <= '0;
		
		dir[0] <= swap_xy ? dir_comb[1] : dir_comb[0];
		dir[1] <= swap_xy ? dir_comb[0] : dir_comb[1];
		dir[2] <= swap_uv ? dir_comb[3] : dir_comb[2];
		dir[3] <= swap_uv ? dir_comb[2] : dir_comb[3];
		dir[4] <= 1'b0;
		dir[7:5] <= '0;
	end
	
	wire [4:0] _X, _Y;
	wire [2:0] _U, _V;
	
	step_dir #(.WIDTH(5))
		X_inst(.clk, .aclr, .sclr(sclr || !oe), .step(step[0]), .dir(dir[0]), .phase(_X), .changed()),	
		Y_inst(.clk, .aclr, .sclr(sclr || !oe), .step(step[1]), .dir(dir[1]), .phase(_Y), .changed());
	
	step_dir #(.WIDTH(3))
		U_inst(.clk, .aclr, .sclr(sclr || !oe), .step(step[2]), .dir(dir[2]), .phase(_U), .changed()),
		V_inst(.clk, .aclr, .sclr(sclr || !oe), .step(step[3]), .dir(dir[3]), .phase(_V), .changed());
	
	step_cnts #(MOTORS) cnt_inst(
		.clk, .aclr, .sclr,
		.addr(l_wraddr[5:0]), .be, .wrdata, .write(write && wrhit && l_wraddr >= 'h80 && l_wraddr < 'hC0), .global_snapshot, .enc_changed(MOTORS'(enc_changed)),
		.step(gen_step), .dir(gen_dir),
		.coord, .dst(), .coord_enc
	);
	
	assign imit_enc_step = gen_step[1:0];
	assign imit_enc_dir = gen_dir[1:0];
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			{X, Y, U, V} <= '0;
		else if (sclr)
			{X, Y, U, V} <= '0;
		else if (sd_oe_n)
			{X, Y, U, V} <= {_X, _Y, _U, _V};
		else
			begin
				X <= {1'b0, dir[1], step[1], dir[0], step[0]};
				Y <= {1'b0, dir[3], step[3], dir[2], step[2]};
				U <= '0;
				V <= '0;
			end
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			task_id_snap <= '0;
		else if (sclr)
			task_id_snap <= '0;
		else if (global_snapshot)
			task_id_snap <= cur_task_id;
	
	// Timeout
	wire slow_clk_ena;
	
	prescale to_prescale(.clk, .aclr, .sclr, .enable(!permit), .T_scale, .clk_ena(slow_clk_ena));
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			timer <= '0;
		else if (sclr || alarm || permit || !hv_enabled || !timeout_ena || mtr_timeout)
			timer <= '0;
		else if (slow_clk_ena)
			timer	<= timer + 1'b1;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			mtr_timeout <= 1'b0;
		else if (sclr || permit)
			mtr_timeout <= 1'b0;
		else if (timeout_ena && timer > timeout && slow_clk_ena)
			mtr_timeout <= 1'b1;
		else if (timeout_clr)
			mtr_timeout <= 1'b0;
	
endmodule :motor_bus

`include "step_dir_cnt.sv"

module step_cnts #(
	parameter MOTORS = 4
)(
	input clk, aclr, sclr,
	input [5:0] addr,
	input [1:0] be,
	input [15:0] wrdata,

	input write, global_snapshot,
	input [MOTORS-1:0] enc_changed,
	input [MOTORS-1:0] step, dir,
	output [MOTORS-1:0][31:0] coord, dst, coord_enc
);
	genvar k;
	
	generate for (k = 0; k < MOTORS; k++)
		begin :gen_cnt
			step_dir_cnt coord_cnt(
				.clk, .aclr, .sclr,
				.addr(addr[1]), .be, .wrdata, .write(write && (addr[5:2] == 2 * k)), .snapshot(global_snapshot), .enc_changed(enc_changed[k]),
				.step(step[k]), .dir(dir[k]), .cnt(coord[k]), .cnt_enc(coord_enc[k])
			);
			
			step_dir_cnt dst_cnt(
				.clk, .aclr, .sclr,
				.addr(addr[1]), .be, .wrdata, .write(write && (addr[5:2] == 2 * k + 1)), .snapshot(global_snapshot), .enc_changed(1'b0),
				.step(step[k]), .dir(1'b0), .cnt(dst[k]), .cnt_enc()
			);
		end
	endgenerate
	
endmodule :step_cnts

`endif
