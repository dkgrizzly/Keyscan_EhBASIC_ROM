; Reset / IRQ / NMI Vectors for Keyscan CA8400B
;
; Based on
; VCF-MW 12 6502 Badge Software
; Hardware design by Lee Hart
; Software design by Daryl Rictor
;
; This software is free to use and modify in any non-commercial application.
; Comericial use is prohibited without expressed, written permission from the author.
;
;****************************************************************************
; Reset, Interrupt, & Break Handlers
;****************************************************************************
RAMBANK           =   $EC

;--------------Reset handler----------------------------------------------
Reset           SEI                     ; diable interupts
                CLD                     ; clear decimal mode                      
                LDX   #$FF              ;
                TXS                     ; init stack pointer
                LDY   #$FF              ;
InitDelay
                DEX
                BNE InitDelay
                DEY
                BNE InitDelay

                LDX   #$FF              ;
                TXS                     ; init stack pointer

                JSR   VIA_Init
                JSR   Serial_Init       ; init serial port
                JSR   LED_Init

                LDA   #$00              ; Clear registers
                TAY                     ;
                TAX                     ;
                CLC                     ; clear flags
                CLD                     ; clear decimal mode
                CLI                     ; enable IRQ's
                JMP  MonitorBoot        ; Monitor for cold reset                       

NMIjump         RTI                     ; NMI null routine

Interrupt       PHA                     ; Save A
                TXA                     ; Save X
                PHA
                TYA                     ; Save Y
                PHA

                LDA VIA0_ORB            ; Save RAM Bank
                AND #$1F
                PHA

                LDA VIA0_ORB            ; Select RAM Bank $1F
                ORA #$1F
                STA VIA0_ORB

                CLD                     ; Clear decimal mode

                LDA UART0_ISR           ; Check UARTs for RX data
                LSR
                BCS UART1_CheckIRQ
                JSR UART0_IRQ_Handler

UART1_CheckIRQ
                LDA UART1_ISR
                LSR
                BCS UART2_CheckIRQ
                JSR UART1_IRQ_Handler

UART2_CheckIRQ
                LDA UART2_ISR
                LSR
                BCS UART3_CheckIRQ
                JSR UART2_IRQ_Handler

UART3_CheckIRQ
                LDA UART3_ISR
                LSR
                BCS VIA1_CheckIRQ
                JSR UART3_IRQ_Handler

VIA1_CheckIRQ
                LDA VIA1_IER            ; Check for VIA1 Timer IRQ
                AND VIA1_IFR
                BPL VIA0_CheckIRQ
                JSR VIA1_IRQ_Handler

VIA0_CheckIRQ
                LDA VIA0_IER
                AND VIA0_IFR
                BPL VIA2_CheckIRQ
                JSR VIA0_IRQ_Handler

VIA2_CheckIRQ
                LDA VIA2_IER
                AND VIA2_IFR
                BPL ReturnFromInterrupt
                JSR VIA2_IRQ_Handler

ReturnFromInterrupt                
                PLA                     ; Restore RAM Bank
                STA RAMBANK
                LDA VIA0_ORB
                AND #$E0
                ORA RAMBANK
                STA VIA0_ORB

                PLA                     ; Restore Y
                TAY
                PLA                     ; Restore X
                TAX
                PLA                     ; Restore A
                RTI

;
;  NMIjmp      =     $FFFA             
;  RESjmp      =     $FFFC             
;  INTjmp      =     $FFFE             

               *=    $FFFA
               .word  NMIjump          ; NMI jump vector
               .word  Reset            ; RES jump vector
               .word  Interrupt        ; IRQ jump vector
;end of file
