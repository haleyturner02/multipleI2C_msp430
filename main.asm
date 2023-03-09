;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
; Haley Turner, Zachary Becker, EELE 465, Project 04
;
; I2C Master
;
; This project uses I2C communication with the MSP430FR2355 as the master and
; two MSP430FR2310 devices as slaves. Both slaves receive data from the master for the
; keypad input and use it to control different outputs. One 2310 controls the LED bar
; to display patterns when A, B, C, or D on the keypad are pressed. The other 2310
; controls an LCD screen to display which character on the keypad was pressed.
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------

init:

	bis.b	#BIT0, &P1DIR					; Init LED1 as output
	bic.b	#BIT0, &P1OUT					; Start LED1 off


	mov.w	#0, R4							; Clear register data for column
	mov.w	#0, R5							; Clear register data for row
	mov.w	#0, R6							; Clear register data for keypad input

	bic.b	#LOCKLPM5, &PM5CTL0				; Disable GPIO power-on default high_Z mode

main:

	mov.w	#0777h, R8					; Initialize outer delay loop counter (small delay for button response time)
	call	#Delay

	call 	#ColumnInput				; Change columns to be inputs, rows to be outputs
	call	#CheckKeypad

	cmp.b	#0087h, R4					; Check if '1' was pressed
	;jz		Transmit1					; LCD Data for 1: 0011 0001
										; LED Data for 1: 0087h

	cmp.b	#0083h, R4					; Check if '2' was pressed
	;jz		Transmit2					; LCD Data for 2: 0011 0010
										; LED Data for 2: 0083h

	cmp.b	#0081h, R4					; Check if '3' was pressed
	;jz		Transmit3					; LCD Data for 3: 0011 0011
										; LED Data for 3: 0081h

	cmp.b	#0080h, R4					; Check if 'A' was pressed
	;jz		TransmitA					; LCD Data for A: 0100 0001
										; LED Data for A: 0080h

	cmp.b	#0047h, R4					; Check if '4' was pressed
	;jz		Transmit4					; LCD Data for 4: 0011 0100
										; LED Data for 4: 0047h

	cmp.b	#0043h, R4					; Check if '5' was pressed
	;jz		Transmit5					; LCD Data for 5: 0011 0101
										; LED Data for 5: 0043h

	cmp.b	#0041h, R4					; Check if '6' was pressed
	;jz		Transmit6					; LCD Data for 6: 0011 0110
										; LED Data for 6: 0041h

	cmp.b	#0040h, R4					; Check if 'B' was pressed
	;jz		TransmitB					; LCD Data for B: 0100 0010
										; LED Data for B: 0040h

	cmp.b	#0027h, R4					; Check if '7' was pressed
	;jz		Transmit7					; LCD Data for 7: 0011 0111
										; LED Data for 7: 0027h

	cmp.b	#0023h, R4					; Check if '8' was pressed
	;jz		Transmit8					; LCD Data for 8: 0011 1000
										; LED Data for 8: 0023h

	cmp.b	#0021h, R4					; Check if '9' was pressed
	;jz		Transmit9					; LCD Data for 9: 0011 1001
										; LED Data for 9: 0021h

	cmp.b	#0020h, R4					; Check if 'C' was pressed
	;jz		TransmitC					; LCD Data for C: 0100 0011
										; LED Data for C: 0020h

	cmp.b	#0017h, R4					; Check if '*' was pressed
	;jz		Transmit*					; LCD Data for *: 0010 1010
										; LED Data for *: 0017h

	cmp.b	#0013h, R4					; Check if '0' was pressed
	;jz		Transmit0					; LCD Data for 0: 0011 0000
										; LED Data for 0: 0013h

	cmp.b	#0011h, R4					; Check if '#' was pressed
	;jz		Transmit#					; LCD Data for #: 0010 0011
										; LED Data for #: 0011h

	cmp.b	#0010h, R4					; Check if 'D' was pressed
	;jz		TransmitD					; LCD Data for D: 0100 0100
										; LED Data for D: 0010h

	mov.w	#0, R4						; Clear register data for column
	mov.w	#0, R5						; Clear register data for row

	jmp		main

;-------------------------------------------------------------------------------
; Subroutine: CheckKeypad
;-------------------------------------------------------------------------------

CheckKeypad:

	mov.b	&P3IN, R6					; Move keypad input byte from Port 3 to R6
	call	#CheckColumn				; Call subroutine to check which column was pressed

	call	#RowInput					; Change rows to be inputs, columns to be outputs

	mov.b	&P3IN, R6					; Move keypad input byte from Port 3 to R6
	call	#CheckRow					; Call subroutine to check which row was pressed

	call	#ColumnInput				; Change columns back to inputs, rows to be outputs

	add.b	R5, R4						; Concatenate column and row bits and put into R4

	ret

;-------------------------- END CheckKeypad ------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: CheckColumn
;-------------------------------------------------------------------------------

CheckColumn:

	bit.b	#BIT0, R6					; Test if bit 0 is set (column 4)
	jnz		Column4

	bit.b	#BIT1, R6					; Test if bit 1 is set (column 3)
	jnz		Column3

	bit.b	#BIT2, R6					; Test if bit 2 is set (column 2)
	jnz		Column2

	bit.b	#BIT3, R6					; Test if bit 3 is set (column 3)
	jnz		Column1

	cmp.b	#0, R6
	jz		NoColumn

	ret


