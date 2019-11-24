;==============================================================================
;
; IEMOS Library
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

include IEMOS.inc

EXTERNDEF IEMOSTilePalette     :PROTO hIEMOS:DWORD, nTile:DWORD

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTilePaletteValue - Returns in eax a RGBQUAD of the specified 
; palette index of the tile palette or -1 if not valid
;------------------------------------------------------------------------------
IEMOSTilePaletteValue PROC USES EBX hIEMOS:DWORD, nTile:DWORD, PaletteIndex:DWORD
    LOCAL TilePaletteOffset:DWORD
    
    .IF hIEMOS == NULL
        mov eax, -1
        ret
    .ENDIF
    
    .IF PaletteIndex > 255
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEMOSTilePalette, hIEMOS, nTile
    .IF eax == NULL
        mov eax, -1
        ret
    .ENDIF
    mov TilePaletteOffset, eax

    mov eax, PaletteIndex
    mov ebx, 4 ; dword RGBA array size
    mul ebx
    add eax, TilePaletteOffset
    mov eax, [eax]

    ret
IEMOSTilePaletteValue ENDP



IEMOS_LIBEND

