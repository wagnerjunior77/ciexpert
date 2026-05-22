module tb_regs;
  timeunit 1ns;
  timeprecision 1ps;

  import ufe8_pkg::*;

  logic      clk;
  logic      rst;
  logic      wr;
  reg_addr_t rs_addr;
  reg_addr_t rd_addr;
  reg_addr_t wr_addr;
  data_t     wr_data;
  data_t     rs_data;
  data_t     rd_data;

  regs dut (
    .clk     (clk),
    .rst     (rst),
    .wr      (wr),
    .rs_addr (rs_addr),
    .rd_addr (rd_addr),
    .wr_addr (wr_addr),
    .wr_data (wr_data),
    .rs_data (rs_data),
    .rd_data (rd_data)
  );

  always #5 clk = ~clk;

  task automatic write_reg(
    input reg_addr_t addr,
    input data_t     data
  );
    wr_addr = addr;
    wr_data = data;
    wr      = 1'b1;
    @(posedge clk);
    #1;
    wr      = 1'b0;
  endtask

  task automatic check_read(
    input string     name,
    input reg_addr_t exp_rs_addr,
    input data_t     exp_rs_data,
    input reg_addr_t exp_rd_addr,
    input data_t     exp_rd_data
  );
    rs_addr = exp_rs_addr;
    rd_addr = exp_rd_addr;
    #1;
    if ((rs_data !== exp_rs_data) || (rd_data !== exp_rd_data)) begin
      $error(
        "%s: esperado rs=0x%02h rd=0x%02h, obtido rs=0x%02h rd=0x%02h",
        name, exp_rs_data, exp_rd_data, rs_data, rd_data
      );
    end
  endtask

  initial begin
    $fsdbDumpfile("sim/tb_regs.fsdb");
    $fsdbDumpvars(0, tb_regs);

    clk     = 1'b0;
    rst     = 1'b1;
    wr      = 1'b0;
    rs_addr = 2'b00;
    rd_addr = 2'b01;
    wr_addr = 2'b00;
    wr_data = '0;

    @(posedge clk);
    #1;
    check_read("reset R0 e R1", 2'b00, 8'h00, 2'b01, 8'h00);
    check_read("reset R2 e R3", 2'b10, 8'h00, 2'b11, 8'h00);

    rst = 1'b0;

    write_reg(2'b00, 8'h11);
    write_reg(2'b01, 8'h22);
    write_reg(2'b10, 8'h33);
    write_reg(2'b11, 8'h44);

    check_read("le R0 e R1", 2'b00, 8'h11, 2'b01, 8'h22);
    check_read("le R2 e R3", 2'b10, 8'h33, 2'b11, 8'h44);

    wr_addr = 2'b01;
    wr_data = 8'haa;
    wr      = 1'b0;
    @(posedge clk);
    #1;
    check_read("wr desabilitado", 2'b01, 8'h22, 2'b11, 8'h44);

    rst = 1'b1;
    @(posedge clk);
    #1;
    check_read("reset depois de escrita", 2'b00, 8'h00, 2'b11, 8'h00);

    $display("tb_regs finalizado");
    $finish;
  end
endmodule
