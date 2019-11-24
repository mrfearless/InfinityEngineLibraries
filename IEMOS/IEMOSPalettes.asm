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


.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSPalettes - Returns in eax a pointer to the palettes or NULL if not valid
;------------------------------------------------------------------------------
IEMOSPalettes PROC USES EBX hIEMOS:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSPaletteEntriesPtr
    ret
IEMOSPalettes ENDP



IEMOS_LIBEND

