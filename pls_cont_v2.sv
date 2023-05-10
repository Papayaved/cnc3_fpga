`ifndef _pls_cont_
`define _pls_cont_
//`include "fifo_rdreq1.sv"
`include "fifo_rdreq.sv"
`include "pls_gen.sv"

module pls_cont(
	input clk, aclr, abort,
	input green,
	input oi,
	input sop_in, eop_in,
	input PlsData data_in,
	input wrreq,
	output full,
	output reg ready,
	
	output run, oi_req, pls_clk,
	
	output pls, dir,
	
	input brake_clk
);

wire empty;
reg start_clk = 1'b0, stop_clk = 1'b0, rdreq = 1'b0;
wire sop_out, eop_out;
PlsData data_out;
wire loaded, stop_req, start_rdy;
reg pls_reg = 1'b0;

typedef enum {IDLE, WAIT[2], SOP, OI, RUN, LOAD, ERR} State;
State state;

always_ff @(posedge clk, posedge aclr)
	if (aclr)
		begin
			start_clk <= 1'b0;
			stop_clk <= 1'b0;
			rdreq <= 1'b0;
			state <= IDLE;
		end
	else if (abort)
		begin
			start_clk <= 1'b0;
			stop_clk <= 1'b0;
			rdreq <= 1'b0;
			state <= ERR;
		end
	else if (brake_clk)
		begin
			start_clk <= 1'b0;
			stop_clk <= 1'b0;
			rdreq <= 1'b0;
			state <= IDLE;
		end
	else
		case (state)
			IDLE:
				begin
					stop_clk <= 1'b0;
					
					if (start_rdy && !empty)
						begin
							rdreq <= 1'b1;
							state <= WAIT0;
						end
				end
			WAIT0:
				begin
					rdreq <= 1'b0;
					state <= SOP;
				end
			SOP:
				if (sop_out)
					state <= OI;
				else // skip incorrect data
					state <= IDLE;
			OI:
				if (oi)
					if (data_out.mask)
						begin
							start_clk <= 1'b1;
							state <= LOAD;
						end
					else // empty data
						state <= IDLE;
			LOAD:
				begin
					start_clk <= 1'b0;
					
					if (eop_out && !data_out.mask && stop_req) // stop at eop?
						begin
							stop_clk <= 1'b1;
							state <= IDLE;
						end
					else if (loaded)
						state <= RUN;
				end
			RUN:
				if (eop_out)
					begin
						stop_clk <= 1'b1;
						state <= IDLE;
					end
				else if (!empty && pls_reg) // waiting to store cur_data at pls_clk
					begin
						rdreq <= 1'b1;
						state <= WAIT1;
					end
				else if (empty && stop_req) begin // not enough time for read from fifo
					stop_clk <= 1'b1;
					state <= IDLE;
				end
			WAIT1:
				begin
					rdreq <= 1'b0;
					state <= LOAD;
				end
			ERR:;
		endcase

assign oi_req = state == OI && start_rdy;

always_ff @(posedge clk, posedge aclr)
	if (aclr)
		pls_reg <= 1'b0;
	else if (loaded)
		pls_reg <= 1'b0;
	else if (pls_clk)
		pls_reg <= 1'b1;

pls_gen pls_gen_inst(
	.clk, .aclr,
	.green,
	.start_clk, .stop_clk(stop_clk || abort), .brake_clk,
	.dir_req(data_out.dir), .T(data_out.T),
	.run, .loaded,
	.pls, .dir,
	.stop_req, .start_rdy, .pls_clk
);

fifo_rdreq #(.ADDR_WIDTH(1), .DATA_WIDTH($bits(data_in) + 2)) fifo_inst(
	.clock(clk), .aclr, .sclr(brake_clk || abort),
	.data({sop_in, eop_in, data_in}), .wrreq,
	.rdreq, .q({sop_out, eop_out, data_out}),
	.empty, .full, .usedw()
);

//fifo_rdreq1 #(.DATA_WIDTH($bits(data_in) + 2)) fifo1_inst(
//	.clock(clk),
//	.aclr,
//	.sclr(brake_clk || abort),
//	.data({sop_in, eop_in, data_in}),
//	.wrreq,
//	.rdreq,
//	.q({sop_out, eop_out, data_out}),
//	.empty,
//	.full
//);

always_ff @(posedge clk, posedge aclr)
	if (aclr)
		ready <= 1'b1;
	else if (brake_clk)
		ready <= 1'b1;
	else if (oi_req && oi && data_out.mask)
		ready <= 1'b0;
	else if ((eop_out && pls_clk) || (empty && stop_req))
		ready <= 1'b1;

endmodule :pls_cont

`endif
