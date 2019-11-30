;==============================================================================
;
; IEPVR Library
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

include IEPVR.inc

EXTERNDEF IEPVRHeader :PROTO hIEPVR:DWORD

.CODE


IEPVR_ALIGN
;------------------------------------------------------------------------------
; Returns in eax TRUE if sucessful or FALSE otherwise. On return lpdwImageWidth and 
; lpdwImageHeight will contain the values
;------------------------------------------------------------------------------
IEPVRTextureDimensions PROC USES EBX hIEPVR:DWORD, lpdwImageWidth:DWORD, lpdwImageHeight:DWORD
    LOCAL PVRHeaderPtr:DWORD
    LOCAL ImageWidth:DWORD
    LOCAL ImageHeight:DWORD
    
    .IF hIEPVR == NULL
        mov eax, FALSE
        ret
    .ENDIF
    
    Invoke IEPVRHeader, hIEPVR
    .IF eax == NULL
        ret
    .ENDIF
    mov PVRHeaderPtr, eax
    mov ebx, PVRHeaderPtr
    
    mov eax, dword ptr [ebx].PVR3_HEADER.ImageHeight
    mov ImageHeight, eax
    mov eax, dword ptr [ebx].PVR3_HEADER.ImageWidth
    mov ImageWidth, eax
    
    .IF lpdwImageWidth != NULL
        mov ebx, lpdwImageWidth
        mov eax, ImageWidth
        mov [ebx], eax
    .ENDIF
    .IF lpdwImageHeight != NULL
        mov ebx, lpdwImageHeight
        mov eax, ImageHeight
        mov [ebx], eax
    .ENDIF
    
    mov eax, TRUE
    ret
IEPVRTextureDimensions ENDP


IEPVR_LIBEND

