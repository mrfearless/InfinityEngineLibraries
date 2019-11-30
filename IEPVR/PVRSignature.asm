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
PVRSignature PROC pPVR:DWORD
    LOCAL UncompressedSize:DWORD
    ; check signatures to determine version
    mov ebx, pPVR
    mov eax, [ebx]
    .IF eax == PVR_SIG || eax == PVR_SIG_
        mov eax, PVR_VERSION_PVR3
    .ELSE
        movzx eax, word ptr [ebx+4]
        .IF ax == 09C78h || ax == 0DA78h || ax == 00178h || ax == 05E78h ; Zlib magic bytes: https://stackoverflow.com/questions/9050260/what-does-a-zlib-header-look-like#17176881  
            mov eax, PVR_VERSION_PVRZ ; if successfully uncompressed in IEPVROpen, is checked again in IEPVRMem to see if its a PVR3
        .ELSE
            mov eax, PVR_VERSION_INVALID
        .ENDIF            
    .ENDIF
    ret
PVRSignature ENDP


IEPVR_LIBEND