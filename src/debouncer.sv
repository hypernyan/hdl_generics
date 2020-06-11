`ifndef MODULE_DEBOUNCER
`define MODULE_DEBOUNCER

module debouncer #(
  parameter TICKS = 10000
)
(
  input  logic clk,
  input  logic rst,

  input  logic i,
  output logic o
);
initial o = 0;
logic i_prev;
logic pos_event = 0;
logic neg_event = 0;

logic [$clog2(TICKS+2)-1:0] ctr = 0;

always @ (posedge clk) i_prev <= i;

assign i_pos = !i_prev && i;
assign i_neg = i_prev && !i;

always @ (posedge clk) if (ctr == TICKS) o <= i;
always @ (posedge clk) ctr <= (i_pos || i_neg) ? 0 : (ctr == TICKS+1) ? TICKS+1 : ctr + 1;

endmodule

`endif // MODULE_DEBOUNCER