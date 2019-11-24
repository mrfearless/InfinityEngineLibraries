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

EXTERNDEF IEMOSTileDataEntries :PROTO hIEMOS:DWORD

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileDataEntry - Returns in eax a pointer to a specific TILEDATA entry or
; NULL if not valid
;------------------------------------------------------------------------------
IEMOSTileDataEntry PROC USES EBX hIEMOS:DWORD, nTile:DWORD
    LOCAL TileDataEntries:DWORD
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
    
    Invoke IEMOSTileDataEntries, hIEMOS
    .IF eax == NULL
        ret
    .ENDIF
    .IF nTile == 0
        ; eax contains TileDataEntries which is tile 0's start
        ret
    .ENDIF    
    mov TileDataEntries, eax    
    
    mov eax, nTile
    mov ebx, SIZEOF TILEDATA
    mul ebx
    add eax, TileDataEntries    
    
    ret
IEMOSTileDataEntry ENDP



IEMOS_LIBEND

