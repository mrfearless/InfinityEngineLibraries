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

EXTERNDEF IEMOSPalettes     :PROTO hIEMOS:DWORD

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTilePalette - Returns in eax a pointer to the tile palette or NULL if 
; not valid
;------------------------------------------------------------------------------
IEMOSTilePalette PROC USES EBX hIEMOS:DWORD, nTile:DWORD
    LOCAL PaletteOffset:DWORD

    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSTotalTiles
    .IF nTile >= eax ; 0 based tile index
        mov eax, NULL
        ret
    .ENDIF

    Invoke IEMOSPalettes, hIEMOS
    .IF eax == NULL
        ret
    .ENDIF
    .IF nTile == 0
        ; eax contains PaletteOffset which is tile 0's palette start
        ret
    .ENDIF
    mov PaletteOffset, eax    
    
    mov eax, nTile
    mov ebx, 1024 ;(256 * SIZEOF DWORD)
    mul ebx
    add eax, PaletteOffset
    
    ret
IEMOSTilePalette ENDP



IEMOS_LIBEND

