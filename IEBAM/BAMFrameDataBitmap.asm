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
include user32.inc
include kernel32.inc
include gdi32.inc

includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib

include IEBAM.inc

EXTERNDEF BAMCalcDwordAligned   :PROTO dwWidthOrHeight:DWORD

.DATA
BAMFrameBitmap              DB (SIZEOF BITMAPINFOHEADER + 1024) dup (0)

.CODE


IEBAM_ALIGN
;******************************************************************************
; Returns in eax handle to frame data bitmap or NULL
;******************************************************************************
BAMFrameDataBitmap PROC USES EBX dwFrameWidth:DWORD, dwFrameHeight:DWORD, pFrameBMP:DWORD, dwFrameSizeBMP:DWORD, pFramePalette:DWORD
    LOCAL dwFrameWidthDword:DWORD
    LOCAL hdc:DWORD
    LOCAL FrameBitmapHandle:DWORD
    
    Invoke RtlZeroMemory, Addr BAMFrameBitmap, (SIZEOF BITMAPINFOHEADER + 1024)

    Invoke BAMCalcDwordAligned, dwFrameWidth
    mov dwFrameWidthDword, eax

    lea ebx, BAMFrameBitmap
    mov [ebx].BITMAPINFOHEADER.biSize, 40d
    
    mov eax, dwFrameWidthDword
    mov [ebx].BITMAPINFOHEADER.biWidth, eax
    mov eax, dwFrameHeight
    neg eax
    mov [ebx].BITMAPINFOHEADER.biHeight, eax
    mov [ebx].BITMAPINFOHEADER.biPlanes, 1
    mov [ebx].BITMAPINFOHEADER.biBitCount, 8
    mov [ebx].BITMAPINFOHEADER.biCompression, BI_RGB
    mov eax, dwFrameSizeBMP
    mov [ebx].BITMAPINFOHEADER.biSizeImage, eax
    mov [ebx].BITMAPINFOHEADER.biXPelsPerMeter, 2835d
    mov [ebx].BITMAPINFOHEADER.biYPelsPerMeter, 2835d
    lea eax, BAMFrameBitmap
    lea ebx, [eax].BITMAPINFO.bmiColors
    Invoke RtlMoveMemory, ebx, pFramePalette, 1024d
    
    ;Invoke CreateDC, Addr szMOSDisplayDC, NULL, NULL, NULL
    Invoke GetDC, 0
    mov hdc, eax
    Invoke CreateDIBitmap, hdc, Addr BAMFrameBitmap, CBM_INIT, pFrameBMP, Addr BAMFrameBitmap, DIB_RGB_COLORS
    .IF eax == NULL
        IFDEF DEBUG32
            PrintText 'CreateDIBitmap Failed'
        ENDIF
    .ENDIF
    mov FrameBitmapHandle, eax
    ;Invoke DeleteDC, hdc
    Invoke ReleaseDC, 0, hdc
    mov eax, FrameBitmapHandle
    ret
BAMFrameDataBitmap ENDP




IEBAM_LIBEND

