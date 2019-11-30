;==============================================================================
;
; IEPVR Library
;
; DXT Decompressor by Matej Tomcik
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

.DATA
EXTERNDEF aAlphaDxt3Lookup:DWORD
aAlphaDxt3Lookup DD 0h,011000000h,022000000h,033000000h,044000000h,055000000h,066000000h,077000000h
                 DD 088000000h,099000000h,0aa000000h,0bb000000h,0cc000000h,0dd000000h,0ee000000h,0ff000000h


IEPVR_LIBEND

