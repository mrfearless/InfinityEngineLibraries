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
include gdi32.inc

includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib

include IEMOS.inc

EXTERNDEF MOSCalcDwordAligned   :PROTO dwWidthOrHeight:DWORD

.DATA
MOSTileBitmap               DB (SIZEOF BITMAPINFOHEADER + 1024) dup (0)

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; Returns in eax handle to tile data bitmap or NULL. 
;------------------------------------------------------------------------------
MOSTileDataBitmap PROC USES EBX dwTileWidth:DWORD, dwTileHeight:DWORD, pTileBMP:DWORD, dwTileSizeBMP:DWORD, pTilePalette:DWORD
    LOCAL dwTileWidthDword:DWORD
    LOCAL hdc:DWORD
    LOCAL TileBitmapHandle:DWORD
    
    Invoke RtlZeroMemory, Addr MOSTileBitmap, (SIZEOF BITMAPINFOHEADER + 1024)

    Invoke MOSCalcDwordAligned, dwTileWidth
    mov dwTileWidthDword, eax

    lea ebx, MOSTileBitmap
    mov [ebx].BITMAPINFOHEADER.biSize, 40d
    
    mov eax, dwTileWidthDword
    mov [ebx].BITMAPINFOHEADER.biWidth, eax
    mov eax, dwTileHeight
    neg eax
    mov [ebx].BITMAPINFOHEADER.biHeight, eax
    mov [ebx].BITMAPINFOHEADER.biPlanes, 1
    mov [ebx].BITMAPINFOHEADER.biBitCount, 8
    mov [ebx].BITMAPINFOHEADER.biCompression, BI_RGB
    mov eax, dwTileSizeBMP
    mov [ebx].BITMAPINFOHEADER.biSizeImage, eax
    mov [ebx].BITMAPINFOHEADER.biXPelsPerMeter, 2835d
    mov [ebx].BITMAPINFOHEADER.biYPelsPerMeter, 2835d
    lea eax, MOSTileBitmap
    lea ebx, [eax].BITMAPINFO.bmiColors
    Invoke RtlMoveMemory, ebx, pTilePalette, 1024d
    
    ;Invoke CreateDC, Addr szMOSDisplayDC, NULL, NULL, NULL
    Invoke GetDC, 0
    mov hdc, eax
    Invoke CreateDIBitmap, hdc, Addr MOSTileBitmap, CBM_INIT, pTileBMP, Addr MOSTileBitmap, DIB_RGB_COLORS
    .IF eax == NULL
        IFDEF DEBUG32
            PrintText 'CreateDIBitmap Failed'
        ENDIF
    .ENDIF
    mov TileBitmapHandle, eax
    ;Invoke DeleteDC, hdc
    Invoke ReleaseDC, 0, hdc
    mov eax, TileBitmapHandle
    ret
MOSTileDataBitmap ENDP


IEMOS_LIBEND

