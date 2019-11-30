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
; -1 = No PVR file, TRUE for PVRZ, FALSE for PVR3
;------------------------------------------------------------------------------
IEPVRFileCompression PROC USES EBX hIEPVR:DWORD
    .IF hIEPVR == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEPVR
    mov eax, [ebx].PVRINFO.PVRVersion
    .IF eax == 3
        mov eax, TRUE
    .ELSE
        mov eax, FALSE
    .ENDIF
    ret
IEPVRFileCompression ENDP


IEPVR_LIBEND

