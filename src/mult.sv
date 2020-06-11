`ifndef MODULE_MULT
`define MODULE_MULT

module mult #(
  parameter int W = 8
)(
  input  logic           clk,
  input  logic           rst,
  input  logic           calc,
  input  logic [W-1:0]   a,
  input  logic [W-1:0]   b,
  output logic [2*W-1:0] q,
  output logic           rdy
);

logic rdy_reg;
logic [W-1:0] a_reg;
logic [2*W-1:0] b_reg;
logic [$clog2(W+1)-1:0] ctr;
enum logic [1:0] {idle_s, calc_s} fsm;

assign rdy = !calc && rdy_reg;
always @ (posedge clk) begin
  if (rst) begin
    fsm <= idle_s;
    a_reg <= 0;
    b_reg <= 0;
    q <= 0;
    ctr <= 0;
    rdy_reg <= 0;
  end
  case (fsm)
    idle_s : begin
      ctr <= W;
      if (calc) begin
        a_reg <= a;
        b_reg <= b;
        rdy_reg <= 0;
        fsm <= calc_s;
      end
    end
    calc_s : begin
      ctr <= ctr - 1;
      b_reg <= b_reg << 1;
      a_reg <= a_reg >> 1;
      if (a_reg[0]) q <= q + b_reg;
      if (ctr == 0) begin
        fsm <= idle_s;
        rdy_reg <= 1;
      end
    end
  endcase
end

endmodule

`endif // MODULE_MULT
