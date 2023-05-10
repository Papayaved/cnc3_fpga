`ifndef _ctrl_bus_
`define _ctrl_bus_

`include "header.sv"

`include "sipo.sv"
`include "piso.sv"
`include "keyboard.sv"

module ctrl_bus #(parameter
	KEYS = 32,	
	BAR = 'h0,
	MASK = 'h1F
)(
	input clk, aclr,
	output reg sclr,
	
	input [15:0] addr,
	input [1:0] be,
	input write,
	input [15:0] wrdata,
	output reg [15:0] rddata,
	output reg nirq,
	
	output kb_sclk, kb_load,
	input kb_sdi,
	
	output slow_out_sclk, slow_out_sdo, slow_out_lock,
	output slow_in_sclk, slow_in_load_n,
	input slow_in_sdi,
	
	input [3:0] hv_code, hv_update,
	output [1:0] ls // limit switch
);
	reg [11:0] slow_dato = '0;
	reg [3:0] flag = '0, irq_mask = '0;
	wire [3:0] flag_set, flag_clr;

	task reset();
		slow_dato <= '0;
	endtask
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			reset();
		else if (sclr)
			reset();
		else if (write && (addr & ~MASK) == BAR)
			case (addr & MASK)
				'h2: irq_mask <= wrdata[3:0];
				
				'h8:	begin
							if (be[0]) slow_dato <= wrdata[7:0];
							if (be[1]) slow_dato <= wrdata[11:8];
						end
			endcase
	
	reg slow_wrreq = 1'b0;	
	
	assign flag_clr = (write && (addr & ~MASK) == BAR && (addr & MASK) == 'h0 && be[0]) & wrdata[3:0]; // ?
	
	always_ff @(posedge clk, posedge aclr) begin
		sclr			<= aclr ? 1'b1 : write && (addr & ~MASK) == BAR && (addr & MASK) == 'h4 && be[0] && wrdata[0];
		slow_wrreq	<= aclr ? 1'b0 : write && (addr & ~MASK) == BAR && (addr & MASK) == 'h8 && |be;
	end
	
	
	
	wire [15:0] slow_dati;
	wire [KEYS-1:0] key;
	reg [KEYS-1:0] key_reg = '0;
	wire key_clicked;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			rddata <= '0;
		else if (sclr)
			rddata <= '0;
		else if ((addr & ~MASK) == BAR)
			case (addr & MASK)
				'h0: rddata <= flag;
				'h2: rddata <= irq_mask;
				
				'h8: rddata <= '{slow_dato};
//				'hA: rddata <= slow_dato[31:16];
				'hC: rddata <= slow_dati[15:0];
//				'hE: rddata <= slow_dati[31:16];
				'h10: rddata <= key[15:0];
				'h12: rddata <= key[31:16];
				
				'h1C: rddata <= {`VER, `REV};
				'h1E: rddata <= {`VER_TYPE, `FAC_VER, `FAC_REV};
				
				default: rddata <= '0;
			endcase
		else
			rddata <= '0;
	
	// Slow inputs
	sipo_reg #(.WIDTH(16), .CLK_DIV(10)) sipo_inst(
		.clk, .aclr, .sclr,
		.sdi(slow_in_sdi), .sclk(slow_in_sclk), .load_n(slow_in_load_n),	
		.data(slow_dati)
	);
	
	// Slow outputs
	piso_reg #(.WIDTH(16), .CLK_DIV(10)) piso_inst(
		.clk, .aclr, .sclr,
		.data({slow_dato, hv_code}),
		.we(hv_update || slow_wrreq),
		.sclk(slow_out_sclk), .sdo(slow_out_sdo), .lock(slow_out_lock)
	);
	
	// Keyboard
	keyboard #(.NUM(KEYS), .CLK_DIV(100)) kb_inst(
		.clk, .aclr, .sclr,
		.sdi(kb_sdi), .sclk(kb_sclk), .load_n(kb_load),
		.key
	);
	
	always_ff @(posedge clk, posedge aclr)
		key_reg <= aclr ? '0 : sclr ? '0 : key;
	
	assign key_clicked = key != key_reg;
	
	assign ls[1:0] = slow_dati[1:0];
	
	assign flag_set[0] = key_clicked;
	assign flag_set[3:1] = ls;
	
	genvar i;
	
	generate for (i = 0; i < 4; i++)
		begin :gen_flags
			always @(posedge clk, posedge aclr)
				if (aclr)
					flag[i] <= 1'b0;
				else if (sclr || flag_clr[i])
					flag[i] <= 1'b0;
				else if (flag_set[i])
					flag[i] <= 1'b1;
		end
	endgenerate
			
	
	always @(posedge clk, posedge aclr)
		nirq <= aclr ? 1'b1 : sclr ? 1'b1 : !( |(flag & irq_mask) );

endmodule :ctrl_bus

`endif
