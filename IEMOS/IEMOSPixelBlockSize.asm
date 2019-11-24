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
; IEMOSPixelBlockSize - Returns size of pixels used in each block
;------------------------------------------------------------------------------
IEMOSPixelBlockSize PROC USES EBX hIEMOS:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEMOS
    mov ebx, [ebx].MOSINFO.MOSHeaderPtr
    .IF ebx != NULL
        movzx eax, word ptr [ebx].MOSV1_HEADER.BlockSize
    .ELSE
        mov eax, 0
    .ENDIF
    ret
IEMOSPixelBlockSize ENDP



IEMOS_LIBEND

