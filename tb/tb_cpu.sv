module tb_cpu;
  timeunit 1ns;
  timeprecision 1ps;

  import ufe8_pkg::*;

  logic  clk;
  logic  rst;
  data_t bus_in;
  data_t bus_out;
  data_t addr;
  logic  bus_wr;
  data_t rom [256];

  cpu dut (
    .clk     (clk),
    .rst     (rst),
    .bus_in  (bus_in),
    .bus_out (bus_out),
    .addr    (addr),
    .bus_wr  (bus_wr)
  );

  assign bus_in = rom[addr];

  always #5 clk = ~clk;

  task automatic check_reg(input string name, input int index, input data_t expected);
    if (dut.u_regs.regs_q[index] !== expected) begin
      $error(
        "%s: esperado R%0d=0x%02h, obtido R%0d=0x%02h",
        name, index, expected, index, dut.u_regs.regs_q[index]
      );
    end
  endtask

  initial begin
    $fsdbDumpfile("sim/tb_cpu.fsdb");
    $fsdbDumpvars(0, tb_cpu);

    for (int i = 0; i < 256; i++) begin
      rom[i] = '0;
    end

    rom[8'h00] = {OP_MOV, 1'b1, 2'b00, 2'b00}; // MOV #1, R0
    rom[8'h01] = 8'h01;
    rom[8'h02] = {OP_MOV, 1'b1, 2'b00, 2'b01}; // MOV #2, R1
    rom[8'h03] = 8'h02;
    rom[8'h04] = {OP_ADD, 1'b0, 2'b00, 2'b01}; // ADD R0, R1

    clk = 1'b0;
    rst = 1'b1;

    repeat (2) @(posedge clk);
    #1;
    rst = 1'b0;

    repeat (14) @(posedge clk);
    #1;

    check_reg("programa simples", 0, 8'h01);
    check_reg("programa simples", 1, 8'h03);

    if (dut.pc_q !== 8'h05) begin
      $error("PC esperado=0x05, obtido=0x%02h", dut.pc_q);
    end

    $display("tb_cpu finalizado");
    $finish;
  end
endmodule
