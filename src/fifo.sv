`ifndef MODULE_FIFO
`define MODULE_FIFO

interface fifo_dc_if
#(
  parameter ADDR_WIDTH = 16,
  parameter DATA_WIDTH = 16)
();

  logic                  rst;
  logic                  clk_w;
  logic                  clk_r;
  
  logic                  write;
  logic [DATA_WIDTH-1:0] data_in;
  
  logic                  read;
  logic [DATA_WIDTH-1:0] data_out;
  
  logic                  full;
  logic                  empty;
  
  modport fifo (input rst, clk_w, clk_r, write, data_in, read, output data_out, full, empty);
  modport sys  (input data_out, full, empty, output rst, clk_w, clk_r, write, data_in, read);

endinterface

module fifo_dc #(
  parameter ADDR_WIDTH = 3,
  parameter DATA_WIDTH = 32
)
(
  fifo_dc_if.fifo fifo
);

reg [ADDR_WIDTH-1:0] wr_addr;
reg [ADDR_WIDTH-1:0] wr_addr_gray;
reg [ADDR_WIDTH-1:0] wr_addr_gray_rd;
reg [ADDR_WIDTH-1:0] wr_addr_gray_rd_r;
reg [ADDR_WIDTH-1:0] rd_addr;
reg [ADDR_WIDTH-1:0] rd_addr_gray;
reg [ADDR_WIDTH-1:0] rd_addr_gray_wr;
reg [ADDR_WIDTH-1:0] rd_addr_gray_wr_r;

function [ADDR_WIDTH-1:0] gray_conv;
  input [ADDR_WIDTH-1:0] in;
  begin
    gray_conv = {in[ADDR_WIDTH-1], in[ADDR_WIDTH-2:0] ^ in[ADDR_WIDTH-1:1]};
  end
endfunction

always @ (posedge fifo.clk_w or posedge fifo.rst) begin
  if (fifo.rst) begin
    wr_addr <= 0;
    wr_addr_gray <= 0;
  end else if (fifo.write) begin
    wr_addr <= wr_addr + 1'b1;
    wr_addr_gray <= gray_conv(wr_addr + 1'b1);
  end
end

// synchronize read address to write clock domain
always @ (posedge fifo.clk_w) begin
  rd_addr_gray_wr   <= rd_addr_gray;
  rd_addr_gray_wr_r <= rd_addr_gray_wr;
end

always @ (posedge fifo.clk_w or posedge fifo.rst)
  if (fifo.rst)
    fifo.full <= 0;
  else if (fifo.write)
    fifo.full <= gray_conv (wr_addr + 2) == rd_addr_gray_wr_r;
  else
    fifo.full <= fifo.full & (gray_conv (wr_addr + 1'b1) == rd_addr_gray_wr_r);

always @ (posedge fifo.clk_w or posedge fifo.rst) begin
  if (fifo.rst) begin
    rd_addr      <= 0;
    rd_addr_gray <= 0;
  end else if (fifo.read) begin
    rd_addr      <= rd_addr + 1'b1;
    rd_addr_gray <= gray_conv(rd_addr + 1'b1);
  end
end

// synchronize write address to read clock domain
always @ (posedge fifo.clk_r) begin
  wr_addr_gray_rd   <= wr_addr_gray;
  wr_addr_gray_rd_r <= wr_addr_gray_rd;
end

always @ (posedge fifo.clk_w or posedge fifo.rst)
  if (fifo.rst)
    fifo.empty <= 1'b1;
  else if (fifo.read)
    fifo.empty <= gray_conv (rd_addr + 1) == wr_addr_gray_rd_r;
  else
    fifo.empty <= fifo.empty & (gray_conv (rd_addr) == wr_addr_gray_rd_r);

// generate dual clocked memory
reg [DATA_WIDTH-1:0] mem[(1<<ADDR_WIDTH)-1:0];

always @(posedge fifo.clk_r) if (fifo.read) fifo.data_out <= mem[rd_addr];
always @(posedge fifo.clk_w) if (fifo.write) mem[wr_addr] <= fifo.data_in;

endmodule

interface fifo_sc_if
#( 
  parameter D = 16,
  parameter W = 16 )
();
  logic         rst;
  logic         clk;
  
  logic         write;
  logic [W-1:0] data_in;
  
  logic         read;
  logic [W-1:0] data_out;
  logic         valid_out;
  
  logic         full;
  logic         empty;
  
  modport fifo (input rst, clk, write, data_in, read, output data_out, valid_out, full, empty);
  modport sys  (input data_out, full, empty, output rst, clk, write, data_in, read);
  modport tb   (output data_out, full, empty, rst, clk, write, data_in, read);

endinterface

module fifo_sc #(
  parameter D = 16,
  parameter W = 16
)
(
  fifo_sc_if.fifo fifo
);

logic [D-1:0] wr_addr;
logic [D-1:0] rd_addr;
logic [D:0]   diff;
logic [D:0]   wr_ctr;
logic [D:0]   rd_ctr;

assign diff = wr_ctr - rd_ctr;

assign fifo.empty = (diff == 0);
assign fifo.full = (diff[D] == 1);

always @ (posedge fifo.clk) begin
  if (fifo.rst) wr_ctr <= 0;
  else if (fifo.write && !fifo.full) wr_ctr <= wr_ctr + 1;
end

assign wr_addr[D-1:0] = wr_ctr[D-1:0];
assign rd_addr[D-1:0] = rd_ctr[D-1:0];

always @ (posedge fifo.clk) begin
  if (fifo.rst) rd_ctr <= 0;
  else if (fifo.read && !fifo.empty) rd_ctr <= rd_ctr + 1;
end
always @ (posedge fifo.clk) fifo.valid_out <= (fifo.read && !fifo.empty);

reg [W-1:0] mem[(1<<D)-1:0];

int i;

initial for (i = 0; i < 2**D; i = i + 1) mem[i] = '0;

always @ (posedge fifo.clk) if (fifo.read) fifo.data_out <= mem[rd_addr];

always @ (posedge fifo.clk) if (fifo.write) mem[wr_addr] <= fifo.data_in;

endmodule

module fifo_sc_no_if #(
  parameter D = 16,
  parameter W = 16
)
(
  input  logic         rst,
  input  logic         clk,
  
  input  logic         write,
  input  logic [W-1:0] data_in,
  
  input  logic         read,
  output logic [W-1:0] data_out,
  
  output logic         full,
  output logic         empty
);

logic [D-1:0] wr_addr;
logic [D-1:0] rd_addr;
logic [D:0]   diff;
logic [D:0]   wr_ctr;
logic [D:0]   rd_ctr;

assign diff = wr_ctr - rd_ctr;

assign empty = (diff == 0);
assign full = (diff[D] == 1);

always @ (posedge clk) begin
  if (rst) wr_ctr <= 0;
  else if (write && !full) wr_ctr <= wr_ctr + 1;
end

assign wr_addr[D-1:0] = wr_ctr[D-1:0];
assign rd_addr[D-1:0] = rd_ctr[D-1:0];

always @ (posedge clk) begin
  if (rst) rd_ctr <= 0;
  else if (read && !empty) rd_ctr <= rd_ctr + 1;
end

reg [W-1:0] mem[(1<<D)-1:0];

int i;

initial for (i = 0; i < 2**D; i = i + 1) mem[i] = '0;

always @ (posedge clk) if (read) data_out <= mem[rd_addr];

always @ (posedge clk) if (write) mem[wr_addr] <= data_in;

endmodule

`endif // MODULE_FIFO