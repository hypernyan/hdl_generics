// Credits to:
// Joey for bcd2bin https://embeddedthoughts.com/2016/06/01/bcd-to-binary-conversion-on-an-fpga/
// Scott Larson for bin2bcd https://www.digikey.com/eewiki/pages/viewpage.action?pageId=60030986

module tb();
logic clk = 1;
logic rst = 1;
always #1 clk <= ~clk;
parameter TEST_NUM = 100;

parameter BCD2BIN_DEC_W = 4;
parameter BCD2BIN_BIN_W = $clog2(10**BCD2BIN_DEC_W);
parameter BIN2BCD_DEC_W = 4;
parameter BIN2BCD_BIN_W = 4;

logic [BCD2BIN_DEC_W-1:0][3:0] bcd2bin_in = 0;
logic [BCD2BIN_BIN_W-1:0]      bcd2bin_out;
logic                  bcd2bin_conv = 0;
logic                  bcd2bin_rdy;

initial begin
  #100 rst = 0;
  $display("Testing BCD to binary with %d random numbers", TEST_NUM);
  //repeat (TEST_NUM) begin
    bcd2bin_in <= {4'd7, 4'd2, 4'd1, 4'd3};
    bcd2bin_conv <= 1;
  //end
end

bcd2bin #(
  .DEC_W (4)
) bcd2bin_inst (
  .clk  (clk),
  .rst  (rst),
  .in   (bcd2bin_in),
  .out  (bcd2bin_out),
  .conv (bcd2bin_conv),
  .rdy  (bcd2bin_rdy)
);
/*
module bin2bcd #(
  parameter integer DEC_W = 8,
  parameter integer BIN_W = $clog2(10**DEC_W)
)
(
  input  logic                  clk,
  input  logic                  rst,
  input  logic [BIN_W-1:0]      in,
  output logic [DEC_W-1:0][3:0] out,
  input  logic                  conv,
  output logic                  rdy
);
*/
endmodule
