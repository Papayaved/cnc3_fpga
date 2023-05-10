`ifndef _mcu_amux_mem_
`define _mcu_amux_mem_

module mcu_amux_mem(
	input clk, aclr,
	
	input ne, noe, nwe, nadv,
	input [1:0] nbl,
	inout [15:0] ad,
	
	output [15:0] wraddr,
	output [15:0] rdaddr,
	output reg [1:0] be,
	output reg write,
	input [15:0] rddata,
	output reg [15:0] wrdata
);

	assign ad = (!ne && !noe) ? rddata : 16'hZ;
	
	reg [1:0] cs, adv, we;
	reg [1:0][1:0] bl;
	reg [1:0][15:0] ad_reg;
	reg [14:0] addr16, wraddr16;
	
	always_ff @(posedge clk, posedge aclr) begin
		cs			<= (aclr) ? 2'h0			: {cs[0], !ne};
		adv		<= (aclr) ? 2'h0			: {adv[0], !nadv};
		we			<= (aclr) ? 2'h0			: {we[0], !nwe};
		bl			<= (aclr) ? {2{2'h0}}	: {bl[0], ~nbl};
		ad_reg	<= (aclr) ? {2{16'h0}}	: {ad_reg[0], ad};
	end
	
	wire _write = we[1] && cs[1];
	
	always_ff @(posedge clk, posedge aclr) begin
		if (aclr)
			addr16 <= '0;
		else if (adv[1])
			addr16 <= ad_reg[1][14:0]; // last
		
		if (aclr)
			begin
				wrdata <= '0;
				wraddr16 <= '0;
				be <= '0;
			end
		else if (_write)
			begin // last
				wrdata <= ad_reg[1];
				wraddr16 <= addr16;
				be <= bl[1];
			end
	end

	reg write_reg;
	always_ff @(posedge clk, posedge aclr)
		write_reg <= (aclr) ? 1'b0 : _write;
	
	always_ff @(posedge clk, posedge aclr)
		write <= (aclr) ? 1'b0 : write_reg && !_write;
		
	assign rdaddr = {addr16, 1'b0};
	assign wraddr = {wraddr16, 1'b0};
	
endmodule :mcu_amux_mem

`endif
