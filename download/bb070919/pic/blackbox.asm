	list p=16f648a
	#include "p16f648a.inc"
	__config	_BOREN_OFF & _CP_OFF & _DATA_CP_OFF & _PWRTE_ON & _WDT_OFF & _LVP_OFF & _MCLRE_OFF & _INTOSC_OSC_CLKOUT

LCD_RS	equ	2
LCD_E	equ	3
SCAN0	equ	0
SCAN1	equ	1
SCAN2	equ	4

KEYNULL	equ	7
KEYCMD	equ	6
KEYCUR	equ	5
KEYNUM	equ	4
KEYENT	equ	0
KEYCAN	equ	1
KEYA	equ	2
KEYS	equ	3
KEYU	equ	0
KEYL	equ	1
KEYR	equ	2
KEYD	equ	3


work0	equ	0x3e
work1	equ	0x3f

disp_ah	equ	0x40
disp_al	equ	0x41
disp_bh	equ	0x42
disp_bl	equ	0x43
disp_ch	equ	0x44
disp_cl	equ	0x45
disp_dh	equ	0x46
disp_dl	equ	0x47

disp_ai	equ	0x48
disp_bi	equ	0x49
disp_ci	equ	0x4a
disp_di	equ	0x4b

disp_c	equ	0x4c
work2	equ	0x4f

input_ah	equ	0x50
input_al	equ	0x51
input_bh	equ	0x52
input_bl	equ	0x53
input_ch	equ	0x54
input_cl	equ	0x55
input_dh	equ	0x56
input_dl	equ	0x57

acch	equ	0x58
accl	equ	0x59
acctmph	equ	0x5a
acctmpl	equ	0x5b

menu0	equ	0x5c
menu1	equ	0x5d
menu2	equ	0x5e
menu3	equ	0x5f

type2count	equ	60h
type3count	equ	61h
type4count	equ	62h
type5count	equ	63h
type6count	equ	64h

type6a	equ	68h
type6b	equ	69h
type6c	equ	6ah
type6d	equ	6bh


	org	0
	goto	init

	org	5

typetable
	clrf	disp_ah
	clrf	disp_al
	clrf	disp_bh
	clrf	disp_bl
	clrf	disp_ch
	clrf	disp_cl
	clrf	disp_dh
	clrf	disp_dl
	clrf	disp_ai
	clrf	disp_bi
	clrf	disp_ci
	clrf	disp_di
	clrf	input_ah
	clrf	input_al
	clrf	input_bh
	clrf	input_bl
	clrf	input_ch
	clrf	input_cl
	clrf	input_dh
	clrf	input_dl
	addwf	PCL, 1
	
	nop
	goto	type1
	goto	type2
	goto	type3
	goto	type4
	goto	type5
	goto	type6


type5sub
	andlw	3
	movwf	work0
	addwf	work0, 0
	addwf	PCL, 1
	
	movf	disp_ai, 0
	return
	movf	disp_bi, 0
	return
	movf	disp_ci, 0
	return
	movf	disp_di, 0
	return


acc_add		; acc += W
	addwf	accl, 1
	btfsc	STATUS, C
	incf	acch, 1
	retlw	0

acc_sub		; acc -= W
	subwf	accl, 1
	btfss	STATUS, C
	decf	acch, 1
	retlw	0

acc_mul		; acc += work0 * work1
	movf	work0, 0
	movwf	acctmph
	clrf	acctmpl
acc_mul_loop
	movf	work1, 0
	btfsc	STATUS, Z
	retlw	0
	
	bcf	STATUS, C
	rrf	acctmph, 1
	rrf	acctmpl, 1
	
	bcf	STATUS, C
	rlf	work1, 1
	btfss	STATUS, C
	goto	acc_mul_loop
	
	movf	acctmph, 0
	addwf	acch, 1
	
	movf	acctmpl, 0
	addwf	accl, 1
	btfsc	STATUS, C
	incf	acch, 1
	goto	acc_mul_loop


wait1ms
	clrf	work0
wait1ms_0
	nop
	nop
	decfsz	work0, 1
	goto	wait1ms_0		;4uS
	retlw	0


wait50ms
	movlw	32h
	movwf	work1
wait50ms_0
	call	wait1ms
	decfsz	work1, 1
	goto	wait200ms_0
	retlw	0


wait200ms
	movlw	0c8h
	movwf	work1
wait200ms_0
	call	wait1ms
	decfsz	work1, 1
	goto	wait200ms_0
	retlw	0


