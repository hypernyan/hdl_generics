`ifndef MODULE_MEM_ARB
`define MODULE_MEM_ARB
module mem_arb # (
  parameter integer        AW = 16,
  parameter integer        DW = 16,
  parameter integer        N  = 1,
  parameter integer        DC = 0,
  parameter [N-1:0] [31:0] D  = 10 )
(
//
// RAM clock domain
//
  input logic ram_clk,
  input logic ram_rst,
//
// Users
//

// Clocking and synchronous resets

  input  logic [N-1:0]                  in_clk, // .in_clk
  input  logic [N-1:0]                  in_rst, // .in_rst

// Interfacing
  input  logic [N-1:0]                  r_nw,  // .r_nw  // read = 1, write = 0 (opcode)
  input  logic [N-1:0]                  v_i,   // .v_i   // valid in (strobe)
  input  logic [N-1:0] [AW-1:0] a_i,   // .a_i   // address in
  input  logic [N-1:0] [DW-1:0] d_i,   // .d_i   // data in

  output logic [N-1:0]                  v_o,   // .v_o   // valid out
  output logic                 [AW-1:0] a_o,   // .a_o   // address out
  output logic                 [DW-1:0] d_o,   // .d_o   // data out

  //ram_if_sp.sys main_ram,
  // Interface with RAM
  ram_if_sp.sys ram
);

defparam ram.AW = AW;
defparam ram.DW = DW;

logic [N-1:0] [AW+DW:0] fifo_i;
logic [N-1:0] [AW+DW:0] fifo_o;
logic [N-1:0]                           fifo_e;

wor   [$clog2(N)-1:0]                   ind_fifo;
logic [$clog2(N)-1:0]                   ind_fifo_dl;
logic [N-1:0]                           active_fifo;
logic [N-1:0]                           v_o_pipe;

// Fifo flags

// Full flag asserted by any of the FIFOs is considered as overflow
logic [N-1:0] fifo_f;

// Data stored in FIFOs consists of Address, Data and R/#W signal
logic [N-1:0] fifo_v;
logic [N-1:0] fifo_r;

// Generating FIFOs for storing incoming data
genvar i;

generate 
  for (i = 0; i < N; i = i + 1) begin : gen_fifos
    if (DC) begin
      dual_clock_fifo #( D[i], DW+AW+1 )
      fifo_inst (
        .wr_rst_i  (in_rst[i]),    // Each FIFO has it's own clock domain on write side
        .wr_clk_i  (in_clk[i]),    // 
        .wr_en_i   (v_i[i]),
        .wr_data_i ({d_i[i][DW-1:0], a_i[i][AW-1:0], r_nw[i]}),

        .rd_rst_i  (ram_rst),    // All FIFOs share main RAM's clock domain on read side
        .rd_clk_i  (ram_clk),    // 
        .rd_en_i   (fifo_r[i]),  // 
        .rd_data_o (fifo_o[i]),

        .full_o    (fifo_f[i]),
        .empty_o   (fifo_e[i])
      );
    end
    else begin
      fifo_sc_no_if #(
        .D (D[i]),
        .W (DW+AW+1)
      ) fifo_inst
      (
        .rst (ram_rst),
        .clk (ram_clk),

        .w_v (v_i[i]),
        .w_d ({d_i[i][DW-1:0], a_i[i][AW-1:0], r_nw[i]}),

        .r_v (fifo_r[i]),
        .r_q (fifo_o[i]),

        .f (fifo_f[i]),
        .e (fifo_e[i])
      );
    end
  end
endgenerate
// Instantiate target RAM interface
//ram_if #( AW, DW ) main_ram (.*);

// Connect the clock
// assign main_ram.clk = ram_clk;

// Instantiate target RAM and connect the interface
//true_dpram_sclk #( AW, DW ) ram_inst ( .mem_if ( main_ram ) );

// Get the FIFO by priority
onehot_msb #( N ) onehot_msb_inst (
  .i ( ~fifo_e ),
  .o ( active_fifo )
);

// Get active FIFO's index
generate
for ( i = 0; i < N; i = i + 1 ) begin : decode_fifos
    assign ind_fifo = ( active_fifo[i] == 1'b1 ) ? i : 0;
end
endgenerate

// Delay index and active FIFO registers
logic [N-1:0] active_fifo_dl;
always @ ( posedge ram_clk ) begin
  if ( ram_rst ) begin
    ind_fifo_dl    <= 0;
    active_fifo_dl <= 0;
  end
  else begin
    ind_fifo_dl    <= ind_fifo;
    active_fifo_dl <= active_fifo;
  end
end

// Write to RAM
always @ ( posedge ram_clk ) begin
  ram.d <= fifo_o [ind_fifo_dl] [DW+AW-:DW];
  ram.a <= fifo_o [ind_fifo_dl] [AW-:AW];
  ram.v <= ( active_fifo_dl != 0 && ~fifo_o[ind_fifo_dl][0] );
end

generate
  for ( i = 0; i < N; i = i + 1 ) begin : reaf_from_fifos
    assign fifo_r[i] = active_fifo[i] && !fifo_e[i]; // read from FIFO with the highest priority
  end
endgenerate

// Read from RAM
assign d_o = ram.q;

// delay a_o and v_o due to 1 tick delay added by ram
always @ ( posedge ram_clk ) a_o <= ram.a; 

generate
  for ( i = 0; i < N; i = i + 1 ) begin : set_valid_sig
    always @ ( posedge ram_clk ) v_o_pipe[i] <= ( active_fifo_dl[i] && fifo_o[i][0] );
  end
endgenerate

always @ ( posedge ram_clk ) v_o <= v_o_pipe; 

endmodule
`endif // MODULE_MEM_ARB
