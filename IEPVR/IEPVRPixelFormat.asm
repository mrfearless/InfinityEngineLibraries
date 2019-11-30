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
; Returns pixel format defined by constants in PVR Pixel Format or -1 if error
;------------------------------------------------------------------------------
IEPVRPixelFormat PROC USES EBX hIEPVR:DWORD
    LOCAL PVRHeaderPtr:DWORD
    
    .IF hIEPVR == NULL
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEPVRHeader, hIEPVR
    .IF eax == NULL
        ret
    .ENDIF
    mov PVRHeaderPtr, eax
    mov ebx, PVRHeaderPtr
    
    mov eax, dword ptr [ebx].PVR3_HEADER.PixelFormat
    ret
IEPVRPixelFormat ENDP


IEPVR_LIBEND

