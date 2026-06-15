.MODEL SMALL
.STACK 100H

.DATA
    msg1 DB 'Enter UTC Hours (0-23): $'
    msg2 DB 0DH,0AH,'Enter Minutes (0-59): $'
    msg3 DB 0DH,0AH,'Enter Seconds (0-59): $'
    
    utc_label DB 'UTC (North Pole): $'
    pak_label DB 'Pakistan (UTC+5): $'
    usa_label DB 'USA (UTC-5):      $'
    
    ; Pre-formatted time strings (ready to display)
    utc_time DB '00:00:00$'     ; UTC time string
    pak_time DB '00:00:00$'     ; Pakistan time string
    usa_time DB '00:00:00$'     ; USA time string
    
    ; Current time values
    hours DB 0
    minutes DB 0
    seconds DB 0

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    
    CALL GET_TIME           ; Get initial time
    CALL CLEAR_SCREEN       ; Clear screen once
    
    ; Display labels (only once)
    MOV AH, 02H
    MOV BH, 0
    MOV DH, 5
    MOV DL, 10
    INT 10H
    LEA DX, utc_label
    MOV AH, 09H
    INT 21H
    
    MOV AH, 02H
    MOV DH, 7
    MOV DL, 10
    INT 10H
    LEA DX, pak_label
    MOV AH, 09H
    INT 21H
    
    MOV AH, 02H
    MOV DH, 9
    MOV DL, 10
    INT 10H
    LEA DX, usa_label
    MOV AH, 09H
    INT 21H
    
CLOCK_LOOP:
    CALL PREPARE_ALL_TIMES      ; Prepare all strings in memory
    CALL DISPLAY_ALL_FAST       ; Display all at once
    CALL DELAY_ONE_SEC          ; Wait 1 second
    CALL TICK                   ; Update time
    JMP CLOCK_LOOP
    
MAIN ENDP

; Get time from user
GET_TIME PROC
    LEA DX, msg1
    MOV AH, 09H
    INT 21H
    CALL READ_NUM
    MOV hours, AL
    
    LEA DX, msg2
    MOV AH, 09H
    INT 21H
    CALL READ_NUM
    MOV minutes, AL
    
    LEA DX, msg3
    MOV AH, 09H
    INT 21H
    CALL READ_NUM
    MOV seconds, AL
    RET
GET_TIME ENDP

; Read 2-digit number
READ_NUM PROC
    MOV AH, 01H
    INT 21H
    SUB AL, 30H
    MOV BL, AL
    
    MOV AH, 01H
    INT 21H
    SUB AL, 30H
    MOV CL, AL
    
    MOV AL, BL
    MOV BL, 10
    MUL BL
    ADD AL, CL
    RET
READ_NUM ENDP

; Prepare all time strings in memory (ALL AT ONCE)
PREPARE_ALL_TIMES PROC
    ; Prepare UTC time string
    MOV AL, hours
    LEA SI, utc_time
    CALL FORMAT_TIME_STRING
    
    ; Prepare Pakistan time string (UTC + 5)
    MOV AL, hours
    ADD AL, 5
    CMP AL, 24
    JL PAK_OK
    SUB AL, 24
PAK_OK:
    LEA SI, pak_time
    CALL FORMAT_TIME_STRING
    
    ; Prepare USA time string (UTC - 5)
    MOV AL, hours
    CMP AL, 5
    JGE USA_SUB
    ADD AL, 24
USA_SUB:
    SUB AL, 5
    LEA SI, usa_time
    CALL FORMAT_TIME_STRING
    
    RET
PREPARE_ALL_TIMES ENDP

; Format time into string at SI (HH:MM:SS)
; Input: AL = hours, SI = pointer to string
FORMAT_TIME_STRING PROC
    PUSH AX
    PUSH SI
    
    ; Convert hours to 2 digits
    MOV AH, 0
    MOV BL, 10
    DIV BL                  ; AL = tens, AH = ones
    
    ADD AL, 30H             ; Convert to ASCII
    MOV [SI], AL            ; First digit
    INC SI
    
    MOV AL, AH
    ADD AL, 30H
    MOV [SI], AL            ; Second digit
    INC SI
    
    INC SI                  ; Skip colon
    
    ; Convert minutes to 2 digits
    MOV AL, minutes
    MOV AH, 0
    DIV BL
    
    ADD AL, 30H
    MOV [SI], AL
    INC SI
    
    MOV AL, AH
    ADD AL, 30H
    MOV [SI], AL
    INC SI
    
    INC SI                  ; Skip colon
    
    ; Convert seconds to 2 digits
    MOV AL, seconds
    MOV AH, 0
    DIV BL
    
    ADD AL, 30H
    MOV [SI], AL
    INC SI
    
    MOV AL, AH
    ADD AL, 30H
    MOV [SI], AL
    
    POP SI
    POP AX
    RET
FORMAT_TIME_STRING ENDP

; Display all pre-formatted times (SUPER FAST)
DISPLAY_ALL_FAST PROC
    ; Display UTC (already formatted)
    MOV AH, 02H
    MOV BH, 0
    MOV DH, 5
    MOV DL, 30
    INT 10H
    LEA DX, utc_time
    MOV AH, 09H
    INT 21H
    
    ; Display Pakistan (already formatted)
    MOV AH, 02H
    MOV DH, 7
    MOV DL, 30
    INT 10H
    LEA DX, pak_time
    MOV AH, 09H
    INT 21H
    
    ; Display USA (already formatted)
    MOV AH, 02H
    MOV DH, 9
    MOV DL, 30
    INT 10H
    LEA DX, usa_time
    MOV AH, 09H
    INT 21H
    
    RET
DISPLAY_ALL_FAST ENDP

; Update time by 1 second
TICK PROC
    INC seconds
    CMP seconds, 60
    JL TICK_DONE          ; If seconds < 60, we're done
    
    MOV seconds, 0        ; Reset seconds to 0
    INC minutes           ; Increment minutes
    
    CMP minutes, 60
    JL TICK_DONE          ; If minutes < 60, we're done
    
    MOV minutes, 0        ; Reset minutes to 0
    INC hours             ; Increment hours
    
    CMP hours, 24
    JL TICK_DONE          ; If hours < 24, we're done
    
    MOV hours, 0          ; Reset hours to 0
    
TICK_DONE:
    RET
TICK ENDP

; Delay for 1 second
DELAY_ONE_SEC PROC
    PUSH CX
    PUSH DX
    PUSH BX
    
    MOV AH, 86H
    MOV CX, 0FH
    MOV DX, 4240H
    INT 15H
    
    POP BX
    POP DX
    POP CX
    RET
DELAY_ONE_SEC ENDP

; Clear screen
CLEAR_SCREEN PROC
    MOV AH, 00H
    MOV AL, 03H
    INT 10H
    RET
CLEAR_SCREEN ENDP

END MAIN