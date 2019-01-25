.data
	a:	.word	0
	temp0:	.word	0
	temp1:	.word	0
	temp2:		0
	z:		0
.text
	li $t0, 1
	sw $t0, a
	li $t0, 5
	sw $t0, a
	li $t0, 2
	li $t1, 2
	mul $t0, $t0, $t1
	sw $t0, temp0
	li $t0, 3
	sw $t0, a
	lw $t2, a
	li $t3, 1
	bgt $t2, $t3, label0
	li $t0, 8
	sw $t0, a

	label0:
	li $t0, 2
	li $t1, 2
	add $t0, $t0, $t1
	sw $t0, temp1
	lw $t0, temp1
	sw $t0, z
	lw $t0, z
	li $t1, 3
	add $t0, $t0, $t1
	sw $t0, temp2
	lw $t0, temp2
	sw $t0, a

