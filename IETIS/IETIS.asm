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


.686
.MMX
.XMM
.model flat,stdcall
option casemap:none

include windows.inc
include kernel32.inc
include user32.inc
include masm32.inc

includelib kernel32.lib
includelib user32.lib
includelib masm32.lib


include IETIS.inc

;DEBUG32 EQU 1
;IFDEF DEBUG32
;    PRESERVEXMMREGS equ 1
;    includelib M:\Masm32\lib\Debug32.lib
;    DBG32LIB equ 1
;    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
;    include M:\Masm32\include\debug32.inc
;ENDIF


;-------------------------------------------------------------------------
; Internal functions:
;-------------------------------------------------------------------------
TISSignature            PROTO :DWORD
TISJustFname            PROTO :DWORD, :DWORD


;-------------------------------------------------------------------------
; TIS Structures
;-------------------------------------------------------------------------
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


;-------------------------------------------------------------------------
; Structures for internal use
;-------------------------------------------------------------------------
IFNDEF TISINFO
TISINFO                     STRUCT
    TISOpenMode             DD 0
    TISFilename             DB MAX_PATH DUP (0)
    TISFilesize             DD 0
    TISVersion              DD 0
    TISHeaderPtr            DD 0
    TISHeaderSize           DD 0
    TISTileDataPtr          DD 0 
    TISTileDataSize         DD 0
    TISMemMapPtr            DD 0
    TISMemMapHandle         DD 0
    TISFileHandle           DD 0    
TISINFO                     ENDS
ENDIF


.CONST




.DATA
TISV1Header             DB "TIS V1  ",0
NEWTISHeader            TISV1_HEADER <"TIS ", "V1  ", 0, 0, 24d, 64d>



.CODE

IETIS_ALIGN
;------------------------------------------------------------------------------
; IETISOpen
;------------------------------------------------------------------------------
IETISOpen PROC USES EBX lpszTisFilename:DWORD, dwOpenMode:DWORD
    ret
IETISOpen ENDP


IETIS_ALIGN
;------------------------------------------------------------------------------
; IETISMem
;------------------------------------------------------------------------------
IETISMem PROC USES EBX pTISInMemory:DWORD, lpszTisFilename:DWORD, dwTisFilesize:DWORD, dwOpenMode:DWORD
    ret
IETISMem ENDP


IETIS_ALIGN
;------------------------------------------------------------------------------
; IETISClose
;------------------------------------------------------------------------------
IETISClose PROC USES EBX hIETIS:DWORD
    ret
IETISClose ENDP


IETIS_ALIGN
;------------------------------------------------------------------------------
; IETISHeader - Returns in eax a pointer to header or NULL if not valid
;------------------------------------------------------------------------------
IETISHeader PROC USES EBX hIETIS:DWORD
    .IF hIETIS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIETIS
    mov eax, [ebx].TISINFO.TISHeaderPtr
    ret
IETISHeader ENDP


IETIS_ALIGN
;------------------------------------------------------------------------------
; IETISTileDataEntries - Returns in eax a pointer to the array of TISV1_TILEDATA
; / TISV1_TILEDATA_PVRZ or NULL if not valid
;------------------------------------------------------------------------------
IETISTileDataEntries PROC USES EBX hIETIS:DWORD
    .IF hIETIS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIETIS
    mov eax, [ebx].TISINFO.TISTileDataPtr
    ret
IETISTileDataEntries ENDP


IETIS_ALIGN
;------------------------------------------------------------------------------
; IETISTileDataEntry - Returns in eax a pointer to a specific TISV1_TILEDATA 
; entry / TISV1_TILEDATA_PVRZ or NULL if not valid
;------------------------------------------------------------------------------
IETISTileDataEntry PROC USES EBX hIETIS:DWORD, nTile:DWORD
    LOCAL TileDataEntries:DWORD

    .IF hIETIS == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IETISTotalTiles, hIETIS
    .IF nTile >= eax ; 0 based tile index
        mov eax, NULL
        ret
    .ENDIF        
    
    Invoke IETISTileDataEntries, hIETIS
    .IF eax == NULL
        ret
    .ENDIF
    .IF nTile == 0
        ; eax contains TileDataEntries which is tile 0's start
        ret
    .ENDIF    
    mov TileDataEntries, eax    
    
    Invoke IETISVersion, hIETIS
    .IF eax == TIS_VERSION_TIS_V1
        mov ebx, SIZEOF TISV1_TILEDATA
    .ELSEIF eax == TIS_VERSION_TIS_V1P
        mov ebx, SIZEOF TISV1_TILEDATA_PVRZ
    .ELSE
        mov eax, 0
        ret
    .ENDIF
    mov eax, nTile
    mul ebx
    add eax, TileDataEntries    
    
    ret
IETISTileDataEntry ENDP


