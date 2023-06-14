; UART Driver for Keyscan CA8400B
;
; Based on
; VCF-MW 12 6502 Badge Software
; Hardware design by Lee Hart
; Software design by Daryl Rictor
;
; This software is free to use and modify in any non-commercial application.
; Comericial use is prohibited without expressed, written permission from the author.
;

Serbuf      =   $200    ; 128 byte buffer
Bufin       =   $EA     ; zp pointer
Bufout      =   $EB     ; zp pointer

UART0_DAT   =   $8000
UART0_DLL   =   $8000
UART0_DLM   =   $8001
UART0_IER   =   $8001
UART0_FCR   =   $8002
UART0_ISR   =   $8002
UART0_EFR   =   $8002
UART0_LCR   =   $8003
UART0_MCR   =   $8004
UART0_LSR   =   $8005
UART0_MSR   =   $8006
UART0_SPR   =   $8007

UART1_DAT   =   $8008
UART1_DLL   =   $8008
UART1_DLM   =   $8009
UART1_IER   =   $8009
UART1_FCR   =   $800A
UART1_ISR   =   $800A
UART1_EFR   =   $800A
UART1_LCR   =   $800B
UART1_MCR   =   $800C
UART1_LSR   =   $800D
UART1_MSR   =   $800E
UART1_SPR   =   $800F

UART2_DAT   =   $8010
UART2_DLL   =   $8010
UART2_DLM   =   $8011
UART2_IER   =   $8011
UART2_FCR   =   $8012
UART2_ISR   =   $8012
UART2_EFR   =   $8012
UART2_LCR   =   $8013
UART2_MCR   =   $8014
UART2_LSR   =   $8015
UART2_MSR   =   $8016
UART2_SPR   =   $8017

UART3_DAT   =   $8018
UART3_DLL   =   $8018
UART3_DLM   =   $8019
UART3_IER   =   $8019
UART3_FCR   =   $801A
UART3_ISR   =   $801A
UART3_EFR   =   $801A
UART3_LCR   =   $801B
UART3_MCR   =   $801C
UART3_LSR   =   $801D
UART3_MSR   =   $801E
UART3_SPR   =   $801F

;---------------------------------------------------------------------
;  16C654 Serial Input
;---------------------------------------------------------------------
UART0_IRQ_Handler
        PHA             ; save Acc register
        PHX             ; save X register
        LDA UART0_DAT   ; get data
        PLX             ; restore X register
        PLA             ; restore Acc register
        RTS             ; done

UART1_IRQ_Handler
        PHA             ; save Acc register
        PHX             ; save X register
        LDA UART1_DAT   ; get data
        PLX             ; restore X register
        PLA             ; restore Acc register
        RTS             ; done

UART2_IRQ_Handler
        PHA             ; save Acc register
        PHX             ; save X register
        LDA UART2_DAT   ; get data
        PLX             ; restore X register
        PLA             ; restore Acc register
        RTS             ; done

UART3_IRQ_Handler
        PHA             ; save Acc register
        PHX             ; save X register
        LDA UART3_DAT   ; get data
        LDX Bufin       ; get pointer
        STA Serbuf,x    ; safe in buffer
        TXA             ; save old pointer
        INA             ; adjust pointer
        AND #$7F        ; limit to 128 bytes
        CMP Bufout      ; check for full buffer     
        BNE Stopcont    ; not full
        TXA             ; full, don't advance pointer
Stopcont    STA Bufin       ; save pointer
        PLX             ; restore X register
        PLA             ; restore Acc register
        RTS             ; done

;---------------------------------------------------------------------
;  16C654 Serial Outputs
;---------------------------------------------------------------------
UART0_TXByte
        PHA             ; Save Acc
UART0_TXWait
        LDA UART0_LSR   ; Wait until TX Holding Register is empty
        AND #$20
        BEQ UART0_TXWait

        PLA             ; restore A
        STA UART0_DAT
        RTS             ; done

UART1_TXByte
        PHA             ; Save Acc
UART1_TXWait
        LDA UART1_LSR   ; Wait until TX Holding Register is empty
        AND #$20
        BEQ UART1_TXWait

        PLA             ; restore A
        STA UART1_DAT
        RTS             ; done

UART2_TXByte
        PHA             ; Save Acc
UART2_TXWait
        LDA UART2_LSR   ; Wait until TX Holding Register is empty
        AND #$20
        BEQ UART2_TXWait

        PLA             ; restore A
        STA UART2_DAT
        RTS             ; done

UART3_TXByte
        PHA             ; Save Acc
UART3_TXWait
        LDA UART3_LSR   ; Wait until TX Holding Register is empty
        AND #$20
        BEQ UART3_TXWait

        PLA             ; restore A
        STA UART3_DAT
        RTS             ; done


Output
Serial_Output
        JMP UART3_TXByte

