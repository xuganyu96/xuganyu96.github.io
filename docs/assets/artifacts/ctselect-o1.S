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
	cbz	x3, LBB1_3
; %bb.1:
	neg	w8, w4
	sub	w9, w4, #1
LBB1_2:                                 ; =>This Inner Loop Header: Depth=1
	ldrb	w10, [x1], #1
	ldrb	w11, [x2], #1
	and	w10, w10, w8
	and	w11, w11, w9
	orr	w10, w11, w10
	strb	w10, [x0], #1
	subs	x3, x3, #1
	b.ne	LBB1_2
LBB1_3:
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #64
	stp	x22, x21, [sp, #16]             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #32]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #48]             ; 16-byte Folded Spill
	add	x29, sp, #48
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset w21, -40
	.cfi_offset w22, -48
	mov	w8, #16843009                   ; =0x1010101
	str	w8, [sp, #8]
	strb	w8, [sp, #12]
Lloh6:
	adrp	x8, l_.str.4@PAGE
Lloh7:
	add	x8, x8, l_.str.4@PAGEOFF
	str	x8, [sp]
Lloh8:
	adrp	x0, l_.str@PAGE
Lloh9:
	add	x0, x0, l_.str@PAGEOFF
	bl	_printf
	mov	x20, #0                         ; =0x0
Lloh10:
	adrp	x21, l___const.main.lhs@PAGE
Lloh11:
	add	x21, x21, l___const.main.lhs@PAGEOFF
Lloh12:
	adrp	x19, l_.str.1@PAGE
Lloh13:
	add	x19, x19, l_.str.1@PAGEOFF
	b	LBB2_2
LBB2_1:                                 ;   in Loop: Header=BB2_2 Depth=1
	add	x20, x20, #1
	cmp	x20, #5
	b.eq	LBB2_4
LBB2_2:                                 ; =>This Inner Loop Header: Depth=1
	ldrb	w8, [x21, x20]
	str	x8, [sp]
	mov	x0, x19
	bl	_printf
	cmp	x20, #3
	b.hi	LBB2_1
; %bb.3:                                ;   in Loop: Header=BB2_2 Depth=1
	mov	w0, #58                         ; =0x3a
	bl	_putchar
	b	LBB2_1
LBB2_4:
Lloh14:
	adrp	x0, l_str@PAGE
Lloh15:
	add	x0, x0, l_str@PAGEOFF
	bl	_puts
Lloh16:
	adrp	x8, l_.str.5@PAGE
Lloh17:
	add	x8, x8, l_.str.5@PAGEOFF
	str	x8, [sp]
Lloh18:
	adrp	x0, l_.str@PAGE
Lloh19:
	add	x0, x0, l_.str@PAGEOFF
	bl	_printf
	mov	x20, #0                         ; =0x0
Lloh20:
	adrp	x21, l___const.main.rhs@PAGE
Lloh21:
	add	x21, x21, l___const.main.rhs@PAGEOFF
Lloh22:
	adrp	x19, l_.str.1@PAGE
Lloh23:
	add	x19, x19, l_.str.1@PAGEOFF
	b	LBB2_6
LBB2_5:                                 ;   in Loop: Header=BB2_6 Depth=1
	add	x20, x20, #1
	cmp	x20, #5
	b.eq	LBB2_8
LBB2_6:                                 ; =>This Inner Loop Header: Depth=1
	ldrb	w8, [x21, x20]
	str	x8, [sp]
	mov	x0, x19
	bl	_printf
	cmp	x20, #3
	b.hi	LBB2_5
; %bb.7:                                ;   in Loop: Header=BB2_6 Depth=1
	mov	w0, #58                         ; =0x3a
	bl	_putchar
	b	LBB2_5
LBB2_8:
Lloh24:
	adrp	x0, l_str@PAGE
Lloh25:
	add	x0, x0, l_str@PAGEOFF
	bl	_puts
Lloh26:
	adrp	x8, l_.str.6@PAGE
Lloh27:
	add	x8, x8, l_.str.6@PAGEOFF
	str	x8, [sp]
Lloh28:
	adrp	x0, l_.str@PAGE
Lloh29:
	add	x0, x0, l_.str@PAGEOFF
	bl	_printf
	mov	x20, #0                         ; =0x0
	add	x21, sp, #8
Lloh30:
	adrp	x19, l_.str.1@PAGE
Lloh31:
	add	x19, x19, l_.str.1@PAGEOFF
	b	LBB2_10
LBB2_9:                                 ;   in Loop: Header=BB2_10 Depth=1
	add	x20, x20, #1
	cmp	x20, #5
	b.eq	LBB2_12
LBB2_10:                                ; =>This Inner Loop Header: Depth=1
	ldrb	w8, [x21, x20]
	str	x8, [sp]
	mov	x0, x19
	bl	_printf
	cmp	x20, #3
	b.hi	LBB2_9
; %bb.11:                               ;   in Loop: Header=BB2_10 Depth=1
	mov	w0, #58                         ; =0x3a
	bl	_putchar
	b	LBB2_9
LBB2_12:
Lloh32:
	adrp	x0, l_str@PAGE
Lloh33:
	add	x0, x0, l_str@PAGEOFF
	bl	_puts
	mov	w0, #0                          ; =0x0
	ldp	x29, x30, [sp, #48]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #32]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #64
	ret
	.loh AdrpAdd	Lloh12, Lloh13
	.loh AdrpAdd	Lloh10, Lloh11
	.loh AdrpAdd	Lloh8, Lloh9
	.loh AdrpAdd	Lloh6, Lloh7
	.loh AdrpAdd	Lloh22, Lloh23
	.loh AdrpAdd	Lloh20, Lloh21
	.loh AdrpAdd	Lloh18, Lloh19
	.loh AdrpAdd	Lloh16, Lloh17
	.loh AdrpAdd	Lloh14, Lloh15
	.loh AdrpAdd	Lloh30, Lloh31
	.loh AdrpAdd	Lloh28, Lloh29
	.loh AdrpAdd	Lloh26, Lloh27
	.loh AdrpAdd	Lloh24, Lloh25
	.loh AdrpAdd	Lloh32, Lloh33
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"%s = ["

l_.str.1:                               ; @.str.1
	.asciz	"%02hhx"

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

l_str:                                  ; @str
	.asciz	"]"

.subsections_via_symbols