write_vpattern
	movwf	work1
	swapf	work1, 0
	call	write_lcd8
	movf	work1, 0
	call	write_lcd8
	
	swapf	work1, 0
	call	write_lcd8
	movf	work1, 0
	call	write_lcd8
	
	swapf	work1, 0
	call	write_lcd8
	movf	work1, 0
	call	write_lcd8
	
	swapf	work1, 0
	call	write_lcd8
	movf	work1, 0
	call	write_lcd8
	
	swapf	work1, 0
	call	write_lcd8
	movf	work1, 0
	call	write_lcd8
	
	swapf	work1, 0
	call	write_lcd8
	movf	work1, 0
	call	write_lcd8
	
	swapf	work1, 0
	call	write_lcd8
	movf	work1, 0
	call	write_lcd8
	
	swapf	work1, 0
	call	write_lcd8
	movf	work1, 0
	call	write_lcd8
	
	retlw	0


write_hex
	movwf	work1
	andlw	0f0h
	addlw	60h
	btfss	STATUS, C
	goto	write_hex_hn
write_hex_ha
	movlw	60h
	call	write_lcd8
	
	movf	work1, 0
	andlw	0f0h
	addlw	70h
	call	write_lcd8
	goto	write_hex_l
write_hex_hn
	movlw	30h
	call	write_lcd8
	
	movf	work1, 0
	andlw	0f0h
	call	write_lcd8
	
write_hex_l
	swapf	work1, 0
	andlw	0f0h
	addlw	60h
	btfss	STATUS, C
	goto	write_hex_ln
write_hex_la
	movlw	60h
	call	write_lcd8
	
	swapf	work1, 0
	andlw	0f0h
	addlw	70h
	goto	write_lcd8
write_hex_ln
	movlw	30h
	call	write_lcd8
	
	swapf	work1, 0
	andlw	0f0h
	goto	write_lcd8


write_dec
	clrf	acctmph
write_dec_loop
	incf	acctmph, 1
	movwf	acctmpl
	addlw	0f6h
	btfsc	STATUS, C
	goto	write_dec_loop
	
	movf	acctmph, 0
	addlw	2fh
	call	write_lcd
	
	movf	acctmpl, 0
	addlw	30h
	goto	write_lcd


write_acc
	movlw	2bh
	btfss	acch, 7
	goto	write_acc_sign
	
	movlw	0ffh
	xorwf	acch, 1
	xorwf	accl, 1
	
	movlw	1
	call	acc_add
	
	movlw	2dh
write_acc_sign
	call	write_lcd
	movlw	2fh
	movwf	acctmph
write_acc_loop1
	incf	acctmph, 1
	movlw	64h
	call	acc_sub
	btfss	acch, 7
	goto	write_acc_loop1
	
	movf	acctmph, 0
	call	write_lcd
	
	movlw	64h
	call	acc_add
	movlw	2fh
	movwf	acctmph
write_acc_loop2
	incf	acctmph, 1
	movlw	0ah
	call	acc_sub
	btfss	acch, 7
	goto	write_acc_loop2
	
	movf	acctmph, 0
	call	write_lcd
	
	movf	accl, 0
	addlw	3ah
	goto	write_lcd


write_lcd
	movwf	work1
	swapf	work1, 0
	call	write_lcd8
	movf	work1, 0
write_lcd8
	movwf	PORTB
	bsf	STATUS, RP0
	movlw	0b0h			; PORTB: IOIIOOOO
	movwf	PORTB
	bcf	STATUS, RP0
	
	bsf	PORTA, LCD_E
	nop			; 1us
	bcf	PORTA, LCD_E
	
	movlw	0ah		; 50us
	movwf	work0
write_lcd8_wait
	nop
	nop
	decfsz	work0, 1
	goto	write_lcd8_wait
	
	retlw	0


