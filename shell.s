.eqv PROMPT 0x3E
.eqv TERM_COLOR	0x000000FF

.data
buffer:			.space 40 	# buffer para comando do usuario
curr_line:	.byte 0			# linha atual na tela
no_cmd_error:	.string "Erro: comando nao existe"

### Comandos ###
echo_str:		.string "echo"
ls_str:			.string "ls"
clear_str:	.string "clear"
exit_str:		.string "exit"


.include "MACROSv24.s"

.text

shell.read: li a0, PROMPT
li a1, 0
la t0, curr_line
lbu a2, 0(t0)
slli a2, a2, 4
li a3, TERM_COLOR
li a4, 0
li a7, 111
ecall


la a0, buffer
li a1, 39
li a2, 8
la t0, curr_line
lbu a3, 0(t0)
slli a3, a3, 4
li a4, TERM_COLOR
li a7, 81
ecall


la a0, buffer
la a1, echo_str
jal startsWith
bnez a0, shell.echo_cmd

#la a0, buffer
#la a1, ls_str
#jal startsWith
#bnez a0, shell.ls_cmd

la a0, buffer
la a1, clear_str
jal startsWith
bnez a0, shell.clear_cmd

la a0, buffer
la a1, exit_str
jal startsWith
bnez a0, shell.exit_cmd

# comando nao implementado
la a0, no_cmd_error
jal shell.printLine
j shell.reset_buffer

shell.clear_cmd: la t0, curr_line
		sb zero, 0(t0)
		li a0, 0
		li a1, 0
		li a7, 148
		ecall
		j shell.reset_buffer

shell.echo_cmd: la t0, buffer
		addi a0, t0, 5		# como eh echo, pula "echo "
		jal shell.printLine
		j shell.reset_buffer


shell.ls_cmd:
# TODO

shell.exit_cmd: li a7, 10
ecall

shell.reset_buffer:
		la t0, buffer
		li t1, 10
reset_buffer.loop: sw zero, 0(t0)
		addi t0, t0, 4
		addi t1, t1, -1
		bnez t1, reset_buffer.loop
		j shell.read

shell.scroll:
		li t4, VGAADDRESSINI0
		li t5, 320
		slli t5, t5, 5	# 32 linhas de pixels -> duas linhas no terminal
		add t5, t5, t4	# t5 = frame 0 + offset 
		li t6, VGAADDRESSFIM0
scroll.loop: bge t5, t6, scroll.cleanup
		lw t3, 0(t5)
		sw t3, 0(t4)
		addi t4, t4, 4
		addi t5, t5, 4
		j scroll.loop
scroll.cleanup: bge t4, t6, scroll.end
		sw zero, 0(t4)
		addi t4, t4, 4
		j scroll.cleanup
scroll.end: la t4, curr_line
		li t2, 12
		sb t2, 0(t4)
		ret

# printLine
# a0 = string
shell.printLine:
		addi sp, sp, -4
		sw ra, 0(sp)
		li a1, 0
		la t1, curr_line
		lbu t2, 0(t1)
		li t3, 14			# ultima linha da tela
		bne t2, t3, printline.end
		jal shell.scroll
printline.end: addi a2, t2, 1	# incrementa linha
		addi t2, t2, 2	# proxima linha 
		sb t2, 0(t1)
		slli a2, a2, 4	# offset da linha
		li a3, TERM_COLOR
		li a4, 0
		li a7, 104
		ecall
		lw ra, 0(sp)
		addi sp, sp, 4
		ret

# startsWith
# a0 = string
# a1 = prefixo
##############
# retorna
# a0 = a0 comeca com a1
startsWith: lbu t1, 0(a1)	# char do prefixo
		lbu t0, 0(a0)					# char da string
		beqz t1, startsWith.preEnd	# se prefixo acabou
		bne t0, t1, startsWith.false	# se char eh diferente do prefixo
		addi a0, a0, 1	# incrementa ponteiro da string
		addi a1, a1, 1	# incrementa ponteiro do prefixo
		j startsWith

