// Credits to:
// Joey for bcd2bin https://embeddedthoughts.com/2016/06/01/bcd-to-binary-conversion-on-an-fpga/
// Scott Larson for bin2bcd https://www.digikey.com/eewiki/pages/viewpage.action?pageId=60030986

module tb();
logic clk = 1;
logic rst = 1;
always #1 clk <= ~clk;
parameter W = 8;   
logic calc, rdy;

logic [W-1:0] a, b;
logic [2*W-1:0] q;

initial begin
  calc = 0;
  #50
  rst = 0;
  #50
  calc = 1;
  #2
  calc = 0;
end

mult #(
  .W (W)
)
dut (
  .clk      (clk),
  .rst      (rst),
  .calc     (calc),
  .a        (8'd255),
  .b        (8'd255),
  .q        (),
  .rdy      ()
);

endmodule