keyscan
	movlw	0c4h			; PORTA: 11000100
	movwf	PORTA
	
	bsf	STATUS, RP0
	bcf	PORTA, SCAN0
	bsf	PORTA, SCAN1
	bsf	PORTA, SCAN2
	movlw	0bfh			; PORTB: IOIIIIII
	movwf	PORTB
	bcf	STATUS, RP0
	
	call	wait1ms
	btfss	PORTB, 0
	retlw	22h		;KEYL
	btfss	PORTB, 1
	retlw	28h		;KEYD
	btfss	PORTB, 2
	retlw	17h
	btfss	PORTB, 3
	retlw	44h		;KEYA
	btfss	PORTB, 4
	retlw	14h
	btfss	PORTB, 5
	retlw	11h
	
	bsf	STATUS, RP0
	bsf	PORTA, SCAN0
	bcf	PORTA, SCAN1
	bcf	STATUS, RP0
	
	call	wait1ms
	btfss	PORTB, 0
	retlw	41h		;KEYENT
	btfss	PORTB, 1
	retlw	42h		;KEYC
	btfss	PORTB, 2
	retlw	18h
	btfss	PORTB, 3
	retlw	10h
	btfss	PORTB, 4
	retlw	15h
	btfss	PORTB, 5
	retlw	12h
	
	bsf	STATUS, RP0
	bsf	PORTA, SCAN1
	bcf	PORTA, SCAN2
	bcf	STATUS, RP0
	
	call	wait1ms
	btfss	PORTB, 0
	retlw	21h		;KEYU
	btfss	PORTB, 1
	retlw	24h		;KEYR
	btfss	PORTB, 2
	retlw	19h
	btfss	PORTB, 3
	retlw	48h		;KEYS
	btfss	PORTB, 4
	retlw	16h
	btfss	PORTB, 5
	retlw	13h
	
	bsf	STATUS, RP0
	bcf	PORTA, SCAN0
	bcf	PORTA, SCAN1
	bcf	STATUS, RP0
	retlw	80h		; KEYNULL


waitkeyreleaseloop
	call	keyscan
	andlw	80h
	btfsc	STATUS, Z
waitkey
	clrf	work1
	incf	work1, 1
	btfss	work1, 4
	goto	waitkeyreleaseloop
waitkeyloop
	call	keyscan
	movwf	work0
	btfsc	work0, 7
	goto	waitkeyloop
	
	xorlw	41h
	btfss	STATUS, Z
	goto	waitkeyreturn
	
	clrf	work2
waitkeyenter
	call	wait50ms
	call	keyscan
	xorlw	41h
	btfss	STATUS, Z
	retlw	41h
	incf	work2, 1
	btfss	work2, 5
	goto	waitkeyenter
	retlw	80h
	
waitkeyreturn
	movf	work0, 0
	return


inputkey
	call	waitkey
	movwf	work0
	andlw	0fh
	btfsc	work0, KEYNUM
	return
	btfsc	work0, 7
	goto	inputkeymenu
	movf	work0, 0
	xorlw	42h
	btfsc	STATUS, Z
	retlw	20h		; <
	xorlw	60h
	btfsc	STATUS, Z
	retlw	20h		; <
	xorlw	3
	btfsc	STATUS, Z
	retlw	40h		; ^
	xorlw	5
	btfsc	STATUS, Z
	retlw	10h		; >
	goto	inputkey
inputkeymenu
	call	mode_menu
	iorlw	0
	btfsc	STATUS, Z
	retlw	80h
	goto	typetable


mode_result
	bcf	PORTA, LCD_RS
	movlw	0ch		; display-on cursor-off blink-off
	call	write_lcd
	movlw	1		; clear-all
	call	write_lcd
	call	wait200ms
	
	bsf	PORTA, LCD_RS
	movlw	28h
	call	write_lcd
	movlw	2dh
	call	write_lcd
	movf	disp_c, 0
	call	write_dec
	movlw	29h
	call	write_lcd
	
	movf	disp_ai, 0
	call	write_dec
	movlw	20h
	call	write_lcd
	movf	disp_bi, 0
	call	write_dec
	movlw	20h
	call	write_lcd
	movf	disp_ci, 0
	call	write_dec
	movlw	20h
	call	write_lcd
	movf	disp_di, 0
	call	write_dec
	movlw	20h
	call	write_lcd
	
	bcf	PORTA, LCD_RS
	movlw	0c0h		; DDRAM=40h
	call	write_lcd
	bsf	PORTA, LCD_RS
	
	movf	disp_ah, 0
	movwf	acch
	movf	disp_al, 0
	movwf	accl
	call	write_acc
	
	movf	disp_bh, 0
	movwf	acch
	movf	disp_bl, 0
	movwf	accl
	call	write_acc
	
	movf	disp_ch, 0
	movwf	acch
	movf	disp_cl, 0
	movwf	accl
	call	write_acc
	
	movf	disp_dh, 0
	movwf	acch
	movf	disp_dl, 0
	movwf	accl
	call	write_acc
	
mode_result_loop
	call	waitkey
	xorlw	28h
	btfsc	STATUS, Z
	goto	mode_input
	xorlw	0a8h
	btfss	STATUS, Z
	goto	mode_result_loop
	
	call	mode_menu
	iorlw	0
	btfsc	STATUS, Z
	goto	mode_result
	goto	typetable


