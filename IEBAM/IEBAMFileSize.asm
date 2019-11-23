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
; IEBAMFileSize - returns in eax size of file or 0
;------------------------------------------------------------------------------
IEBAMFileSize PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMFilesize
    ret
IEBAMFileSize endp



IEBAM_LIBEND

