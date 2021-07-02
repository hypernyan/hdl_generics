// SystemVerilog implementation of
// DOI: 10.1109/TC.2005.1
// Credits to Marcelo Kaihara and Naofumi Takagi

package mod_pkg;
  
  typedef enum logic [1:0] {
    neg, zer, pos
  } sd2;
    
  typedef struct packed  {
    sd2 s;
  } sd2_t;

endpackage : mod_pkg

import mod_pkg::*;

//////////////////////////////
// Redundant binary inverse //
//////////////////////////////
module sd2_inv #(
  parameter N = 8
)
(
  input  sd2_t [N-1:0] x,
  output sd2_t [N-1:0] o
);

always_comb begin
  for (int i = 0; i < N; i = i + 1) begin
    case (x[i])
      zer : o[i] <= zer;
      pos : o[i] <= neg;
      neg : o[i] <= pos;
      default : o[i] <= zer;
    endcase
  end
end

endmodule : sd2_inv

////////////////////////////
// Redundant binary adder //
////////////////////////////
module rba #(
  parameter N = 8
)
(
  input  sd2_t [N-1:0] x,
  input  sd2_t [N-1:0] y,
  output sd2_t [N:0]   o
);

  sd2_t  c [N:0];
  sd2_t  s [N:0];
  
  always_comb begin
    s[N] = zer;
    c[0] = zer;
    for (int i = 0; i < N; i = i + 1) begin
      case ({x[i], y[i]})
        ({pos, pos}) : begin
          c[i + 1] = pos;
          s[i]     = zer;
        end
        ({pos, zer}), ({zer, pos}) : begin
          if (i == 0) begin
            c[1] = pos;
            s[0] = neg;            
          end
          else begin
            if (x[i-1] == neg || y[i-1] == neg) begin
              c[i + 1] = zer;
              s[i]     = pos;
            end
            else begin
              c[i + 1] = pos;
              s[i]     = neg;              
            end
          end
        end      
        ({zer, zer}), ({pos, neg}), ({neg, pos}) : begin
          c[i + 1] = zer;
          s[i]     = zer;  
        end
        ({zer, neg}), ({neg, zer}) : begin
          if (i == 0) begin
            c[1] = zer;
            s[0] = neg;
          end
          else begin
            if (x[i-1] == neg || y[i-1] == neg) begin
              c[i + 1] = neg;
              s[i]     = pos;
            end
            else begin
              c[i + 1] = zer;
              s[i]     = neg;              
            end
          end
        end
        ({neg, neg}) : begin
          c[i + 1] = neg;
          s[i]     = zer;          
        end
        default : begin
          c[i + 1] = zer;
          s[i]     = zer;
        end
      endcase
    end
    for (int i = 0; i < N + 1; i = i + 1) begin
      case ({c[i], s[i]})
        ({pos, neg}),  ({neg, pos}), ({zer, zer}) : o[i] = zer;
        ({pos, zer}), ({zer, pos})                : o[i] = pos;
        ({neg, zer}), ({zer, neg})                : o[i] = neg;
        default : o[i] = zer;
      endcase
    end
  end

endmodule : rba

/////////////////////////////////////
// Redundant binary + binary adder //
/////////////////////////////////////
/*
module rbab #(
  parameter N = 8
)
(
  input  sd2_t [N-1:0] x,
  input  logic [N-1:0] y,
  output sd2_t [N:0]   o
);

  sd2_t [N:0] c, s;
  
  always_comb begin
    s[N] = zer;
    c[0] = zer;
    for (int i = 0; i < N; i = i + 1) begin
      case ({x[i], y[i]})
        ({pos, 1'b1}) : begin
          c[i + 1] = pos;
          s[i]     = zer;
        end
        ({pos, 1'b0}), ({zer, 1'b1}) : begin
          if (i == 0) begin
            c[1] = pos;
            s[0] = neg;            
          end
          else begin
            if (x[i-1] == neg) begin
              c[i + 1] = zer;
              s[i]     = pos;
            end
            else begin
              c[i + 1] = pos;
              s[i]     = neg;              
            end
          end
        end      
        ({zer, 1'b0}), ({neg, 1'b1}) : begin
          c[i + 1] = zer;
          s[i]     = zer;  
        end
        ({neg, 1'b0}) : begin
          if (i == 0) begin
            c[1] = zer;
            s[0] = neg;
          end
          else begin
            if (x[i-1] == neg) begin
              c[i + 1] = neg;
              s[i]     = pos;
            end
            else begin
              c[i + 1] = zer;
              s[i]     = neg;              
            end
          end
        end
      endcase
    end
    for (int i = 0; i < N + 1; i = i + 1) begin
      case ({c[i], s[i]})
        ({pos, neg}),  ({neg, pos}), ({zer, zer}) : o[i] = zer;
        ({pos, zer}), ({zer, pos})                : o[i] = pos;
        ({neg, zer}), ({zer, neg})                : o[i] = neg;
        default : $error("RBA error"); 
      endcase
    end
  end

endmodule : rbab
*/

