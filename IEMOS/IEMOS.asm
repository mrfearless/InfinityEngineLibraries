;==============================================================================
;
; IEMOS
;
; Copyright (c) 2019 by fearless
;
; http://github.com/mrfearless/InfinityEngineLibraries64
;
;
; This software is provided 'as-is', without any express or implied warranty. 
; In no event will the author be held liable for any damages arising from the 
; use of this software.
;
; Permission is granted to anyone to use this software for any non-commercial 
; program. If you use the library in an application, an acknowledgement in the
; application or documentation is appreciated but not required. 
;
; You are allowed to make modifications to the source code, but you must leave
; the original copyright notices intact and not misrepresent the origin of the
; software. It is not allowed to claim you wrote the original software. 
; Modified files must have a clear notice that the files are modified, and not
; in the original state. This includes the name of the person(s) who modified 
; the code. 
;
; If you want to distribute or redistribute any portion of this package, you 
; will need to include the full package in it's original state, including this
; license and all the copyrights.  
;
; While distributing this package (in it's original state) is allowed, it is 
; not allowed to charge anything for this. You may not sell or include the 
; package in any commercial package without having permission of the author. 
; Neither is it allowed to redistribute any of the package's components with 
; commercial applications.
;
;==============================================================================
.686
.MMX
.XMM
.model flat,stdcall
option casemap:none

;DEBUG32 EQU 1
;IFDEF DEBUG32
;    PRESERVEXMMREGS equ 1
;    includelib M:\Masm32\lib\Debug32.lib
;    DBG32LIB equ 1
;    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
;    include M:\Masm32\include\debug32.inc
;ENDIF

include windows.inc
include kernel32.inc
include user32.inc
include gdi32.inc

includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib

include IEMOS.inc


; Internal functions start with MOS
; External functions start with IEMOS 


;-------------------------------------------------------------------------
; Internal functions:
;-------------------------------------------------------------------------
MOSSignature                PROTO pMOS:DWORD
MOSJustFname                PROTO szFilePathName:DWORD, szFileName:DWORD
MOSUncompress               PROTO hMOSFile:DWORD, pMOS:DWORD, dwSize:DWORD

MOSV1Mem                    PROTO pMOSInMemory:DWORD, lpszMosFilename:DWORD, dwMosFilesize:DWORD, dwOpenMode:DWORD
MOSV2Mem                    PROTO pMOSInMemory:DWORD, lpszMosFilename:DWORD, dwMosFilesize:DWORD, dwOpenMode:DWORD

MOSGetTileDataWidth         PROTO nTile:DWORD, dwBlockColumns:DWORD, dwBlockSize:DWORD, dwImageWidth:DWORD
MOSGetTileDataHeight        PROTO nTile:DWORD, dwBlockRows:DWORD, dwBlockColumns:DWORD, dwBlockSize:DWORD, dwImageHeight:DWORD

MOSCalcDwordAligned         PROTO dwWidthOrHeight:DWORD
MOSTileDataRAWtoBMP         PROTO pTileRAW:DWORD, pTileBMP:DWORD, dwTileSizeRAW:DWORD, dwTileSizeBMP:DWORD, dwTileWidth:DWORD
MOSTileDataBitmap           PROTO dwTileWidth:DWORD, dwTileHeight:DWORD, pTileBMP:DWORD, dwTileSizeBMP:DWORD, pTilePalette:DWORD
MOSBitmapToTiles            PROTO hBitmap:DWORD, lpdwTileDataArray:DWORD, lpdwPaletteArray:DWORD, lpdwImageWidth:DWORD, lpdwImageHeight:DWORD, lpdwBlockColumns:DWORD, lpdwBlockRows:DWORD

MOSScaleWidthHeight         PROTO dwImageWidth:DWORD, dwImageHeight:DWORD, dwPreferredWidth:DWORD, dwPreferredHeight:DWORD, lpdwScaledWidth:DWORD, lpdwScaledHeight:DWORD



.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSOpen - Returns handle in eax of opened mos file. NULL if could not alloc
; enough mem
;------------------------------------------------------------------------------
IEMOSOpen PROC USES EBX lpszMosFilename:DWORD, dwOpenMode:DWORD
    LOCAL hIEMOS:DWORD
    LOCAL hMOSFile:DWORD
    LOCAL MOSFilesize:DWORD
    LOCAL SigReturn:DWORD
    LOCAL MOSMemMapHandle:DWORD
    LOCAL MOSMemMapPtr:DWORD
    LOCAL pMOS:DWORD

    .IF dwOpenMode == IEMOS_MODE_READONLY ; readonly
        Invoke CreateFile, lpszMosFilename, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ELSE
        Invoke CreateFile, lpszMosFilename, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ENDIF
 
    .IF eax == INVALID_HANDLE_VALUE
        mov eax, NULL
        ret
    .ENDIF
    mov hMOSFile, eax

    Invoke GetFileSize, hMOSFile, NULL
    mov MOSFilesize, eax
    
    ;---------------------------------------------------                
    ; File Mapping: Create file mapping for main .mos
    ;---------------------------------------------------
    .IF dwOpenMode == IEMOS_MODE_READONLY ; readonly
        Invoke CreateFileMapping, hMOSFile, NULL, PAGE_READONLY, 0, 0, NULL ; Create memory mapped file
    .ELSE
        Invoke CreateFileMapping, hMOSFile, NULL, PAGE_READWRITE, 0, 0, NULL ; Create memory mapped file
    .ENDIF   
    .IF eax == NULL
        Invoke CloseHandle, hMOSFile      
        mov eax, NULL
        ret
    .ENDIF
    mov MOSMemMapHandle, eax
    
    .IF dwOpenMode == IEMOS_MODE_READONLY ; readonly
        Invoke MapViewOfFileEx, MOSMemMapHandle, FILE_MAP_READ, 0, 0, 0, NULL
    .ELSE
        Invoke MapViewOfFileEx, MOSMemMapHandle, FILE_MAP_ALL_ACCESS, 0, 0, 0, NULL
    .ENDIF
    .IF eax == NULL
        Invoke CloseHandle, MOSMemMapHandle
        Invoke CloseHandle, hMOSFile    
        mov eax, NULL
        ret
    .ENDIF
    mov MOSMemMapPtr, eax
    
    Invoke MOSSignature, MOSMemMapPtr
    mov SigReturn, eax
    .IF SigReturn == MOS_VERSION_INVALID ; not a valid mos file
        Invoke UnmapViewOfFile, MOSMemMapPtr
        Invoke CloseHandle, MOSMemMapHandle
        Invoke CloseHandle, hMOSFile
        mov eax, NULL
        ret    
    
    .ELSEIF SigReturn == MOS_VERSION_MOS_V10 ; MOS
        Invoke IEMOSMem, MOSMemMapPtr, lpszMosFilename, MOSFilesize, dwOpenMode
        mov hIEMOS, eax
        .IF hIEMOS == NULL
            Invoke UnmapViewOfFile, MOSMemMapPtr
            Invoke CloseHandle, MOSMemMapHandle
            Invoke CloseHandle, hMOSFile
            mov eax, NULL
            ret    
        .ENDIF
        .IF dwOpenMode == IEMOS_MODE_WRITE ; write (default)
            Invoke UnmapViewOfFile, MOSMemMapPtr
            Invoke CloseHandle, MOSMemMapHandle
            Invoke CloseHandle, hMOSFile
        .ELSE ; else readonly, so keep mapping around till we close file
            mov ebx, hIEMOS
            mov eax, MOSMemMapHandle
            mov [ebx].MOSINFO.MOSMemMapHandle, eax
            mov eax, hMOSFile
            mov [ebx].MOSINFO.MOSFileHandle, eax
        .ENDIF

    .ELSEIF SigReturn == MOS_VERSION_MOS_V20 ; MOSV2 - return false for the mo
      Invoke IEMOSMem, MOSMemMapPtr, lpszMosFilename, MOSFilesize, dwOpenMode
        mov hIEMOS, eax
        .IF hIEMOS == NULL
            Invoke UnmapViewOfFile, MOSMemMapPtr
            Invoke CloseHandle, MOSMemMapHandle
            Invoke CloseHandle, hMOSFile
            mov eax, NULL
            ret    
        .ENDIF
        .IF dwOpenMode == IEMOS_MODE_WRITE ; write (default)
            Invoke UnmapViewOfFile, MOSMemMapPtr
            Invoke CloseHandle, MOSMemMapHandle
            Invoke CloseHandle, hMOSFile
        .ELSE ; else readonly, so keep mapping around till we close file
            mov ebx, hIEMOS
            mov eax, MOSMemMapHandle
            mov [ebx].MOSINFO.MOSMemMapHandle, eax
            mov eax, hMOSFile
            mov [ebx].MOSINFO.MOSFileHandle, eax
        .ENDIF    
;        Invoke UnmapViewOfFile, MOSMemMapPtr
;        Invoke CloseHandle, MOSMemMapHandle
;        Invoke CloseHandle, hMOSFile
;        mov eax, NULL
;        ret    

    .ELSEIF SigReturn == MOS_VERSION_MOSCV10 ; MOSC
        Invoke MOSUncompress, hMOSFile, MOSMemMapPtr, Addr MOSFilesize
        .IF eax == 0
            Invoke UnmapViewOfFile, MOSMemMapPtr
            Invoke CloseHandle, MOSMemMapHandle
            Invoke CloseHandle, hMOSFile        
            mov eax, NULL
            ret
        .ENDIF
        mov pMOS, eax ; save uncompressed location to this var
        Invoke UnmapViewOfFile, MOSMemMapPtr
        Invoke CloseHandle, MOSMemMapHandle
        Invoke CloseHandle, hMOSFile        
        Invoke IEMOSMem, pMOS, lpszMosFilename, MOSFilesize, dwOpenMode
        mov hIEMOS, eax
        .IF hIEMOS == NULL
            Invoke GlobalFree, pMOS
            mov eax, NULL
            ret
        .ENDIF
   
    .ENDIF
    ; save original version to handle for later use so we know if orignal file opened was standard BIFF or a compressed BIF_ or BIFC file, if 0 then it was in mem so we assume BIFF
    mov ebx, hIEMOS
    mov eax, SigReturn
    mov [ebx].MOSINFO.MOSVersion, eax
    mov eax, hIEMOS
    ret
IEMOSOpen ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSClose - Close MOS File
;------------------------------------------------------------------------------
IEMOSClose PROC USES EBX hIEMOS:DWORD
    LOCAL dwOpenMode:DWORD
    LOCAL TotalTiles:DWORD
    LOCAL TileDataPtr:DWORD
    LOCAL ptrCurrentTileData:DWORD
    LOCAL nTile:DWORD
    LOCAL TileSizeRAW:DWORD
    
    .IF hIEMOS == NULL
        mov eax, 0
        ret
    .ENDIF

    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSOpenMode
    mov dwOpenMode, eax
    
    .IF eax == IEMOS_MODE_WRITE ; Write Mode
        mov ebx, hIEMOS
        mov eax, [ebx].MOSINFO.MOSHeaderPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
        mov ebx, hIEMOS
        mov eax, [ebx].MOSINFO.MOSPaletteEntriesPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF

        mov ebx, hIEMOS
        mov eax, [ebx].MOSINFO.MOSTileLookupEntriesPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF

        mov ebx, hIEMOS
        mov eax, [ebx].MOSINFO.MOSBlockEntriesPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF        
    .ENDIF
    
    ; Loop through all TILEDATA entries and clear RAW and BMP
    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSTileDataPtr
    mov TileDataPtr, eax
    mov ptrCurrentTileData, eax
    mov eax, [ebx].MOSINFO.MOSTotalTiles
    mov TotalTiles, eax
    
    .IF TotalTiles > 0 && TileDataPtr != 0
        mov nTile, 0
        mov eax, 0
        .WHILE eax < TotalTiles
            
            ; Delete Bitmap Handle
            mov ebx, ptrCurrentTileData
            mov eax, [ebx].TILEDATA.TileBitmapHandle
            .IF eax != NULL
                Invoke DeleteObject, eax
            .ENDIF
            
            .IF dwOpenMode == IEMOS_MODE_WRITE
                mov ebx, ptrCurrentTileData
                mov eax, [ebx].TILEDATA.TileRAW
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
            .ENDIF

            mov ebx, ptrCurrentTileData            
            mov eax, [ebx].TILEDATA.TileBMP
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF

            add ptrCurrentTileData, SIZEOF TILEDATA
            inc nTile
            mov eax, nTile
        .ENDW
        
        ; Clear TILEDATA
        mov eax, TileDataPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
    .ENDIF

    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSVersion
    .IF eax == MOS_VERSION_MOSCV10 ; MOSC in read or write mode uncompresed bam in memory needs to be cleared
        mov ebx, hIEMOS
        mov eax, [ebx].MOSINFO.MOSMemMapPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF    
    
    .ELSE ; MOS V1 or MOS V2 so if  opened in readonly, unmap file etc, otherwise free mem

        .IF dwOpenMode == IEMOS_MODE_READONLY ; Read Only
            mov ebx, hIEMOS
            mov eax, [ebx].MOSINFO.MOSMemMapPtr
            .IF eax != NULL
                Invoke UnmapViewOfFile, eax
            .ENDIF
            
            mov ebx, hIEMOS
            mov eax, [ebx].MOSINFO.MOSMemMapHandle
            .IF eax != NULL
                Invoke CloseHandle, eax
            .ENDIF

            mov ebx, hIEMOS
            mov eax, [ebx].MOSINFO.MOSFileHandle
            .IF eax != NULL
                Invoke CloseHandle, eax
            .ENDIF
       
        .ELSE ; free mem if write mode
            mov ebx, hIEMOS
            mov eax, [ebx].MOSINFO.MOSMemMapPtr
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF
        .ENDIF

    .ENDIF
    
    mov eax, hIEMOS
    .IF eax != NULL
        Invoke GlobalFree, eax
    .ENDIF

    mov eax, 0
    ret
IEMOSClose ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSMem - Returns handle in eax of opened bam file that is already loaded 
; into memory. NULL if could not alloc enough mem calls MOSV1Mem or MOSV2Mem 
; depending on version of file found
;------------------------------------------------------------------------------
IEMOSMem PROC pMOSInMemory:DWORD, lpszMosFilename:DWORD, dwMosFilesize:DWORD, dwOpenMode:DWORD
    ; check signatures to determine version
    Invoke MOSSignature, pMOSInMemory

    .IF eax == MOS_VERSION_INVALID ; invalid file
        mov eax, NULL
        ret

    .ELSEIF eax == MOS_VERSION_MOS_V10
        Invoke MOSV1Mem, pMOSInMemory, lpszMosFilename, dwMosFilesize, dwOpenMode

    .ELSEIF eax == MOS_VERSION_MOS_V20
        Invoke MOSV2Mem, pMOSInMemory, lpszMosFilename, dwMosFilesize, dwOpenMode

    .ELSEIF eax == MOS_VERSION_MOSCV10
        Invoke MOSV1Mem, pMOSInMemory, lpszMosFilename, dwMosFilesize, dwOpenMode

    .ENDIF
    ret
IEMOSMem ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; MOSV1Mem - Returns handle in eax of opened bam file that is already loaded 
; into memory. NULL if could not alloc enough mem
;------------------------------------------------------------------------------
MOSV1Mem PROC USES EBX ECX EDX EDI ESI pMOSInMemory:DWORD, lpszMosFilename:DWORD, dwMosFilesize:DWORD, dwOpenMode:DWORD
    LOCAL hIEMOS:DWORD
    LOCAL MOSMemMapPtr:DWORD
    LOCAL OffsetPalettes:DWORD ; From raw mos
    LOCAL OffsetTileEntries:DWORD ; OffsetPalettes + (TotalTiles * 1024)
    LOCAL OffsetTileData:DWORD ; OffsetTileEntries + (TotalTiles * SIZEOF RGBQUAD)
    LOCAL ptrCurrentTileLookupEntry:DWORD ; begins with TileLookupEntriesPtr
    LOCAL ptrCurrentTileLookupEntryData:DWORD ; from TileLookupEntries DWORD pointers
    LOCAL ptrCurrentTileData:DWORD ; Current TILEDATA entry
    LOCAL ptrCurrentTilePalette:DWORD
    LOCAL ImageWidth:DWORD ; From raw mos
    LOCAL ImageHeight:DWORD ; From raw mos
    LOCAL BlockColumns:DWORD ; From raw mos
    LOCAL BlockRows:DWORD ; From raw mos
    LOCAL BlockSize:DWORD ; From raw mos
    LOCAL TotalTiles:DWORD ; BlockColumns * BlockRows
    LOCAL PaletteEntriesPtr:DWORD ; MEMMapped File / Alloced MEM
    LOCAL PaletteEntriesSize:DWORD ; TotalTiles * 1024
    LOCAL TileLookupEntriesPtr:DWORD ; MEMMapped File / Alloced MEM
    LOCAL TileLookupEntriesSize:DWORD ; TotalTiles * SIZEOF RGBQUAD
    LOCAL TileDataPtr:DWORD ; pointer to TILEDATA arrays
    LOCAL TileDataSize:DWORD ; size of all TILEDATA arrays
    LOCAL nTile:DWORD
    LOCAL TileX:DWORD
    LOCAL TileY:DWORD
    LOCAL TileH:DWORD
    LOCAL TileW:DWORD    
    LOCAL TileSizeRAW:DWORD
    LOCAL TileSizeBMP:DWORD
    LOCAL TileRAW:DWORD
    LOCAL TileBMP:DWORD
    LOCAL TileHeightAccumulative:DWORD

    mov eax, pMOSInMemory
    mov MOSMemMapPtr, eax       
    
    ;----------------------------------
    ; Alloc mem for our IEMOS Handle
    ;----------------------------------
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF MOSINFO
    .IF eax == NULL
        ret
    .ENDIF
    mov hIEMOS, eax
    
    mov ebx, hIEMOS
    mov eax, dwOpenMode
    mov [ebx].MOSINFO.MOSOpenMode, eax
    mov eax, MOSMemMapPtr
    mov [ebx].MOSINFO.MOSMemMapPtr, eax
    
    lea eax, [ebx].MOSINFO.MOSFilename
    Invoke lstrcpy, eax, lpszMosFilename
    ;Invoke szCopy, lpszMosFilename, eax
    
    mov ebx, hIEMOS
    mov eax, dwMosFilesize
    mov [ebx].MOSINFO.MOSFilesize, eax

    ;----------------------------------
    ; MOS Header
    ;----------------------------------
    .IF dwOpenMode == IEMOS_MODE_WRITE
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF MOSV1_HEADER
        .IF eax == NULL
            Invoke GlobalFree, hIEMOS
            mov eax, NULL
            ret
        .ENDIF    
        mov ebx, hIEMOS
        mov [ebx].MOSINFO.MOSHeaderPtr, eax
        mov ebx, MOSMemMapPtr
        Invoke RtlMoveMemory, eax, ebx, SIZEOF MOSV1_HEADER
    .ELSE
        mov ebx, hIEMOS
        mov eax, MOSMemMapPtr
        mov [ebx].MOSINFO.MOSHeaderPtr, eax
    .ENDIF
    mov ebx, hIEMOS
    mov eax, SIZEOF MOSV1_HEADER
    mov [ebx].MOSINFO.MOSHeaderSize, eax   

;    ;----------------------------------
;    ; Double check file in mem is MOS
;    ;----------------------------------
;    Invoke RtlZeroMemory, Addr MOSXHeader, SIZEOF MOSXHeader
;    Invoke RtlMoveMemory, Addr MOSXHeader, MOSMemMapPtr, 8d
;    Invoke szCmp, Addr MOSXHeader, Addr MOSV1Header
;    .IF eax == 0 ; no match    
;        mov ebx, hIEMOS
;        mov eax, [ebx].MOSINFO.MOSHeaderPtr
;        .IF eax != NULL
;            Invoke GlobalFree, eax
;        .ENDIF
;        Invoke GlobalFree, hIEMOS
;        mov eax, NULL    
;        ret
;    .ENDIF

    ;----------------------------------
    ; Offsets & Sizes
    ;----------------------------------
    mov ebx, [ebx].MOSINFO.MOSHeaderPtr
    movzx eax, word ptr [ebx].MOSV1_HEADER.ImageWidth
    mov ImageWidth, eax
    movzx eax, word ptr [ebx].MOSV1_HEADER.ImageHeight
    mov ImageHeight, eax
    movzx eax, word ptr [ebx].MOSV1_HEADER.BlockColumns
    mov BlockColumns, eax
    movzx eax, word ptr [ebx].MOSV1_HEADER.BlockRows
    mov BlockRows, eax
    mov eax, [ebx].MOSV1_HEADER.BlockSize
    mov BlockSize, eax
    mov eax, [ebx].MOSV1_HEADER.PalettesOffset
    mov OffsetPalettes, eax
    
    mov eax, BlockColumns
    mov ebx, BlockRows
    mul ebx
    mov TotalTiles, eax
    
    mov eax, TotalTiles
    mov ebx, SIZEOF DWORD
    mul ebx
    mov TileLookupEntriesSize, eax
    
    mov eax, TotalTiles
    mov ebx, 1024d ; size of palette
    mul ebx
    mov PaletteEntriesSize, eax
    add eax, OffsetPalettes
    mov OffsetTileEntries, eax
    add eax, TileLookupEntriesSize
    mov OffsetTileData, eax

    ; Store back to MOSINFO structure
    mov ebx, hIEMOS
    mov eax, ImageWidth
    mov [ebx].MOSINFO.MOSImageWidth, eax
    mov eax, ImageHeight
    mov [ebx].MOSINFO.MOSImageHeight, eax
    mov eax, BlockColumns
    mov [ebx].MOSINFO.MOSBlockColumns, eax
    mov eax, BlockRows
    mov [ebx].MOSINFO.MOSBlockRows, eax
    mov eax, BlockSize
    mov [ebx].MOSINFO.MOSBlockSize, eax
    mov eax, TotalTiles
    mov [ebx].MOSINFO.MOSTotalTiles, eax

    ;----------------------------------
    ; Palette
    ;----------------------------------      
    .IF dwOpenMode == IEMOS_MODE_WRITE
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, PaletteEntriesSize ; alloc space for palettes
        .IF eax == NULL
            mov ebx, hIEMOS
            mov eax, [ebx].MOSINFO.MOSHeaderPtr
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF
            Invoke GlobalFree, hIEMOS
            mov eax, NULL    
            ret
        .ENDIF
        mov ebx, hIEMOS
        mov [ebx].MOSINFO.MOSPaletteEntriesPtr, eax
        mov PaletteEntriesPtr, eax

        mov ebx, MOSMemMapPtr
        add ebx, OffsetPalettes
        Invoke RtlMoveMemory, eax, ebx, PaletteEntriesSize
    .ELSE
        mov ebx, hIEMOS
        mov eax, MOSMemMapPtr
        add eax, OffsetPalettes
        mov [ebx].MOSINFO.MOSPaletteEntriesPtr, eax
        mov PaletteEntriesPtr, eax
    .ENDIF
;    ; copy palette to our bitmap header palette var
;    Invoke RtlMoveMemory, Addr MOSBMPPalette, PaletteEntriesPtr, PaletteEntriesSize    

    ;----------------------------------
    ; Tile Entries
    ;----------------------------------
    .IF TotalTiles > 0
        .IF dwOpenMode == IEMOS_MODE_WRITE
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, TileLookupEntriesSize
            .IF eax == NULL
                mov ebx, hIEMOS
                mov eax, [ebx].MOSINFO.MOSHeaderPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                mov eax, [ebx].MOSINFO.MOSPaletteEntriesPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                Invoke GlobalFree, hIEMOS
                mov eax, NULL    
                ret
            .ENDIF    
            mov ebx, hIEMOS
            mov [ebx].MOSINFO.MOSTileLookupEntriesPtr, eax
            mov TileLookupEntriesPtr, eax
        
            mov ebx, MOSMemMapPtr
            add ebx, OffsetTileEntries
            Invoke RtlMoveMemory, eax, ebx, TileLookupEntriesSize
        .ELSE
            mov ebx, hIEMOS
            mov eax, MOSMemMapPtr
            add eax, OffsetTileEntries
            mov [ebx].MOSINFO.MOSTileLookupEntriesPtr, eax
            mov TileLookupEntriesPtr, eax
        .ENDIF
        mov ebx, hIEMOS
        mov eax, TileLookupEntriesSize
        mov [ebx].MOSINFO.MOSTileLookupEntriesSize, eax    
    .ELSE
        mov ebx, hIEMOS
        mov [ebx].MOSINFO.MOSTileLookupEntriesPtr, 0
        mov [ebx].MOSINFO.MOSTileLookupEntriesSize, 0
        mov TileLookupEntriesPtr, 0
    .ENDIF

    ;----------------------------------
    ; Alloc space for Tile Data
    ;----------------------------------
    ; loop throught tile data blocks and copy to TILEDATA.TileRAW
    ; Convert TileRAW to TileBMP for blitting later on.
    .IF TotalTiles > 0
        mov eax, TotalTiles
        mov ebx, SIZEOF TILEDATA
        mul ebx
        mov TileDataSize, eax
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, TileDataSize
        .IF eax == NULL
            mov ebx, hIEMOS
            mov eax, [ebx].MOSINFO.MOSHeaderPtr
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF
            mov eax, [ebx].MOSINFO.MOSPaletteEntriesPtr
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF
            mov eax, [ebx].MOSINFO.MOSTileLookupEntriesPtr
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF            
            Invoke GlobalFree, hIEMOS
            mov eax, NULL    
            ret
        .ENDIF
        mov ebx, hIEMOS
        mov [ebx].MOSINFO.MOSTileDataPtr, eax
        mov TileDataPtr, eax
        mov eax, TileDataSize
        mov [ebx].MOSINFO.MOSTileDataSize, eax        
        
        ; Setup for loop
        mov eax, TileLookupEntriesPtr
        mov ptrCurrentTileLookupEntry, eax
     
        mov eax, MOSMemMapPtr
        add eax, OffsetTileData
        mov ptrCurrentTileLookupEntryData, eax
        
        mov eax, TileDataPtr
        mov ptrCurrentTileData, eax
        
        mov eax, PaletteEntriesPtr
        mov ptrCurrentTilePalette, eax
        
        mov TileX, 0
        mov TileY, 0
        mov TileHeightAccumulative, 0
        
        mov eax, 0
        mov nTile, 0
        .WHILE eax < TotalTiles

            mov ebx, ptrCurrentTileLookupEntry
            mov eax, [ebx]
            add eax, MOSMemMapPtr
            add eax, OffsetTileData  
            mov ptrCurrentTileLookupEntryData, eax
            
            ;----------------------------------
            ; Calc Tile Data INFO
            ;----------------------------------
            Invoke MOSGetTileDataHeight, nTile, BlockRows, BlockColumns, BlockSize, ImageHeight
            mov TileH, eax
            Invoke MOSGetTileDataWidth, nTile, BlockColumns, BlockSize, ImageWidth
            mov TileW, eax
            mov ebx, TileH
            mul ebx
            mov TileSizeRAW, eax

            ; Calc BMP DWORD aligned width
            Invoke MOSCalcDwordAligned, TileW
            ;mov TileW, eax
            mov ebx, TileH
            mul ebx
            mov TileSizeBMP, eax
            
            IFDEF DEBUG32
            PrintText '============='
            PrintDec nTile
            PrintDec TileH
            PrintDec TileW
            PrintDec TileSizeRAW
            PrintDec TileSizeBMP
            PrintText '============='
            ENDIF

            .IF TileX == 0
                mov eax, TileH
                add TileHeightAccumulative, eax
            .ENDIF

            ;----------------------------------
            ; TILE DATA ENTRY RAW
            ;----------------------------------
            .IF dwOpenMode == IEMOS_MODE_WRITE ; Alloc mem for TileRAW
                Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, TileSizeRAW
                mov TileRAW, eax
                .IF eax != NULL
                    Invoke RtlMoveMemory, TileRAW, ptrCurrentTileLookupEntryData, TileSizeRAW
                .ENDIF
            .ELSE
                mov eax, ptrCurrentTileLookupEntryData
                mov TileRAW, eax
            .ENDIF
            mov ebx, ptrCurrentTileData
            mov eax, TileRAW
            mov [ebx].TILEDATA.TileRAW, eax
            mov eax, TileSizeRAW
            mov [ebx].TILEDATA.TileSizeRAW, eax

            ;----------------------------------
            ; TILE DATA ENTRY BMP
            ;----------------------------------
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, TileSizeBMP ; Alloc mem for TileBMP
            mov TileBMP, eax
            .IF eax != NULL
                mov eax, TileSizeBMP
                .IF eax == TileSizeRAW ; raw = bmp, otherwise if not equal size we have to convert to bmp below
                    Invoke RtlMoveMemory, TileBMP, ptrCurrentTileLookupEntryData, TileSizeRAW
                .ENDIF
            .ENDIF
            mov ebx, ptrCurrentTileData
            mov eax, TileBMP
            mov [ebx].TILEDATA.TileBMP, eax
            mov eax, TileSizeBMP
            mov [ebx].TILEDATA.TileSizeBMP, eax
            
            ; convert RAW to BMP
            mov eax, TileSizeBMP
            .IF eax > TileSizeRAW
                ; Only convert raw pixel data to dword aligned bmp palette data if BMP size for dword aligned > RAW size
                Invoke MOSTileDataRAWtoBMP, TileRAW, TileBMP, TileSizeRAW, TileSizeBMP, TileW
            .ENDIF            
            
            ;----------------------------------
            ; TILE DATA ENTRY INFO
            ;----------------------------------
            ; Save Tile Data: X,Y,W,H,RAW,BMP,Sizes
            mov ebx, ptrCurrentTileData
            mov eax, TileX
            mov [ebx].TILEDATA.TileX, eax
            mov eax, TileY
            mov [ebx].TILEDATA.TileY, eax
            mov eax, TileH
            mov [ebx].TILEDATA.TileH, eax
            mov eax, TileW
            mov [ebx].TILEDATA.TileW, eax
            mov eax, ptrCurrentTilePalette
            mov [ebx].TILEDATA.TilePalette, eax
            
            ;----------------------------------
            ; TILE DATA BITMAP
            ;----------------------------------
            ;Invoke MOSTileDataBitmap, TileH, TileW, TileBMP, TileSizeBMP, ptrCurrentTilePalette
            ;mov ebx, ptrCurrentTileData
            ;mov [ebx].TILEDATA.TileBitmapHandle, eax
            
            ;----------------------------------
            ; Calc TileX/Y for next entry
            ;----------------------------------
            mov eax, TileW
            add eax, TileX
            .IF eax >= ImageWidth
                mov TileX, 0 ; reset TileX if greater than imagewidth
                mov eax, TileHeightAccumulative
                mov TileY, eax
            .ELSE
                mov TileX, eax
            .ENDIF

            ; Setup stuff for next entry
            add ptrCurrentTilePalette, 1024
            add ptrCurrentTileData, SIZEOF TILEDATA
            add ptrCurrentTileLookupEntry, SIZEOF DWORD
            inc nTile
            mov eax, nTile
        .ENDW

    .ELSE
        mov ebx, hIEMOS
        mov [ebx].MOSINFO.MOSTileDataPtr, 0
        mov [ebx].MOSINFO.MOSTileDataSize, 0
    .ENDIF
 

    mov eax, hIEMOS
    ret
MOSV1Mem ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; MOSV2Mem - Returns handle in eax of opened bam file that is already loaded 
; into memory. NULL if could not alloc enough mem
;------------------------------------------------------------------------------
MOSV2Mem PROC USES EBX ECX EDX EDI ESI pMOSInMemory:DWORD, lpszMosFilename:DWORD, dwMosFilesize:DWORD, dwOpenMode:DWORD
    LOCAL hIEMOS:DWORD
    LOCAL MOSMemMapPtr:DWORD
    LOCAL TotalBlockEntries:DWORD
    LOCAL BlockEntriesSize:DWORD
    LOCAL OffsetBlockEntries:DWORD
    LOCAL BlockEntriesPtr:DWORD
    LOCAL DataBlockIndex:DWORD
    LOCAL DataBlockCount:DWORD

    mov eax, pMOSInMemory
    mov MOSMemMapPtr, eax      

    ;----------------------------------
    ; Alloc mem for our IEMOS Handle
    ;----------------------------------
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF MOSINFO
    .IF eax == NULL
        ret
    .ENDIF
    mov hIEMOS, eax
    
    mov ebx, hIEMOS
    mov eax, dwOpenMode
    mov [ebx].MOSINFO.MOSOpenMode, eax
    mov eax, MOSMemMapPtr
    mov [ebx].MOSINFO.MOSMemMapPtr, eax
    
    lea eax, [ebx].MOSINFO.MOSFilename
    Invoke lstrcpy, eax, lpszMosFilename
    ;Invoke szCopy, lpszMosFilename, eax
    
    mov ebx, hIEMOS
    mov eax, dwMosFilesize
    mov [ebx].MOSINFO.MOSFilesize, eax

    ;----------------------------------
    ; MOS Header
    ;----------------------------------
    .IF dwOpenMode == IEMOS_MODE_WRITE
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF MOSV2_HEADER
        .IF eax == NULL
            Invoke GlobalFree, hIEMOS
            mov eax, NULL
            ret
        .ENDIF    
        mov ebx, hIEMOS
        mov [ebx].MOSINFO.MOSHeaderPtr, eax
        mov ebx, MOSMemMapPtr
        Invoke RtlMoveMemory, eax, ebx, SIZEOF MOSV2_HEADER
    .ELSE
        mov ebx, hIEMOS
        mov eax, MOSMemMapPtr
        mov [ebx].MOSINFO.MOSHeaderPtr, eax
    .ENDIF
    mov ebx, hIEMOS
    mov eax, SIZEOF MOSV2_HEADER
    mov [ebx].MOSINFO.MOSHeaderSize, eax   

    ;----------------------------------
    ; Frame & Cycle Counts, Offsets & Sizes
    ;----------------------------------
    mov ebx, [ebx].MOSINFO.MOSHeaderPtr
    mov eax, [ebx].MOSV2_HEADER.BlockEntriesCount
    mov TotalBlockEntries, eax
    mov eax, [ebx].MOSV2_HEADER.BlockEntriesOffset
    mov OffsetBlockEntries, eax

    mov eax, TotalBlockEntries
    mov ebx, SIZEOF DATABLOCK_ENTRY
    mul ebx
    mov BlockEntriesSize, eax

    ;----------------------------------
    ; No Palette for MOS V2!
    ;----------------------------------
    mov ebx, hIEMOS
    mov [ebx].MOSINFO.MOSPaletteEntriesPtr, 0
    mov [ebx].MOSINFO.MOSPaletteEntriesSize, 0

    ;----------------------------------
    ; Data Block Entries
    ;----------------------------------
    .IF TotalBlockEntries > 0
        .IF dwOpenMode == IEMOS_MODE_WRITE
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, BlockEntriesSize
            .IF eax == NULL
                mov ebx, hIEMOS
                mov eax, [ebx].MOSINFO.MOSHeaderPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                Invoke GlobalFree, hIEMOS
                mov eax, NULL    
                ret
            .ENDIF    
            mov ebx, hIEMOS
            mov [ebx].MOSINFO.MOSBlockEntriesPtr, eax
            mov BlockEntriesPtr, eax
        
            mov ebx, MOSMemMapPtr
            add ebx, OffsetBlockEntries
            Invoke RtlMoveMemory, eax, ebx, BlockEntriesSize
        .ELSE
            mov ebx, hIEMOS
            mov eax, MOSMemMapPtr
            add eax, OffsetBlockEntries
            mov [ebx].MOSINFO.MOSBlockEntriesPtr, eax
            mov BlockEntriesPtr, eax
        .ENDIF
        mov ebx, hIEMOS
        mov eax, BlockEntriesSize
        mov [ebx].MOSINFO.MOSBlockEntriesSize, eax   
    .ELSE
        mov ebx, hIEMOS
        mov [ebx].MOSINFO.MOSBlockEntriesPtr, 0
        mov [ebx].MOSINFO.MOSBlockEntriesSize, 0
        mov BlockEntriesPtr, 0
    .ENDIF

    mov eax, hIEMOS 
    ret
MOSV2Mem ENDP




IEMOS_LIBEND







