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

EXTERNDEF IEBAMPalette  :PROTO hIEBAM:DWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Returns in eax pointer to palette RGBAQUAD entry, or NULL otherwise
;------------------------------------------------------------------------------
IEBAMPaletteEntry PROC USES EBX hIEBAM:DWORD, PaletteIndex:DWORD
    LOCAL PaletteOffset:DWORD

    .IF hIEBAM == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    .IF PaletteIndex > 255
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEBAMPalette, hIEBAM
    .IF eax == NULL
        ret
    .ENDIF
    mov PaletteOffset, eax
    
    mov eax, PaletteIndex
    mov ebx, 4 ; dword RGBA array size
    mul ebx
    add eax, PaletteOffset
    ret
IEBAMPaletteEntry endp



IEBAM_LIBEND

