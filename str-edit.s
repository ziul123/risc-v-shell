.eqv PROMPT 0x3E
.eqv BS			0x08
.eqv LF			0x0A
.eqv CURSOR	0x5F
.eqv TERM_COLOR	0x000000FF
.eqv TRAN_BG		0x0000C7FF
.eqv BUF_MAX		39
.eqv LINE_MAX		40 # quantidade de caracteres em uma linha

.data
buffer:			.space BUF_MAX 
buf_pos:		.byte 0
prompt_pos:	.byte 0, 0
cursor_pos:	.half 8, 0
overflow_msg: .string "buffer overflow: line at max characters\n"
lf_det: .string "linefeed detected!\n"


.include "MACROSv21.s"


.macro print_str_at_prompt(%str,%prompt_pos,%color)
	la a0, %str
	la t0, %prompt_pos
	lbu a1, 0(t0)
	addi a1, a1, 8 # move para depois do prompt
	lbu a2, 1(t0)
	li a3, %color
	li a4, 0
	jal printString
.end_macro


.text

li a0, TERM_COLOR
jal print_prompt
li a0, TERM_COLOR
jal print_cursor


l0:
jal char_treatment
print_str_at_prompt(buffer, prompt_pos, TERM_COLOR)
li a0, TERM_COLOR
jal print_cursor

j l0

# le char e faz o tratamento necessario
char_treatment:
addi sp, sp, -4
sw ra, 0(sp)

jal readChar

li t0, BS
beq a0, t0, char_bs

li t0, LF
beq a0, t0, char_lf

# char printavel
# adiciona char no buffer e incrementa posicao
la t0, buffer
la t1, buf_pos
lbu t2, 0(t1)
li t3, BUF_MAX
beq t2, t3, char_treat.buf_over
add t0, t0, t2
sb a0, 0(t0)
addi t2, t2, 1
sb t2, 0(t1)

la t0, cursor_pos
lhu t1, 0(t0)
addi t1, t1, 8
sh t1, 0(t0)
j char_treat.end

char_bs:
la t0, buffer
la t1, buf_pos
lbu t2, 0(t1)
beqz t2, char_treat.end
add t0, t0, t2
sb zero, 0(t0)
addi t2, t2, -1
sb t2, 0(t1)

# apaga o cursor
mv a0, zero
jal print_cursor

la t0, cursor_pos
lhu t1, 0(t0)
addi t1, t1, -8
sh t1, 0(t0)
j char_treat.end

char_lf:
li a7, 31
li a0, 100
li a1, 300
li a2, 1
li a3, 200
ecall
j char_treat.end

char_treat.buf_over:
li a7, 4
la a0, overflow_msg
ecall
char_treat.end:
lw ra, 0(sp)
addi sp, sp, 4
ret

# escreve o prompt na tela
# a0 = cor
print_prompt:
addi sp, sp, -4
sw ra, 0(sp)
mv a3, a0
li a0, PROMPT
la t0, prompt_pos
lbu a1, 0(t0)
lbu a2, 1(t0)
li a4, 0
jal printChar
lw ra, 0(sp)
addi sp, sp, 4
ret

# escreve o cursor na tela
# a0 = cor
print_cursor:
addi sp, sp, -4
sw ra, 0(sp)
mv a3, a0
li a0, CURSOR
la t0, cursor_pos
lhu a1, 0(t0)
lhu a2, 2(t0)
li a4, 0
jal printChar
lw ra, 0(sp)
addi sp, sp, 4
ret

.include "SYSTEMv21.s"
