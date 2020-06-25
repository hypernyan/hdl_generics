// Credits to:
// Joey for bcd2bin https://embeddedthoughts.com/2016/06/01/bcd-to-binary-conversion-on-an-fpga/
// Scott Larson for bin2bcd https://www.digikey.com/eewiki/pages/viewpage.action?pageId=60030986

module tb();

parameter DELAY_TICKS = 100;
parameter MAX_LENGTH_TICKS = 100;

logic clk = 1;
logic rst;
always #1 clk <= ~clk;

logic in, out;
logic [$clog2(MAX_LENGTH_TICKS+1)-1:0] strch;

initial begin
  in = 0;
  rst = 1;
  #150
  rst = 0;
  #50
  in = 1;
  #100
  in = 0;
  #300
  in = 1;
  #50
  in = 0;
end

assign strch = 40;

stretch #(
  .MAX_LENGTH_TICKS (MAX_LENGTH_TICKS),
  .DELAY_TICKS (DELAY_TICKS)
) dut (
  .clk (clk),
  .rst (rst),

  .in (in),
  .strch (strch),
  .out (out)
);

endmodule
