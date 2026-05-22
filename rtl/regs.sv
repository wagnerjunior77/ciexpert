module regs
  import ufe8_pkg::*;
(
  input  logic      clk,
  input  logic      rst,
  input  logic      wr,
  input  reg_addr_t rs_addr,
  input  reg_addr_t rd_addr,
  input  reg_addr_t wr_addr,
  input  data_t     wr_data,
  output data_t     rs_data,
  output data_t     rd_data
);
  timeunit 1ns;
  timeprecision 1ps;

  data_t regs_q [NUM_REGS];

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < NUM_REGS; i++) begin
        regs_q[i] <= '0;
      end
    end else if (wr) begin
      regs_q[wr_addr] <= wr_data;
    end
  end

  assign rs_data = regs_q[rs_addr];
  assign rd_data = regs_q[rd_addr];
endmodule
