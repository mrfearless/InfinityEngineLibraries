;==============================================================================
;
; IEMOS
;
; Copyright (c) 2018 by fearless
;
; All Rights Reserved
;
; http://www.LetTheLight.in
;
; http://github.com/mrfearless/InfinityEngineLibraries
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
include masm32.inc
include zlibstat.inc

includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib
includelib masm32.lib
includelib zlibstat.lib

include IEMOS.inc


; Internal functions start with MOS
; External functions start with IEMOS 


;-------------------------------------------------------------------------
; Internal functions:
;-------------------------------------------------------------------------
MOSSignature            PROTO :DWORD
MOSUncompress           PROTO :DWORD, :DWORD, :DWORD
MOSJustFname            PROTO :DWORD, :DWORD

MOSV1Mem                PROTO :DWORD, :DWORD, :DWORD, :DWORD
MOSV2Mem                PROTO :DWORD, :DWORD, :DWORD, :DWORD

MOSGetTileDataWidth     PROTO :DWORD, :DWORD, :DWORD, :DWORD
MOSGetTileDataHeight    PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
MOSIsCOLSP2             PROTO :DWORD
MOSIsROWSP2             PROTO :DWORD
MOSCalcDwordAligned     PROTO :DWORD
MOSTileDataRAWtoBMP     PROTO :DWORD, :DWORD, :DWORD, :DWORD
MOSTileDataBitmap       PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
MOSBitmapToTiles        PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD


;-------------------------------------------------------------------------
; MOS Structures
;-------------------------------------------------------------------------
IFNDEF MOSV1_HEADER
MOSV1_HEADER            STRUCT
    Signature           DD 0    ; 0x0000 	4 (char array) 	Signature ('MOS ')
    Version             DD 0    ; 0x0004 	4 (char array) 	Version ('V1 ')
    ImageWidth          DW 0    ; 0x0008 	2 (word) 	    Width (pixels)
    ImageHeight         DW 0    ; 0x000a 	2 (word) 	    Height (pixels)
    BlockColumns        DW 0    ; 0x000c 	2 (word) 	    Columns (blocks)
    BlockRows           DW 0    ; 0x000e 	2 (word) 	    Rows (blocks)
    BlockSize           DD 0    ; 0x0010 	4 (dword) 	    Block size (pixels)
    PalettesOffset      DD 0    ; 0x0014 	4 (dword) 	    Offset (from start of file) to palettes
MOSV1_HEADER            ENDS
ENDIF

IFNDEF MOSV2_HEADER
MOSV2_HEADER            STRUCT
    Signature           DD 0    ; 0x0000 	4 (char array) 	Signature ('MOS ')
    Version             DD 0    ; 0x0004 	4 (char array) 	Version ('V2 ')
    ImageWidth          DD 0    ; 0x0008 	4 (dword) 	    Width (pixels)
    ImageHeight         DD 0    ; 0x000c 	4 (dword) 	    Height (pixels)
    BlockEntriesCount   DD 0    ; 0x0010 	4 (dword) 	    Number of data blocks
    BlockEntriesOffset  DD 0    ; 0x0014 	4 (dword) 	    Offset to data blocks
MOSV2_HEADER            ENDS
ENDIF

IFNDEF MOSC_HEADER
MOSC_HEADER             STRUCT
    Signature           DD 0    ; 0x0000   4 (bytes)        Signature ('MOSC')
    Version             DD 0    ; 0x0004   4 (bytes)        Version ('V1 ')
    UncompressedLength  DD 0    ; 0x0008   4 (dword)        Uncompressed data length
MOSC_HEADER             ENDS
ENDIF

IFNDEF DATABLOCK_ENTRY  ; Used in MOS V2
DATABLOCK_ENTRY         STRUCT
    PVRZPage            DD 0
    SourceXCoord        DD 0
    SourceYCoord        DD 0
    FrameWidth          DD 0
    FrameHeight         DD 0
    TargetXCoord        DD 0
    TargetYCoord        DD 0
DATABLOCK_ENTRY         ENDS
ENDIF

