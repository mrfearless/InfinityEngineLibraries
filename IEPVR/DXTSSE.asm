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
; Returns TRUE if SSE available, or FALSE otherwise
;------------------------------------------------------------------------------
DXTSSE PROC USES EBX ECX EDX 
	mov eax, 1
	cpuid
	test edx,02000000h
	jz noSse
	mov eax, 1
	ret
noSse:
	mov eax, 0
	ret
DXTSSE ENDP


IEPVR_LIBEND



