;==============================================================================
;
; IEERF
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


include IEERF.inc

;DEBUG32 EQU 1
;IFDEF DEBUG32
;    PRESERVEXMMREGS equ 1
;    includelib M:\Masm32\lib\Debug32.lib
;    DBG32LIB equ 1
;    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
;    include M:\Masm32\include\debug32.inc
;ENDIF

;-------------------------------------------------------------------------
; Prototypes for internal use
;-------------------------------------------------------------------------
ERFSignature            PROTO :DWORD
ERFJustFname            PROTO :DWORD, :DWORD


;-------------------------------------------------------------------------
; Structures for internal use
;-------------------------------------------------------------------------

IFNDEF ERF_HEADER
ERF_HEADER              STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('ERF ')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V1.0')
    LanguageCount       DD 0 ; 0x0008   4 (dword)       
    LocalStringSize     DD 0 ; 0x000C   4 (dword)       
    FileEntriesCount    DD 0 ; 0x0010   4 (dword)       Count of files within this archive
    LocalStringOffset   DD 0 ; 0x0014   4 (dword)       
    FileEntriesOffset   DD 0 ; 0x0018   4 (dword)       file entries offset
    ResEntriesOffset    DD 0 ; 0x001C   4 (dword)       resource entries offset
    BuildYear           DD 0 ; 0x0020   4 (dword)       
    BuildDay            DD 0 ; 0x0024   4 (dword)       
    DescriptionStrRef   DD 0 ; 0x0028   4 (dword)       
    dwNulls             DB 116 DUP (0) ; 0x003C         NULLS
ERF_HEADER              ENDS
ENDIF

IFNDEF ERF_FILE_ENTRY
ERF_FILE_ENTRY          STRUCT
    ResourceName        DB 16 DUP (0)
    ResourceIndex       DD 0
    ResourceType        DW 0    
    Unknown             DW 0
ERF_FILE_ENTRY          ENDS
ENDIF

IFNDEF ERF_RES_ENTRY
ERF_RES_ENTRY           STRUCT
    ResourceOffset      DD 0
    ResourceSize        DD 0
ERF_RES_ENTRY           ENDS
ENDIF


IFNDEF ERFINFO
ERFINFO                 STRUCT
    ERFOpenMode         DD 0
    ERFFilename         DB MAX_PATH DUP (0)
    ERFFilesize         DD 0
    ERFVersion          DD 0
    ERFHeaderPtr        DD 0
    ERFHeaderSize       DD 0
    ERFFileEntriesPtr   DD 0
    ERFFileEntriesSize  DD 0
    ERFResEntriesPtr    DD 0
    ERFResEntriesSize   DD 0
    ERFFileDataPtr      DD 0 ;  array each entry corresponds to erf file entry and its data alloc'd in memory
    ERFMemMapPtr        DD 0
    ERFMemMapHandle     DD 0
    ERFFileHandle       DD 0
ERFINFO                 ENDS
ENDIF


.CONST



.DATA
NEWERFHeader            ERF_HEADER <" FRE", "  1V", 0, 128d, 1,>
ERFV1Header             db "ERF V1.0",0
ERFExt                  db ".erf",0
MODExt                  db ".mod",0
HAKExt                  db ".hak",0
NWMExt                  db ".nwm",0


.CODE


