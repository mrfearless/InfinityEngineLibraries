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
; IEMOSImageDimensions - Returns width and height in pointer to variables 
; provided
;------------------------------------------------------------------------------
IEMOSImageDimensions PROC USES EBX hIEMOS:DWORD, lpdwImageWidth:DWORD, lpdwImageHeight:DWORD
    LOCAL dwImageWidth:DWORD
    LOCAL dwImageHeight:DWORD
    
    mov dwImageWidth, 0
    mov dwImageHeight, 0
    .IF hIEMOS != NULL
        mov ebx, hIEMOS
        mov ebx, [ebx].MOSINFO.MOSHeaderPtr
        .IF ebx != NULL
            movzx eax, word ptr [ebx].MOSV1_HEADER.ImageWidth
            mov dwImageWidth, eax
            movzx eax, word ptr [ebx].MOSV1_HEADER.ImageHeight
            mov dwImageHeight, eax
        .ENDIF
    .ENDIF
    .IF lpdwImageWidth != NULL
        mov ebx, lpdwImageWidth
        mov eax, dwImageWidth
        mov [ebx], eax
    .ENDIF
    .IF lpdwImageHeight != NULL
        mov ebx, lpdwImageHeight
        mov eax, dwImageHeight
        mov [ebx], eax
    .ENDIF
    xor eax, eax
    ret
IEMOSImageDimensions ENDP



IEMOS_LIBEND

