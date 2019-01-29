;==============================================================================
;
; IEBIF
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
;
; 29/11/2015 - reorg source files to split into different objs to allow 
;              IEBIF.lib to have better support for separate modules if linking 
;              to other projects that use only a subset of the libraries 
;              functions.
;
;
;
;
;
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
include masm32.inc
include zlibstat.inc

includelib kernel32.lib
includelib user32.lib
includelib masm32.lib
includelib zlibstat128.lib
;includelib zlib-ng.lib

include IEBIF.inc

;DEBUG32 EQU 1
;IFDEF DEBUG32
;    PRESERVEXMMREGS equ 1
;    includelib M:\Masm32\lib\Debug32.lib
;    DBG32LIB equ 1
;    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
;    include M:\Masm32\include\debug32.inc
;ENDIF


EXTERNDEF BIFSignature      :PROTO :DWORD
EXTERNDEF BIFUncompressBIF_ :PROTO :DWORD, :DWORD
EXTERNDEF BIFUncompressBIFC :PROTO :DWORD, :DWORD
EXTERNDEF BIFJustFname      :PROTO :DWORD, :DWORD

BIFCalcLargeFileView    PROTO :DWORD, :DWORD, :DWORD, :DWORD
BIFOpenLargeMapView     PROTO :DWORD, :DWORD, :DWORD
BIFCloseLargeMapView    PROTO :DWORD
;BIFFileData             PROTO :DWORD, :DWORD            ; hIEBIF, nFileEntry. Returns in eax pointer to File data
;BIFTileData             PROTO :DWORD, :DWORD            ; hIEBIF, nTileEntry. Returns in eax pointer to Tile data



IFNDEF BIF_HEADER_V1
BIF_HEADER_V1           STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('BIFF')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V1 ')
    FileEntriesCount    DD 0 ; 0x0008   4 (dword)       Count of file entries
    TileEntriesCount    DD 0 ; 0x000c   4 (dword)       Count of tile entries
    OffsetFileEntries   DD 0 ; 0x0010   4 (dword)       Offset (from start of file) to file entries
BIF_HEADER_V1           ENDS
ENDIF

IFNDEF BIF_HEADER_V11 ; witcher etc
BIF_HEADER_V11          STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('BIFF')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V1.1')
    FileEntriesCount    DD 0 ; 0x0008   4 (dword)       Count of resource (file) entries
    TileEntriesCount    DD 0 ; 0x000c   4 (dword)       NULL - not used
    OffsetFileEntries   DD 0 ; 0x0010   4 (dword)       Offset (from start of file) to resource (file) table
BIF_HEADER_V11          ENDS
ENDIF

IFNDEF BIF__HEADER
BIF__HEADER             STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('BIF ')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V1.0')
    FilenameLength      DD 0 ; 0x0008   2 (word)        Length of ascii filename of bif filename
    Filename            DD 0 ; 0x000a   x bytes         ascii filename using x bytes as defined in field above
BIF__HEADER             ENDS
ENDIF

IFNDEF BIF__HEADER_DATA
; Filename offset + filename length points to BIF__HEADER_DATA
BIF__HEADER_DATA        STRUCT
    UncompressedSize    DD 0 ; 0x0000   4 (dword)       Uncompressed data length
    CompressedSize      DD 0 ; 0x0004   4 (dword)       Compressed data length
    CompressedData      DD 0 ; 0x0008   4 (dword)       this is start of compressed data at this location.
BIF__HEADER_DATA        ENDS
ENDIF

IFNDEF BIFC_HEADER
BIFC_HEADER             STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('BIFC')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V1.0')
    UncompressedSize    DD 0 ; 0x0008   4 (dword)       Uncompressed BIF size
BIFC_HEADER             ENDS
ENDIF

IFNDEF BIFC_BLOCK
BIFC_BLOCK              STRUCT
    UncompressedSize    DD 0
    CompressedSize      DD 0
    CompressedData      DD 0
BIFC_BLOCK              ENDS
ENDIF

IFNDEF FILE_ENTRY
FILE_ENTRY              STRUCT
    ResourceLocator     DD 0 ; 0x0000   4 (dword)       Resource locator. The IE resource manager uses 32-bit values as a 'resource index', which codifies the source of the resource as well as which source it refers to. The layout of this value is below. bits 31-20: source index (the ordinal value giving the index of the corresponding BIF entry) bits 19-14: tileset index bits 13- 0: non-tileset file index (any 12 bit value, so long as it matches the value used in the BIF file)
    ResourceOffset      DD 0 ; 0x0004   4 (dword)       Offset (from start of file) to resource data (file data)
    ResourceSize        DD 0 ; 0x0008   4 (dword)       Size of this resource
    ResourceType        DW 0 ; 0x000c   2 (word)        Resource type
    Unknown             DW 0 ; 0x000e   2 (word)        Unknown
FILE_ENTRY              ENDS
ENDIF

IFNDEF FILE_ENTRY_V11 ; for BIF V1.1
FILE_ENTRY_V11          STRUCT
    ResourceLocator     DD 0 ; 0x0000   4 (dword)       Resource locator. The IE resource manager uses 32-bit values as a 'resource index', which codifies the source of the resource as well as which source it refers to. The layout of this value is below. bits 31-20: source index (the ordinal value giving the index of the corresponding BIF entry) bits 19-14: tileset index bits 13- 0: non-tileset file index (any 12 bit value, so long as it matches the value used in the BIF file)
    ResourceFlags       DD 0 ; 0x0004   4 (dword)       Flags (BIF index is now in this value, (flags & 0xFFF00000) >> 20). The rest appears to define 'fixed' index. 
    ResourceOffset      DD 0 ; 0x0008   4 (dword)       Offset (from start of file) to resource data (file data)
    ResourceSize        DD 0 ; 0x000C   4 (dword)       Size of this resource
    ResourceType        DW 0 ; 0x000E   2 (word)        Resource type
    Unknown             DW 0 ; 0x0010   2 (word)        NULL
FILE_ENTRY_V11          ENDS
ENDIF

IFNDEF TILE_ENTRY
TILE_ENTRY              STRUCT
    ResourceLocator     DD 0 ; 0x0000   4 (dword)       Resource locator. The IE resource manager uses 32-bit values as a 'resource index', which codifies the source of the resource as well as which source it refers to. The layout of this value is below. bits 31-20: source index (the ordinal value giving the index of the corresponding BIF entry) bits 19-14: tileset index bits 13- 0: non-tileset file index (any 12 bit value, so long as it matches the value used in the BIF file)
    ResourceOffset      DD 0 ; 0x0004   4 (dword)       Offset (from start of file) to resource data (tile data)
    TilesCount          DD 0 ; 0x0008   4 (dword)       Count of tiles in this resource
    TileSize            DD 0 ; 0x000c   4 (dword)       Size of each tile in this resource
    ResourceType        DW 0 ; 0x0010   2 (word)        Resource type
    Unknown             DW 0 ; 0x0012   2 (word)        Unknown
TILE_ENTRY              ENDS
ENDIF

IFNDEF TISV1_HEADER_FOR_BIF_FOR_BIF
TISV1_HEADER_FOR_BIF    STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('TIS ')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V1  ')
    TilesCount          DD 0 ; 0x0008   4 (dword)       Count of tiles within this tileset
    TilesSectionLength  DD 0 ; 0x000c   4 (dword)       Length of tiles section *
    OffsetTilesData     DD 0 ; 0x0010   4 (dword)       Tile header size, offset to tiles, always 24d
    TileDimension       DD 0 ; 0x0014   4 (dword)       Dimension of 1 tile in pixels (64x64) 64 ?
TISV1_HEADER_FOR_BIF    ENDS
ENDIF

IFNDEF BIFINFO
BIFINFO                 STRUCT
    BIFOpenMode         DD 0
    BIFFilename         DB MAX_PATH DUP (0)
    BIFFilesize         DD 0
    BIFFilesizeHigh     DD 0
    BIFVersion          DD 0
    BIFHeaderPtr        DD 0
    BIFHeaderSize       DD 0
    BIFFileEntriesPtr   DD 0
    BIFFileEntriesSize  DD 0
    BIFTileEntriesPtr   DD 0
    BIFTileEntriesSize  DD 0
    ;BIFFileBifInfoExPtr     DD 0 ; custom mem alloc'd for resource names found in key file
    ;BIFFileBifInfoExSize    DD 0 ; custom mem size for alloc'd for resource names found in key file
    ;BIFTileBifInfoExPtr     DD 0
    ;BIFTileBifInfoExSize    DD 0
    BIFFileDataPtr      DD 0 ; BIFFILEDATA array each entry corresponds to bif file entry and its data alloc'd in memory
    BIFTileDataPtr      DD 0 ; BIFTILEDATA array each entry corresponds to bif tile entry and its data alloc'd in memory
    BIFMemMapPtr        DD 0
    BIFMemMapHandle     DD 0
    BIFFileHandle       DD 0
    BIFLargeMapping     DD 0
    BIFLargeMapView     DD 0
BIFINFO                 ENDS
ENDIF

