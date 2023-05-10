`ifndef _enc_bus_
`define _enc_bus_
`include "rot_enc_zero.sv"

module enc_bus #(parameter
	BAR = 'h0,
	MASK = 'h7F
)(
	input clk, aclr, sclr,
	input [15:0] rdaddr, wraddr,
	input [1:0] be,
	input write,
	input [15:0] wrdata,
	output reg [15:0] rddata,
	
	input [7:0] enc_A, enc_B, enc_Z,
	
	input global_snapshot,
	output [1:0] enc_changed,
	
	output [1:0] imit_enc_clr
);
	wire rdhit = (rdaddr & ~MASK) == BAR;
	wire wrhit = (wraddr & ~MASK) == BAR;
	
	wire [15:0] l_rdaddr = rdaddr & MASK[15:0];
	wire [15:0] l_wraddr = wraddr & MASK[15:0];

	wire signed [7:0][31:0] enc_pos, Z_pos;
	reg signed [7:0][31:0] enc_snap, Z_snap;
	reg [7:0] enc_clr = '0, flag = '0, flag_clr = '0;
	reg l_snapshot = 1'b0;
	reg [7:0] dir = '0, ena = '1;
	
	assign imit_enc_clr = enc_clr[1:0];
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			begin
				ena <= '1;
				dir <= '0;				
			end
		else if (sclr)
			begin
				ena <= '1;
				dir <= '0;				
			end			
		else if (write && wrhit)
			case (l_wraddr)
				'h4:	begin
							if (be[0]) ena <= wrdata[7:0];
						end
				'h6:	begin
							if (be[0]) dir <= wrdata[7:0];
						end
			endcase
	
	always_ff @(posedge clk) begin		
		flag_clr		<= {8{write && wrhit && l_wraddr == 'h0 && be[0]}} & wrdata[7:0];
		enc_clr		<= {8{write && wrhit && l_wraddr == 'h0 && be[1]}} & wrdata[15:8];
		l_snapshot	<= write && wrhit && l_wraddr == 'h8 && be[0] & wrdata[0];
	end
	
	wire [7:0] error, ready;
	
	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			rddata <= '0;
		else if (sclr)
			rddata <= '0;
		else if (rdhit)
			if (l_rdaddr < 16'h40)
				case (l_rdaddr)
					'h0: rddata <= {8'h0, flag};
					'h2: rddata <= {error, ~ready};
					'h4: rddata <= {8'h0, ena};
					'h6: rddata <= {8'h0, dir};					
					
					default: rddata <= '0;
				endcase
			else
				if (l_rdaddr[2] == 1'b0)
					rddata <= l_rdaddr[1] ? enc_snap[l_rdaddr[5:3]][31:16] : enc_snap[l_rdaddr[5:3]][15:0];
				else
					rddata <= l_rdaddr[1] ? Z_snap[l_rdaddr[5:3]][31:16] : Z_snap[l_rdaddr[5:3]][15:0];
		else
			rddata <= '0;

	wire [7:0] l_enc_changed;
	assign enc_changed = l_enc_changed[1:0];
	
	genvar i;
	
	generate for (i = 0; i < 8; i++)
		begin :encoders
			always_ff @(posedge clk, posedge aclr)
				if (aclr)
					flag[i] <= 1'b0;
				else if (sclr || enc_clr[i] || flag_clr[i])
					flag[i] <= 1'b0;
				else if (l_enc_changed[i])
					flag[i] <= 1'b1;
			
			rot_enc_zero encoder(
				.clock(clk),
				.sclr(enc_clr[i] || sclr),
				.ena(ena[i]),
				.dir(dir[i]),
				.A(enc_A[i]), .B(enc_B[i]), .Z(enc_Z[i]),
				.bidir_counter(enc_pos[i]),
				.error(error[i]),
				.ready(ready[i]), // counter enabled
				
				.Z_pos(Z_pos[i]),
				.Z_flag(),
				.Z_clr(1'b0),
				
				.addr(l_wraddr[1]),
				.be,
				.write(write && wrhit && l_wraddr >= 'h40 && l_wraddr[2] == 1'b0 && l_wraddr[5:3] == i),
				.data(wrdata),
				
				.enc_changed(l_enc_changed[i])
			);
			
		always_ff @(posedge clk, posedge aclr)
			if (aclr)
				begin
					enc_snap[i] <= '0;
					Z_snap[i] <= '0;
				end
			else if (enc_clr[i] || sclr)
				begin
					enc_snap[i] <= '0;
					Z_snap[i] <= '0;
				end
			else if (global_snapshot || l_snapshot)
				begin
					enc_snap[i] <= enc_pos[i];
					Z_snap[i] <= Z_pos[i];
				end
		end
	endgenerate
	
endmodule :enc_bus

`include "step_dir_cnt.sv"


`endif
