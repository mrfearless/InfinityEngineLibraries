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
; 
;------------------------------------------------------------------------------
IEPVRTextureDataSize PROC USES EBX hIEPVR:DWORD
    .IF hIEPVR == NULL
        mov eax, FALSE
        ret
    .ENDIF
    
    mov ebx, hIEPVR
    mov eax, [ebx].PVRINFO.PVRTextureDataSize
    ret
IEPVRTextureDataSize ENDP


IEPVR_LIBEND

