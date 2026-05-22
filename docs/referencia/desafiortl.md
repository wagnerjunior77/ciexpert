# uFe-8 - Briefing do Desafio RTL

## 1. Visao geral

O desafio consiste em implementar em RTL um processador simples de 8 bits chamado uFe-8.

O uFe-8 e inspirado no MSP430, mas foi simplificado para fins didaticos. A ideia e conectar conceitos de Sistemas Digitais e Sistemas Microprocessados.

Neste desafio, o objetivo e implementar apenas o processador, nao o sistema completo com ROM, RAM e perifericos reais.

O sistema completo seria formado por:

- CPU/processador
- ROM para instrucoes
- RAM para pilha/dados
- Perifericos mapeados em memoria, como GPIO, timers, ADC etc.

Mas o foco do desafio atual e a CPU.

---

## 2. Componentes principais da CPU

A CPU possui:

- Banco de registradores
- ULA
- Registradores internos
- Controlador baseado em maquina de estados
- Barramento externo para comunicacao com memoria/perifericos

Os principais blocos sao:

- PC
- IR
- CTE
- REGS
- ULA
- Controller/FSM
- Muxes do datapath
- Barramento externo

---

## 3. Registradores de uso geral

O processador possui 4 registradores de uso geral:

- R0
- R1
- R2
- R3

Cada registrador tem 8 bits.

Esses registradores sao usados diretamente pelas instrucoes.

Exemplos:

