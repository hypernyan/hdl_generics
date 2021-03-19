import pkg::*;

module tb ();
  /*
  logic clk = 1;
  logic rst = 1;
  parameter N = 12;
  always #1 clk <= ~clk;
  sd2_t [N-1:0] x, y;
  sd2_t [N:0] o;

  initial begin
    rst <= 1;
    #10
    rst <= 0;
    x = {zero, zero, pos, zero, neg, pos,  zero, pos, zero, zero, neg,  zero};
    y = {pos,  zero, neg, neg,  neg, zero, pos,  neg, pos,  zero, zero, zero};
  end
    rba #(
    .N (N)
  ) dut (
    .clk (clk),
    .x (x),
    .y (y),
    .o (o)
  );
  */
  logic clk = 1;
  logic rst = 1;
  parameter N = 256;
  always #1 clk <= ~clk;
  sd2_t [N-1:0] x, y;
  
  sd2_t [7:0] m;

  sd2_t [N:0] o;

  function automatic int sd2tobin;
    input sd2_t [31:0] x;
    input int n;
    int signed val = 0;
    for (int i = 0; i < n; i++) begin
      case (x[i])
        zero : val = val;
        neg  : val = val - (2**i);
        pos  : val = val + (2**i);
      endcase
    end
    sd2tobin = val;
  endfunction : sd2tobin

  initial begin
    rst <= 1;
    x = {neg, zero, zero, pos, zero, neg,  zero, pos};
    m = {pos, pos,  pos,  pos, pos,  zero, pos,  pos};
    y = {pos, pos,  pos,  pos, pos,  pos,  neg,  neg};
    #10
    rst <= 0;
    //y = {pos,  zero, neg, neg,  neg, zero, pos,  neg, pos,  zero, zero, zero};
  end
/*
  rbab #(
    .N (N)
  ) rba_inst (
    .x   (x),
    .y   (251),
    .o   (o)
  );
  */
  mod_alu #(.N (N))
  dut (
    .clk (clk),
    .rst (rst),
    .mode (1'b0),
    .m   ({pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos,
           pos, pos,  pos,  pos, pos,  zero, pos,  pos }),
    .x   ({neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos,
           neg, zero, zero, pos, zero, neg,  zero, pos }),
    .y   ({pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg,
           pos, pos,  pos,  pos, pos,  pos,  neg,  neg }),
    .z   (z)
  );

  int xd, md, od;
  assign xd = sd2tobin(x, N);
  assign md = sd2tobin(m, N);
  assign od = sd2tobin(o, N);

endmodule : tb