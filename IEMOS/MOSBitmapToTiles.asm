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

.CONST
BLOCKSIZE_DEFAULT           EQU 64

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; Returns in eax total tiles
;------------------------------------------------------------------------------
MOSBitmapToTiles PROC USES EBX hBitmap:DWORD, lpdwTileDataArray:DWORD, lpdwPaletteArray:DWORD, lpdwImageWidth:DWORD, lpdwImageHeight:DWORD, lpdwBlockColumns:DWORD, lpdwBlockRows:DWORD
    LOCAL bm:BITMAP
    LOCAL ImageWidth:DWORD
    LOCAL ImageHeight:DWORD
    LOCAL Columns:DWORD
    LOCAL Rows:DWORD
    LOCAL TileRightWidth:DWORD
    LOCAL TileBottomHeight:DWORD
    LOCAL TileW:DWORD    
    LOCAL TileH:DWORD
    LOCAL TotalTiles:DWORD
    
    ;GetDIBits https://docs.microsoft.com/en-us/windows/desktop/api/wingdi/nf-wingdi-getdibits
    ; https://www.autoitscript.com/forum/topic/74330-getdibits/
    ;https://stackoverflow.com/questions/46562369/winapi-gdi-how-to-use-getdibits-to-get-color-table-synthesized-for-a-bitmap
    ;http://forums.codeguru.com/showthread.php?175394-How-to-save-a-bitmap-correctly
    ; do it in reverse
    
    ; get bitmap image width and height

    ; calc columns, rows, blocksize and total tiles
    
    ; alloc TILEDATA for total tiles
    ; loop through tiles and
    ; get tile width, height, x, y, tilesizebmp, tileBMP
    ; get tileBMP GDIBits and GDI color table for tile palette
    ; strip dword alignment from tileBMP to convert to tileRAW and find tilesizeraw
    ; 

    .IF hBitmap == NULL
        mov eax, 0
        ret
    .ENDIF
    
    Invoke RtlZeroMemory, Addr bm, SIZEOF BITMAP
    Invoke GetObject, hBitmap, SIZEOF bm, Addr bm
    .IF eax == 0
        ret
    .ENDIF

    mov eax, bm.bmWidth
    mov ImageWidth, eax
    mov eax, bm.bmHeight
    mov ImageHeight, eax

    .IF ImageWidth == 0 || ImageHeight == 0
        mov eax, 0
        ret
    .ENDIF
    
    ; 200 x 36
    ; If imagewidth >= BLOCKSIZE_DEFAULT
    ;   imagewidth % BLOCKSIZE_DEFAULT = no of columns
    ;   if remainder != 0
    ;       then inc no columns and last col is this width TileRightWidth
    ;       TileRightWidth = remainder
    ;   else
    ;       TileRightWidth = BLOCKSIZE_DEFAULT
    ;   endif
    ;   TileW = BLOCKSIZE_DEFAULT
    ; else ; imagewidth < BLOCKSIZE_DEFAULT
    ;   columns = 1
    ;   TileW = imagewidth
    ; endif
    
    ; If imageheight >= BLOCKSIZE_DEFAULT
    ;   imageheight % BLOCKSIZE_DEFAULT = no of rows
    ;   if remainder != 0
    ;       then inc no rows and last rows is this width TileBottomHeight
    ;   endif
    ;   TileH = BLOCKSIZE_DEFAULT
    ; else
    ;   TileH = imageheight
    ; endif
    ;
    ; TotalTiles = columns x rows
    
    
    ret

MOSBitmapToTiles ENDP


IEMOS_LIBEND

