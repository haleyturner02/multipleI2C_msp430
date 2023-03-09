;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
; Haley Turner, Zachary Becker, EELE 465, Project 04
;
; LCD Slave
;
; This project uses I2C communication with the MSP430FR2355 as the master and
; two MSP430FR2310 devices as slaves. Both slaves receive data from the master for the
; keypad input and use it to control different outputs. One 2310 controls the LED bar
; to display patterns when A, B, C, or D on the keypad are pressed. The other 2310
; controls an LCD screen to display which character on the keypad was pressed.
;
; R5 - Register for LCDsetup counter
; R6 - Register for 30ms delay
; R7 - Register for storing upper nibble of ASCII character
; R8 - Register for storing lower nibble of ASCII character & resulting ASCII character byte
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

	bis.b	#BIT6, &P6DIR					; Use LED2 as indicator
	bic.b	#BIT6, &P6OUT					; Start LED2 off

	bis.b	#BIT4, &P1OUT					; Output pin for DB4
	bic.b	#BIT4, &P1OUT

	bis.b	#BIT5, &P1DIR					; Output pin for DB5
	bic.b	#BIT5, &P1OUT

	bis.b	#BIT6, &P1DIR					; Output pin for DB6
	bic.b	#BIT6, &P1OUT

	bis.b	#BIT7, &P1DIR					; Output pin for DB7
	bic.b	#BIT7, &P1OUT
											; (R/W = 0 write, tie pin 5 on LCD to ground)

	bis.b	#BIT1, &P1DIR					; Output pin for RS
	bic.b	#BIT1, &P1OUT					; (RS = 0 instruction, RS = 1 data)

	bis.b	#BIT0, &P1DIR					; Output pin for E, data starts on falling edge
	bic.b	#BIT0, &P1OUT

	; Need initialization for I2C Slave

	mov.w	#0, R5
	mov.w	#0, R6
	mov.w	#0, R7
	mov.w	#0, R8

	bic.b	#LOCKLPM5, &PM5CTL0				; Disable GPIO power-on default high_Z mode

	; Setup Timer B0
	bis.w #TBCLR, &TB0CTL 					; Clear timer
	bis.w #TBSSEL__SMCLK, &TB0CTL 			; Choose SMCLK as source
	bis.w #ID__4, &TB0CTL 					; Divide by 4
	bis.w #TBIDEX_7, &TB0EX0				; Divide by 8
	bis.w #MC__UP, &TB0CTL					; Set timer to UP mode

	; Setup Timer Compare
	mov.w #14000, &TB0CCR0					; Set compare value (SMCLK spec. @ 1 MHz)

	bic.w #CCIFG, &TB0CCTL0					; Clear CCIFG flag
	eint 									; Global enable


main:

	call	#LCDstart

WaitForNewValue:

	; Need I2C Receive to put Keypad input value into a register
	; Move upper nibble into R7, lower nibble into R8

	cmp.w	#0, R7						; Check if new value has been received from master (no keypad value has upper nibble == 0000)
	jz		WaitForNewValue

	call	#LCDdisplay					; Call subroutine to display received character

	mov.w	#0, R5
	mov.w	#0, R6
	mov.w	#0, R7
	mov.w	#0, R8

	jmp		WaitForNewValue

;-------------------------------------------------------------------------------
; Subroutine: LCDstart
;-------------------------------------------------------------------------------

LCDstart:

	bic.w	#CCIE, &TB0CCTL0			; Disable flag for 30ms delay
	call	#Delay30					; Delay ~30ms on startup
	mov.w	#3, R5						; Move 3 into R5 for LCDsetup counter
	call	#LCDsetup					; Setup LCD display

	ret


;-------------------------------------------------------------------------------
; Subroutine: LCDSetup
;-------------------------------------------------------------------------------

LCDsetup:

	call	#Configure
	call	#Latch
	call	#Delay30
	dec.b	R5
	jnz		LCDsetup

	call	#Configure2
	call	#Latch
	call	#Delay30

	ret

;-------------------------- END LCDSetup ---------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: Delay30
;-------------------------------------------------------------------------------

Delay30:								; Timer ~ 30ms (temporary compare value for testing)

	bis.w 	#CCIE, &TB0CCTL0			; Enable local enable for CCRO in TB0
	cmp.b	#0, R6						; Check R6 to determine if 30ms has passed
	jz		Delay30						; Continue waiting until R6 is no longer 0

	bic.w 	#CCIE, &TB0CCTL0			; Disable local enable for CCRO in TB0
	mov.w	#0, R6						; Reset R6 value for next time delay is needed

	ret

;-------------------------- END Delay30 ----------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: Configure
;-------------------------------------------------------------------------------

Configure:

	bic.b	#BIT1, &P1OUT					; Clear RS bit
	bis.b	#BIT4, &P1OUT					; Set P1.4 & P1.5
	bis.b	#BIT5, &P1OUT
	bic.b	#BIT6, &P1OUT					; Clear P1.6 & P1.7
	bic.b	#BIT7, &P1OUT

	ret

;-------------------------- END Configure --------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: Latch
;-------------------------------------------------------------------------------

Latch:

	bis.b	#BIT0, &P1OUT					; Set E bit
	mov.w	#1000, R6						; Put 1000 into R6 for 1000 cycle delay

Delay1000:

	dec.w	R6
	cmp.w	#0, R6
	jnz		Delay1000

	bic.b	#BIT0, &P1OUT					; Clear E bit

	ret

;-------------------------- END Latch ------------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: Configure2
;-------------------------------------------------------------------------------

Configure2:

	bic.b	#BIT1, &P1OUT					; Clear RS bit
	bic.b	#BIT4, &P1OUT					; Set P1.5
	bis.b	#BIT5, &P1OUT					; Clear P1.4, P1.6 & P1.7
	bic.b	#BIT6, &P1OUT
	bic.b	#BIT7, &P1OUT

	ret

;-------------------------- END Configure2 -------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: LCDdisplay
;-------------------------------------------------------------------------------

LCDdisplay:

	bis.b	#BIT1, &P1OUT					; Set RS bit

	call	#UpperNibble					; Set upper nibble for column of ASCII chart
	call	#Latch
	call	#Delay30
	call	#LowerNibble					; Set lower nibble for row of ASCII chart
	call	#Latch
	call	#Delay30

	add.b	R7, R8							; Combine upper and lower nibble and put into R8


	ret

;-------------------------- END LCDdisplay -------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: UpperNibble
;-------------------------------------------------------------------------------

UpperNibble:

	; Set upper nibble of value
	;mov.b	#R4, R7				; Move data received from master into R7
	rla.b	R7
	rla.b	R7
	rla.b	R7
	rla.b	R7

	ret

;-------------------------- END UpperNibble ------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: LowerNibble
;-------------------------------------------------------------------------------

LowerNibble:

	; Set lower nibble of value
	mov.b	#0011b, R8				; Temporary value, replace with data received

	ret

;-------------------------- END LowerNibble ------------------------------------

;-------------------------------------------------------------------------------
; Interrupt Service Routine for TB0 CCR0
;-------------------------------------------------------------------------------

ISR_TB0_CCR0:

	mov.b	#1, R6								; Move 1 into R6 to indicate 30ms has passed
	bic.w 	#CCIFG, &TB0CCTL0					; Clear CCIFG flag
	reti

;-------------------------- END ISR --------------------------------------------

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
            
            .sect ".int43"					; TB0 CCR0 Vector
			.short ISR_TB0_CCR0
