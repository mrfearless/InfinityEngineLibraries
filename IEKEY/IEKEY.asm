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


include IEKEY.inc

;DEBUGLOG EQU 1
IFDEF DEBUGLOG
    include DebugLogLIB.asm
ENDIF
;DEBUG32 EQU 1

IFDEF DEBUG32
    PRESERVEXMMREGS equ 1
    includelib M:\Masm32\lib\Debug32.lib
    DBG32LIB equ 1
    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
    include M:\Masm32\include\debug32.inc
ENDIF

KEYSignature            PROTO :DWORD
KEYJustFname            PROTO :DWORD, :DWORD
KEYAllocStructureMemory PROTO :DWORD, :DWORD, :DWORD

KEYV1Mem                PROTO :DWORD, :DWORD, :DWORD, :DWORD ; KEY V1
KEYV1WMem               PROTO :DWORD, :DWORD, :DWORD, :DWORD ; wide KEY V1 version
KEYV11Mem               PROTO :DWORD, :DWORD, :DWORD, :DWORD ; KEY V1.1

KEYSearchLoopFwd        PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
KEYSearchLoopBck        PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
KEYSearchLoopFwdV11     PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
KEYSearchLoopBckV11     PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD




IFNDEF KEY_HEADER_V1
KEY_HEADER_V1           STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('KEY ')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V1  ')
    BifEntriesCount     DD 0 ; 0x0008   4 (dword)       Count of BIF entries
    ResEntriesCount     DD 0 ; 0x000c   4 (dword)       Count of resource entries
    OffsetBifEntries    DD 0 ; 0x0010   4 (dword)       Offset (from start of file) to BIF entries
    OffsetResEntries    DD 0 ; 0x0014   4 (dword)       Offset (from start of file) to resource entries
KEY_HEADER_V1           ENDS
ENDIF

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
    ResourceName        DB 16 DUP (0) ;  16 (byte)      Resource name 16 bytes minus extension
    ResourceType        DW 0 ; 0x0010   2 (word)        Resource type
    ResourceLocator     DD 0 ; 0x0014   4 (dword)       Resource locator. The IE resource manager uses 32-bit values as a 'resource index', which codifies the source of the resource as well as which source it refers to. The layout of this value is below. bits 31-20: source index (the ordinal value giving the index of the corresponding BIF entry) bits 19-14: tileset index bits 13- 0: non-tileset file index (any 12 bit value, so long as it matches the value used in the BIF file)
RES_ENTRY_V1_WIDE       ENDS
ENDIF

IFNDEF BIF_FILENAME
BIF_FILENAME            STRUCT
    BifFilenameLength   DD 0
    BifFilename         DB MAX_PATH DUP (0)
BIF_FILENAME            ENDS
ENDIF

IFNDEF KEYINFO
KEYINFO                 STRUCT
    KEYOpenMode         DD 0
    KEYFilename         DB MAX_PATH DUP (0)
    KEYFilesize         DD 0
    KEYVersion          DD 0
    KEYHeaderPtr        DD 0
    KEYHeaderSize       DD 0
    KEYBifEntriesPtr    DD 0
    KEYBifEntriesSize   DD 0
    KEYResEntriesPtr    DD 0
    KEYResEntriesSize   DD 0
    KEYBifFilenamesPtr  DD 0
    KEYBifFilenamesSize DD 0
    KEYMemMapPtr        DD 0
    KEYMemMapHandle     DD 0
    KEYFileHandle       DD 0
    KEYWideResEntries   DD 0
KEYINFO                 ENDS
ENDIF



.DATA
NEWKEYHeader            KEY_HEADER_V1 <" YEK", "  1V", 0, 0, 24d, 24d>
NEWKEYV11Header         KEY_HEADER_V11 <" YEK", "1.1V", 0, 0, 0, 24d, 24d, 0, 0, >
KEYV1Header             db "KEY V1  ",0
KEYV11Header            db "KEY V1.1",0
KEYXHeader              db 12 dup (0)
szBackSlash             db '\',0
szForwardSlash          db '/',0
szBifExt                db '.bif',0
szKeyExt                db '.key',0
.DATA?
IFDEF DEBUG32
    DbgVar              dd ?
ENDIF

.CODE


;-------------------------------------------------------------------------------------
; IEKEYOpen - Returns handle in eax of opened key file. NULL if could not alloc enough mem
;-------------------------------------------------------------------------------------
IEKEYOpen PROC PUBLIC USES EBX lpszKeyFilename:DWORD, dwOpenMode:DWORD ; 0 = write, 1 = readonly
    LOCAL hIEKEY:DWORD
    LOCAL hKEYFile:DWORD
    LOCAL KEYFilesize:DWORD
    LOCAL SigReturn:DWORD
    LOCAL KEYMemMapHandle:DWORD
    LOCAL KEYMemMapPtr:DWORD
    
    .IF dwOpenMode == 1 ; readonly
        Invoke CreateFile, lpszKeyFilename, GENERIC_READ, FILE_SHARE_READ+FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ELSE
        Invoke CreateFile, lpszKeyFilename, GENERIC_READ+GENERIC_WRITE, FILE_SHARE_READ+FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ENDIF
    .IF eax == INVALID_HANDLE_VALUE
        mov eax, FALSE
        ret
    .ENDIF
    
    mov hKEYFile, eax
;    Invoke KEYSignature, hKEYFile
;    mov SigReturn, eax
;    .IF eax == 0 ; not a valid bam file
;        ;PrintText 'BAMOpen::Not A Valid BAM'
;        Invoke CloseHandle, hKEYFile
;        mov eax, FALSE
;        ret
;    .ENDIF

    Invoke GetFileSize, hKEYFile, NULL
    mov KEYFilesize, eax

    ;---------------------------------------------------                
    ; File Mapping: Create file mapping for main .key
    ;---------------------------------------------------
    .IF dwOpenMode == 1 ; readonly
        Invoke CreateFileMapping, hKEYFile, NULL, PAGE_READONLY, 0, 0, NULL ; Create memory mapped file
    .ELSE   
        Invoke CreateFileMapping, hKEYFile, NULL, PAGE_READWRITE, 0, 0, NULL ; Create memory mapped file
    .ENDIF 
    .IF eax == NULL
        ;PrintText 'Mapping Failed'
        mov eax, FALSE
        ret
    .ENDIF
    mov KEYMemMapHandle, eax
    
    .IF dwOpenMode == 1 ; readonly
        Invoke MapViewOfFileEx, KEYMemMapHandle, FILE_MAP_READ, 0, 0, 0, NULL
    .ELSE
        Invoke MapViewOfFileEx, KEYMemMapHandle, FILE_MAP_ALL_ACCESS, 0, 0, 0, NULL
    .ENDIF
    .IF eax == NULL
        ;PrintText 'Mapping View Failed'
        mov eax, FALSE
        ret
    .ENDIF
    mov KEYMemMapPtr, eax       


    Invoke KEYSignature, KEYMemMapPtr ;hBIFFile
    mov SigReturn, eax


    .IF SigReturn == 0 ; not a valid bif file
        Invoke UnmapViewOfFile, KEYMemMapPtr
        Invoke CloseHandle, KEYMemMapHandle
        Invoke CloseHandle, hKEYFile
        mov eax, NULL
        ret    
    
    .ELSE
        Invoke IEKEYMem, KEYMemMapPtr, lpszKeyFilename, KEYFilesize, dwOpenMode
        mov hIEKEY, eax
        .IF hIEKEY == NULL
            Invoke UnmapViewOfFile, KEYMemMapPtr
            Invoke CloseHandle, KEYMemMapHandle
            Invoke CloseHandle, hKEYFile
            mov eax, NULL
            ret    
        .ENDIF
        
        .IF dwOpenMode == 0 ; write (default)
            Invoke UnmapViewOfFile, KEYMemMapPtr
            Invoke CloseHandle, KEYMemMapHandle
            Invoke CloseHandle, hKEYFile
        .ELSE ; else readonly, so keep mapping around till we close file
            mov ebx, hIEKEY
            mov eax, KEYMemMapHandle
            mov [ebx].KEYINFO.KEYMemMapHandle, eax
            mov eax, hKEYFile
            mov [ebx].KEYINFO.KEYFileHandle, eax
        .ENDIF
    .ENDIF
    
    ; save original version to handle for later use so we know if orignal file opened was standard BIFF or a compressed BIF_ or BIFC file, if 0 then it was in mem so we assume BIFF
    mov ebx, hIEKEY
    mov eax, SigReturn
    mov [ebx].KEYINFO.KEYVersion, eax
       
    mov eax, hIEKEY
    IFDEF DEBUG32
        ;PrintDec hIEKEY
    ENDIF
    ret
IEKEYOpen ENDP


;-------------------------------------------------------------------------------------
; IEKEYNew - Returns handle in eax of new key file. NULL if could not alloc enough mem
;-------------------------------------------------------------------------------------
IEKEYNew PROC PUBLIC USES EBX
    LOCAL hIEKEY:DWORD
    LOCAL KEYMemMapPtr:DWORD
    LOCAL TotalBifEntries:DWORD
    LOCAL TotalResEntries:DWORD
    LOCAL OffsetBifEntries:DWORD
    LOCAL OffsetResEntries:DWORD
    LOCAL OffsetBifFilenames:DWORD

    
    ;----------------------------------
    ; Alloc mem for our IEKEY Handle
    ;----------------------------------
    Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, SIZEOF KEYINFO
    .IF eax == NULL
        ret
    .ENDIF
    mov hIEKEY, eax
    
    mov ebx, hIEKEY
    mov eax, 0 ; write mode
    mov [ebx].KEYINFO.KEYOpenMode, eax
    ;mov eax, KEYMemMapPtr
    ;mov [ebx].KEYINFO.KEYMemMapPtr, eax
    
    ;lea eax, [ebx].KEYINFO.KEYFilename
    ;Invoke szCopy, lpszKeyFilename, eax
    
    mov ebx, hIEKEY
    mov eax, SIZEOF KEY_HEADER_V1
    mov [ebx].KEYINFO.KEYFilesize, eax
    mov eax, 1
    mov [ebx].KEYINFO.KEYVersion, eax
    

    ;----------------------------------
    ; KEY Header
    ;----------------------------------
    Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, SIZEOF KEY_HEADER_V1
    .IF eax == NULL
        Invoke GlobalFree, hIEKEY
        mov eax, NULL
        ret
    .ENDIF    
    mov ebx, hIEKEY
    mov [ebx].KEYINFO.KEYHeaderPtr, eax
    lea ebx, NEWKEYHeader ;KEYMemMapPtr
    Invoke RtlMoveMemory, eax, ebx, SIZEOF KEY_HEADER_V1

    mov ebx, hIEKEY
    mov eax, SIZEOF KEY_HEADER_V1
    mov [ebx].KEYINFO.KEYHeaderSize, eax     

    mov eax, hIEKEY
    
    ret

IEKEYNew endp


;-------------------------------------------------------------------------------------
; IEKEYAddBifEntry - Returns in eax of pointer to new bif entry or -1 if failed.
; dynamically allocs mem for each new entry and adjust KEYINFO struct to point to new
; block of realloc mem, adds filename and some bif entry data.
;-------------------------------------------------------------------------------------
IEKEYAddBifEntry PROC PUBLIC USES EBX hIEKEY:DWORD, lpszBifFilename:DWORD, dwBifFilesize:DWORD, dwBifLocation:DWORD
    LOCAL KEYBifEntries:DWORD
    LOCAL KEYBifFilenameEntries:DWORD
    LOCAL TotalBifEntries:DWORD
    LOCAL BifEntryOffset:DWORD
    LOCAL BifFilenameEntryOffset:DWORD
    LOCAL LengthBifFilename:DWORD
    
    .IF hIEKEY == NULL
        mov eax, -1
        ret
    .ENDIF
    
    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYOpenMode
    .IF eax == 1 ; readonly, so dont allow additions
        mov eax, -1
        ret
    .ENDIF
    Invoke IEKEYTotalBifEntries, hIEKEY
    mov TotalBifEntries, eax
    
    Invoke IEKEYBifEntries, hIEKEY
    mov KEYBifEntries, eax

    Invoke IEKEYBifFilenamesEntries, hIEKEY
    mov KEYBifFilenameEntries, eax    
    
    ; inc total bif entries and alloc/realloc mem for them
    inc TotalBifEntries
    Invoke KEYAllocStructureMemory, Addr KEYBifEntries, TotalBifEntries, SIZEOF BIF_ENTRY
    .IF eax == -1
        ret
    .ENDIF
    mov BifEntryOffset, eax
    
    ; alloc mem for bif filename
    Invoke KEYAllocStructureMemory, Addr KEYBifFilenameEntries, TotalBifEntries, SIZEOF BIF_FILENAME
    .IF eax == -1
        ret
    .ENDIF
    mov BifFilenameEntryOffset, eax
    
    ; save KEYBifEntries back to KEYINFO struct
    mov ebx, hIEKEY
    mov eax, KEYBifEntries
    mov [ebx].KEYINFO.KEYBifEntriesPtr, eax
    add [ebx].KEYINFO.KEYBifEntriesSize, SIZEOF BIF_ENTRY
    mov eax, KEYBifFilenameEntries
    mov [ebx].KEYINFO.KEYBifFilenamesPtr, eax
    mov eax, TotalBifEntries
    mov [ebx].KEYINFO.KEYHeaderPtr.KEY_HEADER_V1.BifEntriesCount, eax
    
    ; save some bif entry stuff - length of file, length of filename, location data
    mov ebx, BifEntryOffset
    mov eax, dwBifFilesize
    mov [ebx].BIF_ENTRY.LengthBifFile, eax
    
    Invoke szLen, lpszBifFilename
    mov LengthBifFilename, eax
    mov ebx, BifEntryOffset
    mov word ptr [ebx].BIF_ENTRY.LengthBifFilename, ax
    
    mov eax, dwBifLocation
    mov word ptr [ebx].BIF_ENTRY.BifLocation, ax
    
    ; save filename
    mov ebx, BifFilenameEntryOffset
    mov eax, LengthBifFilename
    mov [ebx].BIF_FILENAME.BifFilenameLength, eax
    lea eax, [ebx].BIF_FILENAME.BifFilename
    Invoke szCopy, lpszBifFilename, eax
    
    mov eax, BifEntryOffset
    ret

IEKEYAddBifEntry endp


IEKEYDelBifEntry PROC
    
    
    ret

IEKEYDelBifEntry endp

