/*
 * bookboot.S
 * part of the bookboot package
 * 
 *  Copyright (C) 2003-2004 Klaasjan van Druten
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 */

/* parameter locations with respect to _start:
 * these should be consistent with bookglue.pl
 */
#define CPY_PARS 256
#define REG_PARS 436
#define WELCOME  480

/*
 * copy memory blocks here and there, load registers, and jump somewhere
 * output to serial port
 *
 * register usage:
 * r0    : local/scratch
 * r1-r3 : clobbered by serial routines
 * r4-r6 : memcpy registers
 * r7    : index in parameters
 */
	.align
	.text
	.global _start
_start:	
 	b	realstart
	b	realstart
	.rept 126	@ fill header to 512 bytes
	.long   0x0
	.endr
realstart:
	adr	r0, _start + WELCOME
	bl	printascii
	adr 	r0, pc_str
	bl 	printascii
	mov  	r0, pc
	bl 	printhex8
	mov	r0, #'\n'
	bl 	printch
	adr 	r7, _start + CPY_PARS
2:	ldmia   r7!, {r4, r5, r6}  
	teq	r4, r5
	beq 	exit
	mov	r0,r4      /* print source -> destination */
	bl 	printhex8  
	mov 	r0, #'-'
	bl 	printch
	mov 	r0, #'>'
	bl 	printch
	mov	r0,r6
	bl 	printhex8
	mov 	r0, #'\n'
	bl 	printch

1:	ldr 	r0, [r4], #4	/* copy a word */
	str 	r0, [r6], #4
	subs	r0, r5, r4		/* at end? */
	bne 	1b
	mov	r0, r4		/* print final source location */
	bl 	printhex8
	mov 	r0, #'\n'
	bl 	printch
	b	2b

exit:
	adr 	r7, _start + REG_PARS
	ldmia 	r7, {r0-r6,r8}
	mov 	pc, r8
	
pc_str:	
	.asciz	"pc="

#include "serial.S" 

end:
	.end
	
