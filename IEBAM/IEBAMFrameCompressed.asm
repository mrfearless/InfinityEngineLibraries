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
; Returns 0 for compressed, 1 for uncompressed or -1 if invalid
;------------------------------------------------------------------------------
IEBAMFrameCompressed PROC USES EBX hIEBAM:DWORD, nFrame:DWORD
    LOCAL FrameDataEntry:DWORD
    
    .IF hIEBAM == NULL
        mov eax, FALSE
        ret
    .ENDIF

    Invoke IEBAMFrameDataEntry, hIEBAM, nFrame
    .IF eax == NULL
        mov eax, -1
        ret
    .ENDIF
    mov FrameDataEntry, eax
    
    mov ebx, FrameDataEntry
    mov eax, [ebx].FRAMEDATA.FrameCompressed
    ret
IEBAMFrameCompressed ENDP


IEBAM_LIBEND

