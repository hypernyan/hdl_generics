`ifndef MODULE_STRETCH
`define MODULE_STRETCH

module stretch #(
  parameter MAX_LENGTH_TICKS = 100,
  parameter DELAY_TICKS = 300
)
(
  input logic clk,
  input logic rst,

  input logic in,
  input logic [$clog2(MAX_LENGTH_TICKS+1)-1:0] strch,
  output logic out
);

logic [MAX_LENGTH_TICKS-1:0] pipe; 

logic [$clog2(MAX_LENGTH_TICKS+1)-1:0] strch_half;
assign strch_half = strch >> 1;

logic [$clog2(MAX_LENGTH_TICKS+1)-1:0] in_ctr, out_ctr;
logic [$clog2(DELAY_TICKS+1)-1:0] out_dl;
logic pend;

always @ (posedge clk) begin
  if (rst) begin
    out_ctr <= 0;
    pipe <= 0;
    out_dl <= 0;
    out <= 0;
    in_ctr <= 0;
    pend <= 0;
  end
  else begin
    pipe[MAX_LENGTH_TICKS-1:0] <= {pipe[MAX_LENGTH_TICKS-2:0], in};
    if (!pend && pipe[MAX_LENGTH_TICKS-1]) in_ctr <= in_ctr + 1;     
    else if (!pend && in_ctr != 0 && (!pipe[MAX_LENGTH_TICKS-1] || in_ctr == MAX_LENGTH_TICKS)) begin //  \_ falling edge. latch length
      out_ctr <= in_ctr + strch;
      in_ctr <= 0;
      out_dl <= DELAY_TICKS - (in_ctr + strch_half);
      pend <= 1;
    end
    else if (pend) begin
      out_dl <= (out_dl == 0) ? 0 : out_dl - 1;
      if (out_dl == 0) begin
        out_ctr <= out_ctr - 1;
        if (out_ctr == 0) begin
          out <= 0;
          pend <= 0;
        end
        else out <= 1;
      end
    end
  end
end

endmodule

`endif // MODULE_STRETCH

//                      strt______mid________
// ______________________/<-len/2->|         \_______________________ 
//                       |         |         |      _____________________________
//                       |         |         |     /____/<-len/2->|         \    \
//                       |         |_________|_____|______________|
//                       |___________________|_____|