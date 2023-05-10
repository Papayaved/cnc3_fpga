timeunit 1ns;
timeprecision 1ps;

`include "MCP3008.sv"
`include "FmcBus.sv"
`include "SN74HC595.sv"
`include "SN74HC165.sv"

typedef struct packed {
	logic [6:0] drum_vel;
	logic ena;
	
	logic wire_ctrl;
	logic drum_ena;
	logic pump_ena;
	logic [4:0] res;
} indicator_t;

typedef struct packed {
	logic [4:0] res2;
	logic pump_ena;
	logic hv_ena;
	logic hv_lvl;

	logic [7:0] width;
	
	logic [7:0] ratio;
	
	logic [7:0] current_code;
	
	logic [7:0] res1;
	
	logic [2:0] res0;
	logic [2:0] drum_vel;
	logic drum_rev;
	logic drum_fwd;	
} controls_t;

typedef struct packed {
	logic soft_alarm;
	logic power_off;
	logic wire_ctrl;
	logic alarm;
	logic drum_rev;
	logic drum_fwd;
} lim_switch_t;

module top_tb #(parameter
	TEST = 0
);
	// PINS
	bit gen24 = 0;

	bit ne = 1, noe = 1, nwe = 1, nadv = 1;
	wire [15:0] ad;
	bit [1:0] nbl = 2'b11;
	wire nirq;
	
	wire [4:0] X, Y;	
	wire [2:0] U, V;	
	bit [2:0] enc_A, enc_B, enc_Z;
	
	wire adc_sclk, adc_csn, adc_mosi;
	bit adc_miso = '0;
	
	wire ind_sclk, ind_sdo, ind_load;
	
	bit wire_break = 1'b0, OK220 = 1'b1;	
	bit [7:0] sig_in = '0;
	
	wire hv_ena, hv_lvl, pump_ena, estop, drum_fwd, drum_rev, oe, center_n;
	wire [2:0] drum_vel;
	
	bit pult_A = 1'b0, pult_B = 1'b0;
	
	wire step, dir, sd_ena, sd_oe_n;	
	wire [5:0] current;
	
	wire gen_sclk, gen_load, gen_sdo;	
	bit gen_sdi = 1'b0;
	
	wire led_n;
	wire [2:0] res;

	// VARIABLES	
	bit [7:0][9:0] adc_data = {10'd8, 10'd7, 10'd6, 10'd5, 10'd4, 10'd3, 10'd2, 10'd1};

	always #20.833ns gen24++;
	
	IFmcBus i_bus();
	
	always_comb begin
		ne = i_bus.ne;
		noe = i_bus.noe;
		nwe = i_bus.nwe;
		nadv = i_bus.nadv;
		nbl = i_bus.nbl;
		i_bus.adi = ad;
	end
	
	assign ad = (!ne && (!nwe || !nadv)) ? i_bus.ado : 16'hZ;
	
	FmcBus bus;
	
	initial begin
		bus = new(i_bus);
		
		repeat(10) @(posedge gen24);
		
		bus.printVersion();
		bus.printAllRegs();
		
		bus.waitFilterReady();
//		bus.setLimSwitchMask(16'h0020); // The soft alarm is always enabled
		bus.clearLimSwitch();
		
