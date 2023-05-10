`ifndef _ad_adc_
`define _ad_adc_

`include "header.sv"
`include "adc.sv"
`include "ram_2port_init.sv"
`include "ram_2port_be_init.sv"

module ad_adc #(parameter
	ADC_NUM = 2,
	OSR_WIDTH = 16,
	SHIFT_WIDTH = 5,
	SCALE_WIDTH = 32,
	OFFSET_WIDTH = SCALE_WIDTH - 2,
	ADC_NUM_WIDTH = `GET_WIDTH(ADC_NUM),
	
	bit [OSR_WIDTH-1:0] OSR_MAX = '1,
	bit [OSR_WIDTH-1:0] OSR_MIN = 'd15,
	bit [SHIFT_WIDTH-1:0] SHIFT_MAX = '1,
	bit [SCALE_WIDTH-1:0] SCALE_MAX = {1'b1, {(SCALE_WIDTH-1){1'b0}}},
	bit signed [OFFSET_WIDTH-1:0] OFFSET_MAX = {1'b0, {(OFFSET_WIDTH-1){1'b1}}},
	bit signed [OFFSET_WIDTH-1:0] OFFSET_MIN = ~OFFSET_MAX,
	
	bit [OSR_WIDTH-1:0]				OSR_DEFAULT		= OSR_WIDTH'(5_000 - 1), // 20 MHz / 5000 = 4 kHz
	bit [SHIFT_WIDTH-1:0]			SHIFT_DEFAULT	= SHIFT_WIDTH'(14),
	bit [SCALE_WIDTH-1:0]			SCALE_DEFAULT	= SCALE_MAX,
	bit signed [OFFSET_WIDTH-1:0]	OFFSET_DEFAULT	= 'sh0
)(
	input aclr, clk,
	input [9:0] addr,
	input [15:0] wrdata,
	output reg [15:0] rddata,
	input write,
	output reg irq_n,
	
	input sample, // sample by raise edge
	// Sigma-delta ADC
	input adc_clk,
	input [15:0] adc_sdi	
);
	reg l_aclr = 1'b1;
	
	reg [ADC_NUM-1:0][OSR_WIDTH-1:0] osr;
	
	reg [15:0] irq_mask = '0;
	reg test_ena = 1'b0;
	reg test_sdi = 1'b1;
	reg run = 1'b1;
	
	reg [31:0] wrdata32;
	wire [31:0] rddata32;
	wire wrbusy, rdvalid;
	
	reg [3:0] error = '0;
	reg err_clr = 1'b1;
	
	always_ff @(posedge clk, posedge l_aclr)
		if (l_aclr)
			begin
				osr		<= {ADC_NUM{OSR_DEFAULT}};
				irq_mask	<= '0;
				test_ena <= 1'b0;
				test_sdi <= 1'b1;
				run		<= 1'b1;
				csr_wrdata_l <= '0;
				wrdata32	<= '0;
				addr32	<= '0;
			end
		else if (write)
			if (addr >= 'h20 && addr < 'h30)
				osr[addr[0]] <= (wrdata > 16'(OSR_MAX)) ? OSR_MAX : ( (wrdata < 16'(OSR_MIN)) ? OSR_MIN : wrdata[OSR_WIDTH-1:0] );
			else
				case (addr)
					10'h80:
						if (wrdata[3])
							run <= 1'b0;
						else if (wrdata[2])
							run <= 1'b1;
				
					10'h82: irq_mask <= wrdata;				
					10'h83: test_ena <= wrdata[0];
					10'h84: test_sdi <= wrdata[0];
					
					10'h98: wrdata32[15:0] <= wrdata;
					10'h99: wrdata32[31:16] <= wrdata;
					10'h9A: addr32[16:8] <= wrdata[8:0];				
				endcase

	always_ff @(posedge clk, posedge aclr)
		l_aclr <= (aclr) ? 1'b1 : addr == 10'h80 && write && wrdata[0];
			
	always_ff @(posedge clk, posedge l_aclr) begin
		err_clr	<= (l_aclr) ? 1'b1 : addr == 10'h80 && write && wrdata[4];
	end
	
	wire [ADC_NUM-1:0] adc_sync	= {16{addr == 10'h85 && write}} & wrdata;
	wire [ADC_NUM-1:0] soft_smp	= {16{addr == 10'h89 && write}} & wrdata;
	
	wire [ADC_NUM-1:0] empty;
	wire [ADC_NUM-1:0][31:0] q;
	
	wire [ADC_NUM_WIDTH-1:0] adc_addr;
	wire [SHIFT_WIDTH-1:0] shift_q, adc_shift_q;
	wire [SCALE_WIDTH-1:0] scale_q, adc_scale_q;
	wire signed [OFFSET_WIDTH-1:0] offset_q, adc_offset_q;
	
	always_ff @(posedge clk)
		if (addr < 10'h20)
			rddata <= (addr[0]) ? q[addr[4:1]][31:16] : q[addr[4:1]][15:0];
		else if (addr < 10'h30)
			rddata <= 16'(osr[addr[3:0]]);
		else if (addr < 10'h40)
			rddata <= 16'(shift_q);
		else if (addr < 10'h60)
			rddata <= (addr[0]) ? 16'(scale_q[SCALE_WIDTH-1:16]) : scale_q[15:0];
		else if (addr < 10'h80)
			rddata <= (addr[0]) ? 16'sh0 + signed'(offset_q[OFFSET_WIDTH-1:16]) : offset_q[15:0];
		else
			case (addr)				
				10'h81: rddata <= 16'({error, 1'b0, run, 2'b0});
				10'h82: rddata <= irq_mask;
				10'h83: rddata <= 16'(test_ena);
				10'h84: rddata <= 16'(test_sdi);
				
				10'h88: rddata <= empty;
				
				10'h98: rddata <= wrdata32[15:0];
				10'h99: rddata <= wrdata32[31:16];
				10'h9A: rddata <= addr32[16:8];
				10'h9B: rddata <= {6'h0, wrbusy, rdvalid, 8'h0};
				10'h9C: rddata <= rddata32[15:0];
				10'h9D: rddata <= rddata32[31:16];
				
				default: rddata <= '0;
			endcase
	
	reg [2:0] sample_reg = '0;
	reg [15:0] sample_clk = '0;
	
	always_ff @(posedge clk, posedge l_aclr)
		begin
			sample_reg <= (l_aclr) ? '0 : {sample_reg[1:0], sample};
			sample_clk <= (l_aclr) ? '0 : {16{sample_reg[2:1] == 2'b01}} | soft_smp;
		end
	
	wire shift_write			= write && addr >= 'h30 && addr < 'h40;
	wire [3:0] shift_addr	= addr[3:0];
	wire [15:0] shift_data	= wrdata;
	
	ram_2port #(.DATA_WIDTH(SHIFT_WIDTH), .ADDR_WIDTH(ADC_NUM_WIDTH)) shift_ram(
		.clk_a(		clk									),
		.write_a(	shift_write							),
		.addr_a(		shift_addr							),
		.data_a(		shift_data[SHIFT_WIDTH-1:0]	),
		.q_a(			shift_q								),
		
		.clk_b(adc_clk), .addr_b(adc_addr), .q_b(adc_shift_q)
	);
	
	wire scale_write				= write && addr >= 'h40 && addr < 'h60;
	wire [3:0] scale_addr		= addr[4:1];
	wire [3:0] scale_be			= addr[0] ? 4'b1100 : 4'b0011;
	wire [31:0] scale_data		= {wrdata, wrdata};
	
	ram_2port_be #(.DATA_WIDTH(SCALE_WIDTH), .ADDR_WIDTH(ADC_NUM_WIDTH)) scale_ram(
		.clk_a(		clk									),
		.write_a(	scale_write							),
		.addr_a(		scale_addr							),
		.be_a(		scale_be								),
		.data_a(		scale_data[SCALE_WIDTH-1:0]	),
		.q_a(			scale_q								),
		
		.clk_b(adc_clk), .addr_b(adc_addr), .q_b(adc_scale_q)
	);
	
	wire offset_write				= write && addr >= 'h60 && addr < 'h80;
	wire [3:0] offset_addr		= addr[4:1];
	wire [3:0] offset_be			= addr[0] ? 4'b1100 : 4'b0011;
	wire [31:0] offset_data		= {wrdata, wrdata};
	
	wire offset_write_h = offset_write && offset_be[3:2] == '1;
	
	ram_2port_be #(.DATA_WIDTH(OFFSET_WIDTH), .ADDR_WIDTH(ADC_NUM_WIDTH)) offset_ram(
		.clk_a(		clk									),
		.write_a(	offset_write						),
		.addr_a(		offset_addr							),
		.be_a(		offset_be							),
		.data_a(		offset_data[OFFSET_WIDTH-1:0]	),
		.q_a(			offset_q								),
		
		.clk_b(adc_clk), .addr_b(adc_addr), .q_b(adc_offset_q)
	);
	
	wire scale_err;
	adc #(.ADC_NUM(ADC_NUM), .OSR_WIDTH(OSR_WIDTH), .SHIFT_WIDTH(SHIFT_WIDTH), .SCALE_WIDTH(SCALE_WIDTH)) adc_inst(
		.aclr(l_aclr),
		.adc_clk, .adc_sdi(test_ena ? {ADC_NUM{test_sdi}} : adc_sdi),
		
		.clk, .sclr(!run),
		.adc_sync,
		.osr,
		
		.addr(adc_addr), .shift_q(adc_shift_q), .scale_q(adc_scale_q), .offset_q(adc_offset_q),
		
		.empty, .sample_clk, .q,
		
		.scale_err
	);
	
	always_ff @(posedge clk, posedge l_aclr)
		irq_n <= (l_aclr) ? 1'b1 : !(irq_mask & ~empty);
	
endmodule :ad_adc

`endif