mode_input
	bcf	PORTA, LCD_RS
	movlw	0fh		; display-on cursor-on blink-on
	call	write_lcd
	movlw	1		; clear-all
	call	write_lcd
	call	wait200ms
	
	bsf	PORTA, LCD_RS
	movlw	28h
	call	write_lcd
	movlw	2dh
	call	write_lcd
	movf	disp_c, 0
	addlw	0ffh
	btfss	STATUS, C
	goto	mode_result
	call	write_dec
	movlw	29h
	call	write_lcd
	movlw	49h
	call	write_lcd
	movlw	6eh
	call	write_lcd
	movlw	70h
	call	write_lcd
	movlw	75h
	call	write_lcd
	movlw	74h
	call	write_lcd
	
	bcf	PORTA, LCD_RS
	movlw	0c0h		; DDRAM=40h
	call	write_lcd
	bsf	PORTA, LCD_RS
	
	movf	input_ah, 0
	addlw	30h
	call	write_lcd
	movf	input_al, 0
	addlw	30h
	call	write_lcd
	movlw	20h
	call	write_lcd
	
	movf	input_bh, 0
	addlw	30h
	call	write_lcd
	movf	input_bl, 0
	addlw	30h
	call	write_lcd
	movlw	20h
	call	write_lcd
	
	movf	input_ch, 0
	addlw	30h
	call	write_lcd
	movf	input_cl, 0
	addlw	30h
	call	write_lcd
	movlw	20h
	call	write_lcd
	
	movf	input_dh, 0
	addlw	30h
	call	write_lcd
	movf	input_dl, 0
	addlw	30h
	call	write_lcd
	movlw	20h
	call	write_lcd
	
	movlw	4fh
	call	write_lcd
	movlw	6bh
	call	write_lcd
mode_input_ah
	bcf	PORTA, LCD_RS
	movlw	0c0h		; DDRAM=40h
	call	write_lcd
	bsf	PORTA, LCD_RS
	
	call	inputkey
	movwf	work0
	btfsc	work0, 7
	goto	mode_input
	btfsc	work0, 6
	goto	mode_result
	btfsc	work0, 5
	goto	mode_input_ok
	btfsc	work0, 4
	goto	mode_input_al
	
	movwf	input_ah
	addlw	30h
	call	write_lcd
mode_input_al
	bcf	PORTA, LCD_RS
	movlw	0c1h		; DDRAM=41h
	call	write_lcd
	bsf	PORTA, LCD_RS
	
	call	inputkey
	movwf	work0
	btfsc	work0, 7
	goto	mode_input
	btfsc	work0, 6
	goto	mode_result
	btfsc	work0, 5
	goto	mode_input_ah
	btfsc	work0, 4
	goto	mode_input_bh
	
	movwf	input_al
	addlw	30h
	call	write_lcd
mode_input_bh
	bcf	PORTA, LCD_RS
	movlw	0c3h		; DDRAM=43h
	call	write_lcd
	bsf	PORTA, LCD_RS
	
	call	inputkey
	movwf	work0
	btfsc	work0, 7
	goto	mode_input
	btfsc	work0, 6
	goto	mode_result
	btfsc	work0, 5
	goto	mode_input_al
	btfsc	work0, 4
	goto	mode_input_bl
	
	movwf	input_bh
	addlw	30h
	call	write_lcd
mode_input_bl
	bcf	PORTA, LCD_RS
	movlw	0c4h		; DDRAM=44h
	call	write_lcd
	bsf	PORTA, LCD_RS
	
	call	inputkey
	movwf	work0
	btfsc	work0, 7
	goto	mode_input
	btfsc	work0, 6
	goto	mode_result
	btfsc	work0, 5
	goto	mode_input_bh
	btfsc	work0, 4
	goto	mode_input_ch
	
	movwf	input_bl
	addlw	30h
	call	write_lcd
mode_input_ch
	bcf	PORTA, LCD_RS
	movlw	0c6h		; DDRAM=46h
	call	write_lcd
	bsf	PORTA, LCD_RS
	
	call	inputkey
	movwf	work0
	btfsc	work0, 7
	goto	mode_input
	btfsc	work0, 6
	goto	mode_result
	btfsc	work0, 5
	goto	mode_input_bl
	btfsc	work0, 4
	goto	mode_input_cl
	
	movwf	input_ch
	addlw	30h
	call	write_lcd
