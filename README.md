# uFe-8 RTL

Implementacao didatica do processador uFe-8 para o desafio RTL Synopsys/UnB.

O objetivo e construir a CPU em etapas pequenas:

- ULA (`rtl/alu.sv`)
- banco de registradores (`rtl/regs.sv`)
- controlador/FSM (`rtl/controller.sv`)
- integracao da CPU (`rtl/cpu.sv`)
- testbenches em `tb/`

## Preparar ambiente

Antes de compilar ou abrir waveform:

```bash
source /opt/synopsys/env/synopsys.sh
```

## Compilar e simular

Os comandos abaixo geram executaveis dentro de `sim/` e logs tambem em `sim/`.

### ULA

```bash
vcs -full64 -sverilog -debug_access+all -kdb \
  rtl/ufe8_pkg.sv rtl/alu.sv tb/tb_alu.sv \
  -o sim/simv_alu -l sim/compile_alu.log

./sim/simv_alu -l sim/run_alu.log
```

### Banco de registradores

```bash
vcs -full64 -sverilog -debug_access+all -kdb \
  rtl/ufe8_pkg.sv rtl/regs.sv tb/tb_regs.sv \
  -o sim/simv_regs -l sim/compile_regs.log

./sim/simv_regs -l sim/run_regs.log
```

### Controller

```bash
vcs -full64 -sverilog -debug_access+all -kdb \
  rtl/ufe8_pkg.sv rtl/controller.sv tb/tb_controller.sv \
  -o sim/simv_controller -l sim/compile_controller.log

./sim/simv_controller -l sim/run_controller.log
```

### CPU: programa simples

Programa testado:

```asm
MOV #1, R0
MOV #2, R1
ADD R0, R1
```

Comando:

```bash
vcs -full64 -sverilog -debug_access+all -kdb \
  rtl/ufe8_pkg.sv rtl/controller.sv rtl/regs.sv rtl/alu.sv rtl/cpu.sv tb/tb_cpu.sv \
  -o sim/simv_cpu -l sim/compile_cpu.log

./sim/simv_cpu -l sim/run_cpu.log
```

### CPU: branches

Testa `JC`, `JZ`, `JNZ` e `JMP`.

```bash
vcs -full64 -sverilog -debug_access+all -kdb \
  rtl/ufe8_pkg.sv rtl/controller.sv rtl/regs.sv rtl/alu.sv rtl/cpu.sv tb/tb_cpu_branch.sv \
  -o sim/simv_cpu_branch -l sim/compile_cpu_branch.log

./sim/simv_cpu_branch -l sim/run_cpu_branch.log
```

## Abrir waveform no Verdi

Cada testbench gera um `.fsdb` em `sim/`.

Exemplo para a CPU:

```bash
verdi -sv \
  rtl/ufe8_pkg.sv rtl/controller.sv rtl/regs.sv rtl/alu.sv rtl/cpu.sv tb/tb_cpu.sv \
  -ssf sim/tb_cpu.fsdb &
```

Exemplo para branches:

```bash
verdi -sv \
  rtl/ufe8_pkg.sv rtl/controller.sv rtl/regs.sv rtl/alu.sv rtl/cpu.sv tb/tb_cpu_branch.sv \
  -ssf sim/tb_cpu_branch.fsdb &
```

## Arquivos gerados

Arquivos de simulacao e debug nao devem ser versionados:

- `csrc/`
- `sim/simv_*`
- `sim/*.daidir/`
- `*.log`
- `*.fsdb`
- `novas_dump.log`
- `ucli.key`

Esses arquivos sao recriados pelo VCS/Verdi quando as simulacoes rodam.
