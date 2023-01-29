/* 
 * serial.S
 * 
 * modified (mainly simplified) version of:
 *   linux/arch/arm/kernel/debug-armv.S  (from linux-2.4.21-rmk2)
 *   which is Copyright (C) 1994-1999 Russell King
 * 
 * modifications Copyright (C) 2004 Klaasjan van Druten
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 */

#define UTCR3           0x0c
#define UTCR3_RXE       0x00000001      /* Receive Enable                  */
#define UTCR3_TXE       0x00000002      /* Transmit Enable                 */

#define UTSR1           0x20
#define UTSR1_TNF       0x00000004      /* Transmit FIFO Not Full (read)   */
#define UTSR1_TBY       0x00000001      /* Transmitter BusY (read)         */

#define UTDR            0x14

/* Find address of first active UART (serial I/O)
 * note: we assume the MMU is off (otherwise we would need to know where
 * the bootloader maps the serial port).
 * clobbers r1
 */
		.macro	addruart,rx
		mov	\rx, #0x80000000	@ physical base address
		add	\rx, \rx, #0x00050000

		@ see if Ser3 is active
		ldr	r1, [\rx, #UTCR3]
		tst	r1, #UTCR3_TXE

		@ if Ser3 is inactive, then try Ser1
		addeq	\rx, \rx, #(0x00010000 - 0x00050000)
		ldreq	r1, [\rx, #UTCR3]
		tsteq	r1, #UTCR3_TXE

		@ if Ser1 is inactive, then try Ser2
		addeq	\rx, \rx, #(0x00030000 - 0x00010000)
		ldreq	r1, [\rx, #UTCR3]
		tsteq	r1, #UTCR3_TXE

		@ if all ports are inactive, then there is nothing we can do
		moveq	pc, lr
		.endm

		.macro	senduart,rd,rx
		str	\rd, [\rx, #UTDR]
		.endm

		.macro	waituart,rd,rx
1001:		ldr	\rd, [\rx, #UTSR1]
		tst	\rd, #UTSR1_TNF
		beq	1001b
		.endm

		.macro	busyuart,rd,rx
1001:		ldr	\rd, [\rx, #UTSR1]
		tst	\rd, #UTSR1_TBY
		bne	1001b
		.endm

/*
 * Useful debugging routines, argument in r0 [+r1], clobber r1-r3
 */
printhex8:
		mov	r1, #8
		b	printhex

printhex4:
		mov	r1, #4
		b	printhex

printhex2:
		mov	r1, #2
printhex:	adr	r2, hexbuf
		add	r3, r2, r1
		mov	r1, #0
		strb	r1, [r3]
1:		and	r1, r0, #15
		mov	r0, r0, lsr #4
		cmp	r1, #10
		addlt	r1, r1, #'0'
		addge	r1, r1, #'a' - 10
		strb	r1, [r3, #-1]!
		teq	r3, r2
		bne	1b
		mov	r0, r2
		b	printascii

printascii:
		addruart r3
		b	2f
1:		waituart r2, r3
		senduart r1, r3
		busyuart r2, r3
		teq	r1, #'\n'
		moveq	r1, #'\r'
		beq	1b
2:		teq	r0, #0
		ldrneb	r1, [r0], #1
		teqne	r1, #0
		bne	1b
		mov	pc, lr

printch:
		addruart r3
		mov	r1, r0
		mov	r0, #0
		b	1b

hexbuf:		.space 16

