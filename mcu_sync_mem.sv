`ifndef _main_
`define _main_


module mcu_sync_mem(
	input aclr, clk,
	input ne, nadv, nwe, noe,
	output nwait,
	inout [15:0] ad,
	input nbl,
	
	output [15:0] addr,
	output write,
	input [15:0] rddata,
	output [15:0] wrdata
);

	assign nwait = 1'b1;
	
	reg cs = 1'b0, a_valid = 1'b0, we = 1'b0, wrframe = 1'b0;
	reg [15:0] wrdata;
	
	assign ad = (!ne && !noe) ? rddata : 16'hZ;
	
	always_ff @(posedge clk, posedge aclr) begin
		we <= (aclr) ? 1'b0 : !nwe;
		cs <= (aclr) ? 1'b0 : !ne;
		wrframe <= (aclr) ? 1'b0 : !nbl;
	end
	
	always_ff @(posedge clk)
		wrdata <= ad;
	
	//
	always_ff @(negedge clk, posedge aclr) begin
		adv_reg <= (aclr) ? 1'b0 : !nadv;

	always_ff @(posedge clk, posedge aclr) begin
		a_valid <= (aclr) ? 1'b0 : a_valid_reg;	
	
	always_ff @(negedge clk)
		ad_reg <= ad;
		
	always_ff @(posedge clk)
		if (adv_reg) base_addr <= ad_reg;
	
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
		
		else
			

endmodule :mcu_main

`endif