startsWith.preEnd: li t1, 0x20	
		beq t0, t1, startsWith.true	# checa se proximo char eh espaco
		beqz t0, startsWith.true		# checa se proximo char eh nulo

startsWith.false: li a0, 0
		j fimstartsWith

startsWith.true: li a0, 1

fimstartsWith: ret


#######################################
# Read String Interativo							#
# a0 = end inicio											#
# a1 = tam max string									#
# a2 = x															#
# a3 = y															#
# a4 = cores													#
####################
# Retornos
# a5 = num de caracteres digitados		#
# a6 = end do ultimo char							#
#######################################
iReadString: addi sp, sp, -24 # aloca espaco
# nao precisa salvar tudo
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
		jal printCursor	# imprime cursor na primeira posicao

# le char e faz o tratamento necessario
loopTreatChar: jal readChar
		li t0, 0x8		# checa se o char eh backspace
		beq a0, t0, iReadString.backspace

		li t0, 0xA		# checa se o char eh newline (enter)
		beq a0, t0, iReadString.linefeed

# char printavel
# adiciona char no buffer e incrementa posicao
		beq a5, s1, loopTreatChar	# caso tenha o maximo de caracteres, ignora
		add t0, s0, a5	# posicao no buffer
		sb a0, 0(t0)		# escreve char no buffer

# imprime char
		slli t1, a5, 3	# calcula offset do x do char
		add a1, t1, s2	# calcula x do char
		mv a2, s3				# mesmo y
		mv a3, s4				# mesma cor
		li a4, 0				# frame 0
		jal printChar		# imprime char

		addi a5, a5, 1	# incrementa contador de caracteres

		mv a0, s4
		jal printCursor	# imprime cursor na proxima posicao

		j loopTreatChar	# loop para ler o proximo char

iReadString.backspace: beqz a5, loopTreatChar # se nao tem char, pula
		add t0, s0, a5 # posicao no buffer
		sb zero, 0(t0) # escreve \0 no buffer

# apaga o cursor
		mv a0, zero			# cor = 0 (tudo preto)
		jal printCursor	# imprime cursor com tudo preto (apaga cursor antigo)
		addi a5, a5, -1	# decrementa contador de caracteres
		mv a0, s4				# cor
		jal printCursor	# imprime novo cursor

		j loopTreatChar	# loop para ler o proximo char

iReadString.linefeed:
# apaga o cursor
		mv a0, zero			# cor = 0 (tudo preto)
		jal printCursor	# imprime cursor com tudo preto (apaga cursor antigo)
j fimiReadString


# comentar
fimiReadString: add a6, s0, a5	# a6 = endereco do ultimo char
		sb zero, 0(a6)	# escreve \0 no buffer (fim da string)
		addi a6, a6, -1	# char antes do fim da string

		lw ra, 0(sp)
		lw s0, 4(sp)
		lw s1, 8(sp)
		lw s2, 12(sp)
		lw s3, 16(sp)
		lw s4, 20(sp)
		addi sp, sp, 24
		ret

# imprime o cursor depois do ultimo char
# nao imprime se tiver o maximo de caracteres
# a0 = cor
printCursor:
		beq a5, s1, fimprintCursor	# ignora caso ja tenha escrito maximo de caracteres
		addi sp, sp, -4 # aloca espaco
		sw ra, 0(sp)		# salva ra
		mv a3, a0				# cor
		li a0, 0x5F			# ascii do underscore (_)
		slli a1, a5, 3	# calcula offset do x do cursor
		add a1, a1, s2	# calcula x do cursor
		mv a2, s3				# mesmo y
		li a4, 0				# frame 0
		jal printChar		# imprime cursor
		lw ra, 0(sp)		# recupera ra
		addi sp, sp, 4
		fimprintCursor:
		ret


.include "SYSTEMv24.s"
