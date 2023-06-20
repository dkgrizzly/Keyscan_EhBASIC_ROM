; LED driver for Keyscan CA8400B
;
; Based on
; VCF-MW 12 6502 Badge Software
; Hardware design by Lee Hart
; Software design by Daryl Rictor
;
; This software is free to use and modify in any non-commercial application.
; Comericial use is prohibited without expressed, written permission from the author.
;
    
LDbuff      =   $2C0        ; descrete LED bit pattern buffer 32 bits max
Lptr        =   $E2     ; LED pointer
Ldig        =   $E3     ; digit counter
Lscn        =   $E4     ; 16 bit scan speed delay
Lscnc       =   $E5     ; scan counter
LEDchk1     =   $E6     ; config checksum 1
LEDchk2     =   $E7     ; config checksum 2

LEDIO       =   $80B0       ; IO address base for LED display

LSCAN       =   $70     ; constant scan speed

;
; Scan back and forth, aka Knightrider, on the descrete LED's
;
LDdef   .byte   $80, $40, $20, $10, $08, $04, $02, $01
        .byte   $01, $02, $04, $08, $10, $20, $40, $80
        .byte   $80, $40, $20, $10, $08, $04, $02, $01
        .byte   $01, $02, $04, $08, $10, $20, $40, $80
        

;----------------------------------------------------------------------------
LED_Init
        lda LEDchk1     ; check if we have already initialized the video buffer
        cmp #$A5        ; first checksum byte = $A5
        bne Linit2      ; if not a match, we will initialize the checksums and buffer
        lda LEDchk2     ;
        cmp #$5A        ; second checksum is $5A
        beq Linit3      ; match, initialize just buffer pointers and shift counter 
Linit2
        lda #$A5        ; init first checksum
        sta LEDchk1     ;
        lda #$5A        ; init second checksum
        sta LEDchk2     ; 
        ldy #$1F        ; store default display in buffer 32 bytes
Linit1
        lda LDdef, y    ; get descrete LED
        sta LDbuff, y   ; save in buffer
        dey             ; get next character
        bpl Linit1      ; loop until all 32 done 
Linit3
        STZ Lptr        ; clear pointer
        lda #LSCAN
        sta Lscn        ; Set scan speed
        sta Lscnc       ; init counter
        rts             ; done


;----------------------------------------------------------------------------
; call this to complete 1 digit scan.
; call repeatedly to refresh entire display and scroll
; This gets called while waiting for user input via the Monitor's IO routines.
;
LED_scan
        dec Lscnc       ; decrement scan counter
        bne Led_sfin3   ; not ready yet
        pha             ; save a
        phx             ; save x

        ldx Lscn        ; get scan speed
        stx Lscnc       ; reset on-time delay
        beq Led_sfin2   ; disable LED refresh if 0

        ldx Lptr
        lda LDbuff, x   ; get descrete LED code
        sta LEDIO       ; update LED display

        lda Lptr        ; get character pointer
        ina             ; scroll one to the left
        and #$1F        ; mask to 32 characters
        sta Lptr        ; save it

Led_sfin2
        plx             ; restore x
        pla             ; restore a
Led_sfin3
        rts             ; done
;----------------------------------------------------------------------------
