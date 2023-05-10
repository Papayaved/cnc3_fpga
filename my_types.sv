`ifndef _my_types_
`define _my_types_

typedef struct packed {
	logic [1:0] res2;
	logic [5:0] sem;

	logic [4:0] res1;
	logic wire_ctrl;
	logic drum_ena;
	logic pump_ena;
	
	logic [6:0] drum_vel;
	logic ena;
} pult_t;
	
typedef struct packed {
	logic res;
	logic center_ena;
	logic pump_ena; 
	logic [2:0] drum_vel;
	logic drum_rev; // clear mask
	logic drum_fwd; // clear mask
	
	logic [5:0] current; // clear mask
	logic hv_lvl;
	logic hv_ena;
} sig_out_t;

typedef struct packed {
	logic [7:0] ratio; // 8
	logic [7:0] width; // 36
} gen_t;

typedef struct packed {
	logic power_OK;
	logic wire_break;

	logic [1:0] res;
	logic wire_ctrl;
	logic alarm;
	logic drum_rev;
	logic drum_fwd;
} lim_switch_t;

`endif // _my_types_
