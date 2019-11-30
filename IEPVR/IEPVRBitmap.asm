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
include user32.inc
include kernel32.inc
include gdi32.inc

includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib

include IEPVR.inc

EXTERNDEF PVRCalcDwordAligned       :PROTO dwWidthOrHeight:DWORD

EXTERNDEF DXTDImageBackscanDxt1     :PROTO ImageWidth:DWORD, ImageHeight:DWORD, inputImage:DWORD, outputPixels:DWORD ; Decompresses entire DXT1 image into a backscan bitmap (ie HBITMAP)
EXTERNDEF DXTDImageBackscanDxt3     :PROTO ImageWidth:DWORD, ImageHeight:DWORD, inputImage:DWORD, outputPixels:DWORD ; Decompresses entire DXT3 image into a backscan bitmap (ie HBITMAP)
EXTERNDEF DXTDImageBackscanDxt5     :PROTO ImageWidth:DWORD, ImageHeight:DWORD, inputImage:DWORD, outputPixels:DWORD ; Decompresses entire DXT5 image into a backscan bitmap (ie HBITMAP)


.DATA
PVRBitmap DB (SIZEOF BITMAPINFOHEADER) dup (0)

.CODE


IEPVR_ALIGN
;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------
IEPVRBitmap PROC USES EBX hIEPVR:DWORD
    LOCAL hdc:DWORD
    LOCAL hBitmap:DWORD
    LOCAL dwImageWidth:DWORD
    LOCAL dwImageHeight:DWORD
    LOCAL dwImageWidthDword:DWORD
    LOCAL dwImageHeightDword:DWORD
    LOCAL dwImageSize:DWORD
    LOCAL pvBitsMem:DWORD
    LOCAL dwPixelFormat:DWORD
    LOCAL pTextureData:DWORD
    
    .IF hIEPVR == NULL
        mov eax, NULL
        ret
    .ENDIF  
    
    Invoke IEPVRTextureDimensions, hIEPVR, Addr dwImageWidth, Addr dwImageHeight
    .IF dwImageWidth == 0 && dwImageHeight == 0
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEPVRPixelFormat, hIEPVR
    .IF eax == -1
        mov eax, NULL
        ret
    .ENDIF
    .IF eax != DXT1 && eax != DXT3 && eax != DXT5
        mov eax, NULL
        ret
    .ENDIF
    mov dwPixelFormat, eax
    
    Invoke IEPVRTextureData, hIEPVR
    .IF eax == NULL
        ret
    .ENDIF
    mov pTextureData, eax
    
    Invoke RtlZeroMemory, Addr PVRBitmap, SIZEOF BITMAPINFOHEADER
    
    Invoke PVRCalcDwordAligned, dwImageHeight
    mov dwImageHeightDword, eax
    Invoke PVRCalcDwordAligned, dwImageWidth
    mov dwImageWidthDword, eax
    mov ebx, dwImageHeightDword
    mul ebx
    mov ebx, 4
    mul ebx
    mov dwImageSize, eax
    
    lea ebx, PVRBitmap
    mov [ebx].BITMAPINFOHEADER.biSize, 40d
    
    mov eax, dwImageWidthDword
    mov [ebx].BITMAPINFOHEADER.biWidth, eax
    mov eax, dwImageHeightDword
    ;neg eax
    mov [ebx].BITMAPINFOHEADER.biHeight, eax
    mov [ebx].BITMAPINFOHEADER.biPlanes, 1
    mov [ebx].BITMAPINFOHEADER.biBitCount, 32
    mov [ebx].BITMAPINFOHEADER.biCompression, BI_RGB
    mov eax, dwImageSize
    mov [ebx].BITMAPINFOHEADER.biSizeImage, eax
    mov [ebx].BITMAPINFOHEADER.biXPelsPerMeter, 2835d
    mov [ebx].BITMAPINFOHEADER.biYPelsPerMeter, 2835d

    Invoke GetDC, 0
    mov hdc, eax
    Invoke CreateDIBSection, hdc, Addr PVRBitmap, DIB_RGB_COLORS, Addr pvBitsMem, NULL, 0
    mov hBitmap, eax
    
    mov eax, dwPixelFormat
    .IF eax == DXT1
        Invoke DXTDImageBackscanDxt1, dwImageWidthDword, dwImageHeightDword, pTextureData, pvBitsMem
    .ELSEIF eax == DXT3
        Invoke DXTDImageBackscanDxt3, dwImageWidthDword, dwImageHeightDword, pTextureData, pvBitsMem
    .ELSEIF eax == DXT5
        Invoke DXTDImageBackscanDxt5, dwImageWidthDword, dwImageHeightDword, pTextureData, pvBitsMem
    .ENDIF
    
    Invoke ReleaseDC, 0, hdc
    mov eax, hBitmap
    ret
IEPVRBitmap ENDP


IEPVR_LIBEND