;=================================================================
; System Functions
;=================================================================
;
; serial_init = initialize the serial IO
;
; serial_input = wait for receieved character and return in A
;
; serial_scan = scan for key, return C=0 if no key, C=1 for key with key in A
;
; serial_output = send a character out the serial port (located above)
;
; ----------------------------------------------------------------
; Initialization of serial IO
Serial_Init
        LDA #$BF        ; Enable EFR Access
        STA UART3_LCR
        STA UART1_LCR
        STA UART2_LCR
        STA UART0_LCR

        LDA #$10        ; Enable IER[4:7], ISR[4:5], FCR[4:5], MCR[5:7]
        STA UART3_EFR
        STA UART1_EFR
        STA UART2_EFR
        STA UART0_EFR

        LDA #$03        ; Set Serial 8n1
        STA UART3_LCR
        STA UART1_LCR
        STA UART2_LCR
        STA UART0_LCR

        LDA #$80        ; Divide input clock by 4
        STA UART3_MCR
        STA UART1_MCR
        STA UART2_MCR
        STA UART0_MCR

        LDA #$BF        ; Enable EFR Access
        STA UART3_LCR
        STA UART1_LCR
        STA UART2_LCR
        STA UART0_LCR

        LDA #$0         ; Disable IER[4:7], ISR[4:5], FCR[4:5], MCR[5:7]
        STA UART3_EFR
        STA UART1_EFR
        STA UART2_EFR
        STA UART0_EFR

        LDA #$83        ; Enable Baudrate Divisor Latch
        STA UART3_LCR
        STA UART1_LCR
        STA UART2_LCR
        STA UART0_LCR

        LDA #$18        ; 9600 Baud
        STA UART3_DLL
        LDA #$6         ; 38400 Baud
        STA UART1_DLL
        LDA #$18        ; 9600 Baud
        STA UART2_DLL
        LDA #$18        ; 9600 Baud
        STA UART0_DLL

        LDA #$0         ; Baudrate divisor MSB
        STA UART3_DLM
        STA UART1_DLM
        STA UART2_DLM
        STA UART0_DLM

        LDA #$03        ; Disable Baudrate Divisor Latch
        STA UART3_LCR
        STA UART1_LCR
        STA UART2_LCR
        STA UART0_LCR

        LDA UART3_MSR   ; Clear Status & Data buffers
        LDA UART1_MSR
        LDA UART2_MSR
        LDA UART0_MSR

        LDA UART3_LSR
        LDA UART1_LSR
        LDA UART2_LSR
        LDA UART0_LSR

        LDA UART3_ISR
        LDA UART1_ISR
        LDA UART2_ISR
        LDA UART0_ISR

        LDA UART3_DAT
        LDA UART1_DAT
        LDA UART2_DAT
        LDA UART0_DAT

        LDA #$09        ; INTx Enable, DTR
        STA UART3_MCR
        STA UART1_MCR
        STA UART2_MCR
        LDA #$0A        ; INTx Enable, RTS
        STA UART0_MCR

        LDA #$01        ; Interrupt Enable for RX
        STA UART3_IER
        STA UART1_IER
        STA UART2_IER
        STA UART0_IER

        STZ Bufin       ;
        STZ Bufout      ;
        RTS             ; done


Serial_Disable_FIFO
        LDA #$03
        STA UART3_LCR
        STA UART1_LCR
        STA UART2_LCR
        STA UART0_LCR

        LDA #$00
        STA UART3_FCR
        STA UART1_FCR
        STA UART2_FCR
        STA UART0_FCR
        RTS

Serial_Enable_FIFO
        LDA #$03        ; Disable Baudrate Divisor Latch and EFR Access
        STA UART3_LCR
        STA UART1_LCR
        STA UART2_LCR
        STA UART0_LCR

        LDA #$07        ; Enable and reset FIFOs
        STA UART3_FCR
        STA UART1_FCR
        STA UART2_FCR
        STA UART0_FCR

        LDA #$00        ; Disable FIFOs
        STA UART3_FCR
        STA UART1_FCR
        STA UART2_FCR

        LDA #$47        ; RX FIFO Interrupt Triggers at 16 bytes
        STA UART0_FCR
        STA UART3_FCR
        STA UART2_FCR

        LDA #$07        ; RX FIFO Interrupt Triggers at 8 bytes
        STA UART1_FCR
        RTS

; ----------------------------------------------------------------
; Wait for Character to be received
;
Input_Chr
Serial_Input    
Sin1    
        lda Bufout      ; get buffer output
        cmp Bufin       ; compare with buffer input
        beq Sin1        ; nothing to get yet
        phx         ; save X
        tax         ; move pointer to X
        ina         ; adjust pointer
        and #$7F        ; limit size to 128 bytes
        sta Bufout      ; save pointer
        lda Serbuf,x    ; get data
        plx         ; restore X
        ora #$00        ; set flags for data byte
        rts         ; done

; ----------------------------------------------------------------
; Scan for character (non-waiting)

Scan_Input
Serial_Scan
Serial_ScanQ    lda Bufout      ; get buffer output
        cmp Bufin       ; compare with buffer input
        clc         ; set no data flag
        beq Sscan1      ; nothing, return carry clear
        phx         ; save X
        tax         ; move pointer to X
        ina         ; adjust pointer
        and #$7F        ; limit size to 128 bytes
        sta Bufout      ; save pointer
        lda Serbuf,x    ; get data
        plx         ; restore X
        sec         ; set data received flag
        ora #$00        ; set flags for data byte
Sscan1      rts         ; done

