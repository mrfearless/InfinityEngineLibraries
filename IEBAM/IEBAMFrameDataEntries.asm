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
; IEBAMFrameDataEntries - Returns in eax a pointer to the framedata entries or NULL if not valid
;------------------------------------------------------------------------------
IEBAMFrameDataEntries PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMFrameDataEntriesPtr
    ret
IEBAMFrameDataEntries ENDP



IEBAM_LIBEND

