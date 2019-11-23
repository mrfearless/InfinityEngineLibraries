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
; IEBAMTotalFrameEntries - Returns in eax the total no of frame entries
;------------------------------------------------------------------------------
IEBAMTotalFrameEntries PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMVersion
    .IF eax == 2 ; BAM V2
        mov ebx, [ebx].BAMINFO.BAMHeaderPtr
        .IF ebx != NULL
            mov eax, [ebx].BAMV2_HEADER.FrameEntriesCount
        .ELSE
            mov eax, 0
        .ENDIF
    .ELSE
        mov ebx, [ebx].BAMINFO.BAMHeaderPtr
        .IF ebx != NULL
            movzx eax, word ptr [ebx].BAMV1_HEADER.FrameEntriesCount
        .ELSE
            mov eax, 0
        .ENDIF
    .ENDIF
    ret
IEBAMTotalFrameEntries ENDP



IEBAM_LIBEND