```asm
MOV #1, R0
MOV #2, R1
ADD R0, R1

Nesse exemplo:

R0 recebe o valor 1
R1 recebe o valor 2
depois R1 recebe R1 + R0
4. Registradores internos

Alem dos registradores R0 a R3, a CPU possui registradores internos.

Esses registradores nao sao usados diretamente pelo programador, mas sao essenciais para o funcionamento da CPU.

4.1 PC - Program Counter

O PC guarda o endereco da proxima instrucao ou byte que sera buscado na ROM.

Exemplo:

PC = 0x00 -> CPU busca ROM[0x00]
PC = 0x01 -> CPU busca ROM[0x01]
PC = 0x02 -> CPU busca ROM[0x02]

Normalmente, o PC incrementa de 1 em 1.

Mas em instrucoes de salto, como JMP, JC, JZ e JNZ, o PC pode receber outro endereco.

O PC responde a pergunta:

Qual e o proximo byte que a CPU deve buscar?
4.2 IR - Instruction Register

O IR guarda a instrucao atual.

Fluxo basico:

1. PC aponta para um endereco da ROM
2. CPU le o byte nesse endereco
3. esse byte e guardado no IR
4. a CPU decodifica o IR

O IR e a "instrucao atual" que a CPU esta executando.

4.3 CTE - Constante/imediato

O CTE guarda uma constante usada por instrucoes em modo imediato.

Exemplo:

MOV #1, R0

O valor 1 e uma constante imediata.

Como a instrucao principal tem apenas 8 bits, essa constante nao fica no mesmo byte da instrucao. Ela fica no proximo endereco da ROM.

Exemplo:

ROM[0] = instrucao MOV #i, R0
ROM[1] = valor 1

A CPU precisa:

1. buscar a instrucao
2. perceber que ela usa constante
3. buscar o proximo byte da ROM
4. guardar esse byte em CTE
5. usar CTE na execucao
5. Formato da instrucao

Cada instrucao tem 8 bits.

Formato:

OP C SS DD

Ou bit a bit:

op2 op1 op0 cte s1 s0 d1 d0

Campos:

OP = opcode da instrucao, com 3 bits
C  = bit de constante/imediato
SS = registrador fonte, com 2 bits
DD = registrador destino, com 2 bits

Como existem 4 registradores, 2 bits sao suficientes para selecionar cada um:

00 = R0
01 = R1
10 = R2
11 = R3

O campo SS seleciona a fonte quando a instrucao usa registrador.

O campo DD seleciona o destino.

6. Significado do bit C

O bit C indica se a fonte da instrucao e um registrador ou uma constante imediata.

6.1 Quando C = 0

A fonte vem de um registrador.

Exemplo:

ADD R0, R1

Significado:

R1 = R1 + R0

Nesse caso:

C = 0
SS = R0
DD = R1

A instrucao ocupa apenas 1 byte na ROM.

6.2 Quando C = 1

A fonte vem de uma constante imediata.

Exemplo:

MOV #1, R0

Significado:

R0 = 1

Nesse caso:

C = 1
DD = R0

A constante 1 fica no proximo byte da ROM.

Exemplo:

ROM[0] = instrucao MOV #i, R0
ROM[1] = constante 1

Por isso a CPU precisa do estado FETCH_CTE.

7. Modos de enderecamento

A sintaxe geral das instrucoes e:

INSTR SRC, DST

Onde:

SRC = fonte
DST = destino

A fonte pode ser:

Rs = registrador fonte
#i = imediato/constante

O destino pode ser:

Rd = registrador destino

Exemplos:

MOV R1, R0

Copia o valor de R1 para R0.

MOV #5, R0

Coloca o valor 5 diretamente em R0.

ADD R2, R1

Faz R1 = R1 + R2.

ADD #1, R3

Faz R3 = R3 + 1.

8. ISA - Conjunto de instrucoes

A ISA e o conjunto de instrucoes que o processador entende.

A instrucao tem 8 bits no formato:

OP C SS DD

Tabela principal:

OP	Formato	Instrucao	Descricao
000	000 c ss dd	ADD Rs/#i, Rd	Soma fonte com destino
001	001 c ss dd	AND Rs/#i, Rd	AND bit a bit
010	010 c ss dd	XOR Rs/#i, Rd	XOR bit a bit
011	011 c ss dd	OR Rs/#i, Rd	OR bit a bit
100	100 c ss dd	LD @Rs/@i, Rd	Carrega dado da memoria para registrador
101	101 c ss dd	ST Rs/#i, @Rd	Escreve dado na memoria
110	110 c ss dd	MOV Rs/#i, Rd	Copia/move valor para destino
111	111 0 xx 00	JC addr	Salta se carry = 1
111	111 1 xx 01	JZ addr	Salta se zero = 1
111	111 1 xx 10	JNZ addr	Salta se zero = 0
111	111 1 xx 11	JMP addr	Salto incondicional

Observacao:

Rs significa registrador fonte.
Rd significa registrador destino.
#i significa constante imediata.
@Rs significa acessar memoria usando o valor de Rs como endereco.
@i significa acessar memoria usando uma constante como endereco.
addr significa endereco de salto.
xx significa bits irrelevantes/dont care naquele caso.
9. Instrucoes aritmeticas e logicas

As principais instrucoes da ULA sao:

ADD
AND
XOR
OR

Elas usam a forma:

OP Rs/#i, Rd

Ou seja, a fonte pode ser um registrador ou uma constante.

9.1 ADD
ADD R0, R1

Significa:

R1 = R1 + R0

Exemplo:

antes:
R0 = 1
R1 = 2

depois:
R1 = 3

Com imediato:

ADD #5, R1

Significa:

R1 = R1 + 5
9.2 AND
AND R0, R1

Significa:

R1 = R1 & R0

E uma operacao bit a bit.

9.3 XOR
XOR R0, R1

Significa:

R1 = R1 ^ R0

E uma operacao bit a bit.

9.4 OR
OR R0, R1

Significa:

R1 = R1 | R0

E uma operacao bit a bit.

10. Instrucao MOV

A instrucao MOV copia um valor de uma fonte para um destino.

Formato:

MOV fonte, destino

Exemplo com registrador:

MOV R1, R0

Significa:

R0 = R1

Exemplo com imediato:

MOV #1, R0

Significa:

R0 = 1

MOV nao precisa usar a ULA para calcular. Ela apenas transfere/copia o valor.

11. Instrucoes de memoria: LD e ST
11.1 LD

LD significa load, ou carregar dado da memoria para um registrador.

Formato:

LD @Rs/@i, Rd

Exemplo conceitual:

LD @R0, R1

Significa:

Use o valor de R0 como endereco.
Leia a memoria nesse endereco.
Guarde o dado lido em R1.

Com imediato:

LD @i, R1

Significa:

Use a constante i como endereco.
Leia a memoria nesse endereco.
Guarde o dado lido em R1.
11.2 ST

ST significa store, ou armazenar dado na memoria.

Formato:

ST Rs/#i, @Rd

Exemplo conceitual:

ST R1, @R0

Significa:

Use o valor de R0 como endereco.
Escreva o valor de R1 na memoria nesse endereco.

Com imediato:

ST #5, @R0

Significa:

Use o valor de R0 como endereco.
Escreva o valor 5 na memoria nesse endereco.
12. Instrucoes de salto

As instrucoes de salto alteram o PC.

Elas mudam o fluxo do programa.

12.1 JMP
JMP addr

Salta sempre para o endereco addr.

Significado:

PC = addr
12.2 JC
JC addr

Salta se a flag Carry estiver ativa.

Significado:

se Carry = 1:
    PC = addr
senao:
    continua normalmente
12.3 JZ
JZ addr

Salta se a flag Zero estiver ativa.

Significado:

se Zero = 1:
    PC = addr
senao:
    continua normalmente
12.4 JNZ
JNZ addr

Salta se a flag Zero nao estiver ativa.

Significado:

se Zero = 0:
    PC = addr
senao:
    continua normalmente
13. Flags da ULA

A ULA gera pelo menos duas flags:

Carry
Zero
13.1 Zero

A flag Zero indica que o resultado da operacao foi zero.

Exemplo:

1 + (-1) = 0

Nesse caso:

Zero = 1

Essa flag e usada por instrucoes como:

JZ addr
JNZ addr
13.2 Carry

A flag Carry indica estouro em uma operacao de soma de 8 bits.

Como o processador e de 8 bits, o maior valor sem sinal e:

255 decimal
0xFF hexadecimal
11111111 binario

Se fizer:

255 + 1 = 256

O resultado nao cabe em 8 bits.

O resultado de 8 bits vira:

0

E o Carry fica:

Carry = 1

Essa flag e usada por:

JC addr
14. Barramento externo

A CPU acessa memoria e perifericos por barramento.

Sinais principais:

addr    = endereco que a CPU quer acessar
bus_in  = dado vindo de fora para a CPU
bus_out = dado saindo da CPU para fora
bus_wr  = sinal de escrita

Durante leitura:

CPU coloca endereco em addr.
Memoria responde com dado em bus_in.
CPU captura bus_in.

Durante escrita:

CPU coloca endereco em addr.
CPU coloca dado em bus_out.
CPU ativa bus_wr.
Memoria/periferico salva o dado.

No Logisim, o barramento de dados aparece separado como bus_in e bus_out, porque o simulador nao trabalha bem com pinos bidirecionais.

Na pratica, eles representam o caminho de dados entre CPU e memoria/perifericos.

15. Mapa de memoria

O documento define o seguinte mapa de memoria:

Regiao	Inicio	Fim
ROM	0x00	0x9F
RAM	0xA0	0xDF
Perifericos	0xE0	0xFF

Interpretacao:

0x00 ate 0x9F -> ROM
0xA0 ate 0xDF -> RAM
0xE0 ate 0xFF -> perifericos

A ROM guarda o programa.

A RAM pode guardar dados/pilha.

Os perifericos ficam mapeados no fim do espaco de enderecos.

Neste desafio, o foco e implementar a CPU. A ROM/RAM podem ser simuladas depois no testbench.

16. ULA

A ULA e um circuito combinacional.

Ela recebe duas entradas principais:

A
B

E recebe tambem um seletor de operacao.

Ela gera:

resultado
flag Carry
flag Zero

Operacoes esperadas:

ADD
AND
XOR
OR

Exemplo com ADD:

A = R1
B = R0
operacao = ADD
resultado = R1 + R0

A ULA nao decide sozinha onde salvar o resultado. Ela apenas calcula.

Quem decide salvar ou nao e o controlador/FSM.

17. Banco de registradores - REGS

O banco de registradores contem:

R0
R1
R2
R3

Ele precisa permitir:

ler registrador fonte
ler registrador destino
escrever em um registrador

No datapath, o banco de registradores possui duas saidas de leitura.

Essas saidas podem ser usadas para alimentar a ULA ou outros caminhos de dados.

Tambem existe uma entrada de escrita, que pode vir de:

resultado da ULA
barramento
valor da fonte
constante/imediato

A escrita e controlada por um sinal wr.

Quando wr = 1, o valor de entrada e gravado no registrador selecionado.

18. Controlador/FSM

O controlador e uma maquina de estados.

Ele controla o datapath da CPU.

Ele decide sinais como:

quando buscar instrucao
quando salvar no IR
quando incrementar PC
quando buscar constante
quando escrever no banco de registradores
quando ativar escrita no barramento
qual entrada selecionar nos muxes
qual operacao a ULA deve fazer

O fluxo geral da FSM e:

FETCH -> DECODE -> FETCH_CTE -> EXEC -> WRITE -> FETCH

Mas FETCH_CTE so acontece quando a instrucao usa constante/imediato.

19. Estados da FSM
19.1 FETCH

Busca a instrucao na memoria.

Operacao conceitual:

addr = PC
IR = bus_in
PC = PC + 1

A CPU coloca o valor do PC no barramento de endereco.

A memoria responde com a instrucao.

A CPU guarda a instrucao no IR.

Depois o PC e incrementado.

19.2 DECODE

Decodifica a instrucao guardada no IR.

A CPU identifica:

OP
C
SS
DD

Ela descobre:

qual instrucao e
se usa constante
qual e a fonte
qual e o destino

Se C = 1, a CPU vai para FETCH_CTE.

Se C = 0, a CPU pode ir direto para EXEC.

19.3 FETCH_CTE

Busca a constante/imediato no proximo byte da ROM.

Operacao conceitual:

addr = PC
CTE = bus_in
PC = PC + 1

Esse estado e necessario para instrucoes como:

MOV #1, R0
ADD #5, R2
ST #9, @R1
19.4 EXEC

Executa a instrucao.

Exemplos:

Para ADD:

ULA calcula Rd + fonte

Para AND:

ULA calcula Rd & fonte

Para MOV:

seleciona a fonte para gravar no destino

Para JMP:

PC recebe endereco de salto

Para LD:

prepara leitura da memoria

Para ST:

prepara escrita na memoria
19.5 WRITE

Grava o resultado final, se a instrucao precisar.

Exemplos:

MOV #1, R0

No WRITE:

R0 = 1
ADD R0, R1

No WRITE:

R1 = resultado da ULA

Algumas instrucoes podem nao precisar escrever em registrador, como:

ST R0, @R1
JMP addr
20. Fluxo completo de MOV #1, R0

Instrucao:

MOV #1, R0

Significado:

coloque o valor 1 em R0

Como usa imediato, ocupa dois bytes na ROM.

Memoria:

ROM[0] = instrucao MOV #i, R0
ROM[1] = valor 1

Fluxo:

FETCH
- PC = 0
- CPU coloca addr = PC
- memoria entrega ROM[0]
- CPU salva ROM[0] no IR
- PC vira 1

DECODE
- CPU olha o IR
- identifica MOV
- identifica C = 1
- identifica destino R0
- como C = 1, precisa buscar constante

FETCH_CTE
- PC = 1
- CPU coloca addr = PC
- memoria entrega ROM[1]
- CPU salva ROM[1] no CTE
- PC vira 2

EXEC
- CPU seleciona CTE como valor de fonte
- valor selecionado = 1

WRITE
- CPU escreve 1 em R0

Resultado:

R0 = 1
PC = 2
21. Fluxo completo de MOV #2, R1

Instrucao:

MOV #2, R1

Significado:

coloque o valor 2 em R1

Memoria:

ROM[2] = instrucao MOV #i, R1
ROM[3] = valor 2

Fluxo:

FETCH
- PC = 2
- CPU busca ROM[2]
- salva em IR
- PC vira 3

DECODE
- identifica MOV
- identifica C = 1
- identifica destino R1

FETCH_CTE
- PC = 3
- CPU busca ROM[3]
- salva valor 2 em CTE
- PC vira 4

EXEC
- seleciona CTE como fonte

WRITE
- escreve 2 em R1

Resultado:

R0 = 1
R1 = 2
PC = 4
22. Fluxo completo de ADD R0, R1

Instrucao:

ADD R0, R1

Significado:

R1 = R1 + R0

Supondo:

R0 = 1
R1 = 2

Memoria:

ROM[4] = instrucao ADD R0, R1

Como nao usa imediato, ocupa apenas um byte.

Fluxo:

FETCH
- PC = 4
- CPU busca ROM[4]
- salva em IR
- PC vira 5

DECODE
- identifica ADD
- identifica C = 0
- identifica fonte R0
- identifica destino R1
- como C = 0, nao precisa FETCH_CTE

EXEC
- ULA recebe R1 e R0
- ULA calcula 2 + 1
- resultado = 3
- Zero = 0
- Carry = 0

WRITE
- CPU grava resultado em R1

Resultado:

R0 = 1
R1 = 3
PC = 5
23. Exemplo de programa: Fibonacci

Exemplo do documento:

start:
    MOV #1, R0
    MOV #2, R1

fibo:
    MOV R1, R2
    ADD R0, R1
    MOV R2, R0
    JMP fibo

Ideia:

R0 e R1 guardam dois termos consecutivos.
R2 e usado como backup temporario.
A cada iteracao:
- copia R1 para R2
- soma R0 em R1
- copia R2 para R0
- volta para fibo

Exemplo inicial:

R0 = 1
R1 = 2

Depois de uma iteracao:

R2 = R1 antigo = 2
R1 = R1 + R0 = 2 + 1 = 3
R0 = R2 = 2

Resultado:

R0 = 2
R1 = 3

Na proxima:

R0 = 3
R1 = 5

E assim por diante.

24. Exemplo de programa: multiplicacao por soma

Exemplo do documento:

mult:
    MOV #0, R0
    MOV #0, R1

mult_loop:
    ADD R2, R0
    JC mult_c
    JMP mult_dec

mult_c:
    ADD #1, R1

mult_dec:
    ADD #-1, R3
    JNZ mult_loop

Ideia geral:

R0 guarda parte baixa do acumulador
R1 guarda parte alta do acumulador
R2 e o valor somado repetidamente
R3 funciona como contador
se a soma gerar carry, incrementa R1
decrementa R3 ate chegar a zero

Esse programa simula uma multiplicacao usando varias somas.

25. Como pensar no processador

A CPU nao executa uma instrucao inteira de uma vez.

Ela segue um fluxo:

1. buscar instrucao
2. guardar no IR
3. decodificar campos
4. se precisar, buscar constante
5. executar a operacao
6. gravar resultado
7. voltar para buscar a proxima instrucao

Esse e o ciclo fundamental.

26. Ordem recomendada de implementacao

A recomendacao do documento e comecar pela ULA ou pelo banco de registradores, e deixar a maquina de estados por ultimo.

Ordem sugerida:

1. Entender a ISA
2. Fazer tabela dos opcodes
3. Implementar ufe8_pkg.sv
4. Implementar alu.sv
5. Fazer tb_alu.sv
6. Simular ULA
7. Implementar regs.sv
8. Fazer tb_regs.sv
9. Simular banco de registradores
10. Planejar sinais de controle da FSM
11. Implementar controller.sv
12. Implementar cpu.sv
13. Fazer tb_cpu.sv
14. Simular um programa simples
15. Abrir waveform no Verdi
27. Estrutura sugerida de projeto
ufe8/
├── rtl/
│   ├── ufe8_pkg.sv
│   ├── alu.sv
│   ├── regs.sv
│   ├── controller.sv
│   └── cpu.sv
├── tb/
│   ├── tb_alu.sv
│   ├── tb_regs.sv
│   └── tb_cpu.sv
├── sim/
├── docs/
│   ├── briefing_ufe8.md
│   └── architecture_notes.md
├── scripts/
└── Makefile
28. Papel de cada arquivo RTL
28.1 ufe8_pkg.sv

Arquivo de definicoes comuns.

Deve conter:

typedefs
enum de opcodes
enum de estados da FSM
constantes uteis

Exemplo de conteudo conceitual:

OP_ADD
OP_AND
OP_XOR
OP_OR
OP_LD
OP_ST
OP_MOV
OP_BRANCH

ST_FETCH
ST_DECODE
ST_FETCH_CTE
ST_EXEC
ST_WRITE
28.2 alu.sv

Implementa a ULA.

Entradas conceituais:

a
b
op
carry_in

Saidas conceituais:

result
zero
carry

Operacoes:

ADD
AND
XOR
OR
28.3 regs.sv

Implementa o banco de registradores.

Contem:

R0
R1
R2
R3

Funcionalidades:

duas leituras
uma escrita
reset
write enable
28.4 controller.sv

Implementa a FSM.

Estados:

FETCH
DECODE
FETCH_CTE
EXEC
WRITE

Responsavel por gerar sinais de controle do datapath.

28.5 cpu.sv

Modulo top da CPU.

Integra:

PC
IR
CTE
REGS
ULA
controller
muxes
barramento

Interface externa conceitual:

clk
rst
bus_in
bus_out
addr
bus_wr
29. Testbenches esperados
29.1 tb_alu.sv

Testa:

ADD
AND
XOR
OR
Zero flag
Carry flag
29.2 tb_regs.sv

Testa:

reset
escrita em R0
escrita em R1
escrita em R2
escrita em R3
leitura dos registradores
29.3 tb_cpu.sv

Testa a CPU completa com uma ROM simulada dentro do testbench.

Programa simples recomendado:

MOV #1, R0
MOV #2, R1
ADD R0, R1

Resultado esperado:

R0 = 1
R1 = 3
30. Fluxo com VCS e Verdi

Antes de simular:

source /opt/synopsys/env/synopsys.sh

Compilacao conceitual com VCS:

vcs -full64 -sverilog -debug_access+all -kdb arquivos.sv -l sim/compile.log

Executar simulacao:

./simv

Abrir waveform no Verdi:

verdi -sv arquivos.sv -ssf wave.fsdb &

Os testbenches podem usar:

$fsdbDumpfile("wave.fsdb");
$fsdbDumpvars(0, tb_nome);
31. Primeiro programa para estudar o fluxo

Programa:

MOV #1, R0
MOV #2, R1
ADD R0, R1

Memoria conceitual:

ROM[0] = MOV #i, R0
ROM[1] = 1
ROM[2] = MOV #i, R1
ROM[3] = 2
ROM[4] = ADD R0, R1

Resultado esperado:

R0 = 1
R1 = 3

Esse programa e ideal para comecar porque testa:

MOV com imediato
busca de constante em FETCH_CTE
ADD com registrador
ULA
escrita no banco de registradores
incremento do PC
32. Resumo mental do fluxo

Pensar assim:

A ROM guarda o programa.

O PC aponta para o proximo byte da ROM.

A CPU busca o byte apontado pelo PC.

Se esse byte for instrucao, ele vai para IR.

A CPU decodifica IR.

Se a instrucao tiver constante, a CPU busca o proximo byte e guarda em CTE.

A ULA calcula quando necessario.

O banco de registradores guarda R0, R1, R2 e R3.

A FSM controla tudo em passos.

No fim, a CPU volta para FETCH e repete o ciclo.
33. O que deve ficar claro antes de codar

Antes de implementar em SystemVerilog, e importante entender:

1. O que o PC faz
2. O que o IR guarda
3. O que o CTE guarda
4. O que significa OP C SS DD
5. Quando C = 0
6. Quando C = 1
7. Por que MOV #1, R0 usa dois bytes
8. Por que ADD R0, R1 usa um byte
9. O que a ULA calcula
10. O que o banco de registradores armazena
11. Por que a FSM precisa de FETCH, DECODE, FETCH_CTE, EXEC e WRITE
34. Proximo passo recomendado

O primeiro passo pratico nao e codar a CPU inteira.

O primeiro passo recomendado e fazer um trace manual do programa:

MOV #1, R0
MOV #2, R1
ADD R0, R1

Tabela sugerida:

Estado	PC	IR	CTE	R0	R1	Explicacao
FETCH	0	-	-	0	0	Busca instrucao em ROM[0]
DECODE	1	MOV #i,R0	-	0	0	Decodifica MOV com imediato
FETCH_CTE	1	MOV #i,R0	-	0	0	Busca constante em ROM[1]
EXEC	2	MOV #i,R0	1	0	0	Seleciona CTE como fonte
WRITE	2	MOV #i,R0	1	1	0	Escreve 1 em R0

Depois repetir para:

MOV #2, R1
ADD R0, R1

Quando esse fluxo estiver claro, a implementacao da ULA e do banco de registradores fica muito mais facil.

---

## 35. Codificacao binaria das instrucoes

Os bits do campo OP nao devem ser escolhidos livremente.

Eles ja sao definidos pela ISA do desafio.

Tabela de OP:

| OP  | Instrucao |
|-----|-----------|
| 000 | ADD |
| 001 | AND |
| 010 | XOR |
| 011 | OR |
| 100 | LD |
| 101 | ST |
| 110 | MOV |
| 111 | Saltos/branches |

Portanto:

```asm
MOV #1, R0
