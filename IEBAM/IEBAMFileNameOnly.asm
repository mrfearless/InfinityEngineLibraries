;==============================================================================
;
; IEBAM Library
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

include IEBAM.inc

EXTERNDEF IEBAMFileName     :PROTO hIEBAM:DWORD
EXTERNDEF BAMJustFname      :PROTO szFilePathName:DWORD, szFileName:DWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMFileNameOnly - returns in eax true or false if it managed to pass to the buffer pointed at lpszFileNameOnly, the stripped filename without extension
;------------------------------------------------------------------------------
IEBAMFileNameOnly PROC hIEBAM:DWORD, lpszFileNameOnly:DWORD
    Invoke IEBAMFileName, hIEBAM
    .IF eax == NULL
        mov eax, FALSE
        ret
    .ENDIF
    
    Invoke BAMJustFname, eax, lpszFileNameOnly
    
    mov eax, TRUE
    ret
IEBAMFileNameOnly endp



IEBAM_LIBEND

