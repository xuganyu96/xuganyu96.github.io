	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 26, 0	sdk_version 26, 2
	.globl	_println_arr                    ; -- Begin function println_arr
	.p2align	2
_println_arr:                           ; @println_arr
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #64
	stp	x29, x30, [sp, #48]             ; 16-byte Folded Spill
	add	x29, sp, #48
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	stur	x0, [x29, #-8]
	stur	x1, [x29, #-16]
	str	x2, [sp, #24]
	ldur	x8, [x29, #-8]
	mov	x9, sp
	str	x8, [x9]
	adrp	x0, l_.str@PAGE
	add	x0, x0, l_.str@PAGEOFF
	bl	_printf
	str	wzr, [sp, #20]
	b	LBB0_1
LBB0_1:                                 ; =>This Inner Loop Header: Depth=1
	ldrsw	x8, [sp, #20]
	ldr	x9, [sp, #24]
	subs	x8, x8, x9
	b.hs	LBB0_6
	b	LBB0_2
LBB0_2:                                 ;   in Loop: Header=BB0_1 Depth=1
	ldur	x8, [x29, #-16]
	ldrsw	x9, [sp, #20]
	ldrb	w10, [x8, x9]
	mov	x9, sp
                                        ; implicit-def: $x8
	mov	x8, x10
	str	x8, [x9]
	adrp	x0, l_.str.1@PAGE
	add	x0, x0, l_.str.1@PAGEOFF
	bl	_printf
	ldr	w8, [sp, #20]
	add	w9, w8, #1
                                        ; implicit-def: $x8
	mov	x8, x9
	sxtw	x8, w8
	ldr	x9, [sp, #24]
	subs	x8, x8, x9
	b.hs	LBB0_4
	b	LBB0_3
LBB0_3:                                 ;   in Loop: Header=BB0_1 Depth=1
	adrp	x0, l_.str.2@PAGE
	add	x0, x0, l_.str.2@PAGEOFF
	bl	_printf
	b	LBB0_4
LBB0_4:                                 ;   in Loop: Header=BB0_1 Depth=1
	b	LBB0_5
LBB0_5:                                 ;   in Loop: Header=BB0_1 Depth=1
	ldr	w8, [sp, #20]
	add	w8, w8, #1
	str	w8, [sp, #20]
	b	LBB0_1
LBB0_6:
	adrp	x0, l_.str.3@PAGE
	add	x0, x0, l_.str.3@PAGEOFF
	bl	_printf
	ldp	x29, x30, [sp, #48]             ; 16-byte Folded Reload
	add	sp, sp, #64
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_ct_select                      ; -- Begin function ct_select
	.p2align	2
_ct_select:                             ; @ct_select
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #48
	.cfi_def_cfa_offset 48
	str	x0, [sp, #40]
	str	x1, [sp, #32]
	str	x2, [sp, #24]
	str	x3, [sp, #16]
	strb	w4, [sp, #15]
	ldrb	w9, [sp, #15]
	mov	w8, #0                          ; =0x0
	subs	w8, w8, w9
	strb	w8, [sp, #14]
	str	xzr, [sp]
	b	LBB1_1
LBB1_1:                                 ; =>This Inner Loop Header: Depth=1
	ldr	x8, [sp]
	ldr	x9, [sp, #16]
	subs	x8, x8, x9
	b.hs	LBB1_4
	b	LBB1_2
LBB1_2:                                 ;   in Loop: Header=BB1_1 Depth=1
	ldr	x8, [sp, #32]
	ldr	x9, [sp]
	ldrb	w8, [x8, x9]
	ldrb	w9, [sp, #14]
	and	w8, w8, w9
	ldr	x9, [sp, #24]
	ldr	x10, [sp]
	ldrb	w9, [x9, x10]
	ldrb	w10, [sp, #14]
	bic	w9, w9, w10
	orr	w8, w8, w9
	ldr	x9, [sp, #40]
	ldr	x10, [sp]
	strb	w8, [x9, x10]
	b	LBB1_3
LBB1_3:                                 ;   in Loop: Header=BB1_1 Depth=1
	ldr	x8, [sp]
	add	x8, x8, #1
	str	x8, [sp]
	b	LBB1_1
LBB1_4:
	add	sp, sp, #48
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #80
	stp	x29, x30, [sp, #64]             ; 16-byte Folded Spill
	add	x29, sp, #64
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	adrp	x8, l___const.main.lhs@PAGE
	add	x8, x8, l___const.main.lhs@PAGEOFF
	ldr	w9, [x8]
	sub	x1, x29, #8
	str	x1, [sp, #8]                    ; 8-byte Folded Spill
	stur	w9, [x29, #-8]
	ldrb	w8, [x8, #4]
	sturb	w8, [x29, #-4]
	adrp	x8, l___const.main.rhs@PAGE
	add	x8, x8, l___const.main.rhs@PAGEOFF
	ldr	w9, [x8]
	sub	x2, x29, #16
	str	x2, [sp, #16]                   ; 8-byte Folded Spill
	stur	w9, [x29, #-16]
	ldrb	w8, [x8, #4]
	sturb	w8, [x29, #-12]
	sub	x0, x29, #24
	str	x0, [sp, #24]                   ; 8-byte Folded Spill
	stur	wzr, [x29, #-24]
	sturb	wzr, [x29, #-20]
	mov	x3, #5                          ; =0x5
	str	x3, [sp, #32]                   ; 8-byte Folded Spill
	mov	w4, #1                          ; =0x1
	bl	_ct_select
	ldr	x1, [sp, #8]                    ; 8-byte Folded Reload
	ldr	x2, [sp, #32]                   ; 8-byte Folded Reload
	adrp	x0, l_.str.4@PAGE
	add	x0, x0, l_.str.4@PAGEOFF
	bl	_println_arr
	ldr	x1, [sp, #16]                   ; 8-byte Folded Reload
	ldr	x2, [sp, #32]                   ; 8-byte Folded Reload
	adrp	x0, l_.str.5@PAGE
	add	x0, x0, l_.str.5@PAGEOFF
	bl	_println_arr
	ldr	x1, [sp, #24]                   ; 8-byte Folded Reload
	ldr	x2, [sp, #32]                   ; 8-byte Folded Reload
	adrp	x0, l_.str.6@PAGE
	add	x0, x0, l_.str.6@PAGEOFF
	bl	_println_arr
	mov	w0, #0                          ; =0x0
	ldp	x29, x30, [sp, #64]             ; 16-byte Folded Reload
	add	sp, sp, #80
	ret
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"%s = ["

l_.str.1:                               ; @.str.1
	.asciz	"%02hhx"

l_.str.2:                               ; @.str.2
	.asciz	":"

l_.str.3:                               ; @.str.3
	.asciz	"]\n"

	.section	__TEXT,__const
l___const.main.lhs:                     ; @__const.main.lhs
	.space	5,1

l___const.main.rhs:                     ; @__const.main.rhs
	.space	5,2

	.section	__TEXT,__cstring,cstring_literals
l_.str.4:                               ; @.str.4
	.asciz	"lhs"

l_.str.5:                               ; @.str.5
	.asciz	"rhs"

l_.str.6:                               ; @.str.6
	.asciz	"dst"

.subsections_via_symbols