IEERF_ALIGN
;-------------------------------------------------------------------------------------
; IEERFOpen - Returns handle in eax of opened erf file. NULL if could not alloc enough mem
;-------------------------------------------------------------------------------------
IEERFOpen PROC USES EBX lpszErfFilename:DWORD, dwOpenMode:DWORD
    LOCAL hIEERF:DWORD
    LOCAL hERFFile:DWORD
    LOCAL ERFFilesize:DWORD
    LOCAL SigReturn:DWORD
    LOCAL ERFMemMapHandle:DWORD
    LOCAL ERFMemMapPtr:DWORD
    LOCAL pERF:DWORD

    .IF dwOpenMode == IEERF_MODE_READONLY ; readonly
        Invoke CreateFile, lpszErfFilename, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ELSE
        Invoke CreateFile, lpszErfFilename, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ENDIF

    .IF eax == INVALID_HANDLE_VALUE
        mov eax, NULL
        ret
    .ENDIF
    mov hERFFile, eax

    Invoke GetFileSize, hERFFile, NULL
    mov ERFFilesize, eax

    ;---------------------------------------------------                
    ; File Mapping: Create file mapping for main .erf
    ;---------------------------------------------------
    .IF dwOpenMode == IEERF_MODE_READONLY ; readonly
        Invoke CreateFileMapping, hERFFile, NULL, PAGE_READONLY, 0, 0, NULL ; Create memory mapped file
    .ELSE
        Invoke CreateFileMapping, hERFFile, NULL, PAGE_READWRITE, 0, 0, NULL ; Create memory mapped file
    .ENDIF   
    .IF eax == NULL
        Invoke CloseHandle, hERFFile 
        mov eax, NULL
        ret
    .ENDIF
    mov ERFMemMapHandle, eax
    
    .IF dwOpenMode == IEERF_MODE_READONLY ; readonly
        Invoke MapViewOfFileEx, ERFMemMapHandle, FILE_MAP_READ, 0, 0, 0, NULL
    .ELSE
        Invoke MapViewOfFileEx, ERFMemMapHandle, FILE_MAP_ALL_ACCESS, 0, 0, 0, NULL
    .ENDIF
    .IF eax == NULL
        Invoke CloseHandle, ERFMemMapHandle
        Invoke CloseHandle, hERFFile    
        mov eax, NULL
        ret
    .ENDIF
    mov ERFMemMapPtr, eax

    Invoke ERFSignature, ERFMemMapPtr
    mov SigReturn, eax
    .IF SigReturn == ERF_VERSION_INVALID ; not a valid erf file
        Invoke UnmapViewOfFile, ERFMemMapPtr
        Invoke CloseHandle, ERFMemMapHandle
        Invoke CloseHandle, hERFFile
        mov eax, NULL
        ret    
    
    .ELSE ; ERF V1
        Invoke IEERFMem, ERFMemMapPtr, lpszErfFilename, ERFFilesize, dwOpenMode
        mov hIEERF, eax
        .IF hIEERF == NULL
            Invoke UnmapViewOfFile, ERFMemMapPtr
            Invoke CloseHandle, ERFMemMapHandle
            Invoke CloseHandle, hERFFile
            mov eax, NULL
            ret    
        .ENDIF
        .IF dwOpenMode == IEERF_MODE_WRITE ; write (default)
            Invoke UnmapViewOfFile, ERFMemMapPtr
            Invoke CloseHandle, ERFMemMapHandle
            Invoke CloseHandle, hERFFile
        .ELSE ; else readonly, so keep mapping around till we close file
            mov ebx, hIEERF
            mov eax, ERFMemMapHandle
            mov [ebx].ERFINFO.ERFMemMapHandle, eax
            mov eax, hERFFile
            mov [ebx].ERFINFO.ERFFileHandle, eax
        .ENDIF

    .ENDIF
    ; save original version to handle for later use so we know if orignal file opened was standard ERF
    mov ebx, hIEERF
    mov eax, SigReturn
    mov [ebx].ERFINFO.ERFVersion, eax
    mov eax, hIEERF
    ret
IEERFOpen ENDP


