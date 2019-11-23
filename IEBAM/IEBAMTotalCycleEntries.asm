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


.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMTotalCycleEntries - Returns in eax the total no of cycle entries
;------------------------------------------------------------------------------
IEBAMTotalCycleEntries PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMVersion
    .IF eax == 2 ; BAM V2
        mov ebx, [ebx].BAMINFO.BAMHeaderPtr
        .IF ebx != NULL
            mov eax, [ebx].BAMV2_HEADER.CycleEntriesCount
        .ELSE
            mov eax, 0
        .ENDIF
    .ELSE
        mov ebx, [ebx].BAMINFO.BAMHeaderPtr
        .IF ebx != NULL
            movzx eax, byte ptr [ebx].BAMV1_HEADER.CycleEntriesCount
        .ELSE
            mov eax, 0
        .ENDIF
    .ENDIF
    ret
IEBAMTotalCycleEntries ENDP



IEBAM_LIBEND

