module cpu
  import ufe8_pkg::*;
(
  input  logic  clk,
  input  logic  rst,
  input  data_t bus_in,
  output data_t bus_out,
  output data_t addr,
  output logic  bus_wr
);
  timeunit 1ns;
  timeprecision 1ps;

  data_t pc_q;
  data_t ir_q;
  data_t cte_q;
  logic  carry_q;
  logic  zero_q;

  opcode_t   op;
  logic      cte_bit;
  reg_addr_t rs_addr;
  reg_addr_t rd_addr;
  data_t     rs_data;
  data_t     rd_data;
  data_t     reg_wr_data;
  data_t     alu_b;
  data_t     alu_result;
  logic      alu_zero;
  logic      alu_carry;

  cpu_state_t state;
  logic       addr_pc;
  logic       ir_wr;
  logic       cte_wr;
  logic       pc_inc;
  logic       reg_wr;
  logic       alu_en;
  logic       use_cte;

  assign op       = opcode_t'(ir_q[7:5]);
  assign cte_bit  = ir_q[4];
  assign rs_addr  = ir_q[3:2];
  assign rd_addr  = ir_q[1:0];
  assign alu_b    = use_cte ? cte_q : rs_data;
  assign bus_out  = use_cte ? cte_q : rs_data;

  controller u_controller (
    .clk     (clk),
    .rst     (rst),
    .op      (op),
    .cte_bit (cte_bit),
    .state   (state),
    .addr_pc (addr_pc),
    .ir_wr   (ir_wr),
    .cte_wr  (cte_wr),
    .pc_inc  (pc_inc),
    .reg_wr  (reg_wr),
    .bus_wr  (bus_wr),
    .alu_en  (alu_en),
    .use_cte (use_cte)
  );

  regs u_regs (
    .clk     (clk),
    .rst     (rst),
    .wr      (reg_wr),
    .rs_addr (rs_addr),
    .rd_addr (rd_addr),
    .wr_addr (rd_addr),
    .wr_data (reg_wr_data),
    .rs_data (rs_data),
    .rd_data (rd_data)
  );

  alu u_alu (
    .a        (rd_data),
    .b        (alu_b),
    .op       (op),
    .carry_in (1'b0),
    .result   (alu_result),
    .zero     (alu_zero),
    .carry    (alu_carry)
  );

  always_ff @(posedge clk) begin
    if (rst) begin
      pc_q    <= '0;
      ir_q    <= '0;
      cte_q   <= '0;
      carry_q <= 1'b0;
      zero_q  <= 1'b0;
    end else begin
      if (ir_wr) begin
        ir_q <= bus_in;
      end

      if (cte_wr) begin
        cte_q <= bus_in;
      end

      if (pc_inc) begin
        pc_q <= pc_q + 8'd1;
      end

      if (alu_en) begin
        carry_q <= alu_carry;
        zero_q  <= alu_zero;
      end
    end
  end

  always_comb begin
    unique case (op)
      OP_LD:   reg_wr_data = bus_in;
      OP_MOV:  reg_wr_data = use_cte ? cte_q : rs_data;
      default: reg_wr_data = alu_result;
    endcase
  end

  always_comb begin
    addr = pc_q;

    if (!addr_pc) begin
      unique case (op)
        OP_LD: begin
          addr = use_cte ? cte_q : rs_data;
        end

        OP_ST: begin
          addr = rd_data;
        end

        default: begin
          addr = pc_q;
        end
      endcase
    end
  end
endmodule
