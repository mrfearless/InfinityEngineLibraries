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

EXTERNDEF IEBAMTotalCycleEntries    :PROTO hIEBAM:DWORD
EXTERNDEF IEBAMFrameLookupEntries   :PROTO hIEBAM:DWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMFrameLookupEntry - Returns in eax a pointer to the frame lookup NULL if not valid
;------------------------------------------------------------------------------
IEBAMFrameLookupEntry PROC USES EBX hIEBAM:DWORD, nCycle:DWORD
    LOCAL FrameLookupEntries:DWORD
    LOCAL TotalCycleEntries:DWORD
    
    .IF hIEBAM == NULL
        mov eax, NULL
        ret
    .ENDIF

    Invoke IEBAMTotalCycleEntries, hIEBAM
    .IF eax == 0
        mov eax, NULL
        ret
    .ENDIF   
    mov TotalCycleEntries, eax
   
    Invoke IEBAMFrameLookupEntries, hIEBAM
    .IF eax == NULL
        ret
    .ENDIF
    mov FrameLookupEntries, eax  

    mov eax, nCycle
    mov ebx, SIZEOF FRAMELOOKUPTABLE
    mul ebx
    add eax, FrameLookupEntries
    ret
IEBAMFrameLookupEntry ENDP



IEBAM_LIBEND

