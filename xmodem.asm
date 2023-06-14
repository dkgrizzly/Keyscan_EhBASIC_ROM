
; VCF-MW 12 6502 Badge Software
; Hardware design by Lee Hart
; Software design by Daryl Rictor
;
; This software is free to use and modify in any non-commercial application.
; Comericial use is prohibited without expressed, written permission from the author.
;
; XMODEM/CRC Sender/Receiver for the 65C02
;
; By Daryl Rictor Aug 2002
;
; A simple file transfer program to allow transfers between the SBC and a 
; console device utilizing the x-modem/CRC transfer protocol.  Requires 
; ~1200 bytes of either RAM or ROM, 132 bytes of RAM for the receive buffer,
; and 12 bytes of zero page RAM for variable storage.
;
;**************************************************************************
; This implementation of XMODEM/CRC does NOT conform strictly to the 
; XMODEM protocol standard in that it (1) does not accurately time character
; reception or (2) fall back to the Checksum mode.

; (1) For timing, it uses a crude timing loop to provide approximate
; delays.  These have been calibrated against a 1MHz CPU clock.  I have
; found that CPU clock speed of up to 5MHz also work but may not in
; every case.  Windows HyperTerminal worked quite well at both speeds!
;
; (2) Most modern terminal programs support XMODEM/CRC which can detect a
; wider range of transmission errors so the fallback to the simple checksum
; calculation was not implemented to save space.
;**************************************************************************
;
; Files transferred via XMODEM-CRC will have the load address contained in
; the first two bytes in little-endian format:  
;  FIRST BLOCK
;     offset(0) = lo(load start address),
;     offset(1) = hi(load start address)
;     offset(2) = data byte (0)
;     offset(n) = data byte (n-2)
;
; Subsequent blocks
;     offset(n) = data byte (n)
;
; One note, XMODEM send 128 byte blocks.  If the block of memory that
; you wish to save is smaller than the 128 byte block boundary, then
; the last block will be padded with zeros.  Upon reloading, the
; data will be written back to the original location.  In addition, the
; padded zeros WILL also be written into RAM, which could overwrite other
; data.   
;
;-------------------------- The Code ----------------------------
;
; zero page variables (adjust these to suit your needs)
;
;
Lastblk		=	$35		; flag for last block
Blkno		=	$36		; block number 
Errcnt		=	$37		; error counter 10 is the limit
Bflag		=	$37		; block flag 

Crc		=	$38		; CRC lo byte  (two byte variable)
Crch		=	$39		; CRC hi byte  

Ptr		=	$3a		; data pointer (two byte variable)
Ptrh		=	$3b		;   "    "

Eofp		=	$3c		; end of file address pointer (2 bytes)
Eofph		=	$3d		;  "	"	"	"

Retry		=	$3e		; retry counter 
Retry2		=	$3f		; 2nd counter

;
;
; non-zero page variables and buffers
;
;
Rbuff		=	$0370      	; temp 132 byte receive buffer 
					;(place anywhere, page aligned)
;
;
;  tables and constants
;
;
; The crclo & crchi labels are used to point to a lookup table to calculate
; the CRC for the 128 byte data blocks.  There are two implementations of these
; tables.  One is to use the tables included (defined towards the end of this
; file) and the other is to build them at run-time.  If building at run-time,
; then these two labels will need to be un-commented and declared in RAM.
;
;crclo		=	$7D00      	; Two 256-byte tables for quick lookup
;crchi		= 	$7E00      	; (should be page-aligned for speed)
;
;
;
; XMODEM Control Character Constants
SOH		=	$01		; start block
EOT		=	$04		; end of text marker
ACK		=	$06		; good block acknowledged
NAK		=	$15		; bad block acknowledged
CAN		=	$18		; cancel (not standard, not supported)
CR		=	$0d		; carriage return
LLF		=	$0a		; line feed
ESC		=	$1b		; ESC to exit

;
;^^^^^^^^^^^^^^^^^^^^^^ Start of Program ^^^^^^^^^^^^^^^^^^^^^^
;
; Xmodem/CRC transfer routines
; By Daryl Rictor, August 8, 2002
;
; v1.0  released on Aug 8, 2002.
;
;
;		*= 	$FA00		; Start of program (adjust to your needs)
;
; Enter this routine with the beginning address stored in the zero page address
; pointed to by ptr & ptrh and the ending address stored in the zero page address
; pointed to by eofp & eofph.
;
;
XModemSend	jsr	PrintMsg	; send prompt and info
		stz	Errcnt		; error counter set to 0
		stz	Lastblk		; set flag to false
		stz	Blkno		; set block # to 0
Wait4CRC	lda	#$ff		; 3 seconds
		sta	Retry2		;
		jsr	GetByte		;
		bcc	Wait4CRC	; wait for something to come in...
		cmp	#'C'		; is it the "C" to start a CRC xfer?
		beq	LdBuffer	; yes
		cmp	#ESC		; is it a cancel? <Esc> Key
		bne	Wait4CRC	; No, wait for another character
		jmp	PrtAbort	; Print abort msg and exit
