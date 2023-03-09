;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
; Haley Turner, Zachary Becker, EELE 465, Project 04
;
; This project uses I2C communication with the MSP430FR2355 as the master and
; two MSP430FR2310 devices as slaves. Both slaves receive data from the master for the
; keypad input and use it to control different outputs. One 2310 controls the LED bar
; to display patterns when A, B, C, or D on the keypad are pressed. The other 2310
; controls an LCD screen to display which character on the keypad was pressed.
;
; R4 - Register for receiving data from master
; R9- Register for PressB binary counter
; R10- Register for PressC rotating counter
; R11- Register for PressA toggle counter
; R12- Register for PressD sequence counter
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

	bis.b	#BIT0, &P1DIR					; Set LED 0 on LED bar to be an output
	bic.b	#BIT0, &P1OUT					; Start LED 0 on LED bar off

	bis.b	#BIT1, &P1DIR					; Set LED 1 on LED bar to be an output
	bic.b	#BIT1, &P1OUT					; Start LED 1 on LED bar off

	bis.b	#BIT4, &P1DIR					; Set LED 2 on LED bar to be an output
	bic.b	#BIT4, &P1OUT					; Start LED 2 on LED bar off

	bis.b	#BIT5, &P1DIR					; Set LED 3 on LED bar to be an output
	bic.b	#BIT5, &P1OUT					; Start LED 3 on LED bar off

	bis.b	#BIT6, &P1DIR					; Set LED 4 on LED bar to be an output
	bic.b	#BIT6, &P1OUT					; Start LED 4 on LED bar off

    bis.b	#BIT7, &P1DIR					; Set LED 5 on LED bar to be an output
	bic.b	#BIT7, &P1OUT					; Start LED 5 on LED bar off

	bis.b	#BIT6, &P2DIR					; Set LED 6 on LED bar to be an output
	bic.b	#BIT6, &P2OUT					; Start LED 6 on LED bar off

	bis.b	#BIT7, &P2DIR					; Set LED 7 on LED bar to be an output
	bic.b	#BIT7, &P2OUT					; Start LED 7 on LED bar off

	; Need initialization for I2C Slave

	mov.w	#0, R4

	bic.b	#LOCKLPM5, &PM5CTL0				; Disable GPIO power-on default high_Z mode

main:

	; I2C Receive to put Keypad input value into a register (R4)

	call	#FindButton

	mov.w	#0, R9							; Clear register data for PressB binary counter
	mov.w	#0, R10							; Clear register data for PressC rotating counter
	mov.w	#0, R11							; Clear register data for PressA toggle counter
	mov.w	#0, R12							; Clear register data for PressD sequence counter

	jmp 	main

;-------------------------------------------------------------------------------
; Subroutine: FindButton
;-------------------------------------------------------------------------------

FindButton:

	cmp.b	#0080h, R4					; Check if 'A' was sent from master
	jz		PressA

	cmp.b	#0040h, R4					; Check if 'B' was sent from master
	jz		PressB

	cmp.b	#0020h, R4					; Check if 'C' was sent from master
	jz		PressC

	cmp.b	#0010h, R4					; Check if 'D' was sent from master
	jz		PressD

	mov.w	#0, R4						; Clear data stored in R4

	ret

;-------------------------- END FindButton -------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: PressA
;-------------------------------------------------------------------------------
PressA:									; Use LED bar to make XOXOXOXO pattern

	inc.b	R11							; Increase toggle counter in R11
	cmp.b	#2, R11						; Check if toggle counter is 1 or 2
	jz		ResetA						; Reset counter and turn off LEDs if R11 holds 2
	call	#SetLED0					; Set LED 0 if R11 holds 1
	call	#SetLED2					; Set LED 2 if R11 holds 1
	call 	#SetLED4					; Set LED 4 if R11 holds 1
	call	#SetLED6					; Set LED 6 if R11 holds 1