IFNDEF TILELOOKUP_ENTRY
TILELOOKUP_ENTRY        STRUCT
    TileDataOffset      DD 0    ; Offset to specific tile's data pixels from start of Tile Data ( Offset Palettes + (Size Palettes) + (Size TilelookupEntries) )
TILELOOKUP_ENTRY        ENDS
ENDIF

IFNDEF TILEDATA
TILEDATA                STRUCT
    TileX               DD 0
    TileY               DD 0
    TileW               DD 0
    TileH               DD 0
    TileSizeRAW         DD 0
    TileSizeBMP         DD 0
    TilePalette         DD 0
    TileRAW             DD 0
    TileBMP             DD 0
    TileBitmapHandle    DD 0
TILEDATA                ENDS
ENDIF

;-------------------------------------------------------------------------
; Structures for internal use
;-------------------------------------------------------------------------
IFNDEF MOSINFO
MOSINFO                     STRUCT
    MOSOpenMode             DD 0
    MOSFilename             DB MAX_PATH DUP (0)
    MOSFilesize             DD 0
    MOSVersion              DD 0
    MOSCompressed           DD 0
    MOSHeaderPtr            DD 0
    MOSHeaderSize           DD 0
    MOSImageWidth           DD 0
    MOSImageHeight          DD 0
    MOSBlockColumns         DD 0 ; MOS V1
    MOSBlockRows            DD 0 ; MOS V1
    MOSBlockSize            DD 0 ; MOS V1
    MOSTotalTiles           DD 0 ; MOS V1
    MOSPaletteEntriesPtr    DD 0 ; no interal palette for MOS V2
    MOSPaletteEntriesSize   DD 0 ; MOS V1
    MOSTileLookupEntriesPtr DD 0 ; MOS V1 ; TileLookup Entries
    MOSTileLookupEntriesSize DD 0 ; MOS V1
    MOSTileDataPtr          DD 0 
    MOSTileDataSize         DD 0
    MOSBlockEntriesPtr      DD 0 ; for MOS V2
    MOSBlockEntriesSize     DD 0 ; for MOS V2
    MOSMemMapPtr            DD 0
    MOSMemMapHandle         DD 0
    MOSFileHandle           DD 0    
MOSINFO                     ENDS
ENDIF

.CONST
BLOCKSIZE_DEFAULT           EQU 64