;-------------------------------------------------------------------------------------
; IEKEYAddResEntry - Returns in eax of pointer to new res entry or -1 if failed.
; dynamically allocs mem for each new entry and adjust KEYINFO struct to point to new
; block of realloc mem, adds res entry data and codifies resource index.
; TODO - check for already existing resref? keyfile doesnt seem to have duplicates.
;-------------------------------------------------------------------------------------
IEKEYAddResEntry PROC PUBLIC USES EBX hIEKEY:DWORD, lpszResourceName:DWORD, dwResourceType:DWORD, ResourceIndex:DWORD, dwBifFilenameNo:DWORD
    LOCAL KEYResEntries:DWORD
    LOCAL TotalResEntries:DWORD
    LOCAL ResEntryOffset:DWORD
    LOCAL ResourceLocator:DWORD
    
    .IF hIEKEY == NULL
        mov eax, -1
        ret
    .ENDIF
    
    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYOpenMode
    .IF eax == 1 ; readonly, so dont allow additions
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEKEYTotalResEntries, hIEKEY
    mov TotalResEntries, eax
    
    Invoke IEKEYResEntries, hIEKEY
    mov KEYResEntries, eax
    
    ; inc total res entries and alloc/realloc mem for them
    inc TotalResEntries
    Invoke KEYAllocStructureMemory, Addr KEYResEntries, TotalResEntries, SIZEOF RES_ENTRY
    .IF eax == -1
        ret
    .ENDIF
    mov ResEntryOffset, eax
    
    ; save KEYBifEntries back to KEYINFO struct
    mov ebx, hIEKEY
    mov eax, KEYResEntries
    mov [ebx].KEYINFO.KEYResEntriesPtr, eax
    add [ebx].KEYINFO.KEYResEntriesSize, SIZEOF RES_ENTRY
    mov eax, TotalResEntries
    mov [ebx].KEYINFO.KEYHeaderPtr.KEY_HEADER_V1.ResEntriesCount, eax
    
    ; save some res entry stuff - resource name, type and index
    mov ebx, ResEntryOffset
    mov eax, lpszResourceName
    lea ebx, [ebx].RES_ENTRY.ResourceName
    Invoke RtlMoveMemory, ebx, eax, 8d
    
    mov ebx, ResEntryOffset
    mov eax, dwResourceType
    mov word ptr [ebx].RES_ENTRY.ResourceType, ax
    
    ; codify resourceindex with bif entry no
    mov eax, dwBifFilenameNo
    shl eax, 20d
    
    .IF dwResourceType == 03EBh ; TIS
        mov ebx, ResourceIndex
        shr ebx, 14d
        add eax, ebx
    .ELSE
        add eax, ResourceIndex
    .ENDIF
    ;mov ResourceLocator, eax
    mov ebx, ResEntryOffset
    mov [ebx].RES_ENTRY.ResourceLocator, eax
    
    mov eax, ResEntryOffset
    ret

IEKEYAddResEntry endp


IEKEYDelResEntry PROC
    
    
    ret

IEKEYDelResEntry endp

KEYAddBifFilenameEntry PROC
    
    
    ret

KEYAddBifFilenameEntry endp


KEYDelBifFilenameEntry PROC
    
    
    ret

KEYDelBifFilenameEntry endp


;-------------------------------------------------------------------------------------
; IEKEYMem - Returns handle in eax of opened key file that is already loaded into memory. NULL if could not alloc enough mem
;-------------------------------------------------------------------------------------
IEKEYMem PROC PUBLIC USES EBX pKEYInMemory:DWORD, lpszKeyFilename:DWORD, dwKeyFilesize:DWORD, dwOpenMode:DWORD

    Invoke KEYSignature, pKEYInMemory

    .IF eax == 0 ; invalid file
        mov eax, NULL
        ret
    
    .ELSEIF eax == 1
        Invoke KEYV1Mem, pKEYInMemory, lpszKeyFilename, dwKeyFilesize, dwOpenMode
    
    .ELSEIF eax == 2
        Invoke KEYV1WMem, pKEYInMemory, lpszKeyFilename, dwKeyFilesize, dwOpenMode
    
    .ELSEIF eax == 3
        Invoke KEYV11Mem, pKEYInMemory, lpszKeyFilename, dwKeyFilesize, dwOpenMode
        
    .ENDIF

    ret
IEKEYMem ENDP

;-------------------------------------------------------------------------------------
; KEYV1WMem - Returns handle in eax of opened key file that is already loaded into memory. NULL if could not alloc enough mem
;-------------------------------------------------------------------------------------
KEYV1WMem  PROC PUBLIC USES EBX pKEYInMemory:DWORD, lpszKeyFilename:DWORD, dwKeyFilesize:DWORD, dwOpenMode:DWORD
    LOCAL hIEKEY:DWORD
    LOCAL KEYMemMapPtr:DWORD
    LOCAL TotalBifEntries:DWORD
    LOCAL TotalResEntries:DWORD
    LOCAL OffsetBifEntries:DWORD
    LOCAL OffsetResEntries:DWORD
    LOCAL OffsetBifFilenames:DWORD
    LOCAL OffsetFilename:DWORD
    LOCAL BifEntriesSize:DWORD
    LOCAL ResEntriesSize:DWORD
    LOCAL BifFilenamesSize:DWORD
    LOCAL KEYBifFilenamesSize:DWORD
    LOCAL BifEntry:DWORD
    LOCAL BifEntryOffset:DWORD
    LOCAL KEYBifFilenamesPtr:DWORD
   
    
    mov eax, pKEYInMemory
    mov KEYMemMapPtr, eax       

    ;----------------------------------
    ; Alloc mem for our IEKEY Handle
    ;----------------------------------
    Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, SIZEOF KEYINFO
    .IF eax == NULL
        ret
    .ENDIF
    mov hIEKEY, eax
    
    mov ebx, hIEKEY
    mov eax, dwOpenMode
    mov [ebx].KEYINFO.KEYOpenMode, eax
    mov eax, KEYMemMapPtr
    mov [ebx].KEYINFO.KEYMemMapPtr, eax
    
    lea eax, [ebx].KEYINFO.KEYFilename
    Invoke szCopy, lpszKeyFilename, eax
    
    mov ebx, hIEKEY
    mov eax, dwKeyFilesize
    mov [ebx].KEYINFO.KEYFilesize, eax
    mov eax, 1
    mov [ebx].KEYINFO.KEYVersion, eax

    ;----------------------------------
    ; KEY Header
    ;----------------------------------
    .IF dwOpenMode == 0
        Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, SIZEOF KEY_HEADER_V1
        .IF eax == NULL
            Invoke GlobalFree, hIEKEY
            mov eax, NULL
            ret
        .ENDIF    
        mov ebx, hIEKEY
        mov [ebx].KEYINFO.KEYHeaderPtr, eax
        mov ebx, KEYMemMapPtr
        Invoke RtlMoveMemory, eax, ebx, SIZEOF KEY_HEADER_V1
    .ELSE
        mov ebx, hIEKEY
        mov eax, KEYMemMapPtr
        mov [ebx].KEYINFO.KEYHeaderPtr, eax
    .ENDIF
    mov ebx, hIEKEY
    mov eax, SIZEOF KEY_HEADER_V1
    mov [ebx].KEYINFO.KEYHeaderSize, eax    

    ;----------------------------------
    ; Bif & Res Counts, Offsets & Sizes
    ;----------------------------------
    mov ebx, [ebx].KEYINFO.KEYHeaderPtr
    mov eax, [ebx].KEY_HEADER_V1.BifEntriesCount
    mov TotalBifEntries, eax
    mov eax, [ebx].KEY_HEADER_V1.ResEntriesCount
    mov TotalResEntries, eax
    mov eax, [ebx].KEY_HEADER_V1.OffsetBifEntries
    mov OffsetBifEntries, eax
    mov eax, [ebx].KEY_HEADER_V1.OffsetResEntries
    mov OffsetResEntries, eax
    
    
    .IF OffsetBifEntries > 24d ; wide 16bytes char resource name
        mov ebx, hIEKEY
        mov [ebx].KEYINFO.KEYWideResEntries, TRUE
    .ELSE
        mov ebx, hIEKEY
        mov [ebx].KEYINFO.KEYWideResEntries, FALSE
    .ENDIF
    
    mov eax, TotalBifEntries
    mov ebx, SIZEOF BIF_ENTRY
    mul ebx
    mov BifEntriesSize, eax
    
    mov eax, TotalResEntries
    mov ebx, SIZEOF RES_ENTRY_V1_WIDE
    mul ebx
    mov ResEntriesSize, eax
    
    mov eax, OffsetBifEntries
    add eax, BifEntriesSize
    mov OffsetBifFilenames, eax
    
    mov eax, OffsetResEntries
    mov ebx, OffsetBifFilenames
    sub eax, ebx
    mov BifFilenamesSize, eax

    ;----------------------------------
    ; Bif Entries
    ;----------------------------------
    .IF dwOpenMode == 0
        Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, BifEntriesSize
        .IF eax == NULL
            mov ebx, hIEKEY
            mov eax, [ebx].KEYINFO.KEYHeaderPtr
            Invoke GlobalFree, eax    
            Invoke GlobalFree, hIEKEY
            mov eax, NULL    
            ret
        .ENDIF    
        mov ebx, hIEKEY
        mov [ebx].KEYINFO.KEYBifEntriesPtr, eax
    
        mov ebx, KEYMemMapPtr
        add ebx, OffsetBifEntries
        Invoke RtlMoveMemory, eax, ebx, BifEntriesSize
    .ELSE
        mov ebx, hIEKEY
        mov eax, KEYMemMapPtr
        add eax, OffsetBifEntries
        mov [ebx].KEYINFO.KEYBifEntriesPtr, eax
    .ENDIF
    mov ebx, hIEKEY
    mov eax, BifEntriesSize
    mov [ebx].KEYINFO.KEYBifEntriesSize, eax

    ;----------------------------------
    ; Res Entries
    ;----------------------------------    
    .IF dwOpenMode == 0
        Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, ResEntriesSize
        .IF eax == NULL
            mov ebx, hIEKEY
            mov eax, [ebx].KEYINFO.KEYBifEntriesPtr
            Invoke GlobalFree, eax
            mov ebx, hIEKEY
            mov eax, [ebx].KEYINFO.KEYHeaderPtr
            Invoke GlobalFree, eax    
            Invoke GlobalFree, hIEKEY
            mov eax, NULL    
            ret
        .ENDIF    
        mov ebx, hIEKEY
        mov [ebx].KEYINFO.KEYResEntriesPtr, eax
        mov ebx, KEYMemMapPtr
        add ebx, OffsetResEntries
        Invoke RtlMoveMemory, eax, ebx, ResEntriesSize
    .ELSE
        mov ebx, hIEKEY
        mov eax, KEYMemMapPtr
        add eax, OffsetResEntries
        mov [ebx].KEYINFO.KEYResEntriesPtr, eax
    .ENDIF
    mov ebx, hIEKEY
    mov eax, ResEntriesSize
    mov [ebx].KEYINFO.KEYResEntriesSize, eax

    ;----------------------------------
    ; BifFilenames Entries
    ;----------------------------------    
    .IF dwOpenMode == 0
        mov eax, TotalBifEntries
        mov ebx, SIZEOF BIF_FILENAME
        mul ebx
        mov KEYBifFilenamesSize, eax
        Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, KEYBifFilenamesSize
        .IF eax == NULL
            mov ebx, hIEKEY
            mov eax, [ebx].KEYINFO.KEYResEntriesSize
            Invoke GlobalFree, eax
            mov ebx, hIEKEY
            mov eax, [ebx].KEYINFO.KEYBifEntriesPtr
            Invoke GlobalFree, eax
            mov ebx, hIEKEY
            mov eax, [ebx].KEYINFO.KEYHeaderPtr
            Invoke GlobalFree, eax    
            Invoke GlobalFree, hIEKEY
            mov eax, NULL        
            ret
        .ENDIF    
        mov ebx, hIEKEY
        mov [ebx].KEYINFO.KEYBifFilenamesPtr, eax
        mov KEYBifFilenamesPtr, eax
        
        ; loop through filenames and copy each to our structure
        mov eax, KEYMemMapPtr
        add eax, OffsetBifEntries
        mov BifEntryOffset, eax
        
        mov BifEntry, 0
        mov eax, 0
        .WHILE eax < TotalBifEntries
            
            mov ebx, BifEntryOffset
            mov eax, [ebx].BIF_ENTRY.OffsetBifFilename
            add eax, KEYMemMapPtr ; should be at filename in mem mapped file
            mov OffsetFilename, eax ; save this offset
            
            ; calc filename entry to copy to
            mov eax, BifEntry
            mov ebx, SIZEOF BIF_FILENAME
            mul ebx
            add eax, KEYBifFilenamesPtr
            Invoke szCopy, OffsetFilename, eax 
            
            ; adjust vars to loop again        
            mov eax, BifEntryOffset
            add eax, SIZEOF BIF_ENTRY
            mov BifEntryOffset, eax
            ;add BifEntryOffset, SIZEOF BIF_ENTRY
            inc BifEntry
            mov eax, BifEntry
        .ENDW
        
        mov ebx, hIEKEY
        mov eax, KEYBifFilenamesSize
        mov [ebx].KEYINFO.KEYBifFilenamesSize, eax
    .ELSE
        mov ebx, hIEKEY
        mov eax, KEYMemMapPtr
        add eax, OffsetBifFilenames
        mov [ebx].KEYINFO.KEYBifFilenamesPtr, eax
        mov eax, BifFilenamesSize
        mov [ebx].KEYINFO.KEYBifFilenamesSize, eax
    .ENDIF
    IFDEF DEBUG32
        ;PrintDec TotalBifEntries
        ;PrintDec TotalResEntries
    ENDIF
    mov eax, hIEKEY
    ret
KEYV1WMem ENDP


