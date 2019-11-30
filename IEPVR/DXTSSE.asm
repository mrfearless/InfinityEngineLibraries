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

;DEBUG32 EQU 1
;IFDEF DEBUG32
;    PRESERVEXMMREGS equ 1
;    includelib M:\Masm32\lib\Debug32.lib
;    DBG32LIB equ 1
;    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
;    include M:\Masm32\include\debug32.inc
;ENDIF

.CODE


IEPVR_ALIGN
;------------------------------------------------------------------------------
; Returns TRUE if SSE available, or FALSE otherwise
;------------------------------------------------------------------------------
DXTSSE PROC C USES EBX ECX EDX 
	mov eax, 1
	cpuid
	test edx,02000000h
	jz noSse
	;PrintText 'SSE'
	mov eax, 1
	ret
noSse:
    ;PrintText 'No SSE'
	mov eax, 0
	ret
DXTSSE ENDP


IEPVR_LIBEND



