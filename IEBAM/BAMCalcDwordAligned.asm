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

include IEBAM.inc


.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Calc dword aligned size for height or width value
;------------------------------------------------------------------------------
BAMCalcDwordAligned PROC USES ECX EDX dwWidthOrHeight:DWORD
    .IF dwWidthOrHeight == 0
        mov eax, 0
        ret
    .ENDIF
    mov eax, dwWidthOrHeight
    and eax, 1 ; ( a AND (b-1) )
    .IF eax == 0 ; if divisable by 2, use: and eax 3 - to div by 4    
        mov eax, dwWidthOrHeight
        and eax, 3 ; div by 4, get remainder
        add eax, dwWidthOrHeight
    .ELSE ; else use div to get remainder and add to dwWidthOrHeight
        xor edx, edx
        mov eax, dwWidthOrHeight
        mov ecx, 4
        div ecx ;edx contains remainder
        .IF edx != 0
            mov eax, 4
            sub eax, edx
            add eax, dwWidthOrHeight
        .ELSE
            mov eax, dwWidthOrHeight
        .ENDIF
    .ENDIF
    ; eax contains dword aligned value   
    ret

;    .IF dwWidthOrHeight == 0
;        mov eax, 0
;        ret
;    .ENDIF
;    
;    xor edx, edx
;    mov eax, dwWidthOrHeight
;    mov ecx, 4
;    div ecx ;edx contains remainder
;    .IF edx != 0
;        mov eax, 4
;        sub eax, edx
;        add eax, dwWidthOrHeight
;    .ELSE
;        mov eax, dwWidthOrHeight
;    .ENDIF
;    ; eax contains dword aligned value   
;    ret
BAMCalcDwordAligned ENDP


IEBAM_LIBEND

