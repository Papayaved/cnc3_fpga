`ifndef _motor_bus_
`define _motor_bus_


module motor_bus @(parameter
	BAR = 'h0,
	MASK = 'hF
)(
	input clk, aclr, sclr,
	input [15:0] addr,
	input [1:0] be,
	input write,
	input [15:0] wrdata,
	output [15:0] rddata,
	
	
);

	always_ff @(posedge clk, posedge aclr)
		if (aclr)
			begin
				T			<= {8{~32'h0}};
				N			<= {8{32'h0}};				
				main_dir	<= '0;
				phase_ena <= 1'b1;
				slow_dato <= '0;
			end
		else if (sclr)
			begin
				T			<= {8{~32'h0}};
				N			<= {8{32'h0}};				
				main_dir	<= '0;
				phase_ena <= 1'b1;
				slow_dato <= '0;
			end
		else if (write)
			if (addr < 'h40)
				;
			else if (addr < 'h80)
				;
			else if (addr < 'hC0)
				if (addr[2] == 1'b0)
					begin
						if (addr[0] == 1'b0 && be[0]) T[addr[3:1]][7:0] <= wrdata[7:0];
						if (addr[0] == 1'b0 && be[1]) T[addr[3:1]][15:8] <= wrdata[15:8];
						if (addr[0] == 1'b1 && be[0]) T[addr[3:1]][23:16] <= wrdata[7:0];
						if (addr[0] == 1'b1 && be[1]) T[addr[3:1]][31:24] <= wrdata[15:8];
					end
				else
					begin
						if (addr[0] == 1'b0 && be[0]) N[addr[3:1]][7:0] <= wrdata[7:0];
						if (addr[0] == 1'b0 && be[1]) N[addr[3:1]][15:8] <= wrdata[15:8];
						if (addr[0] == 1'b1 && be[0]) N[addr[3:1]][23:16] <= wrdata[7:0];
						if (addr[0] == 1'b1 && be[1]) N[addr[3:1]][31:24] <= wrdata[15:8];
					end
			else if (addr < 'h100)
				case (addr)
					'hC2:	begin
								if (be[0]) main_dir <= wrdata[7:0];
								if (be[1]) phase_ena <= wrdata[8];
							end
					'hC4:	begin
								if (be[0]) slow_dato <= wrdata[7:0];
								if (be[1]) slow_dato <= wrdata[15:8];
							end
				endcase