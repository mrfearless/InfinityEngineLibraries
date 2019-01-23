;==============================================================================
;
; IETIS
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
; IETIS Prototypes
;-----------------------------------------------------------------------------------------
IETISOpen                   PROTO :DWORD,:DWORD             ; lpszTisFilename, dwOpenMode. Returns in eax a handle used in other functions: hIETIS
IETISMem                    PROTO :DWORD,:DWORD,:DWORD,:DWORD ; pTISInMemory, lpszTisFilename, dwTisFilesize, dwOpenMode. Returns in eax a handle used in other functions: hIETIS
IETISClose                  PROTO :DWORD                    ; hIETIS returned from IETISOpen.

; Pointers to parts of TIS file:
IETISHeader                 PROTO :DWORD                    ; hIETIS. Returns in eax pointer to a TISV1_HEADER structure.
IETISTileDataEntries        PROTO :DWORD                    ; hIETIS. Returns in eax pointer to TISV1_TILEDATA array entries
IETISTileDataEntry          PROTO :DWORD,:DWORD             ; hIETIS, nTile. Returns in eax pointer to specific TISV1_TILEDATA entry

; TIS Basic Information:
IETISTotalTiles             PROTO :DWORD                    ; hIETIS. Returns in eax total tiles in TIS
IETISTileDimension          PROTO :DWORD                    ; hIETIS. Returns in eax tile dimension (tile size is x * x)

; TIS Tile Data Information:
IETISTileRAW                PROTO :DWORD,:DWORD             ; hIETIS, nTile. Returns in pointer to RAW tile data.
IETISTilePalette            PROTO :DWORD,:DWORD             ; hIETIS, nTile. Returns in eax pointer to the tile's specific palette (256 entries of RGBQUADs)
IETISTilePaletteValue       PROTO :DWORD,:DWORD,:DWORD      ; hIETIS, nTile, PaletteIndex. eax contains RGBQUAD or -1 if not valid.

; TIS File & Version Information:
IETISFileName               PROTO :DWORD                    ; hIETIS. Returns in eax pointer to tis full path filename
IETISFileNameOnly           PROTO :DWORD,:DWORD             ; hIETIS, lpszFileNameOnly. eax contains True or false if succesfull. strips filename of path and ext information.
IETISFileSize               PROTO :DWORD                    ; hIETIS. Returns in eax size of tis file in bytes
IETISVersion                PROTO :DWORD                    ; hIETIS. Returns in eax 0 no tis, 1 = TIS V1, 2 = TIS V1 PVRZ 

;-----------------------------------------------------------------------------------------
; IETIS Structures
;-----------------------------------------------------------------------------------------

IFNDEF TISV1_HEADER
TISV1_HEADER            STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('TIS ')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V1  ')
    TilesCount          DD 0 ; 0x0008   4 (dword)       Count of tiles within this tileset
    TilesSectionLength  DD 0 ; 0x000c   4 (dword)       Length of tiles section *
    OffsetTilesData     DD 0 ; 0x0010   4 (dword)       Tile header size, offset to tiles, always 24d
    TileDimension       DD 0 ; 0x0014   4 (dword)       Dimension of 1 tile in pixels (64x64) 64 ?
TISV1_HEADER            ENDS
ENDIF

; * Palette based TIS: Length of tiles section is 5120 bytes
; 5120 = (256 palette entries * SIZEOF RGBQUAD) + (tile pixel dimension x tile pixel dimension)) = (256*4)+(64x64) = (1024 + 4096)
; PVRZ based TIS:  Length of tiles section is 12 bytes

IFNDEF TISV1_TILEDATA
TISV1_TILEDATA          STRUCT ; 5120 bytes
    TilePalette         DB (SIZEOF RGBQUAD * 256) DUP (0) ; Palette
    TilePixelData       DB (64 * 64) DUP (0)
TISV1_TILEDATA          ENDS
ENDIF

IFNDEF TISV1_TILEDATA_PVRZ
TISV1_TILEDATA_PVRZ     STRUCT ; 12 bytes
    PVRZPage            DD 0 ; Filenames of referenced PVRZ resources are made up from the first character of the TIS filename, the four digits of the area code, the optional 'N' from night tilesets and this page value as a zero-padded two digits number. Example: AR2600N.TIS would refer to A2600Nxx.PVRZ where xx indicates the PVRZ page. Special: A value of -1 (0xffffffff) indicates a solid black tile.
    XCoord              DD 0 ; PVRZ texture coordinate X
    YCoord              DD 0 ; PVRZ texture coordinate X
TISV1_TILEDATA_PVRZ     ENDS
ENDIF


.CONST

IETIS_ALIGN                 TEXTEQU <ALIGN 16>
; IETISOpen open mode:
IETIS_MODE_WRITE            EQU 0
IETIS_MODE_READONLY         EQU 1
; MOS Versions:
TIS_VERSION_INVALID         EQU 0 ; Not a TIS or invalid
TIS_VERSION_TIS_V1          EQU 1 ; TIS_V1
TIS_VERSION_TIS_V1P         EQU 2 ; TIS_V1 PVRZ