.DATA
MOSV1Header                 DB "MOS V1  ",0
MOSV2Header                 DB "MOS V2  ",0
MOSCHeader                  DB "MOSCV1  ",0
MOSXHeader                  DB 12 dup (0)
MOSTileBitmap               DB (SIZEOF BITMAPINFOHEADER + 1024) dup (0)
szMOSDisplayDC              DB 'DISPLAY',0

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
IEMOSClose PROC USES EAX EBX hIEMOS:DWORD
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
    
    .IF TotalTiles > 0
        mov nTile, 0
        mov eax, 0
        .WHILE eax < TotalTiles
            mov ebx, ptrCurrentTileData
            .IF dwOpenMode == IEMOS_MODE_WRITE ; Write Mode
                mov eax, [ebx].TILEDATA.TileRAW
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
            .ENDIF
            
            mov ebx, ptrCurrentTileData
            mov eax, [ebx].TILEDATA.TileSizeRAW
            mov TileSizeRAW, eax
            
            ; Clear memory of TileBMP if we had to convert TileRAW to a DWORD aligned TileBMP
            ; File size will be greater in TileBMP if this is so.
            mov eax, [ebx].TILEDATA.TileSizeBMP
            .IF eax > TileSizeRAW            
                mov eax, [ebx].TILEDATA.TileBMP
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
            .ENDIF
            
            ; Delete Bitmap Handle
            mov ebx, ptrCurrentTileData
            mov eax, [ebx].TILEDATA.TileBitmapHandle
            .IF eax != NULL
                Invoke DeleteObject, eax
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
MOSV1Mem PROC USES EBX ECX EDX EDX pMOSInMemory:DWORD, lpszMosFilename:DWORD, dwMosFilesize:DWORD, dwOpenMode:DWORD
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
    Invoke szCopy, lpszMosFilename, eax
    
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

    ;----------------------------------
    ; Double check file in mem is MOS
    ;----------------------------------
    Invoke RtlZeroMemory, Addr MOSXHeader, SIZEOF MOSXHeader
    Invoke RtlMoveMemory, Addr MOSXHeader, MOSMemMapPtr, 8d
    Invoke szCmp, Addr MOSXHeader, Addr MOSV1Header
    .IF eax == 0 ; no match    
        mov ebx, hIEMOS
        mov eax, [ebx].MOSINFO.MOSHeaderPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
        Invoke GlobalFree, hIEMOS
        mov eax, NULL    
        ret
    .ENDIF

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
            mov ebx, TileH
            mul ebx
            mov TileSizeBMP, eax

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
            mov eax, TileSizeBMP
            .IF eax > TileSizeRAW
                Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, TileSizeBMP ; Alloc mem for TileBMP
            .ELSE
                mov eax, TileRAW ; raw bmp same 
            .ENDIF
            mov TileBMP, eax
            mov ebx, ptrCurrentTileData
            mov eax, TileBMP
            mov [ebx].TILEDATA.TileBMP, eax
            mov eax, TileSizeBMP
            mov [ebx].TILEDATA.TileSizeBMP, eax
            
            ; convert RAW to BMP
            mov eax, TileSizeBMP
            .IF eax > TileSizeRAW
                ; Only convert raw pixel data to dword aligned bmp palette data if BMP size for dword aligned > RAW size
                Invoke MOSTileDataRAWtoBMP, TileRAW, TileBMP, TileSizeRAW, TileSizeBMP
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
            .IF eax > ImageWidth
                mov TileX, 0 ; reset TileX if greater than imagewidth
                mov eax, TileH
                add TileY, eax
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
MOSV2Mem PROC USES EBX ECX EDX pMOSInMemory:DWORD, lpszMosFilename:DWORD, dwMosFilesize:DWORD, dwOpenMode:DWORD
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
    Invoke szCopy, lpszMosFilename, eax
    
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


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSHeader - Returns in eax a pointer to header or NULL if not valid
;------------------------------------------------------------------------------
IEMOSHeader PROC USES EBX hIEMOS:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSHeaderPtr
    ret
IEMOSHeader ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileLookupEntries - Returns in eax a pointer to the array of TileLookup 
; entries (DWORDs) or NULL if not valid
;------------------------------------------------------------------------------
IEMOSTileLookupEntries PROC USES EBX hIEMOS:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSTileLookupEntriesPtr
    ret
IEMOSTileLookupEntries ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileLookupEntry - Returns in eax a pointer to specific TileLookup entry
; which if read (DWORD) is an offset to the Tile Data from start of tile pixel 
; data.
;------------------------------------------------------------------------------
IEMOSTileLookupEntry PROC USES EBX hIEMOS:DWORD, nTile:DWORD
    LOCAL TileLookupEntries:DWORD
    
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSTotalTiles
    .IF nTile >= eax ; 0 based tile index
        mov eax, NULL
        ret
    .ENDIF    
    
    Invoke IEMOSTileLookupEntries, hIEMOS
    .IF eax == NULL
        ret
    .ENDIF
    .IF nTile == 0
        ; eax contains TileLookupEntries which is tile 0's start
        ret
    .ENDIF    
    mov TileLookupEntries, eax
    
    mov eax, nTile
    mov ebx, SIZEOF DWORD
    mul ebx
    add eax, TileLookupEntries
    
    ret
IEMOSTileLookupEntry ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileDataEntries - Returns in eax a pointer to the array of TILEDATA or 
; NULL if not valid
;------------------------------------------------------------------------------
IEMOSTileDataEntries PROC USES EBX hIEMOS:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSTileDataPtr
    ret