;-------------------------------------------------------------------------------------
; KEYV1Mem - Returns handle in eax of opened key file that is already loaded into memory. NULL if could not alloc enough mem
;-------------------------------------------------------------------------------------
KEYV1Mem PROC PUBLIC USES EBX pKEYInMemory:DWORD, lpszKeyFilename:DWORD, dwKeyFilesize:DWORD, dwOpenMode:DWORD
    LOCAL hIEKEY:DWORD
    LOCAL KEYMemMapPtr:DWORD
    LOCAL TotalBifEntries:DWORD
    LOCAL TotalResEntries:DWORD
    LOCAL OffsetBifEntries:DWORD
    LOCAL OffsetResEntries:DWORD
    LOCAL OffsetBifFilenames:DWORD
    LOCAL OffsetFilename:DWORD
    LOCAL BifEntriesSize:DWORD
    LOCAL ResEntriesSize:DWORD
    LOCAL BifFilenamesSize:DWORD
    LOCAL KEYBifFilenamesSize:DWORD
    LOCAL BifEntry:DWORD
    LOCAL BifEntryOffset:DWORD
    LOCAL KEYBifFilenamesPtr:DWORD

    mov eax, pKEYInMemory
    mov KEYMemMapPtr, eax       

    ;----------------------------------
    ; Alloc mem for our IEKEY Handle
    ;----------------------------------
    Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, SIZEOF KEYINFO
    .IF eax == NULL
        ret
    .ENDIF
    mov hIEKEY, eax
    
    mov ebx, hIEKEY
    mov eax, dwOpenMode
    mov [ebx].KEYINFO.KEYOpenMode, eax
    mov eax, KEYMemMapPtr
    mov [ebx].KEYINFO.KEYMemMapPtr, eax
    
    lea eax, [ebx].KEYINFO.KEYFilename
    Invoke szCopy, lpszKeyFilename, eax
    
    mov ebx, hIEKEY
    mov eax, dwKeyFilesize
    mov [ebx].KEYINFO.KEYFilesize, eax
    mov eax, 1
    mov [ebx].KEYINFO.KEYVersion, eax

    ;----------------------------------
    ; KEY Header
    ;----------------------------------
    .IF dwOpenMode == 0
        Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, SIZEOF KEY_HEADER_V1
        .IF eax == NULL
            Invoke GlobalFree, hIEKEY
            mov eax, NULL
            ret
        .ENDIF    
        mov ebx, hIEKEY
        mov [ebx].KEYINFO.KEYHeaderPtr, eax
        mov ebx, KEYMemMapPtr
        Invoke RtlMoveMemory, eax, ebx, SIZEOF KEY_HEADER_V1
    .ELSE
        mov ebx, hIEKEY
        mov eax, KEYMemMapPtr
        mov [ebx].KEYINFO.KEYHeaderPtr, eax
    .ENDIF
    mov ebx, hIEKEY
    mov eax, SIZEOF KEY_HEADER_V1
    mov [ebx].KEYINFO.KEYHeaderSize, eax    

    ;----------------------------------
    ; Bif & Res Counts, Offsets & Sizes
    ;----------------------------------
    mov ebx, [ebx].KEYINFO.KEYHeaderPtr
    mov eax, [ebx].KEY_HEADER_V1.BifEntriesCount
    mov TotalBifEntries, eax
    mov eax, [ebx].KEY_HEADER_V1.ResEntriesCount
    mov TotalResEntries, eax
    mov eax, [ebx].KEY_HEADER_V1.OffsetBifEntries
    mov OffsetBifEntries, eax
    mov eax, [ebx].KEY_HEADER_V1.OffsetResEntries
    mov OffsetResEntries, eax
    
    
    .IF OffsetBifEntries > 24d ; wide 16bytes char resource name
        mov ebx, hIEKEY
        mov [ebx].KEYINFO.KEYWideResEntries, TRUE
    .ELSE
        mov ebx, hIEKEY
        mov [ebx].KEYINFO.KEYWideResEntries, FALSE
    .ENDIF
    
    mov eax, TotalBifEntries
    mov ebx, SIZEOF BIF_ENTRY
    mul ebx
    mov BifEntriesSize, eax
    
    mov eax, TotalResEntries
    mov ebx, SIZEOF RES_ENTRY_V1_WIDE
    mul ebx
    mov ResEntriesSize, eax
    
    mov eax, OffsetBifEntries
    add eax, BifEntriesSize
    mov OffsetBifFilenames, eax
    
    mov eax, OffsetResEntries
    mov ebx, OffsetBifFilenames
    sub eax, ebx
    mov BifFilenamesSize, eax

    ;----------------------------------
    ; Bif Entries
    ;----------------------------------
    .IF dwOpenMode == 0
        Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, BifEntriesSize
        .IF eax == NULL
            mov ebx, hIEKEY
            mov eax, [ebx].KEYINFO.KEYHeaderPtr
            Invoke GlobalFree, eax    
            Invoke GlobalFree, hIEKEY
            mov eax, NULL    
            ret
        .ENDIF    
        mov ebx, hIEKEY
        mov [ebx].KEYINFO.KEYBifEntriesPtr, eax
    
        mov ebx, KEYMemMapPtr
        add ebx, OffsetBifEntries
        Invoke RtlMoveMemory, eax, ebx, BifEntriesSize
    .ELSE
        mov ebx, hIEKEY
        mov eax, KEYMemMapPtr
        add eax, OffsetBifEntries
        mov [ebx].KEYINFO.KEYBifEntriesPtr, eax
    .ENDIF
    mov ebx, hIEKEY
    mov eax, BifEntriesSize
    mov [ebx].KEYINFO.KEYBifEntriesSize, eax

    ;----------------------------------
    ; Res Entries
    ;----------------------------------    
    .IF dwOpenMode == 0
        Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, ResEntriesSize
        .IF eax == NULL
            mov ebx, hIEKEY
            mov eax, [ebx].KEYINFO.KEYBifEntriesPtr
            Invoke GlobalFree, eax
            mov ebx, hIEKEY
            mov eax, [ebx].KEYINFO.KEYHeaderPtr
            Invoke GlobalFree, eax    
            Invoke GlobalFree, hIEKEY
            mov eax, NULL    
            ret
        .ENDIF    
        mov ebx, hIEKEY
        mov [ebx].KEYINFO.KEYResEntriesPtr, eax
        mov ebx, KEYMemMapPtr
        add ebx, OffsetResEntries
        Invoke RtlMoveMemory, eax, ebx, ResEntriesSize
    .ELSE
        mov ebx, hIEKEY
        mov eax, KEYMemMapPtr
        add eax, OffsetResEntries
        mov [ebx].KEYINFO.KEYResEntriesPtr, eax
    .ENDIF
    mov ebx, hIEKEY
    mov eax, ResEntriesSize
    mov [ebx].KEYINFO.KEYResEntriesSize, eax

    ;----------------------------------
    ; BifFilenames Entries
    ;----------------------------------    
    .IF dwOpenMode == 0
        mov eax, TotalBifEntries
        mov ebx, SIZEOF BIF_FILENAME
        mul ebx
        mov KEYBifFilenamesSize, eax
        Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, KEYBifFilenamesSize
        .IF eax == NULL
            mov ebx, hIEKEY
            mov eax, [ebx].KEYINFO.KEYResEntriesSize
            Invoke GlobalFree, eax
            mov ebx, hIEKEY
            mov eax, [ebx].KEYINFO.KEYBifEntriesPtr
            Invoke GlobalFree, eax
            mov ebx, hIEKEY
            mov eax, [ebx].KEYINFO.KEYHeaderPtr
            Invoke GlobalFree, eax    
            Invoke GlobalFree, hIEKEY
            mov eax, NULL        
            ret
        .ENDIF    
        mov ebx, hIEKEY
        mov [ebx].KEYINFO.KEYBifFilenamesPtr, eax
        mov KEYBifFilenamesPtr, eax
        
        ; loop through filenames and copy each to our structure
        mov eax, KEYMemMapPtr
        add eax, OffsetBifEntries
        mov BifEntryOffset, eax
        
        mov BifEntry, 0
        mov eax, 0
        .WHILE eax < TotalBifEntries
            
            mov ebx, BifEntryOffset
            mov eax, [ebx].BIF_ENTRY.OffsetBifFilename
            add eax, KEYMemMapPtr ; should be at filename in mem mapped file
            mov OffsetFilename, eax ; save this offset
            
            ; calc filename entry to copy to
            mov eax, BifEntry
            mov ebx, SIZEOF BIF_FILENAME
            mul ebx
            add eax, KEYBifFilenamesPtr
            Invoke szCopy, OffsetFilename, eax 
            
            ; adjust vars to loop again        
            mov eax, BifEntryOffset
            add eax, SIZEOF BIF_ENTRY
            mov BifEntryOffset, eax
            ;add BifEntryOffset, SIZEOF BIF_ENTRY
            inc BifEntry
            mov eax, BifEntry
        .ENDW
        
        mov ebx, hIEKEY
        mov eax, KEYBifFilenamesSize
        mov [ebx].KEYINFO.KEYBifFilenamesSize, eax
    .ELSE
        mov ebx, hIEKEY
        mov eax, KEYMemMapPtr
        add eax, OffsetBifFilenames
        mov [ebx].KEYINFO.KEYBifFilenamesPtr, eax
        mov eax, BifFilenamesSize
        mov [ebx].KEYINFO.KEYBifFilenamesSize, eax
    .ENDIF
    IFDEF DEBUG32
        ;PrintDec TotalBifEntries
        ;PrintDec TotalResEntries
    ENDIF
    mov eax, hIEKEY
    ret
KEYV1Mem ENDP



;-------------------------------------------------------------------------------------
; KEYV11Mem - Returns handle in eax of opened key file that is already loaded into memory. NULL if could not alloc enough mem
;-------------------------------------------------------------------------------------
KEYV11Mem PROC PUBLIC USES EBX pKEYInMemory:DWORD, lpszKeyFilename:DWORD, dwKeyFilesize:DWORD, dwOpenMode:DWORD
    LOCAL hIEKEY:DWORD
    LOCAL KEYMemMapPtr:DWORD
    LOCAL TotalBifEntries:DWORD
    LOCAL TotalResEntries:DWORD
    LOCAL OffsetBifEntries:DWORD
    LOCAL OffsetResEntries:DWORD
    LOCAL OffsetBifFilenames:DWORD
    LOCAL OffsetFilename:DWORD
    LOCAL BifEntriesSize:DWORD
    LOCAL ResEntriesSize:DWORD
    LOCAL BifFilenamesSize:DWORD
    LOCAL BifFilenameLength:DWORD
    LOCAL KEYBifFilenamesSize:DWORD
    LOCAL BifEntry:DWORD
    LOCAL BifEntryOffset:DWORD
    LOCAL KEYBifFilenamesPtr:DWORD
    LOCAL tmpPtrToBifFilename:DWORD
    
    mov eax, pKEYInMemory
    mov KEYMemMapPtr, eax       

    ;----------------------------------
    ; Alloc mem for our IEKEY Handle
    ;----------------------------------
    Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, SIZEOF KEYINFO
    .IF eax == NULL
        ret
    .ENDIF
    mov hIEKEY, eax
    
    mov ebx, hIEKEY
    mov eax, dwOpenMode
    mov [ebx].KEYINFO.KEYOpenMode, eax
    mov eax, KEYMemMapPtr
    mov [ebx].KEYINFO.KEYMemMapPtr, eax
    
    lea eax, [ebx].KEYINFO.KEYFilename
    Invoke szCopy, lpszKeyFilename, eax
    
    mov ebx, hIEKEY
    mov eax, dwKeyFilesize
    mov [ebx].KEYINFO.KEYFilesize, eax
    mov eax, 1
    mov [ebx].KEYINFO.KEYVersion, eax

    ;----------------------------------
    ; KEY Header
    ;----------------------------------
    .IF dwOpenMode == 0
        Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, SIZEOF KEY_HEADER_V11
        .IF eax == NULL
            Invoke GlobalFree, hIEKEY
            mov eax, NULL
            ret
        .ENDIF    
        mov ebx, hIEKEY
        mov [ebx].KEYINFO.KEYHeaderPtr, eax
        mov ebx, KEYMemMapPtr
        Invoke RtlMoveMemory, eax, ebx, SIZEOF KEY_HEADER_V11
    .ELSE
        mov ebx, hIEKEY
        mov eax, KEYMemMapPtr
        mov [ebx].KEYINFO.KEYHeaderPtr, eax
    .ENDIF
    mov ebx, hIEKEY
    mov eax, SIZEOF KEY_HEADER_V11
    mov [ebx].KEYINFO.KEYHeaderSize, eax    

    ;----------------------------------
    ; Bif & Res Counts, Offsets & Sizes
    ;----------------------------------
    mov ebx, [ebx].KEYINFO.KEYHeaderPtr
    mov eax, [ebx].KEY_HEADER_V11.BifEntriesCount
    mov TotalBifEntries, eax
    mov eax, [ebx].KEY_HEADER_V11.ResEntriesCount
    mov TotalResEntries, eax
    mov eax, [ebx].KEY_HEADER_V11.OffsetBifEntries
    mov OffsetBifEntries, eax
    mov eax, [ebx].KEY_HEADER_V11.OffsetResEntries
    mov OffsetResEntries, eax
    
    
    .IF OffsetBifEntries > 24d ; wide 16bytes char resource name
        mov ebx, hIEKEY
        mov [ebx].KEYINFO.KEYWideResEntries, TRUE
    .ELSE
        mov ebx, hIEKEY
        mov [ebx].KEYINFO.KEYWideResEntries, FALSE
    .ENDIF
    
    mov eax, TotalBifEntries
    mov ebx, SIZEOF BIF_ENTRY_V11
    mul ebx
    mov BifEntriesSize, eax
    
    mov eax, TotalResEntries
    mov ebx, SIZEOF RES_ENTRY_V11
    mul ebx
    mov ResEntriesSize, eax
    
    mov eax, OffsetBifEntries
    add eax, BifEntriesSize
    mov OffsetBifFilenames, eax
    
    mov eax, OffsetResEntries
    mov ebx, OffsetBifFilenames
    sub eax, ebx
    mov BifFilenamesSize, eax

    ;----------------------------------
    ; Bif Entries
    ;----------------------------------
    .IF dwOpenMode == 0
        Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, BifEntriesSize
        .IF eax == NULL
            mov ebx, hIEKEY
            mov eax, [ebx].KEYINFO.KEYHeaderPtr
            Invoke GlobalFree, eax    
            Invoke GlobalFree, hIEKEY
            mov eax, NULL    
            ret
        .ENDIF    
        mov ebx, hIEKEY
        mov [ebx].KEYINFO.KEYBifEntriesPtr, eax
    
        mov ebx, KEYMemMapPtr
        add ebx, OffsetBifEntries
        Invoke RtlMoveMemory, eax, ebx, BifEntriesSize
    .ELSE
        mov ebx, hIEKEY
        mov eax, KEYMemMapPtr
        add eax, OffsetBifEntries
        mov [ebx].KEYINFO.KEYBifEntriesPtr, eax
    .ENDIF
    mov ebx, hIEKEY
    mov eax, BifEntriesSize
    mov [ebx].KEYINFO.KEYBifEntriesSize, eax

    ;----------------------------------
    ; Res Entries
    ;----------------------------------    
    .IF dwOpenMode == 0
        Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, ResEntriesSize
        .IF eax == NULL
            mov ebx, hIEKEY
            mov eax, [ebx].KEYINFO.KEYBifEntriesPtr
            Invoke GlobalFree, eax
            mov ebx, hIEKEY
            mov eax, [ebx].KEYINFO.KEYHeaderPtr
            Invoke GlobalFree, eax    
            Invoke GlobalFree, hIEKEY
            mov eax, NULL    
            ret
        .ENDIF    
        mov ebx, hIEKEY
        mov [ebx].KEYINFO.KEYResEntriesPtr, eax
        mov ebx, KEYMemMapPtr
        add ebx, OffsetResEntries
        Invoke RtlMoveMemory, eax, ebx, ResEntriesSize
    .ELSE
        mov ebx, hIEKEY
        mov eax, KEYMemMapPtr
        add eax, OffsetResEntries
        mov [ebx].KEYINFO.KEYResEntriesPtr, eax
    .ENDIF
    mov ebx, hIEKEY
    mov eax, ResEntriesSize
    mov [ebx].KEYINFO.KEYResEntriesSize, eax

    ;PrintDec [ebx].KEYINFO.KEYResEntriesPtr

    ;----------------------------------
    ; BifFilenames Entries
    ;----------------------------------    
    .IF dwOpenMode == 0
        mov eax, TotalBifEntries
        mov ebx, SIZEOF BIF_FILENAME
        mul ebx
        mov KEYBifFilenamesSize, eax
        Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, KEYBifFilenamesSize
        .IF eax == NULL
            mov ebx, hIEKEY
            mov eax, [ebx].KEYINFO.KEYResEntriesSize
            Invoke GlobalFree, eax
            mov ebx, hIEKEY
            mov eax, [ebx].KEYINFO.KEYBifEntriesPtr
            Invoke GlobalFree, eax
            mov ebx, hIEKEY
            mov eax, [ebx].KEYINFO.KEYHeaderPtr
            Invoke GlobalFree, eax    
            Invoke GlobalFree, hIEKEY
            mov eax, NULL        
            ret
        .ENDIF    
        mov ebx, hIEKEY
        mov [ebx].KEYINFO.KEYBifFilenamesPtr, eax
        mov KEYBifFilenamesPtr, eax
        
        ; loop through filenames and copy each to our structure
        mov eax, KEYMemMapPtr
        add eax, OffsetBifEntries
        mov BifEntryOffset, eax
        
        mov BifEntry, 0
        mov eax, 0
        .WHILE eax < TotalBifEntries
            
            mov ebx, BifEntryOffset
            mov eax, [ebx].BIF_ENTRY_V11.LengthBifFilename
            mov BifFilenameLength, eax
            mov eax, [ebx].BIF_ENTRY_V11.OffsetBifFilename
            add eax, KEYMemMapPtr ; should be at filename in mem mapped file
            mov OffsetFilename, eax ; save this offset
            
            ; calc filename entry to copy to
            mov eax, BifEntry
            mov ebx, SIZEOF BIF_FILENAME
            mul ebx
            add eax, KEYBifFilenamesPtr
            mov tmpPtrToBifFilename, eax
            Invoke lstrcpyn, tmpPtrToBifFilename, OffsetFilename, BifFilenameLength
            ;Invoke szCopy, OffsetFilename, eax 
            
            ; adjust vars to loop again        
            mov eax, BifEntryOffset
            add eax, SIZEOF BIF_ENTRY_V11
            mov BifEntryOffset, eax
            ;add BifEntryOffset, SIZEOF BIF_ENTRY
            inc BifEntry
            mov eax, BifEntry
        .ENDW
        
        mov ebx, hIEKEY
        mov eax, KEYBifFilenamesSize
        mov [ebx].KEYINFO.KEYBifFilenamesSize, eax
    .ELSE
        mov ebx, hIEKEY
        mov eax, KEYMemMapPtr
        add eax, OffsetBifFilenames
        mov [ebx].KEYINFO.KEYBifFilenamesPtr, eax
        mov eax, BifFilenamesSize
        mov [ebx].KEYINFO.KEYBifFilenamesSize, eax
    .ENDIF
    IFDEF DEBUG32
        ;PrintDec TotalBifEntries
        ;PrintDec TotalResEntries
    ENDIF
    mov eax, hIEKEY
    ret
