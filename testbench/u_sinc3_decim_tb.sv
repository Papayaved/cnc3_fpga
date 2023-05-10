timeunit 1ns;
timeprecision 1ns;
`include "sd_mod.sv"

module u_sinc3_decim_tb #(parameter TEST = 2);
	localparam OSR_WIDTH = 16;	
	localparam RES_WIDTH = 3 * OSR_WIDTH;

	bit aclr = 1;
	// Sigma-delta ADC
	bit clock = 0, sdi = 0;
	bit [OSR_WIDTH-1:0] osr;
	wire [RES_WIDTH-1:0] data;
	wire valid;
	
	int fin, fout, res;
	
	localparam REF_WIDTH = 16;
	localparam signed [REF_WIDTH-1:0] VREF = {1'b0, {(REF_WIDTH-1){1'b1}}};
	bit signed [REF_WIDTH-1:0] V = 0;
	
	always #25ns clock++;
	
	initial begin
		fout <= $fopen("adc.txt", "w");
		
		if (TEST == 1)
			begin
				$display("MIN MAX TEST");
				
				osr = 399;
				aclr = 1;
				repeat(10) @(posedge clock);
				aclr = 0;
				repeat(10) @(posedge clock);
				
				V = -VREF;
				#(2 * 25ns * (osr + 1) * 20);
				$display("MIN VALUE %d", data);
				
				V = VREF;
				#(2 * 25ns * (osr + 1) * 20);
				$display("MAX VALUE %d", data);
				
				osr = 99;
				aclr = 1;
				repeat(10) @(posedge clock);
				aclr = 0;
				repeat(10) @(posedge clock);
				
				V = -VREF;
				#(2 * 25ns * (osr + 1) * 20);
				$display("MIN VALUE %d", data);
				
				V = VREF;
				#(2 * 25ns * (osr + 1) * 20);
				$display("MAX VALUE %d", data);
			end
		else if (TEST == 2)
			begin
				$display("SAW TEST");

				osr = 399;
				aclr = 1;
				repeat(10) @(posedge clock);
				aclr = 0;
				repeat(10) @(posedge clock);
				
				V = 0;
				fork
					begin :block
						forever #(2 * 25ns * (osr + 1)) V += VREF/100;
					end
					
					#(2 * 25ns * (osr + 1) * 100 * 5);
				join_any
				
				disable block;
				
				$display("MIN MAX TEST");
				
				V = -VREF;
				#(2 * 25ns * (osr + 1) * 100);
				$display("MIN VALUE %d", data);				
				
				V = VREF;
				#(2 * 25ns * (osr + 1) * 100);
				$display("MAX VALUE %d", data);
			end
		else
			begin
				$display("FILE TEST");
				fin <= $fopen("sd_mod.txt", "r");
				
				aclr = 1;
				repeat(10) @(posedge clock);
				aclr = 0;
				repeat(10) @(posedge clock);			
				
				while (!$feof(fin)) begin
					res <= $fscanf(fin, "%d\n", sdi);
					@(posedge clock);
				end
				
				repeat(100) @(posedge clock);
				$fclose(fin);
		end
		
		$fclose(fout);
		$stop(2);
	end
	
	always_ff @(posedge clock)
		if (valid)
			$fwrite(fout, "%d\n", signed'(data));
	
	u_sinc3_decim #(.OSR_WIDTH(OSR_WIDTH)) dut(.*);
	
	sd_mod mod(.aclr, .V, .clock, .sdo(sdi));

endmodule :u_sinc3_decim_tb
