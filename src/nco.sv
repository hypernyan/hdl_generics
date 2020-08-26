`ifndef MODULE_NCO
`define MODULE_NCO

module nco #(
  parameter integer LUT_ADDR_BITS   = 8,             // Time precision
  parameter integer LUT_DATA_BITS   = 8,             // Amplitude precision ( half wave )
  parameter integer PHASE_ACC_BITS  = 24,            // Phase accumulator size
  parameter         LUT_FILENAME    = "nco_lut.txt"
)
(  
  input clk,
  input rst,

  input [PHASE_ACC_BITS-2:0] phase_inc,
  output logic [PHASE_ACC_BITS-1:0] phase_acc, // phase accumulator stores 2 bits to determine sine quarter period number

  output logic signed [LUT_DATA_BITS:0] I,
  output logic signed [LUT_DATA_BITS:0] Q
);

logic [1:0] quad_addr, quad_data;

// instantiate nco lut. Use dpsyncram to acquire sin and cos samples simultaneously
nco_lut_if #(LUT_ADDR_BITS, LUT_DATA_BITS) nco_lut_if (.*);
nco_lut    #(LUT_ADDR_BITS, LUT_DATA_BITS, LUT_FILENAME) nco_lut_inst (.ifc (nco_lut_if));

// clock the lut dpsyncram
assign nco_lut_if.clk_a = clk;
assign nco_lut_if.clk_b = clk;
assign nco_lut_if.rst   = rst;

always_ff @ (posedge clk) begin
  if (rst) begin
    phase_acc <= 0;
    nco_lut_if.addr_a <= 0;
    nco_lut_if.addr_b <= 0;
    quad_addr[1:0] <= 0;  
    quad_data[1:0] <= 0;
  end  
  else begin
		phase_acc[PHASE_ACC_BITS-1:0] <= phase_acc[PHASE_ACC_BITS-1:0] + phase_inc[PHASE_ACC_BITS-2:0]; // increment phase accumulator
		nco_lut_if.addr_a <= phase_acc[PHASE_ACC_BITS-3-:LUT_ADDR_BITS];  // sine
		nco_lut_if.addr_b <= ~phase_acc[PHASE_ACC_BITS-3-:LUT_ADDR_BITS]; // cosine
		quad_addr[1:0]    <= phase_acc[PHASE_ACC_BITS-1-:2];
		quad_data[1:0]    <= quad_addr[1:0]; // delayed quad ( sine quarter wave ) due to memory access latency
  end
end

// Create two's complement output
always_ff @ (posedge clk) begin
  case (quad_data)
    (2'b00) : begin
      I[LUT_DATA_BITS:0] <= {1'b0,  nco_lut_if.data_b[LUT_DATA_BITS-1:0]};
      Q[LUT_DATA_BITS:0] <= {1'b0,  nco_lut_if.data_a[LUT_DATA_BITS-1:0]};
    end
    (2'b01) : begin
      I[LUT_DATA_BITS:0] <= {1'b1, ~nco_lut_if.data_a[LUT_DATA_BITS-1:0]};
      Q[LUT_DATA_BITS:0] <= {1'b0,  nco_lut_if.data_b[LUT_DATA_BITS-1:0]};
    end
    (2'b10) : begin
      I[LUT_DATA_BITS:0] <= {1'b1, ~nco_lut_if.data_b[LUT_DATA_BITS-1:0]};
      Q[LUT_DATA_BITS:0] <= {1'b1, ~nco_lut_if.data_a[LUT_DATA_BITS-1:0]};
    end
    (2'b11) : begin
      I[LUT_DATA_BITS:0] <= {1'b0,  nco_lut_if.data_a[LUT_DATA_BITS-1:0]};
      Q[LUT_DATA_BITS:0] <= {1'b1, ~nco_lut_if.data_b[LUT_DATA_BITS-1:0]};
    end
  endcase
end

endmodule

`define PI 3.14159265359
//`define SIMULATION
interface nco_lut_if #(
  parameter int ADDR_WIDTH = 8,
  parameter int DATA_WIDTH = 8 )
(
);
  logic clk_a;
  logic clk_b;
  logic rst;
  logic [ADDR_WIDTH - 1:0] addr_a;
  logic [ADDR_WIDTH - 1:0] addr_b;
  logic [DATA_WIDTH - 1:0] data_a;
  logic [DATA_WIDTH - 1:0] data_b;
  
  modport mem ( input clk_a, clk_b, rst, addr_a, addr_b, output data_a, data_b );
  modport sys ( input data_a, data_b, output addr_a, addr_b );
  modport tb  ( output data_a, data_b, addr_a, addr_b );
endinterface

module nco_lut #(
  parameter int ADDR_WIDTH = 8,
  parameter int DATA_WIDTH = 8,
  parameter LUT_FILENAME = "nco_lut.txt"
)
(
  nco_lut_if.mem ifc
);

typedef bit [DATA_WIDTH-1:0] width_t;
int f, i;

initial begin
`ifdef SIMULATION
  f = $fopen(LUT_FILENAME, "w");

  @(negedge ifc.rst);
  @(posedge ifc.clk_a);

  for (i = 0; i<2**ADDR_WIDTH; i=i+1) begin
    $fwrite(f,"%b\n",width_t'($rtoi((2**DATA_WIDTH-1)*$sin(0.5*`PI*$itor(i)/$itor(2**ADDR_WIDTH-1))))); // quarter of a sine
  end
  $fclose(f);
`endif // SIMULATION
  $readmemb (LUT_FILENAME, rom);
end

reg [DATA_WIDTH-1:0] rom [2**ADDR_WIDTH-1:0];

always @ (posedge ifc.clk_a) begin
  ifc.data_a <= rom [ifc.addr_a];
  ifc.data_b <= rom [ifc.addr_b];
end

endmodule
`endif // MODULE_NCO

