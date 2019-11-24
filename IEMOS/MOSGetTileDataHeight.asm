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
; Returns in eax height of data block as blocksize if row < rows -1
; (row = nTile / columns)
;
; otherwise returns in eax: imageheight - (row * blocksize)
;------------------------------------------------------------------------------
MOSGetTileDataHeight PROC USES EBX ECX EDX nTile:DWORD, dwBlockRows:DWORD, dwBlockColumns:DWORD, dwBlockSize:DWORD, dwImageHeight:DWORD
    LOCAL ROWSmod:DWORD
    
    mov eax, dwBlockRows
    dec eax
    mov ROWSmod, eax
    
    ; row = nTile / columns
    xor edx, edx
    mov eax, nTile
    mov ecx, dwBlockColumns
    div ecx
    ; eax is row
    .IF eax < ROWSmod
        mov eax, dwBlockSize
    .ELSE
        ; eax is row
        mov ebx, dwBlockSize
        mul ebx
        mov ebx, eax
        mov eax, dwImageHeight
        sub eax, ebx
        ; eax = imageheight - (row * blocksize)
    .ENDIF
    
    ret
MOSGetTileDataHeight ENDP


IEMOS_LIBEND

