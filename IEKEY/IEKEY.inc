;==============================================================================
;
; IEKEY
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
; IEKEY Prototypes
;-----------------------------------------------------------------------------------------
IEKEYOpen                   PROTO :DWORD, :DWORD        ; lpszKeyFilename, dwOpenMode. Returns in eax a handle used in other functions: hIEKEY
IEKEYMem                    PROTO :DWORD, :DWORD, :DWORD, :DWORD ; pKEYInMemory, lpszKeyFilename, dwKeyFilesize, dwOpenMode. Returns in eax a handle used in other functions: hIEKEY
IEKEYClose                  PROTO :DWORD                ; hIEKEY returned from IEKEYOpen.
IEKEYSave                   PROTO :DWORD                ; hIEKEY.

IEKEYTotalBifEntries        PROTO :DWORD                ; hIEKEY. Returns in eax total no of bif entries.
IEKEYTotalResEntries        PROTO :DWORD                ; hIEKEY. Returns in eax total no of resource entries.

IEKEYHeader                 PROTO :DWORD                ; hIEKEY. Returns in eax pointer to a KEY_HEADER_V1 structure.
IEKEYBifEntries             PROTO :DWORD
IEKEYResEntries             PROTO :DWORD
IEKEYBifFilenamesEntries    PROTO :DWORD

IEKEYBifEntry               PROTO :DWORD, :DWORD        ; hIEKEY, nBifEntry. Returns in eax pointer to a BIF_ENTRY structure.
IEKEYResEntry               PROTO :DWORD, :DWORD        ; hIEKEY, nResEntry. Returns in eax pointer to a RES_ENTRY structure.
IEKEYBifFilename            PROTO :DWORD, :DWORD        ; hIEKEY, nBifEntry. Returns in eax a pointer to null terminated string containing bif filename.

IEKEYFileName               PROTO :DWORD                ; hIEKEY. Returns in eax pointer to string containing name of key file opened or -1 otherwise.
IEKEYVersion                PROTO :DWORD                ; hIEKEY. Returns in eax 0 no key, 1 = KEY V1, 2 = KEY V1 WIDE, 3 = KEY V1.1 
IEKEYFileSize               PROTO :DWORD

IEKEYFindBifFilenameEntry   PROTO :DWORD, :DWORD        ; hIEKEY, lpszBifFilename. Returns in eax the bif entry index or -1 if not found.
IEKEYFindResource           PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD ; hIEKEY, BifEntry, ResourceIndex, ResourceType. Returns in eax pointer to a RES_ENTRY structure for resource found or -1 if not.
IEKEYFindResourceV11        PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD ; hIEKEY, BifEntry, ResourceIndex, ResourceType. Returns in eax pointer to a RES_ENTRY_V11 structure for resource found or -1 if not.
IEKEYFindResourceByResRef   PROTO :DWORD, :DWORD

IEKEYAddBifEntry            PROTO :DWORD, :DWORD, :DWORD, :DWORD ; hIEKEY, lpszBifFilename, dwBifFilesize, dwBifLocation
IEKEYAddResEntry            PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD

IEKEYWideResName            PROTO :DWORD                ;hIEKEY Returns in eax TRUE if wide resource name 16bytes, or FALSE for 8 bytes 

IEKEYBifEntryFileOffset     PROTO :DWORD, :DWORD, :DWORD;hIEKEY, nBifEntry, lpBifEntriesSize. Returns in eax absolute file offset to a BIF_ENTRY entry.
IEKEYResEntryFileOffset     PROTO :DWORD, :DWORD, :DWORD;hIEKEY, nResEntry, lpResEntriesSize (optional). Returns in eax absolute file offset to a BIF_ENTRY entry.
IEKEYBifFilenamesOffset     PROTO :DWORD, :DWORD        ;hIEKEY, lpBifFilenamesSize (optional). Returns in eax a file offset to biffilename entries or -1 if not valid and size of filenames array in lpBifFilenamesSize

;-----------------------------------------------------------------------------------------



;-----------------------------------------------------------------------------------------
; IEKEY Structures
;-----------------------------------------------------------------------------------------
IFNDEF KEY_HEADER_V11 ; Witcher
KEY_HEADER_V11          STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('KEY ')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V1.1')
    BifEntriesCount     DD 0 ; 0x0008   4 (dword)       Count of BIF entries
    ResEntriesCount     DD 0 ; 0x000c   4 (dword)       Count of resource entries
    dwNull              DD 0 ; 0x0010   4 (dword)       NULL
    OffsetBifEntries    DD 0 ; 0x0014   4 (dword)       Offset (from start of file) to BIF entries
    OffsetResEntries    DD 0 ; 0x0018   4 (dword)       Offset (from start of file) to resource entries
    BuildYear           DD 0 ; 0x001C   4 (dword)       Build Year less 1900
    BuildDay            DD 0 ; 0x0020   4 (dword)       Build Day
    dwNulls             DB 32 DUP (0);   32 bytes       NULL bytes
