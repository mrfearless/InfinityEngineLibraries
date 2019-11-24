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

EXTERNDEF IEMOSTileLookupEntries :PROTO hIEMOS:DWORD

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileLookupEntry - Returns in eax a pointer to specific TileLookup entry
; which if read (DWORD) is an offset to the Tile Data from start of tile pixel 
; data.
;------------------------------------------------------------------------------
IEMOSTileLookupEntry PROC USES EBX hIEMOS:DWORD, nTile:DWORD
    LOCAL TileLookupEntries:DWORD
    
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
    
    Invoke IEMOSTileLookupEntries, hIEMOS
    .IF eax == NULL
        ret
    .ENDIF
    .IF nTile == 0
        ; eax contains TileLookupEntries which is tile 0's start
        ret
    .ENDIF    
    mov TileLookupEntries, eax
    
    mov eax, nTile
    mov ebx, SIZEOF DWORD
    mul ebx
    add eax, TileLookupEntries
    
    ret
IEMOSTileLookupEntry ENDP



IEMOS_LIBEND

