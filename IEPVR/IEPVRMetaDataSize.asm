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
IEPVRMetaDataSize PROC USES EBX hIEPVR:DWORD
    .IF hIEPVR == NULL
        mov eax, FALSE
        ret
    .ENDIF
    
    mov ebx, hIEPVR
    mov eax, [ebx].PVRINFO.PVRMetaDataSize
    ret
IEPVRMetaDataSize ENDP


IEPVR_LIBEND

