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
include user32.inc
include kernel32.inc

includelib user32.lib
includelib kernel32.lib

include IEBAM.inc


.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMFrameEntries - Returns in eax a pointer to frame entries or NULL if not valid
;------------------------------------------------------------------------------
IEBAMFrameEntries PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMFrameEntriesPtr
    ret
IEBAMFrameEntries ENDP



IEBAM_LIBEND