KEYV11Mem ENDP



;-------------------------------------------------------------------------------------
; IEKEYClose - Frees memory used by control data structure
;-------------------------------------------------------------------------------------
IEKEYClose PROC PUBLIC USES EBX hIEKEY:DWORD
    
    ;PrintText 'IEKEYCLOSE'
    
    IFDEF DEBUGLOG 
    DebugLogMsg "IEKEYClose", DEBUGLOG_FUNCTION, 2
    ENDIF
    
    ;PrintText 'hIEKEY == NULL'
    .IF hIEKEY == NULL
        IFDEF DEBUGLOG 
        DebugLogMsg "IEKEYClose::hIEKEY==NULL", DEBUGLOG_INFO, 3
        ENDIF
        mov eax, 0
        ret
    .ENDIF
    
    
    ;PrintText 'KEYINFO.KEYOpenMode'
    ;PrintDec hIEKEY
    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYOpenMode
    ;PrintDec eax
    .IF eax == 0 ; Write Mode
        IFDEF DEBUGLOG 
        DebugLogMsg "IEKEYClose::Read/Write Mode", DEBUGLOG_INFO, 3
        ENDIF
        mov ebx, hIEKEY
        mov eax, [ebx].KEYINFO.KEYHeaderPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
            IFDEF DEBUGLOG 
            DebugLogMsg "IEKEYClose::GlobalFree-KEYHeaderPtr::Success", DEBUGLOG_INFO, 3
            ENDIF            
        .ENDIF
    
        mov ebx, hIEKEY
        mov eax, [ebx].KEYINFO.KEYBifEntriesPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
            IFDEF DEBUGLOG 
            DebugLogMsg "IEKEYClose::GlobalFree-KEYBifEntriesPtr::Success", DEBUGLOG_INFO, 3
            ENDIF
        .ENDIF
    
        mov ebx, hIEKEY
        mov eax, [ebx].KEYINFO.KEYResEntriesPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
            IFDEF DEBUGLOG 
            DebugLogMsg "IEKEYClose::GlobalFree-KEYResEntriesPtr::Success", DEBUGLOG_INFO, 3
            ENDIF
        .ENDIF
    
        mov ebx, hIEKEY
        mov eax, [ebx].KEYINFO.KEYBifFilenamesPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
            IFDEF DEBUGLOG 
            DebugLogMsg "IEKEYClose::GlobalFree-KEYBifFilenamesPtr::Success", DEBUGLOG_INFO, 3
            ENDIF
        .ENDIF
        
    .ELSEIF eax == 1 ; Read Only
        ;PrintText 'Close::ReadOnly'
        mov ebx, hIEKEY
        mov eax, [ebx].KEYINFO.KEYMemMapPtr
        .IF eax != NULL
            Invoke UnmapViewOfFile, eax
            IFDEF DEBUGLOG 
            DebugLogMsg "IEKEYClose::UnmapViewOfFile-KEYMemMapPtr::Success", DEBUGLOG_INFO, 3
            ENDIF
        .ENDIF
        
        mov ebx, hIEKEY
        mov eax, [ebx].KEYINFO.KEYMemMapHandle
        .IF eax != NULL
            Invoke CloseHandle, eax
            IFDEF DEBUGLOG 
            DebugLogMsg "IEKEYClose::CloseHandle-KEYMemMapHandle::Success", DEBUGLOG_INFO, 3
            ENDIF
        .ENDIF  
              
        mov ebx, hIEKEY
        mov eax, [ebx].KEYINFO.KEYFileHandle
        .IF eax != NULL
            Invoke CloseHandle, eax
            IFDEF DEBUGLOG 
            DebugLogMsg "IEKEYClose::CloseHandle-KEYFileHandle::Success", DEBUGLOG_INFO, 3
            ENDIF
        .ENDIF          
    .ENDIF
    
    ;PrintText 'Final::ReadOnly'
    
    mov eax, hIEKEY
    .IF eax != NULL
        Invoke GlobalFree, eax
        IFDEF DEBUGLOG 
        DebugLogMsg "IEKEYClose::GlobalFree-hIEKEY::Success", DEBUGLOG_INFO, 3
        ENDIF
    .ENDIF
    IFDEF DEBUGLOG 
    DebugLogMsg "IEKEYClose::Finished", DEBUGLOG_INFO, 2
    ENDIF
    mov eax, 0
    ret
IEKEYClose ENDP


;-------------------------------------------------------------------------------------
; IEKEYHeader - Returns in eax a pointer to header or -1 if not valid
;-------------------------------------------------------------------------------------
IEKEYHeader PROC PUBLIC USES EBX hIEKEY:DWORD
    .IF hIEKEY == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYHeaderPtr
    ret
IEKEYHeader ENDP


;-------------------------------------------------------------------------------------
; IEKEYBifEntry - Returns in eax a pointer to the specified bif entry or -1 
;-------------------------------------------------------------------------------------
IEKEYBifEntry PROC PUBLIC USES EBX hIEKEY:DWORD, nBifEntry:DWORD
    ;LOCAL HeaderPtr:DWORD
    LOCAL TotalBifEntries:DWORD
    LOCAL BifEntriesPtr:DWORD
    LOCAL Version:DWORD
    
    .IF hIEKEY == NULL
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEKEYTotalBifEntries, hIEKEY
    mov TotalBifEntries, eax
    .IF TotalBifEntries == 0
        mov eax, -1
        ret
    .ENDIF    
    
    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYBifEntriesPtr
    mov BifEntriesPtr, eax
    mov eax, [ebx].KEYINFO.KEYVersion
    mov Version, eax
;    mov eax, [ebx].KEYINFO.KEYHeaderPtr
;    mov HeaderPtr, eax

;    mov ebx, HeaderPtr
;    mov eax, [ebx].KEY_HEADER_V1.BifEntriesCount
;    mov TotalBifEntries, eax
    mov eax, TotalBifEntries
    .IF nBifEntry > eax
        mov eax, -1
        ret
    .ENDIF

    ;Invoke IEKEYVersion, hIEKEY
    ;mov Version, eax
    
    mov eax, nBifEntry
    .IF Version == 3
        mov ebx, SIZEOF BIF_ENTRY_V11
    .ELSE
        mov ebx, SIZEOF BIF_ENTRY
    .ENDIF
    mul ebx
    add eax, BifEntriesPtr
    ret
IEKEYBifEntry ENDP


;-------------------------------------------------------------------------------------
; IEKEYBifEntryFileOffset - Returns in eax file offset of bif entry or -1 if not found
; Used for getting absolute offset to the entry in a file (hex viewer for example) 
;-------------------------------------------------------------------------------------
IEKEYBifEntryFileOffset PROC PUBLIC USES EBX hIEKEY:DWORD, nBifEntry:DWORD, lpBifEntriesSize:DWORD
    LOCAL TotalBifEntries:DWORD
    LOCAL OffsetBifEntries:DWORD
    LOCAL BifEntriesSize:DWORD
    LOCAL Version:DWORD
    
    .IF hIEKEY == NULL
        mov eax, -1
        ret
    .ENDIF

    Invoke IEKEYTotalBifEntries, hIEKEY
    mov TotalBifEntries, eax
    .IF TotalBifEntries == 0
        mov eax, -1
        ret
    .ENDIF    
    
    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYVersion
    mov Version, eax
    mov eax, [ebx].KEYINFO.KEYBifEntriesSize
    mov BifEntriesSize, eax
    .IF lpBifEntriesSize != NULL
        mov ebx, lpBifEntriesSize
        mov [ebx], eax
    .ENDIF    
    
    mov ebx, hIEKEY
    mov ebx, [ebx].KEYINFO.KEYHeaderPtr
    .IF Version == 3 ; KEYV11
        mov eax, [ebx].KEY_HEADER_V11.OffsetBifEntries
    .ELSE ; KEY V1 or KEY V1 Wide
        mov eax, [ebx].KEY_HEADER_V1.OffsetBifEntries
    .ENDIF
    mov OffsetBifEntries, eax

    mov eax, nBifEntry
    .IF Version == 3
        mov ebx, SIZEOF BIF_ENTRY_V11
    .ELSE
        mov ebx, SIZEOF BIF_ENTRY
    .ENDIF
    mul ebx
    add eax, OffsetBifEntries
 
    ret

IEKEYBifEntryFileOffset ENDP



;-------------------------------------------------------------------------------------
; IEKEYResEntry - Returns in eax a pointer to the specified resource entry or -1 
;-------------------------------------------------------------------------------------
IEKEYResEntry PROC PUBLIC USES EBX hIEKEY:DWORD, nResEntry:DWORD
    ;LOCAL HeaderPtr:DWORD
    LOCAL TotalResEntries:DWORD
    LOCAL ResEntriesPtr:DWORD
    LOCAL Version:DWORD
    
    .IF hIEKEY == NULL
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEKEYTotalResEntries, hIEKEY
    mov TotalResEntries, eax
    .IF TotalResEntries == 0
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYResEntriesPtr
    mov ResEntriesPtr, eax
    mov eax, [ebx].KEYINFO.KEYVersion
    mov Version, eax  
    ;mov eax, [ebx].KEYINFO.KEYHeaderPtr
    ;mov HeaderPtr, eax
    
    ;mov ebx, HeaderPtr
    ;mov eax, [ebx].KEY_HEADER_V1.ResEntriesCount
    ;mov TotalResEntries, eax
    
    mov eax, TotalResEntries
    .IF nResEntry > eax
        mov eax, -1
        ret
    .ENDIF
 
    ;Invoke IEKEYVersion, hIEKEY
    ;mov Version, eax
    
    mov eax, nResEntry
    .IF Version == 1
        mov ebx, SIZEOF RES_ENTRY
    .ELSEIF Version == 2
        mov ebx, SIZEOF RES_ENTRY_V1_WIDE
    .ELSEIF Version == 3
        mov ebx, SIZEOF RES_ENTRY_V11
    .ENDIF
    mul ebx
    add eax, ResEntriesPtr
    ret
IEKEYResEntry ENDP


;-------------------------------------------------------------------------------------
; IEKEYResEntryFileOffset - Returns in eax file offset of res entry or -1 if not found
; Used for getting absolute offset to the entry in a file (hex viewer for example) 
;-------------------------------------------------------------------------------------
IEKEYResEntryFileOffset PROC PUBLIC USES EBX hIEKEY:DWORD, nResEntry:DWORD, lpResEntriesSize:DWORD
    LOCAL TotalResEntries:DWORD
    LOCAL OffsetResEntries:DWORD
    LOCAL ResEntriesSize:DWORD    
    LOCAL Version:DWORD
    
    .IF hIEKEY == NULL
        mov eax, -1
        ret
    .ENDIF

    Invoke IEKEYTotalResEntries, hIEKEY
    mov TotalResEntries, eax
    .IF TotalResEntries == 0
        mov eax, -1
        ret
    .ENDIF    
    
    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYVersion
    mov Version, eax
    mov eax, [ebx].KEYINFO.KEYResEntriesSize
    mov ResEntriesSize, eax
    .IF lpResEntriesSize != NULL
        mov ebx, lpResEntriesSize
        mov [ebx], eax
    .ENDIF    
    
    mov ebx, hIEKEY
    mov ebx, [ebx].KEYINFO.KEYHeaderPtr
    .IF Version == 3 ; KEYV11
        mov eax, [ebx].KEY_HEADER_V11.OffsetResEntries
    .ELSE ; KEY V1 or KEY V1 Wide
        mov eax, [ebx].KEY_HEADER_V1.OffsetResEntries
    .ENDIF
    mov OffsetResEntries, eax

    mov eax, nResEntry
    .IF Version == 1
        mov ebx, SIZEOF RES_ENTRY
    .ELSEIF Version == 2
        mov ebx, SIZEOF RES_ENTRY_V1_WIDE
    .ELSEIF Version == 3
        mov ebx, SIZEOF RES_ENTRY_V11
    .ENDIF
    mul ebx
    add eax, OffsetResEntries
 
    ret

IEKEYResEntryFileOffset ENDP


;-------------------------------------------------------------------------------------
; IEKEYBifEntries - Returns in eax a pointer to bif entries or -1 if not valid
;-------------------------------------------------------------------------------------
IEKEYBifEntries PROC PUBLIC USES EBX hIEKEY:DWORD
    .IF hIEKEY == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYBifEntriesPtr
    ret
IEKEYBifEntries ENDP


;-------------------------------------------------------------------------------------
; IEKEYResEntries - Returns in eax a pointer to resource entries or -1 if not valid
;-------------------------------------------------------------------------------------
IEKEYResEntries PROC PUBLIC USES EBX hIEKEY:DWORD
    .IF hIEKEY == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYResEntriesPtr
    ret
IEKEYResEntries ENDP


;-------------------------------------------------------------------------------------
; IEKEYBifFilenamesEntries - Returns in eax a pointer to biffilename entries or -1 if not valid
;-------------------------------------------------------------------------------------
IEKEYBifFilenamesEntries PROC PUBLIC USES EBX hIEKEY:DWORD
    .IF hIEKEY == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYBifFilenamesPtr
    ret

IEKEYBifFilenamesEntries endp


;-------------------------------------------------------------------------------------
; IEKEYBifFilenamesOffset - Returns in eax a file offset to biffilename entries or -1 
; if not valid and size of filenames array in lpBifFilenamesSize (if not NULL)
;-------------------------------------------------------------------------------------
IEKEYBifFilenamesOffset PROC PUBLIC USES EBX hIEKEY:DWORD, lpBifFilenamesSize:DWORD
    LOCAL Version:DWORD
    LOCAL BifEntriesSize:DWORD
    LOCAL BifFilenamesSize:DWORD

    .IF hIEKEY == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYVersion
    mov Version, eax
    mov eax, [ebx].KEYINFO.KEYBifEntriesSize
    mov BifEntriesSize, eax
    .IF lpBifFilenamesSize != NULL
        mov eax, [ebx].KEYINFO.KEYBifFilenamesSize
        mov BifFilenamesSize, eax
        mov ebx, lpBifFilenamesSize
        mov [ebx], eax
    .ENDIF
    
    mov ebx, hIEKEY
    mov ebx, [ebx].KEYINFO.KEYHeaderPtr
    .IF Version == 3 ; KEYV11
        mov eax, [ebx].KEY_HEADER_V11.OffsetBifEntries
        ;add eax, SIZEOF KEY_HEADER_V11
    .ELSE ; KEY V1 or KEY V1 Wide
        mov eax, [ebx].KEY_HEADER_V1.OffsetBifEntries
        ;add eax, SIZEOF KEY_HEADER_V1
    .ENDIF
    add eax, BifEntriesSize
    
    ret

