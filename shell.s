.eqv PROMPT 0x3E
.eqv TERM_COLOR	0x000000FF

.data
buffer:			.space 40 
prompt_pos:	.byte 0, 0
token:			.space 40
echo_cmd:		.string "echo "
ls_cmd:			.string "ls "


.include "MACROSv24.s"

.text

shell.read:
li a0, PROMPT
li a1, 0
li a2, 0
li a3, TERM_COLOR
li a4, 0
li a7, 111
ecall


la a0, buffer
li a1, 39
li a2, 8
li a3, 0
li a4, TERM_COLOR
li a7, 81
ecall

la a0, buffer
la a1, echo_cmd
jal startsWith
bnez a0, is_echo

la a0, buffer
la a1, ls_cmd
jal startsWith
bnez a0, is_ls



is_echo:
la a0, echo_cmd
j end_cmd

is_ls:
la a0, ls_cmd

end_cmd:
li a7, 4
ecall
li a7, 10
ecall

# startsWith
# a0 = string
# a1 = prefixo
##############
# retorna
# a0 = a0 comeca com a1
startsWith: lbu t1, 0(a1)
		beqz t1, startsWith.true
		lbu t0, 0(a0)
		bne t0, t1, startsWith.false
		addi a0, a0, 1
		addi a1, a1, 1
		j startsWith

startsWith.true: li a0, 1
		j fimstartsWith

startsWith.false: li a0, 0

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
# mudar
li a7, 31
li a0, 100
li a1, 300
li a2, 0
li a3, 200
ecall
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




.include "SYSTEMv24.s"