LdBuffer	lda	Lastblk		; Was the last block sent?
		beq	LdBuff0		; no, send the next one	
		jmp 	Done		; yes, we're done
LdBuff0		ldx	#$02		; init pointers
		ldy	#$00		;
		inc	Blkno		; inc block counter
		lda	Blkno		; 
		sta	Rbuff		; save in 1st byte of buffer
		eor	#$FF		; 
		sta	Rbuff+1		; save 1's comp of blkno next

LdBuff1		lda	(Ptr),y		; save 128 bytes of data
		sta	Rbuff,x		;
LdBuff2		sec			; 
		lda	Eofp		;
		sbc	Ptr		; Are we at the last address?
		bne	LdBuff4		; no, inc pointer and continue
		lda	Eofph		;
		sbc	Ptrh		;
		bne	LdBuff4		; 
		inc	Lastblk		; Yes, Set last byte flag
LdBuff3		inx			;
		cpx	#$82		; Are we at the end of the 128 byte block?
		beq	SCalcCRC	; Yes, calc CRC
		lda	#$00		; Fill rest of 128 bytes with $00
		sta	Rbuff,x		;
		beq	LdBuff3		; Branch always

LdBuff4		inc	Ptr		; Inc address pointer
		bne	LdBuff5		;
		inc	Ptrh		;
LdBuff5		inx			;
		cpx	#$82		; last byte in block?
		bne	LdBuff1		; no, get the next
SCalcCRC	jsr 	CalcCRC
		lda	Crch		; save Hi byte of CRC to buffer
		sta	Rbuff,y		;
		iny			;
		lda	Crc		; save lo byte of CRC to buffer
		sta	Rbuff,y		;
Resend		ldx	#$00		;
		lda	#SOH
		jsr	Output		; send SOH
SendBlk		lda	Rbuff,x		; Send 132 bytes in buffer to the console
		jsr	Output		;
		inx			;
		cpx	#$84		; last byte?
		bne	SendBlk		; no, get next
		lda	#$FF		; yes, set 3 second delay 
		sta	Retry2		; and
		jsr	GetByte		; Wait for Ack/Nack
		bcc	Seterror	; No chr received after 3 seconds, resend
		cmp	#ACK		; Chr received... is it:
		beq	LdBuffer	; ACK, send next block
		cmp	#NAK		; 
		beq	Seterror	; NAK, inc errors and resend
		cmp	#ESC		;
		beq	PrtAbort	; Esc pressed to abort
					; fall through to error counter
Seterror	inc	Errcnt		; Inc error counter
		lda	Errcnt		; 
		cmp	#$0A		; are there 10 errors? (Xmodem spec for failure)
		bne	Resend		; no, resend block
PrtAbort	jsr	Flush		; yes, too many errors, flush buffer,
		jmp	Print_Err	; print error msg and exit
Done		Jmp	Print_Good	; All Done..Print msg and exit
;
;
;

XModemRcv	jsr	PrintMsg	; send prompt and info
		lda	#$01		;
		sta	Blkno		; set block # to 1
		lda	Eofp		; get start address from Monitor command
		sta	Ptr		; Hexdigits
		lda	Eofp+1		; and save to our pointer
		sta	Ptr+1		;
StartCrc	lda	#'C'		; "C" start with CRC mode
		jsr	Output		; send it
		lda	#$FF		;
		sta	Retry2		; set loop counter for ~3 sec delay
		lda	#$00		;
               	sta	Crc		;
		sta	Crch		; init CRC value	
		jsr	GetByte		; wait for input
               	bcs	GotByte		; byte received, process it
		bcc	StartCrc	; resend "C"

StartBlk	lda	#$FF		; 
		sta	Retry2		; set loop counter for ~3 sec delay
		jsr	GetByte		; get first byte of block
		bcc	StartBlk	; timed out, keep waiting...
GotByte		cmp	#ESC		; quitting?
                bne	GotByte1	; no
		jmp	Print_Err	; print err and return
GotByte1        cmp	#SOH		; start of block?
		beq	BegBlk		; yes
		cmp	#EOT		;
		bne	BadCrc		; Not SOH or EOT, so flush buffer & send NAK	
		jmp	RDone		; EOT - all done!
BegBlk		ldx	#$00		;
GetBlk		lda	#$ff		; 3 sec window to receive characters
		sta 	Retry2		;
GetBlk1		jsr	GetByte		; get next character
		bcc	BadCrc		; chr rcv error, flush and send NAK
