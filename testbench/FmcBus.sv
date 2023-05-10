`ifndef _FmcBus_
`define _FmcBus_
`include "MyTypesPkg.sv"

import MyTypesPkg::Array;

package ADDR;
	const int MTR_BAR		= 'h0;
	const int ENC_BAR		= 'h100;
	const int CTRL_BAR	= 'h180;
	const int ADC_BAR		= 'h1C0;
	
	const int MTR_NUM		= 8;
	
	const int NT32			= MTR_BAR;
	const int MAIN_DIR	= MTR_BAR + 'h40;
	const int MTR_OE		= MTR_BAR + 'h42;
	const int TASK_ID		= MTR_BAR + 'h44;
	const int MTR_WRREQ	= MTR_BAR + 'h48;
	const int MTR_CONTROL = MTR_BAR + 'h4A;
	const int TIMEOUT32	= MTR_BAR + 'h4C;
	const int TIMEOUT_ENA = MTR_BAR + 'h50;	
	const int T_SCALE		= MTR_BAR + 'h54;
	
	const int POS32		= MTR_BAR + 'h80;
	
	const int ENC_NUM		= 8;
	const int ENC8_CLR	= ENC_BAR;
	const int ENC32		= ENC_BAR + 'h40;
	
	const int IRQ_FLAG		= CTRL_BAR;
	const int IRQ_FLAG_CLR	= CTRL_BAR;
	const int IRQ_MASK		= CTRL_BAR + 'h2;
	const int RESET			= CTRL_BAR + 'h4;
	const int STATUS			= CTRL_BAR + 'h6;
	const int LIM_SWITCH_MASK	= CTRL_BAR + 'h8;
	
	const int LIM_SWITCH			= CTRL_BAR + 'hC;
	const int LIM_SWITCH_FLAG	= CTRL_BAR + 'hE;
	
	const int KEY32_LEVEL		= CTRL_BAR + 'h10;
	const int KEY32				= CTRL_BAR + 'h14;
	const int KEY32_DOWN			= CTRL_BAR + 'h18;
	const int KEY32_TIMEOUT		= CTRL_BAR + 'h1C;
	
	const int CTRL48			= CTRL_BAR + 'h20;
	const int CTRL48_OLD		= CTRL_BAR + 'h28;

	const int IND			= CTRL_BAR + 'h30;
	const int IND_OLD		= CTRL_BAR + 'h32;
	
	const int LED16		= CTRL_BAR + 'h3A;
	const int VER32		= CTRL_BAR + 'h3C;
	
	const int ADC_NUM			= 5;
	const int ADC				= ADC_BAR;
	const int LOW_THLD		= ADC_BAR + 'h10;
	const int HIGH_THLD		= ADC_BAR + 'h12;
	const int FB_ENA			= ADC_BAR + 'h14;
	const int SOFT_PERMIT	= ADC_BAR + 'h16;
	const int PERMIT			= ADC_BAR + 'h18;
endpackage :ADDR

interface IFmcBus();
	bit ne, noe, nwe, nadv;
	logic [15:0] adi;
	bit [15:0] ado;
	bit [1:0] nbl;
endinterface

class FmcBus;
	const int FREQ = 72_000_000;
	const real T = 1.0/FREQ;
	
	local virtual IFmcBus bus;
	
	extern function new(virtual IFmcBus i_bus);
//	extern task write8(shortint unsigned addr, byte data, input bit print = 1);
	extern task write(shortint unsigned addr, shortint unsigned data, input bit print = 1);
	extern task read(shortint unsigned addr, output logic [15:0] data, input bit print = 1);

	extern task readArray(shortint unsigned addr, shortint unsigned len, ref Array ar);
	extern task setArray(int unsigned addr, int unsigned len, shortint unsigned value);	
	extern task clearArray(int unsigned addr, int unsigned len);	

	extern task read32(shortint unsigned addr, output logic [31:0] data, input bit print = 1);	
	extern task write32(shortint unsigned addr, int unsigned data, input bit print = 1);

	extern task readAdcs(output logic [4:0][9:0] adc, output logic [4:0] err);
	extern task readAdc(int n, output logic [9:0] adc, output logic err);
	extern task printAdc();
	
	extern task print32(int start, int stop);
	extern task printAllRegs();
//	extern task SoftReset();

	extern task printVersion();
	
//	extern task IrqMask(bit[15:0] mask);
//	extern task IrqEna();
//	extern task IrqDis();
	
	extern task setOE(bit oe);
	extern task getOE(output logic oe);
	extern task getRun(output logic [15:0] run);
	extern task getWrreq(output logic [7:0] wrreq);
	extern task getReady(output logic ready);
	extern task waitReady();
	extern task waitStop();
	extern task step(int i, int N, int T);
	extern task setTimeout(int unsigned T);
	extern task getTimeout(output logic [31:0] T);
	extern task setTScale(int unsigned T);
	extern task getTScale(output logic [15:0] T);
	extern task globalSnapshot();

	extern task setThld(bit [15:0] low, bit [15:0] high);
	extern task enableFeedback(bit ena);
	extern task setSoftPermit(bit ena);
	
	extern task irqEna(bit enable);
	
	extern task waitFilterReady();
	
	extern task setIndicator(input bit [15:0] value);
	extern task getIndicator(output logic [15:0] value);
	extern task getIndicatorOld(output logic [15:0] value);
	
	extern task getKeysLevel(output logic [15:0] value);
	extern task getKeys(output logic [15:0] value);
	extern task getKeysDown(output logic [15:0] value);
	extern task clearKeysDown(input bit [15:0] value);
	
	extern task setControls(input bit [47:0] value);
	extern task getControls(output logic [47:0] value);
	extern task getControlsOld(output logic [47:0] value);
	
	extern task setLimSwitchMask(input bit [15:0] value);
	extern task getLimSwitchMask(output logic [15:0] value);
	
	extern task clearLimSwitch();
	
	extern task getEncoder(unsigned i, output logic [31:0] value);
	
endclass

function FmcBus::new(virtual IFmcBus i_bus);
	this.bus = i_bus;
	
	bus.ne = 1;
	bus.noe = 1;
	bus.nwe = 1;
	bus.nadv = 1;
	bus.ado = 0;
	bus.nbl = 2'b11;
endfunction

//task FmcBus::write8(shortint unsigned addr, byte data, input bit print = 1);
//	bus.ne = 0;
//	bus.noe = 1;
//	bus.nwe = 1;
//	bus.nadv = 0;
//	bus.ado = addr;
//	bus.nbl = addr[0] ? 2'b01 : 2'b10;
//	#100ns;
//	bus.nwe = 0;
//	bus.nadv = 1;
//	bus.ado = {data, data};
//	#100ns;
//	bus.nwe = 1;
//	bus.ne = 1;
//	bus.nbl = 2'b11;
//	
//	if (print)
//		$display("\t\twrite8. Addr %03h: %02h", addr, data);	
//endtask

task FmcBus::write(shortint unsigned addr, shortint unsigned data, input bit print = 1);
	bus.ne = 0;
	bus.noe = 1;
	bus.nwe = 1;
	bus.nadv = 0;
	bus.ado = addr>>1;
	bus.nbl = 2'b00;
	#100ns;
	bus.nwe = 0;
	bus.nadv = 1;
	bus.ado = data;
	#100ns;
	bus.nwe = 1;
	bus.ne = 1;
	bus.nbl = 2'b11;
	
	if (print)
		$display("\t\twrite. Addr %03h: %04h", addr, data);
endtask

task FmcBus::read(shortint unsigned addr, output logic [15:0] data, input bit print = 1);
	bus.ne = 0;
	bus.noe = 1;
	bus.nwe = 1;
	bus.nadv = 0;
	bus.ado = addr>>1;
	bus.nbl = 2'b00;
	#100ns;
	bus.noe = 0;
	bus.nadv = 1;
	#100ns;
	bus.noe = 1;
	bus.ne = 1;
	data = bus.adi;
	bus.nbl = 2'b11;
	
	if (print)
		$display("\t\tread. Addr %03h: %04h", addr, data);
endtask

task FmcBus::readArray(shortint unsigned addr, shortint unsigned len, ref Array ar);
	ar = new(len); // delete
	for (int i = 0; i < len; i++)
		read(addr++, ar.data[i]);
endtask

task FmcBus::setArray(int unsigned addr, int unsigned len, shortint unsigned value);
	for (int i = 0; i < len; i++)
		write(addr++, value);
endtask

task FmcBus::clearArray(int unsigned addr, int unsigned len);
	setArray(addr, len, 0);
endtask

task FmcBus::read32(shortint unsigned addr, output logic [31:0] data, input bit print = 1);
	read(addr, data[15:0], 0);
	read(addr + 2, data[31:16], 0);
	
	if (print)
		$display("\t\tread32. Addr %04h: %08h", addr, data);
endtask

task FmcBus::write32(shortint unsigned addr, int unsigned data, input bit print = 1);
	write(addr, data[15:0], 0);
	write(addr + 2, data[31:16], 0);
	
	if (print)
		$display("\t\twrite32. Addr %04h: %08h", addr, data);
endtask

task FmcBus::readAdcs(output logic [4:0][9:0] adc, output logic [4:0] err);
	automatic logic [15:0] data;
	
	for (int i = 0, addr = ADDR::ADC; i < ADDR::ADC_NUM; i++, addr += 2) begin	
		read(addr, data);
		adc[i] = data[9:0];
		err[i] = data[10];
	end
	
endtask

task FmcBus::readAdc(int n, output logic [9:0] adc, output logic err);
	automatic logic [15:0] data;
	
	read(ADDR::ADC + (n << 1), data);
	adc = data[9:0];
	err = data[10];
endtask

task FmcBus::printAdc();
	automatic logic [9:0] adc;
	automatic logic err;
	
	for (int i = 0; i < 5; i++) begin
		readAdc(i, adc, err);
		$display("ADC%d: %d, err: %01d", i, adc, err);
	end
	
endtask

task FmcBus::print32(int start, int stop);
	automatic logic [31:0] data;
	automatic int i;

	for (i = start >> 2; i <= stop >> 2; i++)
		begin
			read(i << 2, data, 0);
			
			if ((i & 7) == 0)
				$write("%04h: %08h", i << 2, data);
			else if ((i & 7) == 7)
				$write(" %08h\n", data);
			else
				$write(" %08h", data);				
		end
		
	if ((i & 7) != 7)
		$write("\n");
endtask

task FmcBus::printAllRegs();
	automatic logic [15:0] data;
	automatic int i;

	$display("Print all registors:");
	for (i = 0; i < 'h1E0 >> 1; i++)
		begin
			read(i << 1, data, 0);
			
			if ((i & 7) == 0)
				$write("%02h: %04h", i << 1, data);
			else if ((i & 7) == 7)
				$write(" %04h\n", data);
			else
				$write(" %04h", data);				
		end
		
	if ((i & 7) != 7)
		$write("\n");
endtask

//task FmcBus::SoftReset();
//	$display("Soft reset");		
//	write(ADDR::CONTROL, 1<<0);
//endtask

task FmcBus::printVersion();
	automatic logic [31:0] data;
	
	read32(ADDR::VER32, data);
	$display("VER_TYPE: %h FAC_VER: %d.%d VER: %d.%d", data[31:30], data[29:24], data[23:16], data[15:8], data[7:0]);
endtask

//task FmcBus::IrqMask(bit[15:0] mask);
//	automatic logic [15:0] value;
//	
//	$display("set IRQ mask %04h", mask);
//	write(ADDR::IRQ, mask);
//
//	read(ADDR::IRQ, value);
//	
//	assert (value == mask)
//	else begin
//		$display("IRQ mask error %04h", value);
//		$stop(2);
//	end
//endtask
//
//task FmcBus::IrqEna();
//	IrqMask(~16'h0);
//endtask
//
//task FmcBus::IrqDis();
//	IrqMask(16'h0);
//endtask

task FmcBus::setOE(bit oe);
	write(ADDR::MTR_OE, oe);
endtask

task FmcBus::getOE(output logic oe);
	automatic logic [15:0] data;	
	read(ADDR::MTR_OE, data);
	oe = data[0];
endtask

task FmcBus::getRun(output logic [15:0] run);
	read(ADDR::MTR_WRREQ, run);
endtask

task FmcBus::getWrreq(output logic [7:0] wrreq);
	automatic logic [15:0] run;
	getRun(run);
	wrreq = run[7:0];
endtask

task FmcBus::getReady(output logic ready);
	automatic logic [7:0] wrreq;
	getWrreq(wrreq);
	ready = wrreq == 0;
endtask

task FmcBus::waitReady();
	automatic logic ready = 0;
	while (!ready)
		getReady(ready);
endtask

task FmcBus::waitStop();
	automatic logic [15:0] run = '1;
	while (run != 0)
		getRun(run);
endtask

task FmcBus::step(int i, int N, int T);
	write32(ADDR::NT32 + 8 * i, N);
	write32(ADDR::NT32 + 4 + 8 * i, T);	
	write(ADDR::MTR_WRREQ, 1<<i);
endtask

task FmcBus::setTimeout(int unsigned T);
	write32(ADDR::TIMEOUT32, T);
endtask

task FmcBus::getTimeout(output logic [31:0] T);
	read32(ADDR::TIMEOUT32, T);
endtask

task FmcBus::setTScale(int unsigned T);
	write(ADDR::T_SCALE, T);
endtask

task FmcBus::getTScale(output logic [15:0] T);
	read(ADDR::T_SCALE, T);
endtask

task FmcBus::globalSnapshot();
	write(ADDR::MTR_CONTROL, 4);
endtask

// ADC
task FmcBus::setThld(bit [15:0] low, bit [15:0] high);
	write(ADDR::LOW_THLD, low);
	write(ADDR::HIGH_THLD, high);
endtask

task FmcBus::enableFeedback(bit ena);
	write(ADDR::FB_ENA, ena);
endtask

task FmcBus::setSoftPermit(bit ena);
	write(ADDR::SOFT_PERMIT, ena);
endtask

task FmcBus::irqEna(bit enable);
	write(ADDR::IRQ_MASK, {16{enable}});
endtask

task FmcBus::waitFilterReady();
	automatic logic [15:0] data;
	data = '1;
	
	while (data[3]) // Filters are not ready
		read(ADDR::STATUS, data);
endtask

task FmcBus::setIndicator(input bit [15:0] value);
	write(ADDR::IND, value);
endtask

task FmcBus::getIndicator(output logic [15:0] value);
	read(ADDR::IND, value);
endtask

task FmcBus::getIndicatorOld(output logic [15:0] value);
	read(ADDR::IND_OLD, value);
endtask

task FmcBus::getKeysLevel(output logic [15:0] value);
	read(ADDR::KEY32_LEVEL, value);
endtask
	
task FmcBus::getKeys(output logic [15:0] value);
	read(ADDR::KEY32, value);
endtask

task FmcBus::getKeysDown(output logic [15:0] value);
	read(ADDR::KEY32_DOWN, value);
endtask

task FmcBus::clearKeysDown(input bit [15:0] value);
	write(ADDR::KEY32_DOWN, value);
endtask

task FmcBus::setControls(input bit [47:0] value);
	write(ADDR::CTRL48, value[15:0]);
	write(ADDR::CTRL48 + 2, value[31:16]);
	write(ADDR::CTRL48 + 4, value[47:32]);
endtask

task FmcBus::getControls(output logic [47:0] value);
	read(ADDR::CTRL48, value[15:0]);
	read(ADDR::CTRL48 + 2, value[31:16]);
	read(ADDR::CTRL48 + 4, value[47:32]);
endtask

task FmcBus::getControlsOld(output logic [47:0] value);
	read(ADDR::CTRL48_OLD, value[15:0]);
	read(ADDR::CTRL48_OLD + 2, value[31:16]);
	read(ADDR::CTRL48_OLD + 4, value[47:32]);
endtask

task FmcBus::setLimSwitchMask(input bit [15:0] value);
	write(ADDR::LIM_SWITCH_MASK, value);
endtask

task FmcBus::getLimSwitchMask(output logic [15:0] value);
	read(ADDR::LIM_SWITCH_MASK, value);
endtask

task FmcBus::clearLimSwitch();
	write(ADDR::LIM_SWITCH_FLAG, 16'h003F);
endtask

// i = 0, 1, 2
task FmcBus::getEncoder(unsigned i, output logic [31:0] value);
	read32(ADDR::ENC32 + (i << 3), value);
endtask

`endif
