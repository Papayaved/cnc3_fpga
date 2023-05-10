`ifndef _hv_bus_
`define _hv_bus_
`include "pwm.sv"

module hv_bus#(parameter
	BAR = 'h0,
	MASK = 'h1F
)(
	input clk, aclr, sclr,
	input [15:0] rdaddr, wraddr,
	input [1:0] be,
	input write,
	input [15:0] wrdata,
	output reg [15:0] rddata,
	
	input ls, // limit switch
	output hv_pwm,
	output [3:0] hv_code,
	output reg hv_update
//	input code_uploaded	
);
	wire rdhit = (rdaddr & ~MASK) == BAR;
	wire wrhit = (wraddr & ~MASK) == BAR;
	
	wire [15:0] l_rdaddr = rdaddr & MASK[15:0];
	wire [15:0] l_wraddr = wraddr & MASK[15:0];

	reg [31:0] per = '0, per_reg = '0;
	reg [1:0][31:0] t = '0, t_reg = '0;
	reg [3:0] code = '0, code_reg = '0;
	reg ena = 1'b0, inv = 1'b0;
	reg update_req = 1'b0;
	wire load;
	
	task reset();
		per <= '0;
		t <= '0;
		inv = 1'b0;
	endtask
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			reset();
		else if (sclr)
			reset();
		else if (write && wrhit)
			case (l_wraddr)
				'h0:	begin
							if (be[0]) per[7:0] <= wrdata[7:0];
							if (be[1]) per[15:8] <= wrdata[15:8];
						end
				'h2:	begin
							if (be[0]) per[23:16] <= wrdata[7:0];
							if (be[1]) per[31:24] <= wrdata[15:8];
						end
				'h4:	begin
							if (be[0]) t[0][7:0] <= wrdata[7:0];
							if (be[1]) t[0][15:8] <= wrdata[15:8];
						end
				'h6:	begin
							if (be[0]) t[0][23:16] <= wrdata[7:0];
							if (be[1]) t[0][31:24] <= wrdata[15:8];
						end
				'h8:	begin
							if (be[0]) t[1][7:0] <= wrdata[7:0];
							if (be[1]) t[1][15:8] <= wrdata[15:8];
						end
				'hA:	begin
							if (be[0]) t[1][23:16] <= wrdata[7:0];
							if (be[1]) t[1][31:24] <= wrdata[15:8];
						end				
				'hC:	if (be[0]) code <= wrdata[3:0];
				
				'h12:	if (be[0]) inv <= wrdata[0];
			endcase
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			update_req <= 1'b0;
		else if (write && wrhit && l_wraddr == 'hE && be[0])
			update_req <= wrdata[0];
		else if (load)
			update_req <= 1'b0;
			
	wire ena_change = write && wrhit && l_wraddr == 'h10 && be[0];
		
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			begin
				per_reg <= '0;
				t_reg <= '0;
			end
		else if (update_req && load)
			begin
				per_reg <= per;
				t_reg <= t;
			end
	
	// todo: wait code upload 
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			code_reg <= '0;
		else if (sclr || ls)
			code_reg <= '0;
		else if (update_req && load)
			code_reg <= code;
			
	assign hv_code = code_reg;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			ena <= 1'b0;
		else if (sclr || ls)
			ena <= 1'b0;
		else if (ena_change)
			ena <= wrdata[0];
	
	always_ff @(posedge clk)
		if (rdhit)
			case (l_rdaddr)
				'h0: rddata <= per_reg[15:0];
				'h2: rddata <= per_reg[31:16];
				'h4: rddata <= t_reg[0][15:0];
				'h6: rddata <= t_reg[0][31:16];
				'h8: rddata <= t_reg[1][15:0];
				'hA: rddata <= t_reg[1][31:16];
				'hC: rddata <= 16'(hv_code);
				'hE: rddata <= {15'h0, update_req};
				
				'h10: rddata <= {15'h0, ena};
				'h12: rddata <= {15'h0, inv};
				default: rddata <= '0;
			endcase
		else
			rddata <= '0;

	pwm #(32) pwm_inst(.clk, .aclr, .sclr(!ena || sclr || !ena), .per(per_reg), .t(t_reg), .inv, .load, .q(hv_pwm));
	
	reg ls_reg = 1'b0;
	
	always_ff @(posedge clk)
		ls_reg <= aclr ? 1'b0 : ls;
	
	always_ff @(posedge clk, posedge aclr)
		hv_update <= aclr ? 1'b1 : sclr || update_req && load || ena_change || (ls ^ ls_reg);
			

endmodule :hv_bus

`endif
