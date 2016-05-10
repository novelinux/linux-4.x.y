
vmlinux_aries:     file format elf32-littlearm


Disassembly of section .text:

00000000 <start>:
#endif
		.endm

		.macro	debug_reloc_end
#ifdef DEBUG
		kphex	r5, 8		/* end of kernel */
       0:	e1a00000 	nop			; (mov r0, r0)
       4:	e1a00000 	nop			; (mov r0, r0)
       8:	e1a00000 	nop			; (mov r0, r0)
       c:	e1a00000 	nop			; (mov r0, r0)
      10:	e1a00000 	nop			; (mov r0, r0)
      14:	e1a00000 	nop			; (mov r0, r0)
      18:	e1a00000 	nop			; (mov r0, r0)
		kputc	#'\n'
      1c:	e1a00000 	nop			; (mov r0, r0)
		mov	r0, r4
      20:	ea000002 	b	30 <start+0x30>
      24:	016f2818 	.word	0x016f2818
      28:	00000000 	.word	0x00000000
      2c:	0068eea0 	.word	0x0068eea0
		.endm

		.section ".start", #alloc, #execinstr
/*
 * sort out different calling conventions
 */
      30:	e1a07001 	mov	r7, r1
		.align
      34:	e1a08002 	mov	r8, r2
		.type	start,#function
		.rept	7
		mov	r0, r0
		.endr
   ARM(		mov	r0, r0		)
   ARM(		b	1f		)
      38:	e10f2000 	mrs	r2, CPSR
 THUMB(		adr	r12, BSYM(1f)	)
      3c:	e3120003 	tst	r2, #3
 THUMB(		bx	r12		)
      40:	1a000001 	bne	4c <not_angel>

      44:	e3a00017 	mov	r0, #23
		.word	0x016f2818		@ Magic numbers to help the loader
      48:	ef123456 	svc	0x00123456

0000004c <not_angel>:
		.word	start			@ absolute load/run zImage address
		.word	_edata			@ zImage end address
 THUMB(		.thumb			)
      4c:	e10f2000 	mrs	r2, CPSR
1:		mov	r7, r1			@ save architecture ID
      50:	e38220c0 	orr	r2, r2, #192	; 0xc0
		mov	r8, r2			@ save atags pointer
      54:	e121f002 	msr	CPSR_c, r2
	...
		@ determine final kernel image address
		mov	r4, pc
		and	r4, r4, #0xf8000000
		add	r4, r4, #TEXT_OFFSET
#else
		ldr	r4, =zreladdr
      60:	e59f47a4 	ldr	r4, [pc, #1956]	; 80c <__armv3_mmu_cache_flush+0xc>
#endif

		bl	cache_on
      64:	eb000055 	bl	1c0 <cache_on>

00000068 <restart>:

restart:	adr	r0, LC0
      68:	e28f0f4a 	add	r0, pc, #296	; 0x128
		ldmia	r0, {r1, r2, r3, r6, r10, r11, r12}
      6c:	e8901c4e 	ldm	r0, {r1, r2, r3, r6, sl, fp, ip}
		ldr	sp, [r0, #28]
      70:	e590d01c 	ldr	sp, [r0, #28]

		/*
		 * We might be running at a different address.  We need
		 * to fix up various pointers.
		 */
		sub	r0, r0, r1		@ calculate the delta offset
      74:	e0400001 	sub	r0, r0, r1
		add	r6, r6, r0		@ _edata
      78:	e0866000 	add	r6, r6, r0
		add	r10, r10, r0		@ inflated kernel size location
      7c:	e08aa000 	add	sl, sl, r0
		/*
		 * The kernel build system appends the size of the
		 * decompressed kernel at the end of the compressed data
		 * in little-endian form.
		 */
		ldrb	r9, [r10, #0]
      80:	e5da9000 	ldrb	r9, [sl]
		ldrb	lr, [r10, #1]
      84:	e5dae001 	ldrb	lr, [sl, #1]
		orr	r9, r9, lr, lsl #8
      88:	e189940e 	orr	r9, r9, lr, lsl #8
		ldrb	lr, [r10, #2]
      8c:	e5dae002 	ldrb	lr, [sl, #2]
		ldrb	r10, [r10, #3]
      90:	e5daa003 	ldrb	sl, [sl, #3]
		orr	r9, r9, lr, lsl #16
      94:	e189980e 	orr	r9, r9, lr, lsl #16
		orr	r9, r9, r10, lsl #24
      98:	e1899c0a 	orr	r9, r9, sl, lsl #24

#ifndef CONFIG_ZBOOT_ROM
		/* malloc space is above the relocated stack (64k max) */
		add	sp, sp, r0
      9c:	e08dd000 	add	sp, sp, r0
		add	r10, sp, #0x10000
      a0:	e28da801 	add	sl, sp, #65536	; 0x10000
		 * in which case our reference is _edata.
		 */
		mov	r10, r6
#endif

		mov	r5, #0			@ init dtb size to 0
      a4:	e3a05000 	mov	r5, #0
 *   r10 = end of this image, including  bss/stack/malloc space if non XIP
 * We basically want:
 *   r4 - 16k page directory >= r10 -> OK
 *   r4 + image length <= address of wont_overwrite -> OK
 */
		add	r10, r10, #16384
      a8:	e28aa901 	add	sl, sl, #16384	; 0x4000
		cmp	r4, r10
      ac:	e154000a 	cmp	r4, sl
		bhs	wont_overwrite
      b0:	2a000016 	bcs	110 <wont_overwrite>
		add	r10, r4, r9
      b4:	e084a009 	add	sl, r4, r9
		adr	r9, wont_overwrite
      b8:	e28f9050 	add	r9, pc, #80	; 0x50
		cmp	r10, r9
      bc:	e15a0009 	cmp	sl, r9
		bls	wont_overwrite
      c0:	9a000012 	bls	110 <wont_overwrite>
		/*
		 * Bump to the next 256-byte boundary with the size of
		 * the relocation code added. This avoids overwriting
		 * ourself when the offset is small.
		 */
		add	r10, r10, #((reloc_code_end - restart + 256) & ~255)
      c4:	e28aab02 	add	sl, sl, #2048	; 0x800
		bic	r10, r10, #255
      c8:	e3caa0ff 	bic	sl, sl, #255	; 0xff

		/* Get start of code we want to copy and align it down. */
		adr	r5, restart
      cc:	e24f506c 	sub	r5, pc, #108	; 0x6c
		bic	r5, r5, #31
      d0:	e3c5501f 	bic	r5, r5, #31

		sub	r9, r6, r5		@ size to copy
      d4:	e0469005 	sub	r9, r6, r5
		add	r9, r9, #31		@ rounded up to a multiple
      d8:	e289901f 	add	r9, r9, #31
		bic	r9, r9, #31		@ ... of 32 bytes
      dc:	e3c9901f 	bic	r9, r9, #31
		add	r6, r9, r5
      e0:	e0896005 	add	r6, r9, r5
		add	r9, r9, r10
      e4:	e089900a 	add	r9, r9, sl

1:		ldmdb	r6!, {r0 - r3, r10 - r12, lr}
      e8:	e9365c0f 	ldmdb	r6!, {r0, r1, r2, r3, sl, fp, ip, lr}
		cmp	r6, r5
      ec:	e1560005 	cmp	r6, r5
		stmdb	r9!, {r0 - r3, r10 - r12, lr}
      f0:	e9295c0f 	stmdb	r9!, {r0, r1, r2, r3, sl, fp, ip, lr}
		bhi	1b
      f4:	8afffffb 	bhi	e8 <restart+0x80>

		/* Preserve offset to relocated code. */
		sub	r6, r9, r6
      f8:	e0496006 	sub	r6, r9, r6

#ifndef CONFIG_ZBOOT_ROM
		/* cache_clean_flush may use the stack, so relocate it */
		add	sp, sp, r6
      fc:	e08dd006 	add	sp, sp, r6
#endif

		bl	cache_clean_flush
     100:	eb000156 	bl	660 <cache_clean_flush>

		adr	r0, BSYM(restart)
     104:	e24f00a4 	sub	r0, pc, #164	; 0xa4
		add	r0, r0, r6
     108:	e0800006 	add	r0, r0, r6
		mov	pc, r0
     10c:	e1a0f000 	mov	pc, r0

00000110 <wont_overwrite>:
 *   r8  = atags pointer
 *   r11 = GOT start
 *   r12 = GOT end
 *   sp  = stack pointer
 */
		orrs	r1, r0, r5
     110:	e1901005 	orrs	r1, r0, r5
		beq	not_relocated
     114:	0a00000d 	beq	150 <not_relocated>

		add	r11, r11, r0
     118:	e08bb000 	add	fp, fp, r0
		add	r12, r12, r0
     11c:	e08cc000 	add	ip, ip, r0
		/*
		 * If we're running fully PIC === CONFIG_ZBOOT_ROM = n,
		 * we need to fix up pointers into the BSS region.
		 * Note that the stack pointer has already been fixed up.
		 */
		add	r2, r2, r0
     120:	e0822000 	add	r2, r2, r0
		add	r3, r3, r0
     124:	e0833000 	add	r3, r3, r0

		/*
		 * Relocate all entries in the GOT table.
		 * Bump bss entries to _edata + dtb size
		 */
1:		ldr	r1, [r11, #0]		@ relocate entries in the GOT
     128:	e59b1000 	ldr	r1, [fp]
		add	r1, r1, r0		@ This fixes up C references
     12c:	e0811000 	add	r1, r1, r0
		cmp	r1, r2			@ if entry >= bss_start &&
     130:	e1510002 	cmp	r1, r2
		cmphs	r3, r1			@       bss_end > entry
     134:	21530001 	cmpcs	r3, r1
		addhi	r1, r1, r5		@    entry += dtb size
     138:	80811005 	addhi	r1, r1, r5
		str	r1, [r11], #4		@ next entry
     13c:	e48b1004 	str	r1, [fp], #4
		cmp	r11, r12
     140:	e15b000c 	cmp	fp, ip
		blo	1b
     144:	3afffff7 	bcc	128 <wont_overwrite+0x18>

		/* bump our bss pointers too */
		add	r2, r2, r5
     148:	e0822005 	add	r2, r2, r5
		add	r3, r3, r5
     14c:	e0833005 	add	r3, r3, r5

00000150 <not_relocated>:
		str	r1, [r11], #4		@ C references.
		cmp	r11, r12
		blo	1b
#endif

not_relocated:	mov	r0, #0
     150:	e3a00000 	mov	r0, #0
1:		str	r0, [r2], #4		@ clear bss
     154:	e4820004 	str	r0, [r2], #4
		str	r0, [r2], #4
     158:	e4820004 	str	r0, [r2], #4
		str	r0, [r2], #4
     15c:	e4820004 	str	r0, [r2], #4
		str	r0, [r2], #4
     160:	e4820004 	str	r0, [r2], #4
		cmp	r2, r3
     164:	e1520003 	cmp	r2, r3
		blo	1b
     168:	3afffff9 	bcc	154 <not_relocated+0x4>
 * Set up some pointers, and start decompressing.
 *   r4  = kernel execution address
 *   r7  = architecture ID
 *   r8  = atags pointer
 */
		mov	r0, r4
     16c:	e1a00004 	mov	r0, r4
		mov	r1, sp			@ malloc space above stack
     170:	e1a0100d 	mov	r1, sp
		add	r2, sp, #0x10000	@ 64k max
     174:	e28d2801 	add	r2, sp, #65536	; 0x10000
		mov	r3, r7
     178:	e1a03007 	mov	r3, r7
		bl	decompress_kernel
     17c:	eb0001bc 	bl	874 <decompress_kernel>
		bl	cache_clean_flush
     180:	eb000136 	bl	660 <cache_clean_flush>
		bl	cache_off
     184:	eb000105 	bl	5a0 <cache_off>
		mov	r0, #0			@ must be zero
     188:	e3a00000 	mov	r0, #0
		mov	r1, r7			@ restore architecture number
     18c:	e1a01007 	mov	r1, r7
		mov	r2, r8			@ restore atags pointer
     190:	e1a02008 	mov	r2, r8
 ARM(		mov	pc, r4	)		@ call kernel
     194:	e1a0f004 	mov	pc, r4

00000198 <LC0>:
     198:	00000198 0068eea0 0068eeb8 0068eea0     ......h...h...h.
     1a8:	0068ee66 0068ee78 0068ee9c 0068feb8     f.h.x.h...h...h.
     1b8:	e320f000 e320f000                       .. ... .

000001c0 <cache_on>:
 *  r0, r1, r2, r3, r9, r10, r12 corrupted
 * This routine must preserve:
 *  r4, r7, r8
 */
		.align	5
cache_on:	mov	r3, #8			@ cache_on function
     1c0:	e3a03008 	mov	r3, #8
		b	call_cache_fn
     1c4:	ea000088 	b	3ec <call_cache_fn>

000001c8 <__armv4_mpu_cache_on>:
/*
 * Initialize the highest priority protection region, PR7
 * to cover all 32bit address and cacheable and bufferable.
 */
__armv4_mpu_cache_on:
		mov	r0, #0x3f		@ 4G, the whole
     1c8:	e3a0003f 	mov	r0, #63	; 0x3f
		mcr	p15, 0, r0, c6, c7, 0	@ PR7 Area Setting
     1cc:	ee060f17 	mcr	15, 0, r0, cr6, cr7, {0}
		mcr 	p15, 0, r0, c6, c7, 1
     1d0:	ee060f37 	mcr	15, 0, r0, cr6, cr7, {1}

		mov	r0, #0x80		@ PR7
     1d4:	e3a00080 	mov	r0, #128	; 0x80
		mcr	p15, 0, r0, c2, c0, 0	@ D-cache on
     1d8:	ee020f10 	mcr	15, 0, r0, cr2, cr0, {0}
		mcr	p15, 0, r0, c2, c0, 1	@ I-cache on
     1dc:	ee020f30 	mcr	15, 0, r0, cr2, cr0, {1}
		mcr	p15, 0, r0, c3, c0, 0	@ write-buffer on
     1e0:	ee030f10 	mcr	15, 0, r0, cr3, cr0, {0}

		mov	r0, #0xc000
     1e4:	e3a00903 	mov	r0, #49152	; 0xc000
		mcr	p15, 0, r0, c5, c0, 1	@ I-access permission
     1e8:	ee050f30 	mcr	15, 0, r0, cr5, cr0, {1}
		mcr	p15, 0, r0, c5, c0, 0	@ D-access permission
     1ec:	ee050f10 	mcr	15, 0, r0, cr5, cr0, {0}

		mov	r0, #0
     1f0:	e3a00000 	mov	r0, #0
		mcr	p15, 0, r0, c7, c10, 4	@ drain write buffer
     1f4:	ee070f9a 	mcr	15, 0, r0, cr7, cr10, {4}
		mcr	p15, 0, r0, c7, c5, 0	@ flush(inval) I-Cache
     1f8:	ee070f15 	mcr	15, 0, r0, cr7, cr5, {0}
		mcr	p15, 0, r0, c7, c6, 0	@ flush(inval) D-Cache
     1fc:	ee070f16 	mcr	15, 0, r0, cr7, cr6, {0}
		mrc	p15, 0, r0, c1, c0, 0	@ read control reg
     200:	ee110f10 	mrc	15, 0, r0, cr1, cr0, {0}
						@ ...I .... ..D. WC.M
		orr	r0, r0, #0x002d		@ .... .... ..1. 11.1
     204:	e380002d 	orr	r0, r0, #45	; 0x2d
		orr	r0, r0, #0x1000		@ ...1 .... .... ....
     208:	e3800a01 	orr	r0, r0, #4096	; 0x1000

		mcr	p15, 0, r0, c1, c0, 0	@ write control reg
     20c:	ee010f10 	mcr	15, 0, r0, cr1, cr0, {0}

		mov	r0, #0
     210:	e3a00000 	mov	r0, #0
		mcr	p15, 0, r0, c7, c5, 0	@ flush(inval) I-Cache
     214:	ee070f15 	mcr	15, 0, r0, cr7, cr5, {0}
		mcr	p15, 0, r0, c7, c6, 0	@ flush(inval) D-Cache
     218:	ee070f16 	mcr	15, 0, r0, cr7, cr6, {0}
		mov	pc, lr
     21c:	e1a0f00e 	mov	pc, lr

00000220 <__armv3_mpu_cache_on>:

__armv3_mpu_cache_on:
		mov	r0, #0x3f		@ 4G, the whole
     220:	e3a0003f 	mov	r0, #63	; 0x3f
		mcr	p15, 0, r0, c6, c7, 0	@ PR7 Area Setting
     224:	ee060f17 	mcr	15, 0, r0, cr6, cr7, {0}

		mov	r0, #0x80		@ PR7
     228:	e3a00080 	mov	r0, #128	; 0x80
		mcr	p15, 0, r0, c2, c0, 0	@ cache on
     22c:	ee020f10 	mcr	15, 0, r0, cr2, cr0, {0}
		mcr	p15, 0, r0, c3, c0, 0	@ write-buffer on
     230:	ee030f10 	mcr	15, 0, r0, cr3, cr0, {0}

		mov	r0, #0xc000
     234:	e3a00903 	mov	r0, #49152	; 0xc000
		mcr	p15, 0, r0, c5, c0, 0	@ access permission
     238:	ee050f10 	mcr	15, 0, r0, cr5, cr0, {0}

		mov	r0, #0
     23c:	e3a00000 	mov	r0, #0
		mcr	p15, 0, r0, c7, c0, 0	@ invalidate whole cache v3
     240:	ee070f10 	mcr	15, 0, r0, cr7, cr0, {0}
		/*
		 * ?? ARMv3 MMU does not allow reading the control register,
		 * does this really work on ARMv3 MPU?
		 */
		mrc	p15, 0, r0, c1, c0, 0	@ read control reg
     244:	ee110f10 	mrc	15, 0, r0, cr1, cr0, {0}
						@ .... .... .... WC.M
		orr	r0, r0, #0x000d		@ .... .... .... 11.1
     248:	e380000d 	orr	r0, r0, #13
		/* ?? this overwrites the value constructed above? */
		mov	r0, #0
     24c:	e3a00000 	mov	r0, #0
		mcr	p15, 0, r0, c1, c0, 0	@ write control reg
     250:	ee010f10 	mcr	15, 0, r0, cr1, cr0, {0}

		/* ?? invalidate for the second time? */
		mcr	p15, 0, r0, c7, c0, 0	@ invalidate whole cache v3
     254:	ee070f10 	mcr	15, 0, r0, cr7, cr0, {0}
		mov	pc, lr
     258:	e1a0f00e 	mov	pc, lr

0000025c <__setup_mmu>:
#define CB_BITS 0x08
#else
#define CB_BITS 0x0c
#endif

__setup_mmu:	sub	r3, r4, #16384		@ Page directory size
     25c:	e2443901 	sub	r3, r4, #16384	; 0x4000
		bic	r3, r3, #0xff		@ Align the pointer
     260:	e3c330ff 	bic	r3, r3, #255	; 0xff
		bic	r3, r3, #0x3f00
     264:	e3c33c3f 	bic	r3, r3, #16128	; 0x3f00
/*
 * Initialise the page tables, turning on the cacheable and bufferable
 * bits for the RAM area only.
 */
		mov	r0, r3
     268:	e1a00003 	mov	r0, r3
		mov	r9, r0, lsr #18
     26c:	e1a09920 	lsr	r9, r0, #18
		mov	r9, r9, lsl #18		@ start of RAM
     270:	e1a09909 	lsl	r9, r9, #18
		add	r10, r9, #0x10000000	@ a reasonable RAM size
     274:	e289a201 	add	sl, r9, #268435456	; 0x10000000
		mov	r1, #0x12		@ XN|U + section mapping
     278:	e3a01012 	mov	r1, #18
		orr	r1, r1, #3 << 10	@ AP=11
     27c:	e3811b03 	orr	r1, r1, #3072	; 0xc00
		add	r2, r3, #16384
     280:	e2832901 	add	r2, r3, #16384	; 0x4000
1:		cmp	r1, r9			@ if virt > start of RAM
     284:	e1510009 	cmp	r1, r9
		cmphs	r10, r1			@   && end of RAM > virt
     288:	215a0001 	cmpcs	sl, r1
		bic	r1, r1, #0x1c		@ clear XN|U + C + B
     28c:	e3c1101c 	bic	r1, r1, #28
		orrlo	r1, r1, #0x10		@ Set XN|U for non-RAM
     290:	33811010 	orrcc	r1, r1, #16
		orrhs	r1, r1, r6		@ set RAM section settings
     294:	21811006 	orrcs	r1, r1, r6
		str	r1, [r0], #4		@ 1:1 mapping
     298:	e4801004 	str	r1, [r0], #4
		add	r1, r1, #1048576
     29c:	e2811601 	add	r1, r1, #1048576	; 0x100000
		teq	r0, r2
     2a0:	e1300002 	teq	r0, r2
		bne	1b
     2a4:	1afffff6 	bne	284 <__setup_mmu+0x28>
 * If ever we are running from Flash, then we surely want the cache
 * to be enabled also for our execution instance...  We map 2MB of it
 * so there is no map overlap problem for up to 1 MB compressed kernel.
 * If the execution is in RAM then we would only be duplicating the above.
 */
		orr	r1, r6, #0x04		@ ensure B is set for this
     2a8:	e3861004 	orr	r1, r6, #4
		orr	r1, r1, #3 << 10
     2ac:	e3811b03 	orr	r1, r1, #3072	; 0xc00
		mov	r2, pc
     2b0:	e1a0200f 	mov	r2, pc
		mov	r2, r2, lsr #20
     2b4:	e1a02a22 	lsr	r2, r2, #20
		orr	r1, r1, r2, lsl #20
     2b8:	e1811a02 	orr	r1, r1, r2, lsl #20
		add	r0, r3, r2, lsl #2
     2bc:	e0830102 	add	r0, r3, r2, lsl #2
		str	r1, [r0], #4
     2c0:	e4801004 	str	r1, [r0], #4
		add	r1, r1, #1048576
     2c4:	e2811601 	add	r1, r1, #1048576	; 0x100000
		str	r1, [r0]
     2c8:	e5801000 	str	r1, [r0]
		mov	pc, lr
     2cc:	e1a0f00e 	mov	pc, lr

000002d0 <__arm926ejs_mmu_cache_on>:
		mov	r0, #4			@ put dcache in WT mode
		mcr	p15, 7, r0, c15, c0, 0
#endif

__armv4_mmu_cache_on:
		mov	r12, lr
     2d0:	e1a0c00e 	mov	ip, lr
#ifdef CONFIG_MMU
		mov	r6, #CB_BITS | 0x12	@ U
     2d4:	e3a0601e 	mov	r6, #30
		bl	__setup_mmu
     2d8:	ebffffdf 	bl	25c <__setup_mmu>
		mov	r0, #0
     2dc:	e3a00000 	mov	r0, #0
		mcr	p15, 0, r0, c7, c10, 4	@ drain write buffer
     2e0:	ee070f9a 	mcr	15, 0, r0, cr7, cr10, {4}
		mcr	p15, 0, r0, c8, c7, 0	@ flush I,D TLBs
     2e4:	ee080f17 	mcr	15, 0, r0, cr8, cr7, {0}
		mrc	p15, 0, r0, c1, c0, 0	@ read control reg
     2e8:	ee110f10 	mrc	15, 0, r0, cr1, cr0, {0}
		orr	r0, r0, #0x5000		@ I-cache enable, RR cache replacement
     2ec:	e3800a05 	orr	r0, r0, #20480	; 0x5000
		orr	r0, r0, #0x0030
     2f0:	e3800030 	orr	r0, r0, #48	; 0x30
#ifdef CONFIG_CPU_ENDIAN_BE8
		orr	r0, r0, #1 << 25	@ big-endian page tables
#endif
		bl	__common_mmu_cache_on
     2f4:	eb000030 	bl	3bc <__common_mmu_cache_on>
		mov	r0, #0
     2f8:	e3a00000 	mov	r0, #0
		mcr	p15, 0, r0, c8, c7, 0	@ flush I,D TLBs
     2fc:	ee080f17 	mcr	15, 0, r0, cr8, cr7, {0}
#endif
		mov	pc, r12
     300:	e1a0f00c 	mov	pc, ip

00000304 <__armv7_mmu_cache_on>:

__armv7_mmu_cache_on:
		mov	r12, lr
     304:	e1a0c00e 	mov	ip, lr
#ifdef CONFIG_MMU
		mrc	p15, 0, r11, c0, c1, 4	@ read ID_MMFR0
     308:	ee10bf91 	mrc	15, 0, fp, cr0, cr1, {4}
		tst	r11, #0xf		@ VMSA
     30c:	e31b000f 	tst	fp, #15
		movne	r6, #CB_BITS | 0x02	@ !XN
     310:	13a0600e 	movne	r6, #14
		blne	__setup_mmu
     314:	1bffffd0 	blne	25c <__setup_mmu>
		mov	r0, #0
     318:	e3a00000 	mov	r0, #0
		mcr	p15, 0, r0, c7, c10, 4	@ drain write buffer
     31c:	ee070f9a 	mcr	15, 0, r0, cr7, cr10, {4}
		tst	r11, #0xf		@ VMSA
     320:	e31b000f 	tst	fp, #15
		mcrne	p15, 0, r0, c8, c7, 0	@ flush I,D TLBs
     324:	1e080f17 	mcrne	15, 0, r0, cr8, cr7, {0}
#endif
		mrc	p15, 0, r0, c1, c0, 0	@ read control reg
     328:	ee110f10 	mrc	15, 0, r0, cr1, cr0, {0}
		orr	r0, r0, #0x5000		@ I-cache enable, RR cache replacement
     32c:	e3800a05 	orr	r0, r0, #20480	; 0x5000
		orr	r0, r0, #0x003c		@ write buffer
     330:	e380003c 	orr	r0, r0, #60	; 0x3c
#ifdef CONFIG_MMU
#ifdef CONFIG_CPU_ENDIAN_BE8
		orr	r0, r0, #1 << 25	@ big-endian page tables
#endif
		orrne	r0, r0, #1		@ MMU enabled
     334:	13800001 	orrne	r0, r0, #1
		movne	r1, #0xfffffffd		@ domain 0 = client
     338:	13e01002 	mvnne	r1, #2
		mcrne	p15, 0, r3, c2, c0, 0	@ load page table pointer
     33c:	1e023f10 	mcrne	15, 0, r3, cr2, cr0, {0}
		mcrne	p15, 0, r1, c3, c0, 0	@ load domain access control
     340:	1e031f10 	mcrne	15, 0, r1, cr3, cr0, {0}
#endif
		mcr	p15, 0, r0, c7, c5, 4	@ ISB
     344:	ee070f95 	mcr	15, 0, r0, cr7, cr5, {4}
		mcr	p15, 0, r0, c1, c0, 0	@ load control register
     348:	ee010f10 	mcr	15, 0, r0, cr1, cr0, {0}
		mrc	p15, 0, r0, c1, c0, 0	@ and read it back
     34c:	ee110f10 	mrc	15, 0, r0, cr1, cr0, {0}
		mov	r0, #0
     350:	e3a00000 	mov	r0, #0
		mcr	p15, 0, r0, c7, c5, 4	@ ISB
     354:	ee070f95 	mcr	15, 0, r0, cr7, cr5, {4}
		mov	pc, r12
     358:	e1a0f00c 	mov	pc, ip

0000035c <__fa526_cache_on>:

__fa526_cache_on:
		mov	r12, lr
     35c:	e1a0c00e 	mov	ip, lr
		mov	r6, #CB_BITS | 0x12	@ U
     360:	e3a0601e 	mov	r6, #30
		bl	__setup_mmu
     364:	ebffffbc 	bl	25c <__setup_mmu>
		mov	r0, #0
     368:	e3a00000 	mov	r0, #0
		mcr	p15, 0, r0, c7, c7, 0	@ Invalidate whole cache
     36c:	ee070f17 	mcr	15, 0, r0, cr7, cr7, {0}
		mcr	p15, 0, r0, c7, c10, 4	@ drain write buffer
     370:	ee070f9a 	mcr	15, 0, r0, cr7, cr10, {4}
		mcr	p15, 0, r0, c8, c7, 0	@ flush UTLB
     374:	ee080f17 	mcr	15, 0, r0, cr8, cr7, {0}
		mrc	p15, 0, r0, c1, c0, 0	@ read control reg
     378:	ee110f10 	mrc	15, 0, r0, cr1, cr0, {0}
		orr	r0, r0, #0x1000		@ I-cache enable
     37c:	e3800a01 	orr	r0, r0, #4096	; 0x1000
		bl	__common_mmu_cache_on
     380:	eb00000d 	bl	3bc <__common_mmu_cache_on>
		mov	r0, #0
     384:	e3a00000 	mov	r0, #0
		mcr	p15, 0, r0, c8, c7, 0	@ flush UTLB
     388:	ee080f17 	mcr	15, 0, r0, cr8, cr7, {0}
		mov	pc, r12
     38c:	e1a0f00c 	mov	pc, ip

00000390 <__arm6_mmu_cache_on>:

__arm6_mmu_cache_on:
		mov	r12, lr
     390:	e1a0c00e 	mov	ip, lr
		mov	r6, #CB_BITS | 0x12	@ U
     394:	e3a0601e 	mov	r6, #30
		bl	__setup_mmu
     398:	ebffffaf 	bl	25c <__setup_mmu>
		mov	r0, #0
     39c:	e3a00000 	mov	r0, #0
		mcr	p15, 0, r0, c7, c0, 0	@ invalidate whole cache v3
     3a0:	ee070f10 	mcr	15, 0, r0, cr7, cr0, {0}
		mcr	p15, 0, r0, c5, c0, 0	@ invalidate whole TLB v3
     3a4:	ee050f10 	mcr	15, 0, r0, cr5, cr0, {0}
		mov	r0, #0x30
     3a8:	e3a00030 	mov	r0, #48	; 0x30
		bl	__common_mmu_cache_on
     3ac:	eb000002 	bl	3bc <__common_mmu_cache_on>
		mov	r0, #0
     3b0:	e3a00000 	mov	r0, #0
		mcr	p15, 0, r0, c5, c0, 0	@ invalidate whole TLB v3
     3b4:	ee050f10 	mcr	15, 0, r0, cr5, cr0, {0}
		mov	pc, r12
     3b8:	e1a0f00c 	mov	pc, ip

000003bc <__common_mmu_cache_on>:

__common_mmu_cache_on:
#ifndef CONFIG_THUMB2_KERNEL
#ifndef DEBUG
		orr	r0, r0, #0x000d		@ Write buffer, mmu
     3bc:	e380000d 	orr	r0, r0, #13
#endif
		mov	r1, #-1
     3c0:	e3e01000 	mvn	r1, #0
		mcr	p15, 0, r3, c2, c0, 0	@ load page table pointer
     3c4:	ee023f10 	mcr	15, 0, r3, cr2, cr0, {0}
		mcr	p15, 0, r1, c3, c0, 0	@ load domain access control
     3c8:	ee031f10 	mcr	15, 0, r1, cr3, cr0, {0}
		b	1f
     3cc:	ea000003 	b	3e0 <__common_mmu_cache_on+0x24>
     3d0:	e320f000 	nop	{0}
     3d4:	e320f000 	nop	{0}
     3d8:	e320f000 	nop	{0}
     3dc:	e320f000 	nop	{0}
		.align	5			@ cache line aligned
1:		mcr	p15, 0, r0, c1, c0, 0	@ load control register
     3e0:	ee010f10 	mcr	15, 0, r0, cr1, cr0, {0}
		mrc	p15, 0, r0, c1, c0, 0	@ and read it back to
     3e4:	ee110f10 	mrc	15, 0, r0, cr1, cr0, {0}
		sub	pc, lr, r0, lsr #32	@ properly flush pipeline
     3e8:	e04ef020 	sub	pc, lr, r0, lsr #32

000003ec <call_cache_fn>:
 *  r3  = block offset
 *  r9  = corrupted
 *  r12 = corrupted
 */

call_cache_fn:	adr	r12, proc_types
     3ec:	e28fc01c 	add	ip, pc, #28
#ifdef CONFIG_CPU_CP15
		mrc	p15, 0, r9, c0, c0	@ get processor ID
     3f0:	ee109f10 	mrc	15, 0, r9, cr0, cr0, {0}
#else
		ldr	r9, =CONFIG_PROCESSOR_ID
#endif
1:		ldr	r1, [r12, #0]		@ get value
     3f4:	e59c1000 	ldr	r1, [ip]
		ldr	r2, [r12, #4]		@ get mask
     3f8:	e59c2004 	ldr	r2, [ip, #4]
		eor	r1, r1, r9		@ (real ^ match)
     3fc:	e0211009 	eor	r1, r1, r9
		tst	r1, r2			@       & mask
     400:	e1110002 	tst	r1, r2
 ARM(		addeq	pc, r12, r3		) @ call cache function
     404:	008cf003 	addeq	pc, ip, r3
 THUMB(		addeq	r12, r3			)
 THUMB(		moveq	pc, r12			) @ call cache function
		add	r12, r12, #PROC_ENTRY_SIZE
     408:	e28cc014 	add	ip, ip, #20
		b	1b
     40c:	eafffff8 	b	3f4 <call_cache_fn+0x8>

00000410 <proc_types>:
     410:	41560600 ffffffe0 ea000082 ea000081     ..VA............
proc_types:
		.word	0x41560600		@ ARM6/610
		.word	0xffffffe0
		W(b)	__arm6_mmu_cache_off	@ works, but slow
		W(b)	__arm6_mmu_cache_off
		mov	pc, lr
     420:	e1a0f00e 41007000 fff8fe00 ea00007f     .....p.A........
#endif

		.word	0x41007000		@ ARM7/710
		.word	0xfff8fe00
		W(b)	__arm7_mmu_cache_off
		W(b)	__arm7_mmu_cache_off
     430:	ea00007e e1a0f00e 41807200 ffffff00     ~........r.A....
		mov	pc, lr
 THUMB(		nop				)

		.word	0x41807200		@ ARM720T (writethrough)
		.word	0xffffff00
		W(b)	__armv4_mmu_cache_on
     440:	eaffffa2 ea000065 e1a0f00e 41007400     ....e........t.A
		W(b)	__armv4_mmu_cache_off
		mov	pc, lr
     450:	ff00ff00 eaffff71 ea00005a ea0000e7     ....q...Z.......

		.word	0x41007400		@ ARM74x
		.word	0xff00ff00
		W(b)	__armv3_mpu_cache_on
		W(b)	__armv3_mpu_cache_off
		W(b)	__armv3_mpu_cache_flush
     460:	41009400 ff00ff00 eaffff56 ea00004d     ...A....V...M...
		
		.word	0x41009400		@ ARM94x
		.word	0xff00ff00
		W(b)	__armv4_mpu_cache_on
		W(b)	__armv4_mpu_cache_off
		W(b)	__armv4_mpu_cache_flush
     470:	ea00007c 41069260 ff0ffff0 eaffff93     |...`..A........

		.word	0x41069260		@ ARM926EJ-S (v5TEJ)
		.word	0xff0ffff0
		W(b)	__arm926ejs_mmu_cache_on
		W(b)	__armv4_mmu_cache_off
     480:	ea000056 ea0000bf 00007000 0000f000     V........p......
		W(b)	__armv5tej_mmu_cache_flush

		.word	0x00007000		@ ARM7 IDs
		.word	0x0000f000
		mov	pc, lr
     490:	e1a0f00e e1a0f00e e1a0f00e 4401a100     ...............D
 THUMB(		nop				)
		mov	pc, lr
 THUMB(		nop				)
		mov	pc, lr
     4a0:	ffffffe0 eaffff89 ea00004c ea0000ba     ........L.......

		.word	0x4401a100		@ sa110 / sa1100
		.word	0xffffffe0
		W(b)	__armv4_mmu_cache_on
		W(b)	__armv4_mmu_cache_off
		W(b)	__armv4_mmu_cache_flush
     4b0:	6901b110 fffffff0 eaffff84 ea000047     ...i........G...

		.word	0x6901b110		@ sa1110
		.word	0xfffffff0
		W(b)	__armv4_mmu_cache_on
		W(b)	__armv4_mmu_cache_off
		W(b)	__armv4_mmu_cache_flush
     4c0:	ea0000b5 56056900 ffffff00 eaffff7f     .....i.V........

		.word	0x56056900
		.word	0xffffff00		@ PXA9xx
		W(b)	__armv4_mmu_cache_on
		W(b)	__armv4_mmu_cache_off
     4d0:	ea000042 ea0000b0 56158000 fffff000     B..........V....
		W(b)	__armv4_mmu_cache_flush

		.word	0x56158000		@ PXA168
		.word	0xfffff000
		W(b)	__armv4_mmu_cache_on
     4e0:	eaffff7a ea00003d ea0000a6 56050000     z...=..........V
		W(b)	__armv4_mmu_cache_off
		W(b)	__armv5tej_mmu_cache_flush
     4f0:	ff0f0000 eaffff75 ea000038 ea0000a1     ....u...8.......

		.word	0x56050000		@ Feroceon
		.word	0xff0f0000
		W(b)	__armv4_mmu_cache_on
		W(b)	__armv4_mmu_cache_off
		W(b)	__armv5tej_mmu_cache_flush
     500:	66015261 ff01fff1 eaffff93 ea000033     aR.f........3...

		.word	0x66015261		@ FA526
		.word	0xff01fff1
		W(b)	__fa526_cache_on
		W(b)	__armv4_mmu_cache_off
		W(b)	__fa526_cache_flush
     510:	ea000062 00020000 000f0000 eaffff6b     b...........k...
		@ These match on the architecture ID

		.word	0x00020000		@ ARMv4T
		.word	0x000f0000
		W(b)	__armv4_mmu_cache_on
		W(b)	__armv4_mmu_cache_off
     520:	ea00002e ea00009c 00050000 000f0000     ................
		W(b)	__armv4_mmu_cache_flush

		.word	0x00050000		@ ARMv5TE
		.word	0x000f0000
		W(b)	__armv4_mmu_cache_on
     530:	eaffff66 ea000029 ea000097 00060000     f...)...........
		W(b)	__armv4_mmu_cache_off
		W(b)	__armv4_mmu_cache_flush
     540:	000f0000 eaffff61 ea000024 ea00008d     ....a...$.......

		.word	0x00060000		@ ARMv5TEJ
		.word	0x000f0000
		W(b)	__armv4_mmu_cache_on
		W(b)	__armv4_mmu_cache_off
		W(b)	__armv5tej_mmu_cache_flush
     550:	0007b000 000ff000 eaffff5c ea00001f     ........\.......

		.word	0x0007b000		@ ARMv6
		.word	0x000ff000
		W(b)	__armv4_mmu_cache_on
		W(b)	__armv4_mmu_cache_off
		W(b)	__armv6_mmu_cache_flush
     560:	ea000053 000f0000 000f0000 eaffff64     S...........d...

		.word	0x000f0000		@ new CPU Id
		.word	0x000f0000
		W(b)	__armv7_mmu_cache_on
		W(b)	__armv7_mmu_cache_off
     570:	ea000021 ea000054 00000000 00000000     !...T...........
		W(b)	__armv7_mmu_cache_flush

		.word	0			@ unrecognised type
		.word	0
		mov	pc, lr
     580:	e1a0f00e e1a0f00e e1a0f00e e320f000     .............. .
 THUMB(		nop				)
		mov	pc, lr
 THUMB(		nop				)
		mov	pc, lr
     590:	e320f000 e320f000 e320f000 e320f000     .. ... ... ... .

000005a0 <cache_off>:
 *  r0, r1, r2, r3, r9, r12 corrupted
 * This routine must preserve:
 *  r4, r7, r8
 */
		.align	5
cache_off:	mov	r3, #12			@ cache_off function
     5a0:	e3a0300c 	mov	r3, #12
		b	call_cache_fn
     5a4:	eaffff90 	b	3ec <call_cache_fn>

000005a8 <__armv4_mpu_cache_off>:

__armv4_mpu_cache_off:
		mrc	p15, 0, r0, c1, c0
     5a8:	ee110f10 	mrc	15, 0, r0, cr1, cr0, {0}
		bic	r0, r0, #0x000d
     5ac:	e3c0000d 	bic	r0, r0, #13
		mcr	p15, 0, r0, c1, c0	@ turn MPU and cache off
     5b0:	ee010f10 	mcr	15, 0, r0, cr1, cr0, {0}
		mov	r0, #0
     5b4:	e3a00000 	mov	r0, #0
		mcr	p15, 0, r0, c7, c10, 4	@ drain write buffer
     5b8:	ee070f9a 	mcr	15, 0, r0, cr7, cr10, {4}
		mcr	p15, 0, r0, c7, c6, 0	@ flush D-Cache
     5bc:	ee070f16 	mcr	15, 0, r0, cr7, cr6, {0}
		mcr	p15, 0, r0, c7, c5, 0	@ flush I-Cache
     5c0:	ee070f15 	mcr	15, 0, r0, cr7, cr5, {0}
		mov	pc, lr
     5c4:	e1a0f00e 	mov	pc, lr

000005c8 <__armv3_mpu_cache_off>:

__armv3_mpu_cache_off:
		mrc	p15, 0, r0, c1, c0
     5c8:	ee110f10 	mrc	15, 0, r0, cr1, cr0, {0}
		bic	r0, r0, #0x000d
     5cc:	e3c0000d 	bic	r0, r0, #13
		mcr	p15, 0, r0, c1, c0, 0	@ turn MPU and cache off
     5d0:	ee010f10 	mcr	15, 0, r0, cr1, cr0, {0}
		mov	r0, #0
     5d4:	e3a00000 	mov	r0, #0
		mcr	p15, 0, r0, c7, c0, 0	@ invalidate whole cache v3
     5d8:	ee070f10 	mcr	15, 0, r0, cr7, cr0, {0}
		mov	pc, lr
     5dc:	e1a0f00e 	mov	pc, lr

000005e0 <__armv4_mmu_cache_off>:

__armv4_mmu_cache_off:
#ifdef CONFIG_MMU
		mrc	p15, 0, r0, c1, c0
     5e0:	ee110f10 	mrc	15, 0, r0, cr1, cr0, {0}
		bic	r0, r0, #0x000d
     5e4:	e3c0000d 	bic	r0, r0, #13
		mcr	p15, 0, r0, c1, c0	@ turn MMU and cache off
     5e8:	ee010f10 	mcr	15, 0, r0, cr1, cr0, {0}
		mov	r0, #0
     5ec:	e3a00000 	mov	r0, #0
		mcr	p15, 0, r0, c7, c7	@ invalidate whole cache v4
     5f0:	ee070f17 	mcr	15, 0, r0, cr7, cr7, {0}
		mcr	p15, 0, r0, c8, c7	@ invalidate whole TLB v4
     5f4:	ee080f17 	mcr	15, 0, r0, cr8, cr7, {0}
#endif
		mov	pc, lr
     5f8:	e1a0f00e 	mov	pc, lr

000005fc <__armv7_mmu_cache_off>:

__armv7_mmu_cache_off:
		mrc	p15, 0, r0, c1, c0
     5fc:	ee110f10 	mrc	15, 0, r0, cr1, cr0, {0}
#ifdef CONFIG_MMU
		bic	r0, r0, #0x000d
     600:	e3c0000d 	bic	r0, r0, #13
#else
		bic	r0, r0, #0x000c
#endif
		mcr	p15, 0, r0, c1, c0	@ turn MMU and cache off
     604:	ee010f10 	mcr	15, 0, r0, cr1, cr0, {0}
		mov	r12, lr
     608:	e1a0c00e 	mov	ip, lr
		bl	__armv7_mmu_cache_flush
     60c:	eb00002e 	bl	6cc <__armv7_mmu_cache_flush>
		mov	r0, #0
     610:	e3a00000 	mov	r0, #0
#ifdef CONFIG_MMU
		mcr	p15, 0, r0, c8, c7, 0	@ invalidate whole TLB
     614:	ee080f17 	mcr	15, 0, r0, cr8, cr7, {0}
#endif
		mcr	p15, 0, r0, c7, c5, 6	@ invalidate BTC
     618:	ee070fd5 	mcr	15, 0, r0, cr7, cr5, {6}
		mcr	p15, 0, r0, c7, c10, 4	@ DSB
     61c:	ee070f9a 	mcr	15, 0, r0, cr7, cr10, {4}
		mcr	p15, 0, r0, c7, c5, 4	@ ISB
     620:	ee070f95 	mcr	15, 0, r0, cr7, cr5, {4}
		mov	pc, r12
     624:	e1a0f00c 	mov	pc, ip

00000628 <__arm6_mmu_cache_off>:

__arm6_mmu_cache_off:
		mov	r0, #0x00000030		@ ARM6 control reg.
     628:	e3a00030 	mov	r0, #48	; 0x30
		b	__armv3_mmu_cache_off
     62c:	ea000001 	b	638 <__armv3_mmu_cache_off>

00000630 <__arm7_mmu_cache_off>:

__arm7_mmu_cache_off:
		mov	r0, #0x00000070		@ ARM7 control reg.
     630:	e3a00070 	mov	r0, #112	; 0x70
		b	__armv3_mmu_cache_off
     634:	eaffffff 	b	638 <__armv3_mmu_cache_off>

00000638 <__armv3_mmu_cache_off>:

__armv3_mmu_cache_off:
		mcr	p15, 0, r0, c1, c0, 0	@ turn MMU and cache off
     638:	ee010f10 	mcr	15, 0, r0, cr1, cr0, {0}
		mov	r0, #0
     63c:	e3a00000 	mov	r0, #0
		mcr	p15, 0, r0, c7, c0, 0	@ invalidate whole cache v3
     640:	ee070f10 	mcr	15, 0, r0, cr7, cr0, {0}
		mcr	p15, 0, r0, c5, c0, 0	@ invalidate whole TLB v3
     644:	ee050f10 	mcr	15, 0, r0, cr5, cr0, {0}
		mov	pc, lr
     648:	e1a0f00e 	mov	pc, lr
     64c:	e320f000 	nop	{0}
     650:	e320f000 	nop	{0}
     654:	e320f000 	nop	{0}
     658:	e320f000 	nop	{0}
     65c:	e320f000 	nop	{0}

00000660 <cache_clean_flush>:
 * This routine must preserve:
 *  r4, r6, r7, r8
 */
		.align	5
cache_clean_flush:
		mov	r3, #16
     660:	e3a03010 	mov	r3, #16
		b	call_cache_fn
     664:	eaffff60 	b	3ec <call_cache_fn>

00000668 <__armv4_mpu_cache_flush>:

__armv4_mpu_cache_flush:
		mov	r2, #1
     668:	e3a02001 	mov	r2, #1
		mov	r3, #0
     66c:	e3a03000 	mov	r3, #0
		mcr	p15, 0, ip, c7, c6, 0	@ invalidate D cache
     670:	ee07cf16 	mcr	15, 0, ip, cr7, cr6, {0}
		mov	r1, #7 << 5		@ 8 segments
     674:	e3a010e0 	mov	r1, #224	; 0xe0
1:		orr	r3, r1, #63 << 26	@ 64 entries
     678:	e381333f 	orr	r3, r1, #-67108864	; 0xfc000000
2:		mcr	p15, 0, r3, c7, c14, 2	@ clean & invalidate D index
     67c:	ee073f5e 	mcr	15, 0, r3, cr7, cr14, {2}
		subs	r3, r3, #1 << 26
     680:	e2533301 	subs	r3, r3, #67108864	; 0x4000000
		bcs	2b			@ entries 63 to 0
     684:	2afffffc 	bcs	67c <__armv4_mpu_cache_flush+0x14>
		subs 	r1, r1, #1 << 5
     688:	e2511020 	subs	r1, r1, #32
		bcs	1b			@ segments 7 to 0
     68c:	2afffff9 	bcs	678 <__armv4_mpu_cache_flush+0x10>

		teq	r2, #0
     690:	e3320000 	teq	r2, #0
		mcrne	p15, 0, ip, c7, c5, 0	@ invalidate I cache
     694:	1e07cf15 	mcrne	15, 0, ip, cr7, cr5, {0}
		mcr	p15, 0, ip, c7, c10, 4	@ drain WB
     698:	ee07cf9a 	mcr	15, 0, ip, cr7, cr10, {4}
		mov	pc, lr
     69c:	e1a0f00e 	mov	pc, lr

000006a0 <__fa526_cache_flush>:
		
__fa526_cache_flush:
		mov	r1, #0
     6a0:	e3a01000 	mov	r1, #0
		mcr	p15, 0, r1, c7, c14, 0	@ clean and invalidate D cache
     6a4:	ee071f1e 	mcr	15, 0, r1, cr7, cr14, {0}
		mcr	p15, 0, r1, c7, c5, 0	@ flush I cache
     6a8:	ee071f15 	mcr	15, 0, r1, cr7, cr5, {0}
		mcr	p15, 0, r1, c7, c10, 4	@ drain WB
     6ac:	ee071f9a 	mcr	15, 0, r1, cr7, cr10, {4}
		mov	pc, lr
     6b0:	e1a0f00e 	mov	pc, lr

000006b4 <__armv6_mmu_cache_flush>:

__armv6_mmu_cache_flush:
		mov	r1, #0
     6b4:	e3a01000 	mov	r1, #0
		mcr	p15, 0, r1, c7, c14, 0	@ clean+invalidate D
     6b8:	ee071f1e 	mcr	15, 0, r1, cr7, cr14, {0}
		mcr	p15, 0, r1, c7, c5, 0	@ invalidate I+BTB
     6bc:	ee071f15 	mcr	15, 0, r1, cr7, cr5, {0}
		mcr	p15, 0, r1, c7, c15, 0	@ clean+invalidate unified
     6c0:	ee071f1f 	mcr	15, 0, r1, cr7, cr15, {0}
		mcr	p15, 0, r1, c7, c10, 4	@ drain WB
     6c4:	ee071f9a 	mcr	15, 0, r1, cr7, cr10, {4}
		mov	pc, lr
     6c8:	e1a0f00e 	mov	pc, lr

000006cc <__armv7_mmu_cache_flush>:

__armv7_mmu_cache_flush:
		mrc	p15, 0, r10, c0, c1, 5	@ read ID_MMFR1
     6cc:	ee10afb1 	mrc	15, 0, sl, cr0, cr1, {5}
		tst	r10, #0xf << 16		@ hierarchical cache (ARMv7)
     6d0:	e31a080f 	tst	sl, #983040	; 0xf0000
		mov	r10, #0
     6d4:	e3a0a000 	mov	sl, #0
		beq	hierarchical
     6d8:	0a000001 	beq	6e4 <hierarchical>
		mcr	p15, 0, r10, c7, c14, 0	@ clean+invalidate D
     6dc:	ee07af1e 	mcr	15, 0, sl, cr7, cr14, {0}
		b	iflush
     6e0:	ea000023 	b	774 <iflush>

000006e4 <hierarchical>:
hierarchical:
		mcr	p15, 0, r10, c7, c10, 5	@ DMB
     6e4:	ee07afba 	mcr	15, 0, sl, cr7, cr10, {5}
		stmfd	sp!, {r0-r7, r9-r11}
     6e8:	e92d0eff 	push	{r0, r1, r2, r3, r4, r5, r6, r7, r9, sl, fp}
		mrc	p15, 1, r0, c0, c0, 1	@ read clidr
     6ec:	ee300f30 	mrc	15, 1, r0, cr0, cr0, {1}
		ands	r3, r0, #0x7000000	@ extract loc from clidr
     6f0:	e2103407 	ands	r3, r0, #117440512	; 0x7000000
		mov	r3, r3, lsr #23		@ left align loc bit field
     6f4:	e1a03ba3 	lsr	r3, r3, #23
		beq	finished		@ if loc is 0, then no need to clean
     6f8:	0a00001a 	beq	768 <finished>
		mov	r10, #0			@ start clean at cache level 0
     6fc:	e3a0a000 	mov	sl, #0

00000700 <loop1>:
loop1:
		add	r2, r10, r10, lsr #1	@ work out 3x current cache level
     700:	e08a20aa 	add	r2, sl, sl, lsr #1
		mov	r1, r0, lsr r2		@ extract cache type bits from clidr
     704:	e1a01230 	lsr	r1, r0, r2
		and	r1, r1, #7		@ mask of the bits for current cache only
     708:	e2011007 	and	r1, r1, #7
		cmp	r1, #2			@ see what cache we have at this level
     70c:	e3510002 	cmp	r1, #2
		blt	skip			@ skip if no cache, or just i-cache
     710:	ba000011 	blt	75c <skip>
		mcr	p15, 2, r10, c0, c0, 0	@ select current cache level in cssr
     714:	ee40af10 	mcr	15, 2, sl, cr0, cr0, {0}
		mcr	p15, 0, r10, c7, c5, 4	@ isb to sych the new cssr&csidr
     718:	ee07af95 	mcr	15, 0, sl, cr7, cr5, {4}
		mrc	p15, 1, r1, c0, c0, 0	@ read the new csidr
     71c:	ee301f10 	mrc	15, 1, r1, cr0, cr0, {0}
		and	r2, r1, #7		@ extract the length of the cache lines
     720:	e2012007 	and	r2, r1, #7
		add	r2, r2, #4		@ add 4 (line length offset)
     724:	e2822004 	add	r2, r2, #4
		ldr	r4, =0x3ff
     728:	e59f40e0 	ldr	r4, [pc, #224]	; 810 <__armv3_mmu_cache_flush+0x10>
		ands	r4, r4, r1, lsr #3	@ find maximum number on the way size
     72c:	e01441a1 	ands	r4, r4, r1, lsr #3
		clz	r5, r4			@ find bit position of way size increment
     730:	e16f5f14 	clz	r5, r4
		ldr	r7, =0x7fff
     734:	e59f70d8 	ldr	r7, [pc, #216]	; 814 <__armv3_mmu_cache_flush+0x14>
		ands	r7, r7, r1, lsr #13	@ extract max number of the index size
     738:	e01776a1 	ands	r7, r7, r1, lsr #13

0000073c <loop2>:
loop2:
		mov	r9, r4			@ create working copy of max way size
     73c:	e1a09004 	mov	r9, r4

00000740 <loop3>:
loop3:
 ARM(		orr	r11, r10, r9, lsl r5	) @ factor way and cache number into r11
     740:	e18ab519 	orr	fp, sl, r9, lsl r5
 ARM(		orr	r11, r11, r7, lsl r2	) @ factor index number into r11
     744:	e18bb217 	orr	fp, fp, r7, lsl r2
 THUMB(		lsl	r6, r9, r5		)
 THUMB(		orr	r11, r10, r6		) @ factor way and cache number into r11
 THUMB(		lsl	r6, r7, r2		)
 THUMB(		orr	r11, r11, r6		) @ factor index number into r11
		mcr	p15, 0, r11, c7, c14, 2	@ clean & invalidate by set/way
     748:	ee07bf5e 	mcr	15, 0, fp, cr7, cr14, {2}
		subs	r9, r9, #1		@ decrement the way
     74c:	e2599001 	subs	r9, r9, #1
		bge	loop3
     750:	aafffffa 	bge	740 <loop3>
		subs	r7, r7, #1		@ decrement the index
     754:	e2577001 	subs	r7, r7, #1
		bge	loop2
     758:	aafffff7 	bge	73c <loop2>

0000075c <skip>:
skip:
		add	r10, r10, #2		@ increment cache number
     75c:	e28aa002 	add	sl, sl, #2
		cmp	r3, r10
     760:	e153000a 	cmp	r3, sl
		bgt	loop1
     764:	caffffe5 	bgt	700 <loop1>

00000768 <finished>:
finished:
		ldmfd	sp!, {r0-r7, r9-r11}
     768:	e8bd0eff 	pop	{r0, r1, r2, r3, r4, r5, r6, r7, r9, sl, fp}
		mov	r10, #0			@ swith back to cache level 0
     76c:	e3a0a000 	mov	sl, #0
		mcr	p15, 2, r10, c0, c0, 0	@ select current cache level in cssr
     770:	ee40af10 	mcr	15, 2, sl, cr0, cr0, {0}

00000774 <iflush>:
iflush:
		mcr	p15, 0, r10, c7, c10, 4	@ DSB
     774:	ee07af9a 	mcr	15, 0, sl, cr7, cr10, {4}
		mcr	p15, 0, r10, c7, c5, 0	@ invalidate I+BTB
     778:	ee07af15 	mcr	15, 0, sl, cr7, cr5, {0}
		mcr	p15, 0, r10, c7, c10, 4	@ DSB
     77c:	ee07af9a 	mcr	15, 0, sl, cr7, cr10, {4}
		mcr	p15, 0, r10, c7, c5, 4	@ ISB
     780:	ee07af95 	mcr	15, 0, sl, cr7, cr5, {4}
		mov	pc, lr
     784:	e1a0f00e 	mov	pc, lr

00000788 <__armv5tej_mmu_cache_flush>:

__armv5tej_mmu_cache_flush:
1:		mrc	p15, 0, r15, c7, c14, 3	@ test,clean,invalidate D cache
     788:	ee17ff7e 	mrc	15, 0, APSR_nzcv, cr7, cr14, {3}
		bne	1b
     78c:	1afffffd 	bne	788 <__armv5tej_mmu_cache_flush>
		mcr	p15, 0, r0, c7, c5, 0	@ flush I cache
     790:	ee070f15 	mcr	15, 0, r0, cr7, cr5, {0}
		mcr	p15, 0, r0, c7, c10, 4	@ drain WB
     794:	ee070f9a 	mcr	15, 0, r0, cr7, cr10, {4}
		mov	pc, lr
     798:	e1a0f00e 	mov	pc, lr

0000079c <__armv4_mmu_cache_flush>:

__armv4_mmu_cache_flush:
		mov	r2, #64*1024		@ default: 32K dcache size (*2)
     79c:	e3a02801 	mov	r2, #65536	; 0x10000
		mov	r11, #32		@ default: 32 byte line size
     7a0:	e3a0b020 	mov	fp, #32
		mrc	p15, 0, r3, c0, c0, 1	@ read cache type
     7a4:	ee103f30 	mrc	15, 0, r3, cr0, cr0, {1}
		teq	r3, r9			@ cache ID register present?
     7a8:	e1330009 	teq	r3, r9
		beq	no_cache_id
     7ac:	0a000009 	beq	7d8 <no_cache_id>
		mov	r1, r3, lsr #18
     7b0:	e1a01923 	lsr	r1, r3, #18
		and	r1, r1, #7
     7b4:	e2011007 	and	r1, r1, #7
		mov	r2, #1024
     7b8:	e3a02b01 	mov	r2, #1024	; 0x400
		mov	r2, r2, lsl r1		@ base dcache size *2
     7bc:	e1a02112 	lsl	r2, r2, r1
		tst	r3, #1 << 14		@ test M bit
     7c0:	e3130901 	tst	r3, #16384	; 0x4000
		addne	r2, r2, r2, lsr #1	@ +1/2 size if M == 1
     7c4:	108220a2 	addne	r2, r2, r2, lsr #1
		mov	r3, r3, lsr #12
     7c8:	e1a03623 	lsr	r3, r3, #12
		and	r3, r3, #3
     7cc:	e2033003 	and	r3, r3, #3
		mov	r11, #8
     7d0:	e3a0b008 	mov	fp, #8
		mov	r11, r11, lsl r3	@ cache line size in bytes
     7d4:	e1a0b31b 	lsl	fp, fp, r3

000007d8 <no_cache_id>:
no_cache_id:
		mov	r1, pc
     7d8:	e1a0100f 	mov	r1, pc
		bic	r1, r1, #63		@ align to longest cache line
     7dc:	e3c1103f 	bic	r1, r1, #63	; 0x3f
		add	r2, r1, r2
     7e0:	e0812002 	add	r2, r1, r2
1:
 ARM(		ldr	r3, [r1], r11		) @ s/w flush D cache
     7e4:	e691300b 	ldr	r3, [r1], fp
 THUMB(		ldr     r3, [r1]		) @ s/w flush D cache
 THUMB(		add     r1, r1, r11		)
		teq	r1, r2
     7e8:	e1310002 	teq	r1, r2
		bne	1b
     7ec:	1afffffc 	bne	7e4 <no_cache_id+0xc>

		mcr	p15, 0, r1, c7, c5, 0	@ flush I cache
     7f0:	ee071f15 	mcr	15, 0, r1, cr7, cr5, {0}
		mcr	p15, 0, r1, c7, c6, 0	@ flush D cache
     7f4:	ee071f16 	mcr	15, 0, r1, cr7, cr6, {0}
		mcr	p15, 0, r1, c7, c10, 4	@ drain WB
     7f8:	ee071f9a 	mcr	15, 0, r1, cr7, cr10, {4}
		mov	pc, lr
     7fc:	e1a0f00e 	mov	pc, lr

00000800 <__armv3_mmu_cache_flush>:

__armv3_mmu_cache_flush:
__armv3_mpu_cache_flush:
		mov	r1, #0
     800:	e3a01000 	mov	r1, #0
		mcr	p15, 0, r1, c7, c0, 0	@ invalidate whole cache v3
     804:	ee071f10 	mcr	15, 0, r1, cr7, cr0, {0}
		mov	pc, lr
     808:	e1a0f00e 	mov	pc, lr
		@ determine final kernel image address
		mov	r4, pc
		and	r4, r4, #0xf8000000
		add	r4, r4, #TEXT_OFFSET
#else
		ldr	r4, =zreladdr
     80c:	80208000 	.word	0x80208000
		mcr	p15, 2, r10, c0, c0, 0	@ select current cache level in cssr
		mcr	p15, 0, r10, c7, c5, 4	@ isb to sych the new cssr&csidr
		mrc	p15, 1, r1, c0, c0, 0	@ read the new csidr
		and	r2, r1, #7		@ extract the length of the cache lines
		add	r2, r2, #4		@ add 4 (line length offset)
		ldr	r4, =0x3ff
     810:	000003ff 	.word	0x000003ff
		ands	r4, r4, r1, lsr #3	@ find maximum number on the way size
		clz	r5, r4			@ find bit position of way size increment
		ldr	r7, =0x7fff
     814:	00007fff 	.word	0x00007fff

00000818 <reloc_code_end>:
     818:	e320f000 	nop	{0}
     81c:	e320f000 	nop	{0}

00000820 <putstr>:

static void putstr(const char *ptr)
{
	char c;

	while ((c = *ptr++) != '\0') {
     820:	e4d03001 	ldrb	r3, [r0], #1
     824:	e3530000 	cmp	r3, #0
     828:	1afffffc 	bne	820 <putstr>
			putc('\r');
		putc(c);
	}

	flush();
}
     82c:	e12fff1e 	bx	lr

00000830 <error>:
#ifndef arch_error
#define arch_error(x)
#endif

void error(char *x)
{
     830:	e92d4010 	push	{r4, lr}
     834:	e1a04000 	mov	r4, r0
	arch_error(x);

	putstr("\n\n");
     838:	e59f001c 	ldr	r0, [pc, #28]	; 85c <error+0x2c>
     83c:	e08f0000 	add	r0, pc, r0
     840:	ebfffff6 	bl	820 <putstr>
	putstr(x);
     844:	e1a00004 	mov	r0, r4
     848:	ebfffff4 	bl	820 <putstr>
	putstr("\n\n -- System halted");
     84c:	e59f000c 	ldr	r0, [pc, #12]	; 860 <error+0x30>
     850:	e08f0000 	add	r0, pc, r0
     854:	ebfffff1 	bl	820 <putstr>
     858:	eafffffe 	b	858 <error+0x28>
     85c:	000032da 	.word	0x000032da
     860:	000032c9 	.word	0x000032c9

00000864 <__div0>:
	while(1);	/* Halt */
}

asmlinkage void __div0(void)
{
	error("Attempting division by 0!");
     864:	e59f0004 	ldr	r0, [pc, #4]	; 870 <__div0+0xc>
     868:	e08f0000 	add	r0, pc, r0
     86c:	eaffffef 	b	830 <error>
     870:	000032c5 	.word	0x000032c5

00000874 <decompress_kernel>:

void
decompress_kernel(unsigned long output_start, unsigned long free_mem_ptr_p,
		unsigned long free_mem_ptr_end_p,
		int arch_id)
{
     874:	e92d4038 	push	{r3, r4, r5, lr}
     878:	e1a05000 	mov	r5, r0
     87c:	e59f4088 	ldr	r4, [pc, #136]	; 90c <decompress_kernel+0x98>
	int ret;

	output_data		= (unsigned char *)output_start;
     880:	e59f0088 	ldr	r0, [pc, #136]	; 910 <decompress_kernel+0x9c>

void
decompress_kernel(unsigned long output_start, unsigned long free_mem_ptr_p,
		unsigned long free_mem_ptr_end_p,
		int arch_id)
{
     884:	e08f4004 	add	r4, pc, r4
	int ret;

	output_data		= (unsigned char *)output_start;
     888:	e7940000 	ldr	r0, [r4, r0]
     88c:	e5805000 	str	r5, [r0]
	free_mem_ptr		= free_mem_ptr_p;
     890:	e59f007c 	ldr	r0, [pc, #124]	; 914 <decompress_kernel+0xa0>
     894:	e7940000 	ldr	r0, [r4, r0]
     898:	e5801000 	str	r1, [r0]
	free_mem_end_ptr	= free_mem_ptr_end_p;
     89c:	e59f1074 	ldr	r1, [pc, #116]	; 918 <decompress_kernel+0xa4>
	__machine_arch_type	= arch_id;

	arch_decomp_setup();

	putstr("Uncompressing Linux...");
     8a0:	e59f0074 	ldr	r0, [pc, #116]	; 91c <decompress_kernel+0xa8>
{
	int ret;

	output_data		= (unsigned char *)output_start;
	free_mem_ptr		= free_mem_ptr_p;
	free_mem_end_ptr	= free_mem_ptr_end_p;
     8a4:	e7941001 	ldr	r1, [r4, r1]
	__machine_arch_type	= arch_id;

	arch_decomp_setup();

	putstr("Uncompressing Linux...");
     8a8:	e08f0000 	add	r0, pc, r0
{
	int ret;

	output_data		= (unsigned char *)output_start;
	free_mem_ptr		= free_mem_ptr_p;
	free_mem_end_ptr	= free_mem_ptr_end_p;
     8ac:	e5812000 	str	r2, [r1]
	__machine_arch_type	= arch_id;
     8b0:	e59f2068 	ldr	r2, [pc, #104]	; 920 <decompress_kernel+0xac>
     8b4:	e7942002 	ldr	r2, [r4, r2]
     8b8:	e5823000 	str	r3, [r2]

	arch_decomp_setup();

	putstr("Uncompressing Linux...");
     8bc:	ebffffd7 	bl	820 <putstr>
	ret = do_decompress(input_data, input_data_end - input_data,
     8c0:	e59f305c 	ldr	r3, [pc, #92]	; 924 <decompress_kernel+0xb0>
     8c4:	e1a02005 	mov	r2, r5
     8c8:	e7940003 	ldr	r0, [r4, r3]
     8cc:	e59f3054 	ldr	r3, [pc, #84]	; 928 <decompress_kernel+0xb4>
     8d0:	e7941003 	ldr	r1, [r4, r3]
     8d4:	e59f3050 	ldr	r3, [pc, #80]	; 92c <decompress_kernel+0xb8>
     8d8:	e0601001 	rsb	r1, r0, r1
     8dc:	e7943003 	ldr	r3, [r4, r3]
     8e0:	eb000850 	bl	2a28 <do_decompress>
			    output_data, error);
	if (ret)
     8e4:	e3500000 	cmp	r0, #0
     8e8:	0a000003 	beq	8fc <decompress_kernel+0x88>
		error("decompressor returned an error");
     8ec:	e59f003c 	ldr	r0, [pc, #60]	; 930 <decompress_kernel+0xbc>
	else
		putstr(" done, booting the kernel.\n");
}
     8f0:	e8bd4038 	pop	{r3, r4, r5, lr}

	putstr("Uncompressing Linux...");
	ret = do_decompress(input_data, input_data_end - input_data,
			    output_data, error);
	if (ret)
		error("decompressor returned an error");
     8f4:	e08f0000 	add	r0, pc, r0
     8f8:	eaffffcc 	b	830 <error>
	else
		putstr(" done, booting the kernel.\n");
     8fc:	e59f0030 	ldr	r0, [pc, #48]	; 934 <decompress_kernel+0xc0>
}
     900:	e8bd4038 	pop	{r3, r4, r5, lr}
	ret = do_decompress(input_data, input_data_end - input_data,
			    output_data, error);
	if (ret)
		error("decompressor returned an error");
	else
		putstr(" done, booting the kernel.\n");
     904:	e08f0000 	add	r0, pc, r0
     908:	eaffffc4 	b	820 <putstr>
     90c:	0068e5ec 	.word	0x0068e5ec
     910:	00000018 	.word	0x00000018
     914:	00000020 	.word	0x00000020
     918:	00000010 	.word	0x00000010
     91c:	0000329f 	.word	0x0000329f
     920:	0000001c 	.word	0x0000001c
     924:	00000008 	.word	0x00000008
     928:	00000000 	.word	0x00000000
     92c:	00000014 	.word	0x00000014
     930:	0000326a 	.word	0x0000326a
     934:	00003279 	.word	0x00003279

00000938 <malloc>:
 */
STATIC_RW_DATA unsigned long malloc_ptr;
STATIC_RW_DATA int malloc_count;

static void *malloc(int size)
{
     938:	e59f3078 	ldr	r3, [pc, #120]	; 9b8 <malloc+0x80>
	void *p;

	if (size < 0)
     93c:	e2501000 	subs	r1, r0, #0
 */
STATIC_RW_DATA unsigned long malloc_ptr;
STATIC_RW_DATA int malloc_count;

static void *malloc(int size)
{
     940:	e08f3003 	add	r3, pc, r3
	void *p;

	if (size < 0)
     944:	aa000001 	bge	950 <malloc+0x18>
		return NULL;
     948:	e3a00000 	mov	r0, #0
     94c:	e12fff1e 	bx	lr
	if (!malloc_ptr)
     950:	e59f2064 	ldr	r2, [pc, #100]	; 9bc <malloc+0x84>
     954:	e7932002 	ldr	r2, [r3, r2]
     958:	e5920000 	ldr	r0, [r2]
     95c:	e3500000 	cmp	r0, #0
		malloc_ptr = free_mem_ptr;
     960:	059f0058 	ldreq	r0, [pc, #88]	; 9c0 <malloc+0x88>
     964:	07930000 	ldreq	r0, [r3, r0]
     968:	05900000 	ldreq	r0, [r0]
     96c:	05820000 	streq	r0, [r2]

	malloc_ptr = (malloc_ptr + 3) & ~3;     /* Align */
     970:	e5920000 	ldr	r0, [r2]
     974:	e2800003 	add	r0, r0, #3
     978:	e3c00003 	bic	r0, r0, #3

	p = (void *)malloc_ptr;
	malloc_ptr += size;
     97c:	e0811000 	add	r1, r1, r0
     980:	e5821000 	str	r1, [r2]

	if (free_mem_end_ptr && malloc_ptr >= free_mem_end_ptr)
     984:	e59f2038 	ldr	r2, [pc, #56]	; 9c4 <malloc+0x8c>
     988:	e7932002 	ldr	r2, [r3, r2]
     98c:	e5922000 	ldr	r2, [r2]
     990:	e3520000 	cmp	r2, #0
     994:	0a000001 	beq	9a0 <malloc+0x68>
     998:	e1510002 	cmp	r1, r2
     99c:	2affffe9 	bcs	948 <malloc+0x10>
		return NULL;

	malloc_count++;
     9a0:	e59f2020 	ldr	r2, [pc, #32]	; 9c8 <malloc+0x90>
     9a4:	e7933002 	ldr	r3, [r3, r2]
     9a8:	e5932000 	ldr	r2, [r3]
     9ac:	e2822001 	add	r2, r2, #1
     9b0:	e5832000 	str	r2, [r3]
	return p;
}
     9b4:	e12fff1e 	bx	lr
     9b8:	0068e530 	.word	0x0068e530
     9bc:	00000004 	.word	0x00000004
     9c0:	00000020 	.word	0x00000020
     9c4:	00000010 	.word	0x00000010
     9c8:	0000000c 	.word	0x0000000c

000009cc <nofill>:
#define GZIP_IOBUF_SIZE (16*1024)

static int INIT nofill(void *buffer, unsigned int len)
{
	return -1;
}
     9cc:	e3e00000 	mvn	r0, #0
     9d0:	e12fff1e 	bx	lr

000009d4 <zlib_updatewindow>:
   upon return from inflate(), and since all distances after the first 32K of
   output will fall in the output data, making match copies simpler and faster.
   The advantage may be dependent on the size of the processor's data caches.
 */
static void zlib_updatewindow(z_streamp strm, unsigned out)
{
     9d4:	e92d40f8 	push	{r3, r4, r5, r6, r7, lr}
     9d8:	e1a07000 	mov	r7, r0
    struct inflate_state *state;
    unsigned copy, dist;

    state = (struct inflate_state *)strm->state;
     9dc:	e590401c 	ldr	r4, [r0, #28]

    /* copy state->wsize or less output bytes into the circular window */
    copy = out - strm->avail_out;
     9e0:	e5906010 	ldr	r6, [r0, #16]
    if (copy >= state->wsize) {
     9e4:	e5942024 	ldr	r2, [r4, #36]	; 0x24
    unsigned copy, dist;

    state = (struct inflate_state *)strm->state;

    /* copy state->wsize or less output bytes into the circular window */
    copy = out - strm->avail_out;
     9e8:	e0666001 	rsb	r6, r6, r1
     9ec:	e590100c 	ldr	r1, [r0, #12]
    if (copy >= state->wsize) {
     9f0:	e1560002 	cmp	r6, r2
     9f4:	3a000005 	bcc	a10 <zlib_updatewindow+0x3c>
        memcpy(state->window, strm->next_out - state->wsize, state->wsize);
     9f8:	e5940030 	ldr	r0, [r4, #48]	; 0x30
     9fc:	e0621001 	rsb	r1, r2, r1
     a00:	eb000891 	bl	2c4c <memcpy>
        state->write = 0;
     a04:	e3a03000 	mov	r3, #0
     a08:	e584302c 	str	r3, [r4, #44]	; 0x2c
     a0c:	ea000010 	b	a54 <zlib_updatewindow+0x80>
        state->whave = state->wsize;
    }
    else {
        dist = state->wsize - state->write;
     a10:	e594302c 	ldr	r3, [r4, #44]	; 0x2c
        if (dist > copy) dist = copy;
        memcpy(state->window + state->write, strm->next_out - copy, dist);
     a14:	e0661001 	rsb	r1, r6, r1
     a18:	e5940030 	ldr	r0, [r4, #48]	; 0x30
        memcpy(state->window, strm->next_out - state->wsize, state->wsize);
        state->write = 0;
        state->whave = state->wsize;
    }
    else {
        dist = state->wsize - state->write;
     a1c:	e0635002 	rsb	r5, r3, r2
     a20:	e1560005 	cmp	r6, r5
     a24:	31a05006 	movcc	r5, r6
        if (dist > copy) dist = copy;
        memcpy(state->window + state->write, strm->next_out - copy, dist);
     a28:	e0800003 	add	r0, r0, r3
     a2c:	e1a02005 	mov	r2, r5
     a30:	eb000885 	bl	2c4c <memcpy>
        copy -= dist;
        if (copy) {
     a34:	e0566005 	subs	r6, r6, r5
     a38:	0a000008 	beq	a60 <zlib_updatewindow+0x8c>
            memcpy(state->window, strm->next_out - copy, copy);
     a3c:	e597100c 	ldr	r1, [r7, #12]
     a40:	e1a02006 	mov	r2, r6
     a44:	e5940030 	ldr	r0, [r4, #48]	; 0x30
     a48:	e0661001 	rsb	r1, r6, r1
     a4c:	eb00087e 	bl	2c4c <memcpy>
            state->write = copy;
     a50:	e584602c 	str	r6, [r4, #44]	; 0x2c
            state->whave = state->wsize;
     a54:	e5943024 	ldr	r3, [r4, #36]	; 0x24
     a58:	e5843028 	str	r3, [r4, #40]	; 0x28
     a5c:	e8bd80f8 	pop	{r3, r4, r5, r6, r7, pc}
        }
        else {
            state->write += dist;
     a60:	e594302c 	ldr	r3, [r4, #44]	; 0x2c
            if (state->write == state->wsize) state->write = 0;
     a64:	e5942024 	ldr	r2, [r4, #36]	; 0x24
            memcpy(state->window, strm->next_out - copy, copy);
            state->write = copy;
            state->whave = state->wsize;
        }
        else {
            state->write += dist;
     a68:	e0853003 	add	r3, r5, r3
            if (state->write == state->wsize) state->write = 0;
     a6c:	e1530002 	cmp	r3, r2
            memcpy(state->window, strm->next_out - copy, copy);
            state->write = copy;
            state->whave = state->wsize;
        }
        else {
            state->write += dist;
     a70:	e584302c 	str	r3, [r4, #44]	; 0x2c
            if (state->write == state->wsize) state->write = 0;
            if (state->whave < state->wsize) state->whave += dist;
     a74:	e5943028 	ldr	r3, [r4, #40]	; 0x28
            state->write = copy;
            state->whave = state->wsize;
        }
        else {
            state->write += dist;
            if (state->write == state->wsize) state->write = 0;
     a78:	0584602c 	streq	r6, [r4, #44]	; 0x2c
            if (state->whave < state->wsize) state->whave += dist;
     a7c:	e1530002 	cmp	r3, r2
     a80:	30855003 	addcc	r5, r5, r3
     a84:	35845028 	strcc	r5, [r4, #40]	; 0x28
     a88:	e8bd80f8 	pop	{r3, r4, r5, r6, r7, pc}

00000a8c <free.isra.0>:

static void free(void *where)
     a8c:	e59f3038 	ldr	r3, [pc, #56]	; acc <free.isra.0+0x40>
{
	malloc_count--;
     a90:	e59f2038 	ldr	r2, [pc, #56]	; ad0 <free.isra.0+0x44>

	malloc_count++;
	return p;
}

static void free(void *where)
     a94:	e08f3003 	add	r3, pc, r3
{
	malloc_count--;
     a98:	e7931002 	ldr	r1, [r3, r2]
     a9c:	e5912000 	ldr	r2, [r1]
     aa0:	e2422001 	sub	r2, r2, #1
	if (!malloc_count)
     aa4:	e3520000 	cmp	r2, #0
	return p;
}

static void free(void *where)
{
	malloc_count--;
     aa8:	e5812000 	str	r2, [r1]
	if (!malloc_count)
     aac:	112fff1e 	bxne	lr
		malloc_ptr = free_mem_ptr;
     ab0:	e59f201c 	ldr	r2, [pc, #28]	; ad4 <free.isra.0+0x48>
     ab4:	e59f101c 	ldr	r1, [pc, #28]	; ad8 <free.isra.0+0x4c>
     ab8:	e7932002 	ldr	r2, [r3, r2]
     abc:	e7933001 	ldr	r3, [r3, r1]
     ac0:	e5933000 	ldr	r3, [r3]
     ac4:	e5823000 	str	r3, [r2]
     ac8:	e12fff1e 	bx	lr
     acc:	0068e3dc 	.word	0x0068e3dc
     ad0:	0000000c 	.word	0x0000000c
     ad4:	00000004 	.word	0x00000004
     ad8:	00000020 	.word	0x00000020

00000adc <zlib_inflate_table>:
   table index bits.  It will differ if the request is greater than the
   longest code or if it is less than the shortest code.
 */
int zlib_inflate_table(codetype type, unsigned short *lens, unsigned codes,
			code **table, unsigned *bits, unsigned short *work)
{
     adc:	e92d4ff0 	push	{r4, r5, r6, r7, r8, r9, sl, fp, lr}
     ae0:	e24dd08c 	sub	sp, sp, #140	; 0x8c
       decoding tables.
     */

    /* accumulate lengths for codes (assumes lens[] all in 0..MAXBITS) */
    for (len = 0; len <= MAXBITS; len++)
        count[len] = 0;
     ae4:	e28d4048 	add	r4, sp, #72	; 0x48
   table index bits.  It will differ if the request is greater than the
   longest code or if it is less than the shortest code.
 */
int zlib_inflate_table(codetype type, unsigned short *lens, unsigned codes,
			code **table, unsigned *bits, unsigned short *work)
{
     ae8:	e59dc0b4 	ldr	ip, [sp, #180]	; 0xb4
     aec:	e58d1034 	str	r1, [sp, #52]	; 0x34
     af0:	e3a01000 	mov	r1, #0
       decoding tables.
     */

    /* accumulate lengths for codes (assumes lens[] all in 0..MAXBITS) */
    for (len = 0; len <= MAXBITS; len++)
        count[len] = 0;
     af4:	e58d4008 	str	r4, [sp, #8]
     af8:	e1a04001 	mov	r4, r1
     afc:	e2816048 	add	r6, r1, #72	; 0x48
     b00:	e2811002 	add	r1, r1, #2
     b04:	e1a0500d 	mov	r5, sp
       at length counts to determine sub-table sizes when building the
       decoding tables.
     */

    /* accumulate lengths for codes (assumes lens[] all in 0..MAXBITS) */
    for (len = 0; len <= MAXBITS; len++)
     b08:	e3510020 	cmp	r1, #32
        count[len] = 0;
     b0c:	e18640b5 	strh	r4, [r6, r5]
       at length counts to determine sub-table sizes when building the
       decoding tables.
     */

    /* accumulate lengths for codes (assumes lens[] all in 0..MAXBITS) */
    for (len = 0; len <= MAXBITS; len++)
     b10:	1afffff9 	bne	afc <zlib_inflate_table+0x20>
     b14:	e3a01000 	mov	r1, #0
        count[len] = 0;
    for (sym = 0; sym < codes; sym++)
     b18:	e1510002 	cmp	r1, r2
     b1c:	0a000009 	beq	b48 <zlib_inflate_table+0x6c>
        count[lens[sym]]++;
     b20:	e59d7034 	ldr	r7, [sp, #52]	; 0x34
     b24:	e1a04081 	lsl	r4, r1, #1
     b28:	e28d8088 	add	r8, sp, #136	; 0x88
     */

    /* accumulate lengths for codes (assumes lens[] all in 0..MAXBITS) */
    for (len = 0; len <= MAXBITS; len++)
        count[len] = 0;
    for (sym = 0; sym < codes; sym++)
     b2c:	e2811001 	add	r1, r1, #1
        count[lens[sym]]++;
     b30:	e19740b4 	ldrh	r4, [r7, r4]
     b34:	e0884084 	add	r4, r8, r4, lsl #1
     b38:	e15454b0 	ldrh	r5, [r4, #-64]	; 0xffffffc0
     b3c:	e2855001 	add	r5, r5, #1
     b40:	e14454b0 	strh	r5, [r4, #-64]	; 0xffffffc0
     b44:	eafffff3 	b	b18 <zlib_inflate_table+0x3c>

    /* bound code lengths, force root to be within code lengths */
    root = *bits;
     b48:	e59da0b0 	ldr	sl, [sp, #176]	; 0xb0
    for (max = MAXBITS; max >= 1; max--)
     b4c:	e3a0800f 	mov	r8, #15
        count[len] = 0;
    for (sym = 0; sym < codes; sym++)
        count[lens[sym]]++;

    /* bound code lengths, force root to be within code lengths */
    root = *bits;
     b50:	e59a4000 	ldr	r4, [sl]
     b54:	e1a01088 	lsl	r1, r8, #1
    for (max = MAXBITS; max >= 1; max--)
        if (count[max] != 0) break;
     b58:	e28d5048 	add	r5, sp, #72	; 0x48
     b5c:	e19510b1 	ldrh	r1, [r5, r1]
     b60:	e3510000 	cmp	r1, #0
     b64:	0a000003 	beq	b78 <zlib_inflate_table+0x9c>
    if (root > max) root = max;
    if (max == 0) {                     /* no symbols to code at all */
     b68:	e3580000 	cmp	r8, #0
     b6c:	13a01001 	movne	r1, #1
     b70:	1a000014 	bne	bc8 <zlib_inflate_table+0xec>
     b74:	ea000001 	b	b80 <zlib_inflate_table+0xa4>
    for (sym = 0; sym < codes; sym++)
        count[lens[sym]]++;

    /* bound code lengths, force root to be within code lengths */
    root = *bits;
    for (max = MAXBITS; max >= 1; max--)
     b78:	e2588001 	subs	r8, r8, #1
     b7c:	1afffff4 	bne	b54 <zlib_inflate_table+0x78>
    if (root > max) root = max;
    if (max == 0) {                     /* no symbols to code at all */
        this.op = (unsigned char)64;    /* invalid code marker */
        this.bits = (unsigned char)1;
        this.val = (unsigned short)0;
        *(*table)++ = this;             /* make a table to force an error */
     b80:	e5932000 	ldr	r2, [r3]
     b84:	e3a0c040 	mov	ip, #64	; 0x40
     b88:	e3a00000 	mov	r0, #0
        *(*table)++ = this;
        *bits = 1;
     b8c:	e59d60b0 	ldr	r6, [sp, #176]	; 0xb0
    if (root > max) root = max;
    if (max == 0) {                     /* no symbols to code at all */
        this.op = (unsigned char)64;    /* invalid code marker */
        this.bits = (unsigned char)1;
        this.val = (unsigned short)0;
        *(*table)++ = this;             /* make a table to force an error */
     b90:	e2821004 	add	r1, r2, #4
     b94:	e5831000 	str	r1, [r3]
     b98:	e3a01001 	mov	r1, #1
     b9c:	e5c2c000 	strb	ip, [r2]
     ba0:	e5c21001 	strb	r1, [r2, #1]
     ba4:	e1c200b2 	strh	r0, [r2, #2]
        *(*table)++ = this;
     ba8:	e5932000 	ldr	r2, [r3]
     bac:	e2824004 	add	r4, r2, #4
     bb0:	e5834000 	str	r4, [r3]
     bb4:	e5c2c000 	strb	ip, [r2]
     bb8:	e5c21001 	strb	r1, [r2, #1]
     bbc:	e1c200b2 	strh	r0, [r2, #2]
        *bits = 1;
     bc0:	e5861000 	str	r1, [r6]
        return 0;     /* no symbols, but wait for decoding to report error */
     bc4:	ea00011f 	b	1048 <zlib_inflate_table+0x56c>
     bc8:	e1a05081 	lsl	r5, r1, #1
    }
    for (min = 1; min <= MAXBITS; min++)
        if (count[min] != 0) break;
     bcc:	e28d7048 	add	r7, sp, #72	; 0x48
     bd0:	e19750b5 	ldrh	r5, [r7, r5]
     bd4:	e3550000 	cmp	r5, #0
     bd8:	1a000004 	bne	bf0 <zlib_inflate_table+0x114>
        *(*table)++ = this;             /* make a table to force an error */
        *(*table)++ = this;
        *bits = 1;
        return 0;     /* no symbols, but wait for decoding to report error */
    }
    for (min = 1; min <= MAXBITS; min++)
     bdc:	e2811001 	add	r1, r1, #1
     be0:	e3510010 	cmp	r1, #16
     be4:	1afffff7 	bne	bc8 <zlib_inflate_table+0xec>
     be8:	e1a09001 	mov	r9, r1
     bec:	ea000004 	b	c04 <zlib_inflate_table+0x128>
     bf0:	e1580004 	cmp	r8, r4
     bf4:	31a04008 	movcc	r4, r8
     bf8:	e1a09001 	mov	r9, r1
     bfc:	e1510004 	cmp	r1, r4
     c00:	31a01004 	movcc	r1, r4
        if (count[min] != 0) break;
    if (root < min) root = min;

    /* check for an over-subscribed or incomplete set of lengths */
    left = 1;
     c04:	e3a04001 	mov	r4, #1
    for (len = 1; len <= MAXBITS; len++) {
     c08:	e1a05004 	mov	r5, r4
     c0c:	e1a06085 	lsl	r6, r5, #1
        left <<= 1;
        left -= count[len];
     c10:	e28da048 	add	sl, sp, #72	; 0x48
    if (root < min) root = min;

    /* check for an over-subscribed or incomplete set of lengths */
    left = 1;
    for (len = 1; len <= MAXBITS; len++) {
        left <<= 1;
     c14:	e1a04084 	lsl	r4, r4, #1
        left -= count[len];
     c18:	e19a60b6 	ldrh	r6, [sl, r6]
        if (left < 0) return -1;        /* over-subscribed */
     c1c:	e0544006 	subs	r4, r4, r6
     c20:	4a000107 	bmi	1044 <zlib_inflate_table+0x568>
        if (count[min] != 0) break;
    if (root < min) root = min;

    /* check for an over-subscribed or incomplete set of lengths */
    left = 1;
    for (len = 1; len <= MAXBITS; len++) {
     c24:	e2855001 	add	r5, r5, #1
     c28:	e3550010 	cmp	r5, #16
     c2c:	1afffff6 	bne	c0c <zlib_inflate_table+0x130>
        left <<= 1;
        left -= count[len];
        if (left < 0) return -1;        /* over-subscribed */
    }
    if (left > 0 && (type == CODES || max != 1))
     c30:	e3540000 	cmp	r4, #0
     c34:	0a000005 	beq	c50 <zlib_inflate_table+0x174>
     c38:	e2704001 	rsbs	r4, r0, #1
     c3c:	33a04000 	movcc	r4, #0
     c40:	e3580001 	cmp	r8, #1
     c44:	13844001 	orrne	r4, r4, #1
     c48:	e3540000 	cmp	r4, #0
     c4c:	1a0000fc 	bne	1044 <zlib_inflate_table+0x568>
        return -1;                      /* incomplete set */

    /* generate offsets into symbol table for each length for sorting */
    offs[1] = 0;
     c50:	e3a04000 	mov	r4, #0
     c54:	e28d5068 	add	r5, sp, #104	; 0x68
     c58:	e1cd46ba 	strh	r4, [sp, #106]	; 0x6a
     c5c:	e2844002 	add	r4, r4, #2
    for (len = 1; len < MAXBITS; len++)
        offs[len + 1] = offs[len] + count[len];
     c60:	e28da048 	add	sl, sp, #72	; 0x48
     c64:	e1d570b2 	ldrh	r7, [r5, #2]
     c68:	e19a60b4 	ldrh	r6, [sl, r4]
    if (left > 0 && (type == CODES || max != 1))
        return -1;                      /* incomplete set */

    /* generate offsets into symbol table for each length for sorting */
    offs[1] = 0;
    for (len = 1; len < MAXBITS; len++)
     c6c:	e354001c 	cmp	r4, #28
     c70:	e2855002 	add	r5, r5, #2
        offs[len + 1] = offs[len] + count[len];
     c74:	e0876006 	add	r6, r7, r6
     c78:	e1c560b2 	strh	r6, [r5, #2]
    if (left > 0 && (type == CODES || max != 1))
        return -1;                      /* incomplete set */

    /* generate offsets into symbol table for each length for sorting */
    offs[1] = 0;
    for (len = 1; len < MAXBITS; len++)
     c7c:	1afffff6 	bne	c5c <zlib_inflate_table+0x180>
     c80:	e3a04000 	mov	r4, #0
        offs[len + 1] = offs[len] + count[len];

    /* sort symbols by length, by symbol order within each length */
    for (sym = 0; sym < codes; sym++)
     c84:	e1540002 	cmp	r4, r2
     c88:	0a00000d 	beq	cc4 <zlib_inflate_table+0x1e8>
        if (lens[sym] != 0) work[offs[lens[sym]]++] = (unsigned short)sym;
     c8c:	e59d7034 	ldr	r7, [sp, #52]	; 0x34
     c90:	e1a05084 	lsl	r5, r4, #1
     c94:	e19760b5 	ldrh	r6, [r7, r5]
     c98:	e3560000 	cmp	r6, #0
     c9c:	0a000006 	beq	cbc <zlib_inflate_table+0x1e0>
     ca0:	e28da088 	add	sl, sp, #136	; 0x88
     ca4:	e08a6086 	add	r6, sl, r6, lsl #1
     ca8:	e15652b0 	ldrh	r5, [r6, #-32]	; 0xffffffe0
     cac:	e2857001 	add	r7, r5, #1
     cb0:	e1a05085 	lsl	r5, r5, #1
     cb4:	e14672b0 	strh	r7, [r6, #-32]	; 0xffffffe0
     cb8:	e18c40b5 	strh	r4, [ip, r5]
    offs[1] = 0;
    for (len = 1; len < MAXBITS; len++)
        offs[len + 1] = offs[len] + count[len];

    /* sort symbols by length, by symbol order within each length */
    for (sym = 0; sym < codes; sym++)
     cbc:	e2844001 	add	r4, r4, #1
     cc0:	eaffffef 	b	c84 <zlib_inflate_table+0x1a8>
       routine permits incomplete codes, so another loop after this one fills
       in the rest of the decoding tables with invalid code markers.
     */

    /* set up for code type */
    switch (type) {
     cc4:	e3500000 	cmp	r0, #0
     cc8:	0a000013 	beq	d1c <zlib_inflate_table+0x240>
     ccc:	e3500001 	cmp	r0, #1
     cd0:	1a000008 	bne	cf8 <zlib_inflate_table+0x21c>
    case LENS:
        base = lbase;
        base -= 257;
        extra = lext;
        extra -= 257;
        end = 256;
     cd4:	e3a02c01 	mov	r2, #256	; 0x100
     cd8:	e58d2020 	str	r2, [sp, #32]
        break;
    case LENS:
        base = lbase;
        base -= 257;
        extra = lext;
        extra -= 257;
     cdc:	e59f236c 	ldr	r2, [pc, #876]	; 1050 <zlib_inflate_table+0x574>
     ce0:	e08f2002 	add	r2, pc, r2
     ce4:	e2424c02 	sub	r4, r2, #512	; 0x200
        base = extra = work;    /* dummy value--not used */
        end = 19;
        break;
    case LENS:
        base = lbase;
        base -= 257;
     ce8:	e2422f71 	sub	r2, r2, #452	; 0x1c4
        extra = lext;
        extra -= 257;
     cec:	e2444002 	sub	r4, r4, #2
     cf0:	e58d4010 	str	r4, [sp, #16]
     cf4:	ea000006 	b	d14 <zlib_inflate_table+0x238>
        end = 256;
        break;
    default:            /* DISTS */
        base = dbase;
        extra = dext;
     cf8:	e59f2354 	ldr	r2, [pc, #852]	; 1054 <zlib_inflate_table+0x578>
        end = -1;
     cfc:	e3e05000 	mvn	r5, #0
     d00:	e58d5020 	str	r5, [sp, #32]
        extra -= 257;
        end = 256;
        break;
    default:            /* DISTS */
        base = dbase;
        extra = dext;
     d04:	e08f2002 	add	r2, pc, r2
     d08:	e282607c 	add	r6, r2, #124	; 0x7c
        extra = lext;
        extra -= 257;
        end = 256;
        break;
    default:            /* DISTS */
        base = dbase;
     d0c:	e28220bc 	add	r2, r2, #188	; 0xbc
        extra = dext;
     d10:	e58d6010 	str	r6, [sp, #16]
        extra = lext;
        extra -= 257;
        end = 256;
        break;
    default:            /* DISTS */
        base = dbase;
     d14:	e58d201c 	str	r2, [sp, #28]
     d18:	ea000003 	b	d2c <zlib_inflate_table+0x250>

    /* set up for code type */
    switch (type) {
    case CODES:
        base = extra = work;    /* dummy value--not used */
        end = 19;
     d1c:	e3a07013 	mov	r7, #19
     */

    /* set up for code type */
    switch (type) {
    case CODES:
        base = extra = work;    /* dummy value--not used */
     d20:	e58dc010 	str	ip, [sp, #16]
     d24:	e58dc01c 	str	ip, [sp, #28]
        end = 19;
     d28:	e58d7020 	str	r7, [sp, #32]
    len = min;                  /* starting code length */
    next = *table;              /* current table to fill in */
    curr = root;                /* current table index bits */
    drop = 0;                   /* current bits to drop from code for index */
    low = (unsigned)(-1);       /* trigger new sub-table when len > root */
    used = 1U << root;          /* use root table entries */
     d2c:	e3a04001 	mov	r4, #1

    /* initialize state for loop */
    huff = 0;                   /* starting code */
    sym = 0;                    /* starting code symbol */
    len = min;                  /* starting code length */
    next = *table;              /* current table to fill in */
     d30:	e593b000 	ldr	fp, [r3]
    low = (unsigned)(-1);       /* trigger new sub-table when len > root */
    used = 1U << root;          /* use root table entries */
    mask = used - 1;            /* mask for comparing low */

    /* check available table space */
    if (type == LENS && used >= ENOUGH - MAXD)
     d34:	e0502004 	subs	r2, r0, r4
    len = min;                  /* starting code length */
    next = *table;              /* current table to fill in */
    curr = root;                /* current table index bits */
    drop = 0;                   /* current bits to drop from code for index */
    low = (unsigned)(-1);       /* trigger new sub-table when len > root */
    used = 1U << root;          /* use root table entries */
     d38:	e1a0a114 	lsl	sl, r4, r1
    mask = used - 1;            /* mask for comparing low */

    /* check available table space */
    if (type == LENS && used >= ENOUGH - MAXD)
     d3c:	e2720000 	rsbs	r0, r2, #0
     d40:	e0b00002 	adcs	r0, r0, r2
     d44:	e58d003c 	str	r0, [sp, #60]	; 0x3c
     d48:	e30005af 	movw	r0, #1455	; 0x5af
     d4c:	e59d203c 	ldr	r2, [sp, #60]	; 0x3c
     d50:	e15a0000 	cmp	sl, r0
     d54:	93a02000 	movls	r2, #0
     d58:	82022001 	andhi	r2, r2, #1
     d5c:	e3520000 	cmp	r2, #0
     d60:	1a000008 	bne	d88 <zlib_inflate_table+0x2ac>
    next = *table;              /* current table to fill in */
    curr = root;                /* current table index bits */
    drop = 0;                   /* current bits to drop from code for index */
    low = (unsigned)(-1);       /* trigger new sub-table when len > root */
    used = 1U << root;          /* use root table entries */
    mask = used - 1;            /* mask for comparing low */
     d64:	e24a0001 	sub	r0, sl, #1
     d68:	e24cc002 	sub	ip, ip, #2
     d6c:	e3e05000 	mvn	r5, #0
     d70:	e58d0038 	str	r0, [sp, #56]	; 0x38
     d74:	e1a00002 	mov	r0, r2
     d78:	e58dc028 	str	ip, [sp, #40]	; 0x28
     d7c:	e1a0c001 	mov	ip, r1
     d80:	e58d5018 	str	r5, [sp, #24]
     d84:	ea000010 	b	dcc <zlib_inflate_table+0x2f0>

    /* check available table space */
    if (type == LENS && used >= ENOUGH - MAXD)
        return 1;
     d88:	e3a00001 	mov	r0, #1
     d8c:	ea0000ad 	b	1048 <zlib_inflate_table+0x56c>

        /* backwards increment the len-bit code huff */
        incr = 1U << (len - 1);
        while (huff & incr)
            incr >>= 1;
        if (incr != 0) {
     d90:	e3540000 	cmp	r4, #0
        else
            huff = 0;

        /* go to next symbol, update count, len */
        sym++;
        if (--(count[len]) == 0) {
     d94:	e28d7088 	add	r7, sp, #136	; 0x88
        /* backwards increment the len-bit code huff */
        incr = 1U << (len - 1);
        while (huff & incr)
            incr >>= 1;
        if (incr != 0) {
            huff &= incr - 1;
     d98:	12445001 	subne	r5, r4, #1
            huff += incr;
        }
        else
            huff = 0;
     d9c:	01a02004 	moveq	r2, r4
        /* backwards increment the len-bit code huff */
        incr = 1U << (len - 1);
        while (huff & incr)
            incr >>= 1;
        if (incr != 0) {
            huff &= incr - 1;
     da0:	10052002 	andne	r2, r5, r2
        else
            huff = 0;

        /* go to next symbol, update count, len */
        sym++;
        if (--(count[len]) == 0) {
     da4:	e0875089 	add	r5, r7, r9, lsl #1
        incr = 1U << (len - 1);
        while (huff & incr)
            incr >>= 1;
        if (incr != 0) {
            huff &= incr - 1;
            huff += incr;
     da8:	10822004 	addne	r2, r2, r4
        else
            huff = 0;

        /* go to next symbol, update count, len */
        sym++;
        if (--(count[len]) == 0) {
     dac:	e15544b0 	ldrh	r4, [r5, #-64]	; 0xffffffc0
     db0:	e2444001 	sub	r4, r4, #1
     db4:	e6ff4074 	uxth	r4, r4
     db8:	e3540000 	cmp	r4, #0
     dbc:	e14544b0 	strh	r4, [r5, #-64]	; 0xffffffc0
     dc0:	0a00003f 	beq	ec4 <zlib_inflate_table+0x3e8>
            if (len == max) break;
            len = lens[work[sym]];
        }

        /* create new sub-table if needed */
        if (len > root && (huff & mask) != low) {
     dc4:	e1590001 	cmp	r9, r1
     dc8:	8a000048 	bhi	ef0 <zlib_inflate_table+0x414>

    /* process all codes and make table entries */
    for (;;) {
        /* create table entry */
        this.bits = (unsigned char)(len - drop);
        if ((int)(work[sym]) < end) {
     dcc:	e59d6028 	ldr	r6, [sp, #40]	; 0x28
        return 1;

    /* process all codes and make table entries */
    for (;;) {
        /* create table entry */
        this.bits = (unsigned char)(len - drop);
     dd0:	e0604009 	rsb	r4, r0, r9
     dd4:	e6ef4074 	uxtb	r4, r4
        if ((int)(work[sym]) < end) {
     dd8:	e59d7020 	ldr	r7, [sp, #32]
        return 1;

    /* process all codes and make table entries */
    for (;;) {
        /* create table entry */
        this.bits = (unsigned char)(len - drop);
     ddc:	e58d402c 	str	r4, [sp, #44]	; 0x2c
        if ((int)(work[sym]) < end) {
     de0:	e1f640b2 	ldrh	r4, [r6, #2]!
     de4:	e1540007 	cmp	r4, r7
     de8:	e58d6028 	str	r6, [sp, #40]	; 0x28
            this.op = (unsigned char)0;
     dec:	b3a07000 	movlt	r7, #0
     df0:	b58d7030 	strlt	r7, [sp, #48]	; 0x30

    /* process all codes and make table entries */
    for (;;) {
        /* create table entry */
        this.bits = (unsigned char)(len - drop);
        if ((int)(work[sym]) < end) {
     df4:	ba000008 	blt	e1c <zlib_inflate_table+0x340>
            this.op = (unsigned char)0;
            this.val = work[sym];
        }
        else if ((int)(work[sym]) > end) {
            this.op = (unsigned char)(extra[work[sym]]);
     df8:	c59d5010 	ldrgt	r5, [sp, #16]
     dfc:	c1a04084 	lslgt	r4, r4, #1
            this.val = base[work[sym]];
        }
        else {
            this.op = (unsigned char)(32 + 64);         /* end of block */
     e00:	d3a05060 	movle	r5, #96	; 0x60
            this.op = (unsigned char)0;
            this.val = work[sym];
        }
        else if ((int)(work[sym]) > end) {
            this.op = (unsigned char)(extra[work[sym]]);
            this.val = base[work[sym]];
     e04:	c59d601c 	ldrgt	r6, [sp, #28]
        }
        else {
            this.op = (unsigned char)(32 + 64);         /* end of block */
            this.val = 0;
     e08:	d3a04000 	movle	r4, #0
        else if ((int)(work[sym]) > end) {
            this.op = (unsigned char)(extra[work[sym]]);
            this.val = base[work[sym]];
        }
        else {
            this.op = (unsigned char)(32 + 64);         /* end of block */
     e0c:	d58d5030 	strle	r5, [sp, #48]	; 0x30
        if ((int)(work[sym]) < end) {
            this.op = (unsigned char)0;
            this.val = work[sym];
        }
        else if ((int)(work[sym]) > end) {
            this.op = (unsigned char)(extra[work[sym]]);
     e10:	c7d55004 	ldrbgt	r5, [r5, r4]
            this.val = base[work[sym]];
     e14:	c19640b4 	ldrhgt	r4, [r6, r4]
        if ((int)(work[sym]) < end) {
            this.op = (unsigned char)0;
            this.val = work[sym];
        }
        else if ((int)(work[sym]) > end) {
            this.op = (unsigned char)(extra[work[sym]]);
     e18:	c58d5030 	strgt	r5, [sp, #48]	; 0x30
            this.op = (unsigned char)(32 + 64);         /* end of block */
            this.val = 0;
        }

        /* replicate for those indices with low len bits equal to huff */
        incr = 1U << (len - drop);
     e1c:	e3a06001 	mov	r6, #1
     e20:	e0605009 	rsb	r5, r0, r9
     e24:	e1a05516 	lsl	r5, r6, r5
        fill = 1U << curr;
     e28:	e1a07c16 	lsl	r7, r6, ip
     e2c:	e3e06003 	mvn	r6, #3
            this.op = (unsigned char)(32 + 64);         /* end of block */
            this.val = 0;
        }

        /* replicate for those indices with low len bits equal to huff */
        incr = 1U << (len - drop);
     e30:	e58d500c 	str	r5, [sp, #12]
     e34:	e0050596 	mul	r5, r6, r5
        fill = 1U << curr;
     e38:	e58d7024 	str	r7, [sp, #36]	; 0x24
     e3c:	e0877032 	add	r7, r7, r2, lsr r0
     e40:	e3e06103 	mvn	r6, #-1073741824	; 0xc0000000
     e44:	e58d5044 	str	r5, [sp, #68]	; 0x44
     e48:	e59d500c 	ldr	r5, [sp, #12]
     e4c:	e0257596 	mla	r5, r6, r5, r7
        min = fill;                 /* save offset to next table */
        do {
            fill -= incr;
            next[(huff >> drop) + fill] = this;
     e50:	e3a06000 	mov	r6, #0
     e54:	e58d6004 	str	r6, [sp, #4]
     e58:	e08b7105 	add	r7, fp, r5, lsl #2
            this.val = 0;
        }

        /* replicate for those indices with low len bits equal to huff */
        incr = 1U << (len - drop);
        fill = 1U << curr;
     e5c:	e59d5024 	ldr	r5, [sp, #36]	; 0x24
     e60:	e58d7040 	str	r7, [sp, #64]	; 0x40
     e64:	e58d5014 	str	r5, [sp, #20]
        min = fill;                 /* save offset to next table */
        do {
            fill -= incr;
            next[(huff >> drop) + fill] = this;
     e68:	e59d6040 	ldr	r6, [sp, #64]	; 0x40
     e6c:	e59d7004 	ldr	r7, [sp, #4]
     e70:	e59d5030 	ldr	r5, [sp, #48]	; 0x30
     e74:	e7e65007 	strb	r5, [r6, r7]!
     e78:	e59d702c 	ldr	r7, [sp, #44]	; 0x2c
     e7c:	e59d5004 	ldr	r5, [sp, #4]
     e80:	e1c640b2 	strh	r4, [r6, #2]
     e84:	e5c67001 	strb	r7, [r6, #1]
     e88:	e59d6044 	ldr	r6, [sp, #68]	; 0x44
        } while (fill != 0);
     e8c:	e59d7014 	ldr	r7, [sp, #20]
     e90:	e0855006 	add	r5, r5, r6
     e94:	e58d5004 	str	r5, [sp, #4]
     e98:	e59d500c 	ldr	r5, [sp, #12]
     e9c:	e0577005 	subs	r7, r7, r5
     ea0:	e58d7014 	str	r7, [sp, #20]
     ea4:	1affffef 	bne	e68 <zlib_inflate_table+0x38c>

        /* backwards increment the len-bit code huff */
        incr = 1U << (len - 1);
     ea8:	e2494001 	sub	r4, r9, #1
     eac:	e3a06001 	mov	r6, #1
     eb0:	e1a04416 	lsl	r4, r6, r4
        while (huff & incr)
     eb4:	e1140002 	tst	r4, r2
     eb8:	0affffb4 	beq	d90 <zlib_inflate_table+0x2b4>
            incr >>= 1;
     ebc:	e1a040a4 	lsr	r4, r4, #1
     ec0:	eafffffb 	b	eb4 <zlib_inflate_table+0x3d8>
            huff = 0;

        /* go to next symbol, update count, len */
        sym++;
        if (--(count[len]) == 0) {
            if (len == max) break;
     ec4:	e1590008 	cmp	r9, r8
        /* when done with sub-table, drop back to root table */
        if (drop != 0 && (huff & mask) != low) {
            drop = 0;
            len = root;
            next = *table;
            this.bits = (unsigned char)len;
     ec8:	06ef5071 	uxtbeq	r5, r1
        }

        /* put invalid code marker in table */
        next[huff >> drop] = this;
     ecc:	03a06040 	moveq	r6, #64	; 0x40

        /* backwards increment the len-bit code huff */
        incr = 1U << (len - 1);
     ed0:	03a07001 	moveq	r7, #1
     ed4:	0a00003b 	beq	fc8 <zlib_inflate_table+0x4ec>

        /* go to next symbol, update count, len */
        sym++;
        if (--(count[len]) == 0) {
            if (len == max) break;
            len = lens[work[sym]];
     ed8:	e59d5028 	ldr	r5, [sp, #40]	; 0x28
     edc:	e59d6034 	ldr	r6, [sp, #52]	; 0x34
     ee0:	e1d540b2 	ldrh	r4, [r5, #2]
     ee4:	e1a04084 	lsl	r4, r4, #1
     ee8:	e19690b4 	ldrh	r9, [r6, r4]
     eec:	eaffffb4 	b	dc4 <zlib_inflate_table+0x2e8>
        }

        /* create new sub-table if needed */
        if (len > root && (huff & mask) != low) {
     ef0:	e59d7038 	ldr	r7, [sp, #56]	; 0x38
     ef4:	e59d5018 	ldr	r5, [sp, #24]
     ef8:	e0024007 	and	r4, r2, r7
     efc:	e1540005 	cmp	r4, r5
     f00:	0affffb1 	beq	dcc <zlib_inflate_table+0x2f0>
            /* if first time, transition to sub-tables */
            if (drop == 0)
                drop = root;

            /* increment past last table */
            next += min;            /* here min is 1 << curr */
     f04:	e59d6024 	ldr	r6, [sp, #36]	; 0x24
     f08:	e3500000 	cmp	r0, #0

            /* determine length of next table */
            curr = len - drop;
            left = (int)(1 << curr);
     f0c:	e3a07001 	mov	r7, #1
     f10:	01a00001 	moveq	r0, r1

            /* increment past last table */
            next += min;            /* here min is 1 << curr */

            /* determine length of next table */
            curr = len - drop;
     f14:	e060c009 	rsb	ip, r0, r9
            left = (int)(1 << curr);
     f18:	e1a05c17 	lsl	r5, r7, ip
            /* if first time, transition to sub-tables */
            if (drop == 0)
                drop = root;

            /* increment past last table */
            next += min;            /* here min is 1 << curr */
     f1c:	e08bb106 	add	fp, fp, r6, lsl #2
     f20:	e28d6048 	add	r6, sp, #72	; 0x48
     f24:	e0866080 	add	r6, r6, r0, lsl #1
     f28:	e58d600c 	str	r6, [sp, #12]
     f2c:	e08c6000 	add	r6, ip, r0

            /* determine length of next table */
            curr = len - drop;
            left = (int)(1 << curr);
            while (curr + drop < max) {
     f30:	e1560008 	cmp	r6, r8
     f34:	2a000005 	bcs	f50 <zlib_inflate_table+0x474>
                left -= count[curr + drop];
     f38:	e59d600c 	ldr	r6, [sp, #12]
     f3c:	e1a0708c 	lsl	r7, ip, #1
     f40:	e19660b7 	ldrh	r6, [r6, r7]
     f44:	e0665005 	rsb	r5, r6, r5
                if (left <= 0) break;
     f48:	e3550000 	cmp	r5, #0
     f4c:	ca000015 	bgt	fa8 <zlib_inflate_table+0x4cc>
                left <<= 1;
            }

            /* check for enough space */
            used += 1U << curr;
            if (type == LENS && used >= ENOUGH - MAXD)
     f50:	e59d503c 	ldr	r5, [sp, #60]	; 0x3c
                curr++;
                left <<= 1;
            }

            /* check for enough space */
            used += 1U << curr;
     f54:	e3a07001 	mov	r7, #1
            if (type == LENS && used >= ENOUGH - MAXD)
     f58:	e30065af 	movw	r6, #1455	; 0x5af
                curr++;
                left <<= 1;
            }

            /* check for enough space */
            used += 1U << curr;
     f5c:	e08aac17 	add	sl, sl, r7, lsl ip
            if (type == LENS && used >= ENOUGH - MAXD)
     f60:	e15a0006 	cmp	sl, r6
     f64:	93a05000 	movls	r5, #0
     f68:	82055001 	andhi	r5, r5, #1
     f6c:	e3550000 	cmp	r5, #0
     f70:	1affff84 	bne	d88 <zlib_inflate_table+0x2ac>
                return 1;

            /* point entry in root table to sub-table */
            low = huff & mask;
            (*table)[low].op = (unsigned char)curr;
     f74:	e5935000 	ldr	r5, [r3]
     f78:	e1a06104 	lsl	r6, r4, #2
            (*table)[low].bits = (unsigned char)root;
            (*table)[low].val = (unsigned short)(next - *table);
     f7c:	e58d4018 	str	r4, [sp, #24]
            if (type == LENS && used >= ENOUGH - MAXD)
                return 1;

            /* point entry in root table to sub-table */
            low = huff & mask;
            (*table)[low].op = (unsigned char)curr;
     f80:	e7c5c104 	strb	ip, [r5, r4, lsl #2]
            (*table)[low].bits = (unsigned char)root;
     f84:	e5935000 	ldr	r5, [r3]
     f88:	e0855006 	add	r5, r5, r6
     f8c:	e5c51001 	strb	r1, [r5, #1]
            (*table)[low].val = (unsigned short)(next - *table);
     f90:	e5935000 	ldr	r5, [r3]
     f94:	e0856006 	add	r6, r5, r6
     f98:	e065500b 	rsb	r5, r5, fp
     f9c:	e1a05145 	asr	r5, r5, #2
     fa0:	e1c650b2 	strh	r5, [r6, #2]
     fa4:	eaffff88 	b	dcc <zlib_inflate_table+0x2f0>
            curr = len - drop;
            left = (int)(1 << curr);
            while (curr + drop < max) {
                left -= count[curr + drop];
                if (left <= 0) break;
                curr++;
     fa8:	e28cc001 	add	ip, ip, #1
                left <<= 1;
     fac:	e1a05085 	lsl	r5, r5, #1
     fb0:	eaffffdd 	b	f2c <zlib_inflate_table+0x450>

        /* backwards increment the len-bit code huff */
        incr = 1U << (len - 1);
        while (huff & incr)
            incr >>= 1;
        if (incr != 0) {
     fb4:	e35c0000 	cmp	ip, #0
     fb8:	0a00001a 	beq	1028 <zlib_inflate_table+0x54c>
            huff &= incr - 1;
     fbc:	e24c8001 	sub	r8, ip, #1
     fc0:	e0082002 	and	r2, r8, r2
            huff += incr;
     fc4:	e082200c 	add	r2, r2, ip
       drops back to the root table to fill in any remaining entries there.
     */
    this.op = (unsigned char)64;                /* invalid code marker */
    this.bits = (unsigned char)(len - drop);
    this.val = (unsigned short)0;
    while (huff != 0) {
     fc8:	e3520000 	cmp	r2, #0
     fcc:	0a000015 	beq	1028 <zlib_inflate_table+0x54c>
        /* when done with sub-table, drop back to root table */
        if (drop != 0 && (huff & mask) != low) {
     fd0:	e3500000 	cmp	r0, #0
     fd4:	0a000007 	beq	ff8 <zlib_inflate_table+0x51c>
     fd8:	e59d8038 	ldr	r8, [sp, #56]	; 0x38
     fdc:	e002c008 	and	ip, r2, r8
     fe0:	e59d8018 	ldr	r8, [sp, #24]
     fe4:	e15c0008 	cmp	ip, r8
            drop = 0;
            len = root;
            next = *table;
     fe8:	1593b000 	ldrne	fp, [r3]
            this.bits = (unsigned char)len;
     fec:	11a09001 	movne	r9, r1
    this.bits = (unsigned char)(len - drop);
    this.val = (unsigned short)0;
    while (huff != 0) {
        /* when done with sub-table, drop back to root table */
        if (drop != 0 && (huff & mask) != low) {
            drop = 0;
     ff0:	13a00000 	movne	r0, #0
            len = root;
            next = *table;
            this.bits = (unsigned char)len;
     ff4:	158d502c 	strne	r5, [sp, #44]	; 0x2c
        }

        /* put invalid code marker in table */
        next[huff >> drop] = this;
     ff8:	e1a08032 	lsr	r8, r2, r0
     ffc:	e08bc108 	add	ip, fp, r8, lsl #2
    1000:	e7cb6108 	strb	r6, [fp, r8, lsl #2]
    1004:	e59d802c 	ldr	r8, [sp, #44]	; 0x2c
    1008:	e1cc40b2 	strh	r4, [ip, #2]
    100c:	e5cc8001 	strb	r8, [ip, #1]

        /* backwards increment the len-bit code huff */
        incr = 1U << (len - 1);
    1010:	e249c001 	sub	ip, r9, #1
    1014:	e1a0cc17 	lsl	ip, r7, ip
        while (huff & incr)
    1018:	e11c0002 	tst	ip, r2
    101c:	0affffe4 	beq	fb4 <zlib_inflate_table+0x4d8>
            incr >>= 1;
    1020:	e1a0c0ac 	lsr	ip, ip, #1
    1024:	eafffffb 	b	1018 <zlib_inflate_table+0x53c>
        else
            huff = 0;
    }

    /* set return parameters */
    *table += used;
    1028:	e5932000 	ldr	r2, [r3]
    *bits = root;
    return 0;
    102c:	e3a00000 	mov	r0, #0
        else
            huff = 0;
    }

    /* set return parameters */
    *table += used;
    1030:	e082210a 	add	r2, r2, sl, lsl #2
    *bits = root;
    1034:	e59da0b0 	ldr	sl, [sp, #176]	; 0xb0
        else
            huff = 0;
    }

    /* set return parameters */
    *table += used;
    1038:	e5832000 	str	r2, [r3]
    *bits = root;
    103c:	e58a1000 	str	r1, [sl]
    return 0;
    1040:	ea000000 	b	1048 <zlib_inflate_table+0x56c>
    /* check for an over-subscribed or incomplete set of lengths */
    left = 1;
    for (len = 1; len <= MAXBITS; len++) {
        left <<= 1;
        left -= count[len];
        if (left < 0) return -1;        /* over-subscribed */
    1044:	e3e00000 	mvn	r0, #0

    /* set return parameters */
    *table += used;
    *bits = root;
    return 0;
}
    1048:	e28dd08c 	add	sp, sp, #140	; 0x8c
    104c:	e8bd8ff0 	pop	{r4, r5, r6, r7, r8, r9, sl, fp, pc}
    1050:	00002494 	.word	0x00002494
    1054:	00002470 	.word	0x00002470

00001058 <inflate_fast>:
      output space.

    - @start:	inflate()'s starting value for strm->avail_out
 */
void inflate_fast(z_streamp strm, unsigned start)
{
    1058:	e92d4ff0 	push	{r4, r5, r6, r7, r8, r9, sl, fp, lr}
    105c:	e24dd04c 	sub	sp, sp, #76	; 0x4c
    unsigned len;               /* match length, unused bytes */
    unsigned dist;              /* match distance */
    unsigned char *from;        /* where to copy match from */

    /* copy state to local variables */
    state = (struct inflate_state *)strm->state;
    1060:	e590401c 	ldr	r4, [r0, #28]
      output space.

    - @start:	inflate()'s starting value for strm->avail_out
 */
void inflate_fast(z_streamp strm, unsigned start)
{
    1064:	e1a0b000 	mov	fp, r0
    unsigned dist;              /* match distance */
    unsigned char *from;        /* where to copy match from */

    /* copy state to local variables */
    state = (struct inflate_state *)strm->state;
    in = strm->next_in - OFF;
    1068:	e590c000 	ldr	ip, [r0]
    last = in + (strm->avail_in - 5);
    106c:	e5903004 	ldr	r3, [r0, #4]
    out = strm->next_out - OFF;
    beg = out - (start - strm->avail_out);
    1070:	e5902010 	ldr	r2, [r0, #16]
#ifdef INFLATE_STRICT
    dmax = state->dmax;
#endif
    wsize = state->wsize;
    whave = state->whave;
    write = state->write;
    1074:	e594502c 	ldr	r5, [r4, #44]	; 0x2c
    unsigned dist;              /* match distance */
    unsigned char *from;        /* where to copy match from */

    /* copy state to local variables */
    state = (struct inflate_state *)strm->state;
    in = strm->next_in - OFF;
    1078:	e24cc001 	sub	ip, ip, #1
    dmax = state->dmax;
#endif
    wsize = state->wsize;
    whave = state->whave;
    write = state->write;
    window = state->window;
    107c:	e5946030 	ldr	r6, [r4, #48]	; 0x30
    unsigned char *from;        /* where to copy match from */

    /* copy state to local variables */
    state = (struct inflate_state *)strm->state;
    in = strm->next_in - OFF;
    last = in + (strm->avail_in - 5);
    1080:	e2433005 	sub	r3, r3, #5
    whave = state->whave;
    write = state->write;
    window = state->window;
    hold = state->hold;
    bits = state->bits;
    lcode = state->lencode;
    1084:	e5947048 	ldr	r7, [r4, #72]	; 0x48
    unsigned char *from;        /* where to copy match from */

    /* copy state to local variables */
    state = (struct inflate_state *)strm->state;
    in = strm->next_in - OFF;
    last = in + (strm->avail_in - 5);
    1088:	e08c3003 	add	r3, ip, r3
    out = strm->next_out - OFF;
    beg = out - (start - strm->avail_out);
    108c:	e0611002 	rsb	r1, r1, r2
    write = state->write;
    window = state->window;
    hold = state->hold;
    bits = state->bits;
    lcode = state->lencode;
    dcode = state->distcode;
    1090:	e594804c 	ldr	r8, [r4, #76]	; 0x4c
#ifdef INFLATE_STRICT
    dmax = state->dmax;
#endif
    wsize = state->wsize;
    whave = state->whave;
    write = state->write;
    1094:	e58d5008 	str	r5, [sp, #8]
    window = state->window;
    hold = state->hold;
    bits = state->bits;
    lcode = state->lencode;
    dcode = state->distcode;
    lmask = (1U << state->lenbits) - 1;
    1098:	e5945050 	ldr	r5, [r4, #80]	; 0x50
    state = (struct inflate_state *)strm->state;
    in = strm->next_in - OFF;
    last = in + (strm->avail_in - 5);
    out = strm->next_out - OFF;
    beg = out - (start - strm->avail_out);
    end = out + (strm->avail_out - 257);
    109c:	e2422c01 	sub	r2, r2, #256	; 0x100
    unsigned char *from;        /* where to copy match from */

    /* copy state to local variables */
    state = (struct inflate_state *)strm->state;
    in = strm->next_in - OFF;
    last = in + (strm->avail_in - 5);
    10a0:	e58d301c 	str	r3, [sp, #28]
    out = strm->next_out - OFF;
    10a4:	e590300c 	ldr	r3, [r0, #12]
    beg = out - (start - strm->avail_out);
    end = out + (strm->avail_out - 257);
    10a8:	e2422001 	sub	r2, r2, #1
#ifdef INFLATE_STRICT
    dmax = state->dmax;
#endif
    wsize = state->wsize;
    10ac:	e5940024 	ldr	r0, [r4, #36]	; 0x24
                    if (op > whave) {
                        strm->msg = (char *)"invalid distance too far back";
                        state->mode = BAD;
                        break;
                    }
                    from = window - OFF;
    10b0:	e2469001 	sub	r9, r6, #1
    dmax = state->dmax;
#endif
    wsize = state->wsize;
    whave = state->whave;
    write = state->write;
    window = state->window;
    10b4:	e58d6024 	str	r6, [sp, #36]	; 0x24
                            } while (--op);
                            from = out - dist;  /* rest from output */
                        }
                    }
                    else if (write < op) {      /* wrap around window */
                        from += wsize + write - op;
    10b8:	e59da008 	ldr	sl, [sp, #8]
    whave = state->whave;
    write = state->write;
    window = state->window;
    hold = state->hold;
    bits = state->bits;
    lcode = state->lencode;
    10bc:	e58d700c 	str	r7, [sp, #12]
    dcode = state->distcode;
    10c0:	e58d8010 	str	r8, [sp, #16]

    /* copy state to local variables */
    state = (struct inflate_state *)strm->state;
    in = strm->next_in - OFF;
    last = in + (strm->avail_in - 5);
    out = strm->next_out - OFF;
    10c4:	e2433001 	sub	r3, r3, #1
                    if (op > whave) {
                        strm->msg = (char *)"invalid distance too far back";
                        state->mode = BAD;
                        break;
                    }
                    from = window - OFF;
    10c8:	e58d9014 	str	r9, [sp, #20]
    beg = out - (start - strm->avail_out);
    end = out + (strm->avail_out - 257);
#ifdef INFLATE_STRICT
    dmax = state->dmax;
#endif
    wsize = state->wsize;
    10cc:	e58d0020 	str	r0, [sp, #32]
    window = state->window;
    hold = state->hold;
    bits = state->bits;
    lcode = state->lencode;
    dcode = state->distcode;
    lmask = (1U << state->lenbits) - 1;
    10d0:	e3a00001 	mov	r0, #1
    state = (struct inflate_state *)strm->state;
    in = strm->next_in - OFF;
    last = in + (strm->avail_in - 5);
    out = strm->next_out - OFF;
    beg = out - (start - strm->avail_out);
    end = out + (strm->avail_out - 257);
    10d4:	e0832002 	add	r2, r3, r2
    window = state->window;
    hold = state->hold;
    bits = state->bits;
    lcode = state->lencode;
    dcode = state->distcode;
    lmask = (1U << state->lenbits) - 1;
    10d8:	e1a05510 	lsl	r5, r0, r5
    state = (struct inflate_state *)strm->state;
    in = strm->next_in - OFF;
    last = in + (strm->avail_in - 5);
    out = strm->next_out - OFF;
    beg = out - (start - strm->avail_out);
    end = out + (strm->avail_out - 257);
    10dc:	e58d2018 	str	r2, [sp, #24]
#ifdef INFLATE_STRICT
    dmax = state->dmax;
#endif
    wsize = state->wsize;
    whave = state->whave;
    10e0:	e5942028 	ldr	r2, [r4, #40]	; 0x28
    /* copy state to local variables */
    state = (struct inflate_state *)strm->state;
    in = strm->next_in - OFF;
    last = in + (strm->avail_in - 5);
    out = strm->next_out - OFF;
    beg = out - (start - strm->avail_out);
    10e4:	e0831001 	add	r1, r3, r1
    window = state->window;
    hold = state->hold;
    bits = state->bits;
    lcode = state->lencode;
    dcode = state->distcode;
    lmask = (1U << state->lenbits) - 1;
    10e8:	e2455001 	sub	r5, r5, #1
    /* copy state to local variables */
    state = (struct inflate_state *)strm->state;
    in = strm->next_in - OFF;
    last = in + (strm->avail_in - 5);
    out = strm->next_out - OFF;
    beg = out - (start - strm->avail_out);
    10ec:	e58d1030 	str	r1, [sp, #48]	; 0x30
#endif
    wsize = state->wsize;
    whave = state->whave;
    write = state->write;
    window = state->window;
    hold = state->hold;
    10f0:	e5941034 	ldr	r1, [r4, #52]	; 0x34
    bits = state->bits;
    lcode = state->lencode;
    dcode = state->distcode;
    lmask = (1U << state->lenbits) - 1;
    10f4:	e58d5038 	str	r5, [sp, #56]	; 0x38
    dmask = (1U << state->distbits) - 1;
    10f8:	e5945054 	ldr	r5, [r4, #84]	; 0x54
    end = out + (strm->avail_out - 257);
#ifdef INFLATE_STRICT
    dmax = state->dmax;
#endif
    wsize = state->wsize;
    whave = state->whave;
    10fc:	e58d2034 	str	r2, [sp, #52]	; 0x34
    write = state->write;
    window = state->window;
    hold = state->hold;
    bits = state->bits;
    1100:	e5942038 	ldr	r2, [r4, #56]	; 0x38
    lcode = state->lencode;
    dcode = state->distcode;
    lmask = (1U << state->lenbits) - 1;
    dmask = (1U << state->distbits) - 1;
    1104:	e1a05510 	lsl	r5, r0, r5
                            } while (--op);
                            from = out - dist;  /* rest from output */
                        }
                    }
                    else if (write < op) {      /* wrap around window */
                        from += wsize + write - op;
    1108:	e59d0020 	ldr	r0, [sp, #32]
    hold = state->hold;
    bits = state->bits;
    lcode = state->lencode;
    dcode = state->distcode;
    lmask = (1U << state->lenbits) - 1;
    dmask = (1U << state->distbits) - 1;
    110c:	e2455001 	sub	r5, r5, #1
                            } while (--op);
                            from = out - dist;  /* rest from output */
                        }
                    }
                    else if (write < op) {      /* wrap around window */
                        from += wsize + write - op;
    1110:	e08aa000 	add	sl, sl, r0
    hold = state->hold;
    bits = state->bits;
    lcode = state->lencode;
    dcode = state->distcode;
    lmask = (1U << state->lenbits) - 1;
    dmask = (1U << state->distbits) - 1;
    1114:	e58d503c 	str	r5, [sp, #60]	; 0x3c
                            } while (--op);
                            from = out - dist;  /* rest from output */
                        }
                    }
                    else if (write < op) {      /* wrap around window */
                        from += wsize + write - op;
    1118:	e58da044 	str	sl, [sp, #68]	; 0x44
    dmask = (1U << state->distbits) - 1;

    /* decode literals and length/distances until end-of-block or not enough
       input data or output space */
    do {
        if (bits < 15) {
    111c:	e352000e 	cmp	r2, #14
    1120:	8a000007 	bhi	1144 <inflate_fast+0xec>
            hold += (unsigned long)(PUP(in)) << bits;
            bits += 8;
            hold += (unsigned long)(PUP(in)) << bits;
    1124:	e5dc6002 	ldrb	r6, [ip, #2]
    /* decode literals and length/distances until end-of-block or not enough
       input data or output space */
    do {
        if (bits < 15) {
            hold += (unsigned long)(PUP(in)) << bits;
            bits += 8;
    1128:	e2825008 	add	r5, r2, #8
            hold += (unsigned long)(PUP(in)) << bits;
    112c:	e28cc002 	add	ip, ip, #2

    /* decode literals and length/distances until end-of-block or not enough
       input data or output space */
    do {
        if (bits < 15) {
            hold += (unsigned long)(PUP(in)) << bits;
    1130:	e55c0001 	ldrb	r0, [ip, #-1]
            bits += 8;
            hold += (unsigned long)(PUP(in)) << bits;
    1134:	e1a05516 	lsl	r5, r6, r5

    /* decode literals and length/distances until end-of-block or not enough
       input data or output space */
    do {
        if (bits < 15) {
            hold += (unsigned long)(PUP(in)) << bits;
    1138:	e0855210 	add	r5, r5, r0, lsl r2
            bits += 8;
            hold += (unsigned long)(PUP(in)) << bits;
            bits += 8;
    113c:	e2822010 	add	r2, r2, #16
       input data or output space */
    do {
        if (bits < 15) {
            hold += (unsigned long)(PUP(in)) << bits;
            bits += 8;
            hold += (unsigned long)(PUP(in)) << bits;
    1140:	e0811005 	add	r1, r1, r5
            bits += 8;
        }
        this = lcode[hold & lmask];
    1144:	e59d5038 	ldr	r5, [sp, #56]	; 0x38
    1148:	e59d700c 	ldr	r7, [sp, #12]
    114c:	e0010005 	and	r0, r1, r5
    1150:	e0876100 	add	r6, r7, r0, lsl #2
    1154:	e7d75100 	ldrb	r5, [r7, r0, lsl #2]
    1158:	e5d60001 	ldrb	r0, [r6, #1]
    115c:	e1d660b2 	ldrh	r6, [r6, #2]
      dolen:
        op = (unsigned)(this.bits);
        hold >>= op;
        bits -= op;
        op = (unsigned)(this.op);
        if (op == 0) {                          /* literal */
    1160:	e3550000 	cmp	r5, #0
            bits += 8;
        }
        this = lcode[hold & lmask];
      dolen:
        op = (unsigned)(this.bits);
        hold >>= op;
    1164:	e1a01031 	lsr	r1, r1, r0
        bits -= op;
    1168:	e0602002 	rsb	r2, r0, r2
        op = (unsigned)(this.op);
        if (op == 0) {                          /* literal */
            PUP(out) = (unsigned char)(this.val);
    116c:	05c36001 	strbeq	r6, [r3, #1]
    1170:	0a0000d2 	beq	14c0 <inflate_fast+0x468>
        }
        else if (op & 16) {                     /* length base */
    1174:	e3150010 	tst	r5, #16
    1178:	0a0000e5 	beq	1514 <inflate_fast+0x4bc>
            len = (unsigned)(this.val);
            op &= 15;                           /* number of extra bits */
            if (op) {
    117c:	e215500f 	ands	r5, r5, #15
        op = (unsigned)(this.op);
        if (op == 0) {                          /* literal */
            PUP(out) = (unsigned char)(this.val);
        }
        else if (op & 16) {                     /* length base */
            len = (unsigned)(this.val);
    1180:	e1a00006 	mov	r0, r6
            op &= 15;                           /* number of extra bits */
            if (op) {
    1184:	0a00000b 	beq	11b8 <inflate_fast+0x160>
                if (bits < op) {
    1188:	e1520005 	cmp	r2, r5
                    hold += (unsigned long)(PUP(in)) << bits;
                    bits += 8;
                }
                len += (unsigned)hold & ((1U << op) - 1);
    118c:	e3a08001 	mov	r8, #1
        else if (op & 16) {                     /* length base */
            len = (unsigned)(this.val);
            op &= 15;                           /* number of extra bits */
            if (op) {
                if (bits < op) {
                    hold += (unsigned long)(PUP(in)) << bits;
    1190:	35dc0001 	ldrbcc	r0, [ip, #1]
    1194:	328cc001 	addcc	ip, ip, #1
    1198:	30811210 	addcc	r1, r1, r0, lsl r2
                    bits += 8;
                }
                len += (unsigned)hold & ((1U << op) - 1);
    119c:	e1a00518 	lsl	r0, r8, r5
            len = (unsigned)(this.val);
            op &= 15;                           /* number of extra bits */
            if (op) {
                if (bits < op) {
                    hold += (unsigned long)(PUP(in)) << bits;
                    bits += 8;
    11a0:	32822008 	addcc	r2, r2, #8
                }
                len += (unsigned)hold & ((1U << op) - 1);
    11a4:	e2400001 	sub	r0, r0, #1
                hold >>= op;
                bits -= op;
    11a8:	e0652002 	rsb	r2, r5, r2
            if (op) {
                if (bits < op) {
                    hold += (unsigned long)(PUP(in)) << bits;
                    bits += 8;
                }
                len += (unsigned)hold & ((1U << op) - 1);
    11ac:	e0010000 	and	r0, r1, r0
                hold >>= op;
    11b0:	e1a01531 	lsr	r1, r1, r5
            if (op) {
                if (bits < op) {
                    hold += (unsigned long)(PUP(in)) << bits;
                    bits += 8;
                }
                len += (unsigned)hold & ((1U << op) - 1);
    11b4:	e0860000 	add	r0, r6, r0
                hold >>= op;
                bits -= op;
            }
            if (bits < 15) {
    11b8:	e352000e 	cmp	r2, #14
    11bc:	8a000007 	bhi	11e0 <inflate_fast+0x188>
                hold += (unsigned long)(PUP(in)) << bits;
                bits += 8;
                hold += (unsigned long)(PUP(in)) << bits;
    11c0:	e5dc7002 	ldrb	r7, [ip, #2]
                hold >>= op;
                bits -= op;
            }
            if (bits < 15) {
                hold += (unsigned long)(PUP(in)) << bits;
                bits += 8;
    11c4:	e2826008 	add	r6, r2, #8
                hold += (unsigned long)(PUP(in)) << bits;
    11c8:	e28cc002 	add	ip, ip, #2
                len += (unsigned)hold & ((1U << op) - 1);
                hold >>= op;
                bits -= op;
            }
            if (bits < 15) {
                hold += (unsigned long)(PUP(in)) << bits;
    11cc:	e55c5001 	ldrb	r5, [ip, #-1]
                bits += 8;
                hold += (unsigned long)(PUP(in)) << bits;
    11d0:	e1a06617 	lsl	r6, r7, r6
                len += (unsigned)hold & ((1U << op) - 1);
                hold >>= op;
                bits -= op;
            }
            if (bits < 15) {
                hold += (unsigned long)(PUP(in)) << bits;
    11d4:	e0866215 	add	r6, r6, r5, lsl r2
                bits += 8;
                hold += (unsigned long)(PUP(in)) << bits;
                bits += 8;
    11d8:	e2822010 	add	r2, r2, #16
                bits -= op;
            }
            if (bits < 15) {
                hold += (unsigned long)(PUP(in)) << bits;
                bits += 8;
                hold += (unsigned long)(PUP(in)) << bits;
    11dc:	e0811006 	add	r1, r1, r6
                bits += 8;
            }
            this = dcode[hold & dmask];
    11e0:	e59d903c 	ldr	r9, [sp, #60]	; 0x3c
    11e4:	e59da010 	ldr	sl, [sp, #16]
    11e8:	e0015009 	and	r5, r1, r9
    11ec:	e08a7105 	add	r7, sl, r5, lsl #2
    11f0:	e7da5105 	ldrb	r5, [sl, r5, lsl #2]
    11f4:	e5d76001 	ldrb	r6, [r7, #1]
    11f8:	e1d770b2 	ldrh	r7, [r7, #2]
          dodist:
            op = (unsigned)(this.bits);
            hold >>= op;
            bits -= op;
            op = (unsigned)(this.op);
            if (op & 16) {                      /* distance base */
    11fc:	e3150010 	tst	r5, #16
                bits += 8;
            }
            this = dcode[hold & dmask];
          dodist:
            op = (unsigned)(this.bits);
            hold >>= op;
    1200:	e1a01631 	lsr	r1, r1, r6
            bits -= op;
    1204:	e0662002 	rsb	r2, r6, r2
            op = (unsigned)(this.op);
            if (op & 16) {                      /* distance base */
    1208:	0a0000ae 	beq	14c8 <inflate_fast+0x470>
                dist = (unsigned)(this.val);
                op &= 15;                       /* number of extra bits */
    120c:	e205500f 	and	r5, r5, #15
            }
            this = dcode[hold & dmask];
          dodist:
            op = (unsigned)(this.bits);
            hold >>= op;
            bits -= op;
    1210:	e1a06002 	mov	r6, r2
            op = (unsigned)(this.op);
            if (op & 16) {                      /* distance base */
                dist = (unsigned)(this.val);
                op &= 15;                       /* number of extra bits */
                if (bits < op) {
    1214:	e1520005 	cmp	r2, r5
    1218:	2a000008 	bcs	1240 <inflate_fast+0x1e8>
                    hold += (unsigned long)(PUP(in)) << bits;
    121c:	e5dc8001 	ldrb	r8, [ip, #1]
    1220:	e0811218 	add	r1, r1, r8, lsl r2
                    bits += 8;
    1224:	e2822008 	add	r2, r2, #8
                    if (bits < op) {
    1228:	e1520005 	cmp	r2, r5
                        hold += (unsigned long)(PUP(in)) << bits;
    122c:	35dc8002 	ldrbcc	r8, [ip, #2]
            op = (unsigned)(this.op);
            if (op & 16) {                      /* distance base */
                dist = (unsigned)(this.val);
                op &= 15;                       /* number of extra bits */
                if (bits < op) {
                    hold += (unsigned long)(PUP(in)) << bits;
    1230:	228cc001 	addcs	ip, ip, #1
                    bits += 8;
                    if (bits < op) {
                        hold += (unsigned long)(PUP(in)) << bits;
    1234:	328cc002 	addcc	ip, ip, #2
    1238:	30811218 	addcc	r1, r1, r8, lsl r2
                        bits += 8;
    123c:	32862010 	addcc	r2, r6, #16
                    }
                }
                dist += (unsigned)hold & ((1U << op) - 1);
    1240:	e3a08001 	mov	r8, #1
                    break;
                }
#endif
                hold >>= op;
                bits -= op;
                op = (unsigned)(out - beg);     /* max distance in output */
    1244:	e59d9030 	ldr	r9, [sp, #48]	; 0x30
                    state->mode = BAD;
                    break;
                }
#endif
                hold >>= op;
                bits -= op;
    1248:	e0652002 	rsb	r2, r5, r2
                    if (bits < op) {
                        hold += (unsigned long)(PUP(in)) << bits;
                        bits += 8;
                    }
                }
                dist += (unsigned)hold & ((1U << op) - 1);
    124c:	e1a06518 	lsl	r6, r8, r5
    1250:	e2466001 	sub	r6, r6, #1
    1254:	e0016006 	and	r6, r1, r6
                    strm->msg = (char *)"invalid distance too far back";
                    state->mode = BAD;
                    break;
                }
#endif
                hold >>= op;
    1258:	e1a01531 	lsr	r1, r1, r5
                    if (bits < op) {
                        hold += (unsigned long)(PUP(in)) << bits;
                        bits += 8;
                    }
                }
                dist += (unsigned)hold & ((1U << op) - 1);
    125c:	e0866007 	add	r6, r6, r7
                    break;
                }
#endif
                hold >>= op;
                bits -= op;
                op = (unsigned)(out - beg);     /* max distance in output */
    1260:	e0697003 	rsb	r7, r9, r3
                if (dist > op) {                /* see if copy from window */
    1264:	e1560007 	cmp	r6, r7
    1268:	9a000062 	bls	13f8 <inflate_fast+0x3a0>
                    op = dist - op;             /* distance back in window */
                    if (op > whave) {
    126c:	e59da034 	ldr	sl, [sp, #52]	; 0x34
#endif
                hold >>= op;
                bits -= op;
                op = (unsigned)(out - beg);     /* max distance in output */
                if (dist > op) {                /* see if copy from window */
                    op = dist - op;             /* distance back in window */
    1270:	e0677006 	rsb	r7, r7, r6
                    if (op > whave) {
    1274:	e157000a 	cmp	r7, sl
                        strm->msg = (char *)"invalid distance too far back";
    1278:	859f0350 	ldrhi	r0, [pc, #848]	; 15d0 <inflate_fast+0x578>
    127c:	808f0000 	addhi	r0, pc, r0
    1280:	8a00009f 	bhi	1504 <inflate_fast+0x4ac>
                        state->mode = BAD;
                        break;
                    }
                    from = window - OFF;
                    if (write == 0) {           /* very common case */
    1284:	e59d8008 	ldr	r8, [sp, #8]
                    if (op > whave) {
                        strm->msg = (char *)"invalid distance too far back";
                        state->mode = BAD;
                        break;
                    }
                    from = window - OFF;
    1288:	e59d5014 	ldr	r5, [sp, #20]
                    if (write == 0) {           /* very common case */
    128c:	e3580000 	cmp	r8, #0
    1290:	1a00000d 	bne	12cc <inflate_fast+0x274>
                        from += wsize - op;
    1294:	e59d9020 	ldr	r9, [sp, #32]
                        if (op < len) {         /* some from window */
    1298:	e1570000 	cmp	r7, r0
                        state->mode = BAD;
                        break;
                    }
                    from = window - OFF;
                    if (write == 0) {           /* very common case */
                        from += wsize - op;
    129c:	e59da014 	ldr	sl, [sp, #20]
    12a0:	e0675009 	rsb	r5, r7, r9
    12a4:	e08a5005 	add	r5, sl, r5
                        if (op < len) {         /* some from window */
    12a8:	2a00002c 	bcs	1360 <inflate_fast+0x308>
                            len -= op;
    12ac:	e0670000 	rsb	r0, r7, r0
    12b0:	e1a08003 	mov	r8, r3
    12b4:	e0859007 	add	r9, r5, r7
                            do {
                                PUP(out) = PUP(from);
    12b8:	e5f5a001 	ldrb	sl, [r5, #1]!
                            } while (--op);
    12bc:	e1550009 	cmp	r5, r9
                    if (write == 0) {           /* very common case */
                        from += wsize - op;
                        if (op < len) {         /* some from window */
                            len -= op;
                            do {
                                PUP(out) = PUP(from);
    12c0:	e5e8a001 	strb	sl, [r8, #1]!
                            } while (--op);
    12c4:	1afffffb 	bne	12b8 <inflate_fast+0x260>
    12c8:	ea000033 	b	139c <inflate_fast+0x344>
                            from = out - dist;  /* rest from output */
                        }
                    }
                    else if (write < op) {      /* wrap around window */
    12cc:	e59d8008 	ldr	r8, [sp, #8]
    12d0:	e1580007 	cmp	r8, r7
    12d4:	2a000023 	bcs	1368 <inflate_fast+0x310>
                        from += wsize + write - op;
    12d8:	e59d9044 	ldr	r9, [sp, #68]	; 0x44
    12dc:	e59da014 	ldr	sl, [sp, #20]
    12e0:	e0678009 	rsb	r8, r7, r9
                        op -= write;
    12e4:	e59d9008 	ldr	r9, [sp, #8]
                            } while (--op);
                            from = out - dist;  /* rest from output */
                        }
                    }
                    else if (write < op) {      /* wrap around window */
                        from += wsize + write - op;
    12e8:	e08a8008 	add	r8, sl, r8
                        op -= write;
    12ec:	e0697007 	rsb	r7, r9, r7
                        if (op < len) {         /* some from end of window */
    12f0:	e1570000 	cmp	r7, r0
                            } while (--op);
                            from = out - dist;  /* rest from output */
                        }
                    }
                    else if (write < op) {      /* wrap around window */
                        from += wsize + write - op;
    12f4:	21a05008 	movcs	r5, r8
                        op -= write;
                        if (op < len) {         /* some from end of window */
    12f8:	2a000018 	bcs	1360 <inflate_fast+0x308>
    12fc:	e088a007 	add	sl, r8, r7
                            len -= op;
    1300:	e0670000 	rsb	r0, r7, r0
    1304:	e1a09003 	mov	r9, r3
    1308:	e58da004 	str	sl, [sp, #4]
                            do {
                                PUP(out) = PUP(from);
    130c:	e5f8a001 	ldrb	sl, [r8, #1]!
    1310:	e5e9a001 	strb	sl, [r9, #1]!
                            } while (--op);
    1314:	e59da004 	ldr	sl, [sp, #4]
    1318:	e158000a 	cmp	r8, sl
    131c:	1afffffa 	bne	130c <inflate_fast+0x2b4>
    1320:	e0833007 	add	r3, r3, r7
                            from = window - OFF;
                            if (write < len) {  /* some from start of window */
    1324:	e59d7008 	ldr	r7, [sp, #8]
    1328:	e1570000 	cmp	r7, r0
    132c:	2a00000b 	bcs	1360 <inflate_fast+0x308>
                                op = write;
                                len -= op;
    1330:	e0670000 	rsb	r0, r7, r0
    1334:	e3a05000 	mov	r5, #0
    1338:	e1a07003 	mov	r7, r3
                                do {
                                    PUP(out) = PUP(from);
    133c:	e59d9024 	ldr	r9, [sp, #36]	; 0x24
                                } while (--op);
    1340:	e59da008 	ldr	sl, [sp, #8]
                            from = window - OFF;
                            if (write < len) {  /* some from start of window */
                                op = write;
                                len -= op;
                                do {
                                    PUP(out) = PUP(from);
    1344:	e7d98005 	ldrb	r8, [r9, r5]
    1348:	e2855001 	add	r5, r5, #1
                                } while (--op);
    134c:	e155000a 	cmp	r5, sl
                            from = window - OFF;
                            if (write < len) {  /* some from start of window */
                                op = write;
                                len -= op;
                                do {
                                    PUP(out) = PUP(from);
    1350:	e5e78001 	strb	r8, [r7, #1]!
                                } while (--op);
    1354:	1afffff8 	bne	133c <inflate_fast+0x2e4>
    1358:	e083300a 	add	r3, r3, sl
                                from = out - dist;      /* rest from output */
    135c:	e0665003 	rsb	r5, r6, r3
    1360:	e1a06003 	mov	r6, r3
    1364:	ea00000e 	b	13a4 <inflate_fast+0x34c>
                            }
                        }
                    }
                    else {                      /* contiguous in window */
                        from += write - op;
    1368:	e59d8008 	ldr	r8, [sp, #8]
                        if (op < len) {         /* some from window */
    136c:	e1570000 	cmp	r7, r0
                                from = out - dist;      /* rest from output */
                            }
                        }
                    }
                    else {                      /* contiguous in window */
                        from += write - op;
    1370:	e59d9014 	ldr	r9, [sp, #20]
    1374:	e0675008 	rsb	r5, r7, r8
    1378:	e0895005 	add	r5, r9, r5
                        if (op < len) {         /* some from window */
    137c:	2afffff7 	bcs	1360 <inflate_fast+0x308>
                            len -= op;
    1380:	e0670000 	rsb	r0, r7, r0
    1384:	e1a08003 	mov	r8, r3
    1388:	e0859007 	add	r9, r5, r7
                            do {
                                PUP(out) = PUP(from);
    138c:	e5f5a001 	ldrb	sl, [r5, #1]!
                            } while (--op);
    1390:	e1550009 	cmp	r5, r9
                    else {                      /* contiguous in window */
                        from += write - op;
                        if (op < len) {         /* some from window */
                            len -= op;
                            do {
                                PUP(out) = PUP(from);
    1394:	e5e8a001 	strb	sl, [r8, #1]!
                            } while (--op);
    1398:	1afffffb 	bne	138c <inflate_fast+0x334>
    139c:	e0833007 	add	r3, r3, r7
    13a0:	eaffffed 	b	135c <inflate_fast+0x304>
                            from = out - dist;  /* rest from output */
                        }
                    }
                    while (len > 2) {
    13a4:	e3500002 	cmp	r0, #2
    13a8:	e1a03006 	mov	r3, r6
    13ac:	9a000007 	bls	13d0 <inflate_fast+0x378>
                        PUP(out) = PUP(from);
    13b0:	e5d53001 	ldrb	r3, [r5, #1]
                        PUP(out) = PUP(from);
                        PUP(out) = PUP(from);
                        len -= 3;
    13b4:	e2400003 	sub	r0, r0, #3
                            } while (--op);
                            from = out - dist;  /* rest from output */
                        }
                    }
                    while (len > 2) {
                        PUP(out) = PUP(from);
    13b8:	e5c63001 	strb	r3, [r6, #1]
                        PUP(out) = PUP(from);
    13bc:	e5d53002 	ldrb	r3, [r5, #2]
    13c0:	e5c63002 	strb	r3, [r6, #2]
                        PUP(out) = PUP(from);
    13c4:	e5f53003 	ldrb	r3, [r5, #3]!
    13c8:	e5e63003 	strb	r3, [r6, #3]!
    13cc:	eafffff4 	b	13a4 <inflate_fast+0x34c>
                        len -= 3;
                    }
                    if (len) {
    13d0:	e3500000 	cmp	r0, #0
    13d4:	0a000061 	beq	1560 <inflate_fast+0x508>
                        PUP(out) = PUP(from);
    13d8:	e5d57001 	ldrb	r7, [r5, #1]
                        if (len > 1)
    13dc:	e3500002 	cmp	r0, #2
                            PUP(out) = PUP(from);
    13e0:	02863002 	addeq	r3, r6, #2
                        PUP(out) = PUP(from);
                        PUP(out) = PUP(from);
                        len -= 3;
                    }
                    if (len) {
                        PUP(out) = PUP(from);
    13e4:	e5c67001 	strb	r7, [r6, #1]
                        if (len > 1)
                            PUP(out) = PUP(from);
    13e8:	05d50002 	ldrbeq	r0, [r5, #2]
    13ec:	05c60002 	strbeq	r0, [r6, #2]
                        PUP(out) = PUP(from);
                        len -= 3;
                    }
                    if (len) {
                        PUP(out) = PUP(from);
                        if (len > 1)
    13f0:	0a00005a 	beq	1560 <inflate_fast+0x508>
    13f4:	ea000031 	b	14c0 <inflate_fast+0x468>
		    unsigned long loops;

                    from = out - dist;          /* copy direct from output */
		    /* minimum length is three */
		    /* Align out addr */
		    if (!((long)(out - 1 + OFF) & 1)) {
    13f8:	e3130001 	tst	r3, #1
                }
                else {
		    unsigned short *sout;
		    unsigned long loops;

                    from = out - dist;          /* copy direct from output */
    13fc:	e0667003 	rsb	r7, r6, r3
		    /* minimum length is three */
		    /* Align out addr */
		    if (!((long)(out - 1 + OFF) & 1)) {
			PUP(out) = PUP(from);
    1400:	05d75001 	ldrbeq	r5, [r7, #1]
			len--;
    1404:	02400001 	subeq	r0, r0, #1

                    from = out - dist;          /* copy direct from output */
		    /* minimum length is three */
		    /* Align out addr */
		    if (!((long)(out - 1 + OFF) & 1)) {
			PUP(out) = PUP(from);
    1408:	02877001 	addeq	r7, r7, #1
    140c:	05c35001 	strbeq	r5, [r3, #1]
    1410:	02833001 	addeq	r3, r3, #1
			len--;
		    }
		    sout = (unsigned short *)(out - OFF);
		    if (dist > 2) {
    1414:	e3560002 	cmp	r6, #2
		    /* Align out addr */
		    if (!((long)(out - 1 + OFF) & 1)) {
			PUP(out) = PUP(from);
			len--;
		    }
		    sout = (unsigned short *)(out - OFF);
    1418:	e2435001 	sub	r5, r3, #1
		    if (dist > 2) {
    141c:	9a000015 	bls	1478 <inflate_fast+0x420>
			unsigned short *sfrom;

			sfrom = (unsigned short *)(from - OFF);
			loops = len >> 1;
    1420:	e1a080a0 	lsr	r8, r0, #1
		    }
		    sout = (unsigned short *)(out - OFF);
		    if (dist > 2) {
			unsigned short *sfrom;

			sfrom = (unsigned short *)(from - OFF);
    1424:	e2477001 	sub	r7, r7, #1
    1428:	e1a09005 	mov	r9, r5
    142c:	e1a06007 	mov	r6, r7
			loops = len >> 1;
    1430:	e1a03008 	mov	r3, r8
		    }
		    sout = (unsigned short *)(out - OFF);
		    if (dist > 2) {
			unsigned short *sfrom;

			sfrom = (unsigned short *)(from - OFF);
    1434:	e58d7004 	str	r7, [sp, #4]
get_unaligned16(const unsigned short *p)
{
	union uu  mm;
	unsigned char *b = (unsigned char *)p;

	mm.b[0] = b[0];
    1438:	e5f6a002 	ldrb	sl, [r6, #2]!
#ifdef CONFIG_HAVE_EFFICIENT_UNALIGNED_ACCESS
			    PUP(sout) = PUP(sfrom);
#else
			    PUP(sout) = UP_UNALIGNED(sfrom);
#endif
			while (--loops);
    143c:	e2533001 	subs	r3, r3, #1
get_unaligned16(const unsigned short *p)
{
	union uu  mm;
	unsigned char *b = (unsigned char *)p;

	mm.b[0] = b[0];
    1440:	e1dd72b8 	ldrh	r7, [sp, #40]	; 0x28
    1444:	e7c7701a 	bfi	r7, sl, #0, #8
	mm.b[1] = b[1];
    1448:	e5d6a001 	ldrb	sl, [r6, #1]
    144c:	e7cf741a 	bfi	r7, sl, #8, #8
    1450:	e1cd72b8 	strh	r7, [sp, #40]	; 0x28
			loops = len >> 1;
			do
#ifdef CONFIG_HAVE_EFFICIENT_UNALIGNED_ACCESS
			    PUP(sout) = PUP(sfrom);
#else
			    PUP(sout) = UP_UNALIGNED(sfrom);
    1454:	e1e970b2 	strh	r7, [r9, #2]!
#endif
			while (--loops);
    1458:	1afffff6 	bne	1438 <inflate_fast+0x3e0>
    145c:	e1a08088 	lsl	r8, r8, #1
    1460:	e0853008 	add	r3, r5, r8
    1464:	e59d5004 	ldr	r5, [sp, #4]
			out = (unsigned char *)sout + OFF;
    1468:	e2833001 	add	r3, r3, #1
    146c:	e0857008 	add	r7, r5, r8
			from = (unsigned char *)sfrom + OFF;
    1470:	e2877001 	add	r7, r7, #1
    1474:	ea00000d 	b	14b0 <inflate_fast+0x458>
		    } else { /* dist == 1 or dist == 2 */
			unsigned short pat16;

			pat16 = *(sout-1+OFF);
    1478:	e15380b1 	ldrh	r8, [r3, #-1]
			if (dist == 1) {
    147c:	e3560001 	cmp	r6, #1
    1480:	e1a09005 	mov	r9, r5
				union uu mm;
				/* copy one char pattern to both bytes */
				mm.us = pat16;
    1484:	01a03008 	moveq	r3, r8
				mm.b[0] = mm.b[1];
    1488:	01a08428 	lsreq	r8, r8, #8
    148c:	07c73018 	bfieq	r3, r8, #0, #8
				pat16 = mm.us;
    1490:	06ff8073 	uxtheq	r8, r3
			}
			loops = len >> 1;
    1494:	e1a030a0 	lsr	r3, r0, #1
    1498:	e1a06003 	mov	r6, r3
			do
			    PUP(sout) = pat16;
			while (--loops);
    149c:	e2566001 	subs	r6, r6, #1
				mm.b[0] = mm.b[1];
				pat16 = mm.us;
			}
			loops = len >> 1;
			do
			    PUP(sout) = pat16;
    14a0:	e1e980b2 	strh	r8, [r9, #2]!
			while (--loops);
    14a4:	1afffffc 	bne	149c <inflate_fast+0x444>
    14a8:	e0853083 	add	r3, r5, r3, lsl #1
			out = (unsigned char *)sout + OFF;
    14ac:	e2833001 	add	r3, r3, #1
		    }
		    if (len & 1)
    14b0:	e3100001 	tst	r0, #1
    14b4:	0a000029 	beq	1560 <inflate_fast+0x508>
			PUP(out) = PUP(from);
    14b8:	e5d70001 	ldrb	r0, [r7, #1]
    14bc:	e5c30001 	strb	r0, [r3, #1]
    14c0:	e2833001 	add	r3, r3, #1
    14c4:	ea000025 	b	1560 <inflate_fast+0x508>
                }
            }
            else if ((op & 64) == 0) {          /* 2nd level distance code */
    14c8:	e3150040 	tst	r5, #64	; 0x40
    14cc:	1a00000a 	bne	14fc <inflate_fast+0x4a4>
                this = dcode[this.val + (hold & ((1U << op) - 1))];
    14d0:	e3a06001 	mov	r6, #1
    14d4:	e59d9010 	ldr	r9, [sp, #16]
    14d8:	e1a05516 	lsl	r5, r6, r5
    14dc:	e2455001 	sub	r5, r5, #1
    14e0:	e0055001 	and	r5, r5, r1
    14e4:	e0857007 	add	r7, r5, r7
    14e8:	e0898107 	add	r8, r9, r7, lsl #2
    14ec:	e7d95107 	ldrb	r5, [r9, r7, lsl #2]
    14f0:	e5d86001 	ldrb	r6, [r8, #1]
    14f4:	e1d870b2 	ldrh	r7, [r8, #2]
                goto dodist;
    14f8:	eaffff3f 	b	11fc <inflate_fast+0x1a4>
            }
            else {
                strm->msg = (char *)"invalid distance code";
    14fc:	e59f00d0 	ldr	r0, [pc, #208]	; 15d4 <inflate_fast+0x57c>
    1500:	e08f0000 	add	r0, pc, r0
    1504:	e58b0018 	str	r0, [fp, #24]
                state->mode = BAD;
    1508:	e3a0001b 	mov	r0, #27
    150c:	e5840000 	str	r0, [r4]
                break;
    1510:	ea000017 	b	1574 <inflate_fast+0x51c>
            }
        }
        else if ((op & 64) == 0) {              /* 2nd level length code */
    1514:	e3150040 	tst	r5, #64	; 0x40
    1518:	1a00000a 	bne	1548 <inflate_fast+0x4f0>
            this = lcode[this.val + (hold & ((1U << op) - 1))];
    151c:	e3a0a001 	mov	sl, #1
    1520:	e59d000c 	ldr	r0, [sp, #12]
    1524:	e1a0551a 	lsl	r5, sl, r5
    1528:	e2455001 	sub	r5, r5, #1
    152c:	e0055001 	and	r5, r5, r1
    1530:	e0856006 	add	r6, r5, r6
    1534:	e0807106 	add	r7, r0, r6, lsl #2
    1538:	e7d05106 	ldrb	r5, [r0, r6, lsl #2]
    153c:	e5d70001 	ldrb	r0, [r7, #1]
    1540:	e1d760b2 	ldrh	r6, [r7, #2]
            goto dolen;
    1544:	eaffff05 	b	1160 <inflate_fast+0x108>
        }
        else if (op & 32) {                     /* end-of-block */
    1548:	e3150020 	tst	r5, #32
            state->mode = TYPE;
    154c:	13a0000b 	movne	r0, #11
        }
        else if ((op & 64) == 0) {              /* 2nd level length code */
            this = lcode[this.val + (hold & ((1U << op) - 1))];
            goto dolen;
        }
        else if (op & 32) {                     /* end-of-block */
    1550:	1affffed 	bne	150c <inflate_fast+0x4b4>
            state->mode = TYPE;
            break;
        }
        else {
            strm->msg = (char *)"invalid literal/length code";
    1554:	e59f007c 	ldr	r0, [pc, #124]	; 15d8 <inflate_fast+0x580>
    1558:	e08f0000 	add	r0, pc, r0
    155c:	eaffffe8 	b	1504 <inflate_fast+0x4ac>
            state->mode = BAD;
            break;
        }
    } while (in < last && out < end);
    1560:	e59d5018 	ldr	r5, [sp, #24]
    1564:	e59d601c 	ldr	r6, [sp, #28]
    1568:	e1530005 	cmp	r3, r5
    156c:	315c0006 	cmpcc	ip, r6
    1570:	3afffee9 	bcc	111c <inflate_fast+0xc4>

    /* return unused bytes (on entry, bits < 8, so in won't go too far back) */
    len = bits >> 3;
    1574:	e1a001a2 	lsr	r0, r2, #3

    /* update state and return */
    strm->next_in = in + OFF;
    strm->next_out = out + OFF;
    strm->avail_in = (unsigned)(in < last ? 5 + (last - in) : 5 - (in - last));
    strm->avail_out = (unsigned)(out < end ?
    1578:	e59d8018 	ldr	r8, [sp, #24]
    hold &= (1U << bits) - 1;

    /* update state and return */
    strm->next_in = in + OFF;
    strm->next_out = out + OFF;
    strm->avail_in = (unsigned)(in < last ? 5 + (last - in) : 5 - (in - last));
    157c:	e59d701c 	ldr	r7, [sp, #28]
        }
    } while (in < last && out < end);

    /* return unused bytes (on entry, bits < 8, so in won't go too far back) */
    len = bits >> 3;
    in -= len;
    1580:	e060c00c 	rsb	ip, r0, ip
    bits -= len << 3;
    1584:	e1a00180 	lsl	r0, r0, #3
    1588:	e0602002 	rsb	r2, r0, r2
    hold &= (1U << bits) - 1;
    158c:	e3e00000 	mvn	r0, #0
    1590:	e1c11210 	bic	r1, r1, r0, lsl r2

    /* update state and return */
    strm->next_in = in + OFF;
    1594:	e28c0001 	add	r0, ip, #1
    strm->next_out = out + OFF;
    strm->avail_in = (unsigned)(in < last ? 5 + (last - in) : 5 - (in - last));
    1598:	e06cc007 	rsb	ip, ip, r7
    in -= len;
    bits -= len << 3;
    hold &= (1U << bits) - 1;

    /* update state and return */
    strm->next_in = in + OFF;
    159c:	e58b0000 	str	r0, [fp]
    strm->next_out = out + OFF;
    15a0:	e2830001 	add	r0, r3, #1
    15a4:	e0633008 	rsb	r3, r3, r8
    strm->avail_in = (unsigned)(in < last ? 5 + (last - in) : 5 - (in - last));
    strm->avail_out = (unsigned)(out < end ?
                                 257 + (end - out) : 257 - (out - end));
    15a8:	e2833c01 	add	r3, r3, #256	; 0x100
    hold &= (1U << bits) - 1;

    /* update state and return */
    strm->next_in = in + OFF;
    strm->next_out = out + OFF;
    strm->avail_in = (unsigned)(in < last ? 5 + (last - in) : 5 - (in - last));
    15ac:	e28cc005 	add	ip, ip, #5
    strm->avail_out = (unsigned)(out < end ?
                                 257 + (end - out) : 257 - (out - end));
    15b0:	e2833001 	add	r3, r3, #1
    bits -= len << 3;
    hold &= (1U << bits) - 1;

    /* update state and return */
    strm->next_in = in + OFF;
    strm->next_out = out + OFF;
    15b4:	e58b000c 	str	r0, [fp, #12]
    strm->avail_in = (unsigned)(in < last ? 5 + (last - in) : 5 - (in - last));
    15b8:	e58bc004 	str	ip, [fp, #4]
    strm->avail_out = (unsigned)(out < end ?
    15bc:	e58b3010 	str	r3, [fp, #16]
                                 257 + (end - out) : 257 - (out - end));
    state->hold = hold;
    15c0:	e5841034 	str	r1, [r4, #52]	; 0x34
    state->bits = bits;
    15c4:	e5842038 	str	r2, [r4, #56]	; 0x38
    return;
}
    15c8:	e28dd04c 	add	sp, sp, #76	; 0x4c
    15cc:	e8bd8ff0 	pop	{r4, r5, r6, r7, r8, r9, sl, fp, pc}
    15d0:	0000291d 	.word	0x0000291d
    15d4:	000026b7 	.word	0x000026b7
    15d8:	00002675 	.word	0x00002675

000015dc <zlib_inflate_workspacesize>:
#include "infutil.h"

int zlib_inflate_workspacesize(void)
{
    return sizeof(struct inflate_workspace);
}
    15dc:	e30a052c 	movw	r0, #42284	; 0xa52c
    15e0:	e12fff1e 	bx	lr

000015e4 <zlib_inflateReset>:

int zlib_inflateReset(z_streamp strm)
{
    struct inflate_state *state;

    if (strm == NULL || strm->state == NULL) return Z_STREAM_ERROR;
    15e4:	e3500000 	cmp	r0, #0
    15e8:	0a00001c 	beq	1660 <zlib_inflateReset+0x7c>
    15ec:	e590301c 	ldr	r3, [r0, #28]
    15f0:	e3530000 	cmp	r3, #0
    15f4:	0a000019 	beq	1660 <zlib_inflateReset+0x7c>
    state = (struct inflate_state *)strm->state;
    strm->total_in = strm->total_out = state->total = 0;
    15f8:	e3a02000 	mov	r2, #0
    strm->msg = NULL;
    strm->adler = 1;        /* to support ill-conceived Java test suite */
    15fc:	e3a0c001 	mov	ip, #1
    state->mode = HEAD;
    state->last = 0;
    state->havedict = 0;
    state->dmax = 32768U;
    1600:	e3a01902 	mov	r1, #32768	; 0x8000
{
    struct inflate_state *state;

    if (strm == NULL || strm->state == NULL) return Z_STREAM_ERROR;
    state = (struct inflate_state *)strm->state;
    strm->total_in = strm->total_out = state->total = 0;
    1604:	e583201c 	str	r2, [r3, #28]
    strm->msg = NULL;
    strm->adler = 1;        /* to support ill-conceived Java test suite */
    1608:	e580c028 	str	ip, [r0, #40]	; 0x28
{
    struct inflate_state *state;

    if (strm == NULL || strm->state == NULL) return Z_STREAM_ERROR;
    state = (struct inflate_state *)strm->state;
    strm->total_in = strm->total_out = state->total = 0;
    160c:	e5802014 	str	r2, [r0, #20]
    1610:	e5802008 	str	r2, [r0, #8]
    strm->msg = NULL;
    1614:	e5802018 	str	r2, [r0, #24]
    /* Initialise Window */
    state->wsize = 1U << state->wbits;
    state->write = 0;
    state->whave = 0;

    return Z_OK;
    1618:	e1a00002 	mov	r0, r2
    strm->msg = NULL;
    strm->adler = 1;        /* to support ill-conceived Java test suite */
    state->mode = HEAD;
    state->last = 0;
    state->havedict = 0;
    state->dmax = 32768U;
    161c:	e5831014 	str	r1, [r3, #20]
    state->hold = 0;
    state->bits = 0;
    state->lencode = state->distcode = state->next = state->codes;
    1620:	e2831e52 	add	r1, r3, #1312	; 0x520
    1624:	e281100c 	add	r1, r1, #12
    if (strm == NULL || strm->state == NULL) return Z_STREAM_ERROR;
    state = (struct inflate_state *)strm->state;
    strm->total_in = strm->total_out = state->total = 0;
    strm->msg = NULL;
    strm->adler = 1;        /* to support ill-conceived Java test suite */
    state->mode = HEAD;
    1628:	e5832000 	str	r2, [r3]
    state->last = 0;
    162c:	e5832004 	str	r2, [r3, #4]
    state->havedict = 0;
    state->dmax = 32768U;
    state->hold = 0;
    state->bits = 0;
    state->lencode = state->distcode = state->next = state->codes;
    1630:	e5831068 	str	r1, [r3, #104]	; 0x68
    1634:	e583104c 	str	r1, [r3, #76]	; 0x4c
    1638:	e5831048 	str	r1, [r3, #72]	; 0x48

    /* Initialise Window */
    state->wsize = 1U << state->wbits;
    163c:	e5931020 	ldr	r1, [r3, #32]
    strm->total_in = strm->total_out = state->total = 0;
    strm->msg = NULL;
    strm->adler = 1;        /* to support ill-conceived Java test suite */
    state->mode = HEAD;
    state->last = 0;
    state->havedict = 0;
    1640:	e583200c 	str	r2, [r3, #12]
    state->dmax = 32768U;
    state->hold = 0;
    1644:	e5832034 	str	r2, [r3, #52]	; 0x34
    state->bits = 0;
    1648:	e5832038 	str	r2, [r3, #56]	; 0x38
    state->lencode = state->distcode = state->next = state->codes;

    /* Initialise Window */
    state->wsize = 1U << state->wbits;
    164c:	e1a0c11c 	lsl	ip, ip, r1
    state->write = 0;
    1650:	e583202c 	str	r2, [r3, #44]	; 0x2c
    state->whave = 0;
    1654:	e5832028 	str	r2, [r3, #40]	; 0x28
    state->hold = 0;
    state->bits = 0;
    state->lencode = state->distcode = state->next = state->codes;

    /* Initialise Window */
    state->wsize = 1U << state->wbits;
    1658:	e583c024 	str	ip, [r3, #36]	; 0x24
    state->write = 0;
    state->whave = 0;

    return Z_OK;
    165c:	e12fff1e 	bx	lr

int zlib_inflateReset(z_streamp strm)
{
    struct inflate_state *state;

    if (strm == NULL || strm->state == NULL) return Z_STREAM_ERROR;
    1660:	e3e00001 	mvn	r0, #1
    state->wsize = 1U << state->wbits;
    state->write = 0;
    state->whave = 0;

    return Z_OK;
}
    1664:	e12fff1e 	bx	lr

00001668 <zlib_inflateInit2>:

int zlib_inflateInit2(z_streamp strm, int windowBits)
{
    struct inflate_state *state;

    if (strm == NULL) return Z_STREAM_ERROR;
    1668:	e3500000 	cmp	r0, #0
    166c:	0a000012 	beq	16bc <zlib_inflateInit2+0x54>
    strm->msg = NULL;                 /* in case we return an error */
    1670:	e3a02000 	mov	r2, #0

    state = &WS(strm)->inflate_state;
    1674:	e5903020 	ldr	r3, [r0, #32]
    strm->state = (struct internal_state *)state;

    if (windowBits < 0) {
    1678:	e1510002 	cmp	r1, r2
int zlib_inflateInit2(z_streamp strm, int windowBits)
{
    struct inflate_state *state;

    if (strm == NULL) return Z_STREAM_ERROR;
    strm->msg = NULL;                 /* in case we return an error */
    167c:	e5802018 	str	r2, [r0, #24]
    if (windowBits < 0) {
        state->wrap = 0;
        windowBits = -windowBits;
    }
    else {
        state->wrap = (windowBits >> 4) + 1;
    1680:	a1a02241 	asrge	r2, r1, #4
    state = &WS(strm)->inflate_state;
    strm->state = (struct internal_state *)state;

    if (windowBits < 0) {
        state->wrap = 0;
        windowBits = -windowBits;
    1684:	b2611000 	rsblt	r1, r1, #0
    }
    else {
        state->wrap = (windowBits >> 4) + 1;
    1688:	a2822001 	addge	r2, r2, #1

    if (strm == NULL) return Z_STREAM_ERROR;
    strm->msg = NULL;                 /* in case we return an error */

    state = &WS(strm)->inflate_state;
    strm->state = (struct internal_state *)state;
    168c:	e580301c 	str	r3, [r0, #28]

    if (windowBits < 0) {
        state->wrap = 0;
    1690:	b5832008 	strlt	r2, [r3, #8]
        windowBits = -windowBits;
    }
    else {
        state->wrap = (windowBits >> 4) + 1;
    1694:	a5832008 	strge	r2, [r3, #8]
    }
    if (windowBits < 8 || windowBits > 15) {
    1698:	e2412008 	sub	r2, r1, #8
    169c:	e3520007 	cmp	r2, #7
    16a0:	8a000005 	bhi	16bc <zlib_inflateInit2+0x54>
        return Z_STREAM_ERROR;
    }
    state->wbits = (unsigned)windowBits;
    16a4:	e5831020 	str	r1, [r3, #32]
    state->window = &WS(strm)->working_window[0];
    16a8:	e5902020 	ldr	r2, [r0, #32]
    16ac:	e2822c25 	add	r2, r2, #9472	; 0x2500
    16b0:	e282202c 	add	r2, r2, #44	; 0x2c
    16b4:	e5832030 	str	r2, [r3, #48]	; 0x30

    return zlib_inflateReset(strm);
    16b8:	eaffffc9 	b	15e4 <zlib_inflateReset>
}
    16bc:	e3e00001 	mvn	r0, #1
    16c0:	e12fff1e 	bx	lr

000016c4 <zlib_inflate>:
   when flush is set to Z_FINISH, inflate() cannot return Z_OK.  Instead it
   will return Z_BUF_ERROR if it has not reached the end of the stream.
 */

int zlib_inflate(z_streamp strm, int flush)
{
    16c4:	e92d4ff0 	push	{r4, r5, r6, r7, r8, r9, sl, fp, lr}
        {16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15};

    /* Do not check for strm->next_out == NULL here as ppc zImage
       inflates to strm->next_out = 0 */

    if (strm == NULL || strm->state == NULL ||
    16c8:	e2508000 	subs	r8, r0, #0
   when flush is set to Z_FINISH, inflate() cannot return Z_OK.  Instead it
   will return Z_BUF_ERROR if it has not reached the end of the stream.
 */

int zlib_inflate(z_streamp strm, int flush)
{
    16cc:	e24dd03c 	sub	sp, sp, #60	; 0x3c
    16d0:	e58d1020 	str	r1, [sp, #32]
        {16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15};

    /* Do not check for strm->next_out == NULL here as ppc zImage
       inflates to strm->next_out = 0 */

    if (strm == NULL || strm->state == NULL ||
    16d4:	0a00044e 	beq	2814 <zlib_inflate+0x1150>
    16d8:	e598401c 	ldr	r4, [r8, #28]
    16dc:	e3540000 	cmp	r4, #0
    16e0:	0a00044b 	beq	2814 <zlib_inflate+0x1150>
    16e4:	e5983000 	ldr	r3, [r8]
    16e8:	e3530000 	cmp	r3, #0
    16ec:	1a000002 	bne	16fc <zlib_inflate+0x38>
        (strm->next_in == NULL && strm->avail_in != 0))
    16f0:	e5983004 	ldr	r3, [r8, #4]
    16f4:	e3530000 	cmp	r3, #0
    16f8:	1a000445 	bne	2814 <zlib_inflate+0x1150>
        return Z_STREAM_ERROR;

    state = (struct inflate_state *)strm->state;

    if (state->mode == TYPE) state->mode = TYPEDO;      /* skip check */
    16fc:	e5943000 	ldr	r3, [r4]
    LOAD();
    1700:	e5946034 	ldr	r6, [r4, #52]	; 0x34
    1704:	e5945038 	ldr	r5, [r4, #56]	; 0x38
        (strm->next_in == NULL && strm->avail_in != 0))
        return Z_STREAM_ERROR;

    state = (struct inflate_state *)strm->state;

    if (state->mode == TYPE) state->mode = TYPEDO;      /* skip check */
    1708:	e353000b 	cmp	r3, #11
    170c:	03a0300c 	moveq	r3, #12
    1710:	05843000 	streq	r3, [r4]
    LOAD();
    1714:	e598900c 	ldr	r9, [r8, #12]
    1718:	e598c010 	ldr	ip, [r8, #16]
    171c:	e598b000 	ldr	fp, [r8]
    1720:	e58d9018 	str	r9, [sp, #24]
    1724:	e5989004 	ldr	r9, [r8, #4]
    1728:	e58dc014 	str	ip, [sp, #20]
    in = have;
    out = left;
    172c:	e1a0a00c 	mov	sl, ip
    ret = Z_OK;
    1730:	e3a0c000 	mov	ip, #0
    1734:	e58dc01c 	str	ip, [sp, #28]
        return Z_STREAM_ERROR;

    state = (struct inflate_state *)strm->state;

    if (state->mode == TYPE) state->mode = TYPEDO;      /* skip check */
    LOAD();
    1738:	e58d902c 	str	r9, [sp, #44]	; 0x2c
    173c:	e1a07009 	mov	r7, r9
   fixed code decoding.  This returns fixed tables from inffixed.h.
 */
static void zlib_fixedtables(struct inflate_state *state)
{
#   include "inffixed.h"
    state->lencode = lenfix;
    1740:	e59f9f80 	ldr	r9, [pc, #3968]	; 26c8 <zlib_inflate+0x1004>
    1744:	e08f9009 	add	r9, pc, r9
    state->lenbits = 9;
    state->distcode = distfix;
    1748:	e2893e8f 	add	r3, r9, #2288	; 0x8f0
    174c:	e283300c 	add	r3, r3, #12
   fixed code decoding.  This returns fixed tables from inffixed.h.
 */
static void zlib_fixedtables(struct inflate_state *state)
{
#   include "inffixed.h"
    state->lencode = lenfix;
    1750:	e58d9030 	str	r9, [sp, #48]	; 0x30
    state->lenbits = 9;
    state->distcode = distfix;
    1754:	e58d3034 	str	r3, [sp, #52]	; 0x34
    LOAD();
    in = have;
    out = left;
    ret = Z_OK;
    for (;;)
        switch (state->mode) {
    1758:	e5943000 	ldr	r3, [r4]
    175c:	e353001c 	cmp	r3, #28
    1760:	908ff103 	addls	pc, pc, r3, lsl #2
    1764:	ea00042a 	b	2814 <zlib_inflate+0x1150>
    1768:	ea00001d 	b	17e4 <zlib_inflate+0x120>
    176c:	ea000428 	b	2814 <zlib_inflate+0x1150>
    1770:	ea000427 	b	2814 <zlib_inflate+0x1150>
    1774:	ea000426 	b	2814 <zlib_inflate+0x1150>
    1778:	ea000425 	b	2814 <zlib_inflate+0x1150>
    177c:	ea000424 	b	2814 <zlib_inflate+0x1150>
    1780:	ea000423 	b	2814 <zlib_inflate+0x1150>
    1784:	ea000422 	b	2814 <zlib_inflate+0x1150>
    1788:	ea000421 	b	2814 <zlib_inflate+0x1150>
    178c:	ea00004b 	b	18c0 <zlib_inflate+0x1fc>
    1790:	ea000059 	b	18fc <zlib_inflate+0x238>
    1794:	ea00006a 	b	1944 <zlib_inflate+0x280>
    1798:	ea00006c 	b	1950 <zlib_inflate+0x28c>
    179c:	ea00009a 	b	1a0c <zlib_inflate+0x348>
    17a0:	ea0000b1 	b	1a6c <zlib_inflate+0x3a8>
    17a4:	ea0000d0 	b	1aec <zlib_inflate+0x428>
    17a8:	ea0000e9 	b	1b54 <zlib_inflate+0x490>
    17ac:	ea00012b 	b	1c60 <zlib_inflate+0x59c>
    17b0:	ea0001ce 	b	1ef0 <zlib_inflate+0x82c>
    17b4:	ea000227 	b	2058 <zlib_inflate+0x994>
    17b8:	ea00023b 	b	20ac <zlib_inflate+0x9e8>
    17bc:	ea000273 	b	2190 <zlib_inflate+0xacc>
    17c0:	ea000293 	b	2214 <zlib_inflate+0xb50>
    17c4:	ea0002c0 	b	22cc <zlib_inflate+0xc08>
    17c8:	ea0002cc 	b	2300 <zlib_inflate+0xc3c>
    17cc:	ea000410 	b	2814 <zlib_inflate+0x1150>
    17d0:	ea000350 	b	2518 <zlib_inflate+0xe54>
    17d4:	ea00034c 	b	250c <zlib_inflate+0xe48>
    17d8:	eaffffff 	b	17dc <zlib_inflate+0x118>
            goto inf_leave;
        case BAD:
            ret = Z_DATA_ERROR;
            goto inf_leave;
        case MEM:
            return Z_MEM_ERROR;
    17dc:	e3e00003 	mvn	r0, #3
    17e0:	ea00040c 	b	2818 <zlib_inflate+0x1154>
    out = left;
    ret = Z_OK;
    for (;;)
        switch (state->mode) {
        case HEAD:
            if (state->wrap == 0) {
    17e4:	e5943008 	ldr	r3, [r4, #8]
    17e8:	e3530000 	cmp	r3, #0
                state->mode = TYPEDO;
    17ec:	03a0300c 	moveq	r3, #12
    out = left;
    ret = Z_OK;
    for (;;)
        switch (state->mode) {
        case HEAD:
            if (state->wrap == 0) {
    17f0:	0a0002b3 	beq	22c4 <zlib_inflate+0xc00>
                state->mode = TYPEDO;
                break;
            }
            NEEDBITS(16);
    17f4:	e355000f 	cmp	r5, #15
    17f8:	8a000006 	bhi	1818 <zlib_inflate+0x154>
    17fc:	e3570000 	cmp	r7, #0
    1800:	0a000346 	beq	2520 <zlib_inflate+0xe5c>
    1804:	e4db3001 	ldrb	r3, [fp], #1
    1808:	e2477001 	sub	r7, r7, #1
    180c:	e0866513 	add	r6, r6, r3, lsl r5
    1810:	e2855008 	add	r5, r5, #8
    1814:	eafffff6 	b	17f4 <zlib_inflate+0x130>
            if (
                ((BITS(8) << 8) + (hold >> 8)) % 31) {
    1818:	e1a02406 	lsl	r2, r6, #8
    181c:	e3a0301f 	mov	r3, #31
    1820:	e6ff2072 	uxth	r2, r2
    1824:	e0822426 	add	r2, r2, r6, lsr #8
    1828:	e731f312 	udiv	r1, r2, r3
    182c:	e0622193 	mls	r2, r3, r1, r2
            if (state->wrap == 0) {
                state->mode = TYPEDO;
                break;
            }
            NEEDBITS(16);
            if (
    1830:	e3520000 	cmp	r2, #0
                ((BITS(8) << 8) + (hold >> 8)) % 31) {
                strm->msg = (char *)"incorrect header check";
    1834:	159f3e90 	ldrne	r3, [pc, #3728]	; 26cc <zlib_inflate+0x1008>
    1838:	108f3003 	addne	r3, pc, r3
    183c:	1a00026f 	bne	2200 <zlib_inflate+0xb3c>
                state->mode = BAD;
                break;
            }
            if (BITS(4) != Z_DEFLATED) {
    1840:	e206300f 	and	r3, r6, #15
    1844:	e3530008 	cmp	r3, #8
                strm->msg = (char *)"unknown compression method";
    1848:	159f3e80 	ldrne	r3, [pc, #3712]	; 26d0 <zlib_inflate+0x100c>
    184c:	108f3003 	addne	r3, pc, r3
    1850:	1a00026a 	bne	2200 <zlib_inflate+0xb3c>
                state->mode = BAD;
                break;
            }
            DROPBITS(4);
    1854:	e1a06226 	lsr	r6, r6, #4
            len = BITS(4) + 8;
            if (len > state->wbits) {
    1858:	e5943020 	ldr	r3, [r4, #32]
                strm->msg = (char *)"unknown compression method";
                state->mode = BAD;
                break;
            }
            DROPBITS(4);
            len = BITS(4) + 8;
    185c:	e206100f 	and	r1, r6, #15
    1860:	e2811008 	add	r1, r1, #8
            if (len > state->wbits) {
    1864:	e1510003 	cmp	r1, r3
                strm->msg = (char *)"invalid window size";
    1868:	859f3e64 	ldrhi	r3, [pc, #3684]	; 26d4 <zlib_inflate+0x1010>
            if (BITS(4) != Z_DEFLATED) {
                strm->msg = (char *)"unknown compression method";
                state->mode = BAD;
                break;
            }
            DROPBITS(4);
    186c:	82455004 	subhi	r5, r5, #4
            len = BITS(4) + 8;
            if (len > state->wbits) {
                strm->msg = (char *)"invalid window size";
    1870:	808f3003 	addhi	r3, pc, r3
    1874:	8a000261 	bhi	2200 <zlib_inflate+0xb3c>
                state->mode = BAD;
                break;
            }
            state->dmax = 1U << len;
    1878:	e3a03001 	mov	r3, #1
            strm->adler = state->check = zlib_adler32(0L, NULL, 0);
            state->mode = hold & 0x200 ? DICTID : TYPE;
    187c:	e3160c02 	tst	r6, #512	; 0x200
            if (len > state->wbits) {
                strm->msg = (char *)"invalid window size";
                state->mode = BAD;
                break;
            }
            state->dmax = 1U << len;
    1880:	e1a01113 	lsl	r1, r3, r1
            strm->adler = state->check = zlib_adler32(0L, NULL, 0);
    1884:	e5843018 	str	r3, [r4, #24]
            state->mode = hold & 0x200 ? DICTID : TYPE;
            INITBITS();
    1888:	e1a05002 	mov	r5, r2
    188c:	e1a06002 	mov	r6, r2
            if (len > state->wbits) {
                strm->msg = (char *)"invalid window size";
                state->mode = BAD;
                break;
            }
            state->dmax = 1U << len;
    1890:	e5841014 	str	r1, [r4, #20]
            strm->adler = state->check = zlib_adler32(0L, NULL, 0);
    1894:	e5883028 	str	r3, [r8, #40]	; 0x28
            state->mode = hold & 0x200 ? DICTID : TYPE;
    1898:	03a0300b 	moveq	r3, #11
    189c:	13a03009 	movne	r3, #9
    18a0:	e5843000 	str	r3, [r4]
            INITBITS();
            break;
    18a4:	eaffffab 	b	1758 <zlib_inflate+0x94>
        case DICTID:
            NEEDBITS(32);
    18a8:	e3570000 	cmp	r7, #0
    18ac:	0a00031b 	beq	2520 <zlib_inflate+0xe5c>
    18b0:	e4db3001 	ldrb	r3, [fp], #1
    18b4:	e2477001 	sub	r7, r7, #1
    18b8:	e0866513 	add	r6, r6, r3, lsl r5
    18bc:	e2855008 	add	r5, r5, #8
    18c0:	e355001f 	cmp	r5, #31
    18c4:	9afffff7 	bls	18a8 <zlib_inflate+0x1e4>
            strm->adler = state->check = REVERSE(hold);
    18c8:	e1a02c26 	lsr	r2, r6, #24
    18cc:	e1a03426 	lsr	r3, r6, #8
    18d0:	e0822c06 	add	r2, r2, r6, lsl #24
    18d4:	e2033cff 	and	r3, r3, #65280	; 0xff00
    18d8:	e2066cff 	and	r6, r6, #65280	; 0xff00
    18dc:	e0823003 	add	r3, r2, r3
    18e0:	e0836406 	add	r6, r3, r6, lsl #8
            INITBITS();
            state->mode = DICT;
    18e4:	e3a0300a 	mov	r3, #10
            state->mode = hold & 0x200 ? DICTID : TYPE;
            INITBITS();
            break;
        case DICTID:
            NEEDBITS(32);
            strm->adler = state->check = REVERSE(hold);
    18e8:	e5846018 	str	r6, [r4, #24]
    18ec:	e5886028 	str	r6, [r8, #40]	; 0x28
            INITBITS();
    18f0:	e3a06000 	mov	r6, #0
    18f4:	e1a05006 	mov	r5, r6
            state->mode = DICT;
    18f8:	e5843000 	str	r3, [r4]
        case DICT:
            if (state->havedict == 0) {
    18fc:	e594300c 	ldr	r3, [r4, #12]
    1900:	e3530000 	cmp	r3, #0
    1904:	1a000009 	bne	1930 <zlib_inflate+0x26c>
                RESTORE();
    1908:	e59dc018 	ldr	ip, [sp, #24]
    190c:	e588b000 	str	fp, [r8]
                return Z_NEED_DICT;
    1910:	e3a00002 	mov	r0, #2
            strm->adler = state->check = REVERSE(hold);
            INITBITS();
            state->mode = DICT;
        case DICT:
            if (state->havedict == 0) {
                RESTORE();
    1914:	e59d9014 	ldr	r9, [sp, #20]
    1918:	e5887004 	str	r7, [r8, #4]
    191c:	e588c00c 	str	ip, [r8, #12]
    1920:	e5889010 	str	r9, [r8, #16]
    1924:	e5846034 	str	r6, [r4, #52]	; 0x34
    1928:	e5845038 	str	r5, [r4, #56]	; 0x38
                return Z_NEED_DICT;
    192c:	ea0003b9 	b	2818 <zlib_inflate+0x1154>
            }
            strm->adler = state->check = zlib_adler32(0L, NULL, 0);
    1930:	e3a03001 	mov	r3, #1
    1934:	e5843018 	str	r3, [r4, #24]
    1938:	e5883028 	str	r3, [r8, #40]	; 0x28
            state->mode = TYPE;
    193c:	e3a0300b 	mov	r3, #11
    1940:	e5843000 	str	r3, [r4]
        case TYPE:
            if (flush == Z_BLOCK) goto inf_leave;
    1944:	e59dc020 	ldr	ip, [sp, #32]
    1948:	e35c0006 	cmp	ip, #6
    194c:	0a0002f3 	beq	2520 <zlib_inflate+0xe5c>
        case TYPEDO:
            if (state->last) {
    1950:	e5943004 	ldr	r3, [r4, #4]
    1954:	e3530000 	cmp	r3, #0
    1958:	0a00000a 	beq	1988 <zlib_inflate+0x2c4>
                BYTEBITS();
    195c:	e2053007 	and	r3, r5, #7
    1960:	e3c55007 	bic	r5, r5, #7
    1964:	e1a06336 	lsr	r6, r6, r3
                state->mode = CHECK;
    1968:	e3a03018 	mov	r3, #24
    196c:	ea000254 	b	22c4 <zlib_inflate+0xc00>
                break;
            }
            NEEDBITS(3);
    1970:	e3570000 	cmp	r7, #0
    1974:	0a0002e9 	beq	2520 <zlib_inflate+0xe5c>
    1978:	e4db3001 	ldrb	r3, [fp], #1
    197c:	e2477001 	sub	r7, r7, #1
    1980:	e0866513 	add	r6, r6, r3, lsl r5
    1984:	e2855008 	add	r5, r5, #8
    1988:	e3550002 	cmp	r5, #2
    198c:	9afffff7 	bls	1970 <zlib_inflate+0x2ac>
            state->last = BITS(1);
    1990:	e2063001 	and	r3, r6, #1
            DROPBITS(1);
    1994:	e1a060a6 	lsr	r6, r6, #1
                BYTEBITS();
                state->mode = CHECK;
                break;
            }
            NEEDBITS(3);
            state->last = BITS(1);
    1998:	e5843004 	str	r3, [r4, #4]
            DROPBITS(1);
            switch (BITS(2)) {
    199c:	e2063003 	and	r3, r6, #3
    19a0:	e3530002 	cmp	r3, #2
            case 1:                             /* fixed block */
                zlib_fixedtables(state);
                state->mode = LEN;              /* decode codes */
                break;
            case 2:                             /* dynamic block */
                state->mode = TABLE;
    19a4:	03a0300f 	moveq	r3, #15
                break;
            }
            NEEDBITS(3);
            state->last = BITS(1);
            DROPBITS(1);
            switch (BITS(2)) {
    19a8:	0a000013 	beq	19fc <zlib_inflate+0x338>
    19ac:	e3530003 	cmp	r3, #3
    19b0:	0a00000d 	beq	19ec <zlib_inflate+0x328>
    19b4:	e3530001 	cmp	r3, #1
            case 0:                             /* stored block */
                state->mode = STORED;
    19b8:	13a0300d 	movne	r3, #13
                break;
            }
            NEEDBITS(3);
            state->last = BITS(1);
            DROPBITS(1);
            switch (BITS(2)) {
    19bc:	1a00000e 	bne	19fc <zlib_inflate+0x338>
   fixed code decoding.  This returns fixed tables from inffixed.h.
 */
static void zlib_fixedtables(struct inflate_state *state)
{
#   include "inffixed.h"
    state->lencode = lenfix;
    19c0:	e59d9030 	ldr	r9, [sp, #48]	; 0x30
    state->lenbits = 9;
    state->distcode = distfix;
    19c4:	e59dc034 	ldr	ip, [sp, #52]	; 0x34
   fixed code decoding.  This returns fixed tables from inffixed.h.
 */
static void zlib_fixedtables(struct inflate_state *state)
{
#   include "inffixed.h"
    state->lencode = lenfix;
    19c8:	e28930fc 	add	r3, r9, #252	; 0xfc
    state->lenbits = 9;
    state->distcode = distfix;
    19cc:	e584c04c 	str	ip, [r4, #76]	; 0x4c
   fixed code decoding.  This returns fixed tables from inffixed.h.
 */
static void zlib_fixedtables(struct inflate_state *state)
{
#   include "inffixed.h"
    state->lencode = lenfix;
    19d0:	e5843048 	str	r3, [r4, #72]	; 0x48
    state->lenbits = 9;
    19d4:	e3a03009 	mov	r3, #9
    19d8:	e5843050 	str	r3, [r4, #80]	; 0x50
    state->distcode = distfix;
    state->distbits = 5;
    19dc:	e3a03005 	mov	r3, #5
    19e0:	e5843054 	str	r3, [r4, #84]	; 0x54
            case 0:                             /* stored block */
                state->mode = STORED;
                break;
            case 1:                             /* fixed block */
                zlib_fixedtables(state);
                state->mode = LEN;              /* decode codes */
    19e4:	e3a03012 	mov	r3, #18
    19e8:	ea000003 	b	19fc <zlib_inflate+0x338>
                break;
            case 2:                             /* dynamic block */
                state->mode = TABLE;
                break;
            case 3:
                strm->msg = (char *)"invalid block type";
    19ec:	e59f3ce4 	ldr	r3, [pc, #3300]	; 26d8 <zlib_inflate+0x1014>
    19f0:	e08f3003 	add	r3, pc, r3
    19f4:	e5883018 	str	r3, [r8, #24]
                state->mode = BAD;
    19f8:	e3a0301b 	mov	r3, #27
    19fc:	e5843000 	str	r3, [r4]
            }
            DROPBITS(2);
    1a00:	e1a06126 	lsr	r6, r6, #2
    1a04:	e2455003 	sub	r5, r5, #3
            break;
    1a08:	eaffff52 	b	1758 <zlib_inflate+0x94>
        case STORED:
            BYTEBITS();                         /* go to byte boundary */
    1a0c:	e2053007 	and	r3, r5, #7
    1a10:	e3c55007 	bic	r5, r5, #7
    1a14:	e1a06336 	lsr	r6, r6, r3
            NEEDBITS(32);
    1a18:	e355001f 	cmp	r5, #31
    1a1c:	8a000006 	bhi	1a3c <zlib_inflate+0x378>
    1a20:	e3570000 	cmp	r7, #0
    1a24:	0a0002bd 	beq	2520 <zlib_inflate+0xe5c>
    1a28:	e4db3001 	ldrb	r3, [fp], #1
    1a2c:	e2477001 	sub	r7, r7, #1
    1a30:	e0866513 	add	r6, r6, r3, lsl r5
    1a34:	e2855008 	add	r5, r5, #8
    1a38:	eafffff6 	b	1a18 <zlib_inflate+0x354>
            if ((hold & 0xffff) != ((hold >> 16) ^ 0xffff)) {
    1a3c:	e6ff2076 	uxth	r2, r6
    1a40:	e22634ff 	eor	r3, r6, #-16777216	; 0xff000000
    1a44:	e22338ff 	eor	r3, r3, #16711680	; 0xff0000
    1a48:	e1520823 	cmp	r2, r3, lsr #16
                strm->msg = (char *)"invalid stored block lengths";
    1a4c:	159f3c88 	ldrne	r3, [pc, #3208]	; 26dc <zlib_inflate+0x1018>
    1a50:	108f3003 	addne	r3, pc, r3
    1a54:	1a0001e9 	bne	2200 <zlib_inflate+0xb3c>
                state->mode = BAD;
                break;
            }
            state->length = (unsigned)hold & 0xffff;
            INITBITS();
    1a58:	e3a05000 	mov	r5, #0
            state->mode = COPY;
    1a5c:	e3a0300e 	mov	r3, #14
            if ((hold & 0xffff) != ((hold >> 16) ^ 0xffff)) {
                strm->msg = (char *)"invalid stored block lengths";
                state->mode = BAD;
                break;
            }
            state->length = (unsigned)hold & 0xffff;
    1a60:	e584203c 	str	r2, [r4, #60]	; 0x3c
            INITBITS();
    1a64:	e1a06005 	mov	r6, r5
            state->mode = COPY;
    1a68:	e5843000 	str	r3, [r4]
        case COPY:
            copy = state->length;
    1a6c:	e594903c 	ldr	r9, [r4, #60]	; 0x3c
            if (copy) {
    1a70:	e3590000 	cmp	r9, #0
    1a74:	0a00016d 	beq	2030 <zlib_inflate+0x96c>
    1a78:	e59dc014 	ldr	ip, [sp, #20]
    1a7c:	e15c0009 	cmp	ip, r9
    1a80:	31a0900c 	movcc	r9, ip
    1a84:	e1590007 	cmp	r9, r7
    1a88:	21a09007 	movcs	r9, r7
                if (copy > have) copy = have;
                if (copy > left) copy = left;
                if (copy == 0) goto inf_leave;
    1a8c:	e3590000 	cmp	r9, #0
    1a90:	0a0002a2 	beq	2520 <zlib_inflate+0xe5c>
                memcpy(put, next, copy);
    1a94:	e1a0100b 	mov	r1, fp
    1a98:	e1a02009 	mov	r2, r9
    1a9c:	e59d0018 	ldr	r0, [sp, #24]
    1aa0:	eb000469 	bl	2c4c <memcpy>
                have -= copy;
                next += copy;
                left -= copy;
    1aa4:	e59dc014 	ldr	ip, [sp, #20]
            if (copy) {
                if (copy > have) copy = have;
                if (copy > left) copy = left;
                if (copy == 0) goto inf_leave;
                memcpy(put, next, copy);
                have -= copy;
    1aa8:	e0697007 	rsb	r7, r9, r7
                next += copy;
    1aac:	e08bb009 	add	fp, fp, r9
                left -= copy;
                put += copy;
                state->length -= copy;
    1ab0:	e594303c 	ldr	r3, [r4, #60]	; 0x3c
                if (copy > left) copy = left;
                if (copy == 0) goto inf_leave;
                memcpy(put, next, copy);
                have -= copy;
                next += copy;
                left -= copy;
    1ab4:	e069c00c 	rsb	ip, r9, ip
    1ab8:	e58dc014 	str	ip, [sp, #20]
                put += copy;
    1abc:	e59dc018 	ldr	ip, [sp, #24]
    1ac0:	e08cc009 	add	ip, ip, r9
                state->length -= copy;
    1ac4:	e0699003 	rsb	r9, r9, r3
                if (copy == 0) goto inf_leave;
                memcpy(put, next, copy);
                have -= copy;
                next += copy;
                left -= copy;
                put += copy;
    1ac8:	e58dc018 	str	ip, [sp, #24]
                state->length -= copy;
    1acc:	e584903c 	str	r9, [r4, #60]	; 0x3c
                break;
    1ad0:	eaffff20 	b	1758 <zlib_inflate+0x94>
            }
            state->mode = TYPE;
            break;
        case TABLE:
            NEEDBITS(14);
    1ad4:	e3570000 	cmp	r7, #0
    1ad8:	0a000290 	beq	2520 <zlib_inflate+0xe5c>
    1adc:	e4db3001 	ldrb	r3, [fp], #1
    1ae0:	e2477001 	sub	r7, r7, #1
    1ae4:	e0866513 	add	r6, r6, r3, lsl r5
    1ae8:	e2855008 	add	r5, r5, #8
    1aec:	e355000d 	cmp	r5, #13
    1af0:	9afffff7 	bls	1ad4 <zlib_inflate+0x410>
            state->nlen = BITS(5) + 257;
            DROPBITS(5);
            state->ndist = BITS(5) + 1;
            DROPBITS(5);
            state->ncode = BITS(4) + 4;
    1af4:	e7e31556 	ubfx	r1, r6, #10, #4
            }
            state->mode = TYPE;
            break;
        case TABLE:
            NEEDBITS(14);
            state->nlen = BITS(5) + 257;
    1af8:	e206201f 	and	r2, r6, #31
            DROPBITS(5);
            state->ndist = BITS(5) + 1;
            DROPBITS(5);
            state->ncode = BITS(4) + 4;
    1afc:	e2811004 	add	r1, r1, #4
            }
            state->mode = TYPE;
            break;
        case TABLE:
            NEEDBITS(14);
            state->nlen = BITS(5) + 257;
    1b00:	e2822c01 	add	r2, r2, #256	; 0x100
    1b04:	e2822001 	add	r2, r2, #1
            DROPBITS(5);
            state->ndist = BITS(5) + 1;
    1b08:	e7e432d6 	ubfx	r3, r6, #5, #5
            DROPBITS(5);
            state->ncode = BITS(4) + 4;
    1b0c:	e5841058 	str	r1, [r4, #88]	; 0x58
            DROPBITS(4);
#ifndef PKZIP_BUG_WORKAROUND
            if (state->nlen > 286 || state->ndist > 30) {
    1b10:	e300111e 	movw	r1, #286	; 0x11e
            break;
        case TABLE:
            NEEDBITS(14);
            state->nlen = BITS(5) + 257;
            DROPBITS(5);
            state->ndist = BITS(5) + 1;
    1b14:	e2833001 	add	r3, r3, #1
            DROPBITS(5);
            state->ncode = BITS(4) + 4;
            DROPBITS(4);
#ifndef PKZIP_BUG_WORKAROUND
            if (state->nlen > 286 || state->ndist > 30) {
    1b18:	e1520001 	cmp	r2, r1
            }
            state->mode = TYPE;
            break;
        case TABLE:
            NEEDBITS(14);
            state->nlen = BITS(5) + 257;
    1b1c:	e584205c 	str	r2, [r4, #92]	; 0x5c
            DROPBITS(5);
            state->ndist = BITS(5) + 1;
            DROPBITS(5);
            state->ncode = BITS(4) + 4;
            DROPBITS(4);
    1b20:	e1a06726 	lsr	r6, r6, #14
            break;
        case TABLE:
            NEEDBITS(14);
            state->nlen = BITS(5) + 257;
            DROPBITS(5);
            state->ndist = BITS(5) + 1;
    1b24:	e5843060 	str	r3, [r4, #96]	; 0x60
            DROPBITS(5);
            state->ncode = BITS(4) + 4;
            DROPBITS(4);
    1b28:	e245500e 	sub	r5, r5, #14
#ifndef PKZIP_BUG_WORKAROUND
            if (state->nlen > 286 || state->ndist > 30) {
    1b2c:	8a000001 	bhi	1b38 <zlib_inflate+0x474>
    1b30:	e353001e 	cmp	r3, #30
    1b34:	9a000002 	bls	1b44 <zlib_inflate+0x480>
                strm->msg = (char *)"too many length or distance symbols";
    1b38:	e59f3ba0 	ldr	r3, [pc, #2976]	; 26e0 <zlib_inflate+0x101c>
    1b3c:	e08f3003 	add	r3, pc, r3
    1b40:	ea0001ae 	b	2200 <zlib_inflate+0xb3c>
                state->mode = BAD;
                break;
            }
#endif
            state->have = 0;
    1b44:	e3a03000 	mov	r3, #0
    1b48:	e5843064 	str	r3, [r4, #100]	; 0x64
            state->mode = LENLENS;
    1b4c:	e3a03010 	mov	r3, #16
    1b50:	e5843000 	str	r3, [r4]
        case LENLENS:
            while (state->have < state->ncode) {
                NEEDBITS(3);
                state->lens[order[state->have++]] = (unsigned short)BITS(3);
    1b54:	e59f1b88 	ldr	r1, [pc, #2952]	; 26e4 <zlib_inflate+0x1020>
            }
#endif
            state->have = 0;
            state->mode = LENLENS;
        case LENLENS:
            while (state->have < state->ncode) {
    1b58:	e5942058 	ldr	r2, [r4, #88]	; 0x58
                NEEDBITS(3);
                state->lens[order[state->have++]] = (unsigned short)BITS(3);
    1b5c:	e08f1001 	add	r1, pc, r1
            }
#endif
            state->have = 0;
            state->mode = LENLENS;
        case LENLENS:
            while (state->have < state->ncode) {
    1b60:	e5943064 	ldr	r3, [r4, #100]	; 0x64
    1b64:	e1530002 	cmp	r3, r2
    1b68:	2a000014 	bcs	1bc0 <zlib_inflate+0x4fc>
                NEEDBITS(3);
    1b6c:	e3550002 	cmp	r5, #2
    1b70:	8a000006 	bhi	1b90 <zlib_inflate+0x4cc>
    1b74:	e3570000 	cmp	r7, #0
    1b78:	0a000268 	beq	2520 <zlib_inflate+0xe5c>
    1b7c:	e4db0001 	ldrb	r0, [fp], #1
    1b80:	e2477001 	sub	r7, r7, #1
    1b84:	e0866510 	add	r6, r6, r0, lsl r5
    1b88:	e2855008 	add	r5, r5, #8
    1b8c:	eafffff6 	b	1b6c <zlib_inflate+0x4a8>
                state->lens[order[state->have++]] = (unsigned short)BITS(3);
    1b90:	e2830001 	add	r0, r3, #1
    1b94:	e0813083 	add	r3, r1, r3, lsl #1
                DROPBITS(3);
    1b98:	e2455003 	sub	r5, r5, #3
            state->have = 0;
            state->mode = LENLENS;
        case LENLENS:
            while (state->have < state->ncode) {
                NEEDBITS(3);
                state->lens[order[state->have++]] = (unsigned short)BITS(3);
    1b9c:	e2833e97 	add	r3, r3, #2416	; 0x970
    1ba0:	e5840064 	str	r0, [r4, #100]	; 0x64
    1ba4:	e2060007 	and	r0, r6, #7
    1ba8:	e283300c 	add	r3, r3, #12
                DROPBITS(3);
    1bac:	e1a061a6 	lsr	r6, r6, #3
            state->have = 0;
            state->mode = LENLENS;
        case LENLENS:
            while (state->have < state->ncode) {
                NEEDBITS(3);
                state->lens[order[state->have++]] = (unsigned short)BITS(3);
    1bb0:	e1d330b0 	ldrh	r3, [r3]
    1bb4:	e0843083 	add	r3, r4, r3, lsl #1
    1bb8:	e1c306bc 	strh	r0, [r3, #108]	; 0x6c
    1bbc:	eaffffe7 	b	1b60 <zlib_inflate+0x49c>
                DROPBITS(3);
            }
            while (state->have < 19)
                state->lens[order[state->have++]] = 0;
    1bc0:	e59f2b20 	ldr	r2, [pc, #2848]	; 26e8 <zlib_inflate+0x1024>
    1bc4:	e3a01000 	mov	r1, #0
    1bc8:	e08f2002 	add	r2, pc, r2
            while (state->have < state->ncode) {
                NEEDBITS(3);
                state->lens[order[state->have++]] = (unsigned short)BITS(3);
                DROPBITS(3);
            }
            while (state->have < 19)
    1bcc:	e5943064 	ldr	r3, [r4, #100]	; 0x64
    1bd0:	e3530012 	cmp	r3, #18
    1bd4:	8a000009 	bhi	1c00 <zlib_inflate+0x53c>
                state->lens[order[state->have++]] = 0;
    1bd8:	e2830001 	add	r0, r3, #1
    1bdc:	e0823083 	add	r3, r2, r3, lsl #1
    1be0:	e2833e97 	add	r3, r3, #2416	; 0x970
    1be4:	e5840064 	str	r0, [r4, #100]	; 0x64
    1be8:	e283300c 	add	r3, r3, #12
    1bec:	e1d330b0 	ldrh	r3, [r3]
    1bf0:	e2833034 	add	r3, r3, #52	; 0x34
    1bf4:	e0843083 	add	r3, r4, r3, lsl #1
    1bf8:	e1c310b4 	strh	r1, [r3, #4]
    1bfc:	eafffff2 	b	1bcc <zlib_inflate+0x508>
            state->next = state->codes;
    1c00:	e2843e52 	add	r3, r4, #1312	; 0x520
            state->lencode = (code const *)(state->next);
            state->lenbits = 7;
            ret = zlib_inflate_table(CODES, state->lens, 19, &(state->next),
    1c04:	e3a00000 	mov	r0, #0
                state->lens[order[state->have++]] = (unsigned short)BITS(3);
                DROPBITS(3);
            }
            while (state->have < 19)
                state->lens[order[state->have++]] = 0;
            state->next = state->codes;
    1c08:	e283300c 	add	r3, r3, #12
            state->lencode = (code const *)(state->next);
            state->lenbits = 7;
            ret = zlib_inflate_table(CODES, state->lens, 19, &(state->next),
    1c0c:	e284106c 	add	r1, r4, #108	; 0x6c
    1c10:	e3a02013 	mov	r2, #19
                state->lens[order[state->have++]] = (unsigned short)BITS(3);
                DROPBITS(3);
            }
            while (state->have < 19)
                state->lens[order[state->have++]] = 0;
            state->next = state->codes;
    1c14:	e5843068 	str	r3, [r4, #104]	; 0x68
            state->lencode = (code const *)(state->next);
    1c18:	e5843048 	str	r3, [r4, #72]	; 0x48
            state->lenbits = 7;
    1c1c:	e3a03007 	mov	r3, #7
    1c20:	e5843050 	str	r3, [r4, #80]	; 0x50
            ret = zlib_inflate_table(CODES, state->lens, 19, &(state->next),
    1c24:	e2843050 	add	r3, r4, #80	; 0x50
    1c28:	e58d3000 	str	r3, [sp]
                                &(state->lenbits), state->work);
    1c2c:	e2843fbb 	add	r3, r4, #748	; 0x2ec
            while (state->have < 19)
                state->lens[order[state->have++]] = 0;
            state->next = state->codes;
            state->lencode = (code const *)(state->next);
            state->lenbits = 7;
            ret = zlib_inflate_table(CODES, state->lens, 19, &(state->next),
    1c30:	e58d3004 	str	r3, [sp, #4]
    1c34:	e2843068 	add	r3, r4, #104	; 0x68
    1c38:	ebfffba7 	bl	adc <zlib_inflate_table>
                                &(state->lenbits), state->work);
            if (ret) {
    1c3c:	e3500000 	cmp	r0, #0
    1c40:	e58d001c 	str	r0, [sp, #28]
                strm->msg = (char *)"invalid code lengths set";
    1c44:	159f3aa0 	ldrne	r3, [pc, #2720]	; 26ec <zlib_inflate+0x1028>
    1c48:	108f3003 	addne	r3, pc, r3
    1c4c:	1a00016b 	bne	2200 <zlib_inflate+0xb3c>
                state->mode = BAD;
                break;
            }
            state->have = 0;
    1c50:	e59d301c 	ldr	r3, [sp, #28]
    1c54:	e5843064 	str	r3, [r4, #100]	; 0x64
            state->mode = CODELENS;
    1c58:	e3a03011 	mov	r3, #17
    1c5c:	e5843000 	str	r3, [r4]
        case CODELENS:
            while (state->have < state->nlen + state->ndist) {
    1c60:	e5940060 	ldr	r0, [r4, #96]	; 0x60
    1c64:	e594305c 	ldr	r3, [r4, #92]	; 0x5c
    1c68:	e0800003 	add	r0, r0, r3
    1c6c:	e5942064 	ldr	r2, [r4, #100]	; 0x64
    1c70:	e1520000 	cmp	r2, r0
    1c74:	2a000070 	bcs	1e3c <zlib_inflate+0x778>
                for (;;) {
                    this = state->lencode[BITS(state->lenbits)];
    1c78:	e5949050 	ldr	r9, [r4, #80]	; 0x50
    1c7c:	e3a03001 	mov	r3, #1
    1c80:	e594c048 	ldr	ip, [r4, #72]	; 0x48
    1c84:	e1a09913 	lsl	r9, r3, r9
    1c88:	e2499001 	sub	r9, r9, #1
    1c8c:	e0061009 	and	r1, r6, r9
    1c90:	e08c1101 	add	r1, ip, r1, lsl #2
    1c94:	e5d13001 	ldrb	r3, [r1, #1]
    1c98:	e1d110b2 	ldrh	r1, [r1, #2]
                    if ((unsigned)(this.bits) <= bits) break;
    1c9c:	e1530005 	cmp	r3, r5
    1ca0:	9a000006 	bls	1cc0 <zlib_inflate+0x5fc>
                    PULLBYTE();
    1ca4:	e3570000 	cmp	r7, #0
    1ca8:	0a00021c 	beq	2520 <zlib_inflate+0xe5c>
    1cac:	e4db3001 	ldrb	r3, [fp], #1
    1cb0:	e2477001 	sub	r7, r7, #1
    1cb4:	e0866513 	add	r6, r6, r3, lsl r5
    1cb8:	e2855008 	add	r5, r5, #8
                }
    1cbc:	eafffff2 	b	1c8c <zlib_inflate+0x5c8>
                if (this.val < 16) {
    1cc0:	e351000f 	cmp	r1, #15
    1cc4:	8a00000f 	bhi	1d08 <zlib_inflate+0x644>
                    NEEDBITS(this.bits);
    1cc8:	e1550003 	cmp	r5, r3
    1ccc:	2a000006 	bcs	1cec <zlib_inflate+0x628>
    1cd0:	e3570000 	cmp	r7, #0
    1cd4:	0a000211 	beq	2520 <zlib_inflate+0xe5c>
    1cd8:	e4dbc001 	ldrb	ip, [fp], #1
    1cdc:	e2477001 	sub	r7, r7, #1
    1ce0:	e086651c 	add	r6, r6, ip, lsl r5
    1ce4:	e2855008 	add	r5, r5, #8
    1ce8:	eafffff6 	b	1cc8 <zlib_inflate+0x604>
                    DROPBITS(this.bits);
    1cec:	e1a06336 	lsr	r6, r6, r3
    1cf0:	e0635005 	rsb	r5, r3, r5
                    state->lens[state->have++] = this.val;
    1cf4:	e2823001 	add	r3, r2, #1
    1cf8:	e0842082 	add	r2, r4, r2, lsl #1
    1cfc:	e5843064 	str	r3, [r4, #100]	; 0x64
    1d00:	e1c216bc 	strh	r1, [r2, #108]	; 0x6c
    1d04:	eaffffd8 	b	1c6c <zlib_inflate+0x5a8>
                }
                else {
                    if (this.val == 16) {
    1d08:	e3510010 	cmp	r1, #16
                        NEEDBITS(this.bits + 2);
    1d0c:	02831002 	addeq	r1, r3, #2
                    NEEDBITS(this.bits);
                    DROPBITS(this.bits);
                    state->lens[state->have++] = this.val;
                }
                else {
                    if (this.val == 16) {
    1d10:	1a000015 	bne	1d6c <zlib_inflate+0x6a8>
                        NEEDBITS(this.bits + 2);
    1d14:	e1550001 	cmp	r5, r1
    1d18:	2a000006 	bcs	1d38 <zlib_inflate+0x674>
    1d1c:	e3570000 	cmp	r7, #0
    1d20:	0a0001fe 	beq	2520 <zlib_inflate+0xe5c>
    1d24:	e4dbc001 	ldrb	ip, [fp], #1
    1d28:	e2477001 	sub	r7, r7, #1
    1d2c:	e086651c 	add	r6, r6, ip, lsl r5
    1d30:	e2855008 	add	r5, r5, #8
    1d34:	eafffff6 	b	1d14 <zlib_inflate+0x650>
                        DROPBITS(this.bits);
                        if (state->have == 0) {
    1d38:	e3520000 	cmp	r2, #0
                    state->lens[state->have++] = this.val;
                }
                else {
                    if (this.val == 16) {
                        NEEDBITS(this.bits + 2);
                        DROPBITS(this.bits);
    1d3c:	e1a06336 	lsr	r6, r6, r3
    1d40:	e0635005 	rsb	r5, r3, r5
                        if (state->have == 0) {
                            strm->msg = (char *)"invalid bit length repeat";
    1d44:	059f39a4 	ldreq	r3, [pc, #2468]	; 26f0 <zlib_inflate+0x102c>
    1d48:	008f3003 	addeq	r3, pc, r3
    1d4c:	0a00002e 	beq	1e0c <zlib_inflate+0x748>
                            state->mode = BAD;
                            break;
                        }
                        len = state->lens[state->have - 1];
    1d50:	e0843082 	add	r3, r4, r2, lsl #1
                        copy = 3 + BITS(2);
    1d54:	e2061003 	and	r1, r6, #3
    1d58:	e2811003 	add	r1, r1, #3
                        if (state->have == 0) {
                            strm->msg = (char *)"invalid bit length repeat";
                            state->mode = BAD;
                            break;
                        }
                        len = state->lens[state->have - 1];
    1d5c:	e1d336ba 	ldrh	r3, [r3, #106]	; 0x6a
                        copy = 3 + BITS(2);
                        DROPBITS(2);
    1d60:	e1a06126 	lsr	r6, r6, #2
    1d64:	e2455002 	sub	r5, r5, #2
    1d68:	ea000022 	b	1df8 <zlib_inflate+0x734>
                    }
                    else if (this.val == 17) {
    1d6c:	e3510011 	cmp	r1, #17
                        len = 0;
                        copy = 3 + BITS(3);
                        DROPBITS(3);
                    }
                    else {
                        NEEDBITS(this.bits + 7);
    1d70:	12831007 	addne	r1, r3, #7
                        len = state->lens[state->have - 1];
                        copy = 3 + BITS(2);
                        DROPBITS(2);
                    }
                    else if (this.val == 17) {
                        NEEDBITS(this.bits + 3);
    1d74:	02831003 	addeq	r1, r3, #3
                        }
                        len = state->lens[state->have - 1];
                        copy = 3 + BITS(2);
                        DROPBITS(2);
                    }
                    else if (this.val == 17) {
    1d78:	1a000014 	bne	1dd0 <zlib_inflate+0x70c>
                        NEEDBITS(this.bits + 3);
    1d7c:	e1550001 	cmp	r5, r1
    1d80:	2a000006 	bcs	1da0 <zlib_inflate+0x6dc>
    1d84:	e3570000 	cmp	r7, #0
    1d88:	0a0001e4 	beq	2520 <zlib_inflate+0xe5c>
    1d8c:	e4dbc001 	ldrb	ip, [fp], #1
    1d90:	e2477001 	sub	r7, r7, #1
    1d94:	e086651c 	add	r6, r6, ip, lsl r5
    1d98:	e2855008 	add	r5, r5, #8
    1d9c:	eafffff6 	b	1d7c <zlib_inflate+0x6b8>
                        DROPBITS(this.bits);
    1da0:	e1a06336 	lsr	r6, r6, r3
    1da4:	e3e0c002 	mvn	ip, #2
                        len = 0;
                        copy = 3 + BITS(3);
    1da8:	e2061007 	and	r1, r6, #7
                        DROPBITS(3);
    1dac:	e1a061a6 	lsr	r6, r6, #3
                    }
                    else if (this.val == 17) {
                        NEEDBITS(this.bits + 3);
                        DROPBITS(this.bits);
                        len = 0;
                        copy = 3 + BITS(3);
    1db0:	e2811003 	add	r1, r1, #3
    1db4:	ea00000c 	b	1dec <zlib_inflate+0x728>
                        DROPBITS(3);
                    }
                    else {
                        NEEDBITS(this.bits + 7);
    1db8:	e3570000 	cmp	r7, #0
    1dbc:	0a0001d7 	beq	2520 <zlib_inflate+0xe5c>
    1dc0:	e4dbc001 	ldrb	ip, [fp], #1
    1dc4:	e2477001 	sub	r7, r7, #1
    1dc8:	e086651c 	add	r6, r6, ip, lsl r5
    1dcc:	e2855008 	add	r5, r5, #8
    1dd0:	e1550001 	cmp	r5, r1
    1dd4:	3afffff7 	bcc	1db8 <zlib_inflate+0x6f4>
                        DROPBITS(this.bits);
    1dd8:	e1a06336 	lsr	r6, r6, r3
    1ddc:	e3e0c006 	mvn	ip, #6
                        len = 0;
                        copy = 11 + BITS(7);
    1de0:	e206107f 	and	r1, r6, #127	; 0x7f
                        DROPBITS(7);
    1de4:	e1a063a6 	lsr	r6, r6, #7
                    }
                    else {
                        NEEDBITS(this.bits + 7);
                        DROPBITS(this.bits);
                        len = 0;
                        copy = 11 + BITS(7);
    1de8:	e281100b 	add	r1, r1, #11
                        copy = 3 + BITS(3);
                        DROPBITS(3);
                    }
                    else {
                        NEEDBITS(this.bits + 7);
                        DROPBITS(this.bits);
    1dec:	e063c00c 	rsb	ip, r3, ip
                        len = 0;
    1df0:	e3a03000 	mov	r3, #0
                        copy = 11 + BITS(7);
                        DROPBITS(7);
    1df4:	e085500c 	add	r5, r5, ip
                    }
                    if (state->have + copy > state->nlen + state->ndist) {
    1df8:	e0812002 	add	r2, r1, r2
    1dfc:	e1520000 	cmp	r2, r0
    1e00:	9a000005 	bls	1e1c <zlib_inflate+0x758>
                        strm->msg = (char *)"invalid bit length repeat";
    1e04:	e59f38e8 	ldr	r3, [pc, #2280]	; 26f4 <zlib_inflate+0x1030>
    1e08:	e08f3003 	add	r3, pc, r3
    1e0c:	e5883018 	str	r3, [r8, #24]
                        state->mode = BAD;
    1e10:	e3a0301b 	mov	r3, #27
    1e14:	e5843000 	str	r3, [r4]
                        break;
    1e18:	ea000007 	b	1e3c <zlib_inflate+0x778>
                    }
                    while (copy--)
    1e1c:	e2511001 	subs	r1, r1, #1
    1e20:	3affff91 	bcc	1c6c <zlib_inflate+0x5a8>
                        state->lens[state->have++] = (unsigned short)len;
    1e24:	e5942064 	ldr	r2, [r4, #100]	; 0x64
    1e28:	e282c001 	add	ip, r2, #1
    1e2c:	e0842082 	add	r2, r4, r2, lsl #1
    1e30:	e584c064 	str	ip, [r4, #100]	; 0x64
    1e34:	e1c236bc 	strh	r3, [r2, #108]	; 0x6c
    1e38:	eafffff7 	b	1e1c <zlib_inflate+0x758>
                }
            }

            /* handle error breaks in while */
            if (state->mode == BAD) break;
    1e3c:	e5943000 	ldr	r3, [r4]
    1e40:	e353001b 	cmp	r3, #27
    1e44:	0afffe43 	beq	1758 <zlib_inflate+0x94>

            /* build code tables */
            state->next = state->codes;
    1e48:	e2843e52 	add	r3, r4, #1312	; 0x520
            state->lencode = (code const *)(state->next);
            state->lenbits = 9;
            ret = zlib_inflate_table(LENS, state->lens, state->nlen, &(state->next),
                                &(state->lenbits), state->work);
    1e4c:	e284cfbb 	add	ip, r4, #748	; 0x2ec

            /* handle error breaks in while */
            if (state->mode == BAD) break;

            /* build code tables */
            state->next = state->codes;
    1e50:	e283300c 	add	r3, r3, #12
            state->lencode = (code const *)(state->next);
            state->lenbits = 9;
            ret = zlib_inflate_table(LENS, state->lens, state->nlen, &(state->next),
    1e54:	e2849068 	add	r9, r4, #104	; 0x68
    1e58:	e3a00001 	mov	r0, #1
    1e5c:	e284106c 	add	r1, r4, #108	; 0x6c

            /* handle error breaks in while */
            if (state->mode == BAD) break;

            /* build code tables */
            state->next = state->codes;
    1e60:	e5843068 	str	r3, [r4, #104]	; 0x68
            state->lencode = (code const *)(state->next);
    1e64:	e5843048 	str	r3, [r4, #72]	; 0x48
            state->lenbits = 9;
    1e68:	e3a03009 	mov	r3, #9
    1e6c:	e5843050 	str	r3, [r4, #80]	; 0x50
            ret = zlib_inflate_table(LENS, state->lens, state->nlen, &(state->next),
    1e70:	e2843050 	add	r3, r4, #80	; 0x50
    1e74:	e88d1008 	stm	sp, {r3, ip}
    1e78:	e1a03009 	mov	r3, r9
    1e7c:	e594205c 	ldr	r2, [r4, #92]	; 0x5c
    1e80:	e58dc010 	str	ip, [sp, #16]
    1e84:	ebfffb14 	bl	adc <zlib_inflate_table>
                                &(state->lenbits), state->work);
            if (ret) {
    1e88:	e3500000 	cmp	r0, #0
    1e8c:	e59dc010 	ldr	ip, [sp, #16]
    1e90:	e58d001c 	str	r0, [sp, #28]
                strm->msg = (char *)"invalid literal/lengths set";
    1e94:	159f385c 	ldrne	r3, [pc, #2140]	; 26f8 <zlib_inflate+0x1034>
    1e98:	108f3003 	addne	r3, pc, r3
    1e9c:	1a0000d7 	bne	2200 <zlib_inflate+0xb3c>
                state->mode = BAD;
                break;
            }
            state->distcode = (code const *)(state->next);
    1ea0:	e5943068 	ldr	r3, [r4, #104]	; 0x68
            state->distbits = 6;
            ret = zlib_inflate_table(DISTS, state->lens + state->nlen, state->ndist,
    1ea4:	e3a00002 	mov	r0, #2
    1ea8:	e594105c 	ldr	r1, [r4, #92]	; 0x5c
            if (ret) {
                strm->msg = (char *)"invalid literal/lengths set";
                state->mode = BAD;
                break;
            }
            state->distcode = (code const *)(state->next);
    1eac:	e584304c 	str	r3, [r4, #76]	; 0x4c
            state->distbits = 6;
    1eb0:	e3a03006 	mov	r3, #6
            ret = zlib_inflate_table(DISTS, state->lens + state->nlen, state->ndist,
    1eb4:	e0841081 	add	r1, r4, r1, lsl #1
                strm->msg = (char *)"invalid literal/lengths set";
                state->mode = BAD;
                break;
            }
            state->distcode = (code const *)(state->next);
            state->distbits = 6;
    1eb8:	e5843054 	str	r3, [r4, #84]	; 0x54
            ret = zlib_inflate_table(DISTS, state->lens + state->nlen, state->ndist,
    1ebc:	e2843054 	add	r3, r4, #84	; 0x54
    1ec0:	e281106c 	add	r1, r1, #108	; 0x6c
    1ec4:	e88d1008 	stm	sp, {r3, ip}
    1ec8:	e1a03009 	mov	r3, r9
    1ecc:	e5942060 	ldr	r2, [r4, #96]	; 0x60
    1ed0:	ebfffb01 	bl	adc <zlib_inflate_table>
                            &(state->next), &(state->distbits), state->work);
            if (ret) {
    1ed4:	e3500000 	cmp	r0, #0
    1ed8:	e58d001c 	str	r0, [sp, #28]
                strm->msg = (char *)"invalid distances set";
    1edc:	159f3818 	ldrne	r3, [pc, #2072]	; 26fc <zlib_inflate+0x1038>
    1ee0:	108f3003 	addne	r3, pc, r3
    1ee4:	1a0000c5 	bne	2200 <zlib_inflate+0xb3c>
                state->mode = BAD;
                break;
            }
            state->mode = LEN;
    1ee8:	e3a03012 	mov	r3, #18
    1eec:	e5843000 	str	r3, [r4]
        case LEN:
            if (have >= 6 && left >= 258) {
    1ef0:	e59d9014 	ldr	r9, [sp, #20]
    1ef4:	e3003101 	movw	r3, #257	; 0x101
    1ef8:	e3570005 	cmp	r7, #5
    1efc:	81590003 	cmphi	r9, r3
    1f00:	9a000012 	bls	1f50 <zlib_inflate+0x88c>
                RESTORE();
    1f04:	e59dc018 	ldr	ip, [sp, #24]
    1f08:	e5889010 	str	r9, [r8, #16]
                inflate_fast(strm, out);
    1f0c:	e1a00008 	mov	r0, r8
                break;
            }
            state->mode = LEN;
        case LEN:
            if (have >= 6 && left >= 258) {
                RESTORE();
    1f10:	e588b000 	str	fp, [r8]
                inflate_fast(strm, out);
    1f14:	e1a0100a 	mov	r1, sl
                break;
            }
            state->mode = LEN;
        case LEN:
            if (have >= 6 && left >= 258) {
                RESTORE();
    1f18:	e5887004 	str	r7, [r8, #4]
    1f1c:	e588c00c 	str	ip, [r8, #12]
    1f20:	e5846034 	str	r6, [r4, #52]	; 0x34
    1f24:	e5845038 	str	r5, [r4, #56]	; 0x38
                inflate_fast(strm, out);
    1f28:	ebfffc4a 	bl	1058 <inflate_fast>
                LOAD();
    1f2c:	e598900c 	ldr	r9, [r8, #12]
    1f30:	e598c010 	ldr	ip, [r8, #16]
    1f34:	e598b000 	ldr	fp, [r8]
    1f38:	e5987004 	ldr	r7, [r8, #4]
    1f3c:	e58d9018 	str	r9, [sp, #24]
    1f40:	e5946034 	ldr	r6, [r4, #52]	; 0x34
    1f44:	e58dc014 	str	ip, [sp, #20]
    1f48:	e5945038 	ldr	r5, [r4, #56]	; 0x38
                break;
    1f4c:	eafffe01 	b	1758 <zlib_inflate+0x94>
            }
            for (;;) {
                this = state->lencode[BITS(state->lenbits)];
    1f50:	e5943050 	ldr	r3, [r4, #80]	; 0x50
    1f54:	e3e09000 	mvn	r9, #0
    1f58:	e5940048 	ldr	r0, [r4, #72]	; 0x48
    1f5c:	e1e09319 	mvn	r9, r9, lsl r3
    1f60:	e0063009 	and	r3, r6, r9
    1f64:	e0801103 	add	r1, r0, r3, lsl #2
    1f68:	e7d03103 	ldrb	r3, [r0, r3, lsl #2]
    1f6c:	e5d12001 	ldrb	r2, [r1, #1]
    1f70:	e1d1c0b2 	ldrh	ip, [r1, #2]
                if ((unsigned)(this.bits) <= bits) break;
    1f74:	e1520005 	cmp	r2, r5
    1f78:	e1a01002 	mov	r1, r2
    1f7c:	9a000006 	bls	1f9c <zlib_inflate+0x8d8>
                PULLBYTE();
    1f80:	e3570000 	cmp	r7, #0
    1f84:	0a000165 	beq	2520 <zlib_inflate+0xe5c>
    1f88:	e4db3001 	ldrb	r3, [fp], #1
    1f8c:	e2477001 	sub	r7, r7, #1
    1f90:	e0866513 	add	r6, r6, r3, lsl r5
    1f94:	e2855008 	add	r5, r5, #8
            }
    1f98:	eafffff0 	b	1f60 <zlib_inflate+0x89c>
            if (this.op && (this.op & 0xf0) == 0) {
    1f9c:	e3530000 	cmp	r3, #0
                inflate_fast(strm, out);
                LOAD();
                break;
            }
            for (;;) {
                this = state->lencode[BITS(state->lenbits)];
    1fa0:	e58dc024 	str	ip, [sp, #36]	; 0x24
                if ((unsigned)(this.bits) <= bits) break;
                PULLBYTE();
            }
            if (this.op && (this.op & 0xf0) == 0) {
    1fa4:	0a000019 	beq	2010 <zlib_inflate+0x94c>
    1fa8:	e31300f0 	tst	r3, #240	; 0xf0
    1fac:	1a000017 	bne	2010 <zlib_inflate+0x94c>
                last = this;
                for (;;) {
                    this = state->lencode[last.val +
                            (BITS(last.bits + last.op) >> last.bits)];
    1fb0:	e0823003 	add	r3, r2, r3
    1fb4:	e3e09000 	mvn	r9, #0
    1fb8:	e1e09319 	mvn	r9, r9, lsl r3
    1fbc:	e58d900c 	str	r9, [sp, #12]
    1fc0:	e59d200c 	ldr	r2, [sp, #12]
                PULLBYTE();
            }
            if (this.op && (this.op & 0xf0) == 0) {
                last = this;
                for (;;) {
                    this = state->lencode[last.val +
    1fc4:	e59d9024 	ldr	r9, [sp, #36]	; 0x24
                            (BITS(last.bits + last.op) >> last.bits)];
    1fc8:	e0063002 	and	r3, r6, r2
                PULLBYTE();
            }
            if (this.op && (this.op & 0xf0) == 0) {
                last = this;
                for (;;) {
                    this = state->lencode[last.val +
    1fcc:	e0893133 	add	r3, r9, r3, lsr r1
    1fd0:	e080c103 	add	ip, r0, r3, lsl #2
    1fd4:	e7d03103 	ldrb	r3, [r0, r3, lsl #2]
    1fd8:	e5dc2001 	ldrb	r2, [ip, #1]
    1fdc:	e1dcc0b2 	ldrh	ip, [ip, #2]
                            (BITS(last.bits + last.op) >> last.bits)];
                    if ((unsigned)(last.bits + this.bits) <= bits) break;
    1fe0:	e0819002 	add	r9, r1, r2
    1fe4:	e1590005 	cmp	r9, r5
    1fe8:	9a000006 	bls	2008 <zlib_inflate+0x944>
                    PULLBYTE();
    1fec:	e3570000 	cmp	r7, #0
    1ff0:	0a00014a 	beq	2520 <zlib_inflate+0xe5c>
    1ff4:	e4db3001 	ldrb	r3, [fp], #1
    1ff8:	e2477001 	sub	r7, r7, #1
    1ffc:	e0866513 	add	r6, r6, r3, lsl r5
    2000:	e2855008 	add	r5, r5, #8
                }
    2004:	eaffffed 	b	1fc0 <zlib_inflate+0x8fc>
                DROPBITS(last.bits);
    2008:	e1a06136 	lsr	r6, r6, r1
    200c:	e0615005 	rsb	r5, r1, r5
            }
            DROPBITS(this.bits);
            state->length = (unsigned)this.val;
            if ((int)(this.op) == 0) {
    2010:	e3530000 	cmp	r3, #0
                    if ((unsigned)(last.bits + this.bits) <= bits) break;
                    PULLBYTE();
                }
                DROPBITS(last.bits);
            }
            DROPBITS(this.bits);
    2014:	e1a06236 	lsr	r6, r6, r2
            state->length = (unsigned)this.val;
    2018:	e584c03c 	str	ip, [r4, #60]	; 0x3c
                    if ((unsigned)(last.bits + this.bits) <= bits) break;
                    PULLBYTE();
                }
                DROPBITS(last.bits);
            }
            DROPBITS(this.bits);
    201c:	e0625005 	rsb	r5, r2, r5
            state->length = (unsigned)this.val;
            if ((int)(this.op) == 0) {
                state->mode = LIT;
    2020:	03a03017 	moveq	r3, #23
                }
                DROPBITS(last.bits);
            }
            DROPBITS(this.bits);
            state->length = (unsigned)this.val;
            if ((int)(this.op) == 0) {
    2024:	0a0000a6 	beq	22c4 <zlib_inflate+0xc00>
                state->mode = LIT;
                break;
            }
            if (this.op & 32) {
    2028:	e3130020 	tst	r3, #32
    202c:	0a000001 	beq	2038 <zlib_inflate+0x974>
                state->mode = TYPE;
    2030:	e3a0300b 	mov	r3, #11
    2034:	ea0000a2 	b	22c4 <zlib_inflate+0xc00>
                break;
            }
            if (this.op & 64) {
    2038:	e3130040 	tst	r3, #64	; 0x40
                strm->msg = (char *)"invalid literal/length code";
    203c:	159f36bc 	ldrne	r3, [pc, #1724]	; 2700 <zlib_inflate+0x103c>
    2040:	108f3003 	addne	r3, pc, r3
    2044:	1a00006d 	bne	2200 <zlib_inflate+0xb3c>
                state->mode = BAD;
                break;
            }
            state->extra = (unsigned)(this.op) & 15;
    2048:	e203300f 	and	r3, r3, #15
    204c:	e5843044 	str	r3, [r4, #68]	; 0x44
            state->mode = LENEXT;
    2050:	e3a03013 	mov	r3, #19
    2054:	e5843000 	str	r3, [r4]
        case LENEXT:
            if (state->extra) {
    2058:	e5943044 	ldr	r3, [r4, #68]	; 0x44
    205c:	e3530000 	cmp	r3, #0
    2060:	0a00000f 	beq	20a4 <zlib_inflate+0x9e0>
                NEEDBITS(state->extra);
    2064:	e1550003 	cmp	r5, r3
    2068:	2a000006 	bcs	2088 <zlib_inflate+0x9c4>
    206c:	e3570000 	cmp	r7, #0
    2070:	0a00012a 	beq	2520 <zlib_inflate+0xe5c>
    2074:	e4db2001 	ldrb	r2, [fp], #1
    2078:	e2477001 	sub	r7, r7, #1
    207c:	e0866512 	add	r6, r6, r2, lsl r5
    2080:	e2855008 	add	r5, r5, #8
    2084:	eafffff6 	b	2064 <zlib_inflate+0x9a0>
                state->length += BITS(state->extra);
    2088:	e594103c 	ldr	r1, [r4, #60]	; 0x3c
    208c:	e3e02000 	mvn	r2, #0
                DROPBITS(state->extra);
    2090:	e0635005 	rsb	r5, r3, r5
            state->extra = (unsigned)(this.op) & 15;
            state->mode = LENEXT;
        case LENEXT:
            if (state->extra) {
                NEEDBITS(state->extra);
                state->length += BITS(state->extra);
    2094:	e1c62312 	bic	r2, r6, r2, lsl r3
                DROPBITS(state->extra);
    2098:	e1a06336 	lsr	r6, r6, r3
            state->extra = (unsigned)(this.op) & 15;
            state->mode = LENEXT;
        case LENEXT:
            if (state->extra) {
                NEEDBITS(state->extra);
                state->length += BITS(state->extra);
    209c:	e0812002 	add	r2, r1, r2
    20a0:	e584203c 	str	r2, [r4, #60]	; 0x3c
                DROPBITS(state->extra);
            }
            state->mode = DIST;
    20a4:	e3a03014 	mov	r3, #20
    20a8:	e5843000 	str	r3, [r4]
        case DIST:
            for (;;) {
                this = state->distcode[BITS(state->distbits)];
    20ac:	e5943054 	ldr	r3, [r4, #84]	; 0x54
    20b0:	e3e09000 	mvn	r9, #0
    20b4:	e594004c 	ldr	r0, [r4, #76]	; 0x4c
    20b8:	e1e09319 	mvn	r9, r9, lsl r3
    20bc:	e0063009 	and	r3, r6, r9
    20c0:	e0801103 	add	r1, r0, r3, lsl #2
    20c4:	e7d02103 	ldrb	r2, [r0, r3, lsl #2]
    20c8:	e5d13001 	ldrb	r3, [r1, #1]
    20cc:	e1d1c0b2 	ldrh	ip, [r1, #2]
                if ((unsigned)(this.bits) <= bits) break;
    20d0:	e1530005 	cmp	r3, r5
    20d4:	e1a01003 	mov	r1, r3
    20d8:	9a000006 	bls	20f8 <zlib_inflate+0xa34>
                PULLBYTE();
    20dc:	e3570000 	cmp	r7, #0
    20e0:	0a00010e 	beq	2520 <zlib_inflate+0xe5c>
    20e4:	e4db3001 	ldrb	r3, [fp], #1
    20e8:	e2477001 	sub	r7, r7, #1
    20ec:	e0866513 	add	r6, r6, r3, lsl r5
    20f0:	e2855008 	add	r5, r5, #8
            }
    20f4:	eafffff0 	b	20bc <zlib_inflate+0x9f8>
            if ((this.op & 0xf0) == 0) {
    20f8:	e31200f0 	tst	r2, #240	; 0xf0
                DROPBITS(state->extra);
            }
            state->mode = DIST;
        case DIST:
            for (;;) {
                this = state->distcode[BITS(state->distbits)];
    20fc:	e58dc024 	str	ip, [sp, #36]	; 0x24
                if ((unsigned)(this.bits) <= bits) break;
                PULLBYTE();
            }
            if ((this.op & 0xf0) == 0) {
    2100:	1a000017 	bne	2164 <zlib_inflate+0xaa0>
                last = this;
                for (;;) {
                    this = state->distcode[last.val +
                            (BITS(last.bits + last.op) >> last.bits)];
    2104:	e0832002 	add	r2, r3, r2
    2108:	e3e09000 	mvn	r9, #0
    210c:	e1e09219 	mvn	r9, r9, lsl r2
    2110:	e58d900c 	str	r9, [sp, #12]
    2114:	e59dc00c 	ldr	ip, [sp, #12]
                PULLBYTE();
            }
            if ((this.op & 0xf0) == 0) {
                last = this;
                for (;;) {
                    this = state->distcode[last.val +
    2118:	e59d2024 	ldr	r2, [sp, #36]	; 0x24
                            (BITS(last.bits + last.op) >> last.bits)];
    211c:	e006300c 	and	r3, r6, ip
                PULLBYTE();
            }
            if ((this.op & 0xf0) == 0) {
                last = this;
                for (;;) {
                    this = state->distcode[last.val +
    2120:	e0823133 	add	r3, r2, r3, lsr r1
    2124:	e080c103 	add	ip, r0, r3, lsl #2
    2128:	e7d02103 	ldrb	r2, [r0, r3, lsl #2]
    212c:	e5dc3001 	ldrb	r3, [ip, #1]
    2130:	e1dcc0b2 	ldrh	ip, [ip, #2]
                            (BITS(last.bits + last.op) >> last.bits)];
                    if ((unsigned)(last.bits + this.bits) <= bits) break;
    2134:	e0819003 	add	r9, r1, r3
    2138:	e1590005 	cmp	r9, r5
    213c:	9a000006 	bls	215c <zlib_inflate+0xa98>
                    PULLBYTE();
    2140:	e3570000 	cmp	r7, #0
    2144:	0a0000f5 	beq	2520 <zlib_inflate+0xe5c>
    2148:	e4db3001 	ldrb	r3, [fp], #1
    214c:	e2477001 	sub	r7, r7, #1
    2150:	e0866513 	add	r6, r6, r3, lsl r5
    2154:	e2855008 	add	r5, r5, #8
                }
    2158:	eaffffed 	b	2114 <zlib_inflate+0xa50>
                DROPBITS(last.bits);
    215c:	e1a06136 	lsr	r6, r6, r1
    2160:	e0615005 	rsb	r5, r1, r5
            }
            DROPBITS(this.bits);
            if (this.op & 64) {
    2164:	e3120040 	tst	r2, #64	; 0x40
                    if ((unsigned)(last.bits + this.bits) <= bits) break;
                    PULLBYTE();
                }
                DROPBITS(last.bits);
            }
            DROPBITS(this.bits);
    2168:	e1a06336 	lsr	r6, r6, r3
    216c:	e0635005 	rsb	r5, r3, r5
            if (this.op & 64) {
                strm->msg = (char *)"invalid distance code";
    2170:	159f358c 	ldrne	r3, [pc, #1420]	; 2704 <zlib_inflate+0x1040>
    2174:	108f3003 	addne	r3, pc, r3
    2178:	1a000020 	bne	2200 <zlib_inflate+0xb3c>
                state->mode = BAD;
                break;
            }
            state->offset = (unsigned)this.val;
            state->extra = (unsigned)(this.op) & 15;
    217c:	e202200f 	and	r2, r2, #15
            state->mode = DISTEXT;
    2180:	e3a03015 	mov	r3, #21
            if (this.op & 64) {
                strm->msg = (char *)"invalid distance code";
                state->mode = BAD;
                break;
            }
            state->offset = (unsigned)this.val;
    2184:	e584c040 	str	ip, [r4, #64]	; 0x40
            state->extra = (unsigned)(this.op) & 15;
    2188:	e5842044 	str	r2, [r4, #68]	; 0x44
            state->mode = DISTEXT;
    218c:	e5843000 	str	r3, [r4]
        case DISTEXT:
            if (state->extra) {
    2190:	e5943044 	ldr	r3, [r4, #68]	; 0x44
    2194:	e3530000 	cmp	r3, #0
    2198:	0a00000f 	beq	21dc <zlib_inflate+0xb18>
                NEEDBITS(state->extra);
    219c:	e1550003 	cmp	r5, r3
    21a0:	2a000006 	bcs	21c0 <zlib_inflate+0xafc>
    21a4:	e3570000 	cmp	r7, #0
    21a8:	0a0000dc 	beq	2520 <zlib_inflate+0xe5c>
    21ac:	e4db2001 	ldrb	r2, [fp], #1
    21b0:	e2477001 	sub	r7, r7, #1
    21b4:	e0866512 	add	r6, r6, r2, lsl r5
    21b8:	e2855008 	add	r5, r5, #8
    21bc:	eafffff6 	b	219c <zlib_inflate+0xad8>
                state->offset += BITS(state->extra);
    21c0:	e5941040 	ldr	r1, [r4, #64]	; 0x40
    21c4:	e3e02000 	mvn	r2, #0
                DROPBITS(state->extra);
    21c8:	e0635005 	rsb	r5, r3, r5
            state->extra = (unsigned)(this.op) & 15;
            state->mode = DISTEXT;
        case DISTEXT:
            if (state->extra) {
                NEEDBITS(state->extra);
                state->offset += BITS(state->extra);
    21cc:	e1c62312 	bic	r2, r6, r2, lsl r3
                DROPBITS(state->extra);
    21d0:	e1a06336 	lsr	r6, r6, r3
            state->extra = (unsigned)(this.op) & 15;
            state->mode = DISTEXT;
        case DISTEXT:
            if (state->extra) {
                NEEDBITS(state->extra);
                state->offset += BITS(state->extra);
    21d4:	e0812002 	add	r2, r1, r2
    21d8:	e5842040 	str	r2, [r4, #64]	; 0x40
                strm->msg = (char *)"invalid distance too far back";
                state->mode = BAD;
                break;
            }
#endif
            if (state->offset > state->whave + out - left) {
    21dc:	e5943028 	ldr	r3, [r4, #40]	; 0x28
    21e0:	e59dc014 	ldr	ip, [sp, #20]
    21e4:	e5942040 	ldr	r2, [r4, #64]	; 0x40
    21e8:	e08a3003 	add	r3, sl, r3
    21ec:	e06c3003 	rsb	r3, ip, r3
    21f0:	e1520003 	cmp	r2, r3
    21f4:	9a000004 	bls	220c <zlib_inflate+0xb48>
                strm->msg = (char *)"invalid distance too far back";
    21f8:	e59f3508 	ldr	r3, [pc, #1288]	; 2708 <zlib_inflate+0x1044>
    21fc:	e08f3003 	add	r3, pc, r3
    2200:	e5883018 	str	r3, [r8, #24]
                state->mode = BAD;
    2204:	e3a0301b 	mov	r3, #27
    2208:	ea00002d 	b	22c4 <zlib_inflate+0xc00>
                break;
            }
            state->mode = MATCH;
    220c:	e3a03016 	mov	r3, #22
    2210:	e5843000 	str	r3, [r4]
        case MATCH:
            if (left == 0) goto inf_leave;
    2214:	e59d9014 	ldr	r9, [sp, #20]
    2218:	e3590000 	cmp	r9, #0
    221c:	0a0000bf 	beq	2520 <zlib_inflate+0xe5c>
            copy = out - left;
            if (state->offset > copy) {         /* copy from window */
    2220:	e5941040 	ldr	r1, [r4, #64]	; 0x40
                break;
            }
            state->mode = MATCH;
        case MATCH:
            if (left == 0) goto inf_leave;
            copy = out - left;
    2224:	e069200a 	rsb	r2, r9, sl
            if (state->offset > copy) {         /* copy from window */
    2228:	e1510002 	cmp	r1, r2
    222c:	9a00000c 	bls	2264 <zlib_inflate+0xba0>
                copy = state->offset - copy;
                if (copy > state->write) {
    2230:	e594302c 	ldr	r3, [r4, #44]	; 0x2c
            state->mode = MATCH;
        case MATCH:
            if (left == 0) goto inf_leave;
            copy = out - left;
            if (state->offset > copy) {         /* copy from window */
                copy = state->offset - copy;
    2234:	e0622001 	rsb	r2, r2, r1
    2238:	e5940030 	ldr	r0, [r4, #48]	; 0x30
                if (copy > state->write) {
    223c:	e1520003 	cmp	r2, r3
                    copy -= state->write;
                    from = state->window + (state->wsize - copy);
    2240:	85941024 	ldrhi	r1, [r4, #36]	; 0x24
            if (left == 0) goto inf_leave;
            copy = out - left;
            if (state->offset > copy) {         /* copy from window */
                copy = state->offset - copy;
                if (copy > state->write) {
                    copy -= state->write;
    2244:	80632002 	rsbhi	r2, r3, r2
                    from = state->window + (state->wsize - copy);
                }
                else
                    from = state->window + (state->write - copy);
    2248:	90621003 	rsbls	r1, r2, r3
                if (copy > state->length) copy = state->length;
    224c:	e594303c 	ldr	r3, [r4, #60]	; 0x3c
            copy = out - left;
            if (state->offset > copy) {         /* copy from window */
                copy = state->offset - copy;
                if (copy > state->write) {
                    copy -= state->write;
                    from = state->window + (state->wsize - copy);
    2250:	80621001 	rsbhi	r1, r2, r1
                }
                else
                    from = state->window + (state->write - copy);
    2254:	e0801001 	add	r1, r0, r1
    2258:	e1520003 	cmp	r2, r3
    225c:	21a02003 	movcs	r2, r3
    2260:	ea000002 	b	2270 <zlib_inflate+0xbac>
                if (copy > state->length) copy = state->length;
            }
            else {                              /* copy from output */
                from = put - state->offset;
    2264:	e59dc018 	ldr	ip, [sp, #24]
                copy = state->length;
    2268:	e594203c 	ldr	r2, [r4, #60]	; 0x3c
                else
                    from = state->window + (state->write - copy);
                if (copy > state->length) copy = state->length;
            }
            else {                              /* copy from output */
                from = put - state->offset;
    226c:	e061100c 	rsb	r1, r1, ip
    2270:	e59d9014 	ldr	r9, [sp, #20]
                copy = state->length;
            }
            if (copy > left) copy = left;
            left -= copy;
            state->length -= copy;
    2274:	e594303c 	ldr	r3, [r4, #60]	; 0x3c
    2278:	e1520009 	cmp	r2, r9
    227c:	21a02009 	movcs	r2, r9
    2280:	e0623003 	rsb	r3, r2, r3
            else {                              /* copy from output */
                from = put - state->offset;
                copy = state->length;
            }
            if (copy > left) copy = left;
            left -= copy;
    2284:	e0629009 	rsb	r9, r2, r9
            state->length -= copy;
    2288:	e584303c 	str	r3, [r4, #60]	; 0x3c
    228c:	e3a03000 	mov	r3, #0
            else {                              /* copy from output */
                from = put - state->offset;
                copy = state->length;
            }
            if (copy > left) copy = left;
            left -= copy;
    2290:	e58d9014 	str	r9, [sp, #20]
            state->length -= copy;
            do {
                *put++ = *from++;
    2294:	e7d10003 	ldrb	r0, [r1, r3]
    2298:	e59dc018 	ldr	ip, [sp, #24]
    229c:	e7cc0003 	strb	r0, [ip, r3]
    22a0:	e2833001 	add	r3, r3, #1
            } while (--copy);
    22a4:	e1530002 	cmp	r3, r2
    22a8:	1afffff9 	bne	2294 <zlib_inflate+0xbd0>
    22ac:	e08cc003 	add	ip, ip, r3
            if (state->length == 0) state->mode = LEN;
    22b0:	e594303c 	ldr	r3, [r4, #60]	; 0x3c
    22b4:	e58dc018 	str	ip, [sp, #24]
    22b8:	e3530000 	cmp	r3, #0
    22bc:	1afffd25 	bne	1758 <zlib_inflate+0x94>
    22c0:	e3a03012 	mov	r3, #18
    22c4:	e5843000 	str	r3, [r4]
    22c8:	eafffd22 	b	1758 <zlib_inflate+0x94>
            break;
        case LIT:
            if (left == 0) goto inf_leave;
    22cc:	e59d9014 	ldr	r9, [sp, #20]
    22d0:	e3590000 	cmp	r9, #0
    22d4:	0a000091 	beq	2520 <zlib_inflate+0xe5c>
            *put++ = (unsigned char)(state->length);
    22d8:	e59dc018 	ldr	ip, [sp, #24]
            left--;
    22dc:	e2499001 	sub	r9, r9, #1
            } while (--copy);
            if (state->length == 0) state->mode = LEN;
            break;
        case LIT:
            if (left == 0) goto inf_leave;
            *put++ = (unsigned char)(state->length);
    22e0:	e594303c 	ldr	r3, [r4, #60]	; 0x3c
            left--;
    22e4:	e58d9014 	str	r9, [sp, #20]
            } while (--copy);
            if (state->length == 0) state->mode = LEN;
            break;
        case LIT:
            if (left == 0) goto inf_leave;
            *put++ = (unsigned char)(state->length);
    22e8:	e28cc001 	add	ip, ip, #1
    22ec:	e54c3001 	strb	r3, [ip, #-1]
            left--;
            state->mode = LEN;
    22f0:	e3a03012 	mov	r3, #18
            } while (--copy);
            if (state->length == 0) state->mode = LEN;
            break;
        case LIT:
            if (left == 0) goto inf_leave;
            *put++ = (unsigned char)(state->length);
    22f4:	e58dc018 	str	ip, [sp, #24]
            left--;
            state->mode = LEN;
    22f8:	e5843000 	str	r3, [r4]
            break;
    22fc:	eafffd15 	b	1758 <zlib_inflate+0x94>
        case CHECK:
            if (state->wrap) {
    2300:	e5943008 	ldr	r3, [r4, #8]
    2304:	e3530000 	cmp	r3, #0
    2308:	0a00007a 	beq	24f8 <zlib_inflate+0xe34>
                NEEDBITS(32);
    230c:	e355001f 	cmp	r5, #31
    2310:	8a000006 	bhi	2330 <zlib_inflate+0xc6c>
    2314:	e3570000 	cmp	r7, #0
    2318:	0a000080 	beq	2520 <zlib_inflate+0xe5c>
    231c:	e4db3001 	ldrb	r3, [fp], #1
    2320:	e2477001 	sub	r7, r7, #1
    2324:	e0866513 	add	r6, r6, r3, lsl r5
    2328:	e2855008 	add	r5, r5, #8
    232c:	eafffff6 	b	230c <zlib_inflate+0xc48>
                out -= left;
    2330:	e59d9014 	ldr	r9, [sp, #20]
                strm->total_out += out;
    2334:	e5983014 	ldr	r3, [r8, #20]
            state->mode = LEN;
            break;
        case CHECK:
            if (state->wrap) {
                NEEDBITS(32);
                out -= left;
    2338:	e069100a 	rsb	r1, r9, sl
                strm->total_out += out;
    233c:	e0833001 	add	r3, r3, r1
                state->total += out;
                if (out)
    2340:	e3510000 	cmp	r1, #0
            break;
        case CHECK:
            if (state->wrap) {
                NEEDBITS(32);
                out -= left;
                strm->total_out += out;
    2344:	e5883014 	str	r3, [r8, #20]
                state->total += out;
    2348:	e594301c 	ldr	r3, [r4, #28]
    234c:	e0833001 	add	r3, r3, r1
    2350:	e584301c 	str	r3, [r4, #28]
                if (out)
    2354:	0a000053 	beq	24a8 <zlib_inflate+0xde4>
{
    unsigned long s1 = adler & 0xffff;
    unsigned long s2 = (adler >> 16) & 0xffff;
    int k;

    if (buf == NULL) return 1L;
    2358:	e59dc018 	ldr	ip, [sp, #24]
                    strm->adler = state->check =
                        UPDATE(state->check, put - out, out);
    235c:	e5940018 	ldr	r0, [r4, #24]
    2360:	e05c3001 	subs	r3, ip, r1
*/
static inline uLong zlib_adler32(uLong adler,
				 const Byte *buf,
				 uInt len)
{
    unsigned long s1 = adler & 0xffff;
    2364:	e6ff2070 	uxth	r2, r0
    unsigned long s2 = (adler >> 16) & 0xffff;
    2368:	e1a00820 	lsr	r0, r0, #16
    int k;

    if (buf == NULL) return 1L;
    236c:	03a02001 	moveq	r2, #1
    2370:	0a00004a 	beq	24a0 <zlib_inflate+0xddc>
        }
        if (k != 0) do {
            s1 += *buf++;
	    s2 += s1;
        } while (--k);
        s1 %= BASE;
    2374:	e30f9ff1 	movw	r9, #65521	; 0xfff1
    int k;

    if (buf == NULL) return 1L;

    while (len > 0) {
        k = len < NMAX ? len : NMAX;
    2378:	e301c5b0 	movw	ip, #5552	; 0x15b0
    237c:	e151000c 	cmp	r1, ip
    2380:	31a0c001 	movcc	ip, r1
        len -= k;
    2384:	e06c1001 	rsb	r1, ip, r1
        while (k >= 16) {
    2388:	e35c000f 	cmp	ip, #15
    238c:	da000032 	ble	245c <zlib_inflate+0xd98>
            DO16(buf);
    2390:	e5d3a000 	ldrb	sl, [r3]
	    buf += 16;
            k -= 16;
    2394:	e24cc010 	sub	ip, ip, #16
    while (len > 0) {
        k = len < NMAX ? len : NMAX;
        len -= k;
        while (k >= 16) {
            DO16(buf);
	    buf += 16;
    2398:	e2833010 	add	r3, r3, #16

    while (len > 0) {
        k = len < NMAX ? len : NMAX;
        len -= k;
        while (k >= 16) {
            DO16(buf);
    239c:	e08a2002 	add	r2, sl, r2
    23a0:	e553a00f 	ldrb	sl, [r3, #-15]
    23a4:	e0820000 	add	r0, r2, r0
    23a8:	e082200a 	add	r2, r2, sl
    23ac:	e553a00e 	ldrb	sl, [r3, #-14]
    23b0:	e0800002 	add	r0, r0, r2
    23b4:	e082200a 	add	r2, r2, sl
    23b8:	e553a00d 	ldrb	sl, [r3, #-13]
    23bc:	e0800002 	add	r0, r0, r2
    23c0:	e082200a 	add	r2, r2, sl
    23c4:	e553a00c 	ldrb	sl, [r3, #-12]
    23c8:	e0800002 	add	r0, r0, r2
    23cc:	e082200a 	add	r2, r2, sl
    23d0:	e553a00b 	ldrb	sl, [r3, #-11]
    23d4:	e0800002 	add	r0, r0, r2
    23d8:	e082200a 	add	r2, r2, sl
    23dc:	e553a00a 	ldrb	sl, [r3, #-10]
    23e0:	e0800002 	add	r0, r0, r2
    23e4:	e082200a 	add	r2, r2, sl
    23e8:	e553a009 	ldrb	sl, [r3, #-9]
    23ec:	e0800002 	add	r0, r0, r2
    23f0:	e082200a 	add	r2, r2, sl
    23f4:	e553a008 	ldrb	sl, [r3, #-8]
    23f8:	e0800002 	add	r0, r0, r2
    23fc:	e082200a 	add	r2, r2, sl
    2400:	e553a007 	ldrb	sl, [r3, #-7]
    2404:	e0800002 	add	r0, r0, r2
    2408:	e082200a 	add	r2, r2, sl
    240c:	e553a006 	ldrb	sl, [r3, #-6]
    2410:	e0800002 	add	r0, r0, r2
    2414:	e082200a 	add	r2, r2, sl
    2418:	e553a005 	ldrb	sl, [r3, #-5]
    241c:	e0800002 	add	r0, r0, r2
    2420:	e082200a 	add	r2, r2, sl
    2424:	e553a004 	ldrb	sl, [r3, #-4]
    2428:	e0800002 	add	r0, r0, r2
    242c:	e082200a 	add	r2, r2, sl
    2430:	e553a003 	ldrb	sl, [r3, #-3]
    2434:	e0800002 	add	r0, r0, r2
    2438:	e082200a 	add	r2, r2, sl
    243c:	e553a002 	ldrb	sl, [r3, #-2]
    2440:	e0800002 	add	r0, r0, r2
    2444:	e082200a 	add	r2, r2, sl
    2448:	e553a001 	ldrb	sl, [r3, #-1]
    244c:	e0800002 	add	r0, r0, r2
    2450:	e082200a 	add	r2, r2, sl
    2454:	e0800002 	add	r0, r0, r2
    2458:	eaffffca 	b	2388 <zlib_inflate+0xcc4>
	    buf += 16;
            k -= 16;
        }
        if (k != 0) do {
    245c:	e35c0000 	cmp	ip, #0
    2460:	01a0c003 	moveq	ip, r3
    2464:	0a000005 	beq	2480 <zlib_inflate+0xdbc>
    2468:	e083c00c 	add	ip, r3, ip
            s1 += *buf++;
    246c:	e4d3a001 	ldrb	sl, [r3], #1
	    s2 += s1;
        } while (--k);
    2470:	e153000c 	cmp	r3, ip
            DO16(buf);
	    buf += 16;
            k -= 16;
        }
        if (k != 0) do {
            s1 += *buf++;
    2474:	e082200a 	add	r2, r2, sl
	    s2 += s1;
    2478:	e0800002 	add	r0, r0, r2
        } while (--k);
    247c:	1afffffa 	bne	246c <zlib_inflate+0xda8>
        s1 %= BASE;
    2480:	e733f912 	udiv	r3, r2, r9
    unsigned long s2 = (adler >> 16) & 0xffff;
    int k;

    if (buf == NULL) return 1L;

    while (len > 0) {
    2484:	e3510000 	cmp	r1, #0
        }
        if (k != 0) do {
            s1 += *buf++;
	    s2 += s1;
        } while (--k);
        s1 %= BASE;
    2488:	e0622399 	mls	r2, r9, r3, r2
        s2 %= BASE;
    248c:	e733f910 	udiv	r3, r0, r9
    2490:	e0600399 	mls	r0, r9, r3, r0
    unsigned long s2 = (adler >> 16) & 0xffff;
    int k;

    if (buf == NULL) return 1L;

    while (len > 0) {
    2494:	11a0300c 	movne	r3, ip
    2498:	1affffb6 	bne	2378 <zlib_inflate+0xcb4>
	    s2 += s1;
        } while (--k);
        s1 %= BASE;
        s2 %= BASE;
    }
    return (s2 << 16) | s1;
    249c:	e1822800 	orr	r2, r2, r0, lsl #16
                NEEDBITS(32);
                out -= left;
                strm->total_out += out;
                state->total += out;
                if (out)
                    strm->adler = state->check =
    24a0:	e5842018 	str	r2, [r4, #24]
    24a4:	e5882028 	str	r2, [r8, #40]	; 0x28
                        UPDATE(state->check, put - out, out);
                out = left;
                if ((
                     REVERSE(hold)) != state->check) {
    24a8:	e1a02c26 	lsr	r2, r6, #24
    24ac:	e1a03426 	lsr	r3, r6, #8
    24b0:	e0822c06 	add	r2, r2, r6, lsl #24
    24b4:	e2033cff 	and	r3, r3, #65280	; 0xff00
    24b8:	e0822003 	add	r2, r2, r3
    24bc:	e2063cff 	and	r3, r6, #65280	; 0xff00
    24c0:	e0822403 	add	r2, r2, r3, lsl #8
                state->total += out;
                if (out)
                    strm->adler = state->check =
                        UPDATE(state->check, put - out, out);
                out = left;
                if ((
    24c4:	e5943018 	ldr	r3, [r4, #24]
    24c8:	e1520003 	cmp	r2, r3
    24cc:	0a000006 	beq	24ec <zlib_inflate+0xe28>
                     REVERSE(hold)) != state->check) {
                    strm->msg = (char *)"incorrect data check";
    24d0:	e59f3234 	ldr	r3, [pc, #564]	; 270c <zlib_inflate+0x1048>
                    state->mode = BAD;
                    break;
    24d4:	e59da014 	ldr	sl, [sp, #20]
                    strm->adler = state->check =
                        UPDATE(state->check, put - out, out);
                out = left;
                if ((
                     REVERSE(hold)) != state->check) {
                    strm->msg = (char *)"incorrect data check";
    24d8:	e08f3003 	add	r3, pc, r3
    24dc:	e5883018 	str	r3, [r8, #24]
                    state->mode = BAD;
    24e0:	e3a0301b 	mov	r3, #27
    24e4:	e5843000 	str	r3, [r4]
                    break;
    24e8:	eafffc9a 	b	1758 <zlib_inflate+0x94>
    24ec:	e59da014 	ldr	sl, [sp, #20]
                }
                INITBITS();
    24f0:	e3a05000 	mov	r5, #0
    24f4:	e1a06005 	mov	r6, r5
            }
            state->mode = DONE;
    24f8:	e3a0301a 	mov	r3, #26
    24fc:	e5843000 	str	r3, [r4]
        case DONE:
            ret = Z_STREAM_END;
    2500:	e3a03001 	mov	r3, #1
    2504:	e58d301c 	str	r3, [sp, #28]
    2508:	ea000004 	b	2520 <zlib_inflate+0xe5c>
            goto inf_leave;
        case BAD:
            ret = Z_DATA_ERROR;
    250c:	e3e09002 	mvn	r9, #2
    2510:	e58d901c 	str	r9, [sp, #28]
    2514:	ea000001 	b	2520 <zlib_inflate+0xe5c>
                }
                INITBITS();
            }
            state->mode = DONE;
        case DONE:
            ret = Z_STREAM_END;
    2518:	e3a0c001 	mov	ip, #1
    251c:	e58dc01c 	str	ip, [sp, #28]
       Return from inflate(), updating the total counts and the check value.
       If there was no progress during the inflate() call, return a buffer
       error.  Call zlib_updatewindow() to create and/or update the window state.
     */
  inf_leave:
    RESTORE();
    2520:	e59d9018 	ldr	r9, [sp, #24]
    2524:	e588b000 	str	fp, [r8]
    2528:	e59dc014 	ldr	ip, [sp, #20]
    252c:	e5887004 	str	r7, [r8, #4]
    2530:	e588900c 	str	r9, [r8, #12]
    2534:	e588c010 	str	ip, [r8, #16]
    if (state->wsize || (state->mode < CHECK && out != strm->avail_out))
    2538:	e5943024 	ldr	r3, [r4, #36]	; 0x24
       Return from inflate(), updating the total counts and the check value.
       If there was no progress during the inflate() call, return a buffer
       error.  Call zlib_updatewindow() to create and/or update the window state.
     */
  inf_leave:
    RESTORE();
    253c:	e5846034 	str	r6, [r4, #52]	; 0x34
    2540:	e5845038 	str	r5, [r4, #56]	; 0x38
    if (state->wsize || (state->mode < CHECK && out != strm->avail_out))
    2544:	e3530000 	cmp	r3, #0
    2548:	1a000005 	bne	2564 <zlib_inflate+0xea0>
    254c:	e5943000 	ldr	r3, [r4]
    2550:	e3530017 	cmp	r3, #23
    2554:	8a000005 	bhi	2570 <zlib_inflate+0xeac>
    2558:	e5983010 	ldr	r3, [r8, #16]
    255c:	e15a0003 	cmp	sl, r3
    2560:	0a000002 	beq	2570 <zlib_inflate+0xeac>
        zlib_updatewindow(strm, out);
    2564:	e1a00008 	mov	r0, r8
    2568:	e1a0100a 	mov	r1, sl
    256c:	ebfff918 	bl	9d4 <zlib_updatewindow>

    in -= strm->avail_in;
    2570:	e5987004 	ldr	r7, [r8, #4]
    2574:	e59d902c 	ldr	r9, [sp, #44]	; 0x2c
    out -= strm->avail_out;
    strm->total_in += in;
    2578:	e5983008 	ldr	r3, [r8, #8]
    RESTORE();
    if (state->wsize || (state->mode < CHECK && out != strm->avail_out))
        zlib_updatewindow(strm, out);

    in -= strm->avail_in;
    out -= strm->avail_out;
    257c:	e5981010 	ldr	r1, [r8, #16]
  inf_leave:
    RESTORE();
    if (state->wsize || (state->mode < CHECK && out != strm->avail_out))
        zlib_updatewindow(strm, out);

    in -= strm->avail_in;
    2580:	e0677009 	rsb	r7, r7, r9
    out -= strm->avail_out;
    strm->total_in += in;
    2584:	e0833007 	add	r3, r3, r7
    RESTORE();
    if (state->wsize || (state->mode < CHECK && out != strm->avail_out))
        zlib_updatewindow(strm, out);

    in -= strm->avail_in;
    out -= strm->avail_out;
    2588:	e061100a 	rsb	r1, r1, sl
    strm->total_in += in;
    258c:	e5883008 	str	r3, [r8, #8]
    strm->total_out += out;
    2590:	e5983014 	ldr	r3, [r8, #20]
    2594:	e0833001 	add	r3, r3, r1
    2598:	e5883014 	str	r3, [r8, #20]
    state->total += out;
    259c:	e594301c 	ldr	r3, [r4, #28]
    25a0:	e0833001 	add	r3, r3, r1
    25a4:	e584301c 	str	r3, [r4, #28]
    if (state->wrap && out)
    25a8:	e5943008 	ldr	r3, [r4, #8]
    25ac:	e3530000 	cmp	r3, #0
    25b0:	0a000067 	beq	2754 <zlib_inflate+0x1090>
    25b4:	e3510000 	cmp	r1, #0
    25b8:	0a000065 	beq	2754 <zlib_inflate+0x1090>
        strm->adler = state->check =
            UPDATE(state->check, strm->next_out - out, out);
    25bc:	e598300c 	ldr	r3, [r8, #12]
    25c0:	e5940018 	ldr	r0, [r4, #24]
{
    unsigned long s1 = adler & 0xffff;
    unsigned long s2 = (adler >> 16) & 0xffff;
    int k;

    if (buf == NULL) return 1L;
    25c4:	e0533001 	subs	r3, r3, r1
*/
static inline uLong zlib_adler32(uLong adler,
				 const Byte *buf,
				 uInt len)
{
    unsigned long s1 = adler & 0xffff;
    25c8:	e6ff2070 	uxth	r2, r0
    unsigned long s2 = (adler >> 16) & 0xffff;
    25cc:	e1a00820 	lsr	r0, r0, #16
    int k;

    if (buf == NULL) return 1L;
    25d0:	03a02001 	moveq	r2, #1
    25d4:	0a00005c 	beq	274c <zlib_inflate+0x1088>
    25d8:	e1a05001 	mov	r5, r1

    while (len > 0) {
        k = len < NMAX ? len : NMAX;
    25dc:	e30195b0 	movw	r9, #5552	; 0x15b0
        }
        if (k != 0) do {
            s1 += *buf++;
	    s2 += s1;
        } while (--k);
        s1 %= BASE;
    25e0:	e30f6ff1 	movw	r6, #65521	; 0xfff1
    int k;

    if (buf == NULL) return 1L;

    while (len > 0) {
        k = len < NMAX ? len : NMAX;
    25e4:	e1550009 	cmp	r5, r9
    25e8:	31a0c005 	movcc	ip, r5
    25ec:	21a0c009 	movcs	ip, r9
        len -= k;
    25f0:	e06c5005 	rsb	r5, ip, r5
        while (k >= 16) {
    25f4:	e35c000f 	cmp	ip, #15
    25f8:	da000044 	ble	2710 <zlib_inflate+0x104c>
            DO16(buf);
    25fc:	e5d3a000 	ldrb	sl, [r3]
	    buf += 16;
            k -= 16;
    2600:	e24cc010 	sub	ip, ip, #16
    while (len > 0) {
        k = len < NMAX ? len : NMAX;
        len -= k;
        while (k >= 16) {
            DO16(buf);
	    buf += 16;
    2604:	e2833010 	add	r3, r3, #16

    while (len > 0) {
        k = len < NMAX ? len : NMAX;
        len -= k;
        while (k >= 16) {
            DO16(buf);
    2608:	e08a2002 	add	r2, sl, r2
    260c:	e553a00f 	ldrb	sl, [r3, #-15]
    2610:	e0820000 	add	r0, r2, r0
    2614:	e082200a 	add	r2, r2, sl
    2618:	e553a00e 	ldrb	sl, [r3, #-14]
    261c:	e0800002 	add	r0, r0, r2
    2620:	e082200a 	add	r2, r2, sl
    2624:	e553a00d 	ldrb	sl, [r3, #-13]
    2628:	e0800002 	add	r0, r0, r2
    262c:	e082200a 	add	r2, r2, sl
    2630:	e553a00c 	ldrb	sl, [r3, #-12]
    2634:	e0800002 	add	r0, r0, r2
    2638:	e082200a 	add	r2, r2, sl
    263c:	e553a00b 	ldrb	sl, [r3, #-11]
    2640:	e0800002 	add	r0, r0, r2
    2644:	e082200a 	add	r2, r2, sl
    2648:	e553a00a 	ldrb	sl, [r3, #-10]
    264c:	e0800002 	add	r0, r0, r2
    2650:	e082200a 	add	r2, r2, sl
    2654:	e553a009 	ldrb	sl, [r3, #-9]
    2658:	e0800002 	add	r0, r0, r2
    265c:	e082200a 	add	r2, r2, sl
    2660:	e553a008 	ldrb	sl, [r3, #-8]
    2664:	e0800002 	add	r0, r0, r2
    2668:	e082200a 	add	r2, r2, sl
    266c:	e553a007 	ldrb	sl, [r3, #-7]
    2670:	e0800002 	add	r0, r0, r2
    2674:	e082200a 	add	r2, r2, sl
    2678:	e553a006 	ldrb	sl, [r3, #-6]
    267c:	e0800002 	add	r0, r0, r2
    2680:	e082200a 	add	r2, r2, sl
    2684:	e553a005 	ldrb	sl, [r3, #-5]
    2688:	e0800002 	add	r0, r0, r2
    268c:	e082200a 	add	r2, r2, sl
    2690:	e553a004 	ldrb	sl, [r3, #-4]
    2694:	e0800002 	add	r0, r0, r2
    2698:	e082200a 	add	r2, r2, sl
    269c:	e553a003 	ldrb	sl, [r3, #-3]
    26a0:	e0800002 	add	r0, r0, r2
    26a4:	e082200a 	add	r2, r2, sl
    26a8:	e553a002 	ldrb	sl, [r3, #-2]
    26ac:	e0800002 	add	r0, r0, r2
    26b0:	e082200a 	add	r2, r2, sl
    26b4:	e553a001 	ldrb	sl, [r3, #-1]
    26b8:	e0800002 	add	r0, r0, r2
    26bc:	e082200a 	add	r2, r2, sl
    26c0:	e0800002 	add	r0, r0, r2
    26c4:	eaffffca 	b	25f4 <zlib_inflate+0xf30>
    26c8:	00001a30 	.word	0x00001a30
    26cc:	000023b1 	.word	0x000023b1
    26d0:	000023b4 	.word	0x000023b4
    26d4:	000023ab 	.word	0x000023ab
    26d8:	0000223f 	.word	0x0000223f
    26dc:	000021f2 	.word	0x000021f2
    26e0:	00002123 	.word	0x00002123
    26e4:	00001618 	.word	0x00001618
    26e8:	000015ac 	.word	0x000015ac
    26ec:	0000203b 	.word	0x0000203b
    26f0:	00001f54 	.word	0x00001f54
    26f4:	00001e94 	.word	0x00001e94
    26f8:	00001e1e 	.word	0x00001e1e
    26fc:	00001df2 	.word	0x00001df2
    2700:	00001b8d 	.word	0x00001b8d
    2704:	00001a43 	.word	0x00001a43
    2708:	0000199d 	.word	0x0000199d
    270c:	00001810 	.word	0x00001810
	    buf += 16;
            k -= 16;
        }
        if (k != 0) do {
    2710:	e35c0000 	cmp	ip, #0
    2714:	0a000005 	beq	2730 <zlib_inflate+0x106c>
    2718:	e083c00c 	add	ip, r3, ip
            s1 += *buf++;
    271c:	e4d3a001 	ldrb	sl, [r3], #1
	    s2 += s1;
        } while (--k);
    2720:	e153000c 	cmp	r3, ip
            DO16(buf);
	    buf += 16;
            k -= 16;
        }
        if (k != 0) do {
            s1 += *buf++;
    2724:	e082200a 	add	r2, r2, sl
	    s2 += s1;
    2728:	e0800002 	add	r0, r0, r2
        } while (--k);
    272c:	1afffffa 	bne	271c <zlib_inflate+0x1058>
        s1 %= BASE;
    2730:	e73cf612 	udiv	ip, r2, r6
    unsigned long s2 = (adler >> 16) & 0xffff;
    int k;

    if (buf == NULL) return 1L;

    while (len > 0) {
    2734:	e3550000 	cmp	r5, #0
        }
        if (k != 0) do {
            s1 += *buf++;
	    s2 += s1;
        } while (--k);
        s1 %= BASE;
    2738:	e0622c96 	mls	r2, r6, ip, r2
        s2 %= BASE;
    273c:	e73cf610 	udiv	ip, r0, r6
    2740:	e0600c96 	mls	r0, r6, ip, r0
    unsigned long s2 = (adler >> 16) & 0xffff;
    int k;

    if (buf == NULL) return 1L;

    while (len > 0) {
    2744:	1affffa6 	bne	25e4 <zlib_inflate+0xf20>
	    s2 += s1;
        } while (--k);
        s1 %= BASE;
        s2 %= BASE;
    }
    return (s2 << 16) | s1;
    2748:	e1822800 	orr	r2, r2, r0, lsl #16
    out -= strm->avail_out;
    strm->total_in += in;
    strm->total_out += out;
    state->total += out;
    if (state->wrap && out)
        strm->adler = state->check =
    274c:	e5842018 	str	r2, [r4, #24]
    2750:	e5882028 	str	r2, [r8, #40]	; 0x28
            UPDATE(state->check, strm->next_out - out, out);

    strm->data_type = state->bits + (state->last ? 64 : 0) +
    2754:	e5943004 	ldr	r3, [r4, #4]
    2758:	e5942038 	ldr	r2, [r4, #56]	; 0x38
                      (state->mode == TYPE ? 128 : 0);

    if (flush == Z_PACKET_FLUSH && ret == Z_OK &&
    275c:	e59dc01c 	ldr	ip, [sp, #28]
    2760:	e59d9020 	ldr	r9, [sp, #32]
    state->total += out;
    if (state->wrap && out)
        strm->adler = state->check =
            UPDATE(state->check, strm->next_out - out, out);

    strm->data_type = state->bits + (state->last ? 64 : 0) +
    2764:	e3530000 	cmp	r3, #0
    2768:	13a03040 	movne	r3, #64	; 0x40
    276c:	03a03000 	moveq	r3, #0
    2770:	e0833002 	add	r3, r3, r2
    2774:	e5942000 	ldr	r2, [r4]
    2778:	e352000b 	cmp	r2, #11
    277c:	03a02080 	moveq	r2, #128	; 0x80
    2780:	13a02000 	movne	r2, #0
    2784:	e0833002 	add	r3, r3, r2
    2788:	e5883024 	str	r3, [r8, #36]	; 0x24
                      (state->mode == TYPE ? 128 : 0);

    if (flush == Z_PACKET_FLUSH && ret == Z_OK &&
    278c:	e27c3001 	rsbs	r3, ip, #1
    2790:	33a03000 	movcc	r3, #0
    2794:	e3590002 	cmp	r9, #2
    2798:	035c0000 	cmpeq	ip, #0
    279c:	1a000012 	bne	27ec <zlib_inflate+0x1128>
    27a0:	e5982010 	ldr	r2, [r8, #16]
    27a4:	e3520000 	cmp	r2, #0
    27a8:	0a00000f 	beq	27ec <zlib_inflate+0x1128>
            strm->avail_out != 0 && strm->avail_in == 0)
    27ac:	e5982004 	ldr	r2, [r8, #4]
    27b0:	e3520000 	cmp	r2, #0
    27b4:	1a00000c 	bne	27ec <zlib_inflate+0x1128>
 */
static int zlib_inflateSyncPacket(z_streamp strm)
{
    struct inflate_state *state;

    if (strm == NULL || strm->state == NULL) return Z_STREAM_ERROR;
    27b8:	e598301c 	ldr	r3, [r8, #28]
    27bc:	e3530000 	cmp	r3, #0
    27c0:	0a000013 	beq	2814 <zlib_inflate+0x1150>
    state = (struct inflate_state *)strm->state;

    if (state->mode == STORED && state->bits == 0) {
    27c4:	e5932000 	ldr	r2, [r3]
    27c8:	e352000d 	cmp	r2, #13
    27cc:	1a000004 	bne	27e4 <zlib_inflate+0x1120>
    27d0:	e5930038 	ldr	r0, [r3, #56]	; 0x38
    27d4:	e3500000 	cmp	r0, #0
	state->mode = TYPE;
    27d8:	03a0200b 	moveq	r2, #11
    27dc:	05832000 	streq	r2, [r3]
    27e0:	0a00000c 	beq	2818 <zlib_inflate+0x1154>
        return Z_OK;
    }
    return Z_DATA_ERROR;
    27e4:	e3e00002 	mvn	r0, #2
    strm->data_type = state->bits + (state->last ? 64 : 0) +
                      (state->mode == TYPE ? 128 : 0);

    if (flush == Z_PACKET_FLUSH && ret == Z_OK &&
            strm->avail_out != 0 && strm->avail_in == 0)
		return zlib_inflateSyncPacket(strm);
    27e8:	ea00000a 	b	2818 <zlib_inflate+0x1154>

    if (((in == 0 && out == 0) || flush == Z_FINISH) && ret == Z_OK)
    27ec:	e1911007 	orrs	r1, r1, r7
    27f0:	0a000003 	beq	2804 <zlib_inflate+0x1140>
    27f4:	e59dc020 	ldr	ip, [sp, #32]
    27f8:	e35c0005 	cmp	ip, #5
    27fc:	159d001c 	ldrne	r0, [sp, #28]
    2800:	1a000004 	bne	2818 <zlib_inflate+0x1154>
        ret = Z_BUF_ERROR;
    2804:	e59d001c 	ldr	r0, [sp, #28]
    2808:	e3530000 	cmp	r3, #0
    280c:	13e00004 	mvnne	r0, #4
    2810:	ea000000 	b	2818 <zlib_inflate+0x1154>
            goto inf_leave;
        case MEM:
            return Z_MEM_ERROR;
        case SYNC:
        default:
            return Z_STREAM_ERROR;
    2814:	e3e00001 	mvn	r0, #1

    if (((in == 0 && out == 0) || flush == Z_FINISH) && ret == Z_OK)
        ret = Z_BUF_ERROR;

    return ret;
}
    2818:	e28dd03c 	add	sp, sp, #60	; 0x3c
    281c:	e8bd8ff0 	pop	{r4, r5, r6, r7, r8, r9, sl, fp, pc}

00002820 <zlib_inflateEnd>:

int zlib_inflateEnd(z_streamp strm)
{
    if (strm == NULL || strm->state == NULL)
    2820:	e3500000 	cmp	r0, #0
    2824:	1a000001 	bne	2830 <zlib_inflateEnd+0x10>
        return Z_STREAM_ERROR;
    2828:	e3e00001 	mvn	r0, #1
    282c:	e12fff1e 	bx	lr
    return ret;
}

int zlib_inflateEnd(z_streamp strm)
{
    if (strm == NULL || strm->state == NULL)
    2830:	e590301c 	ldr	r3, [r0, #28]
    2834:	e3530000 	cmp	r3, #0
    2838:	0afffffa 	beq	2828 <zlib_inflateEnd+0x8>
        return Z_STREAM_ERROR;
    return Z_OK;
    283c:	e3a00000 	mov	r0, #0
}
    2840:	e12fff1e 	bx	lr

00002844 <zlib_inflateIncomp>:
 * be waiting on the start of a block (i.e. mode == TYPE or HEAD).  On exit,
 * the output will also be caught up, and the checksum will have been updated
 * if need be.
 */
int zlib_inflateIncomp(z_stream *z)
{
    2844:	e92d41f0 	push	{r4, r5, r6, r7, r8, lr}
    2848:	e1a04000 	mov	r4, r0
    struct inflate_state *state = (struct inflate_state *)z->state;
    284c:	e590501c 	ldr	r5, [r0, #28]
    Byte *saved_no = z->next_out;
    2850:	e590600c 	ldr	r6, [r0, #12]
    uInt saved_ao = z->avail_out;
    2854:	e5907010 	ldr	r7, [r0, #16]

    if (state->mode != TYPE && state->mode != HEAD)
    2858:	e5953000 	ldr	r3, [r5]
    285c:	e3530000 	cmp	r3, #0
    2860:	1353000b 	cmpne	r3, #11
    2864:	03a03000 	moveq	r3, #0
    2868:	13a03001 	movne	r3, #1
    286c:	1a00006b 	bne	2a20 <zlib_inflateIncomp+0x1dc>
	return Z_DATA_ERROR;

    /* Setup some variables to allow misuse of updateWindow */
    z->avail_out = 0;
    z->next_out = (unsigned char*)z->next_in + z->avail_in;
    2870:	e5901004 	ldr	r1, [r0, #4]

    if (state->mode != TYPE && state->mode != HEAD)
	return Z_DATA_ERROR;

    /* Setup some variables to allow misuse of updateWindow */
    z->avail_out = 0;
    2874:	e5803010 	str	r3, [r0, #16]
    z->next_out = (unsigned char*)z->next_in + z->avail_in;
    2878:	e5903000 	ldr	r3, [r0]
    287c:	e0833001 	add	r3, r3, r1
    2880:	e580300c 	str	r3, [r0, #12]

    zlib_updatewindow(z, z->avail_in);
    2884:	ebfff852 	bl	9d4 <zlib_updatewindow>
    /* Restore saved variables */
    z->avail_out = saved_ao;
    z->next_out = saved_no;

    z->adler = state->check =
        UPDATE(state->check, z->next_in, z->avail_in);
    2888:	e8941008 	ldm	r4, {r3, ip}
    z->next_out = (unsigned char*)z->next_in + z->avail_in;

    zlib_updatewindow(z, z->avail_in);

    /* Restore saved variables */
    z->avail_out = saved_ao;
    288c:	e5847010 	str	r7, [r4, #16]
    z->next_out = saved_no;
    2890:	e584600c 	str	r6, [r4, #12]

    z->adler = state->check =
        UPDATE(state->check, z->next_in, z->avail_in);
    2894:	e5951018 	ldr	r1, [r5, #24]
{
    unsigned long s1 = adler & 0xffff;
    unsigned long s2 = (adler >> 16) & 0xffff;
    int k;

    if (buf == NULL) return 1L;
    2898:	e3530000 	cmp	r3, #0
*/
static inline uLong zlib_adler32(uLong adler,
				 const Byte *buf,
				 uInt len)
{
    unsigned long s1 = adler & 0xffff;
    289c:	e6ff2071 	uxth	r2, r1
    unsigned long s2 = (adler >> 16) & 0xffff;
    28a0:	e1a01821 	lsr	r1, r1, #16
    int k;

    if (buf == NULL) return 1L;
    28a4:	03a02001 	moveq	r2, #1
    28a8:	0a00004a 	beq	29d8 <zlib_inflateIncomp+0x194>

    while (len > 0) {
        k = len < NMAX ? len : NMAX;
    28ac:	e30175b0 	movw	r7, #5552	; 0x15b0
        }
        if (k != 0) do {
            s1 += *buf++;
	    s2 += s1;
        } while (--k);
        s1 %= BASE;
    28b0:	e30f6ff1 	movw	r6, #65521	; 0xfff1
    unsigned long s2 = (adler >> 16) & 0xffff;
    int k;

    if (buf == NULL) return 1L;

    while (len > 0) {
    28b4:	e35c0000 	cmp	ip, #0
    28b8:	0a000045 	beq	29d4 <zlib_inflateIncomp+0x190>
        k = len < NMAX ? len : NMAX;
    28bc:	e15c0007 	cmp	ip, r7
    28c0:	31a0000c 	movcc	r0, ip
    28c4:	21a00007 	movcs	r0, r7
        len -= k;
    28c8:	e060c00c 	rsb	ip, r0, ip
        while (k >= 16) {
    28cc:	e350000f 	cmp	r0, #15
    28d0:	da000032 	ble	29a0 <zlib_inflateIncomp+0x15c>
            DO16(buf);
    28d4:	e5d38000 	ldrb	r8, [r3]
	    buf += 16;
            k -= 16;
    28d8:	e2400010 	sub	r0, r0, #16
    while (len > 0) {
        k = len < NMAX ? len : NMAX;
        len -= k;
        while (k >= 16) {
            DO16(buf);
	    buf += 16;
    28dc:	e2833010 	add	r3, r3, #16

    while (len > 0) {
        k = len < NMAX ? len : NMAX;
        len -= k;
        while (k >= 16) {
            DO16(buf);
    28e0:	e0882002 	add	r2, r8, r2
    28e4:	e553800f 	ldrb	r8, [r3, #-15]
    28e8:	e0821001 	add	r1, r2, r1
    28ec:	e0822008 	add	r2, r2, r8
    28f0:	e553800e 	ldrb	r8, [r3, #-14]
    28f4:	e0811002 	add	r1, r1, r2
    28f8:	e0822008 	add	r2, r2, r8
    28fc:	e553800d 	ldrb	r8, [r3, #-13]
    2900:	e0811002 	add	r1, r1, r2
    2904:	e0822008 	add	r2, r2, r8
    2908:	e553800c 	ldrb	r8, [r3, #-12]
    290c:	e0811002 	add	r1, r1, r2
    2910:	e0822008 	add	r2, r2, r8
    2914:	e553800b 	ldrb	r8, [r3, #-11]
    2918:	e0811002 	add	r1, r1, r2
    291c:	e0822008 	add	r2, r2, r8
    2920:	e553800a 	ldrb	r8, [r3, #-10]
    2924:	e0811002 	add	r1, r1, r2
    2928:	e0822008 	add	r2, r2, r8
    292c:	e5538009 	ldrb	r8, [r3, #-9]
    2930:	e0811002 	add	r1, r1, r2
    2934:	e0822008 	add	r2, r2, r8
    2938:	e5538008 	ldrb	r8, [r3, #-8]
    293c:	e0811002 	add	r1, r1, r2
    2940:	e0822008 	add	r2, r2, r8
    2944:	e5538007 	ldrb	r8, [r3, #-7]
    2948:	e0811002 	add	r1, r1, r2
    294c:	e0822008 	add	r2, r2, r8
    2950:	e5538006 	ldrb	r8, [r3, #-6]
    2954:	e0811002 	add	r1, r1, r2
    2958:	e0822008 	add	r2, r2, r8
    295c:	e5538005 	ldrb	r8, [r3, #-5]
    2960:	e0811002 	add	r1, r1, r2
    2964:	e0822008 	add	r2, r2, r8
    2968:	e5538004 	ldrb	r8, [r3, #-4]
    296c:	e0811002 	add	r1, r1, r2
    2970:	e0822008 	add	r2, r2, r8
    2974:	e5538003 	ldrb	r8, [r3, #-3]
    2978:	e0811002 	add	r1, r1, r2
    297c:	e0822008 	add	r2, r2, r8
    2980:	e5538002 	ldrb	r8, [r3, #-2]
    2984:	e0811002 	add	r1, r1, r2
    2988:	e0822008 	add	r2, r2, r8
    298c:	e5538001 	ldrb	r8, [r3, #-1]
    2990:	e0811002 	add	r1, r1, r2
    2994:	e0822008 	add	r2, r2, r8
    2998:	e0811002 	add	r1, r1, r2
    299c:	eaffffca 	b	28cc <zlib_inflateIncomp+0x88>
	    buf += 16;
            k -= 16;
        }
        if (k != 0) do {
    29a0:	e3500000 	cmp	r0, #0
    29a4:	0a000005 	beq	29c0 <zlib_inflateIncomp+0x17c>
    29a8:	e0830000 	add	r0, r3, r0
            s1 += *buf++;
    29ac:	e4d38001 	ldrb	r8, [r3], #1
	    s2 += s1;
        } while (--k);
    29b0:	e1530000 	cmp	r3, r0
            DO16(buf);
	    buf += 16;
            k -= 16;
        }
        if (k != 0) do {
            s1 += *buf++;
    29b4:	e0822008 	add	r2, r2, r8
	    s2 += s1;
    29b8:	e0811002 	add	r1, r1, r2
        } while (--k);
    29bc:	1afffffa 	bne	29ac <zlib_inflateIncomp+0x168>
        s1 %= BASE;
    29c0:	e730f612 	udiv	r0, r2, r6
    29c4:	e0622096 	mls	r2, r6, r0, r2
        s2 %= BASE;
    29c8:	e730f611 	udiv	r0, r1, r6
    29cc:	e0611096 	mls	r1, r6, r0, r1
    29d0:	eaffffb7 	b	28b4 <zlib_inflateIncomp+0x70>
    }
    return (s2 << 16) | s1;
    29d4:	e1822801 	orr	r2, r2, r1, lsl #16

    /* Restore saved variables */
    z->avail_out = saved_ao;
    z->next_out = saved_no;

    z->adler = state->check =
    29d8:	e5852018 	str	r2, [r5, #24]
        UPDATE(state->check, z->next_in, z->avail_in);

    z->total_out += z->avail_in;
    29dc:	e5943004 	ldr	r3, [r4, #4]
    z->total_in += z->avail_in;
    z->next_in += z->avail_in;
    state->total += z->avail_in;
    z->avail_in = 0;
    29e0:	e3a00000 	mov	r0, #0

    /* Restore saved variables */
    z->avail_out = saved_ao;
    z->next_out = saved_no;

    z->adler = state->check =
    29e4:	e5842028 	str	r2, [r4, #40]	; 0x28
        UPDATE(state->check, z->next_in, z->avail_in);

    z->total_out += z->avail_in;
    29e8:	e5942014 	ldr	r2, [r4, #20]
    29ec:	e0822003 	add	r2, r2, r3
    29f0:	e5842014 	str	r2, [r4, #20]
    z->total_in += z->avail_in;
    29f4:	e5942008 	ldr	r2, [r4, #8]
    29f8:	e0822003 	add	r2, r2, r3
    29fc:	e5842008 	str	r2, [r4, #8]
    z->next_in += z->avail_in;
    2a00:	e5942000 	ldr	r2, [r4]
    2a04:	e0822003 	add	r2, r2, r3
    2a08:	e5842000 	str	r2, [r4]
    state->total += z->avail_in;
    2a0c:	e595201c 	ldr	r2, [r5, #28]
    2a10:	e0823003 	add	r3, r2, r3
    2a14:	e585301c 	str	r3, [r5, #28]
    z->avail_in = 0;
    2a18:	e5840004 	str	r0, [r4, #4]

    return Z_OK;
    2a1c:	e8bd81f0 	pop	{r4, r5, r6, r7, r8, pc}
    struct inflate_state *state = (struct inflate_state *)z->state;
    Byte *saved_no = z->next_out;
    uInt saved_ao = z->avail_out;

    if (state->mode != TYPE && state->mode != HEAD)
	return Z_DATA_ERROR;
    2a20:	e3e00002 	mvn	r0, #2
    z->next_in += z->avail_in;
    state->total += z->avail_in;
    z->avail_in = 0;

    return Z_OK;
}
    2a24:	e8bd81f0 	pop	{r4, r5, r6, r7, r8, pc}

00002a28 <do_decompress>:
#define memcpy memcpy
#include "../../../../lib/decompress_unxz.c"
#endif

int do_decompress(u8 *input, int len, u8 *output, void (*error)(char *x))
{
    2a28:	e92d43f8 	push	{r3, r4, r5, r6, r7, r8, r9, lr}
    2a2c:	e1a08000 	mov	r8, r0
		out_buf = malloc(out_len);
	} else {
		out_len = 0x7fffffff; /* no limit */
	}
	if (!out_buf) {
		error("Out of memory while allocating output buffer");
    2a30:	e59f01f4 	ldr	r0, [pc, #500]	; 2c2c <do_decompress+0x204>
		out_len = 0x8000; /* 32 K */
		out_buf = malloc(out_len);
	} else {
		out_len = 0x7fffffff; /* no limit */
	}
	if (!out_buf) {
    2a34:	e2529000 	subs	r9, r2, #0
    2a38:	e1a05001 	mov	r5, r1
    2a3c:	e1a07003 	mov	r7, r3
		error("Out of memory while allocating output buffer");
    2a40:	e08f0000 	add	r0, pc, r0
		out_len = 0x8000; /* 32 K */
		out_buf = malloc(out_len);
	} else {
		out_len = 0x7fffffff; /* no limit */
	}
	if (!out_buf) {
    2a44:	0a000008 	beq	2a6c <do_decompress+0x44>
		error("Out of memory while allocating output buffer");
		goto gunzip_nomem1;
	}

	if (buf)
    2a48:	e3580000 	cmp	r8, #0
    2a4c:	11a06008 	movne	r6, r8
    2a50:	1a000009 	bne	2a7c <do_decompress+0x54>
		zbuf = buf;
	else {
		zbuf = malloc(GZIP_IOBUF_SIZE);
    2a54:	e3a00901 	mov	r0, #16384	; 0x4000
    2a58:	ebfff7b6 	bl	938 <malloc>
		len = 0;
	}
	if (!zbuf) {
    2a5c:	e2506000 	subs	r6, r0, #0
    2a60:	1a000004 	bne	2a78 <do_decompress+0x50>
		error("Out of memory while allocating input buffer");
    2a64:	e59f01c4 	ldr	r0, [pc, #452]	; 2c30 <do_decompress+0x208>
    2a68:	e08f0000 	add	r0, pc, r0
    2a6c:	e12fff37 	blx	r7
	u8 *zbuf;
	struct z_stream_s *strm;
	int rc;
	size_t out_len;

	rc = -1;
    2a70:	e3e05000 	mvn	r5, #0
    2a74:	ea00006a 	b	2c24 <do_decompress+0x1fc>

	if (buf)
		zbuf = buf;
	else {
		zbuf = malloc(GZIP_IOBUF_SIZE);
		len = 0;
    2a78:	e1a05008 	mov	r5, r8
	if (!zbuf) {
		error("Out of memory while allocating input buffer");
		goto gunzip_nomem2;
	}

	strm = malloc(sizeof(*strm));
    2a7c:	e3a00030 	mov	r0, #48	; 0x30
    2a80:	ebfff7ac 	bl	938 <malloc>
	if (strm == NULL) {
    2a84:	e2504000 	subs	r4, r0, #0
    2a88:	1a000004 	bne	2aa0 <do_decompress+0x78>
		error("Out of memory while allocating z_stream");
    2a8c:	e59f01a0 	ldr	r0, [pc, #416]	; 2c34 <do_decompress+0x20c>
	u8 *zbuf;
	struct z_stream_s *strm;
	int rc;
	size_t out_len;

	rc = -1;
    2a90:	e3e05000 	mvn	r5, #0
		goto gunzip_nomem2;
	}

	strm = malloc(sizeof(*strm));
	if (strm == NULL) {
		error("Out of memory while allocating z_stream");
    2a94:	e08f0000 	add	r0, pc, r0
    2a98:	e12fff37 	blx	r7
    2a9c:	ea00005d 	b	2c18 <do_decompress+0x1f0>
		goto gunzip_nomem3;
	}

	strm->workspace = malloc(flush ? zlib_inflate_workspacesize() :
    2aa0:	e302052c 	movw	r0, #9516	; 0x252c
    2aa4:	ebfff7a3 	bl	938 <malloc>
				 sizeof(struct inflate_state));
	if (strm->workspace == NULL) {
    2aa8:	e3500000 	cmp	r0, #0
	if (strm == NULL) {
		error("Out of memory while allocating z_stream");
		goto gunzip_nomem3;
	}

	strm->workspace = malloc(flush ? zlib_inflate_workspacesize() :
    2aac:	e5840020 	str	r0, [r4, #32]
				 sizeof(struct inflate_state));
	if (strm->workspace == NULL) {
    2ab0:	1a000004 	bne	2ac8 <do_decompress+0xa0>
		error("Out of memory while allocating workspace");
    2ab4:	e59f017c 	ldr	r0, [pc, #380]	; 2c38 <do_decompress+0x210>
	u8 *zbuf;
	struct z_stream_s *strm;
	int rc;
	size_t out_len;

	rc = -1;
    2ab8:	e3e05000 	mvn	r5, #0
	}

	strm->workspace = malloc(flush ? zlib_inflate_workspacesize() :
				 sizeof(struct inflate_state));
	if (strm->workspace == NULL) {
		error("Out of memory while allocating workspace");
    2abc:	e08f0000 	add	r0, pc, r0
    2ac0:	e12fff37 	blx	r7
    2ac4:	ea000052 	b	2c14 <do_decompress+0x1ec>
	}

	if (!fill)
		fill = nofill;

	if (len == 0)
    2ac8:	e3550000 	cmp	r5, #0
    2acc:	1a000003 	bne	2ae0 <do_decompress+0xb8>
		len = fill(zbuf, GZIP_IOBUF_SIZE);
    2ad0:	e1a00006 	mov	r0, r6
    2ad4:	e3a01901 	mov	r1, #16384	; 0x4000
    2ad8:	ebfff7bb 	bl	9cc <nofill>
    2adc:	e1a05000 	mov	r5, r0

	/* verify the gzip header */
	if (len < 10 ||
    2ae0:	e3550009 	cmp	r5, #9
    2ae4:	da000008 	ble	2b0c <do_decompress+0xe4>
    2ae8:	e5d63000 	ldrb	r3, [r6]
    2aec:	e353001f 	cmp	r3, #31
    2af0:	1a000005 	bne	2b0c <do_decompress+0xe4>
	   zbuf[0] != 0x1f || zbuf[1] != 0x8b || zbuf[2] != 0x08) {
    2af4:	e5d63001 	ldrb	r3, [r6, #1]
    2af8:	e353008b 	cmp	r3, #139	; 0x8b
    2afc:	1a000002 	bne	2b0c <do_decompress+0xe4>
    2b00:	e5d63002 	ldrb	r3, [r6, #2]
    2b04:	e3530008 	cmp	r3, #8
    2b08:	0a000002 	beq	2b18 <do_decompress+0xf0>
		if (pos)
			*pos = 0;
		error("Not a gzip file");
    2b0c:	e59f0128 	ldr	r0, [pc, #296]	; 2c3c <do_decompress+0x214>
    2b10:	e08f0000 	add	r0, pc, r0
    2b14:	ea000021 	b	2ba0 <do_decompress+0x178>
	}

	/* skip over gzip header (1f,8b,08... 10 bytes total +
	 * possible asciz filename)
	 */
	strm->next_in = zbuf + 10;
    2b18:	e286300a 	add	r3, r6, #10
	strm->avail_in = len - 10;
    2b1c:	e245500a 	sub	r5, r5, #10
	}

	/* skip over gzip header (1f,8b,08... 10 bytes total +
	 * possible asciz filename)
	 */
	strm->next_in = zbuf + 10;
    2b20:	e5843000 	str	r3, [r4]
	strm->avail_in = len - 10;
    2b24:	e5845004 	str	r5, [r4, #4]
	/* skip over asciz filename */
	if (zbuf[3] & 0x8) {
    2b28:	e5d63003 	ldrb	r3, [r6, #3]
    2b2c:	e3130008 	tst	r3, #8
    2b30:	1a000015 	bne	2b8c <do_decompress+0x164>
			--strm->avail_in;
		} while (*strm->next_in++);
	}

	strm->next_out = out_buf;
	strm->avail_out = out_len;
    2b34:	e3e03102 	mvn	r3, #-2147483648	; 0x80000000
			}
			--strm->avail_in;
		} while (*strm->next_in++);
	}

	strm->next_out = out_buf;
    2b38:	e584900c 	str	r9, [r4, #12]
	strm->avail_out = out_len;

	rc = zlib_inflateInit2(strm, -MAX_WBITS);
    2b3c:	e1a00004 	mov	r0, r4
    2b40:	e3e0100e 	mvn	r1, #14
			--strm->avail_in;
		} while (*strm->next_in++);
	}

	strm->next_out = out_buf;
	strm->avail_out = out_len;
    2b44:	e5843010 	str	r3, [r4, #16]

	rc = zlib_inflateInit2(strm, -MAX_WBITS);
    2b48:	ebfffac6 	bl	1668 <zlib_inflateInit2>

	if (!flush) {
		WS(strm)->inflate_state.wsize = 0;
    2b4c:	e5942020 	ldr	r2, [r4, #32]
    2b50:	e3a03000 	mov	r3, #0
		WS(strm)->inflate_state.window = NULL;
	}

	while (rc == Z_OK) {
    2b54:	e2505000 	subs	r5, r0, #0
	strm->avail_out = out_len;

	rc = zlib_inflateInit2(strm, -MAX_WBITS);

	if (!flush) {
		WS(strm)->inflate_state.wsize = 0;
    2b58:	e5823024 	str	r3, [r2, #36]	; 0x24
		WS(strm)->inflate_state.window = NULL;
    2b5c:	e5942020 	ldr	r2, [r4, #32]
    2b60:	e5823030 	str	r3, [r2, #48]	; 0x30
	}

	while (rc == Z_OK) {
    2b64:	0a000010 	beq	2bac <do_decompress+0x184>
    2b68:	ea000026 	b	2c08 <do_decompress+0x1e0>
			 */
			if (strm->avail_in == 0) {
				error("header error");
				goto gunzip_5;
			}
			--strm->avail_in;
    2b6c:	e2433001 	sub	r3, r3, #1
    2b70:	e5843004 	str	r3, [r4, #4]
		} while (*strm->next_in++);
    2b74:	e5943000 	ldr	r3, [r4]
    2b78:	e2832001 	add	r2, r3, #1
    2b7c:	e5842000 	str	r2, [r4]
    2b80:	e5d33000 	ldrb	r3, [r3]
    2b84:	e3530000 	cmp	r3, #0
    2b88:	0affffe9 	beq	2b34 <do_decompress+0x10c>
			/*
			 * If the filename doesn't fit into the buffer,
			 * the file is very probably corrupt. Don't try
			 * to read more data.
			 */
			if (strm->avail_in == 0) {
    2b8c:	e5943004 	ldr	r3, [r4, #4]
    2b90:	e3530000 	cmp	r3, #0
    2b94:	1afffff4 	bne	2b6c <do_decompress+0x144>
				error("header error");
    2b98:	e59f00a0 	ldr	r0, [pc, #160]	; 2c40 <do_decompress+0x218>
    2b9c:	e08f0000 	add	r0, pc, r0
    2ba0:	e12fff37 	blx	r7
	u8 *zbuf;
	struct z_stream_s *strm;
	int rc;
	size_t out_len;

	rc = -1;
    2ba4:	e3e05000 	mvn	r5, #0
    2ba8:	ea000018 	b	2c10 <do_decompress+0x1e8>
		WS(strm)->inflate_state.wsize = 0;
		WS(strm)->inflate_state.window = NULL;
	}

	while (rc == Z_OK) {
		if (strm->avail_in == 0) {
    2bac:	e5943004 	ldr	r3, [r4, #4]
    2bb0:	e3530000 	cmp	r3, #0
    2bb4:	1a000008 	bne	2bdc <do_decompress+0x1b4>
			/* TODO: handle case where both pos and fill are set */
			len = fill(zbuf, GZIP_IOBUF_SIZE);
    2bb8:	e1a00006 	mov	r0, r6
    2bbc:	e3a01901 	mov	r1, #16384	; 0x4000
    2bc0:	ebfff781 	bl	9cc <nofill>
			if (len < 0) {
    2bc4:	e3500000 	cmp	r0, #0
				rc = -1;
				error("read error");
    2bc8:	b59f0074 	ldrlt	r0, [pc, #116]	; 2c44 <do_decompress+0x21c>
    2bcc:	b08f0000 	addlt	r0, pc, r0
    2bd0:	ba00000a 	blt	2c00 <do_decompress+0x1d8>
				break;
			}
			strm->next_in = zbuf;
    2bd4:	e5846000 	str	r6, [r4]
			strm->avail_in = len;
    2bd8:	e5840004 	str	r0, [r4, #4]
		}
		rc = zlib_inflate(strm, 0);
    2bdc:	e1a00004 	mov	r0, r4
    2be0:	e3a01000 	mov	r1, #0
    2be4:	ebfffab6 	bl	16c4 <zlib_inflate>
			strm->next_out = out_buf;
			strm->avail_out = out_len;
		}

		/* after Z_FINISH, only Z_STREAM_END is "we unpacked it all" */
		if (rc == Z_STREAM_END) {
    2be8:	e3500001 	cmp	r0, #1
    2bec:	0a000005 	beq	2c08 <do_decompress+0x1e0>
			rc = 0;
			break;
		} else if (rc != Z_OK) {
    2bf0:	e3500000 	cmp	r0, #0
    2bf4:	0affffec 	beq	2bac <do_decompress+0x184>
			error("uncompression error");
    2bf8:	e59f0048 	ldr	r0, [pc, #72]	; 2c48 <do_decompress+0x220>
    2bfc:	e08f0000 	add	r0, pc, r0
			rc = -1;
    2c00:	e3e05000 	mvn	r5, #0
		/* after Z_FINISH, only Z_STREAM_END is "we unpacked it all" */
		if (rc == Z_STREAM_END) {
			rc = 0;
			break;
		} else if (rc != Z_OK) {
			error("uncompression error");
    2c04:	e12fff37 	blx	r7
			rc = -1;
		}
	}

	zlib_inflateEnd(strm);
    2c08:	e1a00004 	mov	r0, r4
    2c0c:	ebffff03 	bl	2820 <zlib_inflateEnd>
	if (pos)
		/* add + 8 to skip over trailer */
		*pos = strm->next_in - zbuf+8;

gunzip_5:
	free(strm->workspace);
    2c10:	ebfff79d 	bl	a8c <free.isra.0>
gunzip_nomem4:
	free(strm);
    2c14:	ebfff79c 	bl	a8c <free.isra.0>
gunzip_nomem3:
	if (!buf)
    2c18:	e3580000 	cmp	r8, #0
    2c1c:	1a000000 	bne	2c24 <do_decompress+0x1fc>
		free(zbuf);
    2c20:	ebfff799 	bl	a8c <free.isra.0>
	return decompress(input, len, NULL, NULL, output, NULL, error);
}
    2c24:	e1a00005 	mov	r0, r5
    2c28:	e8bd83f8 	pop	{r3, r4, r5, r6, r7, r8, r9, pc}
    2c2c:	000012bd 	.word	0x000012bd
    2c30:	000012c2 	.word	0x000012c2
    2c34:	000012c2 	.word	0x000012c2
    2c38:	000012c2 	.word	0x000012c2
    2c3c:	00001297 	.word	0x00001297
    2c40:	0000121b 	.word	0x0000121b
    2c44:	000011f8 	.word	0x000011f8
    2c48:	000011d3 	.word	0x000011d3

00002c4c <memcpy>:
 */

#include <linux/string.h>

void *memcpy(void *__dest, __const void *__src, size_t __n)
{
    2c4c:	e92d4070 	push	{r4, r5, r6, lr}
	int i = 0;
	unsigned char *d = (unsigned char *)__dest, *s = (unsigned char *)__src;

	for (i = __n >> 3; i > 0; i--) {
    2c50:	e1a041a2 	lsr	r4, r2, #3
    2c54:	e1a03000 	mov	r3, r0
    2c58:	e1a0c001 	mov	ip, r1
    2c5c:	e1a05004 	mov	r5, r4
    2c60:	e3550000 	cmp	r5, #0
    2c64:	da000013 	ble	2cb8 <memcpy+0x6c>
		*d++ = *s++;
    2c68:	e5dc6000 	ldrb	r6, [ip]
void *memcpy(void *__dest, __const void *__src, size_t __n)
{
	int i = 0;
	unsigned char *d = (unsigned char *)__dest, *s = (unsigned char *)__src;

	for (i = __n >> 3; i > 0; i--) {
    2c6c:	e2455001 	sub	r5, r5, #1
    2c70:	e2833008 	add	r3, r3, #8
    2c74:	e28cc008 	add	ip, ip, #8
		*d++ = *s++;
    2c78:	e5436008 	strb	r6, [r3, #-8]
		*d++ = *s++;
    2c7c:	e55c6007 	ldrb	r6, [ip, #-7]
    2c80:	e5436007 	strb	r6, [r3, #-7]
		*d++ = *s++;
    2c84:	e55c6006 	ldrb	r6, [ip, #-6]
    2c88:	e5436006 	strb	r6, [r3, #-6]
		*d++ = *s++;
    2c8c:	e55c6005 	ldrb	r6, [ip, #-5]
    2c90:	e5436005 	strb	r6, [r3, #-5]
		*d++ = *s++;
    2c94:	e55c6004 	ldrb	r6, [ip, #-4]
    2c98:	e5436004 	strb	r6, [r3, #-4]
		*d++ = *s++;
    2c9c:	e55c6003 	ldrb	r6, [ip, #-3]
    2ca0:	e5436003 	strb	r6, [r3, #-3]
		*d++ = *s++;
    2ca4:	e55c6002 	ldrb	r6, [ip, #-2]
    2ca8:	e5436002 	strb	r6, [r3, #-2]
		*d++ = *s++;
    2cac:	e55c6001 	ldrb	r6, [ip, #-1]
    2cb0:	e5436001 	strb	r6, [r3, #-1]
    2cb4:	eaffffe9 	b	2c60 <memcpy+0x14>
    2cb8:	e1c44fc4 	bic	r4, r4, r4, asr #31
	}

	if (__n & 1 << 2) {
    2cbc:	e3120004 	tst	r2, #4
    2cc0:	e1a0c184 	lsl	ip, r4, #3
    2cc4:	e080300c 	add	r3, r0, ip
    2cc8:	e081c00c 	add	ip, r1, ip
    2ccc:	0a000009 	beq	2cf8 <memcpy+0xac>
		*d++ = *s++;
    2cd0:	e7d11184 	ldrb	r1, [r1, r4, lsl #3]
		*d++ = *s++;
		*d++ = *s++;
		*d++ = *s++;
    2cd4:	e28cc004 	add	ip, ip, #4
    2cd8:	e2833004 	add	r3, r3, #4
		*d++ = *s++;
		*d++ = *s++;
	}

	if (__n & 1 << 2) {
		*d++ = *s++;
    2cdc:	e7c01184 	strb	r1, [r0, r4, lsl #3]
		*d++ = *s++;
    2ce0:	e55c1003 	ldrb	r1, [ip, #-3]
    2ce4:	e5431003 	strb	r1, [r3, #-3]
		*d++ = *s++;
    2ce8:	e55c1002 	ldrb	r1, [ip, #-2]
    2cec:	e5431002 	strb	r1, [r3, #-2]
		*d++ = *s++;
    2cf0:	e55c1001 	ldrb	r1, [ip, #-1]
    2cf4:	e5431001 	strb	r1, [r3, #-1]
	}

	if (__n & 1 << 1) {
    2cf8:	e3120002 	tst	r2, #2
    2cfc:	0a000007 	beq	2d20 <memcpy+0xd4>
		*d++ = *s++;
    2d00:	e1a0400c 	mov	r4, ip
    2d04:	e1a01003 	mov	r1, r3
    2d08:	e4d45002 	ldrb	r5, [r4], #2
    2d0c:	e4c15002 	strb	r5, [r1], #2
		*d++ = *s++;
    2d10:	e5dcc001 	ldrb	ip, [ip, #1]
    2d14:	e5c3c001 	strb	ip, [r3, #1]
    2d18:	e1a0c004 	mov	ip, r4
    2d1c:	e1a03001 	mov	r3, r1
	}

	if (__n & 1)
    2d20:	e3120001 	tst	r2, #1
		*d++ = *s++;
    2d24:	15dc2000 	ldrbne	r2, [ip]
    2d28:	15c32000 	strbne	r2, [r3]

	return __dest;
}
    2d2c:	e8bd8070 	pop	{r4, r5, r6, pc}

00002d30 <memmove>:
void *memmove(void *__dest, __const void *__src, size_t count)
{
	unsigned char *d = __dest;
	const unsigned char *s = __src;

	if (__dest == __src)
    2d30:	e1500001 	cmp	r0, r1

	return __dest;
}

void *memmove(void *__dest, __const void *__src, size_t count)
{
    2d34:	e92d4010 	push	{r4, lr}
    2d38:	e1a0c000 	mov	ip, r0
    2d3c:	e1a04001 	mov	r4, r1
    2d40:	e1a03002 	mov	r3, r2
	unsigned char *d = __dest;
	const unsigned char *s = __src;

	if (__dest == __src)
    2d44:	0a000006 	beq	2d64 <memmove+0x34>
		return __dest;

	if (__dest < __src)
    2d48:	2a000001 	bcs	2d54 <memmove+0x24>
		return memcpy(__dest, __src, count);

	while (count--)
		d[count] = s[count];
	return __dest;
}
    2d4c:	e8bd4010 	pop	{r4, lr}

	if (__dest == __src)
		return __dest;

	if (__dest < __src)
		return memcpy(__dest, __src, count);
    2d50:	eaffffbd 	b	2c4c <memcpy>

	while (count--)
    2d54:	e2533001 	subs	r3, r3, #1
		d[count] = s[count];
    2d58:	27d42003 	ldrbcs	r2, [r4, r3]
    2d5c:	27cc2003 	strbcs	r2, [ip, r3]
    2d60:	2afffffb 	bcs	2d54 <memmove+0x24>
	return __dest;
}
    2d64:	e1a0000c 	mov	r0, ip
    2d68:	e8bd8010 	pop	{r4, pc}

00002d6c <strlen>:

size_t strlen(const char *s)
{
    2d6c:	e1a03000 	mov	r3, r0
    2d70:	e1a02003 	mov	r2, r3
    2d74:	e2833001 	add	r3, r3, #1
	const char *sc = s;

	while (*sc != '\0')
    2d78:	e5d21000 	ldrb	r1, [r2]
    2d7c:	e3510000 	cmp	r1, #0
    2d80:	1afffffa 	bne	2d70 <strlen+0x4>
		sc++;
	return sc - s;
}
    2d84:	e0600002 	rsb	r0, r0, r2
    2d88:	e12fff1e 	bx	lr

00002d8c <memcmp>:

int memcmp(const void *cs, const void *ct, size_t count)
{
    2d8c:	e1a03000 	mov	r3, r0
	const unsigned char *su1 = cs, *su2 = ct, *end = su1 + count;
    2d90:	e0802002 	add	r2, r0, r2
	int res = 0;

	while (su1 < end) {
    2d94:	e1530002 	cmp	r3, r2
    2d98:	2a000004 	bcs	2db0 <memcmp+0x24>
		res = *su1++ - *su2++;
    2d9c:	e4d3c001 	ldrb	ip, [r3], #1
    2da0:	e4d10001 	ldrb	r0, [r1], #1
		if (res)
    2da4:	e05c0000 	subs	r0, ip, r0
    2da8:	0afffff9 	beq	2d94 <memcmp+0x8>
    2dac:	e12fff1e 	bx	lr
    2db0:	e3a00000 	mov	r0, #0
			break;
	}
	return res;
}
    2db4:	e12fff1e 	bx	lr

00002db8 <strcmp>:

int strcmp(const char *cs, const char *ct)
{
    2db8:	e3a03000 	mov	r3, #0
	unsigned char c1, c2;
	int res = 0;

	do {
		c1 = *cs++;
    2dbc:	e7d02003 	ldrb	r2, [r0, r3]
		c2 = *ct++;
		res = c1 - c2;
    2dc0:	e7d1c003 	ldrb	ip, [r1, r3]
		if (res)
    2dc4:	e052c00c 	subs	ip, r2, ip
    2dc8:	1a000002 	bne	2dd8 <strcmp+0x20>
			break;
	} while (c1);
    2dcc:	e3520000 	cmp	r2, #0
    2dd0:	e2833001 	add	r3, r3, #1
    2dd4:	1afffff8 	bne	2dbc <strcmp+0x4>
	return res;
}
    2dd8:	e1a0000c 	mov	r0, ip
    2ddc:	e12fff1e 	bx	lr

00002de0 <memchr>:
void *memchr(const void *s, int c, size_t count)
{
	const unsigned char *p = s;

	while (count--)
		if ((unsigned char)c == *p++)
    2de0:	e6ef1071 	uxtb	r1, r1
    2de4:	e0802002 	add	r2, r0, r2

void *memchr(const void *s, int c, size_t count)
{
	const unsigned char *p = s;

	while (count--)
    2de8:	e1500002 	cmp	r0, r2
    2dec:	0a000005 	beq	2e08 <memchr+0x28>
		if ((unsigned char)c == *p++)
    2df0:	e1a03000 	mov	r3, r0
    2df4:	e4d3c001 	ldrb	ip, [r3], #1
    2df8:	e15c0001 	cmp	ip, r1
    2dfc:	012fff1e 	bxeq	lr
    2e00:	e1a00003 	mov	r0, r3
    2e04:	eafffff7 	b	2de8 <memchr+0x8>
			return (void *)(p - 1);
	return NULL;
    2e08:	e3a00000 	mov	r0, #0
}
    2e0c:	e12fff1e 	bx	lr

00002e10 <strchr>:

char *strchr(const char *s, int c)
{
	while (*s != (char)c)
    2e10:	e6ef1071 	uxtb	r1, r1
    2e14:	e1a02000 	mov	r2, r0
    2e18:	e4d03001 	ldrb	r3, [r0], #1
    2e1c:	e1530001 	cmp	r3, r1
    2e20:	0a000003 	beq	2e34 <strchr+0x24>
		if (*s++ == '\0')
    2e24:	e3530000 	cmp	r3, #0
    2e28:	1afffff9 	bne	2e14 <strchr+0x4>
			return NULL;
    2e2c:	e1a00003 	mov	r0, r3
	return (char *)s;
}
    2e30:	e12fff1e 	bx	lr
    2e34:	e1a00002 	mov	r0, r2
    2e38:	e12fff1e 	bx	lr

00002e3c <memset>:

#undef memset

void *memset(void *s, int c, size_t count)
{
    2e3c:	e0802002 	add	r2, r0, r2
	char *xs = s;
    2e40:	e1a03000 	mov	r3, r0
	while (count--)
    2e44:	e1530002 	cmp	r3, r2
		*xs++ = c;
    2e48:	14c31001 	strbne	r1, [r3], #1
    2e4c:	1afffffc 	bne	2e44 <memset+0x8>
	return s;
}
    2e50:	e12fff1e 	bx	lr

00002e54 <__memzero>:

void __memzero(void *s, size_t count)
{
    2e54:	e1a02001 	mov	r2, r1
	memset(s, 0, count);
    2e58:	e3a01000 	mov	r1, #0
    2e5c:	eafffff6 	b	2e3c <memset>

00002e60 <__aeabi_uidiv>:
	addhi	\order, \order, #3
	addls	\order, \order, \divisor, lsr #1

#endif

.endm
    2e60:	e2512001 	subs	r2, r1, #1

    2e64:	01a0f00e 	moveq	pc, lr

    2e68:	3a0000b8 	bcc	3150 <Ldiv0>
.macro ARM_MOD_BODY dividend, divisor, order, spare
    2e6c:	e1500001 	cmp	r0, r1

    2e70:	9a00001a 	bls	2ee0 <__aeabi_uidiv+0x80>
#if __LINUX_ARM_ARCH__ >= 5
    2e74:	e1110002 	tst	r1, r2

    2e78:	0a00001b 	beq	2eec <__aeabi_uidiv+0x8c>
	clz	\order, \divisor
	clz	\spare, \dividend
    2e7c:	e16f3f11 	clz	r3, r1
    2e80:	e16f2f10 	clz	r2, r0
    2e84:	e0432002 	sub	r2, r3, r2
    2e88:	e3a03001 	mov	r3, #1
    2e8c:	e1a01211 	lsl	r1, r1, r2
    2e90:	e1a03213 	lsl	r3, r3, r2
    2e94:	e3a02000 	mov	r2, #0
	blo	1b

	mov	\result, #0

#endif

    2e98:	e1500001 	cmp	r0, r1
    2e9c:	20400001 	subcs	r0, r0, r1
    2ea0:	21822003 	orrcs	r2, r2, r3
    2ea4:	e15000a1 	cmp	r0, r1, lsr #1
    2ea8:	204000a1 	subcs	r0, r0, r1, lsr #1
    2eac:	218220a3 	orrcs	r2, r2, r3, lsr #1
    2eb0:	e1500121 	cmp	r0, r1, lsr #2
    2eb4:	20400121 	subcs	r0, r0, r1, lsr #2
    2eb8:	21822123 	orrcs	r2, r2, r3, lsr #2
    2ebc:	e15001a1 	cmp	r0, r1, lsr #3
    2ec0:	204001a1 	subcs	r0, r0, r1, lsr #3
    2ec4:	218221a3 	orrcs	r2, r2, r3, lsr #3
    2ec8:	e3500000 	cmp	r0, #0
    2ecc:	11b03223 	lsrsne	r3, r3, #4
    2ed0:	11a01221 	lsrne	r1, r1, #4
    2ed4:	1affffef 	bne	2e98 <__aeabi_uidiv+0x38>
#if __LINUX_ARM_ARCH__ >= 5

	clz	\order, \divisor
	clz	\spare, \dividend
	sub	\order, \order, \spare
	mov	\divisor, \divisor, lsl \order
    2ed8:	e1a00002 	mov	r0, r2

    2edc:	e1a0f00e 	mov	pc, lr
#else

    2ee0:	03a00001 	moveq	r0, #1
	mov	\order, #0
    2ee4:	13a00000 	movne	r0, #0

    2ee8:	e1a0f00e 	mov	pc, lr
	@ Unless the divisor is very big, shift it up in multiples of
	@ four bits, since this is the amount of unwinding in the main
    2eec:	e16f2f11 	clz	r2, r1
    2ef0:	e262201f 	rsb	r2, r2, #31
	@ division loop.  Continue shifting until the divisor is 
	@ larger than the dividend.
    2ef4:	e1a00230 	lsr	r0, r0, r2
1:	cmp	\divisor, #0x10000000
    2ef8:	e1a0f00e 	mov	pc, lr

00002efc <__umodsi3>:
	blo	1b

	@ For very big divisors, we must shift it a bit at a time, or
	@ we will be in danger of overflowing.
1:	cmp	\divisor, #0x80000000
	cmplo	\divisor, \dividend
    2efc:	e2512001 	subs	r2, r1, #1
	movlo	\divisor, \divisor, lsl #1
    2f00:	3a000092 	bcc	3150 <Ldiv0>
	addlo	\order, \order, #1
    2f04:	11500001 	cmpne	r0, r1
	blo	1b
    2f08:	03a00000 	moveq	r0, #0

    2f0c:	81110002 	tsthi	r1, r2
#endif
    2f10:	00000002 	andeq	r0, r0, r2

    2f14:	91a0f00e 	movls	pc, lr
	@ Perform all needed substractions to keep only the reminder.
	@ Do comparisons in batch of 4 first.
    2f18:	e16f2f11 	clz	r2, r1
    2f1c:	e16f3f10 	clz	r3, r0
    2f20:	e0422003 	sub	r2, r2, r3
    2f24:	e1a01211 	lsl	r1, r1, r2
	movlo	\divisor, \divisor, lsl #1
	addlo	\order, \order, #1
	blo	1b

#endif

    2f28:	e2522003 	subs	r2, r2, #3
    2f2c:	ba00000e 	blt	2f6c <__umodsi3+0x70>
    2f30:	e1500001 	cmp	r0, r1
    2f34:	20400001 	subcs	r0, r0, r1
    2f38:	e15000a1 	cmp	r0, r1, lsr #1
    2f3c:	204000a1 	subcs	r0, r0, r1, lsr #1
    2f40:	e1500121 	cmp	r0, r1, lsr #2
    2f44:	20400121 	subcs	r0, r0, r1, lsr #2
    2f48:	e15001a1 	cmp	r0, r1, lsr #3
    2f4c:	204001a1 	subcs	r0, r0, r1, lsr #3
    2f50:	e3500001 	cmp	r0, #1
    2f54:	e1a01221 	lsr	r1, r1, #4
    2f58:	a2522004 	subsge	r2, r2, #4
    2f5c:	aafffff3 	bge	2f30 <__umodsi3+0x34>
    2f60:	e3120003 	tst	r2, #3
    2f64:	13300000 	teqne	r0, #0
    2f68:	0a00000a 	beq	2f98 <__umodsi3+0x9c>
    2f6c:	e3720002 	cmn	r2, #2
    2f70:	ba000006 	blt	2f90 <__umodsi3+0x94>
    2f74:	0a000002 	beq	2f84 <__umodsi3+0x88>
    2f78:	e1500001 	cmp	r0, r1
    2f7c:	20400001 	subcs	r0, r0, r1
    2f80:	e1a010a1 	lsr	r1, r1, #1
    2f84:	e1500001 	cmp	r0, r1
    2f88:	20400001 	subcs	r0, r0, r1
    2f8c:	e1a010a1 	lsr	r1, r1, #1
    2f90:	e1500001 	cmp	r0, r1
    2f94:	20400001 	subcs	r0, r0, r1
	@ Perform all needed substractions to keep only the reminder.
	@ Do comparisons in batch of 4 first.
	subs	\order, \order, #3		@ yes, 3 is intended here
	blt	2f
    2f98:	e1a0f00e 	mov	pc, lr

00002f9c <__aeabi_idiv>:
	cmp	\dividend, \divisor,  lsr #1
	subhs	\dividend, \dividend, \divisor, lsr #1
	cmp	\dividend, \divisor,  lsr #2
	subhs	\dividend, \dividend, \divisor, lsr #2
	cmp	\dividend, \divisor,  lsr #3
	subhs	\dividend, \dividend, \divisor, lsr #3
    2f9c:	e3510000 	cmp	r1, #0
	cmp	\dividend, #1
    2fa0:	e020c001 	eor	ip, r0, r1
	mov	\divisor, \divisor, lsr #4
    2fa4:	0a000069 	beq	3150 <Ldiv0>
	subges	\order, \order, #4
    2fa8:	42611000 	rsbmi	r1, r1, #0
	bge	1b
    2fac:	e2512001 	subs	r2, r1, #1

    2fb0:	0a00001f 	beq	3034 <__aeabi_idiv+0x98>
	tst	\order, #3
    2fb4:	e1b03000 	movs	r3, r0
	teqne	\dividend, #0
    2fb8:	42603000 	rsbmi	r3, r0, #0
	beq	5f
    2fbc:	e1530001 	cmp	r3, r1

    2fc0:	9a00001e 	bls	3040 <__aeabi_idiv+0xa4>
	@ Either 1, 2 or 3 comparison/substractions are left.
    2fc4:	e1110002 	tst	r1, r2
2:	cmn	\order, #2
    2fc8:	0a000020 	beq	3050 <__aeabi_idiv+0xb4>
	blt	4f
	beq	3f
    2fcc:	e16f2f11 	clz	r2, r1
    2fd0:	e16f0f13 	clz	r0, r3
    2fd4:	e0420000 	sub	r0, r2, r0
    2fd8:	e3a02001 	mov	r2, #1
    2fdc:	e1a01011 	lsl	r1, r1, r0
    2fe0:	e1a02012 	lsl	r2, r2, r0
    2fe4:	e3a00000 	mov	r0, #0
	blo	1b

	mov	\result, #0

#endif

    2fe8:	e1530001 	cmp	r3, r1
    2fec:	20433001 	subcs	r3, r3, r1
    2ff0:	21800002 	orrcs	r0, r0, r2
    2ff4:	e15300a1 	cmp	r3, r1, lsr #1
    2ff8:	204330a1 	subcs	r3, r3, r1, lsr #1
    2ffc:	218000a2 	orrcs	r0, r0, r2, lsr #1
    3000:	e1530121 	cmp	r3, r1, lsr #2
    3004:	20433121 	subcs	r3, r3, r1, lsr #2
    3008:	21800122 	orrcs	r0, r0, r2, lsr #2
    300c:	e15301a1 	cmp	r3, r1, lsr #3
    3010:	204331a1 	subcs	r3, r3, r1, lsr #3
    3014:	218001a2 	orrcs	r0, r0, r2, lsr #3
    3018:	e3530000 	cmp	r3, #0
    301c:	11b02222 	lsrsne	r2, r2, #4
    3020:	11a01221 	lsrne	r1, r1, #4
    3024:	1affffef 	bne	2fe8 <__aeabi_idiv+0x4c>
	@ Either 1, 2 or 3 comparison/substractions are left.
2:	cmn	\order, #2
	blt	4f
	beq	3f
	cmp	\dividend, \divisor
	subhs	\dividend, \dividend, \divisor
    3028:	e35c0000 	cmp	ip, #0
	mov	\divisor,  \divisor,  lsr #1
    302c:	42600000 	rsbmi	r0, r0, #0
3:	cmp	\dividend, \divisor
    3030:	e1a0f00e 	mov	pc, lr
	subhs	\dividend, \dividend, \divisor
	mov	\divisor,  \divisor,  lsr #1
    3034:	e13c0000 	teq	ip, r0
4:	cmp	\dividend, \divisor
    3038:	42600000 	rsbmi	r0, r0, #0
	subhs	\dividend, \dividend, \divisor
    303c:	e1a0f00e 	mov	pc, lr
5:
.endm
    3040:	33a00000 	movcc	r0, #0

    3044:	01a00fcc 	asreq	r0, ip, #31

    3048:	03800001 	orreq	r0, r0, #1
ENTRY(__udivsi3)
    304c:	e1a0f00e 	mov	pc, lr
ENTRY(__aeabi_uidiv)
UNWIND(.fnstart)
    3050:	e16f2f11 	clz	r2, r1
    3054:	e262201f 	rsb	r2, r2, #31

	subs	r2, r1, #1
    3058:	e35c0000 	cmp	ip, #0
	moveq	pc, lr
    305c:	e1a00233 	lsr	r0, r3, r2
	bcc	Ldiv0
    3060:	42600000 	rsbmi	r0, r0, #0
	cmp	r0, r1
    3064:	e1a0f00e 	mov	pc, lr

00003068 <__modsi3>:

	ARM_DIV_BODY r0, r1, r2, r3

	mov	r0, r2
	mov	pc, lr

    3068:	e3510000 	cmp	r1, #0
11:	moveq	r0, #1
    306c:	0a000037 	beq	3150 <Ldiv0>
	movne	r0, #0
    3070:	42611000 	rsbmi	r1, r1, #0
	mov	pc, lr
    3074:	e1b0c000 	movs	ip, r0

    3078:	42600000 	rsbmi	r0, r0, #0
12:	ARM_DIV2_ORDER r1, r2
    307c:	e2512001 	subs	r2, r1, #1

    3080:	11500001 	cmpne	r0, r1
	mov	r0, r0, lsr r2
    3084:	03a00000 	moveq	r0, #0
	mov	pc, lr
    3088:	81110002 	tsthi	r1, r2

    308c:	00000002 	andeq	r0, r0, r2
UNWIND(.fnend)
    3090:	9a00001f 	bls	3114 <__modsi3+0xac>
ENDPROC(__udivsi3)
ENDPROC(__aeabi_uidiv)
    3094:	e16f2f11 	clz	r2, r1
    3098:	e16f3f10 	clz	r3, r0
    309c:	e0422003 	sub	r2, r2, r3
    30a0:	e1a01211 	lsl	r1, r1, r2
	movlo	\divisor, \divisor, lsl #1
	addlo	\order, \order, #1
	blo	1b

#endif

    30a4:	e2522003 	subs	r2, r2, #3
    30a8:	ba00000e 	blt	30e8 <__modsi3+0x80>
    30ac:	e1500001 	cmp	r0, r1
    30b0:	20400001 	subcs	r0, r0, r1
    30b4:	e15000a1 	cmp	r0, r1, lsr #1
    30b8:	204000a1 	subcs	r0, r0, r1, lsr #1
    30bc:	e1500121 	cmp	r0, r1, lsr #2
    30c0:	20400121 	subcs	r0, r0, r1, lsr #2
    30c4:	e15001a1 	cmp	r0, r1, lsr #3
    30c8:	204001a1 	subcs	r0, r0, r1, lsr #3
    30cc:	e3500001 	cmp	r0, #1
    30d0:	e1a01221 	lsr	r1, r1, #4
    30d4:	a2522004 	subsge	r2, r2, #4
    30d8:	aafffff3 	bge	30ac <__modsi3+0x44>
    30dc:	e3120003 	tst	r2, #3
    30e0:	13300000 	teqne	r0, #0
    30e4:	0a00000a 	beq	3114 <__modsi3+0xac>
    30e8:	e3720002 	cmn	r2, #2
    30ec:	ba000006 	blt	310c <__modsi3+0xa4>
    30f0:	0a000002 	beq	3100 <__modsi3+0x98>
    30f4:	e1500001 	cmp	r0, r1
    30f8:	20400001 	subcs	r0, r0, r1
    30fc:	e1a010a1 	lsr	r1, r1, #1
    3100:	e1500001 	cmp	r0, r1
    3104:	20400001 	subcs	r0, r0, r1
    3108:	e1a010a1 	lsr	r1, r1, #1
    310c:	e1500001 	cmp	r0, r1
    3110:	20400001 	subcs	r0, r0, r1

UNWIND(.fnend)
ENDPROC(__udivsi3)
ENDPROC(__aeabi_uidiv)

ENTRY(__umodsi3)
    3114:	e35c0000 	cmp	ip, #0
UNWIND(.fnstart)
    3118:	42600000 	rsbmi	r0, r0, #0

    311c:	e1a0f00e 	mov	pc, lr

00003120 <__aeabi_uidivmod>:
	andeq	r0, r0, r2
	movls	pc, lr

	ARM_MOD_BODY r0, r1, r2, r3

	mov	pc, lr
    3120:	e92d5003 	push	{r0, r1, ip, lr}

    3124:	ebffff4d 	bl	2e60 <__aeabi_uidiv>
UNWIND(.fnend)
    3128:	e8bd5006 	pop	{r1, r2, ip, lr}
ENDPROC(__umodsi3)
    312c:	e0030290 	mul	r3, r0, r2

    3130:	e0411003 	sub	r1, r1, r3
ENTRY(__divsi3)
    3134:	e1a0f00e 	mov	pc, lr

00003138 <__aeabi_idivmod>:

	cmp	r1, #0
	eor	ip, r0, r1			@ save the sign of the result.
	beq	Ldiv0
	rsbmi	r1, r1, #0			@ loops below use unsigned.
	subs	r2, r1, #1			@ division by 1 or -1 ?
    3138:	e92d5003 	push	{r0, r1, ip, lr}
	beq	10f
    313c:	ebffff96 	bl	2f9c <__aeabi_idiv>
	movs	r3, r0
    3140:	e8bd5006 	pop	{r1, r2, ip, lr}
	rsbmi	r3, r0, #0			@ positive dividend value
    3144:	e0030290 	mul	r3, r0, r2
	cmp	r3, r1
    3148:	e0411003 	sub	r1, r1, r3
	bls	11f
    314c:	e1a0f00e 	mov	pc, lr

00003150 <Ldiv0>:
	cmp	ip, #0
	rsbmi	r0, r0, #0
	mov	pc, lr

10:	teq	ip, r0				@ same sign ?
	rsbmi	r0, r0, #0
    3150:	e52de008 	str	lr, [sp, #-8]!
	mov	pc, lr
    3154:	ebfff5c2 	bl	864 <__div0>

    3158:	e3a00000 	mov	r0, #0
11:	movlo	r0, #0
    315c:	e49df008 	ldr	pc, [sp], #8

00003160 <__aeabi_llsl>:
#endif

ENTRY(__ashldi3)
ENTRY(__aeabi_llsl)

	subs	r3, r2, #32
    3160:	e2523020 	subs	r3, r2, #32
	rsb	ip, r2, #32
    3164:	e262c020 	rsb	ip, r2, #32
	movmi	ah, ah, lsl r2
    3168:	41a01211 	lslmi	r1, r1, r2
	movpl	ah, al, lsl r3
    316c:	51a01310 	lslpl	r1, r0, r3
 ARM(	orrmi	ah, ah, al, lsr ip	)
    3170:	41811c30 	orrmi	r1, r1, r0, lsr ip
 THUMB(	lsrmi	r3, al, ip		)
 THUMB(	orrmi	ah, ah, r3		)
	mov	al, al, lsl r2
    3174:	e1a00210 	lsl	r0, r0, r2
	mov	pc, lr
    3178:	e1a0f00e 	mov	pc, lr