mode_input_cl
	bcf	PORTA, LCD_RS
	movlw	0c7h		; DDRAM=47h
	call	write_lcd
	bsf	PORTA, LCD_RS
	
	call	inputkey
	movwf	work0
	btfsc	work0, 7
	goto	mode_input
	btfsc	work0, 6
	goto	mode_result
	btfsc	work0, 5
	goto	mode_input_ch
	btfsc	work0, 4
	goto	mode_input_dh
	
	movwf	input_cl
	addlw	30h
	call	write_lcd
mode_input_dh
	bcf	PORTA, LCD_RS
	movlw	0c9h		; DDRAM=49h
	call	write_lcd
	bsf	PORTA, LCD_RS
	
	call	inputkey
	movwf	work0
	btfsc	work0, 7
	goto	mode_input
	btfsc	work0, 6
	goto	mode_result
	btfsc	work0, 5
	goto	mode_input_cl
	btfsc	work0, 4
	goto	mode_input_dl
	
	movwf	input_dh
	addlw	30h
	call	write_lcd
mode_input_dl
	bcf	PORTA, LCD_RS
	movlw	0cah		; DDRAM=4ah
	call	write_lcd
	bsf	PORTA, LCD_RS
	
	call	inputkey
	movwf	work0
	btfsc	work0, 7
	goto	mode_input
	btfsc	work0, 6
	goto	mode_result
	btfsc	work0, 5
	goto	mode_input_dh
	btfsc	work0, 4
	goto	mode_input_ok
	
	movwf	input_dl
	addlw	30h
	call	write_lcd
mode_input_ok
	bcf	PORTA, LCD_RS
	movlw	0ceh		; DDRAM=4eh
	call	write_lcd
	bsf	PORTA, LCD_RS
	
	call	waitkey
	movwf	work0
	btfsc	work0, 7
	goto	mode_input_menu
	xorlw	41h
	btfsc	STATUS, Z
	goto	mode_input_calc
	xorlw	3
	btfsc	STATUS, Z
	goto	mode_input_dl	; <
	xorlw	60h
	btfsc	STATUS, Z
	goto	mode_input_dl	; <
	xorlw	3
	btfsc	STATUS, Z
	goto	mode_result	; ^
	xorlw	5
	btfsc	STATUS, Z
	goto	mode_input_ah	; >
	goto	mode_input_ok
mode_input_menu
	call	mode_menu
	iorlw	0
	btfsc	STATUS, Z
	goto	mode_input
	goto	typetable
mode_input_calc
	movf	input_al, 0
	movwf	disp_ai
	bcf	STATUS, C
	rlf	input_ah, 0
	addwf	disp_ai, 1
	addwf	disp_ai, 1
	addwf	disp_ai, 1
	addwf	disp_ai, 1
	addwf	disp_ai, 1
	
	movf	input_bl, 0
	movwf	disp_bi
	bcf	STATUS, C
	rlf	input_bh, 0
	addwf	disp_bi, 1
	addwf	disp_bi, 1
	addwf	disp_bi, 1
	addwf	disp_bi, 1
	addwf	disp_bi, 1
	
	movf	input_cl, 0
	movwf	disp_ci
	bcf	STATUS, C
	rlf	input_ch, 0
	addwf	disp_ci, 1
	addwf	disp_ci, 1
	addwf	disp_ci, 1
	addwf	disp_ci, 1
	addwf	disp_ci, 1
	
	movf	input_dl, 0
	movwf	disp_di
	bcf	STATUS, C
	rlf	input_dh, 0
	addwf	disp_di, 1
	addwf	disp_di, 1
	addwf	disp_di, 1
	addwf	disp_di, 1
	addwf	disp_di, 1
	
	retlw	0


mode_menu
	bcf	PORTA, LCD_RS
	movlw	0fh		; display-on cursor-on blink-on
	call	write_lcd
	movlw	1		; clear-all
	call	write_lcd
	call	wait200ms
	
	bsf	PORTA, LCD_RS
	movlw	4dh
	call	write_lcd
	movlw	65h
	call	write_lcd
	movlw	6eh
	call	write_lcd
	movlw	75h
	call	write_lcd
	movlw	20h
	call	write_lcd
	movlw	63h
	call	write_lcd
	movlw	6fh
	call	write_lcd
	movlw	64h
	call	write_lcd
	movlw	65h
	call	write_lcd
	movlw	3ah
	call	write_lcd
mode_menu_loop0
	call	waitkey
	movwf	menu0
	xorlw	42h
	btfsc	STATUS, Z
	retlw	0
	
	btfss	menu0, KEYNUM
	goto	mode_menu_loop0
	
	movlw	2ah
	call	write_lcd
