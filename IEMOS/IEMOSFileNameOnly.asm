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

EXTERNDEF IEMOSFileName     :PROTO hIEMOS:DWORD
EXTERNDEF MOSJustFname      :PROTO szFilePathName:DWORD, szFileName:DWORD

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSFileNameOnly - returns in eax true or false if it managed to pass to the 
; buffer pointed at lpszFileNameOnly, the stripped filename without extension
;------------------------------------------------------------------------------
IEMOSFileNameOnly PROC hIEMOS:DWORD, lpszFileNameOnly:DWORD
    Invoke IEMOSFileName, hIEMOS
    .IF eax == NULL
        mov eax, FALSE
        ret
    .ENDIF
    
    Invoke MOSJustFname, eax, lpszFileNameOnly
    
    mov eax, TRUE
    ret
IEMOSFileNameOnly ENDP



IEMOS_LIBEND

