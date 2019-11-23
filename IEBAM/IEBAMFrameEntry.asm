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

EXTERNDEF IEBAMTotalFrameEntries    :PROTO hIEBAM:DWORD
EXTERNDEF IEBAMFrameEntries         :PROTO hIEBAM:DWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMFrameEntry - Returns in eax a pointer to the specified frame entry or NULL
;------------------------------------------------------------------------------
IEBAMFrameEntry PROC USES EBX hIEBAM:DWORD, nFrameEntry:DWORD
    LOCAL TotalFrameEntries:DWORD
    LOCAL FrameEntriesPtr:DWORD
    
    .IF hIEBAM == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEBAMTotalFrameEntries, hIEBAM
    .IF eax == 0
        mov eax, NULL
        ret
    .ENDIF    
    mov TotalFrameEntries, eax

    .IF nFrameEntry >= eax
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEBAMFrameEntries, hIEBAM
    .IF eax == NULL
        ret
    .ENDIF
    mov FrameEntriesPtr, eax
    
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMVersion
    .IF eax == 2 ; BAM V2
        mov eax, nFrameEntry
        mov ebx, SIZEOF FRAMEV2_ENTRY
    .ELSE
        mov eax, nFrameEntry
        mov ebx, SIZEOF FRAMEV1_ENTRY
    .ENDIF
    mul ebx
    add eax, FrameEntriesPtr
    
    ret
IEBAMFrameEntry ENDP



IEBAM_LIBEND

