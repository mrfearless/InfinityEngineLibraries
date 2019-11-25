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
include user32.inc
include kernel32.inc

includelib user32.lib
includelib kernel32.lib

include IEMOS.inc


.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSFileName - returns in eax pointer to zero terminated string contained 
; filename that is open or NULL if not opened
;------------------------------------------------------------------------------
IEMOSFileName PROC USES EBX hIEMOS:DWORD
    LOCAL MosFilename:DWORD
    
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEMOS
    lea eax, [ebx].MOSINFO.MOSFilename
    mov MosFilename, eax
    Invoke lstrlen, MosFilename
    .IF eax == 0
        mov eax, NULL
    .ELSE
        mov eax, MosFilename
    .ENDIF
    ret
IEMOSFileName ENDP



IEMOS_LIBEND

