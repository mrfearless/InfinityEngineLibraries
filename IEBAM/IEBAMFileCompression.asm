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
; -1 = No Bam file, TRUE for BAMCV1, FALSE for BAM V1 or BAM V2 
;------------------------------------------------------------------------------
IEBAMFileCompression PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMVersion
    .IF eax == 3
        mov eax, TRUE
    .ELSE
        mov eax, FALSE
    .ENDIF
    ret
IEBAMFileCompression ENDP



IEBAM_LIBEND