//		repeat(100) @(posedge gen24);
//		$display("Continue ...");
//		$stop(2);
		
		case (TEST)
			0: StepByStep();
			1: FullTurn();
			2: AsymSteps();
			3: Timeout();
			4: #50us bus.printAdc();
			5: RW32(0, 15);
			6: oneStep(0);
			7: pauseScale(10);
			8: DataOut();
			9: DataIn();
			10: ControlsTest();
			11: FeedbackTest();
		endcase
		
		repeat(100) @(posedge gen24);
		$display("Finish");
		$stop(2);
	end
	
	always #100ms $stop(2);
	
	top dut(.*);
	
	MCP3008 adc_inst(.data(adc_data), .sclk(adc_sclk), .csn(adc_csn), .mosi(adc_mosi), .miso(adc_miso));	
	
	wire [15:0] gen_dato;
	wire [15:0] ind_dato;
	bit ind_sdi = 0;
	
	SN74HC595_N #(.N(2)) SN74HC595_6x_inst(.lock(gen_load), .sclk(gen_sclk), .sdo(gen_sdo), .sdi(gen_sdi), .q(gen_dato));
	SN74HC595_2x SN74HC595_2x_inst(.lock(ind_load), .sclk(ind_sclk), .sdo(ind_sdo), .sdi(ind_sdi), .q(ind_dato));
	
	bit [15:0] kb = 0;
	
	SN74HC165_2x kb_inst(.data(kb), .load_n(kb_load), .sclk(kb_sclk), .sdi(kb_sdi));
	
	task StepByStep();
		automatic logic[31:0] enc_x, enc_y;
	
		bus.setThld(0, 1023);
		bus.setOE(1);
		
		for (int k = 0; k < 250; k++)
			for (int i = 0; i < 4; i++) begin
				bus.waitReady();
				bus.step(i, 1, 100);
			end
				
		bus.waitReady();
		
		repeat(100) @(posedge gen24);
		bus.globalSnapshot();
		bus.getEncoder(0, enc_x);
		bus.getEncoder(1, enc_y);
		
		$display("Encoder X = %d, Y = %d]", enc_x, enc_y);
	endtask
	
	task FullTurn();
		automatic int k_max = 5*2;
		
		bus.setThld(0, 1023);
		bus.setOE(1);
		
		for (int i = 0; i < 4; i++) begin
			if (i == 2) k_max = 3*2;
			
			for (int k = 0; k < k_max; k++) begin
				bus.waitReady();
				bus.step(i, 1, 100);
			end
		end
		
		k_max = 5*2;
		
		for (int i = 0; i < 4; i++) begin
			if (i == 2) k_max = 3*2;
			
			for (int k = 0; k < k_max; k++) begin
				bus.waitReady();
				bus.step(i, -1, 100);
			end
		end
				
		bus.waitReady();
	endtask
	
	task AsymSteps();
		bus.setThld(0, 1023);
		bus.setOE(1);

		for (int i = 0; i < 3; i++) begin
			bus.waitReady();
			bus.write32(ADDR::NT32 + 'h0, 100);
			bus.write32(ADDR::NT32 + 'h4, 2);
			bus.write32(ADDR::NT32 + 'h8, 200);
			bus.write32(ADDR::NT32 + 'hC, 3);
			bus.write32(ADDR::TASK_ID, i + 1);
			bus.write(ADDR::MTR_WRREQ, 3);
		end
		
		bus.waitReady();
	endtask
	
	task Timeout();
		bus.irqEna(1);
		bus.setThld(0, 1023);
		bus.setOE(1);
		bus.setTimeout(100);

		bus.waitReady();
		bus.write32(ADDR::NT32 + 'h0, 100);
		bus.write32(ADDR::NT32 + 'h4, 3);
		bus.write(ADDR::MTR_WRREQ, 1);
		
		repeat(30) @(posedge gen24);
		bus.setThld(~16'h0, ~16'h0);
		
		wait(!nirq);
	endtask
	
	task RW32(int start, int stop);
		$display("RW32 test. Addr: [%04h, %04h]", start<<2, stop<<2);
	
		for (int i = start, d = 1; i <= stop; i++, d++) begin
			bus.write32((i & 16'hFFFF) << 2, d);
		end
		
		bus.print32(start << 2, stop << 2);
	endtask
	
	task oneStep(int i);
		bus.setThld(0, 1023);
		bus.setOE(1);
		
		bus.waitStop();
		bus.step(i, 1, 60_000 - 1);
				
		bus.waitStop();
	endtask
	
	task pause(bit[31:0] ms);
		automatic bit[31:0] T;
		
		T = 72_000_000 / 1000 * ms;
		
		bus.setThld(0, 1023);
		bus.enableFeedback(0);
		bus.setSoftPermit(1);
		bus.setOE(1);
		
		bus.waitReady();
		bus.step(0, 0, 0); // M command
		
		bus.waitReady();		
		bus.step(0, 0, 0); // M command
		
//		bus.step(i, 1, 200 - 1);
		
		bus.waitReady();
		bus.step(0, 0, T);
		
		bus.waitReady();
		bus.step(0, 1, 300 - 1);
				
		bus.waitStop();
	endtask
	
	task pauseScale(bit[31:0] ms);
		automatic bit[31:0] T;		
		automatic int unsigned scale = 7_200; // 10 kHz
		
		T = 72_000_000 / scale * ms / 1000;
		$display("T = %d", T);
		
//		bus.setTScale(scale);
		
		bus.setThld(0, 1023);
		bus.enableFeedback(0);
		bus.setSoftPermit(1);
		bus.setOE(1);
		
		bus.waitReady();
		bus.step(0, 0, 0); // M command
		
		bus.waitReady();		
		bus.step(0, 0, 0); // M command
		
//		bus.step(i, 1, 200 - 1);
		
		bus.waitReady();
		bus.step(0, 0, T);
		
		bus.waitReady();
		bus.step(0, 1, 300 - 1);
				
		bus.waitStop();
	endtask
	
	task DataOut();
		automatic logic [15:0] data16;
		automatic logic [47:0] data48;
		
		bus.setIndicator(16'hABCD);
		bus.setControls(48'h1234_5678_9ABC);
		
		bus.waitFilterReady();
		bus.setIndicator(16'h8001);
		bus.setControls(48'h1111_2222_3333);
		
		bus.waitFilterReady();
		bus.getIndicatorOld(data16);
		bus.getControlsOld(data48);
		$display("Read Ind: %04h Controls: %04h%08h", data16, data48[47:32], data48[31:0]);
	endtask
	
	task DataIn();
		automatic logic [15:0] level, data, clicked;
		
		kb = 16'h0;
		#10us;
		kb = 16'h8231;
		#400us;		
		
		bus.getKeysLevel(level);
		bus.getKeys(data);
		bus.getKeysDown(clicked);
		
		$display("LEVEL: %h KEYS: %h CLICKED: %h", level, data, clicked);
		
		kb = 16'h0;
		#400us;
		
		bus.getKeysLevel(level);
		bus.getKeys(data);
		bus.getKeysDown(clicked);
		
		$display("LEVEL: %h KEYS: %h CLICKED: %h", level, data, clicked);
		
		bus.clearKeysDown(clicked);
		$display("CLEAR");
		
		bus.getKeysLevel(level);
		bus.getKeys(data);
		bus.getKeysDown(clicked);
		
		$display("LEVEL: %h KEYS: %h CLICKED: %h", level, data, clicked);
	endtask
	
	task ControlsTest();
		automatic logic [15:0] data16;
		automatic logic [47:0] data48;
		
		automatic controls_t ctrl = '0;
		automatic indicator_t ind = '0;
		automatic lim_switch_t limsw_mask = '1;
		
		#48us;
		ind.ena = 1;
		bus.setIndicator(ind);
		
		#48us;
		limsw_mask.wire_ctrl = 0;
		bus.setLimSwitchMask(limsw_mask);
		
		#48us;
		ctrl.pump_ena = 1;
		bus.setControls(ctrl);
		
		#48us;
		ctrl.hv_ena = 1;
		bus.setControls(ctrl);
		
		#48us;
		ctrl.hv_lvl = 1;
		bus.setControls(ctrl);
		
		#48us;
		ctrl.width = 36;
		bus.setControls(ctrl);
		
		#48us;
		ctrl.ratio = 8;
		bus.setControls(ctrl);
		
		#48us;
		ctrl.current_code = 7;
		bus.setControls(ctrl);
		
		#48us;
		ctrl.drum_vel = 7;
		bus.setControls(ctrl);
		
		#48us;
		ctrl.drum_rev = 1;
		bus.setControls(ctrl);
		
		#48us;
		ctrl.drum_rev = 0;
		ctrl.drum_fwd = 1;
		bus.setControls(ctrl);
		
		#48us;
		ctrl = '0;
		bus.setControls(ctrl);
		
		#48us;
	endtask
	
	task FeedbackTest();
		bus.setThld(100, 150);
		bus.enableFeedback(1);
		bus.setSoftPermit(1);
		bus.setOE(1);
		
		adc_data[0] = 151;
		#20ms;
		adc_data[0] = 99;
		#100ms;
		adc_data[0] = 151;		
		#20ms;
		
	endtask
	
endmodule :top_tb