IEKEYBifFilenamesOffset ENDP


;-------------------------------------------------------------------------------------
; IEKEYBifFilename - Returns in eax a pointer to the specified null terminated bif filename entry or -1, ebx contains length of bif filename or -1 if invalid
;-------------------------------------------------------------------------------------
IEKEYBifFilename PROC PUBLIC hIEKEY:DWORD, nBifEntry:DWORD
    LOCAL dwOpenMode:DWORD
    LOCAL HeaderPtr:DWORD
    LOCAL TotalBifEntries:DWORD
    LOCAL BifFilenamesPtr:DWORD
    LOCAL BifEntriesPtr:DWORD
    LOCAL Version:DWORD

    .IF hIEKEY == NULL
        mov eax, -1
        mov ebx, -1
        ret
    .ENDIF
    
    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYOpenMode
    mov dwOpenMode, eax
    mov eax, [ebx].KEYINFO.KEYHeaderPtr
    mov HeaderPtr, eax
    mov eax, [ebx].KEYINFO.KEYBifFilenamesPtr
    mov BifFilenamesPtr, eax
    mov eax, [ebx].KEYINFO.KEYBifEntriesPtr
    mov BifEntriesPtr, eax
    mov eax, [ebx].KEYINFO.KEYVersion
    mov Version, eax
    
    mov ebx, HeaderPtr
    .IF Version == 3 ; KEYV11
        mov eax, [ebx].KEY_HEADER_V11.BifEntriesCount
    .ELSE ; KEY V1 or KEY V1 Wide
        mov eax, [ebx].KEY_HEADER_V1.BifEntriesCount
    .ENDIF
    mov TotalBifEntries, eax
    
    .IF nBifEntry > eax
        mov eax, -1
        mov ebx, -1
        ret
    .ENDIF
    
    .IF dwOpenMode == 0
        mov eax, nBifEntry
        mov ebx, SIZEOF BIF_FILENAME
        mul ebx
        add eax, BifFilenamesPtr
        mov ebx, [eax].BIF_FILENAME.BifFilenameLength
        lea eax, [eax].BIF_FILENAME.BifFilename
    .ELSE
        mov eax, nBifEntry
        .IF Version == 3
            mov ebx, SIZEOF BIF_ENTRY_V11
        .ELSE
            mov ebx, SIZEOF BIF_ENTRY
        .ENDIF
        mul ebx
        add eax, BifEntriesPtr
        ;add eax, HeaderPtr ; same as KEYMemMapPtr
        mov ebx, eax
        .IF Version == 3 ; KEYV11
            mov eax, [ebx].BIF_ENTRY_V11.OffsetBifFilename
            mov ebx, [ebx].BIF_ENTRY_V11.LengthBifFilename
        .ELSE ; KEY V1 or KEY V1 Wide
            mov eax, [ebx].BIF_ENTRY.OffsetBifFilename
            movzx ebx, word ptr [ebx].BIF_ENTRY.LengthBifFilename
        .ENDIF
        add eax, HeaderPtr ; eax should now point to null terminated string of bif file name
        
        IFDEF DEBUG32
            ;mov DbgVar, eax
            ;PrintStringByAddr DbgVar
        ENDIF
    .ENDIF        
    ret
IEKEYBifFilename ENDP


;-------------------------------------------------------------------------------------
; IEKEYFileName - returns in eax pointer to zero terminated string contained filename that is open or -1 if not opened, 0 if in memory ?
;-------------------------------------------------------------------------------------
IEKEYFileName PROC PUBLIC USES EBX hIEKEY:DWORD
    LOCAL KeyFilename:DWORD
    .IF hIEKEY == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEKEY
    lea eax, [ebx].KEYINFO.KEYFilename
    mov KeyFilename, eax
    Invoke szLen, KeyFilename
    .IF eax == 0
        mov eax, -1
    .ELSE
        mov eax, KeyFilename
    .ENDIF
    ret

IEKEYFileName endp


;-------------------------------------------------------------------------------------
; IEKEYTotalBifEntries - Returns in eax the total no of bif file entries
;-------------------------------------------------------------------------------------
IEKEYTotalBifEntries PROC PUBLIC USES EBX hIEKEY:DWORD
    LOCAL Version:DWORD
    .IF hIEKEY == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYVersion
    mov Version, eax    
    mov ebx, [ebx].KEYINFO.KEYHeaderPtr
    .IF Version == 3 ; KEYV11
        mov eax, [ebx].KEY_HEADER_V11.BifEntriesCount
    .ELSE ; KEY V1 or KEY V1 Wide
        mov eax, [ebx].KEY_HEADER_V1.BifEntriesCount
    .ENDIF
    ret
IEKEYTotalBifEntries endp


;-------------------------------------------------------------------------------------
; IEKEYTotalResEntries - Returns in eax the total no of resource entries
;-------------------------------------------------------------------------------------
IEKEYTotalResEntries PROC PUBLIC USES EBX hIEKEY:DWORD
    LOCAL Version:DWORD
    .IF hIEKEY == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYVersion
    mov Version, eax      
    mov ebx, [ebx].KEYINFO.KEYHeaderPtr
    .IF Version == 3 ; KEYV11
        mov eax, [ebx].KEY_HEADER_V11.ResEntriesCount
    .ELSE ; KEY V1 or KEY V1 Wide
        mov eax, [ebx].KEY_HEADER_V1.ResEntriesCount
    .ENDIF
    ret
IEKEYTotalResEntries endp


;-------------------------------------------------------------------------------------
; IEKEYFindBifFilenameEntry - Returns bif entry for corresponding bif filename or -1 if not found
; skips for Data\, DATA\ or data\, cache\, movies etc in filename in key entry and strips
; lpszBifFilename of all path data to search just for the filename.

; for bif resourcelocator to be found in key file
; we need to get bif entry, shift bif entry index 20 to left, then add reslocator non tileset index in bif file to get full resource locator to search for in key file

;-------------------------------------------------------------------------------------
IEKEYFindBifFilenameEntry PROC PUBLIC USES EBX hIEKEY:DWORD, lpszBifFilename:DWORD
    LOCAL nBifEntry:DWORD
    LOCAL TotalBifEntries:DWORD
    LOCAL BifFilenameOffset:DWORD
    LOCAL BifFilenameLength:DWORD
    ;LOCAL LenBifFilenameToSearchFor:DWORD
    LOCAL szBifFilenameToSearchFor[MAX_PATH]:BYTE
    LOCAL szCurrentBifFilename[64]:BYTE

    .IF hIEKEY == NULL
        mov eax, -1
        ret
    .ENDIF
    
    Invoke KEYJustFname, lpszBifFilename, Addr szBifFilenameToSearchFor  
    Invoke szCatStr, Addr szBifFilenameToSearchFor, Addr szBifExt
    
    ;Invoke szLen, Addr szBifFilenameToSearchFor  
    ;mov LenBifFilenameToSearchFor, eax
    
    Invoke IEKEYTotalBifEntries, hIEKEY
    mov TotalBifEntries, eax
    
    mov nBifEntry, 0
    mov eax, 0
    .WHILE eax < TotalBifEntries
        Invoke IEKEYBifFilename, hIEKEY, nBifEntry
        mov BifFilenameOffset, eax
        inc ebx ; for null char
        mov BifFilenameLength, ebx
        
        Invoke lstrcpyn, Addr szCurrentBifFilename, BifFilenameOffset, BifFilenameLength
        lea eax, szCurrentBifFilename
        mov BifFilenameOffset, eax
        
        Invoke InString, 1, BifFilenameOffset, Addr szBackSlash
        .IF eax !=0 ; match found
            add BifFilenameOffset, eax
            ;mov DbgVar, eax
            ;PrintStringByAddr DbgVar
            
        .ELSE
            Invoke InString, 1, BifFilenameOffset, Addr szForwardSlash
            .IF eax !=0 ; match found
                add BifFilenameOffset, eax
                ;mov DbgVar, eax
                ;PrintStringByAddr DbgVar
            .ENDIF
        .ENDIF
        
        

        ;Invoke szLen, BifFilenameOffset
        ;mov LenBifFilenameToSearchFor, eax
        
        
;        mov ebx, [eax]
;        .IF ebx == 'atad' || ebx == 'ataD' || ebx == 'ATAD'
;            add BifFilenameOffset, 6d
;        .ENDIF
        ;PrintStringByAddr BifFilenameOffset
        ;lea eax, szBifFilenameToSearchFor
        ;PrintStringByAddr eax

        Invoke Cmpi, BifFilenameOffset, Addr szBifFilenameToSearchFor
        ;Invoke szCmpi, Addr szBifFilenameToSearchFor, BifFilenameOffset, LenBifFilenameToSearchFor
        .IF eax == 0
            mov eax, nBifEntry
            ret
        .ENDIF
        ;mov eax, BifFilenameOffset
        ;mov DbgVar, eax
        ;PrintStringByAddr DbgVar
        ;lea eax, szBifFilenameToSearchFor
        ;mov DbgVar, eax
        ;PrintStringByAddr DbgVar
        ;PrintText '--------------------------------------'
        inc nBifEntry
        mov eax, nBifEntry
    .ENDW
    mov eax, -1
    
    ret

IEKEYFindBifFilenameEntry endp

;-------------------------------------------------------------------------------------
; IEKEYFindResourceV11 - Returns in eax the resentry of searched for resource or -1 otherwise
;-------------------------------------------------------------------------------------
; when opening a bif file, IEBIF should store BifFileNameEntry in its handle to use for calls to this
; retuns in eax pointer to resource entry and in ebx resentry no
;
; KEY V1.1 ResourceFlags contains part of the ResourceLocator index. ResourceIndex the index
; both added together will give the ResourceIndex we seek
;
; adjust for V1.1 - look for codified BifEntrySourceIndex in ResourceFlags
; when we find a match, add ResourceIndex field to the codified BifEntrySourceIndex and check if it matches our ResourceIndex value
; do new function for V1.1 find resource - still can do divide and conquer and check back and forth till not match codified BifEntrySourceIndex
;
;-------------------------------------------------------------------------------------
IEKEYFindResourceV11 PROC PUBLIC hIEKEY:DWORD, BifEntrySourceIndex:DWORD, ResourceIndex:DWORD, ResourceType:DWORD, lpdwResEntryHint:DWORD
    LOCAL ResourceLocator:DWORD
    LOCAL SourceIndex:DWORD
    LOCAL RecodifiedIndex:DWORD
    LOCAL TotalResEntries:DWORD
    LOCAL TotalBifEntries:DWORD
    LOCAL ResEntry:DWORD
    LOCAL ResEntriesPtr:DWORD
    LOCAL ResEntryOffset:DWORD
    LOCAL ResHint:DWORD
    LOCAL CurrentIndex:DWORD
    LOCAL Version:DWORD

    .IF hIEKEY == NULL
        mov eax, -1
        mov ebx, -1
        ret
    .ENDIF

    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYVersion
    mov Version, eax
    .IF Version != 3 ; KEY V1.1
        mov eax, -1
        mov ebx, -1
        ret
    .ENDIF

    Invoke IEKEYTotalResEntries, hIEKEY
    mov TotalResEntries, eax
    .IF eax == 0
        mov eax, -1
        mov ebx, -1
        ret
    .ENDIF

    mov ebx, lpdwResEntryHint
    mov eax, [ebx]
    mov ResHint, eax
    
    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYResEntriesPtr
    mov ResEntriesPtr, eax
    
    
    ; initially search for 
    mov eax, BifEntrySourceIndex
    shl eax, 20d
    mov SourceIndex, eax
    
    mov eax, ResourceIndex
    and eax, 000FFFFFh
    ;and eax, 0FFF00000h ; mask for bits 31-20
    ;shr eax, 20d    
    mov ResourceLocator, eax ; index of item to search for 0,1,2 etc once we have found SourceIndex in the ResourceFlags field

;    .IF ResourceLocator > 190d
;        IFDEF DEBUG32
;        PrintDec ResourceLocator
;        PrintDec SourceIndex
;        PrintDec ResourceIndex
;        PrintDec BifEntrySourceIndex
;        PrintDec ResHint
;        ENDIF
;    .ENDIF
    
    Invoke IEKEYTotalBifEntries, hIEKEY
    mov TotalBifEntries, eax
    
    .IF ResHint == 0 ; standard search starting at entry 0
        ;PrintText 'standard search starting from 0'
 
        mov eax, TotalBifEntries
        shr eax, 1 ; divide by 2
        .IF BifEntrySourceIndex >= eax ; start at end work back
            ;PrintText 'Working backwards'
            ;PrintDec BifEntrySourceIndex
            mov eax, TotalResEntries
            dec eax ; for 0 based index
            mov ResEntry, eax
            mov ebx, SIZEOF RES_ENTRY_V11
            mul ebx
            add eax, ResEntriesPtr
            mov ResEntryOffset, eax 
            
            Invoke KEYSearchLoopBckV11, ResEntry, 0, ResourceLocator, SourceIndex, Addr ResEntryOffset, Addr lpdwResEntryHint
            .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
                mov eax, ResEntryOffset
                mov ebx, lpdwResEntryHint
                ret
            .ELSE
                mov ebx, lpdwResEntryHint
                mov eax, 0
                mov [ebx], eax ; save reshint for future calls          
                mov eax, -1 ; not found
                mov ebx, 0
                ret
            .ENDIF

        .ELSE ; start at front work forward
        
            mov eax, ResEntriesPtr
            mov ResEntryOffset, eax 
            mov ResEntry, 0

            Invoke KEYSearchLoopFwdV11, 0, TotalResEntries, ResourceLocator, SourceIndex, Addr ResEntryOffset, Addr lpdwResEntryHint
            .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
                mov eax, ResEntryOffset
                mov ebx, lpdwResEntryHint
                ret
            .ELSE
                mov ebx, lpdwResEntryHint
                mov eax, 0
                mov [ebx], eax ; save reshint for future calls          
                mov eax, -1 ; not found
                mov ebx, 0
                ret
            .ENDIF
            
        .ENDIF
        
    .ELSEIF ResHint == -1
;        PrintText ' '
;        PrintText '--------------------------'    
        IFDEF DEBUG32
        PrintText 'divide and conquer search for KEY V1.1'
        ENDIF
;        PrintText '--------------------------'
;        PrintText ' '   

        mov eax, TotalResEntries
        mov ResHint, eax
        dec eax ; for 0 based index
        mov ResEntry, eax        
        
        mov ebx, SIZEOF RES_ENTRY_V11
        mul ebx                          ; only do multiply when we have to
        add eax, ResEntriesPtr
        mov ResEntryOffset, eax
        
        mov eax, ResEntry 
        .WHILE eax != 0
        
            ; modified 10/11/2015 to take the multiple out of the loop for only certain branches instead of every loop iteration
            mov ebx, ResEntryOffset
            mov eax, [ebx].RES_ENTRY_V11.ResourceFlags
            ;mov CurrentIndex, eax                

            .IF eax == SourceIndex ; found source index, check for resourcelocator match now
                mov ebx, ResEntryOffset
                mov eax, [ebx].RES_ENTRY_V11.ResourceLocator
                .IF eax == ResourceLocator ; does it match our resource index, if so save values and exit
                    mov ebx, lpdwResEntryHint
                    mov eax, ResEntry
                    mov [ebx], eax ; save reshint for future calls            
                    mov eax, ResEntryOffset
                    mov ebx, ResEntry
                    ret
                .ELSE ; otherwise we adjust values and loop again
                    mov ebx, ResEntryOffset
                    mov eax, [ebx].RES_ENTRY_V11.ResourceLocator
                    .IF eax > ResourceLocator
                        
                        ; do search back from currently matched sourceindex's resourcelocator value till we find out match
