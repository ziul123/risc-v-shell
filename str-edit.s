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


.include "MACROSv24.s"


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

#li a0, TERM_COLOR
#jal print_prompt

# Read String Interativo
# a0 = end inicio
# a1 = tam max string
# a2 = x
# a3 = y
# a4 = cores
# a5 = num de caracteres digitados

la a0, buffer
li a1, 40
li a2, 0
li a3, 0
li a4, TERM_COLOR
call iReadString

iReadString: addi sp, sp, -24 # aloca espaco
sw ra, 0(sp)	# salva ra
sw s0, 4(sp)	# salva s0
sw s1, 8(sp)	# salva s1
sw s2, 12(sp)	# salva s2
sw s3, 16(sp)	# salva s3
sw s4, 20(sp)	# salva s4
mv s0, a0			# endereco inicial
mv s1, a1			# tamanho maximo
mv s2, a2			# x 
mv s3, a3			# y
mv s4, a4			# cor
li a5, 0			# zera contador de caracteres digitados

mv a0, s4
jal printCursor



# le char e faz o tratamento necessario
loopTreatChar:

jal readChar

li t0, BS
beq a0, t0, char_bs

li t0, LF
beq a0, t0, char_lf

# char printavel
# adiciona char no buffer e incrementa posicao
beq a5, s1, loopTreatChar	# caso tenha o maximo de caracteres, ignora
add t0, s0, a5	# posicao no buffer
sb a0, 0(t0)		# escreve caractere no buffer

# desenha char
slli t1, a5, 3	# calcula offset do x do caractere
add a1, t1, s2	# calcula x do caractere
mv a2, s3				# mesmo y
mv a3, s4				# mesma cor
li a4, 0				# frame 0
jal printChar		# imprime char

addi a5, a5, 1	# incrementa contador de caracteres

mv a0, s4
jal printCursor

j loopTreatChar

char_bs:
beqz a5, loopTreatChar # se nao tem caractere, pula
add t0, s0, a5 # posicao no buffer
sb zero, 0(t0) # escreve \0 no buffer

# apaga o cursor
mv a0, zero
jal printCursor
addi a5, a5, -1
mv a0, s4
jal printCursor

j loopTreatChar

char_lf:
li a7, 31
li a0, 100
li a1, 300
li a2, 1
li a3, 200
ecall
j fimiReadString


fimiReadString: add t0, s0, a5
sb zero, 0(t0)

lw ra, 0(sp)
lw s0, 4(sp)
lw s1, 8(sp)
lw s2, 12(sp)
lw s3, 16(sp)
lw s4, 20(sp)
addi sp, sp, -24
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
printCursor:
beq a5, s1, fimprintCursor	# ignora caso ja tenha escrito maximo de caracteres
addi sp, sp, -4 # aloca espaco
sw ra, 0(sp)		# salva ra
mv a3, a0				# cor
li a0, CURSOR		# caractere a ser impresso
slli a1, a5, 3	# calcula offset do x do cursor
add a1, a1, s2	# calcula x do cursor
mv a2, s3				# mesmo y
li a4, 0				# frame 0
jal printChar		# imprime cursor
lw ra, 0(sp)		# recupera ra
addi sp, sp, 4
fimprintCursor:
ret

#addi sp, sp, -4
#sw ra, 0(sp)
#mv a3, a0
#li a0, CURSOR
#la t0, cursor_pos
#lhu a1, 0(t0)
#lhu a2, 2(t0)
#li a4, 0
#jal printChar
#lw ra, 0(sp)
#addi sp, sp, 4
#ret

##################################
# Read String Interativo
# a0 = end inicio
# a1 = tam max string
# a2 = x
# a3 = y
# a4 = cores
##################################

.include "SYSTEMv24.s"
