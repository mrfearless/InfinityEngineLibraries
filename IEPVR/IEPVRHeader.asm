;==============================================================================
;
; IEPVR Library
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

include IEPVR.inc


.CODE


IEPVR_ALIGN
;------------------------------------------------------------------------------
; IEPVRHeader - Returns in eax a pointer to header or NULL if not valid
;------------------------------------------------------------------------------
IEPVRHeader PROC USES EBX hIEPVR:DWORD
    .IF hIEPVR == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEPVR
    mov eax, [ebx].PVRINFO.PVRHeaderPtr
    ret
IEPVRHeader ENDP



IEPVR_LIBEND

