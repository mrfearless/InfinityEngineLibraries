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


.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileLookupEntries - Returns in eax a pointer to the array of TileLookup 
; entries (DWORDs) or NULL if not valid
;------------------------------------------------------------------------------
IEMOSTileLookupEntries PROC USES EBX hIEMOS:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSTileLookupEntriesPtr
    ret
IEMOSTileLookupEntries ENDP



IEMOS_LIBEND

