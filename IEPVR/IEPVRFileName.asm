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
; Returns in eax pointer to zero terminated string contained filename that is 
; open or NULL if not opened
;------------------------------------------------------------------------------
IEPVRFileName PROC USES EBX hIEPVR:DWORD
    LOCAL PvrFilename:DWORD
    .IF hIEPVR == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEPVR
    lea eax, [ebx].PVRINFO.PVRFilename
    mov PvrFilename, eax
    Invoke lstrlen, PvrFilename
    .IF eax == 0
        mov eax, NULL
    .ELSE
        mov eax, PvrFilename
    .ENDIF
    ret
IEPVRFileName ENDP


IEPVR_LIBEND

