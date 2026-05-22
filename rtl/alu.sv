module alu
  import ufe8_pkg::*;
(
  input  data_t   a,
  input  data_t   b,
  input  opcode_t op,
  input  logic    carry_in,
  output data_t   result,
  output logic    zero,
  output logic    carry
);
  timeunit 1ns;
  timeprecision 1ps;

  logic [DATA_W:0] add_ext;

  always_comb begin
    add_ext = '0;
    result  = '0;
    carry   = 1'b0;

    unique case (op)
      OP_ADD: begin
        add_ext = {1'b0, a} + {1'b0, b} + carry_in;
        result  = add_ext[DATA_W-1:0];
        carry   = add_ext[DATA_W];
      end

      OP_AND: result = a & b;
      OP_XOR: result = a ^ b;
      OP_OR:  result = a | b;

      default: result = '0;
    endcase
  end

  assign zero = (result == '0);
endmodule