IEMOSTileDataEntries ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileDataEntry - Returns in eax a pointer to a specific TILEDATA entry or
; NULL if not valid
;------------------------------------------------------------------------------
IEMOSTileDataEntry PROC USES EBX hIEMOS:DWORD, nTile:DWORD
    LOCAL TileDataEntries:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSTotalTiles
    .IF nTile >= eax ; 0 based tile index
        mov eax, NULL
        ret
    .ENDIF        
    
    Invoke IEMOSTileDataEntries, hIEMOS
    .IF eax == NULL
        ret
    .ENDIF
    .IF nTile == 0
        ; eax contains TileDataEntries which is tile 0's start
        ret
    .ENDIF    
    mov TileDataEntries, eax    
    
    mov eax, nTile
    mov ebx, SIZEOF TILEDATA
    mul ebx
    add eax, TileDataEntries    
    
    ret
IEMOSTileDataEntry ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTotalTiles - Returns in eax total tiles in mos
;------------------------------------------------------------------------------
IEMOSTotalTiles PROC USES EBX hIEMOS:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSTotalTiles
    ret
IEMOSTotalTiles ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSImageDimensions - Returns width and height in pointer to variables 
; provided
;------------------------------------------------------------------------------
IEMOSImageDimensions PROC USES EBX hIEMOS:DWORD, lpdwImageWidth:DWORD, lpdwImageHeight:DWORD
    LOCAL dwImageWidth:DWORD
    LOCAL dwImageHeight:DWORD
    mov dwImageWidth, 0
    mov dwImageHeight, 0
    .IF hIEMOS != NULL
        mov ebx, hIEMOS
        mov ebx, [ebx].MOSINFO.MOSHeaderPtr
        .IF ebx != NULL
            movzx eax, word ptr [ebx].MOSV1_HEADER.ImageWidth
            mov dwImageWidth, eax
            movzx eax, word ptr [ebx].MOSV1_HEADER.ImageHeight
            mov dwImageHeight, eax
        .ENDIF
    .ENDIF
    .IF lpdwImageWidth != NULL
        mov ebx, lpdwImageWidth
        mov eax, dwImageWidth
        mov [ebx], eax
    .ENDIF
    .IF lpdwImageHeight != NULL
        mov ebx, lpdwImageHeight
        mov eax, dwImageHeight
        mov [ebx], eax
    .ENDIF
    xor eax, eax
    ret
IEMOSImageDimensions ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSPalettes - Returns in eax a pointer to the palettes or NULL if not valid
;------------------------------------------------------------------------------
IEMOSPalettes PROC USES EBX hIEMOS:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSPaletteEntriesPtr
    ret
IEMOSPalettes ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTilePalette - Returns in eax a pointer to the tile palette or NULL if 
; not valid
;------------------------------------------------------------------------------
IEMOSTilePalette PROC USES EBX hIEMOS:DWORD, nTile:DWORD
    LOCAL PaletteOffset:DWORD

    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSTotalTiles
    .IF nTile >= eax ; 0 based tile index
        mov eax, NULL
        ret
    .ENDIF

    Invoke IEMOSPalettes, hIEMOS
    .IF eax == NULL
        ret
    .ENDIF
    .IF nTile == 0
        ; eax contains PaletteOffset which is tile 0's palette start
        ret
    .ENDIF
    mov PaletteOffset, eax    
    
    mov eax, nTile
    mov ebx, 1024 ;(256 * SIZEOF DWORD)
    mul ebx
    add eax, PaletteOffset
    
    ret
IEMOSTilePalette ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTilePaletteValue - Returns in eax a RGBQUAD of the specified 
; palette index of the tile palette or -1 if not valid
;------------------------------------------------------------------------------
IEMOSTilePaletteValue PROC USES EBX hIEMOS:DWORD, nTile:DWORD, PaletteIndex:DWORD
    LOCAL TilePaletteOffset:DWORD
    
    .IF hIEMOS == NULL
        mov eax, -1
        ret
    .ENDIF
    
    .IF PaletteIndex > 255
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEMOSTilePalette, hIEMOS, nTile
    .IF eax == NULL
        mov eax, -1
        ret
    .ENDIF
    mov TilePaletteOffset, eax

    mov eax, PaletteIndex
    mov ebx, 4 ; dword RGBA array size
    mul ebx
    add eax, TilePaletteOffset
    mov eax, [eax]

    ret