StaticCont:

	mov.w	#0, R4						; Clear register holding data received

	mov.w	#0FFFh, R8					; Delay for binary counter display
	call	#Delay

	; Need to update data received in R4

	cmp.b	#0, R4
	jz		StaticCont					; Jump to StaticCont if no new data received

	cmp.b	#0080h, R4
	jz		PressA						; Jump back to PressA if 'A' pressed again

	jmp		FindButton					; Return to FindButton if new key pressed

;-------------------------- END PressA -----------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: ResetA
;-------------------------------------------------------------------------------
ResetA:

	call	#ResetLED
	mov.w	#0, R11

	jmp		StaticCont
;-------------------------- END ResetA -----------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: PressB
;-------------------------------------------------------------------------------
PressB:
	inc.b	R9							; Increase binary counter in R9
	cmp.b	#256, R9					; Check if binary counter has reached 256
	jz		ResetB						; Reset counter to 0 if R9 holds 256
	call	#BinaryCounter				; Display binary counter value on LED bar

	mov.w	#0, R4						; Clear register holding data received

	mov.w	#0FFFh, R8					; Delay for binary counter display
	call	#Delay

	; Need to update data received in R4

	cmp.b	#0, R4
	jz		PressB						; Continue PressB subroutine if no new key pressed

	cmp.b	#0040h, R4
	jz		ResetB						; Reset counter if 'B' pressed again

	jmp		FindButton					; Return to FindButton if new key pressed
;-------------------------- END PressB -----------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: ResetB
;-------------------------------------------------------------------------------
ResetB:

	mov.b	#0, R9						; Move 0 into R9 to reset binary counter

	jmp		PressB
;-------------------------- END ResetB -----------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: BinaryCounter
;-------------------------------------------------------------------------------
BinaryCounter:

	bic.b	#BIT0, &P6OUT
	bit.b	#BIT0, R9					; Check if BIT0 is set in binary counter
	jz		BC_LED1
	call	#SetLED0


BC_LED1:
	bic.b	#BIT1, &P6OUT
	bit.b	#BIT1, R9					; Check if BIT1 is set in binary counter
	jz	 	BC_LED2
	call	#SetLED1


BC_LED2:
	bic.b	#BIT2, &P6OUT
	bit.b	#BIT2, R9 					; Check if BIT2 is set in binary counter
	jz	 	BC_LED3
	call	#SetLED2


BC_LED3:
	bic.b	#BIT3, &P6OUT
	bit.b	#BIT3, R9					; Check if BIT3 is set in binary counter
	jz		BC_LED4
	call	#SetLED3


BC_LED4:
	bic.b	#BIT4, &P6OUT
	bit.b	#BIT4, R9					; Check if BIT4 is set in binary counter
	jz		BC_LED5
	call	#SetLED4


BC_LED5:
	bic.b	#BIT0, &P2OUT
	bit.b	#BIT5, R9					; Check if BIT5 is set in binary counter
	jz		BC_LED6
	call	#SetLED5


BC_LED6:
	bic.b	#BIT1, &P2OUT
	bit.b	#BIT6, R9					; Check if BIT6 is set in binary counter
	jz		BC_LED7
	call	#SetLED6

BC_LED7:
	bic.b	#BIT2, &P2OUT
	bit.b	#BIT7, R9					; Check if BIT7 is set in binary counter
	jz		ReturnToPressB
	call	#SetLED7

ReturnToPressB:

	ret									; Return to PressB subroutine

;-------------------------- END BinaryCounter ----------------------------------

;-------------------------------------------------------------------------------
; Subroutine: PressC
;-------------------------------------------------------------------------------
PressC:

	call	#ResetLED

	inc.b	R10							; Increase rotating counter in R10
	cmp.b	#9, R10						; Check if rotating counter has reached 9
	jz		ResetC						; Reset counter to 0 if R10 holds 9
	call	#RotatingCounter


	mov.w	#0, R4						; Clear register holding data received

	mov.w	#0FFFh, R8					; Delay for rotating counter display
	call	#Delay

	; Need to update data received in R4

	cmp.b	#0, R4
	jz		PressC						; Continue PressC subroutine if no new key pressed

	cmp.b	#0020h, R4
	jz		ResetC						; Reset counter if 'C' pressed again

	jmp		FindButton					; Return to FindButton if new key pressed
