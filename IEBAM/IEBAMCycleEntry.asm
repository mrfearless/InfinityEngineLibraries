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
EXTERNDEF IEBAMCycleEntries         :PROTO hIEBAM:DWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMCycleEntry - Returns in eax a pointer to the specified cycle entry or NULL 
;------------------------------------------------------------------------------
IEBAMCycleEntry PROC USES EBX hIEBAM:DWORD, nCycleEntry:DWORD
    LOCAL TotalCycleEntries:DWORD
    LOCAL CycleEntriesPtr:DWORD
    
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

    .IF nCycleEntry >= eax
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEBAMCycleEntries, hIEBAM
    .IF eax == NULL
        ret
    .ENDIF    
    mov CycleEntriesPtr, eax
    
    mov eax, nCycleEntry
    mov ebx, SIZEOF CYCLEV1_ENTRY
    mul ebx
    add eax, CycleEntriesPtr
    ret
IEBAMCycleEntry ENDP



IEBAM_LIBEND