IEERF_ALIGN
;-------------------------------------------------------------------------------------
; IEERFClose - Frees memory used by control data structure
;-------------------------------------------------------------------------------------
IEERFClose PROC USES EBX hIEERF:DWORD
    .IF hIEERF == NULL
        mov eax, 0
        ret
    .ENDIF

    mov ebx, hIEERF
    mov eax, [ebx].ERFINFO.ERFOpenMode
    .IF eax == IEERF_MODE_WRITE ; Write Mode
        mov ebx, hIEERF
        mov eax, [ebx].ERFINFO.ERFHeaderPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
    
        mov ebx, hIEERF
        mov eax, [ebx].ERFINFO.ERFFileEntriesPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
        
        mov ebx, hIEERF
        mov eax, [ebx].ERFINFO.ERFResEntriesPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
    .ENDIF
    
    mov ebx, hIEERF
    mov eax, [ebx].ERFINFO.ERFVersion
    .IF eax == ERF_VERSION_INVALID ; non ERF
        ; do nothing

    .ELSEIF eax == ERF_VERSION_ERF_V10 ; ERF - straight raw erf, so if  opened in readonly, unmap file, otherwise free mem

        mov ebx, hIEERF
        mov eax, [ebx].ERFINFO.ERFOpenMode
        .IF eax == IEERF_MODE_READONLY ; Read Only
            mov ebx, hIEERF
            mov eax, [ebx].ERFINFO.ERFMemMapPtr
            .IF eax != NULL
                Invoke UnmapViewOfFile, eax
            .ENDIF

            mov ebx, hIEERF
            mov eax, [ebx].ERFINFO.ERFMemMapHandle
            .IF eax != NULL
                Invoke CloseHandle, eax
            .ENDIF

            mov ebx, hIEERF
            mov eax, [ebx].ERFINFO.ERFFileHandle
            .IF eax != NULL
                Invoke CloseHandle, eax
            .ENDIF

        .ELSE ; free mem if write mode
            mov ebx, hIEERF
            mov eax, [ebx].ERFINFO.ERFMemMapPtr
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF
        .ENDIF
    .ENDIF
    
    mov eax, hIEERF
    .IF eax != NULL
        Invoke GlobalFree, eax
    .ENDIF

    mov eax, 0
    ret
IEERFClose ENDP


IEERF_ALIGN
;-----------------------------------------------------------------------------------------
; Checks the ERF signatures to determine if they are valid and if ERF file is compressed
; Also supports MOD/HAK/NWM files which are ERF files
;-----------------------------------------------------------------------------------------
ERFSignature PROC USES EBX pERF:DWORD
    ; check signatures to determine version
    mov ebx, pERF
    mov eax, [ebx]
    .IF eax == ' FRE' || eax == ' DOM' || eax == ' KAH' || eax == ' MWN'  ; ERF/MOD/HAK/NWM 
        add ebx, 4
        mov eax, [ebx]
        .IF eax == '0.1V' ; V1.0 standard ERF v1
            mov eax, ERF_VERSION_ERF_V10
        .ELSE
            mov eax, ERF_VERSION_INVALID
        .ENDIF
    .ELSE
        mov eax, ERF_VERSION_INVALID
    .ENDIF
    ret
ERFSignature endp


