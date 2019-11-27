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
include kernel32.inc
include user32.inc

includelib kernel32.lib
includelib user32.lib

;include zlibstat123.inc
;includelib zlibstat123.lib

include zlibstat1211.inc
includelib zlibstat1211.lib



include IEPVR.inc

PVRUncompress PROTO hPVRFile:DWORD, pPVR:DWORD, lpdwSize:DWORD

.CODE


IEPVR_ALIGN
;------------------------------------------------------------------------------
; Uncompresses PVRZ file to an area of memory that we allocate for the exact size of data
; lpdwSize out has size of uncompressed data
;------------------------------------------------------------------------------
PVRUncompress PROC USES EBX hPVRFile:DWORD, pPVR:DWORD, lpdwSize:DWORD
    LOCAL dest:DWORD
    LOCAL src:DWORD
    LOCAL PVRFilesize:DWORD
    LOCAL PVRZ_UncompressedSize:DWORD
    LOCAL PVRZ_CompressedSize:DWORD
    
    Invoke GetFileSize, hPVRFile, NULL
    mov PVRFilesize, eax
    mov ebx, pPVR
    mov eax, [ebx].PVRZ_HEADER.UncompressedSize
    mov PVRZ_UncompressedSize, eax
    mov eax, PVRFilesize
    sub eax, 04h ; take away the PVRZ header 4 bytes
    mov PVRZ_CompressedSize, eax ; set correct compressed size = length of file minus PVRZ header length
    
    mov eax, PVRZ_UncompressedSize
    add eax, 64 ; for extra just in case
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, eax ;PVRC_UncompressedSize
    .IF eax != NULL
        mov dest, eax
        mov eax, pPVR ;PVRMemMapPtr
        add eax, 04h ; add PVRZ Header to Memory map to start at correct offset for uncompressing
        mov src, eax
        Invoke uncompress, dest, Addr PVRZ_UncompressedSize, src, PVRZ_CompressedSize
        .IF eax == Z_OK ; ok
            mov eax, PVRZ_UncompressedSize
            mov ebx, lpdwSize
            mov [ebx], eax
        
            mov eax, dest
            ret
        .ENDIF
    .ENDIF                  
    mov eax, 0        
    ret
PVRUncompress ENDP



IEPVR_LIBEND
