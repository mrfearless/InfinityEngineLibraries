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
; IEBAMFileName - returns in eax pointer to zero terminated string contained filename that is open or NULL if not opened
;------------------------------------------------------------------------------
IEBAMFileName PROC USES EBX hIEBAM:DWORD
    LOCAL BamFilename:DWORD
    .IF hIEBAM == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEBAM
    lea eax, [ebx].BAMINFO.BAMFilename
    mov BamFilename, eax
    Invoke lstrlen, BamFilename
    .IF eax == 0
        mov eax, NULL
    .ELSE
        mov eax, BamFilename
    .ENDIF
    ret
IEBAMFileName endp



IEBAM_LIBEND

