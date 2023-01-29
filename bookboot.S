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
#define CFG_POS  256
#define CFG_PARS 260
#define CPY_PARS 264
#define REG_PARS 436
#define WELCOME  480

/*
 * possibly detect memory layout and add to taglist
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
	mov  	r0, #'p'
	bl 	printch
	mov  	r0, pc
	bl 	printhex8
	mov	r0, #'\n'
	bl 	printch
	adr 	r7, _start + CFG_POS
	ldmia	r7, {r4}
	tst	r4, #1
	beq	noauto

	/* memory autodetection */
	/* register usage: r4 taglist index 
	 * r8 memory index
	 * r5,r6,r7, r8: ATAG_MEM
	 * r0-r3: scratch + serial output */
	adr	r7, _start + CFG_PARS
	ldmia	r7, {r4}
3:
	mov	r0, #'t'	@ walk through taglist, use r4 as index
	bl	printch
	mov	r0, r4
	bl	printhex8
	mov	r0, #'\n'
	bl 	printch
	ldmia	r4, {r5, r6}	
	add	r4, r4, r5, lsl #2
	teq	r5, #0
	bne	3b 
	mov	r5, #0x4	@ set up ATAG_MEM
	mov	r6, #0x54000000
	add	r6, r6, #0x00410000
	add	r6, r6, #0x00000002
	mov	r7, #0x01000000 @ 16 MB block size
	mov	r8, #0xc0000000

2:	mov	r0, #'m'	@ test memory presence by verified writing
	bl	printch
	mov	r0, r8
	bl	printhex8
	ldmia	r8, {r0, r1}
	stmia	r8, {r5, r6}
	ldmia	r8, {r2, r3}
	teq	r2, r5
	teqeq	r3, r6
	movne	r0, #'n'
	bne	1f
	stmia	r8, {r0, r1}  	@ restore
	stmia	r4!,{r5-r8}	@ add to taglist
	mov	r0, #'y'
1:	bl	printch
	mov	r0, #'\n'
	bl	printch
	teq	r8, #0xd8000000
	addne	r8, r8, #0x08000000
	bne	2b
	mov	r0, #0
	mov	r1, r0
	stmia	r4!, {r0,r1}
	
noauto:
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
	

#include "serial.S" 

end:
	.end
	
