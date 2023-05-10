`ifndef _MyTypes_
`define _MyTypes_

typedef int unsigned UInt32;
typedef shortint unsigned UInt16;

package MyTypesPkg;
	
	class Array #(parameter type T = shortint unsigned);
		T data[];
		function new(int size);
			data = new[size];
		endfunction
		
		function void resize(int new_size);
			data = new[new_size](data);
		endfunction
	endclass :Array
	
endpackage :MyTypesPkg

`endif
