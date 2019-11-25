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
include kernel32.inc
include user32.inc

includelib kernel32.lib
includelib user32.lib

;include zlibstat123.inc
;includelib zlibstat123.lib

include zlibstat1211.inc
includelib zlibstat1211.lib



include IEBAM.inc

BAMUncompress PROTO hBAMFile:DWORD, pBAM:DWORD, dwSize:DWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Uncompresses BAMC file to an area of memory that we allocate for the exact size of data
;------------------------------------------------------------------------------
BAMUncompress PROC USES EBX hBAMFile:DWORD, pBAM:DWORD, dwSize:DWORD
    LOCAL dest:DWORD
    LOCAL src:DWORD
    LOCAL BAMU_Size:DWORD
    LOCAL BytesRead:DWORD
    LOCAL BAMFilesize:DWORD
    LOCAL BAMC_UncompressedSize:DWORD
    LOCAL BAMC_CompressedSize:DWORD
    
    Invoke GetFileSize, hBAMFile, NULL
    mov BAMFilesize, eax
    mov ebx, pBAM
    mov eax, [ebx].BAMC_HEADER.UncompressedLength
    mov BAMC_UncompressedSize, eax
    mov eax, BAMFilesize
    sub eax, 0Ch ; take away the BAMC header 12 bytes = 0xC
    mov BAMC_CompressedSize, eax ; set correct compressed size = length of file minus BAMC header length
    
    mov eax, BAMC_UncompressedSize
    add eax, 64 ; for extra just in case
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, eax ;BAMC_UncompressedSize
    .IF eax != NULL
        mov dest, eax
        mov eax, pBAM ;BAMMemMapPtr
        add eax, 0Ch ; add BAMC Header to Memory map to start at correct offset for uncompressing
        mov src, eax
        Invoke uncompress, dest, Addr BAMC_UncompressedSize, src, BAMC_CompressedSize
        .IF eax == Z_OK ; ok
            mov eax, BAMC_UncompressedSize
            mov ebx, dwSize
            mov [ebx], eax
        
            mov eax, dest
            ret
        .ENDIF
    .ENDIF                  
    mov eax, 0        
    ret
BAMUncompress ENDP



IEBAM_LIBEND
