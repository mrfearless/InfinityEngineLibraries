;==============================================================================
;
; IEMOS Library
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

include IEMOS.inc

EXTERNDEF IEMOSTotalBlockEntries    :PROTO hIEMOS:DWORD
EXTERNDEF IEMOSBlockEntries         :PROTO hIEMOS:DWORD

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSBlockEntry - Returns in eax a pointer to the specified Datablock entry 
; or NULL
;------------------------------------------------------------------------------
IEMOSBlockEntry PROC USES EBX hIEMOS:DWORD, nBlockEntry:DWORD
    LOCAL BlockEntriesPtr:DWORD
    
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEMOSTotalBlockEntries, hIEMOS
    .IF eax == 0
        mov eax, NULL
        ret
    .ENDIF
    ; eax contains TotalBlockEntries
     .IF nBlockEntry >= eax
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEMOSBlockEntries, hIEMOS
    .IF eax == NULL
        ret
    .ENDIF
    mov BlockEntriesPtr, eax
    
    mov eax, nBlockEntry
    mov ebx, SIZEOF DATABLOCK_ENTRY
    mul ebx
    add eax, BlockEntriesPtr
    ret
IEMOSBlockEntry ENDP



IEMOS_LIBEND