;                        Invoke KEYSearchLoopBckV11, ResEntry, 0, ResourceLocator, SourceIndex, Addr ResEntryOffset, Addr lpdwResEntryHint
;                        .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
;                            mov eax, ResEntryOffset
;                            mov ebx, lpdwResEntryHint
;                            ret
;                        .ENDIF
;                        
;                        ; if for some reason we didnt find match, then start searching forward from the last sourceindex resource locator point
;                        mov eax, ResHint
;                        mov ResEntry, eax
;                        mov ebx, SIZEOF RES_ENTRY_V11
;                        mul ebx
;                        add eax, ResEntriesPtr
;                        mov ResEntryOffset, eax 
;
;                        Invoke KEYSearchLoopFwdV11, ResEntry, TotalResEntries, ResourceLocator, SourceIndex, Addr ResEntryOffset, Addr lpdwResEntryHint
;                        .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
;                            mov eax, ResEntryOffset
;                            mov ebx, lpdwResEntryHint
;                            ret
;                        .ELSE ; just in case
                            dec ResHint
                            dec ResEntry
                            sub ResEntryOffset, SIZEOF RES_ENTRY_V11 ; sub instead of multiply each loop
;                        .ENDIF
                    
                    .ELSEIF eax < ResourceLocator
                    
                        ; do search forward from currently matched sourceindex's resourcelocator value till we find out match
;                        Invoke KEYSearchLoopFwdV11, ResEntry, TotalResEntries, ResourceLocator, SourceIndex, Addr ResEntryOffset, Addr lpdwResEntryHint
;                        .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
;                            mov eax, ResEntryOffset
;                            mov ebx, lpdwResEntryHint
;                            ret
;                        .ENDIF
;                        
;                        ; if for some reason we didnt find match, then start searching backward from the last sourceindex resource locator point
;                        mov eax, ResHint
;                        mov ResEntry, eax
;                        mov ebx, SIZEOF RES_ENTRY_V11
;                        mul ebx
;                        add eax, ResEntriesPtr
;                        mov ResEntryOffset, eax                         
;                                          
;                        Invoke KEYSearchLoopBckV11, ResEntry, 0, ResourceLocator, SourceIndex, Addr ResEntryOffset, Addr lpdwResEntryHint
;                        .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
;                            mov eax, ResEntryOffset
;                            mov ebx, lpdwResEntryHint
;                            ret
;                        .ELSE ; just in case
                            inc ResHint
                            inc ResEntry
                            add ResEntryOffset, SIZEOF RES_ENTRY_V11 ; add instead of multiply each loop
;                        .ENDIF
                        
                    .ENDIF
                .ENDIF            
                
            .ELSEIF eax > SourceIndex
                mov eax, ResHint
                shr eax, 1
                mov ResHint, eax
                mov eax, ResEntry
                mov ebx, ResHint
                sub eax, ebx
                mov ResEntry, eax
                mov ebx, SIZEOF RES_ENTRY_V11
                mul ebx                          ; only do multiply when we have to
                add eax, ResEntriesPtr
                mov ResEntryOffset, eax
                

            .ELSEIF eax < SourceIndex
                mov eax, ResHint
                shr eax, 1
                mov ResHint, eax
                mov eax, ResEntry
                mov ebx, ResHint
                add eax, ebx
                mov ResEntry, eax
                mov ebx, SIZEOF RES_ENTRY_V11
                mul ebx                          ; only do multiply when we have to
                add eax, ResEntriesPtr
                mov ResEntryOffset, eax                

            .ENDIF
            mov eax, ResHint

        .ENDW
        
        ;PrintDec ResEntry
        ; near to our goal, so just iterate through remaining items up or down till we get to it
        IFDEF DEBUG32
        PrintText 'DivConquer last iterations'
        ENDIF
        
        mov eax, ResEntry
        mov ResHint, eax ; save reshint for re-search back or forward
        mov ebx, SIZEOF RES_ENTRY_V11
        mul ebx
        add eax, ResEntriesPtr
        mov ResEntryOffset, eax
        
        
        mov ebx, ResEntryOffset
        mov eax, [ebx].RES_ENTRY_V11.ResourceFlags
        .IF eax == SourceIndex
            ;PrintText 'Match Found'
            mov ebx, ResEntryOffset
            mov eax, [ebx].RES_ENTRY_V11.ResourceLocator
            .IF eax == ResourceLocator
                mov ebx, lpdwResEntryHint
                mov eax, ResEntry
                mov [ebx], eax ; save reshint for future calls            
                mov eax, ResEntryOffset
                mov ebx, ResEntry
                ret
                
            .ELSEIF eax > ResourceLocator 
                
                IFDEF DEBUG32
                PrintText 'DivConquer: + Got SourceIndex Match, looking for ResourceLocator...'
                PrintText 'DivConquer:BckV11 Trying...'
                ENDIF
                
                Invoke KEYSearchLoopBckV11, ResEntry, 0, ResourceLocator, SourceIndex, Addr ResEntryOffset, Addr lpdwResEntryHint
                .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
                    mov eax, ResEntryOffset
                    mov ebx, lpdwResEntryHint
                    ret
                .ENDIF
                
                ; if we reach this point we didnt find it starting at our reshint to 0. so start search forward in case we missed it for some reason.
                mov eax, ResHint
                mov ResEntry, eax
                mov ebx, SIZEOF RES_ENTRY_V11
                mul ebx
                add eax, ResEntriesPtr
                mov ResEntryOffset, eax 
                
                IFDEF DEBUG32
                PrintText 'DivConquer:BckV11 Failed, Trying Fwd'
                ENDIF
                
                Invoke KEYSearchLoopFwdV11, ResEntry, TotalResEntries, ResourceLocator, SourceIndex, Addr ResEntryOffset, Addr lpdwResEntryHint
                .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
                    mov eax, ResEntryOffset
                    mov ebx, lpdwResEntryHint
                    ret
                .ELSE
                    mov ebx, lpdwResEntryHint
                    mov eax, 0
                    mov [ebx], eax ; save reshint for future calls          
                    mov eax, -1 ; not found
                    mov ebx, 0
                    ret
                .ENDIF
            
            .ELSE ; <
            
                IFDEF DEBUG32
                PrintText 'DivConquer: - Got SourceIndex Match, looking for ResourceLocator...'
                PrintText 'DivConquer:FwdV11 Trying...'
                ENDIF
                
                Invoke KEYSearchLoopFwdV11, ResEntry, TotalResEntries, ResourceLocator, SourceIndex, Addr ResEntryOffset, Addr lpdwResEntryHint
                .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
                    mov eax, ResEntryOffset
                    mov ebx, lpdwResEntryHint
                    ret
                .ENDIF
                
                ; if we reach this point we didnt find it starting at our reshint to 0. so start search forward in case we missed it for some reason.
                mov eax, ResHint
                mov ResEntry, eax
                mov ebx, SIZEOF RES_ENTRY_V11
                mul ebx
                add eax, ResEntriesPtr
                mov ResEntryOffset, eax 
                
                IFDEF DEBUG32
                PrintText 'DivConquer:FwdV11 Failed, Trying Bck'
                ENDIF
                
                Invoke KEYSearchLoopBckV11, ResEntry, 0, ResourceLocator, SourceIndex, Addr ResEntryOffset, Addr lpdwResEntryHint
                .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
                    mov eax, ResEntryOffset
                    mov ebx, lpdwResEntryHint
                    ret
                .ELSE
                    mov ebx, lpdwResEntryHint
                    mov eax, 0
                    mov [ebx], eax ; save reshint for future calls          
                    mov eax, -1 ; not found
                    mov ebx, 0
                    ret
                .ENDIF
            
            
            .ENDIF

        .ELSEIF eax > SourceIndex
            
            IFDEF DEBUG32
            PrintText 'DivConquer:BckV11 Trying...'
            ENDIF
            
            Invoke KEYSearchLoopBckV11, ResEntry, 0, ResourceLocator, SourceIndex, Addr ResEntryOffset, Addr lpdwResEntryHint
            .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
                mov eax, ResEntryOffset
                mov ebx, lpdwResEntryHint
                ret
            .ENDIF
            
            ; if we reach this point we didnt find it starting at our reshint to 0. so start search forward in case we missed it for some reason.
            mov eax, ResHint
            mov ResEntry, eax
            mov ebx, SIZEOF RES_ENTRY_V11
            mul ebx
            add eax, ResEntriesPtr
            mov ResEntryOffset, eax 
            
            IFDEF DEBUG32
            PrintText 'DivConquer:BckV11 Failed, Trying Fwd'
            ENDIF
            
            Invoke KEYSearchLoopFwdV11, ResEntry, TotalResEntries, ResourceLocator, SourceIndex, Addr ResEntryOffset, Addr lpdwResEntryHint
            .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
                mov eax, ResEntryOffset
                mov ebx, lpdwResEntryHint
                ret
            .ELSE
                mov ebx, lpdwResEntryHint
                mov eax, 0
                mov [ebx], eax ; save reshint for future calls          
                mov eax, -1 ; not found
                mov ebx, 0
                ret
            .ENDIF
            
        .ELSE ; < SourceIndex
            
            IFDEF DEBUG32
            PrintText 'DivConquer:BckV11 Trying...'
            ENDIF
            
            Invoke KEYSearchLoopFwdV11, ResEntry, TotalResEntries, ResourceLocator, SourceIndex, Addr ResEntryOffset, Addr lpdwResEntryHint
            .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
                mov eax, ResEntryOffset
                mov ebx, lpdwResEntryHint
                ret
            .ENDIF
            
            ; if we reach this point we didnt find it starting at our reshint to totalentries. so start search back in case we missed it for some reason.
            mov eax, ResHint
            mov ResEntry, eax
            mov ebx, SIZEOF RES_ENTRY_V11
            mul ebx
            add eax, ResEntriesPtr
            mov ResEntryOffset, eax 
            
            IFDEF DEBUG32
            PrintText 'DivConquer:FwdV11 Failed, Trying Bck'
            ENDIF
            
            Invoke KEYSearchLoopBckV11, ResEntry, 0, ResourceLocator, SourceIndex, Addr ResEntryOffset, Addr lpdwResEntryHint
            .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
                mov eax, ResEntryOffset
                mov ebx, lpdwResEntryHint
                ret
            .ELSE
                mov ebx, lpdwResEntryHint
                mov eax, 0
                mov [ebx], eax ; save reshint for future calls          
                mov eax, -1 ; not found
                mov ebx, 0
                ret
            .ENDIF
        .ENDIF       

    .ELSE ; start searching at resource hint from last succesfull search. if not found we try searching back from reshint position, finally if not found we return -1
    
        ;PrintText '--------------------------------------'
        ;PrintText 'Searching from reshint'
        ;PrintDec ResHint
        mov eax, ResHint
        mov ResEntry, eax
        mov ebx, SIZEOF RES_ENTRY_V11
        mul ebx
        add eax, ResEntriesPtr
        mov ResEntryOffset, eax 
        
        ;PrintDec ResEntryOffset
        
        Invoke KEYSearchLoopFwdV11, ResEntry, TotalResEntries, ResourceLocator, SourceIndex, Addr ResEntryOffset, Addr lpdwResEntryHint
        .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
            ;PrintText '::Exit'
            ;PrintDec ResEntry
            ;PrintDec lpdwResEntryHint
            ;PrintDec ResEntryOffset
            mov eax, ResEntryOffset
            mov ebx, lpdwResEntryHint
            ret
        .ENDIF
        
        IFDEF DEBUG32
        PrintText 'Searching backward from reshint'
        ENDIF
        ; if we reach this point we didnt find it starting at our reshint to totalentries. so start search back in case we missed it for some reason.
        mov eax, ResHint
        mov ResEntry, eax
        mov ebx, SIZEOF RES_ENTRY_V11
        mul ebx
        add eax, ResEntriesPtr
        mov ResEntryOffset, eax 
        
        Invoke KEYSearchLoopBckV11, ResEntry, 0, ResourceLocator, SourceIndex, Addr ResEntryOffset, Addr lpdwResEntryHint
        .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
            mov eax, ResEntryOffset
            mov ebx, lpdwResEntryHint
            ret
        .ELSE
            mov ebx, lpdwResEntryHint
            mov eax, 0
            mov [ebx], eax ; save reshint for future calls          
            mov eax, -1 ; not found
            mov ebx, 0
            ret
        .ENDIF  

    .ENDIF

        

IEKEYFindResourceV11 ENDP


;-------------------------------------------------------------------------------------
; IEKEYFindResource - Returns in eax the resentry of searched for resource or -1 otherwise
;-------------------------------------------------------------------------------------
; when opening a bif file, IEBIF should store BifFileNameEntry in its handle to use for calls to this
; retuns in eax pointer to resource entry and in ebx resentry no
; check if resourceindex is codified already by masking and shifting right 20
;-------------------------------------------------------------------------------------
IEKEYFindResource PROC PUBLIC hIEKEY:DWORD, BifEntrySourceIndex:DWORD, ResourceIndex:DWORD, ResourceType:DWORD, lpdwResEntryHint:DWORD
    LOCAL ResourceLocator:DWORD
    LOCAL SourceIndex:DWORD
    LOCAL RecodifiedIndex:DWORD
    LOCAL TotalResEntries:DWORD
    LOCAL TotalBifEntries:DWORD
    LOCAL ResEntry:DWORD
    LOCAL ResEntriesPtr:DWORD
    LOCAL ResEntryOffset:DWORD
    LOCAL ResHint:DWORD
    LOCAL CurrentIndex:DWORD
    LOCAL Version:DWORD
    
    .IF hIEKEY == NULL
        mov eax, -1
        mov ebx, -1
        ret
    .ENDIF

    Invoke IEKEYTotalResEntries, hIEKEY
    mov TotalResEntries, eax
    .IF eax == 0
        mov eax, -1
        mov ebx, -1
        ret
    .ENDIF

    mov ebx, lpdwResEntryHint
    mov eax, [ebx]
    ;.IF eax > TotalResEntries
    ;    mov ResHint, 0
    ;.ELSE
        mov ResHint, eax
    ;.ENDIF
    
    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYResEntriesPtr
    mov ResEntriesPtr, eax
    ;PrintDec ResEntriesPtr
    
    mov eax, [ebx].KEYINFO.KEYVersion
    mov Version, eax   
  
    mov eax, ResourceIndex
    and eax, 0FFF00000h ; mask for bits 31-20
    shr eax, 20d
    .IF eax > 0 ; resource index already codified

        
        ; recodify just in case - like in planescape torment
        
        mov eax, BifEntrySourceIndex
        shl eax, 20d
        mov SourceIndex, eax
        
        mov eax, ResourceIndex
        .IF ResourceType == 03EBh ; tis
            and eax, 0FC000h
            ;shr eax, 14d
        .ELSE
            and eax, 3FFFh ; just 
        .ENDIF
        mov ebx, SourceIndex
        add eax, ebx
        mov RecodifiedIndex, eax
        ;.IF eax != ResourceIndex
        ;    PrintDec ResourceIndex
        ;    PrintDec BifEntrySourceIndex
        ;    PrintDec RecodifiedIndex
        ;.ENDIF
        mov eax, RecodifiedIndex
        ;mov eax, ResourceIndex
    .ELSE
        mov eax, BifEntrySourceIndex
        shl eax, 20d
        mov SourceIndex, eax
        mov ebx, eax
        
        ;.IF ResourceType == 03ebh ; TIS
        ;    mov eax, ResourceIndex
        ;    shl eax, 14d
        ;.ELSE
            mov eax, ResourceIndex
        ;.ENDIF
        add eax, ebx
    .ENDIF
    mov ResourceLocator, eax    
    
    ;PrintDec ResourceLocator
    ;PrintDec BifEntrySourceIndex
    
    Invoke IEKEYTotalBifEntries, hIEKEY
    mov TotalBifEntries, eax
