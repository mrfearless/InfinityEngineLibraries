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

EXTERNDEF IEBAMHeader               :PROTO hIEBAM:DWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Returns in eax the RLEColorIndex
;------------------------------------------------------------------------------
IEBAMRLEColorIndex PROC USES EBX hIEBAM:DWORD
    LOCAL BamHeaderPtr:DWORD
    LOCAL RLEColorIndex:DWORD
    LOCAL ABGR:DWORD
    
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEBAMHeader, hIEBAM
    .IF eax == NULL
        mov eax, -1
        ret
    .ENDIF
    mov BamHeaderPtr, eax
    mov ebx, BamHeaderPtr
    movzx eax, byte ptr [ebx].BAMV1_HEADER.ColorIndexRLE
    
    ret
IEBAMRLEColorIndex ENDP


IEBAM_LIBEND

