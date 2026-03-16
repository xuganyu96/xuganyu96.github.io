	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 26, 0	sdk_version 26, 2
	.globl	_println_arr                    ; -- Begin function println_arr
	.p2align	2
_println_arr:                           ; @println_arr
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #80
	stp	x24, x23, [sp, #16]             ; 16-byte Folded Spill
	stp	x22, x21, [sp, #32]             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #48]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #64]             ; 16-byte Folded Spill
	add	x29, sp, #64
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset w21, -40
	.cfi_offset w22, -48
	.cfi_offset w23, -56
	.cfi_offset w24, -64
	mov	x19, x2
	mov	x20, x1
	str	x0, [sp]
Lloh0:
	adrp	x0, l_.str@PAGE
Lloh1:
	add	x0, x0, l_.str@PAGEOFF
	bl	_printf
	cbz	x19, LBB0_5
; %bb.1:
	mov	w22, #1                         ; =0x1
Lloh2:
	adrp	x21, l_.str.1@PAGE
Lloh3:
	add	x21, x21, l_.str.1@PAGEOFF
	mov	x23, x19
	b	LBB0_3
LBB0_2:                                 ;   in Loop: Header=BB0_3 Depth=1
	add	x22, x22, #1
	subs	x23, x23, #1
	b.eq	LBB0_5
LBB0_3:                                 ; =>This Inner Loop Header: Depth=1
	ldrb	w8, [x20], #1
	str	x8, [sp]
	mov	x0, x21
	bl	_printf
	cmp	x22, x19
	b.hs	LBB0_2
; %bb.4:                                ;   in Loop: Header=BB0_3 Depth=1
	mov	w0, #58                         ; =0x3a
	bl	_putchar
	b	LBB0_2
LBB0_5:
Lloh4:
	adrp	x0, l_str@PAGE
Lloh5:
	add	x0, x0, l_str@PAGEOFF
	ldp	x29, x30, [sp, #64]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #48]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #32]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #80
	b	_puts
	.loh AdrpAdd	Lloh0, Lloh1
	.loh AdrpAdd	Lloh2, Lloh3
	.loh AdrpAdd	Lloh4, Lloh5
	.cfi_endproc
                                        ; -- End function
	.globl	_ct_select                      ; -- Begin function ct_select
	.p2align	2
_ct_select:                             ; @ct_select
	.cfi_startproc
; %bb.0:
	cbz	x3, LBB1_5
; %bb.1:
	neg	w8, w4
	sub	w9, w4, #1
	cmp	x3, #8
	b.hs	LBB1_6
; %bb.2:
	mov	x10, #0                         ; =0x0
LBB1_3:
	sub	x11, x3, x10
	add	x12, x0, x10
	add	x13, x2, x10
	add	x10, x1, x10
LBB1_4:                                 ; =>This Inner Loop Header: Depth=1
	ldrb	w14, [x10], #1
	ldrb	w15, [x13], #1
	and	w14, w14, w8
	and	w15, w15, w9
	orr	w14, w15, w14
	strb	w14, [x12], #1
	subs	x11, x11, #1
	b.ne	LBB1_4
LBB1_5:
	ret
LBB1_6:
	mov	x10, #0                         ; =0x0
	sub	x11, x0, x1
	cmp	x11, #64
	b.lo	LBB1_3
; %bb.7:
	sub	x11, x0, x2
	cmp	x11, #64
	b.lo	LBB1_3
; %bb.8:
	cmp	x3, #64
	b.hs	LBB1_10
; %bb.9:
	mov	x10, #0                         ; =0x0
	b	LBB1_14
LBB1_10:
	and	x10, x3, #0xffffffffffffffc0
	dup.16b	v0, w8
	dup.16b	v1, w9
	add	x11, x1, #32
	add	x12, x0, #32
	add	x13, x2, #32
	mov	x14, x10
LBB1_11:                                ; =>This Inner Loop Header: Depth=1
	ldp	q2, q3, [x11, #-32]
	ldp	q4, q5, [x11], #64
	and.16b	v2, v2, v0
	and.16b	v3, v3, v0
	and.16b	v4, v4, v0
	and.16b	v5, v5, v0
	ldp	q6, q7, [x13, #-32]
	ldp	q16, q17, [x13], #64
	and.16b	v6, v6, v1
	and.16b	v7, v7, v1
	and.16b	v16, v16, v1
	and.16b	v17, v17, v1
	orr.16b	v2, v6, v2
	orr.16b	v3, v7, v3
	orr.16b	v4, v16, v4
	orr.16b	v5, v17, v5
	stp	q2, q3, [x12, #-32]
	stp	q4, q5, [x12], #64
	subs	x14, x14, #64
	b.ne	LBB1_11
; %bb.12:
	cmp	x10, x3
	b.eq	LBB1_5
; %bb.13:
	tst	x3, #0x38
	b.eq	LBB1_3
LBB1_14:
	mov	x14, x10
	and	x10, x3, #0xfffffffffffffff8
	dup.8b	v0, w8
	dup.8b	v1, w9
	add	x11, x1, x14
	add	x12, x2, x14
	add	x13, x0, x14
	sub	x14, x14, x10
LBB1_15:                                ; =>This Inner Loop Header: Depth=1
	ldr	d2, [x11], #8
	ldr	d3, [x12], #8
	and.8b	v2, v2, v0
	and.8b	v3, v3, v1
	orr.8b	v2, v3, v2
	str	d2, [x13], #8
	adds	x14, x14, #8
	b.ne	LBB1_15
; %bb.16:
	cmp	x10, x3
	b.ne	LBB1_3
	b	LBB1_5
	.cfi_endproc
                                        ; -- End function
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #80
	stp	x24, x23, [sp, #16]             ; 16-byte Folded Spill
	stp	x22, x21, [sp, #32]             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #48]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #64]             ; 16-byte Folded Spill
	add	x29, sp, #64
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset w21, -40
	.cfi_offset w22, -48
	.cfi_offset w23, -56
	.cfi_offset w24, -64
Lloh6:
	adrp	x8, l_.str.4@PAGE
Lloh7:
	add	x8, x8, l_.str.4@PAGEOFF
	str	x8, [sp]
Lloh8:
	adrp	x20, l_.str@PAGE
Lloh9:
	add	x20, x20, l_.str@PAGEOFF
	mov	x0, x20
	bl	_printf
	mov	w22, #1                         ; =0x1
	str	x22, [sp]
Lloh10:
	adrp	x19, l_.str.1@PAGE
Lloh11:
	add	x19, x19, l_.str.1@PAGEOFF
	mov	x0, x19
	bl	_printf
	mov	w0, #58                         ; =0x3a
	bl	_putchar
	str	x22, [sp]
	mov	x0, x19
	bl	_printf
	mov	w0, #58                         ; =0x3a
	bl	_putchar
	str	x22, [sp]
	mov	x0, x19
	bl	_printf
	mov	w0, #58                         ; =0x3a
	bl	_putchar
	str	x22, [sp]
	mov	x0, x19
	bl	_printf
	mov	w0, #58                         ; =0x3a
	bl	_putchar
	str	x22, [sp]
	mov	x0, x19
	bl	_printf
Lloh12:
	adrp	x21, l_str@PAGE
Lloh13:
	add	x21, x21, l_str@PAGEOFF
	mov	x0, x21
	bl	_puts
Lloh14:
	adrp	x8, l_.str.5@PAGE
Lloh15:
	add	x8, x8, l_.str.5@PAGEOFF
	str	x8, [sp]
	mov	x0, x20
	bl	_printf
	mov	w23, #2                         ; =0x2
	str	x23, [sp]
	mov	x0, x19
	bl	_printf
	mov	w0, #58                         ; =0x3a
	bl	_putchar
	str	x23, [sp]
	mov	x0, x19
	bl	_printf
	mov	w0, #58                         ; =0x3a
	bl	_putchar
	str	x23, [sp]
	mov	x0, x19
	bl	_printf
	mov	w0, #58                         ; =0x3a
	bl	_putchar
	str	x23, [sp]
	mov	x0, x19
	bl	_printf
	mov	w0, #58                         ; =0x3a
	bl	_putchar
	str	x23, [sp]
	mov	x0, x19
	bl	_printf
	mov	x0, x21
	bl	_puts
Lloh16:
	adrp	x8, l_.str.6@PAGE
Lloh17:
	add	x8, x8, l_.str.6@PAGEOFF
	str	x8, [sp]
	mov	x0, x20
	bl	_printf
	str	x22, [sp]
	mov	x0, x19
	bl	_printf
	mov	w0, #58                         ; =0x3a
	bl	_putchar
	str	x22, [sp]
	mov	x0, x19
	bl	_printf
	mov	w0, #58                         ; =0x3a
	bl	_putchar
	str	x22, [sp]
	mov	x0, x19
	bl	_printf
	mov	w0, #58                         ; =0x3a
	bl	_putchar
	str	x22, [sp]
	mov	x0, x19
	bl	_printf
	mov	w0, #58                         ; =0x3a
	bl	_putchar
	str	x22, [sp]
	mov	x0, x19
	bl	_printf
	mov	x0, x21
	bl	_puts
	mov	w0, #0                          ; =0x0
	ldp	x29, x30, [sp, #64]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #48]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #32]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #80
	ret
	.loh AdrpAdd	Lloh16, Lloh17
	.loh AdrpAdd	Lloh14, Lloh15
	.loh AdrpAdd	Lloh12, Lloh13
	.loh AdrpAdd	Lloh10, Lloh11
	.loh AdrpAdd	Lloh8, Lloh9
	.loh AdrpAdd	Lloh6, Lloh7
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"%s = ["

l_.str.1:                               ; @.str.1
	.asciz	"%02hhx"

l_.str.4:                               ; @.str.4
	.asciz	"lhs"

l_.str.5:                               ; @.str.5
	.asciz	"rhs"

l_.str.6:                               ; @.str.6
	.asciz	"dst"

l_str:                                  ; @str
	.asciz	"]"

.subsections_via_symbols
