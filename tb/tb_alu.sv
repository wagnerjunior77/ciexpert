module tb_alu;
  timeunit 1ns;
  timeprecision 1ps;

  import ufe8_pkg::*;

  data_t   a;
  data_t   b;
  opcode_t op;
  logic    carry_in;
  data_t   result;
  logic    zero;
  logic    carry;

  alu dut (
    .a        (a),
    .b        (b),
    .op       (op),
    .carry_in (carry_in),
    .result   (result),
    .zero     (zero),
    .carry    (carry)
  );

  task automatic check(
    input string   name,
    input data_t   exp_result,
    input logic    exp_zero,
    input logic    exp_carry
  );
    #1;
    if ((result !== exp_result) || (zero !== exp_zero) || (carry !== exp_carry)) begin
      $error(
        "%s: esperado result=0x%02h zero=%0b carry=%0b, obtido result=0x%02h zero=%0b carry=%0b",
        name, exp_result, exp_zero, exp_carry, result, zero, carry
      );
    end
  endtask

  initial begin
    $fsdbDumpfile("sim/tb_alu.fsdb");
    $fsdbDumpvars(0, tb_alu);

    carry_in = 1'b0;

    a = 8'h02;
    b = 8'h01;
    op = OP_ADD;
    check("ADD simples", 8'h03, 1'b0, 1'b0);

    a = 8'hff;
    b = 8'h01;
    op = OP_ADD;
    check("ADD com carry", 8'h00, 1'b1, 1'b1);

    a = 8'hf0;
    b = 8'h0f;
    op = OP_AND;
    check("AND com zero", 8'h00, 1'b1, 1'b0);

    a = 8'haa;
    b = 8'h0f;
    op = OP_XOR;
    check("XOR", 8'ha5, 1'b0, 1'b0);

    a = 8'ha0;
    b = 8'h0f;
    op = OP_OR;
    check("OR", 8'haf, 1'b0, 1'b0);

    $display("tb_alu finalizado");
    $finish;
  end
endmodule
