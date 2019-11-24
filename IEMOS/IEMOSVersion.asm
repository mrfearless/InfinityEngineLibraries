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
; 0 = No Mos file, 1 = MOS V1, 2 = MOS V2, 3 = MOSCV1 
;------------------------------------------------------------------------------
IEMOSVersion PROC USES EBX hIEMOS:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSVersion
    ret
IEMOSVersion ENDP



IEMOS_LIBEND