mode_menu_loop1
	call	waitkey
	movwf	menu1
	xorlw	42h
	btfsc	STATUS, Z
	retlw	0
	
	btfss	menu1, KEYNUM
	goto	mode_menu_loop1
	
	movlw	2ah
	call	write_lcd
mode_menu_loop2
	call	waitkey
	movwf	menu2
	xorlw	42h
	btfsc	STATUS, Z
	retlw	0
	
	btfss	menu2, KEYNUM
	goto	mode_menu_loop2
	
	movlw	2ah
	call	write_lcd
mode_menu_loop3
	call	waitkey
	movwf	menu3
	xorlw	42h
	btfsc	STATUS, Z
	retlw	0
	
	btfss	menu3, KEYNUM
	goto	mode_menu_loop3
	
	movlw	2ah
	call	write_lcd
	
mode_menu_check1		; 1147
	movf	menu0, 0
	xorlw	11h
	btfss	STATUS, Z
	goto	mode_menu_check2
	movf	menu1, 0
	xorlw	11h
	btfss	STATUS, Z
	goto	mode_menu_check2
	movf	menu2, 0
	xorlw	14h
	btfss	STATUS, Z
	goto	mode_menu_check2
	movf	menu3, 0
	xorlw	17h
	btfss	STATUS, Z
	goto	mode_menu_check2
	retlw	1
mode_menu_check2		; 0647
	movf	menu0, 0
	xorlw	10h
	btfss	STATUS, Z
	goto	mode_menu_check3
	movf	menu1, 0
	xorlw	16h
	btfss	STATUS, Z
	goto	mode_menu_check3
	movf	menu2, 0
	xorlw	14h
	btfss	STATUS, Z
	goto	mode_menu_check3
	movf	menu3, 0
	xorlw	17h
	btfss	STATUS, Z
	goto	mode_menu_check3
	retlw	2
mode_menu_check3		; 3922
	movf	menu0, 0
	xorlw	13h
	btfss	STATUS, Z
	goto	mode_menu_check4
	movf	menu1, 0
	xorlw	19h
	btfss	STATUS, Z
	goto	mode_menu_check4
	movf	menu2, 0
	xorlw	12h
	btfss	STATUS, Z
	goto	mode_menu_check4
	movf	menu3, 0
	xorlw	12h
	btfss	STATUS, Z
	goto	mode_menu_check4
	retlw	3
mode_menu_check4		; 9423
	movf	menu0, 0
	xorlw	19h
	btfss	STATUS, Z
	goto	mode_menu_check5
	movf	menu1, 0
	xorlw	14h
	btfss	STATUS, Z
	goto	mode_menu_check5
	movf	menu2, 0
	xorlw	12h
	btfss	STATUS, Z
	goto	mode_menu_check5
	movf	menu3, 0
	xorlw	13h
	btfss	STATUS, Z
	goto	mode_menu_check5
	retlw	4
mode_menu_check5		; 2711
	movf	menu0, 0
	xorlw	12h
	btfss	STATUS, Z
	goto	mode_menu_check6
	movf	menu1, 0
	xorlw	17h
	btfss	STATUS, Z
	goto	mode_menu_check6
	movf	menu2, 0
	xorlw	11h
	btfss	STATUS, Z
	goto	mode_menu_check6
	movf	menu3, 0
	xorlw	11h
	btfss	STATUS, Z
	goto	mode_menu_check6
	retlw	5
mode_menu_check6		; 3235
	movf	menu0, 0
	xorlw	13h
	btfss	STATUS, Z
	goto	mode_menu_check7
	movf	menu1, 0
	xorlw	12h
	btfss	STATUS, Z
	goto	mode_menu_check7
	movf	menu2, 0
	xorlw	13h
	btfss	STATUS, Z
	goto	mode_menu_check7
	movf	menu3, 0
	xorlw	15h
	btfss	STATUS, Z
	goto	mode_menu_check7
	retlw	6
mode_menu_check7
	goto	mode_menu


