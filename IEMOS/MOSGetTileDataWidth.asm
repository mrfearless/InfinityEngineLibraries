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
; Returns in eax width of data block as blocksize if column < columns -1
; (column = nTile % columns)
; 
; otherwise returns in eax: imagewidth - (column * blocksize)
;------------------------------------------------------------------------------
MOSGetTileDataWidth PROC USES EBX ECX EDX nTile:DWORD, dwBlockColumns:DWORD, dwBlockSize:DWORD, dwImageWidth:DWORD
    LOCAL COLSmod:DWORD
    
    mov eax, dwBlockColumns
    dec eax
    mov COLSmod, eax
    
    mov eax, dwBlockColumns
    and eax, 1 ; ( a AND (b-1) = mod )
    .IF eax == 0 ; is divisable by 2?
        mov eax, nTile
        and eax, COLSmod ; then use (a AND (b-1)) instead of div to get modulus
        ; eax = column
        .IF eax < COLSmod
            mov eax, dwBlockSize
            ret
        .ENDIF
    .ELSE ; Use div for modulus otherwise
        xor edx, edx
        mov eax, nTile
        mov ecx, dwBlockColumns
        div ecx
        mov eax, edx
        ; eax = column
        .IF eax < COLSmod
            mov eax, dwBlockSize
            ret
        .ENDIF
    .ENDIF
    ; eax is column
    mov ebx, dwBlockSize
    mul ebx
    mov ebx, eax
    mov eax, dwImageWidth
    sub eax, ebx
    ; eax = imagewidth - (columns * blocksize)
    ret
MOSGetTileDataWidth ENDP


IEMOS_LIBEND