;    mov eax, BifEntrySourceIndex
;    shl eax, 20d
;    mov SourceIndex, eax
;    mov ebx, eax
;    
;    .IF ResourceType == 03ebh ; TIS
;        mov eax, ResourceIndex
;        shl eax, 14d
;    .ELSE
;        mov eax, ResourceIndex
;    .ENDIF
;    add eax, ebx
;    mov ResourceLocator, eax
;    

;--------------------------------------------------------------------------------------
    .IF ResHint == 0 ; standard search starting at entry 0
;--------------------------------------------------------------------------------------    
        ;PrintText 'standard search starting from 0'
 
        mov eax, TotalBifEntries
        shr eax, 1 ; divide by 2
        .IF BifEntrySourceIndex >= eax ; start at end work back
            ;PrintText 'Working backwards'
            ;PrintDec BifEntrySourceIndex
            mov eax, TotalResEntries
            dec eax ; for 0 based index
            mov ResEntry, eax
            .IF Version == 1
                mov ebx, SIZEOF RES_ENTRY
            .ELSEIF Version == 2
                mov ebx, SIZEOF RES_ENTRY_V1_WIDE
            .ENDIF
            mul ebx
            add eax, ResEntriesPtr
            mov ResEntryOffset, eax 
            
            Invoke KEYSearchLoopBck, ResEntry, 0, ResourceLocator, Version, Addr ResEntryOffset, Addr lpdwResEntryHint
            .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
                mov eax, ResEntryOffset
                mov ebx, lpdwResEntryHint
                ret
            .ELSE
                mov ebx, lpdwResEntryHint
                mov eax, 0
                mov [ebx], eax ; save reshint for future calls          
                mov eax, -1 ; not found
                mov ebx, 0
                ret
            .ENDIF
            
        .ELSE ; start at front work forward
        
            mov eax, ResEntriesPtr
            mov ResEntryOffset, eax

            Invoke KEYSearchLoopFwd, 0, TotalResEntries, ResourceLocator, Version, Addr ResEntryOffset, Addr lpdwResEntryHint
            .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
                mov eax, ResEntryOffset
                mov ebx, lpdwResEntryHint
                ret
            .ELSE
                mov ebx, lpdwResEntryHint
                mov eax, 0
                mov [ebx], eax ; save reshint for future calls          
                mov eax, -1 ; not found
                mov ebx, 0
                ret
            .ENDIF
            
        .ENDIF

;--------------------------------------------------------------------------------------
    .ELSEIF ResHint == -1
;--------------------------------------------------------------------------------------    
;        PrintText ' '
;        PrintText '--------------------------'    
        IFDEF DEBUG32
        PrintText 'divide and conquer search'
        ENDIF
;        PrintText '--------------------------'
;        PrintText ' '        
        mov eax, TotalResEntries
        mov ResHint, eax
        dec eax ; for 0 based index
        mov ResEntry, eax        
        
        .IF Version == 1
            mov ebx, SIZEOF RES_ENTRY
        .ELSEIF Version == 2
            mov ebx, SIZEOF RES_ENTRY_V1_WIDE
        .ENDIF
        mul ebx
        add eax, ResEntriesPtr
        mov ResEntryOffset, eax
        
        mov eax, ResEntry
        .WHILE eax != 0

            
            mov ebx, ResEntryOffset
            .IF Version == 1
                mov eax, [ebx].RES_ENTRY.ResourceLocator
            .ELSEIF Version == 2
                mov eax, [ebx].RES_ENTRY_V1_WIDE.ResourceLocator
            .ENDIF
            ;mov CurrentIndex, eax

            .IF eax == ResourceLocator
                ;PrintText 'Match Found'
                mov ebx, lpdwResEntryHint
                mov eax, ResEntry
                mov [ebx], eax ; save reshint for future calls
                mov eax, ResEntryOffset
                ret
                
            .ELSEIF eax > ResourceLocator
                mov eax, ResHint
                shr eax, 1
                mov ResHint, eax
                mov eax, ResEntry
                mov ebx, ResHint
                sub eax, ebx
                mov ResEntry, eax
                .IF Version == 1
                    mov ebx, SIZEOF RES_ENTRY
                .ELSEIF Version == 2
                    mov ebx, SIZEOF RES_ENTRY_V1_WIDE
                .ENDIF
                mul ebx
                add eax, ResEntriesPtr
                mov ResEntryOffset, eax

            .ELSEIF eax < ResourceLocator
                mov eax, ResHint
                shr eax, 1
                mov ResHint, eax
                mov eax, ResEntry
                mov ebx, ResHint
                add eax, ebx
                mov ResEntry, eax
                .IF Version == 1
                    mov ebx, SIZEOF RES_ENTRY
                .ELSEIF Version == 2
                    mov ebx, SIZEOF RES_ENTRY_V1_WIDE
                .ENDIF
                mul ebx
                add eax, ResEntriesPtr
                mov ResEntryOffset, eax                

            .ENDIF
            mov eax, ResHint

        .ENDW
        
        ;PrintDec ResEntry
        ; near to our goal, so just iterate through remaining items up or down till we get to it
        IFDEF DEBUG32
        PrintText 'DivConquer last iterations'
        ENDIF
        
        mov eax, ResEntry
        mov ResHint, eax ; save reshint for re-search back or forward
        .IF Version == 1
            mov ebx, SIZEOF RES_ENTRY
        .ELSEIF Version == 2
            mov ebx, SIZEOF RES_ENTRY_V1_WIDE
        .ENDIF
        mul ebx
        add eax, ResEntriesPtr
        mov ResEntryOffset, eax
        mov ebx, ResEntryOffset
        .IF Version == 1
            mov eax, [ebx].RES_ENTRY.ResourceLocator
        .ELSEIF Version == 2
            mov eax, [ebx].RES_ENTRY_V1_WIDE.ResourceLocator
        .ENDIF
        
        .IF eax == ResourceLocator
            ;PrintText 'Match Found'
            mov ebx, lpdwResEntryHint
            mov eax, ResEntry
            mov [ebx], eax ; save reshint for future calls
            mov eax, ResEntryOffset
            ret

        .ELSEIF eax > ResourceLocator
            
            Invoke KEYSearchLoopBck, ResEntry, 0, ResourceLocator, Version, Addr ResEntryOffset, Addr lpdwResEntryHint
            .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
                mov eax, ResEntryOffset
                mov ebx, lpdwResEntryHint
                ret
            .ENDIF
            
            ; if we reach this point we didnt find it starting at our reshint to 0. so start search forward in case we missed it for some reason.
            mov eax, ResHint
            mov ResEntry, eax
            .IF Version == 1
                mov ebx, SIZEOF RES_ENTRY
            .ELSEIF Version == 2
                mov ebx, SIZEOF RES_ENTRY_V1_WIDE
            .ENDIF
            mul ebx
            add eax, ResEntriesPtr
            mov ResEntryOffset, eax 
            
            IFDEF DEBUG32
            PrintText 'DivConquer:Bck Failed, Trying Fwd'
            ENDIF
            
            Invoke KEYSearchLoopFwd, ResEntry, TotalResEntries, ResourceLocator, Version, Addr ResEntryOffset, Addr lpdwResEntryHint
            .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
                mov eax, ResEntryOffset
                mov ebx, lpdwResEntryHint
                ret
            .ELSE
                mov ebx, lpdwResEntryHint
                mov eax, 0
                mov [ebx], eax ; save reshint for future calls          
                mov eax, -1 ; not found
                mov ebx, 0
                ret
            .ENDIF
            
        .ELSE ; <
            
            mov eax, ResEntry
            Invoke KEYSearchLoopFwd, ResEntry, TotalResEntries, ResourceLocator, Version, Addr ResEntryOffset, Addr lpdwResEntryHint
            .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
                mov eax, ResEntryOffset
                mov ebx, lpdwResEntryHint
                ret
            .ENDIF
            
            ; if we reach this point we didnt find it starting at our reshint to totalentries. so start search back in case we missed it for some reason.
            mov eax, ResHint
            mov ResEntry, eax
            .IF Version == 1
                mov ebx, SIZEOF RES_ENTRY
            .ELSEIF Version == 2
                mov ebx, SIZEOF RES_ENTRY_V1_WIDE
            .ENDIF
            mul ebx
            add eax, ResEntriesPtr
            mov ResEntryOffset, eax 
            
            IFDEF DEBUG32
            PrintText 'DivConquer:Fwd Failed, Trying Bck'
            ENDIF
            
            Invoke KEYSearchLoopBck, ResEntry, 0, ResourceLocator, Version, Addr ResEntryOffset, Addr lpdwResEntryHint
            .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
                mov eax, ResEntryOffset
                mov ebx, lpdwResEntryHint
                ret
            .ELSE
                mov ebx, lpdwResEntryHint
                mov eax, 0
                mov [ebx], eax ; save reshint for future calls          
                mov eax, -1 ; not found
                mov ebx, 0
                ret
            .ENDIF
            
        .ENDIF       


 
;--------------------------------------------------------------------------------------
    .ELSE ; start searching at resource hint from last succesfull search. if not found we try searching back from reshint position, finally if not found we return -1
;--------------------------------------------------------------------------------------    
        ;PrintText 'Searching from reshint'
        ;PrintDec ResHint
        mov eax, ResHint
        mov ResEntry, eax
        .IF Version == 1
            mov ebx, SIZEOF RES_ENTRY
        .ELSEIF Version == 2
            mov ebx, SIZEOF RES_ENTRY_V1_WIDE
        .ENDIF
        mul ebx
        add eax, ResEntriesPtr
        mov ResEntryOffset, eax 
        
        ;PrintDec ResEntriesPtr
        ;PrintDec ResEntryOffset
        
        mov eax, ResEntry
        Invoke KEYSearchLoopFwd, ResEntry, TotalResEntries, ResourceLocator, Version, Addr ResEntryOffset, Addr lpdwResEntryHint
        .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
            mov eax, ResEntryOffset
            mov ebx, lpdwResEntryHint
            ret
        .ENDIF
        
        ;PrintText 'Searching backward from reshint'
        ; if we reach this point we didnt find it starting at our reshint to totalentries. so start search back in case we missed it for some reason.
        mov eax, ResHint
        mov ResEntry, eax
        .IF Version == 1
            mov ebx, SIZEOF RES_ENTRY
        .ELSEIF Version == 2
            mov ebx, SIZEOF RES_ENTRY_V1_WIDE
        .ENDIF
        mul ebx
        add eax, ResEntriesPtr
        mov ResEntryOffset, eax 
        
        Invoke KEYSearchLoopBck, ResEntry, 0, ResourceLocator, Version, Addr ResEntryOffset, Addr lpdwResEntryHint
        .IF eax == TRUE ; lpdwResEntryHint already filled in on succcess.
            mov eax, ResEntryOffset
            mov ebx, lpdwResEntryHint
            ret
        .ELSE
            mov ebx, lpdwResEntryHint
            mov eax, 0
            mov [ebx], eax ; save reshint for future calls          
            mov eax, -1 ; not found
            mov ebx, 0
            ret
        .ENDIF    

    .ENDIF
    
    ret

IEKEYFindResource endp




;-------------------------------------------------------------------------------------
; KEYSearchLoopFwdV11 - Returns in eax TRUE or FALSE for searching for dwResourceLocator
; starting at dwStartEntry and ending at dwEndEntry
; if TRUE on return then lpdwResEntryOffset contains new offset for matched dwResourceLocator
; and lpdwResEntryHint contains the Resource Entry for future calls
;-------------------------------------------------------------------------------------
KEYSearchLoopFwdV11 PROC USES EBX dwStartEntry:DWORD, dwEndEntry:DWORD, dwResourceLocator:DWORD, dwSourceIndex:DWORD, lpdwResEntryOffset:DWORD, lpdwResEntryHint:DWORD
    LOCAL ResEntryOffset:DWORD
    LOCAL ResEntry:DWORD
    
    IFDEF DEBUG32
    ;PrintText '  KEYSearchLoopFwdV11'
    ENDIF
    
    ;PrintDec dwStartEntry
    ;PrintDec dwEndEntry
    ;PrintDec dwResourceLocator
    ;PrintDec dwSourceIndex
    
    mov eax, lpdwResEntryOffset
    mov ebx, [eax]
    mov ResEntryOffset, ebx
    
    ;PrintDec ResEntryOffset
    
    mov eax, dwStartEntry
    mov ResEntry, eax
    
    .WHILE eax < dwEndEntry ; loop from start incrementing 1 each time
        mov ebx, ResEntryOffset
        mov eax, [ebx].RES_ENTRY_V11.ResourceFlags
        .IF eax == dwSourceIndex
            mov ebx, ResEntryOffset
            mov eax, [ebx].RES_ENTRY_V11.ResourceLocator
            .IF eax == dwResourceLocator
                ;PrintText '    KEYSearchLoopFwdV11:Found'
                ;PrintDec ResEntry
                ;PrintDec ResEntryOffset
                mov ebx, lpdwResEntryHint
                mov eax, ResEntry
                mov [ebx], eax ; save reshint for future calls            
                mov ebx, lpdwResEntryOffset
                mov eax, ResEntryOffset
                mov [ebx], eax ; save resentryoffset for other calls
                IFDEF DEBUG32
                ;PrintText 'KEYSearchLoopFwdV11::Found!'
                ;PrintDec dwResourceLocator
                ;PrintDec ResEntry
                ENDIF
                mov eax, TRUE
                ret                
            .ENDIF
        .ENDIF
        add ResEntryOffset, SIZEOF RES_ENTRY_V11
        inc ResEntry
        mov eax, ResEntry            
    .ENDW

    IFDEF DEBUG32
    PrintText 'KEYSearchLoopFwdV11::Not Found'
    ENDIF
    
    mov eax, FALSE
    
    ret

KEYSearchLoopFwdV11 endp


;-------------------------------------------------------------------------------------
; KEYSearchLoopBckV11 - Returns in eax TRUE or FALSE for searching for dwResourceLocator
; starting at dwStartEntry and ending at dwEndEntry
; if TRUE on return then lpdwResEntryOffset contains new offset for matched dwResourceLocator
; and lpdwResEntryHint contains the Resource Entry for future calls
;-------------------------------------------------------------------------------------
KEYSearchLoopBckV11 PROC USES EBX dwStartEntry:DWORD, dwEndEntry:DWORD, dwResourceLocator:DWORD, dwSourceIndex:DWORD, lpdwResEntryOffset:DWORD, lpdwResEntryHint:DWORD
    LOCAL ResEntryOffset:DWORD
    LOCAL ResEntry:DWORD
    
    IFDEF DEBUG32
    ;PrintText 'KEYSearchLoopBckV11'
    ENDIF
    
    mov eax, lpdwResEntryOffset
    mov ebx, [eax]
    mov ResEntryOffset, ebx
    mov eax, dwStartEntry
    mov ResEntry, eax
    
    .WHILE sdword ptr eax >= dwEndEntry ; loop from start decrementing 1 each time
        mov ebx, ResEntryOffset
        mov eax, [ebx].RES_ENTRY_V11.ResourceFlags
        .IF eax == dwSourceIndex
            mov ebx, ResEntryOffset
            mov eax, [ebx].RES_ENTRY_V11.ResourceLocator
            .IF eax == dwResourceLocator
                mov ebx, lpdwResEntryHint
                mov eax, ResEntry
                mov [ebx], eax ; save reshint for future calls            
                mov ebx, lpdwResEntryOffset
                mov eax, ResEntryOffset
                mov [ebx], eax ; save resentryoffset for other calls
                IFDEF DEBUG32
                ;PrintText 'KEYSearchLoopBckV11::Found!'
                ;PrintDec dwResourceLocator
                ;PrintDec ResEntry
                ENDIF
                mov eax, TRUE
                ret                
            .ENDIF
        .ENDIF
        sub ResEntryOffset, SIZEOF RES_ENTRY_V11
        dec ResEntry
        mov eax, ResEntry            
    .ENDW

    IFDEF DEBUG32
    PrintText 'KEYSearchLoopBckV11::Not Found'
    ENDIF
    
    mov eax, FALSE
    
    ret