type1
	movlw	32h
	movwf	type2count
	movwf	type3count
	movwf	type4count
	movwf	type5count
	movwf	type6count
	
	clrf	type6a
	clrf	type6b
	clrf	type6c
	clrf	type6d
	
	bcf	PORTA, LCD_RS
	movlw	0ch		; display-on cursor-off blink-off
	call	write_lcd
	movlw	1		; clear-all
	call	write_lcd
	call	wait200ms
	
	bsf	PORTA, LCD_RS
	movlw	50h
	call	write_lcd
	movlw	72h
	call	write_lcd
	movlw	65h
	call	write_lcd
	movlw	73h
	call	write_lcd
	movlw	73h
	call	write_lcd
	movlw	20h
	call	write_lcd
	movlw	45h
	call	write_lcd
	movlw	6eh
	call	write_lcd
	movlw	74h
	call	write_lcd
	movlw	65h
	call	write_lcd
	movlw	72h
	call	write_lcd
	movlw	20h
	call	write_lcd
	movlw	6bh
	call	write_lcd
	movlw	65h
	call	write_lcd
	movlw	79h
	call	write_lcd
	
	bcf	PORTA, LCD_RS
	movlw	0c0h
	call	write_lcd		; DDRAM-40h
	bsf	PORTA, LCD_RS
	
	movlw	28h
	call	write_lcd
	movlw	4ch
	call	write_lcd
	movlw	6fh
	call	write_lcd
	movlw	6eh
	call	write_lcd
	movlw	67h
	call	write_lcd
	movlw	29h
	call	write_lcd
type1loop
	call	waitkey
	xorlw	80h
	btfss	STATUS, Z
	goto	type1loop
	
	call	mode_menu
	iorlw	0
	btfsc	STATUS, Z
	goto	type1
	goto	typetable


type2
	movf	type2count, 0
	movwf	disp_c
	call	mode_input
type2loop
	clrf	acch
	clrf	accl
	movf	disp_ai, 0
	call	acc_add
	movf	disp_ai, 0
	call	acc_add
	movf	acch, 0
	movwf	disp_ah
	movf	accl, 0
	movwf	disp_al
	
	clrf	acch
	movlw	8
	movwf	accl
	movf	disp_ci, 0
	call	acc_sub
	movf	acch, 0
	movwf	disp_bh
	movf	accl, 0
	movwf	disp_bl
	
	clrf	acch
	movlw	1
	movwf	accl
	movf	disp_ai, 0
	call	acc_add
	movf	disp_ai, 0
	call	acc_add
	movf	disp_ai, 0
	call	acc_add
	movf	disp_ci, 0
	call	acc_sub
	movf	disp_ci, 0
	call	acc_sub
	movf	acch, 0
	movwf	disp_ch
	movf	accl, 0
	movwf	disp_cl
	
	clrf	acch
	movlw	7
	movwf	accl
	movf	disp_bi, 0
	call	acc_add
	movf	disp_bi, 0
	call	acc_add
	movf	disp_bi, 0
	call	acc_add
	movf	disp_di, 0
	call	acc_sub
	movf	disp_di, 0
	call	acc_sub
	movf	disp_di, 0
	call	acc_sub
	movf	acch, 0
	movwf	disp_dh
	movf	accl, 0
	movwf	disp_dl
	
	decf	type2count, 1
	movf	type2count, 0
	movwf	disp_c
	
	call	mode_result
	goto	type2loop


type3
	movf	type3count, 0
	movwf	disp_c
	call	mode_input
type3loop
	clrf	disp_ah
	movf	disp_di, 0
	movwf	disp_al
	
	clrf	disp_bh
	movf	disp_bi, 0
	movwf	disp_bl
	
	clrf	disp_ch
	bcf	STATUS, C
	rlf	disp_ci, 0
	movwf	disp_cl
	
	clrf	disp_dh
	bcf	STATUS, C
	rlf	disp_ai, 0
	movwf	disp_dl
	
	decf	type3count, 1
	movf	type3count, 0
	movwf	disp_c
	
	call	mode_result
	goto	type3loop


type4
	movf	type4count, 0
	movwf	disp_c
	call	mode_input
