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
; IEBAMCycleEntries - Returns in eax a pointer to cycle entries or NULL if not valid
;------------------------------------------------------------------------------
IEBAMCycleEntries PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMCycleEntriesPtr
    ret
IEBAMCycleEntries ENDP



IEBAM_LIBEND