IEERF_ALIGN
;-------------------------------------------------------------------------------------
; IEERFMem - Returns handle in eax of opened erf file that is already loaded into memory. NULL if could not alloc enough mem
;-------------------------------------------------------------------------------------
IEERFMem PROC USES EBX pERFInMemory:DWORD, lpszErfFilename:DWORD, dwErfFilesize:DWORD, dwOpenMode:DWORD
    LOCAL hIEERF:DWORD
    LOCAL ERFMemMapPtr:DWORD
    LOCAL TotalFileEntries:DWORD
    LOCAL FileEntriesSize:DWORD
    LOCAL OffsetFileEntries:DWORD
    LOCAL OffsetResEntries:DWORD
    LOCAL ResEntriesSize:DWORD
    LOCAL LocalStringSize:DWORD

    mov eax, pERFInMemory
    mov ERFMemMapPtr, eax       

    ;----------------------------------
    ; Alloc mem for our IEERF Handle
    ;----------------------------------
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF ERFINFO
    .IF eax == NULL
        ret
    .ENDIF
    mov hIEERF, eax
    
    mov ebx, hIEERF
    mov eax, dwOpenMode
    mov [ebx].ERFINFO.ERFOpenMode, eax
    mov eax, ERFMemMapPtr
    mov [ebx].ERFINFO.ERFMemMapPtr, eax
    
    lea eax, [ebx].ERFINFO.ERFFilename
    Invoke szCopy, lpszErfFilename, eax
    
    mov ebx, hIEERF
    mov eax, dwErfFilesize
    mov [ebx].ERFINFO.ERFFilesize, eax

    ;----------------------------------
    ; ERF Header
    ;----------------------------------
    .IF dwOpenMode == IEERF_MODE_WRITE
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF ERF_HEADER
        .IF eax == NULL
            Invoke GlobalFree, hIEERF
            mov eax, NULL
            ret
        .ENDIF    
        mov ebx, hIEERF
        mov [ebx].ERFINFO.ERFHeaderPtr, eax
        mov ebx, ERFMemMapPtr
        Invoke RtlMoveMemory, eax, ebx, SIZEOF ERF_HEADER
    .ELSE
        mov ebx, hIEERF
        mov eax, ERFMemMapPtr
        mov [ebx].ERFINFO.ERFHeaderPtr, eax
    .ENDIF
    mov ebx, hIEERF
    mov eax, SIZEOF ERF_HEADER
    mov [ebx].ERFINFO.ERFHeaderSize, eax   

    ;----------------------------------
    ; File Counts, Offsets & Sizes
    ;----------------------------------
    mov ebx, [ebx].ERFINFO.ERFHeaderPtr
    mov eax, [ebx].ERF_HEADER.LocalStringSize
    mov LocalStringSize, eax
    mov eax, [ebx].ERF_HEADER.FileEntriesCount
    mov TotalFileEntries, eax
    mov eax, [ebx].ERF_HEADER.FileEntriesOffset
    mov OffsetFileEntries, eax
    mov eax, [ebx].ERF_HEADER.ResEntriesOffset
    mov OffsetResEntries, eax

    mov eax, TotalFileEntries
    mov ebx, SIZEOF ERF_FILE_ENTRY
    mul ebx
    mov FileEntriesSize, eax
    
    mov eax, TotalFileEntries
    mov ebx, SIZEOF ERF_RES_ENTRY
    mul ebx
    mov ResEntriesSize, eax    

    ;----------------------------------
    ; File Entries
    ;----------------------------------
    .IF TotalFileEntries > 0
        .IF dwOpenMode == IEERF_MODE_WRITE
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, FileEntriesSize
            .IF eax == NULL
                mov ebx, hIEERF
                mov eax, [ebx].ERFINFO.ERFHeaderPtr
                Invoke GlobalFree, eax    
                Invoke GlobalFree, hIEERF
                mov eax, NULL    
                ret
            .ENDIF    
            mov ebx, hIEERF
            mov [ebx].ERFINFO.ERFFileEntriesPtr, eax
        
            mov ebx, ERFMemMapPtr
            add ebx, OffsetFileEntries
            Invoke RtlMoveMemory, eax, ebx, FileEntriesSize
        .ELSE
            mov ebx, hIEERF
            mov eax, ERFMemMapPtr
            add eax, OffsetFileEntries
            mov [ebx].ERFINFO.ERFFileEntriesPtr, eax
        .ENDIF
        mov ebx, hIEERF
        mov eax, FileEntriesSize
        mov [ebx].ERFINFO.ERFFileEntriesSize, eax
        
        .IF dwOpenMode == IEERF_MODE_WRITE
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, ResEntriesSize
            .IF eax == NULL
                mov ebx, hIEERF
                mov eax, [ebx].ERFINFO.ERFHeaderPtr
                Invoke GlobalFree, eax    
                Invoke GlobalFree, hIEERF
                mov eax, NULL    
                ret
            .ENDIF    
            mov ebx, hIEERF
            mov [ebx].ERFINFO.ERFResEntriesPtr, eax
        
            mov ebx, ERFMemMapPtr
            add ebx, OffsetResEntries
            Invoke RtlMoveMemory, eax, ebx, ResEntriesSize
        .ELSE
            mov ebx, hIEERF
            mov eax, ERFMemMapPtr
            add eax, OffsetResEntries
            mov [ebx].ERFINFO.ERFResEntriesPtr, eax
        .ENDIF
        mov ebx, hIEERF
        mov eax, ResEntriesSize
        mov [ebx].ERFINFO.ERFResEntriesSize, eax
        
    .ELSE
        mov ebx, hIEERF
        mov [ebx].ERFINFO.ERFFileEntriesPtr, 0
        mov [ebx].ERFINFO.ERFFileEntriesSize, 0
        mov [ebx].ERFINFO.ERFResEntriesPtr, 0
        mov [ebx].ERFINFO.ERFResEntriesSize, 0
    .ENDIF
    mov eax, hIEERF
    ret
