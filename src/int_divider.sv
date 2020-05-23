module int_divider #(
  parameter WIDTH = 12
) 
(
  input logic clk,
  input logic rst,
  input logic [WIDTH-1:0] dvd, // divident
  input logic [WIDTH-1:0] dvs, // divisor
  output logic [WIDTH-1:0] quo,
  output logic rdy
);

logic [WIDTH-1:0] dvd_prev;
logic [WIDTH-1:0] dvs_prev;
logic [WIDTH-1:0] cmp;
logic [WIDTH-1:0] dvd_reg;
logic [$clog2(WIDTH+1)-1:0] cnt;

enum logic [2:0] {
  idle_s,
  calc_s
} fsm;
  
always @ (posedge clk) begin
  if (rst) begin
    fsm <= idle_s;
    dvd_prev <= 0;
    dvd_reg  <= 0;
    dvs_prev <= 0;
    rdy <= 0;
    cmp <= 0;
    quo <= 0;
  end
  else begin
    case (fsm)
      idle_s : begin
        cnt <= 0;
        dvd_prev <= dvd;
        dvs_prev <= dvs;
        if (dvd != dvd_prev || dvs != dvs_prev) begin
          $display("Divident: %d (%b). Divisor: %d (%b).", dvd, dvd, dvs, dvs);
          rdy <= 0;
          quo <= 0;
          cmp <= 0;
          dvd_reg <= dvd;
          fsm <= calc_s;
        end
        else rdy <= 1;
      end
      calc_s : begin
        dvd_reg[WIDTH-1:1] <= dvd_reg[WIDTH-2:0];
        dvd_reg[0] <= 0;
        quo[0] <= (cmp >= dvs);
        quo[WIDTH-1:1] <= quo[WIDTH-2:0];
        cmp[WIDTH-1:0] <= (cmp >= dvs) ? ({cmp[WIDTH-2:0] - dvs, dvd_reg[WIDTH-1]} ) : {cmp[WIDTH-2:0], dvd_reg[WIDTH-1]};
        cnt <= cnt + 1;
        if (cnt == WIDTH) begin
          rdy <= 1;
          fsm <= idle_s;
          $display ("Result: %b. %d", quo, quo);
        end
      end
    endcase
  end
end

endmodule
