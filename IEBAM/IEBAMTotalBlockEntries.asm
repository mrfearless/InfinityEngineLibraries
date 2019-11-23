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
; IEBAMTotalBlockEntries - Returns in eax the total no of data block entries
;------------------------------------------------------------------------------
IEBAMTotalBlockEntries PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov ebx, [ebx].BAMINFO.BAMHeaderPtr
    .IF ebx != NULL
        mov eax, [ebx].BAMV2_HEADER.BlockEntriesCount
    .ELSE
        mov eax, 0
    .ENDIF
    ret
IEBAMTotalBlockEntries ENDP



IEBAM_LIBEND

