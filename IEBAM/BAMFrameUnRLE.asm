;==============================================================================
;
; IEBAM Library
;
; Copyright (c) 2019 by fearless
;
; http://github.com/mrfearless/InfinityEngineLibraries
;
;==============================================================================
.686
.MMX
.XMM
.model flat,stdcall
option casemap:none

include windows.inc

;DEBUG32 EQU 1
;IFDEF DEBUG32
;    PRESERVEXMMREGS equ 1
;    includelib M:\Masm32\lib\Debug32.lib
;    DBG32LIB equ 1
;    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
;    include M:\Masm32\include\debug32.inc
;ENDIF

include IEBAM.inc


.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Unroll RLE compressed bam frame to RAW data. Returns Frame Size or NULL
;------------------------------------------------------------------------------
BAMFrameUnRLE PROC USES ECX EDI ESI pFrameRLE:DWORD, FrameRLESize:DWORD, pFrameRAW:DWORD, FrameRAWSize:DWORD
    LOCAL RLECurrentPos:DWORD
    LOCAL RAWCurrentPos:DWORD
    LOCAL ZeroCount:DWORD
    LOCAL ZeroTotal:DWORD
    LOCAL FrameSize:DWORD

    .IF pFrameRLE == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    .IF pFrameRAW == NULL
        mov eax, NULL
        ret
    .ENDIF

    mov RLECurrentPos, 0
    mov RAWCurrentPos, 0
    mov FrameSize, 0
    
    mov eax, 0
    .WHILE eax < FrameRLESize
        mov esi, pFrameRLE
        add esi, RLECurrentPos
        
        movzx eax, byte ptr [esi]
        .IF al == 0h
            mov ecx, RLECurrentPos ; check not at end for next char
            inc ecx
            .IF ecx < FrameRLESize
                inc esi
                movzx eax, byte ptr [esi] ; al contains amount of 0's to copy
                inc eax ; for +1 count
                mov ZeroTotal, eax
                mov ZeroCount, 0
                mov eax, 0
                mov edi, pFrameRAW
                add edi, RAWCurrentPos
                .WHILE eax < ZeroTotal
                    mov byte ptr [edi], 0h
                    inc edi
                    inc RAWCurrentPos
                    
                    ; check frame size
                    mov eax, FrameSize
                    inc eax
                    .IF eax > FrameRAWSize
                        .BREAK
                    .ENDIF
                    
                    inc FrameSize
                    inc ZeroCount
                    mov eax, ZeroCount
                .ENDW
                
                ; check frame size
                mov eax, FrameSize
                inc eax
                .IF eax > FrameRAWSize
                    .BREAK
                .ENDIF
                inc RLECurrentPos
                inc RLECurrentPos

            .ELSE ; if this char is the last one and we have a 0 then just copy it
                mov edi, pFrameRAW
                add edi, RAWCurrentPos
                mov byte ptr [edi], al
                inc RAWCurrentPos
                inc FrameSize
                inc RLECurrentPos
            .ENDIF
        .ELSE
            mov edi, pFrameRAW
            add edi, RAWCurrentPos
            mov byte ptr [edi], al
            inc RAWCurrentPos
            inc FrameSize
            inc RLECurrentPos
        .ENDIF
    
        mov eax, RLECurrentPos
    .ENDW

    mov eax, FrameSize
    ret
BAMFrameUnRLE ENDP


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Check the size of the Unroll RLE compressed bam frame. Returns RAW Frame Size
;------------------------------------------------------------------------------
BAMFrameUnRLESize PROC USES ECX ESI pFrameRLE:DWORD, FrameRLESize:DWORD
    LOCAL RLECurrentPos:DWORD
    LOCAL ZeroCount:DWORD
    LOCAL ZeroTotal:DWORD
    LOCAL FrameSize:DWORD

    .IF pFrameRLE == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    mov RLECurrentPos, 0
    mov FrameSize, 0
    
    mov eax, 0
    .WHILE eax < FrameRLESize
        mov esi, pFrameRLE
        add esi, RLECurrentPos
        
        movzx eax, byte ptr [esi]
        .IF al == 0h
            mov ecx, RLECurrentPos ; check not at end for next char
            inc ecx
            .IF ecx < FrameRLESize
                inc esi
                movzx eax, byte ptr [esi] ; al contains amount of 0's to copy
                inc eax ; for +1 count
                mov ZeroTotal, eax
                mov ZeroCount, 0
                mov eax, 0

                .WHILE eax < ZeroTotal
                    inc FrameSize
                    inc ZeroCount
                    mov eax, ZeroCount
                .ENDW
                inc RLECurrentPos
                inc RLECurrentPos

            .ELSE ; if this char is the last one and we have a 0 then just copy it
                inc FrameSize
                inc RLECurrentPos
            .ENDIF
        .ELSE
            inc FrameSize
            inc RLECurrentPos
        .ENDIF
    
        mov eax, RLECurrentPos
    .ENDW

    mov eax, FrameSize
    ret
BAMFrameUnRLESize ENDP




IEBAM_LIBEND

