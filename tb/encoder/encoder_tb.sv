module encoder #(
  parameter ENCODER_DEBOUNCE_TICKS = 10000,
  parameter BUTTON_DEBOUNCE_TICKS  = 10000
)
(
  input logic clk,
  input logic rst,
  // Physical connections
  input logic a,
  input logic b,
  input logic btn,
  // Logic outputs
  output logic cw,
  output logic ccw,
  output logic prs
);

logic a_db;
logic b_db;
logic btn_db;

logic a_db_prev;
logic b_db_prev;
logic btn_db_prev;

logic a_pos;
logic a_neg;
logic b_pos;
logic b_neg;
logic btn_pos;
logic btn_neg;

debouncer #(
  .TICKS (ENCODER_DEBOUNCE_TICKS)
)
ch_a_debouncer_inst (
  .clk (clk),
  .i   (a),
  .o   (a_db)
);

debouncer #(
  .TICKS (ENCODER_DEBOUNCE_TICKS)
)
ch_b_debouncer_inst (
  .clk (clk),
  .i   (b),
  .o   (b_db)
);

debouncer #(
  .TICKS (BUTTON_DEBOUNCE_TICKS)
)
btn_debouncer_inst (
  .clk (clk),
  .i   (btn),
  .o   (btn_db)
);

always_ff @ (posedge clk) begin
  a_db_prev <= a_db;
  b_db_prev <= b_db;
  btn_db_prev <= btn_db;
end

assign a_pos = (a_db && !a_db_prev);
assign a_neg = (!a_db && a_db_prev);

assign b_pos = (b_db && !b_db_prev); 
assign b_neg = (!b_db && b_db_prev); 

assign btn_pos =  (btn_db && !btn_db_prev);
assign btn_neg =  (!btn_db && btn_db_prev);

assign cw = (a_neg && b_db);
assign ccw = (a_pos && b_db);
assign prs = btn_neg;

endmodule