IEMOSTilePaletteValue ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTotalPalettes - Returns in eax total palettes (= total tiles) in mos
;------------------------------------------------------------------------------
IEMOSTotalPalettes PROC USES EBX hIEMOS:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSTotalTiles
    ret
IEMOSTotalPalettes ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTotalBlockEntries - Returns in eax the total no of data block entries
;------------------------------------------------------------------------------
IEMOSTotalBlockEntries PROC USES EBX hIEMOS:DWORD
    .IF hIEMOS == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEMOS
    mov ebx, [ebx].MOSINFO.MOSHeaderPtr
    mov eax, [ebx].MOSV2_HEADER.BlockEntriesCount
    ret
IEMOSTotalBlockEntries ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSBlockEntries - Returns in eax a pointer to data block entries or NULL if
; not valid
;------------------------------------------------------------------------------
IEMOSBlockEntries PROC USES EBX hIEMOS:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSBlockEntriesPtr
    .IF eax == NULL
        mov eax, NULL
    .ENDIF    
    ret
IEMOSBlockEntries ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSBlockEntry - Returns in eax a pointer to the specified Datablock entry 
; or NULL
;------------------------------------------------------------------------------
IEMOSBlockEntry PROC USES EBX hIEMOS:DWORD, nBlockEntry:DWORD
    LOCAL BlockEntriesPtr:DWORD
    
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEMOSTotalBlockEntries, hIEMOS
    .IF eax == 0
        mov eax, NULL
        ret
    .ENDIF
    ; eax contains TotalBlockEntries
     .IF nBlockEntry >= eax
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEMOSBlockEntries, hIEMOS
    .IF eax == NULL
        ret
    .ENDIF
    mov BlockEntriesPtr, eax
    
    mov eax, nBlockEntry
    mov ebx, SIZEOF DATABLOCK_ENTRY
    mul ebx
    add eax, BlockEntriesPtr
    ret
IEMOSBlockEntry ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileBitmap - Returns in eax HBITMAP or NULL. Optional variables pointed 
; to, are filled in if eax is a HBITMAP (!NULL), otherwise vars (if supplied) 
; will be set to 0
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


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileBitmap - Returns HBITMAP (of all combined tile bitmaps) or NULL.
;------------------------------------------------------------------------------
IEMOSBitmap PROC hIEMOS:DWORD
    LOCAL hdc:DWORD
    LOCAL hdcMem:DWORD
    LOCAL hdcTile:DWORD
    LOCAL SavedDCTile:DWORD
    LOCAL hBitmap:DWORD
    LOCAL hOldBitmap:DWORD
    LOCAL hTileBitmap:DWORD
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
    
    Invoke CreateDC, Addr szMOSDisplayDC, NULL, NULL, NULL
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
            Invoke BitBlt, hdcMem, TileX, TileY, TileW, TileH, hdcTile, 0, 0, SRCCOPY
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
    Invoke DeleteDC, hdc
    
    mov eax, hBitmap
    ret
IEMOSBitmap ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileWidth - Returns in eax width of tile.
;------------------------------------------------------------------------------
IEMOSTileWidth PROC USES EBX hIEMOS:DWORD, nTile:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF    

    Invoke IEMOSTileDataEntry, hIEMOS, nTile
    .IF eax == NULL
        ret
    .ENDIF
    mov ebx, eax
    mov eax, [ebx].TILEDATA.TileW
    ret
IEMOSTileWidth ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileHeight - Returns in eax height of tile.
;------------------------------------------------------------------------------
IEMOSTileHeight PROC USES EBX hIEMOS:DWORD, nTile:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF    

    Invoke IEMOSTileDataEntry, hIEMOS, nTile
    .IF eax == NULL
        ret
    .ENDIF
    mov ebx, eax
    mov eax, [ebx].TILEDATA.TileH
    ret
