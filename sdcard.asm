SDC_ORA = $8021
SDC_DDRA = $8023

SD1_CS   = $80
SD1_SCK  = $40
SD1_MOSI = $20
SD1_MISO = $10

SD2_CS   = $08
SD2_SCK  = $04
SD2_MOSI = $02
SD2_MISO = $01

SD2_IDLE = SD2_CS | SD2_SCK | SD2_MOSI
SD1_IDLE = SD1_CS | SD1_SCK | SD1_MOSI

SDC_OUTPUTPINS = SD2_IDLE | SD1_IDLE

SD2_START = SD1_IDLE | SD2_MOSI
SD2_END   = SD1_IDLE | SD2_CS | SD2_MOSI
SD2_nMOSI = SD1_IDLE | SD2_SCK | SD2_CS

SD1_START = SD2_IDLE | SD1_MOSI
SD1_END   = SD2_IDLE | SD1_CS | SD1_MOSI
SD1_nMOSI = SD2_IDLE | SD1_SCK | SD1_CS

zp_sd_counter     = $38  ; Byte Counter
zp_sd_drive       = $39  ; Drive Number
zp_sd_cmd_buffer  = $3A  ; 6-byte temporary command buffer
                         ; also used by Monitor ROM and XModem
zp_sd_dat_address = $EA  ; Data pointer low byte
;                   $EB  ; Data pointer high byte
zp_sd_card_status = $EC  ; Bitfield of available drives

; read sector
; pass address in zp_sd_cmd_buffer bytes 1-4
; pass dest buffer address in zp_sd_dat_address
; pass drive number in zp_sd_drive
SD_ReadSector
  phy
  sei                    ; Disable interupts while talking to SD card

; Command 17 - READ_SINGLE_BLOCK
  lda #$51
  sta zp_sd_cmd_buffer
  lda #$01
  sta zp_sd_cmd_buffer+5
  
  lda zp_sd_drive
.drive1
  cmp #$01
  bne .drive2
  jsr sd1_sendcommand
  jsr sd1_waitresult
  cmp #$00
  bne .errout
  jsr sd1_waitresult
  cmp #$fe
  beq .readgotdata1

  jmp .errout

.drive2
  cmp #$02
  bne .errout
  jsr sd2_sendcommand
  jsr sd2_waitresult
  cmp #$00
  bne .errout
  jsr sd2_waitresult
  cmp #$fe
  beq .readgotdata2
  ;jmp .errout

.errout
  cli
  lda #$FF
  ply
  rts

.readgotdata1
  ; Need to read 512 bytes.  Read two at a time, 256 times.
  lda #0
  ldy #0
  sta zp_sd_counter ; counter
.readloop1
  jsr sd1_readbyte
  sta (zp_sd_dat_address),y
  iny
  jsr sd1_readbyte
  sta (zp_sd_dat_address),y
  iny
  dec zp_sd_counter ; counter
  bne .readloop1

  ; End command
  lda #SD1_END
  sta SDC_ORA

  jmp .success

.readgotdata2
  ; Need to read 512 bytes.  Read two at a time, 256 times.
  lda #0
  ldy #0
  sta zp_sd_counter ; counter
.readloop2
  jsr sd2_readbyte
  sta (zp_sd_dat_address),y
  iny
  jsr sd2_readbyte
  sta (zp_sd_dat_address),y
  iny
  dec zp_sd_counter ; counter
  bne .readloop2

  ; End command
  lda #SD2_END
  sta SDC_ORA

  ;jmp .success

.success
  lda #0
  cli
  ply
  rts


SD_Init:
  ; Let the SD card boot up, by pumping the clock with SD CS disabled

  ; We need to apply around 80 clock pulses with CS and MOSI high.
  ; Normally MOSI doesn't matter when CS is high, but the card is
  ; not yet is SPI mode, and in this non-SPI state it does care.
  
  lda #SDC_OUTPUTPINS
  sta SDC_ORA

  lda #SDC_OUTPUTPINS
  sta SDC_DDRA

  lda #SD1_CS | SD1_MOSI | SD2_CS | SD2_MOSI
  ldx #160               ; toggle the clock 160 times, so 80 low-high transitions
.preinitloop:
  eor #SD1_SCK | SD2_SCK
  sta SDC_ORA
  dex
  bne .preinitloop

; Initialize no drives available
  lda #0
  sta zp_sd_card_status

; Try initalizing drive 1
.drive1
  lda #1
  sta zp_sd_drive
  jsr drive_init
  bne .drive2
  lda zp_sd_card_status
  ora #$01
  sta zp_sd_card_status

; Try initalizing drive 2
.drive2
  lda #2
  sta zp_sd_drive
  jsr drive_init
  bne .done
  lda zp_sd_card_status
  ora #$02
  sta zp_sd_card_status
  
.done
  rts


drive_init
  jsr cmd0
  cmp #$01
  bne .drive_fail

  jsr cmd8
  cmp #$00
  bne .drive_fail

