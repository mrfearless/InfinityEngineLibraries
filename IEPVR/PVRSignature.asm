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

.CODE


IEPVR_ALIGN
;------------------------------------------------------------------------------
; Checks the PVR signatures to determine if they are valid and if PVR file is compressed
;------------------------------------------------------------------------------
PVRSignature PROC pPVR:DWORD, dwPVRFilesize:DWORD
    LOCAL UncompressedSize:DWORD
    ; check signatures to determine version
    mov ebx, pPVR
    mov eax, [ebx]
    .IF eax == PVR_SIG || eax == PVR_SIG_
        mov eax, PVR_VERSION_PVR3
    .ELSE
        mov UncompressedSize, eax
        mov eax, dwPVRFilesize
        sub eax, 4
        .IF eax == UncompressedSize
            mov eax, PVR_VERSION_PVR3
        .ELSE
            mov eax, PVR_VERSION_INVALID
        .ENDIF            
    .ENDIF
    ret
PVRSignature ENDP


IEPVR_LIBEND