Column1:

	mov.w	#00F8h, R4					; Move F8h into R4 if column 1 pressed
	ret

Column2:

	mov.w	#00F4h, R4					; Move F4h into R4 if column 2 pressed
	ret

Column3:

	mov.w	#00F2h, R4					; Move F2h into R4 if column 3 pressed
	ret

Column4:

	mov.w	#00F1h, R4					; Move F1h into R4 if column 4 pressed
	ret

NoColumn:

	mov.w	#0, R4						; Clear register data for column
	ret

;-------------------------- END CheckColumn ------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: CheckRow
;-------------------------------------------------------------------------------

CheckRow:

	bit.b	#BIT4, R6					; Test if bit 4 is set (row 4)
	jnz		Row4

	bit.b	#BIT5, R6					; Test if bit 5 is set (row 3)
	jnz		Row3

	bit.b	#BIT6, R6					; Test if bit 6 is set (row 2)
	jnz		Row2

	bit.b	#BIT7, R6					; Test if bit 7 is set (row 1)
	jnz		Row1

	cmp.b	#0, R6
	jz		NoRow

	ret

Row1:

	mov.w	#008Fh, R5					; Move 8Fh into R5 if row 1 pressed
	ret

Row2:

	mov.w	#004Fh, R5					; Move 4Fh into R5 if row 2 pressed
	ret

Row3:

	mov.w	#002Fh, R5					; Move 2Fh into R5 if row 3 pressed
	ret

Row4:

	mov.w	#001Fh, R5					; Move 1Fh into R5 if row 4 pressed
	ret

NoRow:

	mov.w	#0, R5						; Clear register data for row
	ret

;-------------------------- END CheckRow ---------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: RowInput
;-------------------------------------------------------------------------------

RowInput:

	bic.b 	#BIT4, &P3DIR					; Initialize P3.4 as input
	bis.b	#BIT4, &P3REN					; Enable pull up/down resistor for P3.4
	bic.b	#BIT4, &P3OUT					; Configure resistor as pull down

	bic.b	#BIT5, &P3DIR					; Intialize P3.5 as input
	bis.b	#BIT5, &P3REN					; Enable pull up/down resistor for P3.5
	bic.b	#BIT5, &P3OUT					; Configure resistor as pull down

	bic.b	#BIT6, &P3DIR					; Initialize P3.6 as input
	bis.b	#BIT6, &P3REN					; Enable pull up/down resistor for P3.6
	bic.b	#BIT6, &P3OUT					; Configure resistor as pull down

	bic.b	#BIT7, &P3DIR					; Initialize P3.7 as input
	bis.b	#BIT7, &P3REN					; Enable pull up/down resistor for P3.7
	bic.b	#BIT7, &P3OUT					; Configure resistor as pull down

	bis.b	#BIT0, &P3DIR					; Initialize P3.0 as output
	bis.b	#BIT0, &P3OUT					; Set P3.0 to be on

	bis.b	#BIT1, &P3DIR					; Initialize P3.1 as output
	bis.b	#BIT1, &P3OUT					; Set P3.1 to be on

	bis.b	#BIT2, &P3DIR					; Initialize P3.2 as output
	bis.b	#BIT2, &P3OUT					; Set P3.2 to be on

	bis.b	#BIT3, &P3DIR					; Initialize P3.3 as output
	bis.b	#BIT3, &P3OUT					; Set P3.3 to be on

	ret

;-------------------------- END RowInput ---------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: ColumnInput
;-------------------------------------------------------------------------------

ColumnInput:

	bic.b 	#BIT0, &P3DIR					; Initialize P3.0 as input
	bis.b	#BIT0, &P3REN					; Enable pull up/down resistor for P3.0
	bic.b	#BIT0, &P3OUT					; Configure resistor as pull down

	bic.b	#BIT1, &P3DIR					; Intialize P3.1 as input
	bis.b	#BIT1, &P3REN					; Enable pull up/down resistor for P3.1
	bic.b	#BIT1, &P3OUT					; Configure resistor as pull down

	bic.b	#BIT2, &P3DIR					; Initialize P3.2 as input
	bis.b	#BIT2, &P3REN					; Enable pull up/down resistor for P3.2
	bic.b	#BIT2, &P3OUT					; Configure resistor as pull down

	bic.b	#BIT3, &P3DIR					; Initialize P3.3 as input
	bis.b	#BIT3, &P3REN					; Enable pull up/down resistor for P3.3
	bic.b	#BIT3, &P3OUT					; Configure resistor as pull down

	bis.b	#BIT4, &P3DIR					; Initialize P3.4 as output
	bis.b	#BIT4, &P3OUT					; Set P3.4 to be on

	bis.b	#BIT5, &P3DIR					; Initialize P3.5 as output
	bis.b	#BIT5, &P3OUT					; Set P3.5 to be on

	bis.b	#BIT6, &P3DIR					; Initialize P3.6 as output
	bis.b	#BIT6, &P3OUT					; Set P3.6 to be on

	bis.b	#BIT7, &P3DIR					; Initialize P3.7 as output
	bis.b	#BIT7, &P3OUT					; Set P3.7 to be on

	ret

;-------------------------- END ColumnInput ------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: Delay
;-------------------------------------------------------------------------------

Delay:

	mov.w	#50, R7

InnerDelay:

	dec.w	R7
	jnz		InnerDelay
	dec.w	R8
	jnz		Delay

	ret

;-------------------------- END Delay ------------------------------------------

;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            
