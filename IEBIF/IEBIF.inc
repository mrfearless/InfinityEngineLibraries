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


;-----------------------------------------------------------------------------------------
; IEBIF Prototypes
;-----------------------------------------------------------------------------------------
IEBIFOpen                   PROTO :DWORD, :DWORD            ; lpszBifFilename, dwOpenMode. Returns in eax a handle used in other functions: hIEBIF
IEBIFLargeFileMapping       PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD ; hBIFLargeFileToMap, LargeBifMemMapHandle, dwBIFFilesize, dwBIFFilesizeHigh, dwOpenMode, lpdwBIFLargeMapping
IEBIFMem                    PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD ; pBIFInMemory, lpszBifFilename, dwBifFilesize, dwBifFilesizeHigh, dwOpenMode, dwBIFLargeMapping. Returns in eax a handle used in other functions: hIEBIF
IEBIFClose                  PROTO :DWORD                    ; hIEBIF returned from IEBIFOpen.
IEBIFSave                   PROTO :DWORD                    ; hIEBIF.

; Functions for returning pointers to internal bif structure areas of interest
IEBIFHeader                 PROTO :DWORD                    ; hIEBIF. Returns in eax pointer to a BIF_HEADER_V1 structure.
IEBIFFileEntry              PROTO :DWORD, :DWORD            ; hIEBIF, nFileEntry. Returns in eax pointer to a FILE_ENTRY structure.
IEBIFTileEntry              PROTO :DWORD, :DWORD            ; hIEBIF, nTileEntry. Returns in eax pointer to a TILE_ENTRY structure.
IEBIFFileEntries            PROTO :DWORD                    ; hIEBIF. Returns in eax pointer to File Entries
IEBIFTileEntries            PROTO :DWORD                    ; hIEBIF. Returns in eax pointer to Tile Entries
IEBIFPeekFileSignature      PROTO :DWORD, :DWORD            ; hIEBIF, nFileEntry. Returns in eax SIGNATURE dword and ebx the VERSION dword (from the BIFF_HEADER). -1 eax, -1 ebx if not valid entry or iebif handle invalid

; Bif file information
IEBIFTotalFileEntries       PROTO :DWORD                    ; hIEBIF. Returns in eax total no of file entries.
IEBIFTotalTileEntries       PROTO :DWORD                    ; hIEBIF. Returns in eax total no of tile entries.
IEBIFFileName               PROTO :DWORD                    ; hIEBIF. Returns in eax pointer to bif full path filename
IEBIFFileNameOnly           PROTO :DWORD, :DWORD            ; hIEBIF, lpszFileNameOnly. eax contains True or false if succesfull. strips filename of path and ext information.
IEBIFFileSize               PROTO :DWORD                    ; hIEBIF. Returns in eax size of bif file in bytes
IEBIFFileCompression        PROTO :DWORD                    ; hIEBIF. Returns in eax 0 no bif, 1 = BIFF, 2 = BIF V1.0, 3 = BIFCV1.0, 4 = BIF V1.1
IEBIFVersion                PROTO :DWORD                    ; hIEBIF. Returns in eax 0 no bif, 1 = BIFF, 2 = BIF V1.0, 3 = BIFCV1.0, 4 = BIF V1.1

IEBIFFindKeyFile            PROTO :DWORD, :DWORD            ; Returns true if key file found or false otherwise

; Extract file/tile
IEBIFExtractFile            PROTO :DWORD, :DWORD, :DWORD    ; hIEBIF, nFileEntry, lpszOutputFilename. Returns in eax size of file extracted or -1 if failed
IEBIFExtractTile            PROTO :DWORD, :DWORD, :DWORD    ; hIEBIF, nTileEntry, lpszOutputFilename. Returns in eax size of tile extracted or -1 if failed

IEBIFUncompressBIF          PROTO :DWORD, :DWORD            ; lpszBifInputFilename to uncompress, lpszBifOutputFilename (optional) to write out uncompressed bif as (null=same filename as lpszBifInputFilename)
IEBIFCompressBIF            PROTO :DWORD, :DWORD, :DWORD    ; lpszBifInputFilename to compress, lpszBifOutputFilename (optional) to write out compressed bif as (null=same filename as lpszBifInputFilename), dwCompressedFormat (0=BIF V.0, 2=BIFC)

