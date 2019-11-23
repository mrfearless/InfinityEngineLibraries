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
; Convert to RGBQUAD (BGRA) format from RGB ColorRef (ARGB)
;------------------------------------------------------------------------------
IEBAMConvertARGBtoABGR PROC USES EBX dwARGB:DWORD
    LOCAL clrRed:DWORD
    LOCAL clrGreen:DWORD
    LOCAL clrBlue:DWORD
    LOCAL clrAlpha:DWORD
    
    xor eax, eax
    mov eax, dwARGB

    xor ebx, ebx
    mov bl, al
    mov clrRed, ebx
    xor ebx, ebx
    mov bl, ah
    mov clrGreen, ebx

    shr eax, 16d

    xor ebx, ebx
    mov bl, al
    mov clrBlue, ebx
    xor ebx, ebx
    mov bl, ah
    mov clrAlpha, ebx

    xor eax, eax
    xor ebx, ebx
    mov eax, clrAlpha
    mov ebx, clrRed
    shl eax, 8d
    mov al, bl
    shl eax, 16d ; alpha and red in upper dword
    mov ebx, clrGreen
    mov ah, bl
    mov ebx, clrBlue
    mov al, bl
    ; eax contains BGRA - RGBQUAD
    ret
IEBAMConvertARGBtoABGR ENDP



IEBAM_LIBEND

