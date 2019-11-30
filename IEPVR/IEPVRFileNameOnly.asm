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
include user32.inc
include kernel32.inc

includelib user32.lib
includelib kernel32.lib

include IEPVR.inc

EXTERNDEF IEPVRFileName     :PROTO hIEPVR:DWORD
EXTERNDEF PVRJustFname      :PROTO szFilePathName:DWORD, szFileName:DWORD


.CODE


IEPVR_ALIGN
;------------------------------------------------------------------------------
; Returns in eax true or false if it managed to pass to the buffer pointed at 
; lpszFileNameOnly, the stripped filename without extension
;------------------------------------------------------------------------------
IEPVRFileNameOnly PROC hIEPVR:DWORD, lpszFileNameOnly:DWORD
    Invoke IEPVRFileName, hIEPVR
    .IF eax == NULL
        mov eax, FALSE
        ret
    .ENDIF
    
    Invoke PVRJustFname, eax, lpszFileNameOnly
    
    mov eax, TRUE
    ret
IEPVRFileNameOnly ENDP


IEPVR_LIBEND