IEMOSTileHeight ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileXCoord - Returns in eax x coord of tile.
;------------------------------------------------------------------------------
IEMOSTileXCoord PROC USES EBX hIEMOS:DWORD, nTile:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF    

    Invoke IEMOSTileDataEntry, hIEMOS, nTile
    .IF eax == NULL
        ret
    .ENDIF
    mov ebx, eax
    mov eax, [ebx].TILEDATA.TileX
    ret
IEMOSTileXCoord ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileYCoord - Returns in eax y coord of tile.
;------------------------------------------------------------------------------
IEMOSTileYCoord PROC USES EBX hIEMOS:DWORD, nTile:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF    

    Invoke IEMOSTileDataEntry, hIEMOS, nTile
    .IF eax == NULL
        ret
    .ENDIF
    mov ebx, eax
    mov eax, [ebx].TILEDATA.TileY
    ret
IEMOSTileYCoord ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileRAW - Returns in eax pointer to RAW tile data.
;------------------------------------------------------------------------------
IEMOSTileRAW PROC USES EBX hIEMOS:DWORD, nTile:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF    

    Invoke IEMOSTileDataEntry, hIEMOS, nTile
    .IF eax == NULL
        ret
    .ENDIF
    mov ebx, eax
    mov eax, [ebx].TILEDATA.TileRAW
    ret
IEMOSTileRAW ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSFileName - returns in eax pointer to zero terminated string contained 
; filename that is open or NULL if not opened
;------------------------------------------------------------------------------
IEMOSFileName PROC USES EBX hIEMOS:DWORD
    LOCAL MosFilename:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEMOS
    lea eax, [ebx].MOSINFO.MOSFilename
    mov MosFilename, eax
    Invoke szLen, MosFilename
    .IF eax == 0
        mov eax, NULL
    .ELSE
        mov eax, MosFilename
    .ENDIF
    ret
IEMOSFileName endp


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSFileNameOnly - returns in eax true or false if it managed to pass to the 
; buffer pointed at lpszFileNameOnly, the stripped filename without extension
;------------------------------------------------------------------------------
IEMOSFileNameOnly PROC hIEMOS:DWORD, lpszFileNameOnly:DWORD
    Invoke IEMOSFileName, hIEMOS
    .IF eax == NULL
        mov eax, FALSE
        ret
    .ENDIF
    
    Invoke MOSJustFname, eax, lpszFileNameOnly
    
    mov eax, TRUE
    ret
IEMOSFileNameOnly endp


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSFileSize - returns in eax size of file or NULL
;------------------------------------------------------------------------------
IEMOSFileSize PROC USES EBX hIEMOS:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSFilesize
    ret
IEMOSFileSize endp


IEMOS_ALIGN
;------------------------------------------------------------------------------
; -1 = No Mos file, TRUE for MOSCV1, FALSE for MOS V1 or MOS V2 
;------------------------------------------------------------------------------
IEMOSFileCompression PROC USES EBX hIEMOS:DWORD
    .IF hIEMOS == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSVersion
    .IF eax == 3
        mov eax, TRUE
    .ELSE
        mov eax, FALSE
    .ENDIF
    ret
IEMOSFileCompression endp


IEMOS_ALIGN
;------------------------------------------------------------------------------
; 0 = No Mos file, 1 = MOS V1, 2 = MOS V2, 3 = MOSCV1 
;------------------------------------------------------------------------------
IEMOSVersion PROC USES EBX hIEMOS:DWORD
    .IF hIEMOS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEMOS
    mov eax, [ebx].MOSINFO.MOSVersion
    ret
IEMOSVersion ENDP



; INTERNAL FUNCTIONS