IEERFMem ENDP


IEERF_ALIGN
;-------------------------------------------------------------------------------------
; IEERFHeader - Returns in eax a pointer to header or NULL if not valid
;-------------------------------------------------------------------------------------
IEERFHeader PROC USES EBX hIEERF:DWORD
    .IF hIEERF == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEERF
    mov eax, [ebx].ERFINFO.ERFHeaderPtr
    ret
IEERFHeader ENDP


IEERF_ALIGN
;-------------------------------------------------------------------------------------
; IEERFFileEntry - Returns in eax a pointer to the specified file entry or NULL
;-------------------------------------------------------------------------------------
IEERFFileEntry PROC USES EBX hIEERF:DWORD, nFileEntry:DWORD
    LOCAL TotalFileEntries:DWORD
    LOCAL FileEntriesPtr:DWORD
    
    .IF hIEERF == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEERFTotalFileEntries, hIEERF
    .IF eax == 0
        mov eax, NULL
        ret
    .ENDIF    
    mov TotalFileEntries, eax

    .IF nFileEntry > eax
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEERFFileEntries, hIEERF
    mov FileEntriesPtr, eax
    
    mov eax, nFileEntry
    mov ebx, SIZEOF ERF_FILE_ENTRY
    mul ebx
    add eax, FileEntriesPtr
    ret
IEERFFileEntry ENDP


IEERF_ALIGN
;-------------------------------------------------------------------------------------
; IEERFResEntry - Returns in eax a pointer to the specified resource entry or NULL 
;-------------------------------------------------------------------------------------
IEERFResEntry PROC USES EBX hIEERF:DWORD, nFileEntry:DWORD
    LOCAL TotalFileEntries:DWORD
    LOCAL ResEntriesPtr:DWORD
    
    .IF hIEERF == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEERFTotalFileEntries, hIEERF
    .IF eax == 0
        mov eax, NULL
        ret
    .ENDIF    
    mov TotalFileEntries, eax

    .IF nFileEntry > eax
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEERFResEntries, hIEERF
    mov ResEntriesPtr, eax
    
    mov eax, nFileEntry
    mov ebx, SIZEOF ERF_RES_ENTRY
    mul ebx
    add eax, ResEntriesPtr
    ret
IEERFResEntry ENDP


IEERF_ALIGN
;-------------------------------------------------------------------------------------
; IEERFTotalFileEntries - Returns in eax the total no of file entries
;-------------------------------------------------------------------------------------
IEERFTotalFileEntries PROC USES EBX hIEERF:DWORD
    .IF hIEERF == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEERF
    mov ebx, [ebx].ERFINFO.ERFHeaderPtr
    .IF ebx != 0
        mov eax, [ebx].ERF_HEADER.FileEntriesCount
    .ELSE
        mov eax, 0
    .ENDIF
    ret
IEERFTotalFileEntries ENDP