;-------------------------- END PressC -----------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: ResetC
;-------------------------------------------------------------------------------
ResetC:

	mov.w	#0, R10

	jmp		PressC
;-------------------------- END ResetC -----------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: RotatingCounter
;-------------------------------------------------------------------------------
RotatingCounter:

	cmp.b	#1, R10
	jz		SetLED0

	cmp.b	#2, R10
	jz		SetLED1

	cmp.b	#3, R10
	jz		SetLED2

	cmp.b	#4, R10
	jz		SetLED3

	cmp.b	#5, R10
	jz		SetLED4

	cmp.b	#6, R10
	jz		SetLED5

	cmp.b	#7, R10
	jz		SetLED6

	cmp.b	#8, R10
	jz		SetLED7

	ret
;-------------------------- END RotatingCounter --------------------------------

;-------------------------------------------------------------------------------
; Subroutine: PressD
;-------------------------------------------------------------------------------
PressD:

	call	#ResetLED

	inc.b	R12							; Increase rotating counter in R12
	cmp.b	#7, R12						; Check if sequence counter has reached 7
	jz		ResetD						; Reset counter to 0 if R10 holds 9
	call	#SequenceCounter


	mov.w	#0, R4						; Clear register holding data received

	mov.w	#0FFFh, R8					; Delay for rotating counter display
	call	#Delay

	; Need to update data received in R4
	cmp.b	#0, R4
	jz		PressD						; Continue PressC subroutine if no new key pressed

	cmp.b	#0010h, R4
	jz		ResetD						; Reset counter if 'C' pressed again

	jmp		FindButton					; Return to FindButton if new key pressed
;-------------------------- END PressD -----------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: ResetD
;-------------------------------------------------------------------------------
ResetD:

	mov.w	#0, R12

	jmp		PressD
;-------------------------- END ResetD -----------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: SequenceCounter
;-------------------------------------------------------------------------------
SequenceCounter:

	cmp.b	#1, R12
	jz		SC_Pattern1

	cmp.b	#2, R12
	jz		SC_Pattern2

	cmp.b	#3, R12
	jz		SC_Pattern3

	cmp.b	#4, R12
	jz		SC_Pattern4

	cmp.b	#5, R12
	jz		SC_Pattern3

	cmp.b	#6, R12
	jz		SC_Pattern2

SC_Pattern1:
	call	#SetLED3
	call	#SetLED4
	ret

SC_Pattern2:
	call	#SetLED2
	call	#SetLED5
	ret

SC_Pattern3:
	call	#SetLED1
	call	#SetLED6
	ret

SC_Pattern4:
	call	#SetLED0
	call	#SetLED7
	ret
;-------------------------- END SequenceCounter --------------------------------

;-------------------------------------------------------------------------------
; Subroutine: SetLEDX
;-------------------------------------------------------------------------------
SetLED0:
	bis.b	#BIT0, &P6OUT
	ret

SetLED1:
	bis.b	#BIT1, &P6OUT
	ret

SetLED2:
	bis.b	#BIT2, &P6OUT
	ret

SetLED3:
	bis.b	#BIT3, &P6OUT
	ret

SetLED4:
	bis.b	#BIT4, &P6OUT
	ret

SetLED5:
	bis.b	#BIT0, &P2OUT
	ret

SetLED6:
	bis.b	#BIT1, &P2OUT
	ret

SetLED7:
	bis.b	#BIT2, &P2OUT
	ret
;-------------------------- END SetLEDX ----------------------------------------

;-------------------------------------------------------------------------------
; Subroutine: ResetLED
;-------------------------------------------------------------------------------
ResetLED:
	bic.b	#BIT0, &P6OUT
	bic.b	#BIT1, &P6OUT
	bic.b	#BIT2, &P6OUT
	bic.b	#BIT3, &P6OUT
	bic.b	#BIT4, &P6OUT
	bic.b	#BIT0, &P2OUT
	bic.b	#BIT1, &P2OUT
	bic.b	#BIT2, &P2OUT

	ret
;-------------------------- END ResetLED ---------------------------------------

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
            