IFNDEF BIFINFOEX
BIFINFOEX               STRUCT
    ResourceName        DB 32 DUP (0) ; incorporates name and extension (type) once filled in (last byte used to determine if chr or eff file used
    ResourceType        DB 12 DUP (0) ; string of resource type
    ResourceSize        DB 36 DUP (0) ; string of resource size (file or tile. Tiles show size x count as well)
    ResourceIndex       DB 16 DUP (0) ; string of resource index
    ResourceLocator     DB 16 DUP (0) ; string of resource locator
    ResourceOffset      DB 16 DUP (0) ; string of resource offset
BIFINFOEX               ENDS
ENDIF

IFNDEF BIFFILEDATA
BIFFILEDATA             STRUCT
    FileData            DD 0
BIFFILEDATA             ENDS
ENDIF

IFNDEF BIFTILEDATA
BIFTILEDATA             STRUCT
    TileData            DD 0
BIFTILEDATA             ENDS
ENDIF


.CONST
; Open Modes:
IEMODE_WRITE            EQU 0
IEMODE_READONLY         EQU 1

.DATA
TISV1Header             TISV1_HEADER_FOR_BIF <" SIT", "  1V", 0, 0, 24d, 64d>
BIFFV1Header            db "BIFFV1  ",0
BIFFV11Header           db "BIFFV1.1",0
BIFCHeader              db "BIF V1.0",0
BIFCV1Header            db "BIFCV1.0",0
BIFXHeader              db 12 dup (0)
KEYExt                  db ".key",0
szHex                   db '0x',0
szWitcherVoices_        db 'voices_',0
szWitcherLang_          db 'lang_',0
szChitinKey             db 'chitin.key',0
szMainKey               db 'main.key',0
szModKey                db 'mod.key',0
szBackslash             db '\',0


.CODE


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; IEBIFOpen - Returns handle in eax of opened bif file. NULL if could not alloc enough mem
;-------------------------------------------------------------------------------------
IEBIFOpen PROC USES EBX lpszBifFilename:DWORD, dwOpenMode:DWORD
    LOCAL hIEBIF:DWORD
    LOCAL hBIFFile:DWORD
    LOCAL BIFFilesize:DWORD
    LOCAL BIFFilesizeHigh:DWORD
    LOCAL SigReturn:DWORD
    LOCAL BIFMemMapHandle:DWORD
    LOCAL BIFMemMapPtr:DWORD
    LOCAL pBIF:DWORD
    LOCAL BIFLargeMapping:DWORD

    .IF dwOpenMode == IEMODE_READONLY ; readonly
        Invoke CreateFile, lpszBifFilename, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ELSE ; IEMODE_WRITE
        Invoke CreateFile, lpszBifFilename, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ENDIF

    .IF eax == INVALID_HANDLE_VALUE
        mov eax, NULL
        ret
    .ENDIF
    mov hBIFFile, eax
    mov BIFLargeMapping, FALSE

    Invoke GetFileSize, hBIFFile, Addr BIFFilesizeHigh
    mov BIFFilesize, eax
    .IF BIFFilesize == 0 && BIFFilesizeHigh == 0
        Invoke CloseHandle, hBIFFile
        mov eax, NULL
        ret
    .ENDIF        
    
    
    ; 536870912 = 20000000h | 268435456 = 10000000h 2^28 = 268,435,456 bytes = 268MB
    ;---------------------------------------------------                
    ; File Mapping: Create file mapping for main .bif
    ;---------------------------------------------------
    .IF dwOpenMode == IEMODE_READONLY ; readonly
        Invoke CreateFileMapping, hBIFFile, NULL, PAGE_READONLY, 0, 0, NULL ; Create memory mapped file
    .ELSE
        Invoke CreateFileMapping, hBIFFile, NULL, PAGE_READWRITE, 0, 0, NULL ; Create memory mapped file
    .ENDIF   
    .IF eax == NULL
        ;PrintText 'Mapping Failed'
        Invoke CloseHandle, hBIFFile
        mov eax, NULL
        ret
    .ENDIF
    mov BIFMemMapHandle, eax
    
    .IF BIFFilesize > 20000000h || BIFFilesizeHigh > 0 ; 2^29 = 536870912 = 536,870,912 bytes = 536MB
    ;.IF BIFFilesize > 10000000h || BIFFilesizeHigh > 0 ; 2^28 = 268435456 = 268,435,456 bytes = 268MB
        Invoke IEBIFLargeFileMapping, hBIFFile, BIFMemMapHandle, BIFFilesize, BIFFilesizeHigh, dwOpenMode, Addr BIFLargeMapping
        .IF eax == NULL
            Invoke CloseHandle, BIFMemMapHandle
            Invoke CloseHandle, hBIFFile
            mov eax, NULL
            ret
            ; otherwise we have a MemMapHandle to save
        .ENDIF
    .ELSE
        .IF dwOpenMode == IEMODE_READONLY ; readonly
            Invoke MapViewOfFileEx, BIFMemMapHandle, FILE_MAP_READ, 0, 0, 0, NULL
        .ELSE
            Invoke MapViewOfFileEx, BIFMemMapHandle, FILE_MAP_ALL_ACCESS, 0, 0, 0, NULL
        .ENDIF
        .IF eax == NULL
            Invoke IEBIFLargeFileMapping, hBIFFile, BIFMemMapHandle, BIFFilesize, BIFFilesizeHigh, dwOpenMode, Addr BIFLargeMapping
            .IF eax == NULL
                Invoke CloseHandle, BIFMemMapHandle
                Invoke CloseHandle, hBIFFile
                mov eax, NULL
                ret
                ; otherwise we have a MemMapHandle to save
            .ENDIF
        .ENDIF
    .ENDIF
    mov BIFMemMapPtr, eax

    Invoke BIFSignature, BIFMemMapPtr ;hBIFFile
    mov SigReturn, eax

    .IF SigReturn == BIF_VERSION_INVALID ; not a valid bif file
        Invoke UnmapViewOfFile, BIFMemMapPtr
        Invoke CloseHandle, BIFMemMapHandle
        Invoke CloseHandle, hBIFFile
        mov eax, NULL
        ret    

    .ELSEIF SigReturn == BIF_VERSION_BIFFV10 || SigReturn == BIF_VERSION_BIFFV11; BIFF V1.0 or BIFF V1.1
        Invoke IEBIFMem, BIFMemMapPtr, lpszBifFilename, BIFFilesize, BIFFilesizeHigh, dwOpenMode, BIFLargeMapping
        .IF eax == NULL
            Invoke UnmapViewOfFile, BIFMemMapPtr
            Invoke CloseHandle, BIFMemMapHandle
            Invoke CloseHandle, hBIFFile
            mov eax, NULL
            ret    
        .ENDIF
        mov hIEBIF, eax
        .IF dwOpenMode == IEMODE_WRITE ; write (default)
            Invoke UnmapViewOfFile, BIFMemMapPtr
            Invoke CloseHandle, BIFMemMapHandle
            Invoke CloseHandle, hBIFFile
        .ELSE ; else readonly, so keep mapping around till we close file
            mov ebx, hIEBIF
            mov eax, BIFMemMapHandle
            mov [ebx].BIFINFO.BIFMemMapHandle, eax
            mov eax, hBIFFile
            mov [ebx].BIFINFO.BIFFileHandle, eax
        .ENDIF

    .ELSEIF SigReturn == BIF_VERSION_BIF_V10  ; BIF_V1.0
        Invoke BIFUncompressBIF_, BIFMemMapPtr, Addr BIFFilesize
        .IF eax == 0
            ;PrintText 'Failed to uncompress BIF V1.0'
            Invoke UnmapViewOfFile, BIFMemMapPtr
            Invoke CloseHandle, BIFMemMapHandle
            Invoke CloseHandle, hBIFFile        
            mov eax, NULL
            ret
        .ENDIF
        mov pBIF, eax ; save uncompressed location to this var
        ;PrintText 'Uncompressed BIF V1.0'
        Invoke UnmapViewOfFile, BIFMemMapPtr
        Invoke CloseHandle, BIFMemMapHandle
        Invoke CloseHandle, hBIFFile
        Invoke IEBIFMem, pBIF, lpszBifFilename, BIFFilesize, BIFFilesizeHigh, dwOpenMode, BIFLargeMapping
        .IF eax == NULL
            ;PrintText 'IEBIFMem Failed'
            .IF pBIF != NULL
                Invoke GlobalFree, pBIF
            .ENDIF
            mov eax, NULL
            ret
        .ENDIF
        mov hIEBIF, eax
        ;PrintText 'IEBIFMem Ok'

    .ELSEIF SigReturn == BIF_VERSION_BIFCV10 ; BIFCV1.0
        Invoke BIFUncompressBIFC, BIFMemMapPtr, Addr BIFFilesize
        .IF eax == 0
            Invoke UnmapViewOfFile, BIFMemMapPtr
            Invoke CloseHandle, BIFMemMapHandle
            Invoke CloseHandle, hBIFFile        
            mov eax, NULL
            ret
        .ENDIF
        mov pBIF, eax ; save uncompressed location to this var
        Invoke UnmapViewOfFile, BIFMemMapPtr
        Invoke CloseHandle, BIFMemMapHandle
        Invoke CloseHandle, hBIFFile        
        Invoke IEBIFMem, pBIF, lpszBifFilename, BIFFilesize, BIFFilesizeHigh, dwOpenMode, Addr BIFLargeMapping
         .IF eax == NULL
            .IF pBIF != NULL
                Invoke GlobalFree, pBIF
            .ENDIF
            mov eax, NULL
            ret
        .ENDIF
        mov hIEBIF, eax

    .ELSE ; Not currently supported/implemented
        Invoke UnmapViewOfFile, BIFMemMapPtr
        Invoke CloseHandle, BIFMemMapHandle
        Invoke CloseHandle, hBIFFile
        mov eax, NULL
        ret
    .ENDIF

    ; save original version to handle for later use so we know if orignal file opened was standard BIFF or a compressed BIF_ or BIFC file, if 0 then it was in mem so we assume BIFF
    mov ebx, hIEBIF
    mov eax, SigReturn
    mov [ebx].BIFINFO.BIFVersion, eax
    mov eax, hIEBIF
    ret
IEBIFOpen ENDP


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; IEBIFLargeFileMapping - For files close to 1GB or higher normal memory mapping will
; fail - so we need to attempt to do the following:
;
; Map memory of 4k
; Read header, verify it is a BIF V1 or BIF V1.1 file, if not then fail and fall out
; If a bif file, calc mem granularity and size of header + file entry table + tile entry table
; Get new amount to map to cover this large header
; unmap 4k view
; map new large header view
; For IEBIFFileData, IEBIFTileData, IEBIFResPeekFileSignature, IEBIFExtractFile, IEBIFExtractTile
; set a flag which when these functions are called they calc offsets for mapping on the fly
; for the required data. 
;-------------------------------------------------------------------------------------
IEBIFLargeFileMapping PROC USES EBX EDX hBIFLargeFileToMap:DWORD, LargeBifMemMapHandle:DWORD, dwBIFFilesize:DWORD, dwBIFFilesizeHigh:DWORD, dwOpenMode:DWORD, lpdwBIFLargeMapping:DWORD
    LOCAL sysinfo:SYSTEM_INFO
    LOCAL dwAllocationGranularity:DWORD
    LOCAL LargeBifMemMapPtr:DWORD
    LOCAL Version:DWORD
    LOCAL BIFHeaderPtr:DWORD
    LOCAL TotalFileEntries:DWORD
    LOCAL TotalTileEntries:DWORD
    LOCAL FileEntriesSize:DWORD
    LOCAL TileEntriesSize:DWORD
    LOCAL OffsetFileEntries:DWORD
    LOCAL LargeBifHeaderSize:DWORD
    LOCAL dwAdjustedLargeBifHeaderSize:DWORD

    Invoke GetSystemInfo, Addr sysinfo
    mov eax, sysinfo.dwAllocationGranularity
    mov dwAllocationGranularity, eax
    
    .IF dwOpenMode == 1 ; readonly
        Invoke MapViewOfFileEx, LargeBifMemMapHandle, FILE_MAP_READ, 0, 0, dwAllocationGranularity, NULL
    .ELSE
        Invoke MapViewOfFileEx, LargeBifMemMapHandle, FILE_MAP_ALL_ACCESS, 0, 0, dwAllocationGranularity, NULL
    .ENDIF
    .IF eax == NULL
        ;Invoke CloseHandle, LargeBifMemMapHandle
        ;Invoke CloseHandle, hBIFFile
        mov ebx, lpdwBIFLargeMapping
        mov eax, FALSE
        mov [ebx], eax
        mov eax, NULL
        ret
    .ENDIF
    mov LargeBifMemMapPtr, eax
    mov BIFHeaderPtr, eax
    
    Invoke BIFSignature, LargeBifMemMapPtr ;hBIFFile
    mov Version, eax
    .IF Version == 1 || Version == 4; BIFF V1.0 or BIFF V1.1

        mov ebx, BIFHeaderPtr
        mov eax, [ebx].BIF_HEADER_V1.FileEntriesCount
        mov TotalFileEntries, eax
        .IF Version == 4 ; BIFF V1.1
            mov TotalTileEntries, 0
        .ELSE
            mov eax, [ebx].BIF_HEADER_V1.TileEntriesCount
            mov TotalTileEntries, eax
        .ENDIF
        mov eax, [ebx].BIF_HEADER_V1.OffsetFileEntries
        mov OffsetFileEntries, eax
        ;mov eax, [ebx].BIF_HEADER_V1.OffsetResEntries
        ;mov OffsetResEntries, eax
        
        mov eax, TotalFileEntries
        .IF Version == 4 ; BIFF V1.1
            mov ebx, SIZEOF FILE_ENTRY_V11
        .ELSE
            mov ebx, SIZEOF FILE_ENTRY
        .ENDIF
        mul ebx
        mov FileEntriesSize, eax
        
        .IF Version == 4 ; BIFF V1.1
            mov TileEntriesSize, 0
        .ELSE
            mov eax, TotalTileEntries
            mov ebx, SIZEOF TILE_ENTRY
            mul ebx
            mov TileEntriesSize, eax
        .ENDIF

        ; calc size
        mov eax, OffsetFileEntries
        add eax, FileEntriesSize
        add eax, TileEntriesSize
        mov LargeBifHeaderSize, eax
        mov dwAdjustedLargeBifHeaderSize, eax
        
        mov eax, LargeBifHeaderSize
        xor edx, edx
        mov ebx, dwAllocationGranularity
        div ebx ; Divides LargeBifHeaderSize by dwAllocationGranularity. EAX = quotient and EDX = remainder (modulo).
        .IF edx > 0 ; we have a remainder, so calc to add dwAllocationGranularity to LargeBifHeaderSize - remainder
            mov ebx, LargeBifHeaderSize
            sub ebx, edx
            add ebx, dwAllocationGranularity
            mov dwAdjustedLargeBifHeaderSize, ebx 
        .ENDIF
        Invoke UnmapViewOfFile, LargeBifMemMapPtr ; close map as we dont need it now
        ; check LargeBifHeaderSize is ok with allocation granularity
        
        .IF dwOpenMode == 1 ; readonly
            Invoke MapViewOfFileEx, LargeBifMemMapHandle, FILE_MAP_READ, 0, 0, dwAdjustedLargeBifHeaderSize, NULL
        .ELSE
            Invoke MapViewOfFileEx, LargeBifMemMapHandle, FILE_MAP_ALL_ACCESS, 0, 0, dwAdjustedLargeBifHeaderSize, NULL
        .ENDIF
        .IF eax == NULL
            mov ebx, lpdwBIFLargeMapping
            mov eax, FALSE
            mov [ebx], eax        
            mov eax, NULL
            ret
        .ENDIF
        mov LargeBifMemMapPtr, eax
        mov ebx, lpdwBIFLargeMapping
        mov eax, TRUE
        mov [ebx], eax
        mov eax, LargeBifMemMapPtr
        ret
        
    .ELSE
        Invoke UnmapViewOfFile, LargeBifMemMapPtr
        mov ebx, lpdwBIFLargeMapping
        mov eax, FALSE
        mov [ebx], eax           
        mov eax, NULL
        ret
    .ENDIF
    ret
IEBIFLargeFileMapping endp


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; IEBIFMem - Returns handle in eax of opened bif file that is already loaded into memory. NULL if could not alloc enough mem
;-------------------------------------------------------------------------------------
IEBIFMem PROC USES EBX pBIFInMemory:DWORD, lpszBifFilename:DWORD, dwBifFilesize:DWORD, dwBIFFilesizeHigh:DWORD, dwOpenMode:DWORD, dwBIFLargeMapping:DWORD
    LOCAL hIEBIF:DWORD
    LOCAL BIFMemMapPtr:DWORD
    LOCAL TotalFileEntries:DWORD
    LOCAL TotalTileEntries:DWORD
    LOCAL FileEntriesSize:DWORD
    LOCAL TileEntriesSize:DWORD
    LOCAL OffsetFileEntries:DWORD
    LOCAL OffsetTileEntries:DWORD
    ;LOCAL FileBifInfoExSize:DWORD
    ;LOCAL TileBifInfoExSize:DWORD
    LOCAL Version:DWORD
    
    mov eax, pBIFInMemory
    mov BIFMemMapPtr, eax       

    ;----------------------------------
    ; Alloc mem for our IEBIF Handle
    ;----------------------------------
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF BIFINFO
    .IF eax == NULL
        ret
    .ENDIF
    mov hIEBIF, eax
    
    mov ebx, hIEBIF
    mov eax, dwOpenMode
    mov [ebx].BIFINFO.BIFOpenMode, eax
    mov eax, BIFMemMapPtr
    mov [ebx].BIFINFO.BIFMemMapPtr, eax
    
    lea eax, [ebx].BIFINFO.BIFFilename
    Invoke szCopy, lpszBifFilename, eax
    
    mov ebx, hIEBIF
    mov eax, dwBifFilesize
    mov [ebx].BIFINFO.BIFFilesize, eax
    mov eax, dwBIFFilesizeHigh
    mov [ebx].BIFINFO.BIFFilesizeHigh, eax
    mov eax, dwBIFLargeMapping
    mov [ebx].BIFINFO.BIFLargeMapping, eax

    ;mov eax, 1
    ;mov [ebx].BIFINFO.BIFVersion, eax ; version is handled outside this routine, or if its 0 we opened the bif in mem already, like a new file, so treat it as version BIFF
    
    ;----------------------------------
    ; BIF Header
    ;----------------------------------
    .IF dwOpenMode == IEMODE_WRITE
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF BIF_HEADER_V1
        .IF eax == NULL
            Invoke GlobalFree, hIEBIF
            mov eax, NULL
            ret
        .ENDIF    
        mov ebx, hIEBIF
        mov [ebx].BIFINFO.BIFHeaderPtr, eax
        mov ebx, BIFMemMapPtr
        Invoke RtlMoveMemory, eax, ebx, SIZEOF BIF_HEADER_V1
    .ELSE
        mov ebx, hIEBIF
        mov eax, BIFMemMapPtr
        mov [ebx].BIFINFO.BIFHeaderPtr, eax
    .ENDIF
    mov ebx, hIEBIF
    mov eax, SIZEOF BIF_HEADER_V1
    mov [ebx].BIFINFO.BIFHeaderSize, eax   


    Invoke BIFSignature, pBIFInMemory
    mov Version, eax
    .IF Version == BIF_VERSION_BIFFV10 || Version == BIF_VERSION_BIFFV11
    .ELSE
        ; added 07/01/2019
        .IF dwOpenMode == IEMODE_WRITE
            mov ebx, hIEBIF
            mov eax, [ebx].BIFINFO.BIFHeaderPtr
            .IF eax != 0
                Invoke GlobalFree, eax
            .ENDIF
        .ENDIF
        Invoke GlobalFree, hIEBIF
        mov eax, NULL    
        ret
    .ENDIF

    ;----------------------------------
    ; File & Tile Counts, Offsets & Sizes
    ;----------------------------------
    mov ebx, [ebx].BIFINFO.BIFHeaderPtr
    mov eax, [ebx].BIF_HEADER_V1.FileEntriesCount
    mov TotalFileEntries, eax
    .IF Version == BIF_VERSION_BIFFV11 ; BIFF V1.1
        mov TotalTileEntries, 0
    .ELSE
        mov eax, [ebx].BIF_HEADER_V1.TileEntriesCount
        mov TotalTileEntries, eax
    .ENDIF
    mov eax, [ebx].BIF_HEADER_V1.OffsetFileEntries
    mov OffsetFileEntries, eax
    ;mov eax, [ebx].BIF_HEADER_V1.OffsetResEntries
    ;mov OffsetResEntries, eax
    
    mov eax, TotalFileEntries
    .IF Version == BIF_VERSION_BIFFV11 ; BIFF V1.1
        mov ebx, SIZEOF FILE_ENTRY_V11
    .ELSE
        mov ebx, SIZEOF FILE_ENTRY
    .ENDIF
    mul ebx
    mov FileEntriesSize, eax
    
    .IF Version == BIF_VERSION_BIFFV11 ; BIFF V1.1
        mov TileEntriesSize, 0
    .ELSE
        mov eax, TotalTileEntries
        mov ebx, SIZEOF TILE_ENTRY
        mul ebx
        mov TileEntriesSize, eax
    .ENDIF
    
    mov eax, FileEntriesSize
    add eax, OffsetFileEntries ;SIZEOF BIF_HEADER_V1
    mov OffsetTileEntries, eax

    ;----------------------------------
    ; File Entries
    ;----------------------------------
    .IF TotalFileEntries > 0
        .IF dwOpenMode == IEMODE_WRITE
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, FileEntriesSize
            .IF eax == NULL
                ; added 07/01/2019
                mov ebx, hIEBIF
                mov eax, [ebx].BIFINFO.BIFHeaderPtr
                .IF eax != 0
                    Invoke GlobalFree, eax
                .ENDIF
                Invoke GlobalFree, hIEBIF
                mov eax, NULL    
                ret
            .ENDIF    
            mov ebx, hIEBIF
            mov [ebx].BIFINFO.BIFFileEntriesPtr, eax
        
            mov ebx, BIFMemMapPtr
            add ebx, OffsetFileEntries
            Invoke RtlMoveMemory, eax, ebx, FileEntriesSize
        .ELSE
            mov ebx, hIEBIF
            mov eax, BIFMemMapPtr
            add eax, OffsetFileEntries
            mov [ebx].BIFINFO.BIFFileEntriesPtr, eax
        .ENDIF
        mov ebx, hIEBIF
        mov eax, FileEntriesSize
        mov [ebx].BIFINFO.BIFFileEntriesSize, eax    
    .ELSE
        mov ebx, hIEBIF
        mov [ebx].BIFINFO.BIFFileEntriesPtr, 0
        mov [ebx].BIFINFO.BIFFileEntriesSize, 0
    .ENDIF
    
    ;----------------------------------
    ; Tile Entries
    ;----------------------------------
    .IF TotalTileEntries > 0
        .IF dwOpenMode == IEMODE_WRITE
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, TileEntriesSize
            .IF eax == NULL
                mov ebx, hIEBIF
                mov eax, [ebx].BIFINFO.BIFFileEntriesPtr
                .IF eax != 0
                    Invoke GlobalFree, eax
                .ENDIF
                mov ebx, hIEBIF
                mov eax, [ebx].BIFINFO.BIFHeaderPtr
                .IF eax != 0
                    Invoke GlobalFree, eax
                .ENDIF   
                Invoke GlobalFree, hIEBIF
                mov eax, NULL    
                ret
            .ENDIF    
            mov ebx, hIEBIF
            mov [ebx].BIFINFO.BIFTileEntriesPtr, eax
            mov ebx, BIFMemMapPtr
            add ebx, OffsetTileEntries
            Invoke RtlMoveMemory, eax, ebx, TileEntriesSize
        .ELSE
            mov ebx, hIEBIF
            mov eax, BIFMemMapPtr
            add eax, OffsetTileEntries
            mov [ebx].BIFINFO.BIFTileEntriesPtr, eax
        .ENDIF
        mov ebx, hIEBIF
        mov eax, TileEntriesSize
        mov [ebx].BIFINFO.BIFTileEntriesSize, eax
    .ELSE
        mov ebx, hIEBIF
        mov [ebx].BIFINFO.BIFTileEntriesPtr, 0
        mov [ebx].BIFINFO.BIFTileEntriesSize, 0
    .ENDIF
    mov eax, hIEBIF
    ret
IEBIFMem ENDP


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; IEBIFClose - Frees memory used by control data structure
;-------------------------------------------------------------------------------------
IEBIFClose PROC USES EBX hIEBIF:DWORD
    .IF hIEBIF == NULL
        mov eax, 0
        ret
    .ENDIF

    mov ebx, hIEBIF
    mov eax, [ebx].BIFINFO.BIFOpenMode
    .IF eax == IEMODE_WRITE ; Write Mode
        mov ebx, hIEBIF
        mov eax, [ebx].BIFINFO.BIFHeaderPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
    
        mov ebx, hIEBIF
        mov eax, [ebx].BIFINFO.BIFFileEntriesPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
    
        mov ebx, hIEBIF
        mov eax, [ebx].BIFINFO.BIFTileEntriesPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
    .ENDIF
    
    mov ebx, hIEBIF
    mov eax, [ebx].BIFINFO.BIFVersion
    .IF eax == BIF_VERSION_INVALID ; non BIFF
        ; do nothing

    .ELSEIF eax == BIF_VERSION_BIFFV10 || eax == BIF_VERSION_BIFFV11 ; BIFF - straight raw biff, so if  opened in readonly, unmap file, otherwise free mem
        mov ebx, hIEBIF
        mov eax, [ebx].BIFINFO.BIFOpenMode
        .IF eax == IEMODE_READONLY ; Read Only
            mov ebx, hIEBIF
            mov eax, [ebx].BIFINFO.BIFMemMapPtr
            .IF eax != NULL
                Invoke UnmapViewOfFile, eax
            .ENDIF

            mov ebx, hIEBIF
            mov eax, [ebx].BIFINFO.BIFMemMapHandle
            .IF eax != NULL
                Invoke CloseHandle, eax
            .ENDIF

            mov ebx, hIEBIF
            mov eax, [ebx].BIFINFO.BIFFileHandle
            .IF eax != NULL
                Invoke CloseHandle, eax
            .ENDIF

        .ELSE ; free mem if write mode IEMODE_WRITE
            mov ebx, hIEBIF
            mov eax, [ebx].BIFINFO.BIFMemMapPtr
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF
        .ENDIF
    .ELSE ; BIF_ or BIFC in read or write mode uncompresed biff in memory needs to be cleared
        mov ebx, hIEBIF
        mov eax, [ebx].BIFINFO.BIFMemMapPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
    .ENDIF
    
    mov eax, hIEBIF
    .IF eax != NULL
        Invoke GlobalFree, eax
    .ENDIF
    mov eax, 0
    ret
IEBIFClose ENDP


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; IEBIFHeader - Returns in eax a pointer to header or NULL if not valid
;-------------------------------------------------------------------------------------
IEBIFHeader PROC USES EBX hIEBIF:DWORD
    .IF hIEBIF == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEBIF
    mov eax, [ebx].BIFINFO.BIFHeaderPtr
    ret
IEBIFHeader ENDP


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; IEBIFFileEntry - Returns in eax a pointer to the specified file entry or NULL
;-------------------------------------------------------------------------------------
IEBIFFileEntry PROC USES EBX hIEBIF:DWORD, nFileEntry:DWORD
    LOCAL TotalFileEntries:DWORD
    LOCAL FileEntriesPtr:DWORD
    LOCAL Version:DWORD
    
    .IF hIEBIF == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEBIFTotalFileEntries, hIEBIF
    .IF eax == 0
        ret
    .ENDIF    
    mov TotalFileEntries, eax

    .IF nFileEntry > eax
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEBIFFileEntries, hIEBIF
    mov FileEntriesPtr, eax
    
    mov ebx, hIEBIF
    mov eax, [ebx].BIFINFO.BIFVersion
    mov Version, eax
    
    mov eax, nFileEntry
    .IF Version == 4
        mov ebx, SIZEOF FILE_ENTRY_V11
    .ELSE
        mov ebx, SIZEOF FILE_ENTRY
    .ENDIF
    mul ebx
    add eax, FileEntriesPtr
    ret
IEBIFFileEntry ENDP


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; IEBIFTileEntry - Returns in eax a pointer to the specified tile entry or NULL
;-------------------------------------------------------------------------------------
IEBIFTileEntry PROC USES EBX hIEBIF:DWORD, nTileEntry:DWORD
    LOCAL TotalTileEntries:DWORD
    LOCAL TileEntriesPtr:DWORD
    
    .IF hIEBIF == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEBIFTotalTileEntries, hIEBIF
    .IF eax == 0
        ret
    .ENDIF    
    mov TotalTileEntries, eax

    .IF nTileEntry > eax
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEBIFTileEntries, hIEBIF
    mov TileEntriesPtr, eax
    
    mov eax, nTileEntry
    mov ebx, SIZEOF TILE_ENTRY
    mul ebx
    add eax, TileEntriesPtr
    ret
IEBIFTileEntry ENDP


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; IEBIFTotalFileEntries - Returns in eax the total no of file entries
;-------------------------------------------------------------------------------------
IEBIFTotalFileEntries PROC USES EBX hIEBIF:DWORD
    .IF hIEBIF == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEBIF
    mov ebx, [ebx].BIFINFO.BIFHeaderPtr
    .IF ebx != 0
        mov eax, [ebx].BIF_HEADER_V1.FileEntriesCount
    .ELSE
        mov eax, 0
    .ENDIF
    ret
IEBIFTotalFileEntries ENDP


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; IEBIFTotalTileEntries - Returns in eax the total no of tile entries
;-------------------------------------------------------------------------------------
IEBIFTotalTileEntries PROC USES EBX hIEBIF:DWORD
    .IF hIEBIF == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEBIF
    mov ebx, [ebx].BIFINFO.BIFHeaderPtr
    .IF ebx != 0
        mov eax, [ebx].BIF_HEADER_V1.TileEntriesCount
    .ELSE
        mov eax, 0
    .ENDIF
    ret
IEBIFTotalTileEntries ENDP


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; IEBIFFileEntries - Returns in eax a pointer to file entries or NULL if not valid
;-------------------------------------------------------------------------------------
IEBIFFileEntries PROC USES EBX hIEBIF:DWORD
    .IF hIEBIF == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEBIF
    mov eax, [ebx].BIFINFO.BIFFileEntriesPtr
    ret
IEBIFFileEntries ENDP


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; IEBIFTileEntries - Returns in eax a pointer to tile entries or NULL if not valid
;-------------------------------------------------------------------------------------
IEBIFTileEntries PROC USES EBX hIEBIF:DWORD
    .IF hIEBIF == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEBIF
    mov eax, [ebx].BIFINFO.BIFTileEntriesPtr
    ret
IEBIFTileEntries ENDP


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; Peek at resource files actual signature - helps to determine actual resource type
; returns in eax SIG dword and ebx the version dword. NULL eax, NULL ebx if not valid entry or iebif handle
;
; Returned dword is reverse of sig and version:
; CHR sig will be ' RHC' 
; EFF sig will be ' FFE'
; Version will be '  1V' of usual V1__ and '0.1V' for V1.0
;-------------------------------------------------------------------------------------
IEBIFPeekFileSignature PROC hIEBIF:DWORD, nFileEntry:DWORD
    LOCAL FileEntryOffset:DWORD
    LOCAL ResourceOffset:DWORD
    LOCAL ResourceSize:DWORD
    LOCAL Version:DWORD
    LOCAL LargeFileMapping:DWORD
    LOCAL RetEAX:DWORD
    LOCAL RetEBX:DWORD
        
    .IF hIEBIF == NULL
        mov eax, NULL
        mov ebx, NULL
        ret
    .ENDIF
    
    mov ebx, hIEBIF
    mov eax, [ebx].BIFINFO.BIFLargeMapping
    mov LargeFileMapping, eax
    mov eax, [ebx].BIFINFO.BIFVersion
    mov Version, eax

    Invoke IEBIFFileEntry, hIEBIF, nFileEntry
    .IF eax == NULL
        mov ebx, NULL
        ret
    .ENDIF
    mov FileEntryOffset, eax
    
    mov ebx, FileEntryOffset
    .IF Version == 4 ; BIFF V1.1
        mov eax, [ebx].FILE_ENTRY_V11.ResourceOffset
    .ELSE
        mov eax, [ebx].FILE_ENTRY.ResourceOffset
    .ENDIF
    mov ResourceOffset, eax
    
    ; added 25/11/2015 just in case we have a 0 byte resource stored in bif, otherwise we are accessing some other resources data
    mov ebx, FileEntryOffset
    .IF Version == 4 ; BIFF V1.1
        mov eax, [ebx].FILE_ENTRY_V11.ResourceSize
    .ELSE
        mov eax, [ebx].FILE_ENTRY.ResourceSize
    .ENDIF
    mov ResourceSize, eax
    
    .IF ResourceSize < 4 ; we need 8 bytes, 2 dwords to read sigs, but at minumum we need the first dword
        mov eax, NULL
        mov ebx, NULL
    .ENDIF
        
    .IF LargeFileMapping == TRUE
        Invoke BIFOpenLargeMapView, hIEBIF, 8d, ResourceOffset
        .IF eax == NULL
            mov ebx, NULL
            ret
        .ENDIF
        mov ebx, dword ptr [eax+4] ; save ebx first for the version dword
        mov RetEBX, ebx
        mov eax, dword ptr [eax] ; overwrite eax with the sig dword
        mov RetEAX, eax
        Invoke BIFCloseLargeMapView, hIEBIF
        mov eax, RetEAX
        mov ebx, RetEBX
    .ELSE
        mov ebx, hIEBIF
        mov eax, [ebx].BIFINFO.BIFMemMapPtr
        mov ebx, ResourceOffset
        add eax, ebx        
        mov ebx, dword ptr [eax+4] ; save ebx first for the version dword
        mov eax, dword ptr [eax] ; overwrite eax with the sig dword
    .ENDIF
    ret
IEBIFPeekFileSignature endp


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; IEBIFFileName - returns in eax pointer to zero terminated string contained filename that is open or NULL if not opened
;-------------------------------------------------------------------------------------
IEBIFFileName PROC USES EBX hIEBIF:DWORD
    LOCAL BifFilename:DWORD
    .IF hIEBIF == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEBIF
    lea eax, [ebx].BIFINFO.BIFFilename
    mov BifFilename, eax
    Invoke szLen, BifFilename
    .IF eax == 0
        mov eax, NULL
    .ELSE
        mov eax, BifFilename
    .ENDIF
    ret
IEBIFFileName endp


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; IEBIFFileNameOnly - returns in eax true or false if it managed to pass to the buffer pointed at lpszFileNameOnly, the stripped filename without extension
;-------------------------------------------------------------------------------------
IEBIFFileNameOnly PROC USES EBX hIEBIF:DWORD, lpszFileNameOnly:DWORD
    Invoke IEBIFFileName, hIEBIF
    .IF eax == NULL
        mov eax, FALSE
        ret
    .ENDIF
    
    Invoke BIFJustFname, eax, lpszFileNameOnly
    mov eax, TRUE
    ret
IEBIFFileNameOnly endp


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; IEBIFFileSize - returns low order in eax, high order in ebx of size of file or eax = 0, ebx = 0
;-------------------------------------------------------------------------------------
IEBIFFileSize PROC hIEBIF:DWORD
    .IF hIEBIF == NULL
        mov eax, 0
        mov ebx, 0
        ret
    .ENDIF
    mov ebx, hIEBIF
    mov eax, [ebx].BIFINFO.BIFFilesize
    mov ebx, [ebx].BIFINFO.BIFFilesizeHigh
    ret
IEBIFFileSize endp


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; IEBIFFindKeyFile - returns in eax TRUE if found, or FALSE otherwise
;-------------------------------------------------------------------------------------
IEBIFFindKeyFile PROC USES EBX lpszBifFilePath:DWORD, lpszKeyFilePath:DWORD
    LOCAL szKeyFileName[MAX_PATH]:BYTE
    LOCAL szKeyFilePath[MAX_PATH]:BYTE
    LOCAL szCurrentKeyFilePath[MAX_PATH]:BYTE
    LOCAL CurrentPos:DWORD
    LOCAL LenKeyPath:DWORD

    Invoke BIFJustFname, lpszBifFilePath, Addr szKeyFileName; strip to just filename without extension
    Invoke GetPathOnly, lpszBifFilePath, Addr szKeyFilePath

    ;---------------------------------------------------------------------------------------------------
    ; look for bifname.key first, starting at current level and going down each level till end of string
    ;---------------------------------------------------------------------------------------------------
    Invoke szLen, Addr szKeyFilePath ;szCurrentKeyFilePath
    mov LenKeyPath, eax
    mov CurrentPos, eax
    
    .WHILE eax != 0
        lea ebx, szKeyFilePath ;szCurrentKeyFilePath
        add ebx, CurrentPos
        
        movzx eax, byte ptr [ebx]
        .WHILE al != '\' ; find backslash
            .IF CurrentPos == 0
                ;PrintText 'Start of string and no more backslashes left'
                .BREAK
            .ENDIF
            dec CurrentPos
            dec ebx
            movzx eax, byte ptr [ebx]
        .ENDW
        
        .IF CurrentPos != 0
            lea ebx, szKeyFilePath ;szCurrentKeyFilePath
            add ebx, CurrentPos
            mov [ebx], byte ptr 0 ; null our \ for the moment   
    
            Invoke szCopy, Addr szKeyFilePath, Addr szCurrentKeyFilePath
            Invoke szCatStr, Addr szCurrentKeyFilePath, Addr szBackslash
            Invoke szCatStr, Addr szCurrentKeyFilePath, Addr szKeyFileName 
            Invoke szCatStr, Addr szCurrentKeyFilePath, Addr KEYExt 
            
            lea ebx, szKeyFilePath ;szCurrentKeyFilePath
            add ebx, CurrentPos
            mov [ebx], byte ptr '\' ; restore our \ 

            ; check for chitin.key
            Invoke exist, Addr szCurrentKeyFilePath
            .IF eax == 1 ; exists
                Invoke szCopy, Addr szCurrentKeyFilePath, lpszKeyFilePath
                mov eax, TRUE
                ret
            .ENDIF
        .ELSE
            .BREAK
        .ENDIF
        .IF CurrentPos == 0
            .BREAK
        .ELSE
            dec CurrentPos
            mov eax, CurrentPos
        .ENDIF
    .ENDW
    ;---------------------------------------------------------------------------------------------------

    ;---------------------------------------------------------------------------------------------------
    ; look for bifname00.key - stripping off double 00s if found
    ;---------------------------------------------------------------------------------------------------
    
    lea ebx, szKeyFileName
    Invoke szLen, Addr szKeyFileName
    add ebx, eax ; at end of name
    sub ebx, 2
    movzx eax, word ptr [ebx]
    .IF eax == '00' ; we have a witcher style bif
        movzx eax, byte ptr [ebx-1]
        .IF al == '_'
            mov [ebx-1], byte ptr 0h ; null out string here
        .ELSE
            mov [ebx], byte ptr 0h ; null out string here
        .ENDIF

        ; added for witcher specific bifs: voices_X_00.bif use lang_X.key files
        Invoke InString, 1, Addr szKeyFileName, Addr szWitcherVoices_
        .IF eax != 0 
            Invoke szRep, Addr szKeyFileName, Addr szCurrentKeyFilePath, Addr szWitcherVoices_, Addr szWitcherLang_
            Invoke szCopy, Addr szCurrentKeyFilePath, Addr szKeyFileName
        .ENDIF

        Invoke szLen, Addr szKeyFilePath ;szCurrentKeyFilePath
        mov LenKeyPath, eax
        mov CurrentPos, eax
        
        .WHILE eax != 0
            lea ebx, szKeyFilePath ;szCurrentKeyFilePath
            add ebx, CurrentPos
            
            movzx eax, byte ptr [ebx]
            .WHILE al != '\' ; find backslash
                .IF CurrentPos == 0
                    ;PrintText 'Start of string and no more backslashes left'
                    .BREAK
                .ENDIF
                dec CurrentPos
                dec ebx
                movzx eax, byte ptr [ebx]
            .ENDW
            
            .IF CurrentPos != 0
                lea ebx, szKeyFilePath ;szCurrentKeyFilePath
                add ebx, CurrentPos
                mov [ebx], byte ptr 0 ; null our \ for the moment
                
                Invoke szCopy, Addr szKeyFilePath, Addr szCurrentKeyFilePath
                Invoke szCatStr, Addr szCurrentKeyFilePath, Addr szBackslash
                Invoke szCatStr, Addr szCurrentKeyFilePath, Addr szKeyFileName 
                Invoke szCatStr, Addr szCurrentKeyFilePath, Addr KEYExt 
                
                lea ebx, szKeyFilePath ;szCurrentKeyFilePath
                add ebx, CurrentPos
                mov [ebx], byte ptr '\' ; restore our \ 

                ; check for chitin.key
                Invoke exist, Addr szCurrentKeyFilePath
                .IF eax == 1 ; exists
                    Invoke szCopy, Addr szCurrentKeyFilePath, lpszKeyFilePath
                    mov eax, TRUE
                    ret
                .ENDIF
            .ELSE
                .BREAK
            .ENDIF
            .IF CurrentPos == 0
                .BREAK
            .ELSE
                dec CurrentPos
                mov eax, CurrentPos
            .ENDIF
        .ENDW   
    .ENDIF

    ;---------------------------------------------------------------------------------------------------
    ; look for chitin.key
    ;---------------------------------------------------------------------------------------------------
    Invoke BIFJustFname, lpszBifFilePath, Addr szKeyFileName; strip to just filename without extension
    mov eax, LenKeyPath 
    mov CurrentPos, eax
    
    .WHILE eax != 0
        lea ebx, szKeyFilePath ;szCurrentKeyFilePath
        add ebx, CurrentPos
        
        movzx eax, byte ptr [ebx]
        .WHILE al != '\' ; find backslash
            .IF CurrentPos == 0
                ;PrintText 'Start of string and no more backslashes left'
                .BREAK
            .ENDIF
            dec CurrentPos
            dec ebx
            movzx eax, byte ptr [ebx]
        .ENDW
        
        .IF CurrentPos != 0
            lea ebx, szKeyFilePath ;szCurrentKeyFilePath
            add ebx, CurrentPos
            mov [ebx], byte ptr 0 ; null our \ for the moment
            
            Invoke szCopy, Addr szKeyFilePath, Addr szCurrentKeyFilePath
            Invoke szCatStr, Addr szCurrentKeyFilePath, Addr szBackslash
            Invoke szCatStr, Addr szCurrentKeyFilePath, Addr szChitinKey
            
            lea ebx, szKeyFilePath ;szCurrentKeyFilePath
            add ebx, CurrentPos
            mov [ebx], byte ptr '\' ; restore our \ 

            ; check for chitin.key
            Invoke exist, Addr szCurrentKeyFilePath
            .IF eax == 1 ; exists
                Invoke szCopy, Addr szCurrentKeyFilePath, lpszKeyFilePath
                mov eax, TRUE
                ret
            .ENDIF
        .ELSE
            .BREAK
        .ENDIF
        .IF CurrentPos == 0
            .BREAK
        .ELSE
            dec CurrentPos
            mov eax, CurrentPos
        .ENDIF
    .ENDW

    ;---------------------------------------------------------------------------------------------------
    ; look for main.key
    ;---------------------------------------------------------------------------------------------------
    mov eax, LenKeyPath
    mov CurrentPos, eax
    
    .WHILE eax != 0
        lea ebx, szKeyFilePath ;szCurrentKeyFilePath
        add ebx, CurrentPos
        
        movzx eax, byte ptr [ebx]
        .WHILE al != '\' ; find backslash
            .IF CurrentPos == 0
                ;PrintText 'Start of string and no more backslashes left'
                .BREAK
            .ENDIF
            dec CurrentPos
            dec ebx
            movzx eax, byte ptr [ebx]
        .ENDW
        
        .IF CurrentPos != 0 
            ; check for main.key
            lea ebx, szKeyFilePath ;szCurrentKeyFilePath
            add ebx, CurrentPos
            mov [ebx], byte ptr 0 ; null our \ for the moment
            
            Invoke szCopy, Addr szKeyFilePath, Addr szCurrentKeyFilePath
            Invoke szCatStr, Addr szCurrentKeyFilePath, Addr szBackslash
            Invoke szCatStr, Addr szCurrentKeyFilePath, Addr szMainKey

            lea ebx, szKeyFilePath ;szCurrentKeyFilePath
            add ebx, CurrentPos
            mov [ebx], byte ptr '\' ; restore our \ 

            Invoke exist, Addr szCurrentKeyFilePath
            .IF eax == 1 ; exists
                Invoke szCopy, Addr szCurrentKeyFilePath, lpszKeyFilePath
                mov eax, TRUE
                ret
            .ENDIF
        .ELSE
            .BREAK
        .ENDIF
        .IF CurrentPos == 0
            .BREAK
        .ELSE
            dec CurrentPos
            mov eax, CurrentPos
        .ENDIF
    .ENDW

    ;---------------------------------------------------------------------------------------------------
    ; look for mod.key
    ;---------------------------------------------------------------------------------------------------
    mov eax, LenKeyPath
    mov CurrentPos, eax
    
    .WHILE eax != 0
        lea ebx, szKeyFilePath ;szCurrentKeyFilePath
        add ebx, CurrentPos
        
        movzx eax, byte ptr [ebx]
        .WHILE al != '\' ; find backslash
            .IF CurrentPos == 0
                ;PrintText 'Start of string and no more backslashes left'
                .BREAK
            .ENDIF
            dec CurrentPos
            dec ebx
            movzx eax, byte ptr [ebx]
        .ENDW
        
        .IF CurrentPos != 0 
            ; check for main.key
            lea ebx, szKeyFilePath ;szCurrentKeyFilePath
            add ebx, CurrentPos
            mov [ebx], byte ptr 0 ; null our \ for the moment
            
            Invoke szCopy, Addr szKeyFilePath, Addr szCurrentKeyFilePath
            Invoke szCatStr, Addr szCurrentKeyFilePath, Addr szBackslash
            Invoke szCatStr, Addr szCurrentKeyFilePath, Addr szModKey

            lea ebx, szKeyFilePath ;szCurrentKeyFilePath
            add ebx, CurrentPos
            mov [ebx], byte ptr '\' ; restore our \ 

            Invoke exist, Addr szCurrentKeyFilePath
            .IF eax == 1 ; exists
                Invoke szCopy, Addr szCurrentKeyFilePath, lpszKeyFilePath
                mov eax, TRUE
                ret
            .ENDIF
        .ELSE
            .BREAK
        .ENDIF
        .IF CurrentPos == 0
            .BREAK
        .ELSE
            dec CurrentPos
            mov eax, CurrentPos
        .ENDIF
    .ENDW

    ; not found bifname.key, bifname00.key, chitin.key or main.key
    mov ebx, lpszKeyFilePath
    mov [ebx], byte ptr 0
    mov eax, FALSE
    ret
IEBIFFindKeyFile endp


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; IEBIFExtractFile - returns in eax size of file extracted or 0 if failed
;-------------------------------------------------------------------------------------
IEBIFExtractFile PROC USES EBX hIEBIF:DWORD, nFileEntry:DWORD, lpszOutputFilename:DWORD
    LOCAL FileEntryOffset:DWORD
    LOCAL ResourceSize:DWORD
    LOCAL ResourceData:DWORD
    LOCAL ResourceOffset:DWORD
    LOCAL hOutputFile:DWORD
    LOCAL MemMapHandle:DWORD
    LOCAL MemMapPtr:DWORD
    LOCAL Version:DWORD
    LOCAL LargeMapResourceSize:DWORD
    LOCAL LargeMapResourceOffset:DWORD
    LOCAL LargeMapAdjOffset:DWORD
    LOCAL LargeMapHandle:DWORD
    LOCAL LargeMemMapPtr:DWORD
    LOCAL LargeFileMapping:DWORD
    LOCAL dwOpenMode:DWORD

    .IF hIEBIF == NULL
        mov eax, 0
        ret
    .ENDIF
    
    Invoke IEBIFFileEntry, hIEBIF, nFileEntry
    .IF eax == NULL
        ret
    .ENDIF
    mov FileEntryOffset, eax

    mov ebx, hIEBIF
    mov eax, [ebx].BIFINFO.BIFVersion
    mov Version, eax
    mov eax, [ebx].BIFINFO.BIFLargeMapping
    mov LargeFileMapping, eax
    mov eax, [ebx].BIFINFO.BIFMemMapHandle
    mov LargeMapHandle, eax
    mov eax, [ebx].BIFINFO.BIFOpenMode
    mov dwOpenMode, eax

    mov ebx, FileEntryOffset
    .IF Version == 4 ; BIFF V1.1
        mov eax, [ebx].FILE_ENTRY_V11.ResourceSize
        mov ResourceSize, eax
        mov eax, [ebx].FILE_ENTRY_V11.ResourceOffset
        mov ResourceOffset, eax
    .ELSE
        mov eax, [ebx].FILE_ENTRY.ResourceSize
        mov ResourceSize, eax
        mov eax, [ebx].FILE_ENTRY.ResourceOffset
        mov ResourceOffset, eax
    .ENDIF
    
    
    .IF LargeFileMapping == TRUE
        Invoke BIFOpenLargeMapView, hIEBIF, ResourceSize, ResourceOffset
        .IF eax == NULL
            ret
        .ENDIF
        mov ResourceData, eax    
    
;        IFDEF DEBUG32
;        PrintText 'Large Map Extract File'
;        ENDIF
;        ; calc map view size, based on resourcesize and granularity
;        ; calc map view offset, based on resourceofffset and granularity
;        ; calc adjusted resource offset based on all the above
;        
;        Invoke BIFCalcLargeFileView, ResourceSize, ResourceOffset, Addr LargeMapResourceSize, Addr LargeMapResourceOffset
;        mov LargeMapAdjOffset, eax
;        
;        IFDEF DEBUG32
;            PrintDec ResourceSize
;            PrintDec ResourceOffset
;            PrintDec LargeMapResourceSize
;            PrintDec LargeMapResourceOffset
;            PrintDec LargeMapAdjOffset
;        ENDIF
;        .IF dwOpenMode == 1
;            Invoke MapViewOfFileEx, LargeMapHandle, FILE_MAP_READ, 0, LargeMapResourceOffset, LargeMapResourceSize, NULL
;        .ELSE
;            Invoke MapViewOfFileEx, LargeMapHandle, FILE_MAP_ALL_ACCESS, 0, LargeMapResourceOffset, LargeMapResourceSize, NULL
;        .ENDIF
;        .IF eax == NULL ; added to try for actual resource size, like at end of a file, cant allocate more size than max length of file
;           ; inc ResourceSize
;            .IF dwOpenMode == 1
;                Invoke MapViewOfFileEx, LargeMapHandle, FILE_MAP_READ, 0, LargeMapResourceOffset, 0, NULL
;            .ELSE
;                Invoke MapViewOfFileEx, LargeMapHandle, FILE_MAP_ALL_ACCESS, 0, LargeMapResourceOffset, 0, NULL
;            .ENDIF        
;        
;            .IF eax == NULL
;                IFDEF DEBUG32
;                Invoke GetLastError
;                PrintDec eax
;                ENDIF
;                mov eax, -1
;                ret
;            .ENDIF
;        .ENDIF
;        mov LargeMemMapPtr, eax
;        mov ebx, LargeMapAdjOffset
;        add eax, ebx
;        mov ResourceData, eax
;        ;dec ResourceSize
    .ELSE
        mov ebx, hIEBIF
        mov eax, [ebx].BIFINFO.BIFMemMapPtr
        mov ebx, ResourceOffset
        add eax, ebx
        mov ResourceData, eax
    .ENDIF

    ; Create file to write data to, map it to memory and then write resource data to it, then close memmap and file
    Invoke CreateFile, lpszOutputFilename, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_FLAG_WRITE_THROUGH, NULL
    .IF eax == INVALID_HANDLE_VALUE
        mov eax, 0
        ret
    .ENDIF
    mov hOutputFile, eax

    Invoke CreateFileMapping, hOutputFile, NULL, PAGE_READWRITE, 0, ResourceSize, NULL
    .IF eax == NULL
        Invoke CloseHandle, hOutputFile
        mov eax, 0
        ret
    .ENDIF
    mov MemMapHandle, eax

    Invoke MapViewOfFile, MemMapHandle, FILE_MAP_ALL_ACCESS, 0, 0, 0
    .IF eax == NULL
        Invoke CloseHandle, MemMapHandle
        Invoke CloseHandle, hOutputFile
        mov eax, 0
        ret        
    .ENDIF
    mov MemMapPtr, eax

    Invoke RtlMoveMemory, MemMapPtr, ResourceData, ResourceSize
    ;Invoke BIFCopyMemory, MemMapPtr, ResourceData, ResourceSize

    .IF LargeFileMapping == TRUE
        Invoke BIFCloseLargeMapView, hIEBIF
        ;Invoke UnmapViewOfFile, LargeMemMapPtr
    .ENDIF
    
    Invoke FlushViewOfFile, MemMapPtr, ResourceSize
    Invoke UnmapViewOfFile, MemMapPtr
    Invoke CloseHandle, MemMapHandle 
    Invoke CloseHandle, hOutputFile
 
    mov eax, ResourceSize
    ret
IEBIFExtractFile endp


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; IEBIFExtractTile - returns in eax size of tile extracted or 0 if failed
;-------------------------------------------------------------------------------------
IEBIFExtractTile PROC USES EBX hIEBIF:DWORD, nTileEntry:DWORD, lpszOutputFilename:DWORD
    LOCAL TileEntryOffset:DWORD
    LOCAL ResourceSize:DWORD
    LOCAL ResSizeWithHeader:DWORD
    LOCAL TilesCount:DWORD
    LOCAL TileSize:DWORD
    LOCAL ResourceData:DWORD
    LOCAL ResourceOffset:DWORD
    LOCAL hOutputFile:DWORD
    LOCAL MemMapHandle:DWORD
    LOCAL MemMapPtr:DWORD
    LOCAL LargeFileMapping:DWORD    
    
    .IF hIEBIF == NULL
        mov eax, 0
        ret
    .ENDIF
    
    Invoke IEBIFTileEntry, hIEBIF, nTileEntry
    .IF eax == NULL
        ret
    .ENDIF
    mov TileEntryOffset, eax
    
    mov ebx, hIEBIF
    mov eax, [ebx].BIFINFO.BIFLargeMapping
    mov LargeFileMapping, eax

    mov ebx, TileEntryOffset
    mov eax, [ebx].TILE_ENTRY.ResourceOffset
    mov ResourceOffset, eax
    mov eax, [ebx].TILE_ENTRY.TileSize
    mov TileSize, eax
    mov eax, [ebx].TILE_ENTRY.TilesCount
    mov TilesCount, eax
    mov ebx, TileSize
    mul ebx    
    mov ResourceSize, eax

    .IF LargeFileMapping == TRUE    
        Invoke BIFOpenLargeMapView, hIEBIF, ResourceSize, ResourceOffset
        .IF eax == NULL
            ret
        .ENDIF
        mov ResourceData, eax
    .ELSE
    
        mov ebx, hIEBIF
        mov eax, [ebx].BIFINFO.BIFMemMapPtr
        mov ebx, ResourceOffset
        add eax, ebx
        mov ResourceData, eax
    .ENDIF
    ;PrintDec TileEntryOffset
    ;PrintDec ResourceOffset
    ;PrintDec ResourceSize
    ;PrintDec ResourceData
    
    Invoke CreateFile, lpszOutputFilename, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_FLAG_WRITE_THROUGH, NULL
    .IF eax == INVALID_HANDLE_VALUE
        mov eax, -1
        ret
    .ENDIF
    mov hOutputFile, eax

    ; update TISV1_HEADER_FOR_BIF for our new extracted tile
    lea ebx, TISV1Header
    mov eax, TilesCount
    mov [ebx].TISV1_HEADER_FOR_BIF.TilesCount, eax
    mov eax, TileSize
    mov [ebx].TISV1_HEADER_FOR_BIF.TilesSectionLength, eax
    
    
    mov eax, ResourceSize
    add eax, SIZEOF TISV1_HEADER_FOR_BIF ;TISV1Header
    mov ResSizeWithHeader, eax
    Invoke CreateFileMapping, hOutputFile, NULL, PAGE_READWRITE, 0, ResSizeWithHeader, NULL ;ResourceSize
    .IF eax == NULL
        Invoke CloseHandle, hOutputFile
        mov eax, 0
        ret
    .ENDIF
    mov MemMapHandle, eax

    Invoke MapViewOfFile, MemMapHandle, FILE_MAP_ALL_ACCESS, 0, 0, 0
    .IF eax == NULL
        Invoke CloseHandle, MemMapHandle
        Invoke CloseHandle, hOutputFile
        mov eax, 0
        ret        
    .ENDIF
    mov MemMapPtr, eax

    Invoke RtlMoveMemory, MemMapPtr, Addr TISV1Header, SIZEOF TISV1_HEADER_FOR_BIF
    mov ebx, MemMapPtr
    add ebx, SIZEOF TISV1_HEADER_FOR_BIF
    
    ;Invoke BIFCopyMemory, ebx, ResourceData, ResourceSize
    Invoke RtlMoveMemory, ebx, ResourceData, ResourceSize ; MemMapPtr

    .IF LargeFileMapping == TRUE
        Invoke BIFCloseLargeMapView, hIEBIF
    .ENDIF
    
    Invoke FlushViewOfFile, MemMapPtr, ResSizeWithHeader ;ResourceSize
    Invoke UnmapViewOfFile, MemMapPtr
    Invoke CloseHandle, MemMapHandle 
    Invoke CloseHandle, hOutputFile
    mov eax, ResSizeWithHeader ;ResourceSize
    ret
IEBIFExtractTile endp


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; 0 = No Bif file, 1 = BIFF, 2 = BIF V1.0 3 = BIFCV1.0, 4 = BIF V1.1
;-------------------------------------------------------------------------------------
IEBIFFileCompression PROC USES EBX hIEBIF:DWORD
    .IF hIEBIF == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEBIF
    mov eax, [ebx].BIFINFO.BIFVersion
    ret
IEBIFFileCompression endp


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; 0 = No Bif file, 1 = BIFF, 2 = BIF V1.0 3 = BIFCV1.0, 4 = BIF V1.1
;-------------------------------------------------------------------------------------
IEBIFVersion PROC USES EBX hIEBIF:DWORD
    .IF hIEBIF == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEBIF
    mov eax, [ebx].BIFINFO.BIFVersion
    ret
IEBIFVersion endp


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; Returns in eax newly created and opened bif file handle hIEBIF
; or if < 0 an error
; dwBifFormat = 0 for BIF V1.0, 1= for BIF V1.1
;-------------------------------------------------------------------------------------
IEBIFNewBif PROC USES EBX lpszNewBifFilename:DWORD, dwBifFormat:DWORD
    LOCAL hBifNEW:DWORD
    LOCAL BifMemMapHandleNEW:DWORD
    LOCAL BifMemMapPtrNEW:DWORD
    LOCAL FilesizeNEW:DWORD
    LOCAL hIEBIF:DWORD
    
    Invoke CreateFile, lpszNewBifFilename, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, 0, NULL    
    .IF eax == INVALID_HANDLE_VALUE
        mov eax, BN_BIF_CREATION
        ret
    .ENDIF
    mov hBifNEW, eax
    
    .IF dwBifFormat == IEBIF_BIF_FORMAT_BIFV10
        mov FilesizeNEW, SIZEOF BIF_HEADER_V1 ; BIF v1.0
    .ELSE
        mov FilesizeNEW, SIZEOF BIF_HEADER_V11 ; BIF v1.1
    .ENDIF
    Invoke CreateFileMapping, hBifNEW, NULL, PAGE_READWRITE, 0, FilesizeNEW, NULL ; Create memory mapped file
    .IF eax == NULL
        Invoke CloseHandle, hBifNEW
        mov eax, BN_BIF_MAPPING
        ret        
    .ENDIF
    mov BifMemMapHandleNEW, eax

    Invoke MapViewOfFileEx, BifMemMapHandleNEW, FILE_MAP_ALL_ACCESS, 0, 0, 0, NULL
    .IF eax == NULL
        Invoke CloseHandle, BifMemMapHandleNEW
        Invoke CloseHandle, hBifNEW
        mov eax, BN_BIF_VIEW
        ret
    .ENDIF
    mov BifMemMapPtrNEW, eax
    
    ; Add basic header info before processing and getting our IEBIF handle
    mov ebx, BifMemMapPtrNEW
    mov eax, 'FFIB'
    mov [ebx].BIF_HEADER_V1.Signature, eax
    .IF dwBifFormat == IEBIF_BIF_FORMAT_BIFV10
        mov eax, '  1V'
    .ELSE
        mov eax, '1.1V'
    .ENDIF
    mov [ebx].BIF_HEADER_V1.Version, eax
    mov eax, 0
    mov [ebx].BIF_HEADER_V1.FileEntriesCount, eax
    mov [ebx].BIF_HEADER_V1.TileEntriesCount, eax
    mov eax, 20d
    mov [ebx].BIF_HEADER_V1.OffsetFileEntries, eax
    
    Invoke IEBIFMem, BifMemMapPtrNEW, lpszNewBifFilename, FilesizeNEW, 0, 1, FALSE
    .IF eax == NULL
        Invoke UnmapViewOfFile, BifMemMapPtrNEW
        Invoke CloseHandle, BifMemMapHandleNEW
        Invoke CloseHandle, hBifNEW    
        mov eax, BN_BIF_MEMBIFINFO
        ret
    .ENDIF
    mov hIEBIF, eax
    ret
IEBIFNewBif endp


;=========================================================================================
;-----------------------------------------------------------------------------------------
; INTERNAL FUNCTIONS
;-----------------------------------------------------------------------------------------

IEBIF_ALIGN
;-----------------------------------------------------------------------------------------
; BIFCalcLargeFileView - calculate large mapping size, view and offset
;-----------------------------------------------------------------------------------------
BIFCalcLargeFileView PROC USES EBX EDX dwRequiredViewSize:DWORD, dwRequiredViewOffset:DWORD, lpdwMappedViewSize:DWORD, lpdwMappedViewOffset:DWORD
    LOCAL sysinfo:SYSTEM_INFO
    LOCAL dwAllocationGranularity:DWORD
    LOCAL dwAdjustedOffset:DWORD
    
    Invoke GetSystemInfo, Addr sysinfo
    mov eax, sysinfo.dwAllocationGranularity
    mov dwAllocationGranularity, eax

    mov eax, dwRequiredViewSize
    .IF eax < dwAllocationGranularity
        mov ebx, lpdwMappedViewSize
        mov eax, dwAllocationGranularity
        add eax, dwAllocationGranularity
        mov [ebx], eax
    .ELSE
        mov eax, dwRequiredViewSize
        xor edx, edx
        mov ebx, dwAllocationGranularity
        div ebx ; Divides dwRequiredViewSize by dwAllocationGranularity. EAX = quotient and EDX = remainder (modulo).
        .IF edx > 0 ; we have a remainder, so calc to add dwAllocationGranularity to dwRequiredViewSize - remainder
            mov eax, dwRequiredViewSize
            sub eax, edx
            add eax, dwAllocationGranularity
            add eax, dwAllocationGranularity
            mov ebx, lpdwMappedViewSize
            mov [ebx], eax
        .ELSE ; else we have a multiple of dwAllocationGranularity, so just return the dwRequiredViewSize as actualsize
            mov eax, dwRequiredViewSize
            mov ebx, lpdwMappedViewSize
            mov [ebx], eax
        .ENDIF
    .ENDIF

    mov eax, dwRequiredViewOffset
    .IF eax < dwAllocationGranularity
        mov ebx, dwAllocationGranularity
        sub ebx, eax
        mov dwAdjustedOffset, ebx
        mov eax, 0
        mov ebx, lpdwMappedViewOffset
        mov [ebx], eax
    .ELSE
        mov eax, dwRequiredViewOffset
        xor edx, edx
        mov ebx, dwAllocationGranularity
        div ebx ; Divides dwRequiredViewSize by dwAllocationGranularity. EAX = quotient and EDX = remainder (modulo).
        .IF edx > 0 ; we have a remainder, so calc to add dwAllocationGranularity to dwRequiredViewSize - remainder
            mov dwAdjustedOffset, edx
            mov eax, dwRequiredViewOffset
            sub eax, edx
            mov ebx, lpdwMappedViewOffset
            mov [ebx], eax
        .ELSE ; else we have a multiple of dwAllocationGranularity, so just return the dwRequiredViewSize as actualsize
            mov eax, dwRequiredViewOffset
            mov ebx, lpdwMappedViewOffset
            mov [ebx], eax
            mov dwAdjustedOffset, 0
        .ENDIF
    .ENDIF
    mov eax, dwAdjustedOffset
    ; offset = offset & 0xffff0000;
    ;       64                      100                     120
    ;---------------------------------------------------------------------------------------
    ;
    ; 64 bytes gran
    ; file start at 100bytes, size of 20 - to offset 120
    ; size view is 64
    ; offset will be 
    ret
BIFCalcLargeFileView endp


IEBIF_ALIGN
;-----------------------------------------------------------------------------------------
; BIFOpenLargeMapView - opens a view in a large mem mapped file to access data pointed to
; by dwRequiredViewOffset. Returns in eax adjusted offset of memory where dwRequiredViewOffset
; can be accesed. Once finished with this view use BIFCloseLargeMapView to close it.
;-----------------------------------------------------------------------------------------
BIFOpenLargeMapView PROC USES EBX hIEBIF:DWORD, dwRequiredViewSize:DWORD, dwRequiredViewOffset:DWORD
    LOCAL LargeMapResourceSize:DWORD
    LOCAL LargeMapResourceOffset:DWORD
    LOCAL LargeMapAdjOffset:DWORD
    LOCAL LargeMapHandle:DWORD
    LOCAL LargeMemMapPtr:DWORD
    LOCAL LargeFileMapping:DWORD
    LOCAL dwOpenMode:DWORD
    
    .IF hIEBIF == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    mov ebx, hIEBIF
    mov eax, [ebx].BIFINFO.BIFLargeMapping
    mov LargeFileMapping, eax
    mov eax, [ebx].BIFINFO.BIFMemMapHandle
    mov LargeMapHandle, eax
    mov eax, [ebx].BIFINFO.BIFOpenMode
    mov dwOpenMode, eax
    
    Invoke BIFCalcLargeFileView, dwRequiredViewSize, dwRequiredViewOffset, Addr LargeMapResourceSize, Addr LargeMapResourceOffset
    mov LargeMapAdjOffset, eax

    .IF dwOpenMode == 1
        Invoke MapViewOfFileEx, LargeMapHandle, FILE_MAP_READ, 0, LargeMapResourceOffset, LargeMapResourceSize, NULL
    .ELSE
        Invoke MapViewOfFileEx, LargeMapHandle, FILE_MAP_ALL_ACCESS, 0, LargeMapResourceOffset, LargeMapResourceSize, NULL
    .ENDIF    
    .IF eax == NULL ; try again with 0 as no bytes to map - otherwise end of files are a problem, cant alloc size > max file size, let MapViewOfFile handle this with 0 specified as no bytes to map
        .IF dwOpenMode == 1
            Invoke MapViewOfFileEx, LargeMapHandle, FILE_MAP_READ, 0, LargeMapResourceOffset, 0, NULL
        .ELSE
            Invoke MapViewOfFileEx, LargeMapHandle, FILE_MAP_ALL_ACCESS, 0, LargeMapResourceOffset, 0, NULL
        .ENDIF        
        .IF eax == NULL
            ret
        .ENDIF    
    .ENDIF
    mov LargeMemMapPtr, eax
    
    ; save memmap ptr for later use in BIFCloseLargeMapView
    mov ebx, hIEBIF
    mov [ebx].BIFINFO.BIFLargeMapView, eax
    
    add eax, LargeMapAdjOffset
    ret
BIFOpenLargeMapView ENDP


IEBIF_ALIGN
;-----------------------------------------------------------------------------------------
; BIFCloseLargeMapView - Closes an open view of a large mem mapped file.
; Returns TRUE if succesful or FALSE otherwise
;-----------------------------------------------------------------------------------------
BIFCloseLargeMapView PROC USES EBX hIEBIF:DWORD
    .IF hIEBIF == NULL
        mov eax, FALSE
        ret
    .ENDIF

    mov ebx, hIEBIF
    mov eax, [ebx].BIFINFO.BIFLargeMapView
    .IF eax != 0
        Invoke UnmapViewOfFile, eax ;LargeMemMapPtr
    .ENDIF
    mov eax, TRUE
    ret
BIFCloseLargeMapView ENDP








END
