`ifndef MODULE_RAM
`define MODULE_RAM

interface ram_req #(
	parameter AW = 16,
	parameter DW = 16
);
	logic           r_nw;
	logic           v_in;
	logic [AW-1:0]  a_in;
	logic [DW-1:0]  d_in;
	
	logic [AW-1:0] v_out;
	logic [DW-1:0] a_out;
	logic          d_out;
	modport mem (input r_nw, v_in, a_in, d_in, output v_out, a_out, d_out);
	modport sys (output r_nw, v_in, a_in, d_in, input v_out, a_out, d_out);
endinterface

interface ram_if_dp
#( 
	parameter AW = 16,
	parameter DW = 16 )
(
);
logic clk_a;
logic clk_b;
logic rst;
logic [AW - 1:0] a_a;
logic [AW - 1:0] a_b;
logic [DW - 1:0] d_a;
logic [DW - 1:0] d_b;
logic w_a;
logic w_b;
logic [DW - 1:0] q_a;
logic [DW - 1:0] q_b;

modport mem ( input clk_a, clk_b, rst, w_a, w_b, a_a, a_b, d_a, d_b, output q_a, q_b );
modport sys ( input q_a, q_b, output w_a, w_b, a_a, a_b, d_a, d_b );
modport tb  ( output q_a, q_b, w_a, w_b, a_a, a_b, d_a, d_b );

endinterface

interface ram_if_sp
#( 
	parameter AW = 16,
	parameter DW = 16 )
(
);
logic            clk;
logic            rst;
logic [AW - 1:0] a;
logic [DW - 1:0] d;
logic            w;
logic [DW - 1:0] q;

modport mem ( input clk, rst, a, d, w, output q );
modport sys ( input q, output w, a, d );
modport tb  ( output a, d, w, q );

endinterface

module ram_dp #( 
	parameter AW = 16,
	parameter DW = 16
)
(
	ram_if_dp.mem mem_if
);

reg [DW - 1:0] ram [2**AW - 1:0];
initial for (int i = 0; i < 2**AW; i = i + 1) ram[i] = '0;

`ifdef SIMULATION
initial begin

  @ ( negedge mem_if.rst )
  @ ( posedge mem_if.clk_a )
  $readmemh ( "../../src/verilog/true_dpram_sclk/init.txt", ram );
end
`endif

	// Port A
	always @ ( posedge mem_if.clk_a ) begin
		if ( mem_if.w_a ) begin
			ram[ mem_if.a_a ] <= mem_if.d_a;
			mem_if.q_a <= mem_if.d_a;
		end
		else mem_if.q_a <= ram[ mem_if.a_a ];
	end
	// Port B          
	always @ ( posedge mem_if.clk_b ) begin
		if ( mem_if.w_b ) begin
			ram[ mem_if.a_b ] <= mem_if.d_b;
			mem_if.q_b <= mem_if.d_b;
		end
		else mem_if.q_b <= ram[ mem_if.a_b ];
	end
	
endmodule

module ram_sp #( 
	parameter AW = 16,
	parameter DW = 16
)
(
	ram_if_sp.mem mem_if
);

reg [DW - 1:0] ram [2**AW - 1:0];
initial for (int i = 0; i < 2**AW; i = i + 1) ram[i] = '0;

`ifdef SIMULATION
initial begin

  @ ( negedge mem_if.rst )
  @ ( posedge mem_if.clk )
  $readmemh ( "../../src/verilog/true_dpram_sclk/init.txt", ram );
end
`endif

	always @ ( posedge mem_if.clk ) begin
		if ( mem_if.w ) begin
			ram[ mem_if.a ] <= mem_if.d;
			mem_if.q <= mem_if.d;
		end
		else mem_if.q <= ram[ mem_if.a ];
	end

	
endmodule
`endif // MODULE_RAM
