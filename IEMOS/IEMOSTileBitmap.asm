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

includelib user32.lib
includelib kernel32.lib

include IEMOS.inc

EXTERNDEF IEMOSTileDataEntry    :PROTO hIEMOS:DWORD, nTile:DWORD
EXTERNDEF IEMOSTilePalette      :PROTO hIEMOS:DWORD, nTile:DWORD
EXTERNDEF MOSTileDataBitmap     :PROTO dwTileWidth:DWORD, dwTileHeight:DWORD, pTileBMP:DWORD, dwTileSizeBMP:DWORD, pTilePalette:DWORD

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileBitmap - Returns in eax HBITMAP or NULL. Optional variables pointed 
; to, are filled in if eax is a HBITMAP (!NULL), otherwise vars (if supplied) 
; will be set to 0
; Bitmaps created with this function are freed by the IEMOS library when it
; is closed
;------------------------------------------------------------------------------
IEMOSTileBitmap PROC USES EBX hIEMOS:DWORD, nTile:DWORD, lpdwTileWidth:DWORD, lpdwTileHeight:DWORD, lpdwTileXCoord:DWORD, lpdwTileYCoord:DWORD
    LOCAL TilePaletteEntry:DWORD
    LOCAL TileDataEntry:DWORD
    LOCAL TileWidth:DWORD
    LOCAL TileHeight:DWORD
    LOCAL TileXCoord:DWORD
    LOCAL TileYCoord:DWORD
    LOCAL TileSizeBMP:DWORD
    LOCAL TileBMP:DWORD
    LOCAL TileBitmapHandle:DWORD
    
    mov TileWidth, 0
    mov TileHeight, 0
    mov TileXCoord, 0
    mov TileYCoord, 0
    mov TileBitmapHandle, 0
    
    .IF hIEMOS == NULL
        jmp IEMOSTileBitmapExit
    .ENDIF    
    
    Invoke IEMOSTileDataEntry, hIEMOS, nTile
    .IF eax == NULL
        jmp IEMOSTileBitmapExit
    .ENDIF
    mov TileDataEntry, eax

    mov ebx, TileDataEntry
    mov eax, [ebx].TILEDATA.TileW
    .IF eax == 0
        jmp IEMOSTileBitmapExit
    .ENDIF
    mov TileWidth, eax
    mov eax, [ebx].TILEDATA.TileH
    .IF eax == 0
        jmp IEMOSTileBitmapExit
    .ENDIF
    mov TileHeight, eax
    mov eax, [ebx].TILEDATA.TileX
    mov TileXCoord, eax
    mov eax, [ebx].TILEDATA.TileY
    mov TileYCoord, eax
    
    mov eax, [ebx].TILEDATA.TileBitmapHandle
    .IF eax != 0
        mov TileBitmapHandle, eax
        jmp IEMOSTileBitmapExit
    .ENDIF    
    
    mov eax, [ebx].TILEDATA.TileSizeBMP
    .IF eax == 0
        jmp IEMOSTileBitmapExit
    .ENDIF
    mov TileSizeBMP, eax
    mov eax, [ebx].TILEDATA.TileBMP
    .IF eax == 0
        jmp IEMOSTileBitmapExit
    .ENDIF
    mov TileBMP, eax

    Invoke IEMOSTilePalette, hIEMOS, nTile
    .IF eax == NULL
        jmp IEMOSTileBitmapExit
    .ENDIF
    mov TilePaletteEntry, eax

    Invoke MOSTileDataBitmap, TileWidth, TileHeight, TileBMP, TileSizeBMP, TilePaletteEntry
    .IF eax != NULL ; save bitmap handle back to TILEDATA struct
        mov TileBitmapHandle, eax
        mov ebx, TileDataEntry
        mov [ebx].TILEDATA.TileBitmapHandle, eax
    .ENDIF

IEMOSTileBitmapExit:

    .IF lpdwTileWidth != NULL
        mov ebx, lpdwTileWidth
        mov eax, TileWidth
        mov [ebx], eax
    .ENDIF
    
    .IF lpdwTileHeight != NULL
        mov ebx, lpdwTileHeight
        mov eax, TileHeight
        mov [ebx], eax
    .ENDIF
   
    .IF lpdwTileXCoord != NULL
        mov ebx, lpdwTileXCoord
        mov eax, TileXCoord
        mov [ebx], eax
    .ENDIF
    
    .IF lpdwTileYCoord != NULL
        mov ebx, lpdwTileYCoord
        mov eax, TileYCoord
        mov [ebx], eax
    .ENDIF
    
    mov eax, TileBitmapHandle
    ret
IEMOSTileBitmap ENDP




IEMOS_LIBEND

