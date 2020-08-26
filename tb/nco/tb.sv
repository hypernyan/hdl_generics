`define SIMULATION

module tb();
logic clk = 1;
logic rst = 1;
always #1 clk <= ~clk;
initial #100 rst <= 0;
parameter PHASE_ACC_BITS = 20;
parameter LUT_DATA_BITS  = 13;
parameter LUT_ADDR_BITS  = 10;

parameter real TARGET_NCO_FREQ_MHZ = 28.6;
parameter real REFCLK_FREQ_MHZ = 112;

logic signed [LUT_DATA_BITS-1:0] nco;

parameter PHASE_INC = $rtoi((2**PHASE_ACC_BITS)*(TARGET_NCO_FREQ_MHZ/REFCLK_FREQ_MHZ));

nco #(
  .LUT_ADDR_BITS  (LUT_ADDR_BITS),  // Time precision
  .LUT_DATA_BITS  (LUT_DATA_BITS),  // Amplitude precision ( half wave )
  .PHASE_ACC_BITS (PHASE_ACC_BITS)) // Phase accumulator size
dut (  
  .clk (clk),
  .rst (rst),

  .phase_inc (PHASE_INC),
  .phase_acc (), // phase accumulator stores 2 bits to determine sine quarter period number

  .I (nco),
  .Q ()
);


endmodule