type4loop
	clrf	acch
	clrf	accl
	movf	disp_ai, 0
	call	acc_add
	movf	disp_bi, 0
	call	acc_add
	movf	disp_di, 0
	call	acc_add
	movf	acch, 0
	movwf	disp_ah
	movf	accl, 0
	movwf	disp_al
	
	clrf	acch
	clrf	accl
	movf	disp_ai, 0
	call	acc_add
	movf	disp_bi, 0
	call	acc_add
	movf	disp_ci, 0
	call	acc_add
	movf	acch, 0
	movwf	disp_bh
	movf	accl, 0
	movwf	disp_bl
	
	clrf	acch
	clrf	accl
	movf	disp_ai, 0
	call	acc_add
	movf	disp_ci, 0
	call	acc_add
	movf	disp_di, 0
	call	acc_add
	movf	acch, 0
	movwf	disp_ch
	movf	accl, 0
	movwf	disp_cl
	
	clrf	acch
	clrf	accl
	movf	disp_bi, 0
	call	acc_add
	movf	disp_ci, 0
	call	acc_add
	movf	disp_di, 0
	call	acc_add
	movf	acch, 0
	movwf	disp_dh
	movf	accl, 0
	movwf	disp_dl
	
	clrf	acch
	clrf	accl
	movf	disp_ai, 0
	movwf	work0
	movwf	work1
	call	acc_mul
	movf	disp_bi, 0
	movwf	work0
	movwf	work1
	call	acc_mul
	movf	disp_ci, 0
	movwf	work0
	movwf	work1
	call	acc_mul
	movf	disp_di, 0
	movwf	work0
	movwf	work1
	call	acc_mul
	
	movf	acch, 0
	andlw	0fch
	btfsc	STATUS, Z
	goto	type4skip
	
	incf	disp_al, 1
	btfsc	STATUS, Z
	incf	disp_ah, 1
	incf	disp_bl, 1
	btfsc	STATUS, Z
	incf	disp_bh, 1
	incf	disp_cl, 1
	btfsc	STATUS, Z
	incf	disp_ch, 1
	incf	disp_dl, 1
	btfsc	STATUS, Z
	incf	disp_dh, 1
type4skip
	decf	type4count, 1
	movf	type4count, 0
	movwf	disp_c
	
	call	mode_result
	goto	type4loop


type5
	movf	type5count, 0
	movwf	disp_c
	call	mode_input
type5loop
	clrf	disp_ah
	clrf	disp_bh
	clrf	disp_ch
	clrf	disp_dh
	
	movf	disp_ai, 0
	call	type5sub
	movwf	disp_al
	
	movf	disp_bi, 0
	call	type5sub
	movwf	disp_bl
	
	movf	disp_ci, 0
	call	type5sub
	movwf	disp_cl
	
	movf	disp_di, 0
	call	type5sub
	movwf	disp_dl
	
	decf	type5count, 1
	movf	type5count, 0
	movwf	disp_c
	
	call	mode_result
	goto	type5loop


type6
	movf	type6count, 0
	movwf	disp_c
	call	mode_input
type6loop
	clrf	disp_ah
	movf	type6a, 0
	addwf	disp_bi, 0
	movwf	disp_al
	
	clrf	disp_bh
	movf	type6b, 0
	addwf	disp_ci, 0
	movwf	disp_bl
	
	clrf	disp_ch
	movf	type6c, 0
	addwf	disp_di, 0
	movwf	disp_cl
	
	clrf	disp_dh
	movf	type6d, 0
	addwf	disp_ai, 0
	movwf	disp_dl
	
	movf	disp_ai, 0
	movwf	type6a
	movf	disp_bi, 0
	movwf	type6b
	movf	disp_ci, 0
	movwf	type6c
	movf	disp_di, 0
	movwf	type6d
	
	decf	type6count, 1
	movf	type6count, 0
	movwf	disp_c
	
	call	mode_result
	goto	type6loop


init
	movlw	0c0h			; PORTA: 11000000
	movwf	PORTA
	clrf	PORTB			; PORTB: 00000000
	
	bsf	STATUS, RP0
	
	movlw	20h			; PORTA: OOIOOOOO
	movwf	PORTA
	movlw	0b0h			; PORTB: IOIIOOOO
	movwf	PORTB
	movlw	7			; RBPU, TMR0:1/256
	movwf	OPTION_REG & 7fh
	
	bcf	STATUS, RP0
	
	movlw	7			; PORTA: digital-input
	movwf	CMCON
	
	call	wait200ms
	call	wait200ms
	
	movlw	33h
	call	write_lcd8
	call	wait200ms
	
	movlw	33h
	call	write_lcd8
	call	wait200ms
	
	movlw	33h
	call	write_lcd8
	call	wait200ms
				; 8bit mode
	movlw	22h
	call	write_lcd8
				; 4bit mode
	
	movlw	28h		; 4bit 2lines 5x8font
	call	write_lcd
	movlw	0ch		; display-on cursor-off blink-off
	call	write_lcd
	movlw	6		; increment no-shift
	call	write_lcd
	movlw	1		; clear-all
	call	write_lcd
	call	wait200ms
passwordcheck
	call	mode_menu
	xorlw	1
	btfss	STATUS, Z
	goto	passwordcheck
	goto	type1


	end
