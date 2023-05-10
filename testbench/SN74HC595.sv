`ifndef _SN74HC595_
`define _SN74HC595_

module SN74HC595(
	input oen, rclk, srclrn, srclk, ser,
	output [7:0] q,
	output d_out7
);
	
	reg [7:0] data = '0;
	assign d_out7 = data[7];
	
	always_ff @(posedge srclk, negedge srclrn)
		if (!srclrn)
			data <= '0;
		else
			data <= {data[6:0], ser};
	
	reg [7:0] q_reg = 0;
	
	always_ff @(posedge rclk)
		q_reg <= data;
		
	assign q = oen ? 8'hz : q_reg;

endmodule :SN74HC595

module SN74HC595_2x(
	input lock, sclk, sdo,
	output sdi,
	output [15:0] q
);

	wire d_out7;
	
	SN74HC595 SN74HC595_inst0(
		.oen(1'b0), .rclk(lock), .srclrn(1'b1), .srclk(sclk), .ser(sdo),
		.q(q[7:0]), .d_out7(d_out7)
	);
	
	SN74HC595 SN74HC595_inst1(
		.oen(1'b0), .rclk(lock), .srclrn(1'b1), .srclk(sclk), .ser(d_out7),
		.q(q[15:8]), .d_out7(sdi)
	);
	
endmodule :SN74HC595_2x

module SN74HC595_N #(parameter
	N = 6
)(
	input lock, sclk, sdo,
	output sdi,
	output [8 * N - 1:0] q
);

	wire [N-1:0] d_out7;
	
	genvar i;
	
	generate for (i = 0; i < N; i++)
		begin	:gen
			SN74HC595 SN74HC595_inst0(
				.oen(1'b0), .rclk(lock), .srclrn(1'b1), .srclk(sclk), .ser(i == 0 ? sdo : d_out7[i - 1]),
				.q(q[(8 * (i + 1) - 1) : (8 * i)]), .d_out7(d_out7[i])
			);
		end
	endgenerate
	
	assign sdi = d_out7[N - 1];
	
endmodule :SN74HC595_N

`endif
