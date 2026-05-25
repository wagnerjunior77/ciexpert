module tb_controller;
  timeunit 1ns;
  timeprecision 1ps;

  import ufe8_pkg::*;

  logic       clk;
  logic       rst;
  opcode_t    op;
  logic       cte_bit;
  branch_t    branch_sel;
  logic       carry_flag;
  logic       zero_flag;
  cpu_state_t state;
  logic       addr_pc;
  logic       ir_wr;
  logic       cte_wr;
  logic       pc_inc;
  logic       pc_load;
  logic       reg_wr;
  logic       bus_wr;
  logic       alu_en;
  logic       use_cte;

  controller dut (
    .clk     (clk),
    .rst     (rst),
    .op      (op),
    .cte_bit (cte_bit),
    .branch_sel (branch_sel),
    .carry_flag (carry_flag),
    .zero_flag  (zero_flag),
    .state   (state),
    .addr_pc (addr_pc),
    .ir_wr   (ir_wr),
    .cte_wr  (cte_wr),
    .pc_inc  (pc_inc),
    .pc_load (pc_load),
    .reg_wr  (reg_wr),
    .bus_wr  (bus_wr),
    .alu_en  (alu_en),
    .use_cte (use_cte)
  );

  always #5 clk = ~clk;

  task automatic check_state(input string name, input cpu_state_t exp_state);
    #1;
    if (state !== exp_state) begin
      $error("%s: esperado state=%0d, obtido state=%0d", name, exp_state, state);
    end
  endtask

  task automatic check_fetch_controls(input string name);
    #1;
    if (!addr_pc || !ir_wr || !pc_inc || pc_load || cte_wr || reg_wr || bus_wr || alu_en) begin
      $error("%s: controles de FETCH incorretos", name);
    end
  endtask

  task automatic check_fetch_cte_controls(input string name);
    #1;
    if (!addr_pc || !cte_wr || !pc_inc || pc_load || ir_wr || reg_wr || bus_wr || alu_en) begin
      $error("%s: controles de FETCH_CTE incorretos", name);
    end
  endtask

  task automatic tick;
    @(posedge clk);
  endtask

  task automatic reset_controller;
    rst     = 1'b1;
    op      = OP_MOV;
    cte_bit = 1'b0;
    branch_sel = BR_JMP;
    carry_flag = 1'b0;
    zero_flag  = 1'b0;
    tick();
    check_state("reset", ST_FETCH);
    rst = 1'b0;
  endtask

  task automatic check_mov_immediate_sequence;
    op      = OP_MOV;
    cte_bit = 1'b1;
    branch_sel = BR_JMP;

    check_state("MOV #i FETCH", ST_FETCH);
    check_fetch_controls("MOV #i FETCH");
    tick();

    check_state("MOV #i DECODE", ST_DECODE);
    tick();

    check_state("MOV #i FETCH_CTE", ST_FETCH_CTE);
    check_fetch_cte_controls("MOV #i FETCH_CTE");
    tick();

    check_state("MOV #i EXEC", ST_EXEC);
    if (alu_en || bus_wr || pc_load || reg_wr || !use_cte) begin
      $error("MOV #i EXEC: controles incorretos");
    end
    tick();

    check_state("MOV #i WRITE", ST_WRITE);
    if (!reg_wr) begin
      $error("MOV #i WRITE: reg_wr deveria estar ativo");
    end
    tick();

    check_state("MOV #i volta FETCH", ST_FETCH);
  endtask

  task automatic check_add_register_sequence;
    op      = OP_ADD;
    cte_bit = 1'b0;
    branch_sel = BR_JMP;

    check_state("ADD FETCH", ST_FETCH);
    tick();

    check_state("ADD DECODE", ST_DECODE);
    tick();

    check_state("ADD EXEC", ST_EXEC);
    if (!alu_en || bus_wr || pc_load || reg_wr || use_cte) begin
      $error("ADD EXEC: controles incorretos");
    end
    tick();

    check_state("ADD WRITE", ST_WRITE);
    if (!reg_wr) begin
      $error("ADD WRITE: reg_wr deveria estar ativo");
    end
    tick();

    check_state("ADD volta FETCH", ST_FETCH);
  endtask

  task automatic check_store_sequence;
    op      = OP_ST;
    cte_bit = 1'b0;
    branch_sel = BR_JMP;

    check_state("ST FETCH", ST_FETCH);
    tick();

    check_state("ST DECODE", ST_DECODE);
    tick();

    check_state("ST EXEC", ST_EXEC);
    if (!bus_wr || alu_en || pc_load || reg_wr) begin
      $error("ST EXEC: controles incorretos");
    end
    tick();

    check_state("ST volta FETCH", ST_FETCH);
  endtask

  task automatic check_branch_sequence;
    op      = OP_BRANCH;
    cte_bit = 1'b0;
    branch_sel = BR_JMP;
    carry_flag = 1'b0;
    zero_flag  = 1'b0;

    check_state("BRANCH FETCH", ST_FETCH);
    tick();

    check_state("BRANCH DECODE", ST_DECODE);
    tick();

    check_state("BRANCH FETCH_CTE", ST_FETCH_CTE);
    check_fetch_cte_controls("BRANCH FETCH_CTE");
    tick();

    check_state("BRANCH EXEC", ST_EXEC);
    if (alu_en || bus_wr || reg_wr || !pc_load) begin
      $error("BRANCH EXEC: controles incorretos");
    end
    tick();

    check_state("BRANCH volta FETCH", ST_FETCH);
  endtask

  task automatic check_conditional_branch_not_taken;
    op          = OP_BRANCH;
    cte_bit     = 1'b1;
    branch_sel  = BR_JZ;
    carry_flag  = 1'b0;
    zero_flag   = 1'b0;

    check_state("BRANCH NT FETCH", ST_FETCH);
    tick();

    check_state("BRANCH NT DECODE", ST_DECODE);
    tick();

    check_state("BRANCH NT FETCH_CTE", ST_FETCH_CTE);
    tick();

    check_state("BRANCH NT EXEC", ST_EXEC);
    if (pc_load) begin
      $error("BRANCH NT EXEC: pc_load nao deveria estar ativo");
    end
    tick();

    check_state("BRANCH NT volta FETCH", ST_FETCH);
  endtask

  initial begin
    $fsdbDumpfile("sim/tb_controller.fsdb");
    $fsdbDumpvars(0, tb_controller);

    clk = 1'b0;
    reset_controller();

    check_mov_immediate_sequence();
    check_add_register_sequence();
    check_store_sequence();
    check_branch_sequence();
    check_conditional_branch_not_taken();

    $display("tb_controller finalizado");
    $finish;
  end
endmodule
