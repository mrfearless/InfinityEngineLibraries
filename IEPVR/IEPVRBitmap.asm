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

;DEBUG32 EQU 1
;IFDEF DEBUG32
;    PRESERVEXMMREGS equ 1
;    includelib M:\Masm32\lib\Debug32.lib
;    DBG32LIB equ 1
;    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
;    include M:\Masm32\include\debug32.inc
;ENDIF

include IEPVR.inc

EXTERNDEF PVRCalcDwordAligned       :PROTO dwWidthOrHeight:DWORD

EXTERNDEF DXTDImageBackscanDxt1     :PROTO STDCALL ImageWidth:DWORD, ImageHeight:DWORD, inputImage:DWORD, outputPixels:DWORD ; Decompresses entire DXT1 image into a backscan bitmap (ie HBITMAP)
EXTERNDEF DXTDImageBackscanDxt3     :PROTO STDCALL ImageWidth:DWORD, ImageHeight:DWORD, inputImage:DWORD, outputPixels:DWORD ; Decompresses entire DXT3 image into a backscan bitmap (ie HBITMAP)
EXTERNDEF DXTDImageBackscanDxt5     :PROTO STDCALL ImageWidth:DWORD, ImageHeight:DWORD, inputImage:DWORD, outputPixels:DWORD ; Decompresses entire DXT5 image into a backscan bitmap (ie HBITMAP)
EXTERNDEF DXTSSE                    :PROTO STDCALL

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
    
    IFDEF DEBUG32
    PrintText 'IEPVRBitmap'
    ENDIF
    
    .IF hIEPVR == NULL
        mov eax, NULL
        ret
    .ENDIF  
    
    Invoke IEPVRTextureDimensions, hIEPVR, Addr dwImageWidth, Addr dwImageHeight
    .IF dwImageWidth == 0 && dwImageHeight == 0
        mov eax, NULL
        ret
    .ENDIF
    
    IFDEF DEBUG32
    PrintText 'IEPVRTextureDimensions'
    PrintDec dwImageWidth
    PrintDec dwImageHeight
    ENDIF
    
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
    
    IFDEF DEBUG32
    PrintText 'IEPVRPixelFormat'
    PrintDec dwPixelFormat
    ENDIF
    
    Invoke IEPVRTextureData, hIEPVR
    .IF eax == NULL
        ret
    .ENDIF
    mov pTextureData, eax
    
    
    
    IFDEF DEBUG32
    DbgDump pTextureData, 16
    PrintText 'IEPVRTextureData'
    PrintDec pTextureData
    ENDIF
    
    Invoke RtlZeroMemory, Addr PVRBitmap, SIZEOF BITMAPINFOHEADER
    
    Invoke PVRCalcDwordAligned, dwImageHeight
    mov dwImageHeightDword, eax
    Invoke PVRCalcDwordAligned, dwImageWidth
    mov dwImageWidthDword, eax
    mov ebx, dwImageHeightDword
    mul ebx
    mov ebx, 4
    mul ebx
    add eax, 4096
    mov dwImageSize, eax
    
    lea ebx, PVRBitmap
    mov [ebx].BITMAPINFOHEADER.biSize, SIZEOF BITMAPINFOHEADER ;40d
    
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
    
    IFDEF DEBUG32
    PrintText 'CreateDIBSection'
    PrintDec hBitmap
    PrintDec pvBitsMem
    ENDIF
    
    .IF hBitmap != 0
        mov eax, dwPixelFormat
        .IF eax == DXT1
            IFDEF DEBUG32
            PrintText 'Invoke DXTDImageBackscanDxt1'
            ENDIF
            Invoke DXTDImageBackscanDxt1, dwImageWidthDword, dwImageHeightDword, pTextureData, pvBitsMem
        .ELSEIF eax == DXT3
            IFDEF DEBUG32
            PrintText 'Invoke DXTDImageBackscanDxt3'
            ENDIF
            Invoke DXTDImageBackscanDxt3, dwImageWidthDword, dwImageHeightDword, pTextureData, pvBitsMem
        .ELSEIF eax == DXT5
            IFDEF DEBUG32
            PrintText 'Invoke DXTDImageBackscanDxt5'
            ENDIF
            Invoke DXTDImageBackscanDxt5, dwImageWidthDword, dwImageHeightDword, pTextureData, pvBitsMem
        .ENDIF
        
        IFDEF DEBUG32
        PrintText 'Finished DXT'
        ENDIF
    .ENDIF
    
    Invoke ReleaseDC, 0, hdc
    mov eax, hBitmap
    ret
IEPVRBitmap ENDP


IEPVR_LIBEND

