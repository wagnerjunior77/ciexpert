module tb_cpu_branch;
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
    $fsdbDumpfile("sim/tb_cpu_branch.fsdb");
    $fsdbDumpvars(0, tb_cpu_branch);

    for (int i = 0; i < 256; i++) begin
      rom[i] = '0;
    end

    rom[8'h00] = {OP_MOV, 1'b1, 2'b00, 2'b00};       // MOV #0xff, R0
    rom[8'h01] = 8'hff;
    rom[8'h02] = {OP_ADD, 1'b1, 2'b00, 2'b00};       // ADD #1, R0 -> zero=1, carry=1
    rom[8'h03] = 8'h01;
    rom[8'h04] = {OP_BRANCH, 1'b0, 2'b00, BR_JC};   // JC 0x08
    rom[8'h05] = 8'h08;
    rom[8'h06] = {OP_MOV, 1'b1, 2'b00, 2'b01};       // MOV #0xee, R1 (deve pular)
    rom[8'h07] = 8'hee;

    rom[8'h08] = {OP_BRANCH, 1'b1, 2'b00, BR_JZ};   // JZ 0x0c
    rom[8'h09] = 8'h0c;
    rom[8'h0a] = {OP_MOV, 1'b1, 2'b00, 2'b01};       // MOV #0xdd, R1 (deve pular)
    rom[8'h0b] = 8'hdd;

    rom[8'h0c] = {OP_BRANCH, 1'b1, 2'b00, BR_JNZ};  // JNZ 0x10 (nao deve pular)
    rom[8'h0d] = 8'h10;
    rom[8'h0e] = {OP_MOV, 1'b1, 2'b00, 2'b01};       // MOV #0x11, R1
    rom[8'h0f] = 8'h11;

    rom[8'h10] = {OP_ADD, 1'b1, 2'b00, 2'b01};       // ADD #1, R1 -> zero=0
    rom[8'h11] = 8'h01;
    rom[8'h12] = {OP_BRANCH, 1'b1, 2'b00, BR_JNZ};  // JNZ 0x16
    rom[8'h13] = 8'h16;
    rom[8'h14] = {OP_MOV, 1'b1, 2'b00, 2'b10};       // MOV #0xee, R2 (deve pular)
    rom[8'h15] = 8'hee;

    rom[8'h16] = {OP_MOV, 1'b1, 2'b00, 2'b10};       // MOV #0x22, R2
    rom[8'h17] = 8'h22;
    rom[8'h18] = {OP_BRANCH, 1'b1, 2'b00, BR_JMP};  // JMP 0x1c
    rom[8'h19] = 8'h1c;
    rom[8'h1a] = {OP_MOV, 1'b1, 2'b00, 2'b11};       // MOV #0xee, R3 (deve pular)
    rom[8'h1b] = 8'hee;

    rom[8'h1c] = {OP_MOV, 1'b1, 2'b00, 2'b11};       // MOV #0x33, R3
    rom[8'h1d] = 8'h33;

    clk = 1'b0;
    rst = 1'b1;

    repeat (2) @(posedge clk);
    #1;
    rst = 1'b0;

    wait (dut.pc_q == 8'h1e && dut.state == ST_FETCH);
    #1;

    check_reg("programa branch", 0, 8'h00);
    check_reg("programa branch", 1, 8'h12);
    check_reg("programa branch", 2, 8'h22);
    check_reg("programa branch", 3, 8'h33);

    if (dut.carry_q || dut.zero_q) begin
      $error("flags finais inesperadas: carry=%0b zero=%0b", dut.carry_q, dut.zero_q);
    end

    $display("tb_cpu_branch finalizado");
    $finish;
  end
endmodule
