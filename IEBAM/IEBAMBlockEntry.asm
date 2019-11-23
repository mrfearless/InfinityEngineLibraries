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

EXTERNDEF IEBAMTotalBlockEntries    :PROTO hIEBAM:DWORD
EXTERNDEF IEBAMBlockEntries         :PROTO hIEBAM:DWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMBlockEntry - Returns in eax a pointer to the specified Datablock entry or NULL 
;------------------------------------------------------------------------------
IEBAMBlockEntry PROC USES EBX hIEBAM:DWORD, nBlockEntry:DWORD
    LOCAL TotalBlockEntries:DWORD
    LOCAL BlockEntriesPtr:DWORD
    
    .IF hIEBAM == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEBAMTotalBlockEntries, hIEBAM
    .IF eax == 0
        mov eax, NULL
        ret
    .ENDIF    
    mov TotalBlockEntries, eax
    
    .IF nBlockEntry >= eax
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEBAMBlockEntries, hIEBAM
    .IF eax == NULL
        ret
    .ENDIF    
    mov BlockEntriesPtr, eax    
    
    mov eax, nBlockEntry
    mov ebx, SIZEOF DATABLOCK_ENTRY
    mul ebx
    add eax, BlockEntriesPtr
    ret
IEBAMBlockEntry ENDP



IEBAM_LIBEND