.cmd55_retry
  lda #0
  sta zp_sd_counter ; retry counter

  jsr cmd55
  ; Expect status response $01 (not initialized)
  cmp #$01
  bne .drive_fail

  jsr cmd41
  ; Status response $00 means initialised
  cmp #$00
  beq .drive_done

  ; Otherwise expect status response $01 (not initialized)
  cmp #$01
  bne .drive_fail

  ; Retry 256 times before giving up on a drive.
  inc zp_sd_counter
  beq .drive_fail

  ; Not initialized yet, so wait a while then try again.
  ; This retry is important, to give the card time to initialize.
  jsr delay
  jmp .cmd55_retry

.drive_done
  lda #$00
  rts

.drive_fail
  lda #$FF
  rts

; Command 0 - GO_IDLE_STATE / Enter SPI Mode
cmd0
  lda #$40
  sta zp_sd_cmd_buffer+0
  lda #0
  sta zp_sd_cmd_buffer+1
  sta zp_sd_cmd_buffer+2
  sta zp_sd_cmd_buffer+3
  sta zp_sd_cmd_buffer+4
  lda #$95
  sta zp_sd_cmd_buffer+5

  lda zp_sd_drive
.drive1
  cmp #$01
  bne .drive2
  jsr sd1_sendcommand
  ; Expect status response $01 (not initialized)
  rts

.drive2
  cmp #$02
  bne .errout
  jsr sd2_sendcommand
  rts

.errout
  lda #$FF
  rts

; Command 8 - SEND_IF_COND / Set 3.3V I/O
cmd8
  lda #$48
  sta zp_sd_cmd_buffer+0
  lda #0
  sta zp_sd_cmd_buffer+1
  sta zp_sd_cmd_buffer+2
  lda #$01
  sta zp_sd_cmd_buffer+3
  lda #$AA
  sta zp_sd_cmd_buffer+4
  lda #$87
  sta zp_sd_cmd_buffer+5

  lda zp_sd_drive
.drive1
  cmp #$01
  bne .drive2
  jsr sd1_sendcommand

  ; Expect status response $01 (not initialized)
  cmp #$01
  bne .errout

  ; Read 32-bit return value, but ignore it
  jsr sd1_readbyte
  jsr sd1_readbyte
  jsr sd1_readbyte
  jsr sd1_readbyte

  lda #0
  rts

.drive2
  cmp #$02
  bne .errout
  jsr sd2_sendcommand

  ; Expect status response $01 (not initialized)
  cmp #$01
  bne .errout

  ; Read 32-bit return value, but ignore it
  jsr sd2_readbyte
  jsr sd2_readbyte
  jsr sd2_readbyte
  jsr sd2_readbyte

  lda #0
  rts

.errout
  lda #$FF
  rts

; Command 55 - APP_CMD
cmd55 ; APP_CMD - required prefix for ACMD commands
  lda #$77
  sta zp_sd_cmd_buffer+0
  lda #0
  sta zp_sd_cmd_buffer+1
  sta zp_sd_cmd_buffer+2
  sta zp_sd_cmd_buffer+3
  sta zp_sd_cmd_buffer+4
  lda #$01
  sta zp_sd_cmd_buffer+5

  lda zp_sd_drive
.drive1
  cmp #$01
  bne .drive2
  jsr sd1_sendcommand

  rts

.drive2
  cmp #$02
  bne .errout
  jsr sd2_sendcommand

  rts

.errout
  lda #$FF
  rts


; Command 41 - APP_SEND_OP_COND / Initialize Card
cmd41 ; APP_SEND_OP_COND - send operating conditions, initialize card
  lda #$69
  sta zp_sd_cmd_buffer+0
  lda #$40
  sta zp_sd_cmd_buffer+1
  lda #0
  sta zp_sd_cmd_buffer+2
  sta zp_sd_cmd_buffer+3
  sta zp_sd_cmd_buffer+4
  lda #$01
  sta zp_sd_cmd_buffer+5

.drive1
  cmp #$01
  bne .drive2
  jsr sd1_sendcommand
  rts

.drive2
  cmp #$02
  bne .errout
  jsr sd2_sendcommand
  rts

.errout
  lda #$FF
  rts


sd2_readbyte:
  phy
  phx

  ; Enable the card and tick the clock 8 times with MOSI high, 
  ; capturing bits from MISO and returning them

  ldx #8                      ; we'll read 8 bits
.loop:

  lda #SD2_START                ; enable card (CS low), set MOSI (resting state), SCK low
  sta SDC_ORA

  lda #SD2_START | SD2_SCK       ; toggle the clock high
  sta SDC_ORA

  lda SDC_ORA                   ; read next bit
  and #SD2_MISO

  clc                         ; default to clearing the bottom bit
  beq .bitnotset              ; unless MISO was set
  sec                         ; in which case get ready to set the bottom bit
.bitnotset:

  tya                         ; transfer partial result from Y
  rol                         ; rotate carry bit into read result
  tay                         ; save partial result back to Y

  dex                         ; decrement counter
  bne .loop                   ; loop if we need to read more bits

  plx
  ply
  rts


