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

EXTERNDEF MOSCalcDwordAligned :PROTO dwWidthOrHeight:DWORD

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------
MOSTileDataRAWtoBMP PROC USES EDI ESI pTileRAW:DWORD, pTileBMP:DWORD, dwTileSizeRAW:DWORD, dwTileSizeBMP:DWORD, dwTileWidth:DWORD
    LOCAL RAWCurrentPos:DWORD
    LOCAL BMPCurrentPos:DWORD
    LOCAL WidthDwordAligned:DWORD
    
    Invoke RtlZeroMemory, pTileBMP, dwTileSizeBMP

    Invoke MOSCalcDwordAligned, dwTileWidth
    mov WidthDwordAligned, eax

    mov RAWCurrentPos, 0
    mov BMPCurrentPos, 0
    mov eax, 0
    .WHILE eax < dwTileSizeRAW
    
        mov esi, pTileRAW
        add esi, RAWCurrentPos
        mov edi, pTileBMP
        add edi, BMPCurrentPos
        
        Invoke RtlMoveMemory, edi, esi, dwTileWidth
    
        mov eax, WidthDwordAligned
        add BMPCurrentPos, eax
        mov eax, dwTileWidth
        add RAWCurrentPos, eax
        
        mov eax, RAWCurrentPos
    .ENDW

    ret
MOSTileDataRAWtoBMP ENDP


IEMOS_LIBEND

