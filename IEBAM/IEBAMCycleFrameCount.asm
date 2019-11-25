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

EXTERNDEF IEBAMCycleEntry   :PROTO hIEBAM:DWORD, nCycleEntry:DWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Returns count of frames in particular cycle or 0
;------------------------------------------------------------------------------
IEBAMCycleFrameCount PROC USES EBX hIEBAM:DWORD, nCycle:DWORD
    .IF hIEBAM == NULL
        mov eax, 0
        ret
    .ENDIF
    
    Invoke IEBAMCycleEntry, hIEBAM, nCycle
    .IF eax == 0
        ret
    .ENDIF
    mov ebx, eax
    movzx eax, word ptr [ebx].CYCLEV1_ENTRY.CycleFrameCount
    ret
IEBAMCycleFrameCount ENDP



IEBAM_LIBEND

