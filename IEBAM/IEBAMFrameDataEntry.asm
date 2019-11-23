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

EXTERNDEF IEBAMFrameDataEntries     :PROTO hIEBAM:DWORD


.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMFrameDataEntry - returns in eax pointer to frame data or NULL if not found
;------------------------------------------------------------------------------
IEBAMFrameDataEntry PROC USES EBX hIEBAM:DWORD, nFrameEntry:DWORD
    LOCAL FrameDataEntriesPtr:DWORD
    .IF hIEBAM == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEBAMFrameDataEntries, hIEBAM
    .IF eax == NULL
        ret
    .ENDIF
    mov FrameDataEntriesPtr, eax
    
    mov eax, nFrameEntry
    mov ebx, SIZEOF FRAMEDATA
    mul ebx
    add eax, FrameDataEntriesPtr
    ret
IEBAMFrameDataEntry ENDP



IEBAM_LIBEND

