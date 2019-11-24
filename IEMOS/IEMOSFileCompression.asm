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
; -1 = No Mos file, TRUE for MOSCV1, FALSE for MOS V1 or MOS V2 
;------------------------------------------------------------------------------
IEMOSFileCompression PROC USES EBX hIEMOS:DWORD
    .IF hIEMOS == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSVersion
    .IF eax == MOS_VERSION_MOSCV10
        mov eax, TRUE
    .ELSE
        mov eax, FALSE
    .ENDIF
    ret
IEMOSFileCompression endp



IEMOS_LIBEND

