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
; IEMOSTotalBlockEntries - Returns in eax the total no of data block entries
;------------------------------------------------------------------------------
IEMOSTotalBlockEntries PROC USES EBX hIEMOS:DWORD
    .IF hIEMOS == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEMOS
    mov ebx, [ebx].MOSINFO.MOSHeaderPtr
    mov eax, [ebx].MOSV2_HEADER.BlockEntriesCount
    ret
IEMOSTotalBlockEntries ENDP



IEMOS_LIBEND

