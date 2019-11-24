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

EXTERNDEF IEMOSTotalTiles       :PROTO hIEMOS:DWORD
EXTERNDEF IEMOSImageDimensions  :PROTO hIEMOS:DWORD, lpdwImageWidth:DWORD, lpdwImageHeight:DWORD
EXTERNDEF IEMOSTileBitmap       :PROTO hIEMOS:DWORD, nTile:DWORD, lpdwTileWidth:DWORD, lpdwTileHeight:DWORD, lpdwTileXCoord:DWORD, lpdwTileYCoord:DWORD

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileBitmap - Returns HBITMAP (of all combined tile bitmaps) or NULL.
; This HBITMAP is not freed when IEMOS library is closed, it should be freed
; by DeleteObject when no longer needed
;------------------------------------------------------------------------------
IEMOSBitmap PROC hIEMOS:DWORD
    LOCAL hdc:DWORD
    LOCAL hdcMem:DWORD
    LOCAL hdcTile:DWORD
    LOCAL SavedDCTile:DWORD
    LOCAL hBitmap:DWORD
    LOCAL hOldBitmap:DWORD
    LOCAL hTileBitmap:DWORD
    LOCAL hTileBitmapOld:DWORD
    LOCAL ImageWidth:DWORD
    LOCAL ImageHeight:DWORD
    LOCAL TileX:DWORD
    LOCAL TileY:DWORD
    LOCAL TileW:DWORD
    LOCAL TileH:DWORD
    LOCAL TotalTiles:DWORD
    LOCAL nTile:DWORD
    
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF  
    
    Invoke IEMOSTotalTiles, hIEMOS
    .IF eax == 0
        ret
    .ENDIF
    mov TotalTiles, eax
    
    Invoke IEMOSImageDimensions, hIEMOS, Addr ImageWidth, Addr ImageHeight
    .IF ImageWidth == 0 && ImageHeight == 0
        mov eax, NULL
        ret
    .ENDIF
    
    ;Invoke CreateDC, Addr szMOSDisplayDC, NULL, NULL, NULL
    Invoke GetDC, 0
    mov hdc, eax

    Invoke CreateCompatibleDC, hdc
    mov hdcMem, eax

    Invoke CreateCompatibleDC, hdc
    mov hdcTile, eax

    Invoke CreateCompatibleBitmap, hdc, ImageWidth, ImageHeight
    mov hBitmap, eax
    
    Invoke SelectObject, hdcMem, hBitmap
    mov hOldBitmap, eax
    
    Invoke SaveDC, hdcTile
    mov SavedDCTile, eax
    
    mov eax, 0
    mov nTile, 0
    .WHILE eax < TotalTiles
        Invoke IEMOSTileBitmap, hIEMOS, nTile, Addr TileW, Addr TileH, Addr TileX, Addr TileY
        .IF eax != NULL
            mov hTileBitmap, eax
            Invoke SelectObject, hdcTile, hTileBitmap
            mov hTileBitmapOld, eax
            
            IFDEF DEBUG32
            PrintText '---------'
            PrintDec nTile
            PrintDec TileX
            PrintDec TileY
            PrintDec TileW
            PrintDec TileH
            PrintText '---------'
            ENDIF
            
            Invoke BitBlt, hdcMem, TileX, TileY, TileW, TileH, hdcTile, 0, 0, SRCCOPY
            Invoke SelectObject, hdcTile, hTileBitmapOld
        .ENDIF

        inc nTile
        mov eax, nTile
    .ENDW
    
    .IF hOldBitmap != 0
        Invoke SelectObject, hdcMem, hOldBitmap
    .ENDIF
    Invoke RestoreDC, hdcTile, SavedDCTile
    Invoke DeleteDC, hdcTile
    Invoke DeleteDC, hdcMem
    ;Invoke DeleteDC, hdc
    Invoke ReleaseDC, 0, hdc
    
    mov eax, hBitmap
    ret
IEMOSBitmap ENDP



IEMOS_LIBEND