IEBIFNewBif                 PROTO :DWORD, :DWORD            ; lpszNewBifFilename, dwBifFormat. Returns in eax a handle used in other functions: hIEBIF, or NULL failed. 

;-----------------------------------------------------------------------------------------







;-----------------------------------------------------------------------------------------
; IEBIF Structures
;-----------------------------------------------------------------------------------------

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

IFNDEF BIF_HEADER_V12 ; proposed 64bit format for a BIF V1.2
BIF_HEADER_V12          STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('BIFF')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V1.2')
    FileEntriesCount    DQ 0 ; 0x0008   8 (qword)       Count of resource (file) entries
    OffsetFileEntries   DQ 0 ; 0x0010   8 (qword)       Offset (from start of file) to resource (file) table
BIF_HEADER_V12          ENDS
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

IFNDEF FILE_ENTRY_V12 ; proposed 64bit format for a BIF V1.2
FILE_ENTRY_V12          STRUCT
    ResourceLocator     DQ 0 ; 0x0000   8 (qword)       Resource locator. The IE resource manager uses 32-bit values as a 'resource index', which codifies the source of the resource as well as which source it refers to. The layout of this value is below. bits 31-20: source index (the ordinal value giving the index of the corresponding BIF entry) bits 19-14: tileset index bits 13- 0: non-tileset file index (any 12 bit value, so long as it matches the value used in the BIF file)
    ResourceFlags       DQ 0 ; 0x0004   8 (qword)       Flags (BIF index is now in this value, (flags & 0xFFF00000) >> 20). The rest appears to define 'fixed' index. 
    ResourceOffset      DQ 0 ; 0x0008   8 (qword)       Offset (from start of file) to resource data (file data)
    ResourceSize        DQ 0 ; 0x000C   8 (qword)       Size of this resource
    ResourceType        DW 0 ; 0x000E   4 (dword)       Resource type
    Unknown             DW 0 ; 0x0010   2 (word)        NULL
FILE_ENTRY_V12          ENDS
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


.CONST
; IEBIFUncompress return values
BU_SUCCESS                  EQU 0
BU_BIF_INVALID              EQU -1
BU_BIF_ALREADY_UNCOMPRESSED EQU -2
BU_BIF_FORMAT_UNSUPPORTED   EQU -3
BU_BIF_TOO_LARGE            EQU -4
BU_BIF_OUTPUTFILE_CREATION  EQU -5
BU_BIF_OUTPUTFILE_MAPPING   EQU -6
BU_BIF_OUTPUTFILE_VIEW      EQU -7
BU_BIF_INPUTFILE_OPEN       EQU -8
BU_BIF_INPUTFILE_MAPPING    EQU -9
BU_BIF_INPUTFILE_VIEW       EQU -10
BU_BIF_INPUTFILE_ZEROSIZE   EQU -11
BU_BIF_UNCOMPRESS_ERROR     EQU -12

; IEBIFCompress return values
BC_SUCCESS                  EQU 0
BC_BIF_INVALID              EQU -1
BC_BIF_ALREADY_COMPRESSED   EQU -2
BC_BIF_FORMAT_UNSUPPORTED   EQU -3
BC_BIF_TOO_LARGE            EQU -4
BC_BIF_OUTPUTFILE_CREATION  EQU -5
BC_BIF_OUTPUTFILE_MAPPING   EQU -6
BC_BIF_OUTPUTFILE_VIEW      EQU -7
BC_BIF_INPUTFILE_OPEN       EQU -8
BC_BIF_INPUTFILE_MAPPING    EQU -9
BC_BIF_INPUTFILE_VIEW       EQU -10
BC_BIF_INPUTFILE_ZEROSIZE   EQU -11
BC_BIF_COMPRESS_ERROR       EQU -12
BC_BIF_COMPRESS_TOOLARGE    EQU -13

; IEBIFNewBif return values
BN_BIF_CREATION             EQU -1
BN_BIF_MAPPING              EQU -2
BN_BIF_VIEW                 EQU -3
BN_BIF_MEMBIFINFO           EQU -4