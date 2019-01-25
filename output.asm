.data
	xx:	.word	0
.text
	li $t2, 2
	li $t3, 1
	bgt $t2, $t3, label0
#labels
	label0:
	li $t0, 5
	sw $t0, xx