IEERF_ALIGN
;-------------------------------------------------------------------------------------
; IEERFFileEntries - Returns in eax a pointer to file entries or NULL if not valid
;-------------------------------------------------------------------------------------
IEERFFileEntries PROC USES EBX hIEERF:DWORD
    .IF hIEERF == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEERF
    mov eax, [ebx].ERFINFO.ERFFileEntriesPtr
    ret
IEERFFileEntries ENDP


IEERF_ALIGN
;-------------------------------------------------------------------------------------
; IEERFResEntries - Returns in eax a pointer to resource entries or NULL if not valid
;-------------------------------------------------------------------------------------
IEERFResEntries PROC USES EBX hIEERF:DWORD
    .IF hIEERF == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEERF
    mov eax, [ebx].ERFINFO.ERFResEntriesPtr
    ret
IEERFResEntries ENDP


IEERF_ALIGN
;-------------------------------------------------------------------------------------
; IEERFFileName - returns in eax pointer to zero terminated string contained filename that is open or NULL if not opened
;-------------------------------------------------------------------------------------
IEERFFileName PROC USES EBX hIEERF:DWORD
    LOCAL ErfFilename:DWORD
    .IF hIEERF == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIEERF
    lea eax, [ebx].ERFINFO.ERFFilename
    mov ErfFilename, eax
    Invoke szLen, ErfFilename
    .IF eax == 0
        mov eax, NULL
    .ELSE
        mov eax, ErfFilename
    .ENDIF
    ret
IEERFFileName endp


IEERF_ALIGN
;-------------------------------------------------------------------------------------
; IEERFFileNameOnly - returns in eax true or false if it managed to pass to the buffer pointed at lpszFileNameOnly, the stripped filename without extension
;-------------------------------------------------------------------------------------
IEERFFileNameOnly PROC hIEERF:DWORD, lpszFileNameOnly:DWORD
    Invoke IEERFFileName, hIEERF
    .IF eax == NULL
        mov eax, FALSE
        ret
    .ENDIF
    
    Invoke ERFJustFname, eax, lpszFileNameOnly
    
    mov eax, TRUE
    ret
IEERFFileNameOnly endp


IEERF_ALIGN
;-------------------------------------------------------------------------------------
; IEERFFileSize - returns in eax size of file or 0
;-------------------------------------------------------------------------------------
IEERFFileSize PROC USES EBX hIEERF:DWORD
    .IF hIEERF == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEERF
    mov eax, [ebx].ERFINFO.ERFFilesize
    ret
IEERFFileSize endp


IEERF_ALIGN
;-------------------------------------------------------------------------------------
; 0 = No erf file, 1 = ERF V1
;-------------------------------------------------------------------------------------
IEERFVersion PROC USES EBX hIEERF:DWORD
    .IF hIEERF == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEERF
    mov eax, [ebx].ERFINFO.ERFVersion
    ret
IEERFVersion endp


IEERF_ALIGN
;-------------------------------------------------------------------------------------
; IEERFFileData - returns in eax pointer to file data or NULL if not found
;-------------------------------------------------------------------------------------
IEERFFileData PROC USES EBX hIEERF:DWORD, nFileEntry:DWORD
    LOCAL ResEntryOffset:DWORD
    LOCAL ResourceOffset:DWORD
    
    .IF hIEERF == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEERFResEntry, hIEERF, nFileEntry
    .IF eax == NULL
        ret
    .ENDIF
    mov ResEntryOffset, eax
    
    mov ebx, ResEntryOffset
    mov eax, [ebx].ERF_RES_ENTRY.ResourceOffset
    mov ResourceOffset, eax
    
    mov ebx, hIEERF
    mov eax, [ebx].ERFINFO.ERFMemMapPtr
    mov ebx, ResourceOffset
    add eax, ebx
    ret
IEERFFileData ENDP


