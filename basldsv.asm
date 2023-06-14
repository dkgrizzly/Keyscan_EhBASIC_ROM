
; VCF-MW 12 6502 Badge Software
; Hardware design by Lee Hart
; Software design by Daryl Rictor
;
; This software is free to use and modify in any non-commercial application.
; Comericial use is prohibited without expressed, written permission from the author.
;
;******** LOAD & SAVE PATCH FOR ENHANCED BASIC ON 65C02 Simulator
;
; Typing SAVE will caclulate start address and end address of the BASIC program and then initiate an XMODEM Send command.  
;Upon completion of the transfer, you are returned to BASIC.
;
; To load a saved program, type LOAD and an XMODEM Receive command is started.  Upon completion, you are 
; returned to BASIC.  You can type LIST to see your program.
;
; If any file transfer errors occur, it is best to retry the commmand.
;
;

Fptr 		= 	$3a			; this value must match the xmodem.asm value for ptr!
Feofp		=	$3c			; this value must match the xmodem.asm value for eofp!

;
; SAVE command
;
Psave		jsr	Pscan			; finds start and end of the program
		ldx	Smeml			;
		lda	Smemh			; get start address of BASIC program
		stx	Fptr			;
		sta	Fptr+1			; save in xmodem pointer 
		ldx	Itempl			;
		lda	Itemph			; get end address of BASIC program
		stx	Feofp			; 
		sta	Feofp+1			; save in xmodem pointer
		jmp	XModemSend		; do XMODEM send andreturn to BASIC

;
; LOAD command
;
Pload		lda	Smeml			; get start address
		sta	Feofp			; put it in XMODEM pointer
		lda	Smemh			;
		sta	Feofp+1			;
		jsr	XModemRcv		; call XMODEM receive
		jsr	Pscan			; find end of program
		lda	Itempl			; set variable and string pointers
		sta	Svarl			; to end of file
		sta	Sarryl			; this clears
		sta	Earryl			; both variable sets
		lda	Itemph			; so RUN is fresh.
		sta	Svarh			;
		sta	Sarryh			;
		sta	Earryh			;
		JMP	LAB_1319		; Return to BASIC (RTS from thissubroutine call is accounted for)

;
; Scan BASIC RAM to find start and end addresses
;
Pscan		lda	Smeml			; get start address
      		sta	Itempl			; temp pointer
      		lda	Smemh			;
      		sta	Itemph			;
Pscan1		ldy	#$00			; index = 0
		lda	(Itempl),y		; get first BASIC line (will be pointer to next line or 0)
		bne	Pscan2			; non zero means a line is present
		iny   				;
		lda	(Itempl),y		; get second byte (high byte of pointer or 0)
		bne	Pscan2			; non zero means a line is present
		clc				; double $00 = end of program
		lda	#$02			; adjust pointer to end of double $00's
		adc	Itempl			; by adding 2
		sta	Itempl			;
		lda	#$00			;
		adc	Itemph			;
		sta	Itemph			;
		rts				; done
Pscan2		ldy	#$00			; reset index
		lda	(Itempl),y		; get low byte of pointer 
		tax				; move to x
		iny				; point to second byte
		lda	(Itempl),y		; get high byte
		sta	Itemph			; set temp pointer to new line
		stx	Itempl			;
		bra	Pscan1			; repeat scan 
