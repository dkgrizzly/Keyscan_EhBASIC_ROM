; VIA Driver for Keyscan CA8400B

VIA0_ORB    =   $8020
VIA0_ORA    =   $8021
VIA0_DDRB   =   $8022
VIA0_DDRA   =   $8023
VIA0_T1C_L  =   $8024
VIA0_T1C_H  =   $8025
VIA0_T1L_L  =   $8026
VIA0_T1L_H  =   $8027
VIA0_T2C_L  =   $8028
VIA0_T2C_H  =   $8029
VIA0_SR     =   $802A
VIA0_ACR    =   $802B
VIA0_PCR    =   $802C
VIA0_IFR    =   $802D
VIA0_IER    =   $802E
VIA0_ORB_NH =   $802F

VIA1_ORB    =   $8030
VIA1_ORA    =   $8031
VIA1_DDRB   =   $8032
VIA1_DDRA   =   $8033
VIA1_T1C_L  =   $8034
VIA1_T1C_H  =   $8035
VIA1_T1L_L  =   $8036
VIA1_T1L_H  =   $8037
VIA1_T2C_L  =   $8038
VIA1_T2C_H  =   $8039
VIA1_SR     =   $803A
VIA1_ACR    =   $803B
VIA1_PCR    =   $803C
VIA1_IFR    =   $803D
VIA1_IER    =   $803E
VIA1_ORB_NH =   $803F

VIA2_ORB    =   $80A0
VIA2_ORA    =   $80A1
VIA2_DDRB   =   $80A2
VIA2_DDRA   =   $80A3
VIA2_T1C_L  =   $80A4
VIA2_T1C_H  =   $80A5
VIA2_T1L_L  =   $80A6
VIA2_T1L_H  =   $80A7
VIA2_T2C_L  =   $80A8
VIA2_T2C_H  =   $80A9
VIA2_SR     =   $80AA
VIA2_ACR    =   $80AB
VIA2_PCR    =   $80AC
VIA2_IFR    =   $80AD
VIA2_IER    =   $80AE
VIA2_ORB_NH =   $80AF

ZP_SYSTICKS =   $58     ; System Ticks low byte (256Hz)
;           =   $59     ; System Ticks mid byte (1Hz)
;           =   $5A     ; System Ticks high byte (1/256Hz)

;----------------------------------------------------------------------------
VIA_Init
        PHA

        LDA #$40        ; T1 Continuous interrupts
        STA VIA0_ACR
        STA VIA1_ACR
        STA VIA2_ACR
        LDA #$7F        ; Disable all VIA0 interrupts
        STA VIA0_IER
        STA VIA1_IER
        STA VIA2_IER
        LDA #$C1        ; Enable Timer2, CB1, CA2 interrupts
        STA VIA0_IER

        LDA #$FF        ; 57600 Ticks // 256Hz
        STA VIA0_T1C_L
        LDA #$E0
        STA VIA0_T1C_H

        LDA #$E2
        STA VIA0_PCR

        LDA #$7F        ; VIA0.PB[0:4] RAM BANK Control, VIA0.PB[6] Reader TX, VIA0.PB[7] Reader RX
        STA VIA0_DDRB
        STA VIA0_ORB

        LDA #$FF
        STA VIA0_DDRA   ; Turn off Control 1 Outputs
        STA VIA0_ORA

        STA VIA1_DDRA   ; Turn off Control 2 Outputs
        STA VIA1_ORA

        STA VIA1_DDRB   ; Turn off Control 3 Outputs
        STA VIA1_ORB

        STA VIA2_DDRA   ; Turn off Control 4 Outputs
        STA VIA2_ORA

        STA VIA2_DDRB   ; Turn off Control 5 Outputs
        STA VIA2_ORB

        LDA #$FF        ; 32768 Ticks // 450 Hz?
        STA VIA1_T1C_L
        LDA #$7F
        STA VIA1_T1C_H

        LDA #0
        STA ZP_SYSTICKS
        STA ZP_SYSTICKS+1
        STA ZP_SYSTICKS+2

        PLA
        RTS

VIA0_IRQ_Handler
        LSR
        BCS VIA0_CA2_Handler
        LSR
        LSR
        LSR
        BCS VIA0_CB2_Handler
        LSR
        LSR
        LSR
        BCS VIA0_Timer1_Handler
        LDA #$36
        STA VIA0_IFR        ; Clear any unexpected interrupts
        RTS

VIA0_CA2_Handler
        LDA #$01            ; Clear the interrupt
        STA VIA0_IFR
        RTS

VIA0_CB2_Handler
        LDA #$08            ; Clear the interrupt
        STA VIA0_IFR
        RTS

; 256Hz Timer Interrupt
VIA0_Timer1_Handler
        LDA #$FF            ; Reset the Timer
        STA VIA0_T1C_L
        LDA #$E0
        STA VIA0_T1C_H

        JSR LED_scan

        INC ZP_SYSTICKS
        BNE .done

        INC ZP_SYSTICKS+1
        BNE .done

        INC ZP_SYSTICKS+2
        BNE .done

.done
        LDA #$40            ; Clear the interrupt
        STA VIA0_IFR
        RTS

VIA1_IRQ_Handler
        AND #$40
        BNE VIA1_Timer1_Handler

        LDA #$7F
        STA VIA1_IFR        ; Clear any unexpected interrupts
        RTS

; 450Hz Timer Interrupt
VIA1_Timer1_Handler
        LDA #$FF            ; Reset the Timer
        STA VIA1_T1C_L
        LDA #$7F
        STA VIA1_T1C_H

        LDA #$40            ; Clear the interrupt
        STA VIA1_IFR
        RTS

VIA2_IRQ_Handler
        AND #$40
        BNE VIA2_Timer1_Handler

        LDA #$7F
        STA VIA2_IFR        ; Clear any unexpected interrupts
        RTS

VIA2_Timer1_Handler
        LDA #$FF            ; Reset the Timer
        STA VIA2_T1C_L
        LDA #$7F
        STA VIA2_T1C_H

        LDA #$40            ; Clear the interrupt
        STA VIA2_IFR
        RTS