IEERF_ALIGN
;-------------------------------------------------------------------------------------
; IEERFExtractFile - returns in eax size of file extracted or 0 if failed
;-------------------------------------------------------------------------------------
IEERFExtractFile PROC USES EBX hIEERF:DWORD, nFileEntry:DWORD, lpszOutputFilename:DWORD
    LOCAL ResEntryOffset:DWORD
    LOCAL ResourceSize:DWORD
    LOCAL ResourceData:DWORD
    LOCAL ResourceOffset:DWORD
    LOCAL hOutputFile:DWORD
    LOCAL MemMapHandle:DWORD
    LOCAL MemMapPtr:DWORD
    LOCAL Version:DWORD
    
    .IF hIEERF == NULL
        mov eax, 0
        ret
    .ENDIF
    
    Invoke IEERFResEntry, hIEERF, nFileEntry
    .IF eax == NULL
        ret
    .ENDIF
    mov ResEntryOffset, eax

    mov ebx, ResEntryOffset
    mov eax, [ebx].ERF_RES_ENTRY.ResourceSize
    mov ResourceSize, eax
    mov eax, [ebx].ERF_RES_ENTRY.ResourceOffset
    mov ResourceOffset, eax

    mov ebx, hIEERF
    mov eax, [ebx].ERFINFO.ERFMemMapPtr
    mov ebx, ResourceOffset
    add eax, ebx
    mov ResourceData, eax

    Invoke CreateFile, lpszOutputFilename, GENERIC_READ+GENERIC_WRITE, FILE_SHARE_READ+FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_FLAG_WRITE_THROUGH, NULL
    .IF eax == INVALID_HANDLE_VALUE
        mov eax, NULL
        ret
    .ENDIF
    mov hOutputFile, eax
    
    ; just in case we find a 0 byte resource
    .IF ResourceSize == 0
        Invoke CloseHandle, hOutputFile
        mov eax, 0
        ret
    .ENDIF
 
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
    
    Invoke FlushViewOfFile, MemMapPtr, ResourceSize
    Invoke UnmapViewOfFile, MemMapPtr
    Invoke CloseHandle, MemMapHandle 
    Invoke CloseHandle, hOutputFile
    mov eax, ResourceSize
    ret
IEERFExtractFile endp


IEERF_ALIGN
;-------------------------------------------------------------------------------------
; Peek at resource files actual signature - helps to determine actual resource type
; returns in eax SIG dword and ebx the version dword. NULL eax, NULL ebx if not valid entry or ieerf handle
;
; Returned dword is reverse of sig and version:
; CHR sig will be ' RHC' 
; EFF sig will be ' FFE'
; Version will be '  1V' of usual V1__ and '0.1V' for V1.0
;-------------------------------------------------------------------------------------
IEERFPeekFileSignature PROC hIEERF:DWORD, nFileEntry:DWORD
    LOCAL ResEntryOffset:DWORD
    LOCAL ResourceOffset:DWORD
        
    .IF hIEERF == NULL
        mov eax, NULL
        mov ebx, NULL
        ret
    .ENDIF

    Invoke IEERFResEntry, hIEERF, nFileEntry
    .IF eax == NULL
        mov ebx, NULL
        ret
    .ENDIF
    mov ResEntryOffset, eax
    
    mov ebx, ResEntryOffset
    mov eax, [ebx].ERF_RES_ENTRY.ResourceOffset
    mov ResourceOffset, eax
    mov ebx, hIEERF
    mov eax, [ebx].ERFINFO.ERFMemMapPtr
    mov ebx, ResourceOffset
    add eax, ebx        
    mov ebx, dword ptr [eax+4] ; save ebx first for the version dword
    mov eax, dword ptr [eax] ; overwrite eax with the sig dword
    ret
IEERFPeekFileSignature endp


IEERF_ALIGN
;**************************************************************************
; Strip path name to just filename Without extention
;**************************************************************************
ERFJustFname PROC szFilePathName:DWORD, szFileName:DWORD
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
ERFJustFname ENDP





END
