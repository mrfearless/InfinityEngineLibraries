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
; Convert to RGB ColorRef (ARGB) format from RGBQUAD (BGRA) Returns Alpha as well
; to mask off use AND, 00FFFFFFh for just RGB.
;------------------------------------------------------------------------------
IEBAMConvertABGRtoARGB PROC USES EBX dwBGRA:DWORD
    LOCAL clrRed:DWORD
    LOCAL clrGreen:DWORD
    LOCAL clrBlue:DWORD
    LOCAL clrAlpha:DWORD
    
    xor eax, eax
    mov eax, dwBGRA ; stored in reverse format ARGB in memory

    xor ebx, ebx
    mov bl, al
    mov clrBlue, ebx
    xor ebx, ebx
    mov bl, ah
    mov clrGreen, ebx

    shr eax, 16d

    xor ebx, ebx
    mov bl, al
    mov clrRed, ebx
    xor ebx, ebx
    mov bl, ah
    mov clrAlpha, ebx

    xor eax, eax
    xor ebx, ebx
    mov eax, clrAlpha
    mov ebx, clrBlue
    shl eax, 8d
    mov al, bl
    shl eax, 16d ; alpha and red in upper dword
    mov ebx, clrGreen
    mov ah, bl
    mov ebx, clrRed
    mov al, bl
    ; eax contains ARGB
    ret
IEBAMConvertABGRtoARGB ENDP


IEBAM_LIBEND

