; ==============================================================================
; YAMAHA DX9/7 FIRMWARE
; Copyright (C) 2022 AJXS (https://ajxs.me/)
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; ==============================================================================
; pedals.asm
; ==============================================================================
; DESCRIPTION:
; This file contains the definitions, and code related to scanning the synth's
; peripheral pedals.
; ==============================================================================

    .PROCESSOR HD6303

; ==============================================================================
; Pedal Constants.
; These bitmasks are used to mask the pedal status byte to check the status of
; individual pedals.
; ==============================================================================
PEDAL_INPUT_PORTA:                              EQU 1 << 6
PEDAL_INPUT_SUSTAIN:                            EQU 1 << 7

; ==============================================================================
; PEDALS_UPDATE
; ==============================================================================
; @TAKEN_FROM_DX9_FIRMWARE
; DESCRIPTION:
; Updates the status of whether the synth's sustain, and portamento pedals are
; currently being pressed.
; This routine returns an integer indicating which pedal's status has changed.
;
; MEMORY MODIFIED:
; * pedal_status_current
;
; REGISTERS MODIFIED:
; * ACCA, ACCB
;
; RETURNS:
; * ACCB: An integer indicating the status of the peripherals.
;         0 = No pedals active.
;         1 = Sustain active.
;         2 = Portamento active.
;
; ==============================================================================
pedals_update:                                  SUBROUTINE
    LDAB    <io_port_1_data
    ANDB    #%11110000
    ORAB    #KEY_SWITCH_SCAN_DRIVER_SOURCE_PEDALS

; Update the key/switch scan driver source, delay, and then read the input.
    STAB    <io_port_1_data
    DELAY_SINGLE
    LDAA    <key_switch_scan_driver_input
    ANDA    #%11000000

; Store the updated pedal state in ACCB.
    TAB

; Test whether the pedal input has changed since the last time it was read.
    EORA    <pedal_status_previous
; If the result of the XOR is zero, nothing has changed. In this case
; exit returning zero.
    BEQ     .exit_input_unchanged

; If bit 7 of the result is not set, it indicates that the sustain input
; status has not changed since the previous read.
    BPL     .portamento_pedal_updated

; If this point has been reached it means that the sustain pedal input has
; been changed.
; Use XOR to update the PREVIOUS pedal state to match the NEW updated
; sustain pedal state.
    EIMD     #PEDAL_INPUT_SUSTAIN, pedal_status_previous

; Load the CURRENT state, mask the portamento, and sustain status bits,
; then add the UPDATED state byte to update the current state.
    LDAA    <pedal_status_current
    ANDA    #PEDAL_INPUT_PORTA
    ANDB    #PEDAL_INPUT_SUSTAIN
    ABA
    STAA    <pedal_status_current

; Send a MIDI message with the updated sustain pedal status, set the result
; value, and return.
    JSR     midi_tx_pedal_status_sustain
    LDAB    #1
    RTS

.portamento_pedal_updated:
; Use XOR to update the PREVIOUS pedal state to match the NEW updated
; portamento pedal state.
    EIMD     #PEDAL_INPUT_PORTA, pedal_status_previous

; Load the CURRENT state, mask the portamento, and sustain status bits,
; then add the UPDATED state byte to update the current state.
    LDAA    <pedal_status_current
    ANDA    #PEDAL_INPUT_SUSTAIN
    ANDB    #PEDAL_INPUT_PORTA
    ABA
    STAA    <pedal_status_current

; Send a MIDI message with the updated portamento pedal status, set the result
; value, and return.
    JSR     midi_tx_pedal_status_portamento
    LDAB    #2
    RTS

.exit_input_unchanged:
    CLRB
    RTS
