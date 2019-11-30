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

include IEPVR.inc


.CODE


IEPVR_ALIGN
;------------------------------------------------------------------------------
; Returns in eax size of file or 0
;------------------------------------------------------------------------------
IEPVRFileSize PROC USES EBX hIEPVR:DWORD
    .IF hIEPVR == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEPVR
    mov eax, [ebx].PVRINFO.PVRFilesize
    ret
IEPVRFileSize ENDP


IEPVR_LIBEND