IEMOS_ALIGN
;******************************************************************************
; Checks the MOS signatures to determine if they are valid and if MOS file is 
; compressed
;******************************************************************************
MOSSignature PROC USES EBX pMOS:DWORD
    ; check signatures to determine version
    mov ebx, pMOS
    mov eax, [ebx]
    .IF eax == ' SOM' ; MOS
        add ebx, 4
        mov eax, [ebx]
        .IF eax == '  1V' ; V1.0
            mov eax, MOS_VERSION_MOS_V10
        .ELSEIF eax == '  2V' ; V2.0
            mov eax, MOS_VERSION_MOS_V20
        .ELSE
            mov eax, MOS_VERSION_INVALID
        .ENDIF

    .ELSEIF eax == 'CSOM' ; MOSC
        add ebx, 4
        mov eax, [ebx]
        .IF eax == '  1V' ; V1.0
            mov eax, MOS_VERSION_MOSCV10
        .ELSE
            mov eax, MOS_VERSION_INVALID
        .ENDIF            
    .ELSE
        mov eax, MOS_VERSION_INVALID
    .ENDIF
    ret
MOSSignature endp


IEMOS_ALIGN
;******************************************************************************
; Uncompresses MOSC file to an area of memory that we allocate for the exact 
; size of data
;******************************************************************************
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
MOSUncompress endp


IEMOS_ALIGN
;******************************************************************************
; Strip path name to just filename Without extention
;******************************************************************************
MOSJustFname PROC szFilePathName:DWORD, szFileName:DWORD
    LOCAL LenFilePathName:DWORD
    LOCAL nPosition:DWORD
    
    Invoke szLen, szFilePathName
    mov LenFilePathName, eax
    mov nPosition, eax
    
    .IF LenFilePathName == 0
        mov byte ptr [edi], 0
        ret
    .ENDIF
    
    mov esi, szFilePathName
    add esi, eax
    
    mov eax, nPosition
    .WHILE eax != 0
        movzx eax, byte ptr [esi]
        .IF al == '\' || al == ':' || al == '/'
            inc esi
            .BREAK
        .ENDIF
        dec esi
        dec nPosition
        mov eax, nPosition
    .ENDW
    mov edi, szFileName
    mov eax, nPosition
    .WHILE eax != LenFilePathName
        movzx eax, byte ptr [esi]
        .IF al == '.' ; stop here
            .BREAK
        .ENDIF
        mov byte ptr [edi], al
        inc edi
        inc esi
        inc nPosition
        mov eax, nPosition
    .ENDW
    mov byte ptr [edi], 0h
    ret
MOSJustFname ENDP


IEMOS_ALIGN
;******************************************************************************
; Returns in eax width of data block as blocksize if column < columns -1
; (column = nTile % columns)
; 
; otherwise returns in eax: imagewidth - (column * blocksize)
;******************************************************************************
MOSGetTileDataWidth PROC USES EBX ECX EDX nTile:DWORD, dwBlockColumns:DWORD, dwBlockSize:DWORD, dwImageWidth:DWORD
    LOCAL COLSmod:DWORD
    
    mov eax, dwBlockColumns
    dec eax
    mov COLSmod, eax
    
    mov eax, dwBlockColumns
    and eax, 1 ; ( a AND (b-1) = mod )
    .IF eax == 0 ; is divisable by 2?
        mov eax, nTile
        and eax, COLSmod ; then use (a AND (b-1)) instead of div to get modulus
        ; eax = column
        .IF eax < COLSmod
            mov eax, dwBlockSize
            ret
        .ENDIF
    .ELSE ; Use div for modulus otherwise
        xor edx, edx
        mov eax, nTile
        mov ecx, dwBlockColumns
        div ecx
        mov eax, edx
        ; eax = column
        .IF eax < COLSmod
            mov eax, dwBlockSize
            ret
        .ENDIF
    .ENDIF
    ; eax is column
    mov ebx, dwBlockSize
    mul ebx
    mov ebx, eax
    mov eax, dwImageWidth
    sub eax, ebx
    ; eax = imagewidth - (columns * blocksize)
    ret
MOSGetTileDataWidth ENDP