GetBlk2		sta	Rbuff,x		; good char, save it in the rcv buffer
		inx			; inc buffer pointer	
		cpx	#$84		; <01> <FE> <128 bytes> <CRCH> <CRCL>
		bne	GetBlk		; get 132 characters
		ldx	#$00		;
		lda	Rbuff,x		; get block # from buffer
		cmp	Blkno		; compare to expected block #	
		beq	GoodBlk1	; matched!
		jsr	Print_Err	; Unexpected block number - abort	
		jmp	Flush		; mismatched - flush buffer and return
GoodBlk1	eor	#$ff		; 1's comp of block #
		inx			;
		cmp	Rbuff,x		; compare with expected 1's comp of block #
		beq	GoodBlk2 	; matched!
		jsr	Print_Err	; Unexpected block number - abort	
		jmp 	Flush		; mismatched - flush buffer and return
GoodBlk2	jsr	CalcCRC		; calc CRC
		lda	Rbuff,y		; get hi CRC from buffer
		cmp	Crch		; compare to calculated hi CRC
		bne	BadCrc		; bad crc, send NAK
		iny			;
		lda	Rbuff,y		; get lo CRC from buffer
		cmp	Crc		; compare to calculated lo CRC
		beq	GoodCrc		; good CRC
BadCrc		jsr	Flush		; flush the input port
		lda	#NAK		;
		jsr	Output		; send NAK to resend block
		jmp	StartBlk	; start over, get the block again			
GoodCrc		ldx	#$02		;
CopyBlk		ldy	#$00		; set offset to zero
CopyBlk3	lda	Rbuff,x		; get data byte from buffer
		sta	(Ptr),y		; save to target
		inc	Ptr		; point to next address
		bne	CopyBlk4	; did it step over page boundary?
		inc	Ptr+1		; adjust high address for page crossing
CopyBlk4	inx			; point to next data byte
		cpx	#$82		; is it the last byte
		bne	CopyBlk3	; no, get the next one
IncBlk		inc	Blkno		; done.  Inc the block #
		lda	#ACK		; send ACK
		jsr	Output		;
		jmp	StartBlk	; get next block

RDone		lda	#ACK		; last block, send ACK and exit.
		jsr	Output		;
		jsr	Flush		; get leftover characters, if any
		jsr	Print_Good	;
		rts			;
;
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;=========================================================================
;
; subroutines
;
;
;
GetByte		;lda	#$00		; wait for chr input and cycle timing loop
		stz	Retry		; set low value of timing loop
StartCrcLp	jsr	Serial_ScanQ	; get chr from serial port, don't wait, no LED update
		bcs	GetByte1	; got one, so exit
		dec   	Retry		; no character received, so dec counter
		bne	StartCrcLp	;
		dec	Retry2		; dec hi byte of counter
		bne	StartCrcLp	; look for character again
		clc			; if loop times out, CLC, else SEC and return
GetByte1	rts			; with character in "A"
;
Flush		lda	#$70		; flush receive buffer
		sta	Retry2		; flush until empty for ~1 sec.
Flush1		jsr	GetByte		; read the port
		bcs	Flush		; if chr recvd, wait for another
		rts			; else done
;
PrintMsg	ldx	#$00		; PRINT starting message
PrtMsg1		lda   	Msg,x		
		beq	PrtMsg2			
		jsr	Output
		inx
		bne	PrtMsg1
PrtMsg2		rts
Msg		.byte	"Begin XMODEM/CRC transfer.  Press <Esc> to abort..."
		.BYTE  	CR, LLF
               	.byte   0
;
Print_Err	ldx	#$00		; PRINT Error message
PrtErr1		lda   	ErrMsg,x
		beq	PrtErr2
		jsr	Output
		inx
		bne	PrtErr1
PrtErr2		rts
ErrMsg		.byte 	"Transfer Error!"
		.BYTE  	CR, LLF
                .byte   0
;
Print_Good	ldx	#$00		; PRINT Good Transfer message
Prtgood1	lda   	GoodMsg,x
		beq	Prtgood2
		jsr	Output
		inx
		bne	Prtgood1
Prtgood2	rts
GoodMsg		.byte	EOT,CR,LLF,EOT,CR,LLF,EOT,CR,LLF,CR,LLF
		.byte 	"Transfer Successful!"
		.BYTE  	CR, LLF
                .byte   0
;
;
;=========================================================================
;
;
;  CRC subroutines 
;
;
CalcCRC		lda	#$00		; yes, calculate the CRC for the 128 bytes
		sta	Crc		;
		sta	Crch		;
		ldy	#$02		;
CalcCRC1	lda	Rbuff,y		;
		eor 	Crc+1 		; Quick CRC computation with lookup tables
       		tax		 	; updates the two bytes at crc & crc+1
       		lda 	Crc		; with the byte send in the "A" register
       		eor 	Crchi,X
       		sta 	Crc+1
      	 	lda 	Crclo,X
       		sta 	Crc
		iny			;
		cpy	#$82		; done yet?
		bne	CalcCRC1	; no, get next
		rts			; y=82 on exit


