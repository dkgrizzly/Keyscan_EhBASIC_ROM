; Homebrew Firmware for Keyscan CA8400B
;
; Based on
; VCF-MW 12 6502 Badge Software
; Hardware design by Lee Hart
; Software design by Daryl Rictor
;
; This software is free to use and modify in any non-commercial application.
; Comericial use is prohibited without expressed, written permission from the author.
;
; Instructions to Assemble
;
; 1.  Open this file in the 6502 Simulator
; 2.  Select "Simulator->Options from the top menu bar
; 3.  On the Simulator tab:
;	Select Finish running with 0xBB instruction
;	Set IO area to 0x7F00
; 4.  On the Assember tab:
;	Uncheck generate extra byte for BRK   
; 5.  On the General Tab:
;	Select 65C02, 6501
; 6.  Close Options and Assemble
; 7.  Select SAVE CODE from the File menu
;       Select Binary Image (*.65b) and open the options tab
;       Select 0x8000 as the start address (0x8000 file size)
;	close options and Save the file.
; 8.  Burn the Binary Code.65b file to your EPROM and install in your badge. 
; 9.  Go play!
;
	*=  $B000                    ; start at $B000
	.include "basic.asm"         ; Enhanced BASIC V2.22
	.include "basldsv.asm"	     ; EH-BASIC load & save support

	*=  $E000                    ; start at $F000
 	.include "sbcos.asm"         ; ML Montor 
	.include "xmodem.asm"        ; Xmodem-CRC downloader
	.include "CRCtable.asm"      ; XMODEM CRC TABLE (these need to be page aligned, so put first)
	.include "serial.asm"	     ; 16C654 Hardware UARTs (9600,n,8,1)
	.include "via.asm"	     ; 65C22 VIAs
	.include "rtc.asm"	     ; DS1284 RTC
	.include "led.asm"	     ; Reader LEDs

	*=  $FF00                    ; start at $F800
	.include "reset.asm"         ; Reset & IRQ handler

