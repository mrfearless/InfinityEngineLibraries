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
; IEBAMFrameLookupEntries - Returns in eax a pointer to the frame lookup indexes or NULL if not valid
;------------------------------------------------------------------------------
IEBAMFrameLookupEntries PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMFrameLookupPtr
    ret
IEBAMFrameLookupEntries ENDP



IEBAM_LIBEND