IEMOS_ALIGN
;******************************************************************************
; Returns in eax height of data block as blocksize if row < rows -1
; (row = nTile / columns)
;
; otherwise returns in eax: imageheight - (row * blocksize)
;******************************************************************************
MOSGetTileDataHeight PROC USES EBX ECX EDX nTile:DWORD, dwBlockRows:DWORD, dwBlockColumns:DWORD, dwBlockSize:DWORD, dwImageHeight:DWORD
    LOCAL ROWSmod:DWORD
    
    mov eax, dwBlockRows
    dec eax
    mov ROWSmod, eax
    
    ; row = nTile / columns
    xor edx, edx
    mov eax, nTile
    mov ecx, dwBlockColumns
    div ecx
    ; eax is row
    .IF eax < ROWSmod
        mov eax, dwBlockSize
    .ELSE
        ; eax is row
        mov ebx, dwBlockSize
        mul ebx
        mov ebx, eax
        mov eax, dwImageHeight
        sub eax, ebx
        ; eax = imageheight - (row * blocksize)
    .ENDIF
    
    ret
MOSGetTileDataHeight ENDP


IEMOS_ALIGN
;******************************************************************************
; Calc dword aligned size for height or width value
;******************************************************************************
MOSCalcDwordAligned PROC USES ECX EDX dwWidthOrHeight:DWORD
    .IF dwWidthOrHeight == 0
        mov eax, 0
        ret
    .ENDIF
    mov eax, dwWidthOrHeight
    and eax, 1 ; ( a AND (b-1) )
    .IF eax == 0 ; if divisable by 2, use: and eax 3 - to div by 4    
        mov eax, dwWidthOrHeight
        and eax, 3 ; div by 4, get remainder
        add eax, dwWidthOrHeight
    .ELSE ; else use div to get remainder and add to dwWidthOrHeight
        xor edx, edx
        mov eax, dwWidthOrHeight
        mov ecx, 4
        div ecx ;edx contains remainder
        .IF edx != 0
            mov eax, 4
            sub eax, edx
            add eax, dwWidthOrHeight
        .ELSE
            mov eax, dwWidthOrHeight
        .ENDIF
    .ENDIF
    ; eax contains dword aligned value   
    ret
MOSCalcDwordAligned endp


IEMOS_ALIGN
;******************************************************************************

;******************************************************************************
MOSTileDataRAWtoBMP PROC USES EBX EDI ESI pTileRAW:DWORD, pTileBMP:DWORD, dwTileSizeRAW:DWORD, dwTileSizeBMP:DWORD
    
    
    ret
MOSTileDataRAWtoBMP ENDP


IEMOS_ALIGN
;******************************************************************************
; Returns in eax handle to tile data bitmap or NULL
;******************************************************************************
MOSTileDataBitmap PROC USES EBX dwTileWidth:DWORD, dwTileHeight:DWORD, pTileBMP:DWORD, dwTileSizeBMP:DWORD, pTilePalette:DWORD
    LOCAL hdc:DWORD
    LOCAL TileBitmapHandle:DWORD
    Invoke RtlZeroMemory, Addr MOSTileBitmap, (SIZEOF BITMAPINFOHEADER + 1024)

    lea ebx, MOSTileBitmap
    mov [ebx].BITMAPINFOHEADER.biSize, 40d
    mov eax, dwTileWidth
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
    
    Invoke CreateDC, Addr szMOSDisplayDC, NULL, NULL, NULL
    ;Invoke GetDC, NULL
    mov hdc, eax
    Invoke CreateDIBitmap, hdc, Addr MOSTileBitmap, CBM_INIT, pTileBMP, Addr MOSTileBitmap, DIB_RGB_COLORS
    .IF eax == NULL
        IFDEF DEBUG32
            PrintText 'CreateDIBitmap Failed'
        ENDIF
    .ENDIF
    mov TileBitmapHandle, eax
    Invoke DeleteDC, hdc
    ;Invoke ReleaseDC, NULL, hdc
    mov eax, TileBitmapHandle
    ret
MOSTileDataBitmap ENDP


IEMOS_ALIGN
;******************************************************************************
; Returns in eax total tiles.
;******************************************************************************
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



END







