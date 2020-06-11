// Credits to:
// Joey for bcd2bin https://embeddedthoughts.com/2016/06/01/bcd-to-binary-conversion-on-an-fpga/
// Scott Larson for bin2bcd https://www.digikey.com/eewiki/pages/viewpage.action?pageId=60030986
`ifndef MODULE_BCD2BIN
`define MODULE_BCD2BIN
module bcd2bin #(
  parameter integer DEC_W = 8,
  parameter integer BIN_W = $clog2(10**DEC_W)
)
(
  input  logic                  clk,
  input  logic                  rst,
  input  logic [DEC_W-1:0][3:0] in,
  output logic [BIN_W-1:0]      out,
  input  logic                  conv,
  output logic                  rdy
);

logic [DEC_W*4-1:0] in_reg, in_reg_add;
logic [$clog2(BIN_W+2):0] ctr;

always @ (posedge clk) begin
  if (rst) begin
    in_reg <= 0;
    ctr <= 0;
    rdy <= 1;
    out <= 0;
  end
  else begin
    if (conv && rdy) begin
      rdy <= 0;
      in_reg <= in;
    end
    else if (!rdy) begin
      ctr <= ctr + 1;
      if (ctr[$clog2(BIN_W+2):1] == BIN_W) begin
        rdy <= 1;
        ctr <= 0;
      end
      else begin
        rdy <= 0;
        in_reg <= (ctr[0]) ? in_reg_add : {1'b0, in_reg[4*DEC_W-1:1]};
        if (!ctr[0]) out <= {in_reg[0], out[BIN_W-1:1]};
      end
    end
  end
end

genvar gv;
generate 
  for (gv = 1; gv < DEC_W+1; gv++) begin : gen_digits
    assign in_reg_add[4*gv-1-:4] = (in_reg[4*gv-1-:4] > 4) ? in_reg[4*gv-1-:4] - 3 : in_reg[4*gv-1-:4];
  end
endgenerate

endmodule : bcd2bin
`endif // MODULE_BCD2BIN

`ifndef MODULE_BIN2BCD
`define MODULE_BIN2BCD
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

logic [BIN_W-1:0]           in_reg;
logic [DEC_W:0]             bcd_in;
logic [DEC_W-1:0][3:0]      bcd;
logic [$clog2(BIN_W+2)-1:0] cnt;
logic rst_req;

always @ (posedge clk) begin
  if (rst) begin
    cnt       <= 0;
    bcd_in[0] <= 0;
    in_reg    <= 0;
    rst_req   <= 0;
    rdy       <= 0;
  end
  else begin
    if (conv && rdy) begin
      rdy <= 0;
      in_reg <= in;
      rst_req <= 0;
    end
    else if (!rdy) begin
      if (cnt == BIN_W+1) begin
        cnt       <= 0;
        rdy       <= 1;
        bcd_in[0] <= 0;
        rst_req   <= 1;
        out       <= bcd;
      end
      else begin
        cnt <= cnt + 1;
        bcd_in[0] <= in_reg[BIN_W-1];
        in_reg[BIN_W-1:0] <= {in_reg[BIN_W-2:0], 1'b0};
      end
    end
  end
end

genvar gv;
generate
  for (gv = 1; gv < DEC_W+1; gv = gv + 1) begin : gen_digits
    bcd_dig bcd_dig_inst (
      .clk   (clk),
      .rst   (rst_req || rst),
      .ena   (!rdy),
      .bin   (bcd_in[gv-1]),
      .c_out (bcd_in[gv]),
      .bcd   (bcd[gv-1])
    );
  end
endgenerate

endmodule : bin2bcd

module bcd_dig (
  input logic clk,
  input logic rst,
  input logic ena,
  input logic bin,
  output logic c_out,
  output logic [3:0] bcd
);

assign c_out = bcd[3] || (bcd[2] && bcd[1]) || (bcd[2] && bcd[0]);

always @ (posedge clk) begin
  if (rst) bcd <= 0;
  else if (ena) bcd <= (c_out == 1) ? {bcd[3] && bcd[0], ~(bcd[1] ^ bcd[0]), ~bcd[0], bin} : {bcd[2:0], bin};
end

endmodule : bcd_dig
`endif // MODULE_BIN2BCD