KEY_HEADER_V11          ENDS
ENDIF

IFNDEF KEY_HEADER_V1
KEY_HEADER_V1           STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('BAM ')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V1 ')
    BifEntriesCount     DD 0 ; 0x0008   4 (dword)       Count of BIF entries
    ResEntriesCount     DD 0 ; 0x000c   4 (dword)       Count of resource entries
    OffsetBifEntries    DD 0 ; 0x0010   4 (dword)       Offset (from start of file) to BIF entries
    OffsetResEntries    DD 0 ; 0x0014   4 (dword)       Offset (from start of file) to resource entries
KEY_HEADER_V1           ENDS
ENDIF

IFNDEF BIF_ENTRY
BIF_ENTRY               STRUCT
    LengthBifFile       DD 0 ; 0x0000   4 (dword)       Length of BIF file
    OffsetBifFilename   DD 0 ; 0x0004   4 (dword)       Offset from start of file to ASCIIZ BIF filename
    LengthBifFilename   DW 0 ; 0x0008   2 (word)        Length, including terminating NUL, of ASCIIZ BIF filename
    BifLocation         DW 0 ; 0x000a   2 (word)        The 16 bits of this field are used individually to mark the location of the relevant file. (MSB) xxxx xxxx ABCD EFGH (LSB) Bits marked A to F determine on which CD the file is stored (A = CD6, F = CD1) Bit G determines if the file is in the \cache directory Bit H determines if the file is in the \data directory
BIF_ENTRY               ENDS
ENDIF

IFNDEF BIF_ENTRY_V11
BIF_ENTRY_V11           STRUCT
    LengthBifFile       DD 0 ; 0x0000   4 (dword)       Length of BIF file
    OffsetBifFilename   DD 0 ; 0x0004   4 (dword)       Offset from start of file to ASCIIZ BIF filename
    LengthBifFilename   DD 0 ; 0x0008   4 (dword)       Length, including terminating NUL, of ASCIIZ BIF filename
BIF_ENTRY_V11           ENDS
ENDIF

IFNDEF RES_ENTRY
RES_ENTRY               STRUCT
    ResourceName        DB 8 DUP (0) ;  8 (byte)        Resource name
    ResourceType        DW 0 ; 0x0008   2 (word)        Resource type
    ResourceLocator     DD 0 ; 0x000a   4 (dword)       Resource locator. The IE resource manager uses 32-bit values as a 'resource index', which codifies the source of the resource as well as which source it refers to. The layout of this value is below. bits 31-20: source index (the ordinal value giving the index of the corresponding BIF entry) bits 19-14: tileset index bits 13- 0: non-tileset file index (any 12 bit value, so long as it matches the value used in the BIF file)
RES_ENTRY               ENDS
ENDIF

IFNDEF RES_ENTRY_V11
RES_ENTRY_V11           STRUCT
    ResourceName        DB 16 DUP (0) ;  8 (byte)       Resource name 16 bytes minus extension
    ResourceType        DW 0 ; 0x0008   2 (word)        Resource type
    ResourceLocator     DD 0 ; 0x000a   4 (dword)       Resource locator. The IE resource manager uses 32-bit values as a 'resource index', which codifies the source of the resource as well as which source it refers to. The layout of this value is below. bits 31-20: source index (the ordinal value giving the index of the corresponding BIF entry) bits 19-14: tileset index bits 13- 0: non-tileset file index (any 12 bit value, so long as it matches the value used in the BIF file)
    ResourceFlags       DD 0 ; 0x000E   4 (dword)       Flags (BIF index is now in this value, (flags & 0xFFF00000) >> 20). The rest appears to define 'fixed' index.
RES_ENTRY_V11           ENDS
ENDIF

IFNDEF RES_ENTRY_V1_WIDE ; SWKotoR
RES_ENTRY_V1_WIDE       STRUCT
    ResourceName        DB 16 DUP (0) ;  16 (byte)      Resource name
    ResourceType        DW 0 ; 0x0010   2 (word)        Resource type
    ResourceLocator     DD 0 ; 0x0014   4 (dword)       Resource locator. The IE resource manager uses 32-bit values as a 'resource index', which codifies the source of the resource as well as which source it refers to. The layout of this value is below. bits 31-20: source index (the ordinal value giving the index of the corresponding BIF entry) bits 19-14: tileset index bits 13- 0: non-tileset file index (any 12 bit value, so long as it matches the value used in the BIF file)
RES_ENTRY_V1_WIDE       ENDS
ENDIF


IEKEY_OPEN_EXCLUSIVE    EQU 0
IEKEY_OPEN_READONLY     EQU 1


