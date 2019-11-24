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
include kernel32.inc
include user32.inc

includelib kernel32.lib
includelib user32.lib

include zlibstat1211.inc
includelib zlibstat1211.lib

include IEMOS.inc


.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; Uncompresses MOSC file to an area of memory that we allocate for the exact 
; size of data
;------------------------------------------------------------------------------
MOSUncompress PROC USES EBX hMOSFile:DWORD, pMOS:DWORD, dwSize:DWORD
    LOCAL dest:DWORD
    LOCAL src:DWORD
    LOCAL MOSU_Size:DWORD
    LOCAL BytesRead:DWORD
    LOCAL MOSFilesize:DWORD
    LOCAL MOSC_UncompressedSize:DWORD
    LOCAL MOSC_CompressedSize:DWORD
    
    Invoke GetFileSize, hMOSFile, NULL
    mov MOSFilesize, eax
    mov ebx, pMOS
    mov eax, [ebx].MOSC_HEADER.UncompressedLength
    mov MOSC_UncompressedSize, eax
    mov eax, MOSFilesize
    sub eax, 0Ch ; take away the MOSC header 12 bytes = 0xC
    mov MOSC_CompressedSize, eax ; set correct compressed size = length of file minus MOSC header length

    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, MOSC_UncompressedSize
    .IF eax != NULL
        mov dest, eax
        mov eax, pMOS ;MOSMemMapPtr
        add eax, 0Ch ; add MOSC Header to Memory map to start at correct offset for uncompressing
        mov src, eax
        Invoke uncompress, dest, Addr MOSC_UncompressedSize, src, MOSC_CompressedSize
        .IF eax == Z_OK ; ok
            mov eax, MOSC_UncompressedSize
            mov ebx, dwSize
            mov [ebx], eax
        
            mov eax, dest
            ret
        .ENDIF
    .ENDIF                  
    mov eax, 0        
    ret
MOSUncompress ENDP



IEMOS_LIBEND
