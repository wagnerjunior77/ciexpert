package ufe8_pkg;
  timeunit 1ns;
  timeprecision 1ps;

  parameter int DATA_W = 8;
  parameter int REG_ADDR_W = 2;
  parameter int NUM_REGS = 1 << REG_ADDR_W;

  typedef logic [DATA_W-1:0] data_t;
  typedef logic [REG_ADDR_W-1:0] reg_addr_t;

  typedef enum logic [2:0] {
    OP_ADD    = 3'b000,
    OP_AND    = 3'b001,
    OP_XOR    = 3'b010,
    OP_OR     = 3'b011,
    OP_LD     = 3'b100,
    OP_ST     = 3'b101,
    OP_MOV    = 3'b110,
    OP_BRANCH = 3'b111
  } opcode_t;

  typedef enum logic [1:0] {
    BR_JC  = 2'b00,
    BR_JZ  = 2'b01,
    BR_JNZ = 2'b10,
    BR_JMP = 2'b11
  } branch_t;

  typedef enum logic [2:0] {
    ST_FETCH,
    ST_DECODE,
    ST_FETCH_CTE,
    ST_EXEC,
    ST_WRITE
  } cpu_state_t;
endpackage