KEYSearchLoopBckV11 endp


;-------------------------------------------------------------------------------------
; KEYSearchLoopFwd - Returns in eax TRUE or FALSE for searching for dwResourceLocator
; starting at dwStartEntry and ending at dwEndEntry
; if TRUE on return then lpdwResEntryOffset contains new offset for matched dwResourceLocator
; and lpdwResEntryHint contains the Resource Entry for future calls
;-------------------------------------------------------------------------------------
KEYSearchLoopFwd PROC USES EBX dwStartEntry:DWORD, dwEndEntry:DWORD, dwResourceLocator:DWORD, Version:DWORD, lpdwResEntryOffset:DWORD, lpdwResEntryHint:DWORD
    LOCAL ResEntryOffset:DWORD
    LOCAL ResEntry:DWORD
    
    IFDEF DEBUG32
    ;PrintText 'KEYSearchLoopFwd'
    ENDIF
    
    mov eax, lpdwResEntryOffset
    mov ebx, [eax]
    mov ResEntryOffset, ebx
    mov eax, dwStartEntry
    mov ResEntry, eax
    .WHILE eax < dwEndEntry ; loop from start incrementing 1 each time
        mov ebx, ResEntryOffset
        .IF Version == 1
            mov eax, [ebx].RES_ENTRY.ResourceLocator
        .ELSEIF Version == 2
            mov eax, [ebx].RES_ENTRY_V1_WIDE.ResourceLocator
        .ENDIF
        .IF eax == dwResourceLocator ;ResourceIndex
            ;PrintDec ResEntry
            mov ebx, lpdwResEntryHint
            mov eax, ResEntry
            mov [ebx], eax ; save reshint for future calls            
            mov ebx, lpdwResEntryOffset
            mov eax, ResEntryOffset
            mov [ebx], eax ; save resentryoffset for other calls
            ;mov ebx, ResEntry
            IFDEF DEBUG32
            ;PrintText 'KEYSearchLoopFwd::Found!'
            ;PrintDec dwResourceLocator
            ;PrintDec ResEntry
            ENDIF
            mov eax, TRUE
            ret
        .ENDIF
        .IF Version == 1
            add ResEntryOffset, SIZEOF RES_ENTRY
        .ELSEIF Version == 2
            add ResEntryOffset, SIZEOF RES_ENTRY_V1_WIDE
        .ENDIF
        inc ResEntry
        mov eax, ResEntry            
    .ENDW

    IFDEF DEBUG32
    PrintText 'KEYSearchLoopFwd::Not Found'
    ENDIF
    
    mov eax, FALSE
    
    ret

KEYSearchLoopFwd endp


;-------------------------------------------------------------------------------------
; KEYSearchLoopBck - Returns in eax TRUE or FALSE for searching for dwResourceLocator
; starting at dwStartEntry and ending at dwEndEntry
; if TRUE on return then lpdwResEntryOffset contains new offset for matched dwResourceLocator
; and lpdwResEntryHint contains the Resource Entry for future calls
;-------------------------------------------------------------------------------------
KEYSearchLoopBck PROC USES EBX dwStartEntry:DWORD, dwEndEntry:DWORD, dwResourceLocator:DWORD, Version:DWORD, lpdwResEntryOffset:DWORD, lpdwResEntryHint:DWORD
    LOCAL ResEntryOffset:DWORD
    LOCAL ResEntry:DWORD
    
    IFDEF DEBUG32
    ;PrintText 'KEYSearchLoopBck'
    ENDIF
    
    mov eax, lpdwResEntryOffset
    mov ebx, [eax]
    mov ResEntryOffset, ebx
    mov eax, dwStartEntry
    mov ResEntry, eax
    .WHILE sdword ptr eax >= dwEndEntry ; loop from start decrementing 1 each time
        mov ebx, ResEntryOffset
        .IF Version == 1
            mov eax, [ebx].RES_ENTRY.ResourceLocator
        .ELSEIF Version == 2
            mov eax, [ebx].RES_ENTRY_V1_WIDE.ResourceLocator
        .ENDIF
        .IF eax == dwResourceLocator ;ResourceIndex
            ;PrintDec ResEntry
            mov ebx, lpdwResEntryHint
            mov eax, ResEntry
            mov [ebx], eax ; save reshint for future calls            
            mov ebx, lpdwResEntryOffset
            mov eax, ResEntryOffset
            mov [ebx], eax ; save resentryoffset for other calls
            ;mov ebx, ResEntry
            IFDEF DEBUG32
            ;PrintText 'KEYSearchLoopBck::Found!'
            ;PrintDec dwResourceLocator
            ;PrintDec ResEntry
            ENDIF
            mov eax, TRUE
            ret
        .ENDIF
        .IF Version == 1
            sub ResEntryOffset, SIZEOF RES_ENTRY
        .ELSEIF Version == 2
            sub ResEntryOffset, SIZEOF RES_ENTRY_V1_WIDE
        .ENDIF
        dec ResEntry
        mov eax, ResEntry            
    .ENDW

    IFDEF DEBUG32
    PrintText 'KEYSearchLoopBck::Not Found'
    ENDIF
    
    mov eax, FALSE
    
    ret

KEYSearchLoopBck endp


;-------------------------------------------------------------------------------------
; IEKEYFindResourceByResRef - Returns in eax the resentry offset and in ebx the resentry of searched for resource or -1 otherwise
;-------------------------------------------------------------------------------------
IEKEYFindResourceByResRef PROC PUBLIC hIEKEY:DWORD, lpszResRef:DWORD
    LOCAL TotalResEntries:DWORD
    LOCAL ResEntry:DWORD
    LOCAL ResEntriesPtr:DWORD
    LOCAL ResEntryOffset:DWORD
    LOCAL szResRef[24]:BYTE
    LOCAL Version:DWORD
    
    .IF hIEKEY == NULL
        mov eax, -1
        mov ebx, -1
        ret
    .ENDIF

    Invoke IEKEYTotalResEntries, hIEKEY
    mov TotalResEntries, eax
    .IF eax == 0
        mov eax, -1
        mov ebx, -1
        ret
    .ENDIF

    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYResEntriesPtr
    mov ResEntriesPtr, eax
    mov eax, [ebx].KEYINFO.KEYVersion
    mov Version, eax
    
    mov eax, ResEntriesPtr
    mov ResEntryOffset, eax
    
    mov ResEntry, 0
    mov eax, 0
    .WHILE eax < TotalResEntries
        mov ebx, ResEntryOffset
        .IF Version == 1
            lea eax, [ebx].RES_ENTRY.ResourceName
            Invoke RtlMoveMemory, Addr szResRef, eax, 8d
            Invoke Cmpi, lpszResRef, Addr szResRef;, 8d
        .ELSEIF Version == 2
            lea eax, [ebx].RES_ENTRY_V1_WIDE.ResourceName
            Invoke RtlMoveMemory, Addr szResRef, eax, 16d
            Invoke Cmpi, lpszResRef, Addr szResRef;, 16d
        .ELSEIF Version == 3
            lea eax, [ebx].RES_ENTRY_V11.ResourceName
            Invoke RtlMoveMemory, Addr szResRef, eax, 16d
            Invoke Cmpi, lpszResRef, Addr szResRef;, 16d
        .ENDIF
        .IF eax == 0
            mov eax, ResEntryOffset
            mov ebx, ResEntry
            ret
        .ENDIF
        .IF Version == 1
            add ResEntryOffset, SIZEOF RES_ENTRY
        .ELSEIF Version == 2
            add ResEntryOffset, SIZEOF RES_ENTRY_V1_WIDE
        .ELSEIF Version == 3
            add ResEntryOffset, SIZEOF RES_ENTRY_V11
        .ENDIF
        inc ResEntry
        mov eax, ResEntry
    .ENDW
    mov eax, -1
    mov ebx, -1
    ret

IEKEYFindResourceByResRef endp


;-----------------------------------------------------------------------------------------
; Returns TRUE if wide resourcename is used 16bytes (SWKotoR) or 8 bytes (IE games), or -1 if failure
;-----------------------------------------------------------------------------------------
IEKEYWideResName PROC PUBLIC USES EBX hIEKEY:DWORD
    
    .IF hIEKEY == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYWideResEntries
    ret

IEKEYWideResName endp


;-----------------------------------------------------------------------------------------
; 0 no key, 1 = KEY V1, 2= KEY V1W, 3 = KEY V1.1
;-----------------------------------------------------------------------------------------
IEKEYVersion PROC PUBLIC USES EBX hIEKEY:DWORD
    
    .IF hIEKEY == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYVersion
    ret

IEKEYVersion ENDP


;-----------------------------------------------------------------------------------------
; IEKEYFileSize - returns in eax, size of file or eax = -1
;-----------------------------------------------------------------------------------------
IEKEYFileSize PROC PUBLIC USES EBX hIEKEY:DWORD
    
    .IF hIEKEY == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEKEY
    mov eax, [ebx].KEYINFO.KEYFilesize
    ret

IEKEYFileSize ENDP



;-----------------------------------------------------------------------------------------
; Checks the KEY signatures to determine if they are valid
;-----------------------------------------------------------------------------------------
;KEYSignature PROC PRIVATE hKEYFile:DWORD
;    LOCAL BytesRead:DWORD
;    
;    Invoke ReadFile, hKEYFile, Addr KEYXHeader,8, Addr BytesRead, NULL
;    Invoke szCmp, Addr KEYXHeader, Addr KEYV1Header
;    .IF eax == 0 ; no match
;        Invoke szCmp, Addr KEYXHeader, Addr KEYV11Header
;        .IF eax == 0 ; no match
;            mov eax, 0 ; no key file
;        .ELSE
;            mov eax, 3 ; KEYV11 File
;        .ENDIF    
;    .ELSE
;        mov eax, 1 ; KEYV1 File
;    .ENDIF
;    ret
;KEYSignature endp

KEYSignature PROC PRIVATE USES EBX pKEY:DWORD
    
    ; check signatures to determine version
    mov ebx, pKEY
    mov eax, [ebx]
    .IF eax == ' YEK' ; KEY
        add ebx, 4
        mov eax, [ebx]
        .IF eax == '  1V' ; V1.0
            mov ebx, pKEY
            mov eax, [ebx].KEY_HEADER_V1.OffsetBifEntries
            .IF eax > 24d
                mov eax, 2
            .ELSE
                mov eax, 1
            .ENDIF
        .ELSEIF eax == '1.1V' ; V1.0
            mov eax, 3
        .ELSE
            mov eax, 0
        .ENDIF
    .ENDIF
    ret

KEYSignature endp


;**************************************************************************
; Strip path name to just filename With extention
;**************************************************************************
KEYJustFname PROC szFilePathName:DWORD, szFileName:DWORD
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
KEYJustFname ENDP




;--------------------------------------------------------------------------------------------------------------------
; Dynamically allocates or resizes a memory location based on items in a structure and the size of the structure
;
; StructMemPtr is an address to receive the pointer to memory location of the base structure in memory.
; StructMemPtr can be NULL if TotalItems are 0. Otherwise it must contain the address of the base structure in memory
; if the memory is to be increased, TotalItems > 0
; ItemSize is typically SIZEOF structure to be allocated (this function calcs for you the size * TotalItems)
; On return eax contains the pointer to the new structure item or -1 if there was a problem alloc'ing memory.
;--------------------------------------------------------------------------------------------------------------------
KEYAllocStructureMemory PROC USES EBX dwPtrStructMem:DWORD, TotalItems:DWORD, ItemSize:DWORD
    LOCAL StructDataOffset:DWORD
    LOCAL StructSize:DWORD
    LOCAL StructData:DWORD
    
    ;PrintText 'AllocStructureMemory'
    .IF TotalItems == 0
        Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, ItemSize
        .IF eax != NULL
            mov StructData, eax
            mov ebx, dwPtrStructMem
            mov [ebx], eax ; save pointer to memory alloc'd for structure
            mov StructDataOffset, 0 ; save offset for new entry
            IFDEF DEBUG32
                PrintDec StructData
            ENDIF
        .ELSE
            IFDEF DEBUG32
            PrintText 'AllocStructureMemory::Mem error GlobalAlloc'
            ENDIF
            mov eax, -1
            ret
        .ENDIF
    .ELSE
        
        .IF dwPtrStructMem != NULL
        
            ; calc new size to grow structure and offset to new entry
            mov eax, TotalItems
            inc eax
            mov ebx, ItemSize
            mul ebx
            mov StructSize, eax ; save new size to alloc mem for
            mov ebx, ItemSize
            sub eax, ebx
            mov StructDataOffset, eax ; save offset for new entry
            
            mov ebx, dwPtrStructMem ; get value from addr of passed dword dwPtrStructMem into eax, this is our pointer to previous mem location of structure
            mov eax, [ebx]
            mov StructData, eax
            IFDEF DEBUG32
                PrintDec StructData
            ENDIF
            .IF TotalItems >= 2
                Invoke GlobalUnlock, StructData
            .ENDIF
            Invoke GlobalReAlloc, StructData, StructSize, GMEM_ZEROINIT + GMEM_MOVEABLE ; resize memory for structure
            .IF eax != NULL
                Invoke GlobalLock, eax
                mov StructData, eax
                mov ebx, dwPtrStructMem
                mov [ebx], eax ; save new pointer to memory alloc'd for structure back to dword address passed as dwPtrStructMem
            .ELSE
                ;PrintText 'Mem error GlobalReAlloc'
                IFDEF DEBUG32
                PrintText 'AllocStructureMemory::Mem error GlobalReAlloc'
                ENDIF                
                mov eax, -1
                ret
            .ENDIF
        
        .ELSE ; initialize structure size to the size specified by items * size
            
            ; calc size of structure
            mov eax, TotalItems
            mov ebx, ItemSize
            mul ebx
            mov StructSize, eax ; save new size to alloc mem for        
            Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, StructSize
            .IF eax != NULL
                mov StructData, eax
                ;mov ebx, dwPtrStructMem ; alloc memory so dont return anything to this as it was null when we got it
                ;mov [ebx], eax ; save pointer to memory alloc'd for structure
                mov StructDataOffset, 0 ; save offset for new entry
                IFDEF DEBUG32
                    PrintDec StructData
                ENDIF
            .ELSE
                IFDEF DEBUG32
                PrintText 'AllocStructureMemory::Mem error GlobalAlloc'
                ENDIF
                mov eax, -1
                ret
            .ENDIF
        .ENDIF
    .ENDIF

    ; calc entry to new item, (base address of memory alloc'd for structure + size of mem for new structure size - size of structure item)
    mov eax, StructData
    add eax, StructDataOffset
    
    ret
KEYAllocStructureMemory endp



END