sd1_readbyte:
  phy
  phx

  ; Enable the card and tick the clock 8 times with MOSI high, 
  ; capturing bits from MISO and returning them

  ldx #8                      ; we'll read 8 bits
.loop:

  lda #SD1_START                ; enable card (CS low), set MOSI (resting state), SCK low
  sta SDC_ORA

  lda #SD1_START | SD2_SCK       ; toggle the clock high
  sta SDC_ORA

  lda SDC_ORA                   ; read next bit
  and #SD1_MISO

  clc                         ; default to clearing the bottom bit
  beq .bitnotset              ; unless MISO was set
  sec                         ; in which case get ready to set the bottom bit
.bitnotset:

  tya                         ; transfer partial result from Y
  rol                         ; rotate carry bit into read result
  tay                         ; save partial result back to Y

  dex                         ; decrement counter
  bne .loop                   ; loop if we need to read more bits

  plx
  ply
  rts


sd2_writebyte:
  phy
  phx

  ; Tick the clock 8 times with descending bits on MOSI
  ; SD communication is mostly half-duplex so we ignore anything it sends back here

  ldx #8                      ; send 8 bits

.loop:
  asl                         ; shift next bit into carry
  tay                         ; save remaining bits for later

  lda SDC_ORA
  bcc .sendbit0               ; if carry clear, don't set MOSI for this bit
  ora #SD2_MOSI
  jmp .sendbit

.sendbit0:
  and #SD2_nMOSI
.sendbit:
  sta SDC_ORA                   ; set MOSI (or not) first with SCK low
  eor #SD2_SCK
  sta SDC_ORA                   ; raise SCK keeping MOSI the same, to send the bit

  tya                         ; restore remaining bits to send

  dex
  bne .loop                   ; loop if there are more bits to send

  plx
  ply
  rts


sd1_writebyte:
  phy
  phx

  ; Tick the clock 8 times with descending bits on MOSI
  ; SD communication is mostly half-duplex so we ignore anything it sends back here

  ldx #8                      ; send 8 bits

.loop:
  asl                         ; shift next bit into carry
  tay                         ; save remaining bits for later

  lda SDC_ORA
  bcc .sendbit0               ; if carry clear, don't set MOSI for this bit
  ora #SD1_MOSI
  jmp .sendbit

.sendbit0:
  and #SD1_nMOSI
.sendbit:
  sta SDC_ORA                   ; set MOSI (or not) first with SCK low
  eor #SD1_SCK
  sta SDC_ORA                   ; raise SCK keeping MOSI the same, to send the bit

  tya                         ; restore remaining bits to send

  dex
  bne .loop                   ; loop if there are more bits to send

  plx
  ply
  rts


sd2_waitresult:
  ; Wait for the SD card to return something other than $ff
  jsr sd2_readbyte
  cmp #$ff
  beq sd2_waitresult
  rts

sd1_waitresult:
  ; Wait for the SD card to return something other than $ff
  jsr sd1_readbyte
  cmp #$ff
  beq sd1_waitresult
  rts

sd2_sendcommand:
  lda #SD2_START           ; pull CS low to begin command
  sta SDC_ORA

  lda zp_sd_cmd_buffer+0    ; command byte
  jsr sd2_writebyte
  lda zp_sd_cmd_buffer+1    ; data 1
  jsr sd2_writebyte
  lda zp_sd_cmd_buffer+2    ; data 2
  jsr sd2_writebyte
  lda zp_sd_cmd_buffer+3    ; data 3
  jsr sd2_writebyte
  lda zp_sd_cmd_buffer+4    ; data 4
  jsr sd2_writebyte
  lda zp_sd_cmd_buffer+5    ; crc
  jsr sd2_writebyte

  jsr sd2_waitresult
  pha

  ; End command
  lda #SD2_END
  sta SDC_ORA

  lda #SDC_OUTPUTPINS
  sta SDC_ORA

  pla   ; restore result code
  rts

sd1_sendcommand:
  lda #SD1_START           ; pull CS low to begin command
  sta SDC_ORA

  lda zp_sd_cmd_buffer+0    ; command byte
  jsr sd1_writebyte
  lda zp_sd_cmd_buffer+1    ; data 1
  jsr sd1_writebyte
  lda zp_sd_cmd_buffer+2    ; data 2
  jsr sd1_writebyte
  lda zp_sd_cmd_buffer+3    ; data 3
  jsr sd1_writebyte
  lda zp_sd_cmd_buffer+4    ; data 4
  jsr sd1_writebyte
  lda zp_sd_cmd_buffer+5    ; crc
  jsr sd1_writebyte

  jsr sd1_waitresult
  pha

  ; End command
  lda #SD1_END
  sta SDC_ORA

  lda #SDC_OUTPUTPINS
  sta SDC_ORA

  pla   ; restore result code
  rts


delay
  ldx #0
  ldy #0
.loop
  dey
  bne .loop
  dex
  bne .loop
  rts
