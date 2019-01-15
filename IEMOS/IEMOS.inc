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

;-----------------------------------------------------------------------------------------
; IEMOS Prototypes
;-----------------------------------------------------------------------------------------
IEMOSOpen                   PROTO :DWORD, :DWORD            ; lpszMosFilename, dwOpenMode. Returns in eax a handle used in other functions: hIEMOS
IEMOSMem                    PROTO :DWORD, :DWORD, :DWORD, :DWORD ; pMOSInMemory, lpszMosFilename, dwMosFilesize, dwOpenMode. Returns in eax a handle used in other functions: hIEMOS
IEMOSClose                  PROTO :DWORD                    ; hIEMOS returned from IEMOSOpen.

IEMOSHeader                 PROTO :DWORD                    ; hIEMOS. Returns in eax pointer to a MOSV1_HEADER structure.
IEMOSTileLookupEntries      PROTO :DWORD                    ; hIEMOS. Returns in eax pointer to TileLookup array entries
IEMOSTileLookupEntry        PROTO :DWORD, :DWORD            ; hIEMOS, nTile. Returns in eax pointer to specific TileLookup entry
IEMOSTileDataEntries        PROTO :DWORD                    ; hIEMOS. Returns in eax pointer to TILEDATA array entries
IEMOSTileDataEntry          PROTO :DWORD, :DWORD            ; hIEMOS, nTile. Returns in eax pointer to specific TILEDATA entry
IEMOSTotalTiles             PROTO :DWORD                    ; hIEMOS. Returns in eax total tiles in MOS

IEMOSPalettes               PROTO :DWORD                    ; hIEMOS. Returns in eax pointer to the palettes array
IEMOSTilePalette            PROTO :DWORD, :DWORD            ; hIEMOS, nTile. Returns in eax pointer to the tile's specific palette (256 entries of RGBQUADs)
IEMOSTilePaletteEntry       PROTO :DWORD, :DWORD, :DWORD    ; hIEMOS, nTile, PaletteIndex. eax contains pointer to RGBQUAD
IEMOSTotalPalettes          PROTO :DWORD                    ; hIEMOS. Returns in eax total palettes in MOS (same as total tiles)

IEMOSBlockEntries           PROTO :DWORD                    ; hIEMOS. Returns in eax pointer to DATABLOCK_ENTRY array entries. For MOS V2 Only
IEMOSBlockEntry             PROTO :DWORD, :DWORD            ; hIEMOS, nBlockEntry. Returns in eax pointer to a DATABLOCK_ENTRY structure. For MOS V2 Only
IEMOSTotalBlockEntries      PROTO :DWORD                    ; hIEMOS. Returns in eax total no of Datablock entries. For MOS V2 Only

IEMOSFileName               PROTO :DWORD                    ; hIEMOS. Returns in eax pointer to mos full path filename
IEMOSFileNameOnly           PROTO :DWORD, :DWORD            ; hIEMOS, lpszFileNameOnly. eax contains True or false if succesfull. strips filename of path and ext information.
IEMOSFileSize               PROTO :DWORD                    ; hIEMOS. Returns in eax size of mos file in bytes
IEMOSFileCompression        PROTO :DWORD                    ; hIEMOS. Returns in eax -1 = No Mos file, TRUE for MOSCV1, FALSE for MOS V1 or MOS V2 
IEMOSVersion                PROTO :DWORD                    ; hIEMOS. Returns in eax 0 no mos, 1 = MOS V1, 2 = MOS V2, 3 = MOSC 

;-----------------------------------------------------------------------------------------
; IEMOS Structures
;-----------------------------------------------------------------------------------------
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

IFNDEF TILELOOKUP_ENTRY
TILELOOKUP_ENTRY        STRUCT
    TileDataOffset      DD 0    ; Offset to specific tile's data pixels from start of Tile Data ( Offset Palettes + (Size Palettes) + (Size TilelookupEntries) )
TILELOOKUP_ENTRY        ENDS
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


.CONST

IEMOS_ALIGN                 TEXTEQU <ALIGN 16>
; IEMOSOpen open mode:
IEMOS_MODE_WRITE            EQU 0
IEMOS_MODE_READONLY         EQU 1
; MOS Versions:
MOS_VERSION_INVALID         EQU 0 ; Not a MOS or invalid
MOS_VERSION_MOS_V10         EQU 1 ; MOS_V1.0
MOS_VERSION_MOS_V20         EQU 2 ; MOS_V2.0
MOS_VERSION_MOSCV10         EQU 3 ; MOSCV1.0 (Compressed Blocks)







