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

EXTERNDEF IEMOSTileDataEntry    :PROTO hIEMOS:DWORD, nTile:DWORD

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileRAW - Returns in eax pointer to RAW tile data.
;------------------------------------------------------------------------------
IEMOSTileRAW PROC USES EBX hIEMOS:DWORD, nTile:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF    

    Invoke IEMOSTileDataEntry, hIEMOS, nTile
    .IF eax == NULL
        ret
    .ENDIF
    mov ebx, eax
    mov eax, [ebx].TILEDATA.TileRAW
    ret
IEMOSTileRAW ENDP



IEMOS_LIBEND
