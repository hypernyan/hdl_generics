module tb;

parameter PRESCALER = 10;
parameter ADDR_BITS = 7; 
parameter BYTES_W   = 3; 
parameter BYTES_R   = 3; 

typedef logic [6:0] addr_t;
typedef enum logic {write = 0, read = 1} opcode_t;
typedef logic [BYTES_W*8-1:0] data_t;

typedef struct packed {
	addr_t   addr;
	opcode_t opcode;
	data_t   data;
} packet_t;



logic clk = 1;
logic rst = 1;

logic [BYTES_W*8-1:0] din;
logic [6:0] ain;
opcode_t    opcode;
logic [2:0] bytes = 2;
logic       vin = 0;
logic       req;
logic [BYTES_R*8-1:0] dout;
logic       vout;
logic       busy;

wire sda;
wire scl;   

pullup (sda);
pullup (scl);

packet_t [1:0] packet;
packet_t       cur_packet;

i2c dut (
	.clk    (clk),
	.rst    (rst),

	.sda    (sda),
	.scl    (scl),

	.din    (din   ),
	.ain    (ain   ),
	.opcode (opcode), // 1 = read, 0 = write
	.vin    (vin   ),
	.dout   (dout  ),
	.vout   (vout  ),
	.busy   (busy  )
);

defparam dut.PRESCALER = PRESCALER;  
defparam dut.BYTES_W   = BYTES_W  ;  // expected byte count for write operation
defparam dut.BYTES_R   = BYTES_R  ;  // expected byte count to read 

always #1 clk <= !clk;

initial begin
	packet[0].addr   = 7'b1000001;
	packet[0].opcode = write;
	packet[0].data   = {8'h05, 16'b1100010111011101};
	packet[1].addr   = 7'b1000001;
	packet[1].opcode = write;
	packet[1].data   = 24'habcdff;
end

assign cur_packet = packet[0];

assign ain    = cur_packet.addr;
assign din    = cur_packet.data;
assign opcode = cur_packet.opcode;


//
//always @ (posedge clk) begin
//	if (req) din <= 8'h02;
//end


initial begin
	#200 rst <= 0;
	#200 rst <= 0;
	#20  vin <= 1;
	#2   vin <= 0;
end

endmodule
