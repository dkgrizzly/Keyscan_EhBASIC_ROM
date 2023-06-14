 This tree contains homebrew firmware for the Keyscan CA8400B and similar boards.
 Originally these were designed to be used as door controllers.
 After a few days of reverse engineering this firmware is the result.

 Attach a serial terminal to the Communications 1 port on the board and set it
 for 9600 baud, 8n1 RS232.  At this time the Wiegand Reader CPU must be removed
 since it will constantly reboot the 65C02 when it reaches a timeout for comms.
 You will likely need to use the system reset jumper since the Reader CPU is
 normally responsible for the Power On Reset of the 65C02.
 
 The IO CPU can stay in the board as it won't interfere with operation of this
 firmware.
 
 At some point in the future I plan to write drivers to interface with all the
 onboard hardware.

 - 32x32K paged battery backed static ram
 - DS1284 Real Time Clock
 - 40 relay outputs controlled by three 65C22 VIAs
 - 32 contact closure inputs handled by the IO PIC16F877 on the RS485 bus
 - 8 LED outputs driven by an 8-bit latch
 - 8 Wiegand inputs handled by the Reader PIC16F877
 - 2 RS232 serial ports (one onboard, one offboard)
 - RS485 serial bus

 Large portions of this firmware is based on the works of
 Lee Davidson (EhBASIC) and Daryl Rictor (VCF-MW 12 6502 Badge Software)

 Enhanced BASIC is a BASIC interpreter for the 6502 family microprocessors. It
 is constructed to be quick and powerful and easily ported between 6502 systems.
 It requires few resources to run and includes instructions to facilitate easy
 low level handling of hardware devices. It also retains most of the powerful
 high level instructions from similar BASICs.

 EhBASIC is free but not copyright free. For non commercial use there is only one
 restriction, any derivative work should include, in any binary image distributed,
 the string "Derived from EhBASIC" and in any distribution that includes human
 readable files a file that includes the above string in a human readable form
 e.g. not as a comment in an HTML file.

 For commercial use please contact Lee Davison at leeedavison@googlemail.com
 for conditions.