////////////////
// Core logic //
////////////////

module mod_alu #(
  parameter int N = 8)
(
  input  logic clk,
  input  logic rst,
  input  logic mode,
  input  sd2_t [N-1:0] m,
  input  sd2_t [N-1:0] x,
  input  sd2_t [N-1:0] y,
  output sd2_t [N-1:0] z
);

  // Select RBA input of MQRTR oe MHLV operation
  function [1:0] op_sel;
    input sd2_t [1:0] a;
    input sd2_t       m1;
    input logic       op;
    case (op)
      0 : begin // mhlv
        op_sel = (a[0] == zer) ? 0 : 1;
      end
      1 : begin // mqrtr
        case (a)
      /* 0->0 */ ({zer, zer}) : op_sel = 0; // ()
      /* 1->1 */ ({zer, pos}),
      /* 1->1 */ ({pos, neg}) : op_sel = (m1 == pos) ? 1 : 3;
      /*-2->2 */ ({neg, zer}),
      /* 2->2 */ ({pos, zer}) : op_sel = 2;
      /*-1->3 */ ({zer, neg}),
      /*-1->3 */ ({neg, pos}),
      /* 3->3 */ ({neg, neg}),
      /* 3->3 */ ({pos, pos})  : op_sel = (m1 == pos) ? 3 : 1;
          default : op_sel = 0;
        endcase
      end
    endcase
    $display("selected: %d", op_sel);

  endfunction : op_sel
  
  parameter sd2_t [N-1:0] zer_v   = {N{zer}};
  parameter sd2_t [N-1:0] neglsb_v = {{(N-1){zer}}, neg};
  
  logic [1:0] state, state_nxt;
  
  logic [1:0] sel1, sel2, sel3, sel4, sel6, sel7, sel8, sel9, sel10;
  logic [2:0] sel5;
  
  
  logic [N+1:0] p, d;

  logic op, s, sreg;

  sd2_t [2:0] lsb;

  sd2_t [N-1:0] a, b, bi, u, v, vi, mi, rba1x, rba1y, rba3x, rba3y;
  sd2_t [N  :0] rba2x, rba2y, rba1, rba3;
  sd2_t [N+1:0] rba2;
  
  assign rba3x = u;

  // A+-B
  rba #(
    .N (N)
  ) rba1_inst (
    .x   (rba1x),
    .y   (rba1y),
    .o   (rba1)
  );
  
  assign rba1x = a;
  
  // MQRTR or MHLV
  rba #(
    .N (N+1)
  ) rba2_inst (
    .x   (rba2x),
    .y   (rba2y),
    .o   (rba2)
  );

  // U+-V
  rba #(
    .N (N)
  ) rba3_inst (
    .x   (rba3x),
    .y   (rba3y),
    .o   (rba3)
  );
  
  rba #(
    .N (2)
  ) rba_lsb_inst (
    .x   (a[1:0]),
    .y   (b[1:0]),
    .o   (lsb)
  );

  always @ (posedge clk) state <= state_nxt;
  always @ (posedge clk) sreg <= s;
  
  always_comb begin
    if (rst) begin
      z <= {N{zer}};
      state_nxt <= 0;
      sel1 <= 0;
      sel2 <= 0;
      sel4 <= 0;
      sel5 <= 0;
      sel6 <= 0;
      sel8 <= 0;
      sel9 <= 0;
      s    <= 0;
      op   <= 0;
    end
    else begin
      case (state)
        0 : begin
          z <= {N{zer}};
          state_nxt <= 1;
          sel1 <= 0;
          sel2 <= 0;
          sel4 <= 0;
          sel5 <= 0;
          sel6 <= 0;
          sel8 <= 0;
          sel9 <= 0;
          s    <= 1;
          op   <= 0;
        end
        1 : begin
          z <= {N{zer}};
          if (p[0]) begin
            state_nxt <= 2;
            sel1 <= 1;
            sel2 <= 1;
            sel4 <= 1;
            sel5 <= 1;
            sel6 <= 1;
            sel8 <= 0;
            sel9 <= 1;
            s    <= sreg;
            op   <= 0;
          end
          else begin 
            state_nxt <= 1;
            // Amod4 = 0
            if (a[1:0] == {zer, zer}) begin
              sel8 <= 0; // U
              sel1 <= 2; // A:=A>>2
              sel2 <= 1; // B:=B
              sel6 <= 2; // U:=MQRTR(U,M)
              sel9 <= 1; // V:=V
              op   <= 1; // MQRTR
              if (!sreg) begin
                if (!d[1]) begin
                  sel4 <= 1; // P:=P
                  sel5 <= 3; // D:=D>>2
                end
                else begin
                  sel4 <= 2; // P:=P>>1
                  sel5 <= 1; // D:=D
                end
                s <= (d[1] || d[2]) ? 1 : sreg;
              end
              else begin
                sel5 <= 5; // D:=D<<2
                if (!p[1]) begin
                  sel4 <= 3; // P:=P>>2
                  s <= sreg;
                end
                else begin
                  sel4 <= 2; // P:=P>>1
                  s <= 0;
                end
              end
            end
            // Amod4 = 2
            else if (a[0] == zer) begin
              sel1 <= 1; // A:=A>>1
              sel2 <= 1; // B:=B
              sel6 <= 3; // U:=MHLV(U,M)
              sel8 <= 0; // U for op
              sel9 <= 1; // V:=V
              op   <= 0; // MHLV
              if (!sreg) begin
                s <= (d[1]) ? 1 : sreg;
                sel4 <= 1; // P:=P
                sel5 <= 2; // D:=D>>1
              end
              else begin
                s <= sreg;
                sel4 <= 2; // P:=P>>1
                sel5 <= 4; // D:=D<<1
              end
            end
            // Amod4 == 1|3
            else begin
              sel8 <= 1; // U+qV
              sel1 <= 3; // A:=RBA1>>2
              sel6 <= 2; // U:=MQRTR(U+qV,M)
              op   <= 1; // MQRTR
              if (!mode || !sreg || d[0]) begin
                sel9 <= 1; // V:=U
                sel2 <= 1; // B:=B
                if (sreg) begin
                  sel5 <= 4; // D:=D<<1
                  if (!mode && !p[1]) begin
                    s <= sreg;
                    sel4 <= 3; // P:=P>>2
                  end
                  else begin
                    s <= (p[1]) ? 0 : sreg;
                    sel4 <= 2; // P:=P>>1
                  end
                end
                else begin // s = 0
                  sel4 <= 1; // P:=P
                  sel5 <= 2; // D:=D>>1
                  s <= (d[1]) ? 1 : sreg;
                end
              end
              else begin 
                sel4 <= 1; // P:=P
                sel2 <= 2; // B:=A
                sel9 <= 2; // V:=U
                sel5 <= 2; // D:=D>>1
                s <= (!d[1]) ? 0 : sreg;
              end
            end
          end
        end
        2 : begin
          state_nxt <= 3;
          sel4 <= 1;
          sel2 <= 1;
          sel1 <= 0; // A:=RBA1>>2
          sel5 <= 0;
          sel8 <= 0; // U
          s <= sreg;
          z <= {N{zer}};
          op   <= 0; // MHLV
          if (!mode && sreg) begin
            sel6 <= 3; // U:=MHLV(U,M)
            sel9 <= 1; // V:=V
          end
          else if (mode && ((b[1:0] == {pos, pos}) || (b[1:0] == {neg, pos}) || (b[1:0] == {zer, neg}))) begin
            sel6 <= 1; // U:=U
            sel9 <= 3; // V:=-V
          end
          else begin
            sel6 <= 1; // U:=U
            sel9 <= 1; // V:=V
          end
        end
        3 : begin
          s <= sreg;
           sel8 <= 0; // U
           sel1 <= 0;
           sel2 <= 0;
           sel4 <= 0;
           sel5 <= 0;
           sel6 <= 1;
           sel9 <= 0;
          op   <= 0;
          z <= (mode) ? v : u;
          state_nxt <= 0;
        end
      endcase
    end
  end

  always_comb begin
    if (lsb[1:0] == {zer, zer}) begin
      sel10 <= 0;
      sel3  <= 0;
    end
    else begin
      sel10 <= 1;
      sel3  <= 1;
    end
  end
  always_comb begin
    case (sel8)
      0 : begin
      //  rba2x <= u;
        rba2x[N] <= zer;
        rba2x[N-1:0] <= u;

      end
      1 : rba2x <= rba3;
    endcase
  end
  always_comb begin
    sel7 <= op_sel(rba2x[1:0], m[1], op);
  end

  always_comb begin
    case (sel7)
      0 : rba2y <= {(N+1){zer}}; // RBAY1:=0
      1 : rba2y <= {zer, m};     // RBAY1:=M
      2 : begin
        rba2y[N:1] <= m[N-1:0];   // RBAY1:=M<<1
        rba2y[0] <= zer;
      end
      3 : rba2y <= {zer, mi};     // RBAY1:=-M
      default : rba2y <= {(N+1){zer}};
    endcase
  end

  always_comb begin
    case (sel3)
      0 : rba1y <= b;  // RBAY1:=B
      1 : rba1y <= bi; // RBAY1:=-B
    endcase
  end
  
  always_comb begin
    case (sel10)
      0 : rba3y <= v;  // V:=V
      1 : rba3y <= vi; // V:=-V
    endcase
  end

  always_ff @ (posedge clk) begin
    case (sel1)
      0 : begin
        a <= y;                 // init
      end
      1 : begin
        a[N-2:0] <= a[N-1:1];   // A:=A>>1
        a[N-1]   <= zer;
      end
      2 : begin
        a[N-3:0]   <= a[N-1:2]; // A:=A>>2
        a[N-1:N-2] <= {zer, zer};
      end
      3 : begin
        a[N-2:0] <= rba1[N:2];  // A:=RBA1>>2
        a[N-1]   <= zer;
      end
    endcase
    case (sel2)
      0 : b <= (mode) ? m : neglsb_v; // init
      1 : b <= b;                     // B:=B
      2 : b <= a;                     // B:=A
    endcase
    case (sel4)
      0 : p <= {1'b1, {(N+1){1'b0}}}; // P:=10..0 init
      1 : p <= p;                     // P:=P
      2 : p <= p >> 1;                // P:=P>>1
      3 : p <= p >> 2;                // P:=P>>2
    endcase
    case (sel5)
      0 : d <= 1;      // D:=0..01 init
      1 : d <= d;      // D:=D
      2 : d <= d >> 1; // D:=D>>1
      3 : d <= d >> 2; // D:=D>>2
      4 : d <= d << 1; // D:=D<<1
      5 : d <= d << 2; // D:=D<<2
    endcase
    case (sel6)
      0 : begin
        u <= (mode) ? x : zer_v; // init
      end
      1 : begin
        u <= u;  // U:=U
      end
      2 : begin
        u[N-1:0] <= rba2[N+1:2];  // MQRTR(U+qV)
      end
      3 : begin
        u[N-1:0] <= (u[0] == zer) ? {zer, u[N-1:1]} : rba2[N:1];  // MHLV(U)
      end
    endcase
    case (sel9)
      0 : v <= (mode) ? zer_v : x;
      1 : v <= v;
      2 : v <= u;
      3 : v <= vi;
    endcase
  end
  
  sd2_inv #(
    .N (N)
  ) sd2_b_inv_inst
  (
    .x (b),
    .o (bi)
  );
  
  sd2_inv #(
    .N (N)
  ) sd2_v_inv_inst
  (
    .x (v),
    .o (vi)
  );
  
  sd2_inv #(
    .N (N)
  ) sd2_m_inv_inst
  (
    .x (m),
    .o (mi)
  );

endmodule : mod_alu