IETIS_ALIGN
;------------------------------------------------------------------------------
; IETISTotalTiles - Returns in eax total tiles in tis
;------------------------------------------------------------------------------
IETISTotalTiles PROC USES EBX hIETIS:DWORD
    .IF hIETIS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIETIS
    mov ebx, [ebx].TISINFO.TISHeaderPtr
    .IF ebx != 0
        mov eax, [ebx].TISV1_HEADER.TilesCount
    .ELSE
        mov eax, 0
    .ENDIF
    ret
IETISTotalTiles ENDP


IETIS_ALIGN
;------------------------------------------------------------------------------
; IETISTileDimension
;------------------------------------------------------------------------------
IETISTileDimension PROC USES EBX hIETIS:DWORD
    ret
IETISTileDimension ENDP


IETIS_ALIGN
;------------------------------------------------------------------------------
; IETISTileRAW
;------------------------------------------------------------------------------
IETISTileRAW PROC USES EBX hIETIS:DWORD, nTile:DWORD
    ret
IETISTileRAW ENDP


IETIS_ALIGN
;------------------------------------------------------------------------------
; IETISTilePalette
;------------------------------------------------------------------------------
IETISTilePalette PROC USES EBX hIETIS:DWORD, nTile:DWORD
    ret
IETISTilePalette ENDP


IETIS_ALIGN
;------------------------------------------------------------------------------
; IETISTilePaletteValue
;------------------------------------------------------------------------------
IETISTilePaletteValue PROC USES EBX hIETIS:DWORD, nTile:DWORD, PaletteIndex:DWORD
    ret
IETISTilePaletteValue ENDP



IETIS_ALIGN
;------------------------------------------------------------------------------
; IETISFileName - returns in eax pointer to zero terminated string contained 
; filename that is open or NULL if not opened
;------------------------------------------------------------------------------
IETISFileName PROC USES EBX hIETIS:DWORD
    LOCAL TisFilename:DWORD
    .IF hIETIS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIETIS
    lea eax, [ebx].TISINFO.TISFilename
    mov TisFilename, eax
    Invoke szLen, TisFilename
    .IF eax == 0
        mov eax, NULL
    .ELSE
        mov eax, TisFilename
    .ENDIF
    ret
IETISFileName endp


IETIS_ALIGN
;------------------------------------------------------------------------------
; IETISFileNameOnly - returns in eax true or false if it managed to pass to the 
; buffer pointed at lpszFileNameOnly, the stripped filename without extension
;------------------------------------------------------------------------------
IETISFileNameOnly PROC hIETIS:DWORD, lpszFileNameOnly:DWORD
    Invoke IETISFileName, hIETIS
    .IF eax == NULL
        mov eax, FALSE
        ret
    .ENDIF
    
    Invoke TISJustFname, eax, lpszFileNameOnly
    
    mov eax, TRUE
    ret
IETISFileNameOnly endp


IETIS_ALIGN
;------------------------------------------------------------------------------
; IETISFileSize - returns in eax size of file or NULL
;------------------------------------------------------------------------------
IETISFileSize PROC USES EBX hIETIS:DWORD
    .IF hIETIS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIETIS
    mov eax, [ebx].TISINFO.TISFilesize
    ret
IETISFileSize endp


IETIS_ALIGN
;------------------------------------------------------------------------------
; 0 = No Tis file, 1 = TIS V1, 2 = TIS V1 PVRZ 
;------------------------------------------------------------------------------
IETISVersion PROC USES EBX hIETIS:DWORD
    .IF hIETIS == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIETIS
    mov eax, [ebx].TISINFO.TISVersion
    ret
IETISVersion ENDP


IETIS_ALIGN
;******************************************************************************
; Checks the TIS signatures to determine if they are valid
;******************************************************************************
TISSignature PROC USES EBX pTIS:DWORD
    ; check signatures to determine version
    mov ebx, pTIS
    mov eax, [ebx]
    .IF eax == ' SIT' ; TIS
        add ebx, 4
        mov eax, [ebx]
        .IF eax == '  1V' ; V1
            mov ebx, pTIS
            mov eax, [ebx].TISV1_HEADER.TilesSectionLength
            .IF eax == 5120d ; Palette based
                mov eax, TIS_VERSION_TIS_V1
            .ELSEIF eax == 12 ; PVRZ
                mov eax, TIS_VERSION_TIS_V1P
            .ELSE
                mov eax, TIS_VERSION_INVALID
            .ENDIF
        .ELSE
            mov eax, TIS_VERSION_INVALID
        .ENDIF
    .ELSE
        mov eax, TIS_VERSION_INVALID
    .ENDIF
    ret
TISSignature endp


IETIS_ALIGN
;******************************************************************************
; Strip path name to just filename Without extention
;******************************************************************************
TISJustFname PROC szFilePathName:DWORD, szFileName:DWORD
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
TISJustFname ENDP






END
