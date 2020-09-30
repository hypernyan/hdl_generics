`ifndef MODULE_INT_DIVIDER
`define MODULE_INT_DIVIDER
module int_divider #(
  parameter WIDTH = 12
) 
(
  input logic clk,
  input logic rst,
  input logic cal,
  input logic [WIDTH-1:0] dvd, // divident
  input logic [WIDTH-1:0] dvs, // divisor
  output logic [WIDTH-1:0] quo,
  output logic rdy
);

logic [WIDTH-1:0] cmp;
logic [WIDTH-1:0] dvd_reg;
logic [$clog2(WIDTH+1)-1:0] cnt;
logic rdy_reg;

enum logic [2:0] {
  idle_s,
  calc_s
} fsm;

assign rdy = rdy_reg && !cal;
  
always @ (posedge clk) begin
  if (rst) begin
    fsm <= idle_s;
    dvd_reg  <= 0;
    rdy_reg <= 0;
    cmp <= 0;
    quo <= 0;
  end
  else begin
    case (fsm)
      idle_s : begin
        cnt <= 0;
        if (cal) begin
          $display("Divident: %d (%b). Divisor: %d (%b).", dvd, dvd, dvs, dvs);
          rdy_reg <= 0;
          quo <= 0;
          cmp <= 0;
          dvd_reg <= dvd;
          fsm <= calc_s;
        end
        else rdy_reg <= 1;
      end
      calc_s : begin
        dvd_reg[WIDTH-1:1] <= dvd_reg[WIDTH-2:0];
        dvd_reg[0] <= 0;
        quo[0] <= (cmp >= dvs);
        quo[WIDTH-1:1] <= quo[WIDTH-2:0];
        cmp[WIDTH-1:0] <= (cmp >= dvs) ? ({cmp[WIDTH-2:0] - dvs, dvd_reg[WIDTH-1]} ) : {cmp[WIDTH-2:0], dvd_reg[WIDTH-1]};
        cnt <= cnt + 1;
        if (cnt == WIDTH) begin
          rdy_reg <= 1;
          fsm <= idle_s;
          $display ("Result: %b. %d", quo, quo);
        end
      end
    endcase
  end
end

endmodule

`endif // MODULE_INT_DIVIDER
