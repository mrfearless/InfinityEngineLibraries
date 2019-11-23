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

EXTERNDEF IEBAMFrameLookupEntry     :PROTO hIEBAM:DWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Returns frame no for particular cycle and index into sequence or -1
;------------------------------------------------------------------------------
IEBAMFrameLookupSequence PROC USES EBX hIEBAM:DWORD, nCycle:DWORD, CycleIndex:DWORD
    LOCAL FrameLookupOffset:DWORD
    LOCAL SequenceSize:DWORD
    LOCAL SequenceData:DWORD
    LOCAL Index:DWORD
    
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEBAMFrameLookupEntry, hIEBAM, nCycle
    .IF eax == -1
        ret
    .ENDIF
    mov FrameLookupOffset, eax
    
    mov ebx, FrameLookupOffset
    mov eax, [ebx].FRAMELOOKUPTABLE.SequenceSize
    mov SequenceSize, eax
    mov eax, [ebx].FRAMELOOKUPTABLE.SequenceData
    mov SequenceData, eax
    
    .IF SequenceSize > 0
        
        mov eax, CycleIndex
        shl eax, 1 ; x2
        mov Index, eax
    
        .IF eax >= SequenceSize
            mov eax, -1
            ret
        .ENDIF
        
        .IF SequenceData != NULL
            mov ebx, SequenceData
            add ebx, Index ; for dword array 
            movzx eax, word ptr [ebx]
        .ELSE
            mov eax, -1
        .ENDIF
    .ELSE
        mov eax, -1
    .ENDIF    
    ret
IEBAMFrameLookupSequence endp



IEBAM_LIBEND

