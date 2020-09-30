`ifndef MODULE_FIFO
`define MODULE_FIFO

interface fifo_dc_if
#(
  parameter ADDR_WIDTH = 16,
  parameter DATA_WIDTH = 16)
();

  logic                  rst_w;
  logic                  rst_r;
  logic                  clk_w;
  logic                  clk_r;
  
  logic                  write;
  logic [DATA_WIDTH-1:0] data_in;
  
  logic                  read;
  logic [DATA_WIDTH-1:0] data_out;
  logic                  valid_out;
  
  logic                  full;
  logic                  empty;
  
  modport fifo (input rst_w, rst_r, clk_w, clk_r, write, data_in, read, output data_out, valid_out, full, empty);
  modport sys  (input data_out, valid_out, full, empty, output rst_w, rst_r, clk_w, clk_r, write, data_in, read);

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

always @ (posedge fifo.clk_w or posedge fifo.rst_w) begin
  if (fifo.rst_w) begin
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

always @ (posedge fifo.clk_w or posedge fifo.rst_w)
  if (fifo.rst_w)
    fifo.full <= 0;
  else if (fifo.write && !fifo.full)
    fifo.full <= gray_conv (wr_addr + 2) == rd_addr_gray_wr_r;
  else
    fifo.full <= fifo.full & (gray_conv (wr_addr + 1'b1) == rd_addr_gray_wr_r);

always @ (posedge fifo.clk_r or posedge fifo.rst_r) begin
  if (fifo.rst_r) begin
    rd_addr      <= 0;
    rd_addr_gray <= 0;
  end else if (fifo.read && !fifo.empty) begin
    rd_addr      <= rd_addr + 1'b1;
    rd_addr_gray <= gray_conv(rd_addr + 1'b1);
  end
end

// synchronize write address to read clock domain
always @ (posedge fifo.clk_r) begin
  wr_addr_gray_rd   <= wr_addr_gray;
  wr_addr_gray_rd_r <= wr_addr_gray_rd;
end

always @ (posedge fifo.clk_r or posedge fifo.rst_r)
  if (fifo.rst_r)
    fifo.empty <= 1'b1;
  else if (fifo.read && !fifo.empty)
    fifo.empty <= gray_conv (rd_addr + 1) == wr_addr_gray_rd_r;
  else
    fifo.empty <= fifo.empty & (gray_conv (rd_addr) == wr_addr_gray_rd_r);

// generate dual clocked memory
reg [DATA_WIDTH-1:0] mem[(1<<ADDR_WIDTH)-1:0];

always @(posedge fifo.clk_r) begin
  if (fifo.read && !fifo.empty) fifo.data_out <= mem[rd_addr];
  fifo.valid_out <= (fifo.read && !fifo.empty);
end
always @(posedge fifo.clk_w) if (fifo.write && !fifo.full) mem[wr_addr] <= fifo.data_in;

endmodule

module fifo_dc_no_if #(
  parameter ADDR_WIDTH = 3,
  parameter DATA_WIDTH = 32
)
(

  input logic                   rst_w,
  input logic                   rst_r,
  input logic                   clk_w,
  input logic                   clk_r,
  
  input logic                   write,
  input logic [DATA_WIDTH-1:0]  data_in,
  
  input logic                   read,
  output logic [DATA_WIDTH-1:0] data_out,
  output logic                  valid_out,
  
  output logic                  full,
  output logic                  empty
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

always @ (posedge clk_w or posedge rst_w) begin
  if (rst_w) begin
    wr_addr <= 0;
    wr_addr_gray <= 0;
  end else if (write && !full) begin
    wr_addr <= wr_addr + 1'b1;
    wr_addr_gray <= gray_conv(wr_addr + 1'b1);
  end
end

// synchronize read address to write clock domain
always @ (posedge clk_w) begin
  rd_addr_gray_wr   <= rd_addr_gray;
  rd_addr_gray_wr_r <= rd_addr_gray_wr;
end

always @ (posedge clk_w or posedge rst_w)
  if (rst_w)
    full <= 0;
  else if (write && !full)
    full <= gray_conv (wr_addr + 2) == rd_addr_gray_wr_r;
  else
    full <= full & (gray_conv (wr_addr + 1'b1) == rd_addr_gray_wr_r);

always @ (posedge clk_r or posedge rst_r) begin
  if (rst_r) begin
    rd_addr      <= 0;
    rd_addr_gray <= 0;
  end else if (read && !empty) begin
    rd_addr      <= rd_addr + 1'b1;
    rd_addr_gray <= gray_conv(rd_addr + 1'b1);
  end
end

// synchronize write address to read clock domain
always @ (posedge clk_r) begin
  wr_addr_gray_rd   <= wr_addr_gray;
  wr_addr_gray_rd_r <= wr_addr_gray_rd;
end

always @ (posedge clk_r or posedge rst_r)
  if (rst_r)
    empty <= 1'b1;
  else if (read && !empty)
    empty <= gray_conv (rd_addr + 1) == wr_addr_gray_rd_r;
  else
    empty <= empty & (gray_conv (rd_addr) == wr_addr_gray_rd_r);

// generate dual clocked memory
reg [DATA_WIDTH-1:0] mem[(1<<ADDR_WIDTH)-1:0];

always @(posedge clk_r) begin
  if (read && !empty) data_out <= mem[rd_addr];
  valid_out <= (read && !empty);
end

always @(posedge clk_w) if (write && !full) mem[wr_addr] <= data_in;

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
  modport sys  (input data_out, valid_out, full, empty, output rst, clk, write, data_in, read);
  modport tb   (output data_out, valid_out, full, empty, rst, clk, write, data_in, read);

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

reg [W-1:0] mem[(1<<D)-1:0];

int i;

initial for (i = 0; i < 2**D; i = i + 1) mem[i] = '0;

always @ (posedge fifo.clk) begin
  if (fifo.read && !fifo.empty) fifo.data_out <= mem[rd_addr];
  fifo.valid_out <= (fifo.read && !fifo.empty);
  if (fifo.write && !fifo.full) mem[wr_addr] <= fifo.data_in;
end

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
  output logic         valid_out,
  
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

always @ (posedge clk) begin
  if (read && !empty) data_out <= mem[rd_addr];
  valid_out <= (read && !empty);
  if (write && !full) mem[wr_addr] <= data_in;
end

endmodule

`endif // MODULE_FIFO