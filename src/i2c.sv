`ifndef MODULE_I2C
`define MODULE_I2C
module i2c #(
  parameter integer PRESCALER = 10, 
  parameter integer BYTES_W  = 3,  // expected byte count for write operation
  parameter integer BYTES_R  = 2   // expected byte count to read 
)
(
  input  logic clk,
  input  logic rst,

  inout  logic sda,
  output logic scl,

  input  logic [BYTES_W-1:0][7:0] din,  // input data
  input  logic [7:0]              ain,  // 7-bit slave address
  input  logic                    opcode, // 1 = read, 0 = write
  input  logic                    ptr_set, // 1 to set pointer only
  input  logic                    vin,
  output logic [BYTES_R-1:0][7:0] dout,
  output logic                    vout,
  output logic                    busy
);

parameter integer PRESCALER_HALF = integer'(PRESCALER/2);

typedef enum logic [2:0] {
  idle_s,
  start_s,
  tx_s,
  ack_s_s,
  ack_m_s,
  rx_s,
  stop_s
} fsm_t;

fsm_t fsm;

logic scl_r; // scl reg
logic sda_r; // sda reg
logic sda_oe; // sda output enable
logic scl_oe; // scl output enable
logic scl_pos; // scl pos edge
logic scl_neg; // scl neg edge
logic [7:0] dts; // data to send (1 byte)
logic [7:0] rd; // byte being read
logic [3:0] bit_ctr;
logic [3:0] byte_ctr;

logic [$clog2(PRESCALER)-1:0] ctr;

assign scl_pos = (ctr == PRESCALER-1);
assign scl_neg = (ctr == PRESCALER_HALF-1);

assign scl = (scl_oe) ? scl_r : 1'bz; 
assign sda = (sda_oe) ? sda_r : 1'bz;

assign busy = (fsm != idle_s);

always @ (posedge clk) begin
  if (rst) begin
    fsm      <= idle_s;
    dts      <= 0;
    vout     <= 0;
    dout     <= 0;
    rd       <= 0;
    bit_ctr  <= 0;
    byte_ctr <= 0;
    ctr      <= 0;
    sda_oe   <= 0;
    scl_r    <= 1;
    sda_r    <= 0;
    scl_oe   <= 0;
  end
  else begin
    ctr <= (ctr == PRESCALER-1 || vin) ? 0 : ctr + 1;
    if (ctr == PRESCALER-1 && fsm != start_s) scl_r <= 1;
    if (ctr == PRESCALER_HALF-1) scl_r <= 0;
    case (fsm)
      idle_s : begin
        scl_oe   <= 0;
        sda_oe   <= 0;
        byte_ctr <= 0;
        bit_ctr  <= 0;
        if (vin) begin
          dts <= {ain[6:0], opcode};
          fsm <= start_s;
        end
      end
      start_s : begin
        if (scl_neg) begin
          sda_oe <= 1;
          sda_r  <= 0;
        end
        if (scl_pos) begin
          fsm    <= tx_s;
          scl_oe <= 1;
        end
      end
      tx_s : begin
        if (scl_neg) begin
          dts[7:1] <= dts[6:0];
          sda_r    <= dts[7];
          bit_ctr  <= bit_ctr + 1;
        end
        if (bit_ctr == 9) begin
          byte_ctr <= byte_ctr + 1;
          fsm      <= ack_s_s;
          sda_oe   <= 0;
        end
        else sda_oe <= 1;
      end
      ack_s_s : begin // Slave ack
        bit_ctr <= (opcode) ? 0 : 1;
        if (scl_pos) begin 
          dts <= din[BYTES_W-byte_ctr];
        end
        if (scl_neg) begin
          sda_r  <= (byte_ctr == BYTES_W + 1) ? 0 : dts[7];
          dts[7:1] <= dts[6:0];
          fsm    <= (opcode) ? rx_s : (byte_ctr == BYTES_W + 1 || (byte_ctr == 2 && ptr_set )) ? stop_s : tx_s;
          sda_oe <= (opcode) ? 0 : 1;
        end
      end
      rx_s : begin
        vout   <= 0;
        sda_oe <= 0;
        if (scl_pos) begin
          rd[0]   <= sda;
          rd[7:1] <= rd[6:0];
          bit_ctr <= bit_ctr + 1;
        end
        if (bit_ctr == 8 && scl_neg) begin
          sda_oe           <= 1;
          sda_r            <= (byte_ctr == BYTES_R) ? 1 : 0;
          fsm              <= ack_m_s;
          dout[BYTES_R-byte_ctr] <= rd;
        end
      end
      ack_m_s : begin 
        bit_ctr <= 0;
        if (scl_neg) begin
          if (byte_ctr == BYTES_R) vout <= 1;
          byte_ctr <= byte_ctr + 1;
          fsm <= (byte_ctr == BYTES_R) ? stop_s : rx_s;
        end
      end
      stop_s : begin
        vout <= 0;
        if (scl_neg) begin
          scl_oe <= 0;
          sda_r  <= 0;
          fsm <= idle_s;
        end
      end
    endcase
  end
end

endmodule

`endif // MODULE_I2C