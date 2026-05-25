module controller
  import ufe8_pkg::*;
(
  input  logic       clk,
  input  logic       rst,
  input  opcode_t    op,
  input  logic       cte_bit,
  output cpu_state_t state,
  output logic       addr_pc,
  output logic       ir_wr,
  output logic       cte_wr,
  output logic       pc_inc,
  output logic       reg_wr,
  output logic       bus_wr,
  output logic       alu_en,
  output logic       use_cte
);
  timeunit 1ns;
  timeprecision 1ps;

  cpu_state_t state_q;
  cpu_state_t state_d;

  function automatic logic is_alu_op(input opcode_t opcode);
    return (opcode == OP_ADD) ||
           (opcode == OP_AND) ||
           (opcode == OP_XOR) ||
           (opcode == OP_OR);
  endfunction

  function automatic logic needs_cte(input opcode_t opcode, input logic cte);
    return cte || (opcode == OP_BRANCH);
  endfunction

  function automatic logic needs_reg_write(input opcode_t opcode);
    return is_alu_op(opcode) ||
           (opcode == OP_LD) ||
           (opcode == OP_MOV);
  endfunction

  always_ff @(posedge clk) begin
    if (rst) begin
      state_q <= ST_FETCH;
    end else begin
      state_q <= state_d;
    end
  end

  always_comb begin
    unique case (state_q)
      ST_FETCH: begin
        state_d = ST_DECODE;
      end

      ST_DECODE: begin
        if (needs_cte(op, cte_bit)) begin
          state_d = ST_FETCH_CTE;
        end else begin
          state_d = ST_EXEC;
        end
      end

      ST_FETCH_CTE: begin
        state_d = ST_EXEC;
      end

      ST_EXEC: begin
        if (needs_reg_write(op)) begin
          state_d = ST_WRITE;
        end else begin
          state_d = ST_FETCH;
        end
      end

      ST_WRITE: begin
        state_d = ST_FETCH;
      end

      default: begin
        state_d = ST_FETCH;
      end
    endcase
  end

  always_comb begin
    addr_pc = 1'b0;
    ir_wr   = 1'b0;
    cte_wr  = 1'b0;
    pc_inc  = 1'b0;
    reg_wr  = 1'b0;
    bus_wr  = 1'b0;
    alu_en  = 1'b0;
    use_cte = cte_bit;

    unique case (state_q)
      ST_FETCH: begin
        addr_pc = 1'b1;
        ir_wr   = 1'b1;
        pc_inc  = 1'b1;
      end

      ST_FETCH_CTE: begin
        addr_pc = 1'b1;
        cte_wr  = 1'b1;
        pc_inc  = 1'b1;
      end

      ST_EXEC: begin
        alu_en = is_alu_op(op);
        bus_wr = (op == OP_ST);
      end

      ST_WRITE: begin
        reg_wr = needs_reg_write(op);
      end

      default: begin
      end
    endcase
  end

  assign state = state_q;
endmodule
