;==============================================================================
;
; IERIM
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


include IERIM.inc

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

;-------------------------------------------------------------------------
; Prototypes for internal use
;-------------------------------------------------------------------------
RIMSignature            PROTO :DWORD
RIMJustFname            PROTO :DWORD, :DWORD


;-------------------------------------------------------------------------
; Structures for internal use
;-------------------------------------------------------------------------

IFNDEF RIM_HEADER
RIM_HEADER              STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('RIM ')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V1  ')
    Unknown             DD 0
    FileEntriesCount    DD 0 ; 0x0008   4 (dword)       Count of files within this archive
    FileEntriesOffset   DD 0 ; 0x000c   4 (dword)       Directory offset
    RimVersion          DD 0 ; 0x0010   4 (dword)       version 1
    dwNulls             DB 96 DUP (0) ; 0x0014          NULLS
RIM_HEADER              ENDS
ENDIF

IFNDEF RIM_FILE_ENTRY
RIM_FILE_ENTRY          STRUCT
    ResourceName        DB 16 DUP (0)
    ResourceType        DD 0
    ResourceIndex       DD 0
    ResourceOffset      DD 0
    ResourceSize        DD 0
RIM_FILE_ENTRY          ENDS
ENDIF


IFNDEF RIMINFO
RIMINFO                 STRUCT
    RIMOpenMode         DD 0
    RIMFilename         DB MAX_PATH DUP (0)
    RIMFilesize         DD 0
    RIMVersion          DD 0
    RIMHeaderPtr        DD 0
    RIMHeaderSize       DD 0
    RIMFileEntriesPtr   DD 0
    RIMFileEntriesSize  DD 0
    RIMFileDataPtr      DD 0 ;  array each entry corresponds to bif file entry and its data alloc'd in memory
    RIMMemMapPtr        DD 0
    RIMMemMapHandle     DD 0
    RIMFileHandle       DD 0
RIMINFO                 ENDS
ENDIF


.CONST



.DATA
NEWRIMHeader            RIM_HEADER <" MIR", "  1V", 0, 128d, 1,>
RIMV1Header             db "RIM V1.0",0
IFDEF DEBUG32
DbgVar                      DD 0
ENDIF



.CODE

;-------------------------------------------------------------------------------------
; IERIMOpen - Returns handle in eax of opened rim file. NULL if could not alloc enough mem
;-------------------------------------------------------------------------------------
IERIMOpen PROC PUBLIC USES EBX lpszRimFilename:DWORD, dwOpenMode:DWORD
    LOCAL hIERIM:DWORD
    LOCAL hRIMFile:DWORD
    LOCAL RIMFilesize:DWORD
    LOCAL SigReturn:DWORD
    LOCAL RIMMemMapHandle:DWORD
    LOCAL RIMMemMapPtr:DWORD
    LOCAL pRIM:DWORD
    IFDEF DEBUGLOG
    DebugLogMsg "IERIMOpen", DEBUGLOG_FUNCTION, 2
    ENDIF
    .IF dwOpenMode == 1 ; readonly
        Invoke CreateFile, lpszRimFilename, GENERIC_READ, FILE_SHARE_READ+FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ELSE
        Invoke CreateFile, lpszRimFilename, GENERIC_READ+GENERIC_WRITE, FILE_SHARE_READ+FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ENDIF
    ;PrintDec eax
    .IF eax == INVALID_HANDLE_VALUE
        mov eax, FALSE
        ret
    .ENDIF
    mov hRIMFile, eax

    Invoke GetFileSize, hRIMFile, NULL
    mov RIMFilesize, eax

    ;---------------------------------------------------                
    ; File Mapping: Create file mapping for main .rim
    ;---------------------------------------------------
    .IF dwOpenMode == 1 ; readonly
        Invoke CreateFileMapping, hRIMFile, NULL, PAGE_READONLY, 0, 0, NULL ; Create memory mapped file
    .ELSE
        Invoke CreateFileMapping, hRIMFile, NULL, PAGE_READWRITE, 0, 0, NULL ; Create memory mapped file
    .ENDIF   
    .IF eax == NULL
        IFDEF DEBUGLOG
        DebugLogMsg "CreateFileMapping Failed", DEBUGLOG_INFO, 3
        ENDIF    
    
        ;PrintText 'Mapping Failed'
        mov eax, FALSE
        ret
    .ENDIF
    mov RIMMemMapHandle, eax
    
    .IF dwOpenMode == 1 ; readonly
        Invoke MapViewOfFileEx, RIMMemMapHandle, FILE_MAP_READ, 0, 0, 0, NULL
    .ELSE
        Invoke MapViewOfFileEx, RIMMemMapHandle, FILE_MAP_ALL_ACCESS, 0, 0, 0, NULL
    .ENDIF
    .IF eax == NULL
        ;PrintText 'Mapping View Failed'
        IFDEF DEBUGLOG
        DebugLogMsg "MapViewOfFileEx Failed", DEBUGLOG_INFO, 3
        ENDIF           
        mov eax, FALSE
        ret
    .ENDIF
    mov RIMMemMapPtr, eax

    Invoke RIMSignature, RIMMemMapPtr ;hRIMFile
    mov SigReturn, eax
    ;PrintDec SigReturn
    .IF SigReturn == 0 ; not a valid bif file
        Invoke UnmapViewOfFile, RIMMemMapPtr
        Invoke CloseHandle, RIMMemMapHandle
        Invoke CloseHandle, hRIMFile
        mov eax, NULL
        ret    
    
    .ELSE ; RIM V1
        Invoke IERIMMem, RIMMemMapPtr, lpszRimFilename, RIMFilesize, dwOpenMode
        mov hIERIM, eax
        .IF hIERIM == NULL
            Invoke UnmapViewOfFile, RIMMemMapPtr
            Invoke CloseHandle, RIMMemMapHandle
            Invoke CloseHandle, hRIMFile
            mov eax, NULL
            ret    
        .ENDIF
        .IF dwOpenMode == 0 ; write (default)
            Invoke UnmapViewOfFile, RIMMemMapPtr
            Invoke CloseHandle, RIMMemMapHandle
            Invoke CloseHandle, hRIMFile
        .ELSE ; else readonly, so keep mapping around till we close file
            mov ebx, hIERIM
            mov eax, RIMMemMapHandle
            mov [ebx].RIMINFO.RIMMemMapHandle, eax
            mov eax, hRIMFile
            mov [ebx].RIMINFO.RIMFileHandle, eax
        .ENDIF

    .ENDIF
    ; save original version to handle for later use so we know if orignal file opened was standard RIM
    mov ebx, hIERIM
    mov eax, SigReturn
    mov [ebx].RIMINFO.RIMVersion, eax
    
    IFDEF DEBUGLOG
    DebugLogMsg "IERIMOpen::Finished", DEBUGLOG_INFO, 2
    ENDIF
    mov eax, hIERIM
    
    IFDEF DEBUG32
        PrintDec hIERIM
    ENDIF
    ret
IERIMOpen ENDP


;-------------------------------------------------------------------------------------
; IERIMClose - Frees memory used by control data structure
;-------------------------------------------------------------------------------------
IERIMClose PROC PUBLIC USES EBX hIERIM:DWORD
    IFDEF DEBUGLOG
    DebugLogMsg "IERIMClose", DEBUGLOG_FUNCTION, 2
    ENDIF
    .IF hIERIM == NULL
        IFDEF DEBUGLOG
        DebugLogMsg "IERIMClose::hIERIM==NULL", DEBUGLOG_INFO, 3
        ENDIF
        mov eax, 0
        ret
    .ENDIF

    mov ebx, hIERIM
    mov eax, [ebx].RIMINFO.RIMOpenMode
    .IF eax == 0 ; Write Mode
        IFDEF DEBUGLOG
        DebugLogMsg "IERIMClose::Read/Write Mode", DEBUGLOG_INFO, 3
        ENDIF
        mov ebx, hIERIM
        mov eax, [ebx].RIMINFO.RIMHeaderPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
            IFDEF DEBUGLOG
            DebugLogMsg "IERIMClose::GlobalFree-RIMHeaderPtr::Success", DEBUGLOG_INFO, 3
            ENDIF
        .ENDIF
    
        mov ebx, hIERIM
        mov eax, [ebx].RIMINFO.RIMFileEntriesPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
            IFDEF DEBUGLOG
            DebugLogMsg "IERIMClose::GlobalFree-RIMFileEntriesPtr::Success", DEBUGLOG_INFO, 3
            ENDIF
        .ENDIF
    .ENDIF
    
    mov ebx, hIERIM
    mov eax, [ebx].RIMINFO.RIMVersion
    ;PrintDec eax
    IFDEF DEBUGLOG
    DebugLogValue "IERIMClose::RIMVersion", eax, 3
    ENDIF
    .IF eax == 0 ; non RIMF
        ; do nothing
        IFDEF DEBUGLOG
        DebugLogMsg "IERIMClose::RIMVersion::0 - NONE", DEBUGLOG_INFO, 3
        ENDIF
        
    .ELSEIF eax == 1 ; RIMF - straight raw biff, so if  opened in readonly, unmap file, otherwise free mem
        ;PrintText 'RIMF'
        IFDEF DEBUGLOG
        DebugLogMsg "IERIMClose::RIMVersion:: RIMF", DEBUGLOG_INFO, 3
        ENDIF
        
        mov ebx, hIERIM
        mov eax, [ebx].RIMINFO.RIMOpenMode
        .IF eax == 1 ; Read Only
            IFDEF DEBUGLOG
            DebugLogMsg "IERIMClose::RIMVersion:: RIMF (Read Only)", DEBUGLOG_INFO, 3
            ENDIF
            ;PrintText 'Read Only'
            mov ebx, hIERIM
            mov eax, [ebx].RIMINFO.RIMMemMapPtr
            .IF eax != NULL
                Invoke UnmapViewOfFile, eax
                IFDEF DEBUGLOG
                DebugLogMsg "IERIMClose::UnmapViewOfFile-RIMMemMapPtr::Success", DEBUGLOG_INFO, 3
                ENDIF
            .ENDIF
                      
            mov ebx, hIERIM
            mov eax, [ebx].RIMINFO.RIMMemMapHandle
            .IF eax != NULL
                Invoke CloseHandle, eax
                IFDEF DEBUGLOG
                DebugLogMsg "IERIMClose::CloseHandle-RIMMemMapHandle::Success", DEBUGLOG_INFO, 3
                ENDIF
            .ENDIF
            
            mov ebx, hIERIM
            mov eax, [ebx].RIMINFO.RIMFileHandle
            .IF eax != NULL
                Invoke CloseHandle, eax
                IFDEF DEBUGLOG
                DebugLogMsg "IERIMClose::CloseHandle-RIMFileHandle::Success", DEBUGLOG_INFO, 3
                ENDIF
            .ENDIF
                     
        .ELSE ; free mem if write mode
            IFDEF DEBUGLOG
            DebugLogMsg "IERIMClose::RIMVersion:: RIMF (Read / Write)", DEBUGLOG_INFO, 3
            ENDIF
            ;PrintText 'Read/Write'
            mov ebx, hIERIM
            mov eax, [ebx].RIMINFO.RIMMemMapPtr
            .IF eax != NULL
                Invoke GlobalFree, eax
                IFDEF DEBUGLOG
                DebugLogMsg "IERIMClose::GlobalFree-RIMMemMapPtr::Success", DEBUGLOG_INFO, 3
                ENDIF
            .ENDIF
        .ENDIF

    .ENDIF
    
    mov eax, hIERIM
    .IF eax != NULL
        Invoke GlobalFree, eax
        IFDEF DEBUGLOG
        DebugLogMsg "IERIMClose::GlobalFree-hIERIM::Success", DEBUGLOG_INFO, 3
        ENDIF
    .ENDIF
    IFDEF DEBUGLOG
    DebugLogMsg "IERIMClose::Finished", DEBUGLOG_INFO, 2
    ENDIF 
    mov eax, 0
    ret
IERIMClose ENDP


;-----------------------------------------------------------------------------------------
; Checks the RIM signatures to determine if they are valid and if BAM file is compressed
;-----------------------------------------------------------------------------------------
RIMSignature PROC PRIVATE USES EBX pRIM:DWORD
    ; check signatures to determine version
    mov ebx, pRIM
    mov eax, [ebx]
    .IF eax == ' MIR' ; RIM 
        add ebx, 4
        mov eax, [ebx]
        .IF eax == '0.1V' ; V1.0 standard RIM v1
            mov eax, 1
        .ELSE
            mov eax, 0
        .ENDIF
    .ELSE
        mov eax, 0
    .ENDIF
    ret
RIMSignature endp


;-------------------------------------------------------------------------------------
; IERIMMem - Returns handle in eax of opened bif file that is already loaded into memory. NULL if could not alloc enough mem
;-------------------------------------------------------------------------------------
IERIMMem PROC PUBLIC USES EBX pRIMInMemory:DWORD, lpszRimFilename:DWORD, dwRimFilesize:DWORD, dwOpenMode:DWORD
    LOCAL hIERIM:DWORD
    LOCAL RIMMemMapPtr:DWORD
    LOCAL TotalFileEntries:DWORD
    LOCAL FileEntriesSize:DWORD
    LOCAL OffsetFileEntries:DWORD
    LOCAL FileRimInfoExSize:DWORD

    IFDEF DEBUGLOG
    DebugLogMsg "IERIMMem", DEBUGLOG_FUNCTION, 2
    ENDIF
    mov eax, pRIMInMemory
    mov RIMMemMapPtr, eax       
    
    ;----------------------------------
    ; Alloc mem for our IERIM Handle
    ;----------------------------------
    Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, SIZEOF RIMINFO
    .IF eax == NULL
        ret
    .ENDIF
    mov hIERIM, eax
    
    mov ebx, hIERIM
    mov eax, dwOpenMode
    mov [ebx].RIMINFO.RIMOpenMode, eax
    mov eax, RIMMemMapPtr
    mov [ebx].RIMINFO.RIMMemMapPtr, eax
    
    lea eax, [ebx].RIMINFO.RIMFilename
    Invoke szCopy, lpszRimFilename, eax
    
    mov ebx, hIERIM
    mov eax, dwRimFilesize
    mov [ebx].RIMINFO.RIMFilesize, eax

    ;----------------------------------
    ; RIM Header
    ;----------------------------------
    .IF dwOpenMode == 0
        Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, SIZEOF RIM_HEADER
        .IF eax == NULL
            Invoke GlobalFree, hIERIM
            mov eax, NULL
            ret
        .ENDIF    
        mov ebx, hIERIM
        mov [ebx].RIMINFO.RIMHeaderPtr, eax
        mov ebx, RIMMemMapPtr
        Invoke RtlMoveMemory, eax, ebx, SIZEOF RIM_HEADER
    .ELSE
        mov ebx, hIERIM
        mov eax, RIMMemMapPtr
        mov [ebx].RIMINFO.RIMHeaderPtr, eax
    .ENDIF
    mov ebx, hIERIM
    mov eax, SIZEOF RIM_HEADER
    mov [ebx].RIMINFO.RIMHeaderSize, eax   

    ;----------------------------------
    ; File Counts, Offsets & Sizes
    ;----------------------------------
    mov ebx, [ebx].RIMINFO.RIMHeaderPtr
    mov eax, [ebx].RIM_HEADER.FileEntriesCount
    mov TotalFileEntries, eax
    mov eax, [ebx].RIM_HEADER.FileEntriesOffset
    mov OffsetFileEntries, eax
    
    mov eax, TotalFileEntries
    mov ebx, SIZEOF RIM_FILE_ENTRY
    mul ebx
    mov FileEntriesSize, eax

    IFDEF DEBUGLOG
    DebugLogValue "TotalFileEntries", TotalFileEntries, 3
    DebugLogValue "FileEntriesSize", FileEntriesSize, 3
    ENDIF
    ;----------------------------------
    ; File Entries
    ;----------------------------------
    .IF TotalFileEntries > 0
        .IF dwOpenMode == 0
            Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, FileEntriesSize
            .IF eax == NULL
                mov ebx, hIERIM
                mov eax, [ebx].RIMINFO.RIMHeaderPtr
                Invoke GlobalFree, eax    
                Invoke GlobalFree, hIERIM
                mov eax, NULL    
                ret
            .ENDIF    
            mov ebx, hIERIM
            mov [ebx].RIMINFO.RIMFileEntriesPtr, eax
        
            mov ebx, RIMMemMapPtr
            add ebx, OffsetFileEntries
            Invoke RtlMoveMemory, eax, ebx, FileEntriesSize
        .ELSE
            mov ebx, hIERIM
            mov eax, RIMMemMapPtr
            add eax, OffsetFileEntries
            mov [ebx].RIMINFO.RIMFileEntriesPtr, eax
        .ENDIF
        mov ebx, hIERIM
        mov eax, FileEntriesSize
        mov [ebx].RIMINFO.RIMFileEntriesSize, eax    
    .ELSE
        mov ebx, hIERIM
        mov [ebx].RIMINFO.RIMFileEntriesPtr, 0
        mov [ebx].RIMINFO.RIMFileEntriesSize, 0
    .ENDIF
    
    IFDEF DEBUG32
        PrintDec TotalFileEntries
    ENDIF
    IFDEF DEBUGLOG
    DebugLogMsg "IERIMMem::Finished", DEBUGLOG_INFO, 2
    ENDIF
    mov eax, hIERIM
    ret
IERIMMem ENDP


;-------------------------------------------------------------------------------------
; IERIMHeader - Returns in eax a pointer to header or -1 if not valid
;-------------------------------------------------------------------------------------
IERIMHeader PROC PUBLIC USES EBX hIERIM:DWORD
    .IF hIERIM == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIERIM
    mov eax, [ebx].RIMINFO.RIMHeaderPtr
    ret
IERIMHeader ENDP

;-------------------------------------------------------------------------------------
; IERIMFileEntry - Returns in eax a pointer to the specified file entry or -1 
;-------------------------------------------------------------------------------------
IERIMFileEntry PROC PUBLIC USES EBX hIERIM:DWORD, nFileEntry:DWORD
    LOCAL TotalFileEntries:DWORD
    LOCAL FileEntriesPtr:DWORD
    
    .IF hIERIM == NULL
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IERIMTotalFileEntries, hIERIM
    mov TotalFileEntries, eax
    .IF TotalFileEntries == 0
        mov eax, -1
        ret
    .ENDIF    

    mov eax, TotalFileEntries
    .IF nFileEntry > eax
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IERIMFileEntries, hIERIM
    mov FileEntriesPtr, eax
    
    mov eax, nFileEntry
    mov ebx, SIZEOF RIM_FILE_ENTRY
    mul ebx
    add eax, FileEntriesPtr
    ret
IERIMFileEntry ENDP

;-------------------------------------------------------------------------------------
; IERIMTotalFileEntries - Returns in eax the total no of file entries
;-------------------------------------------------------------------------------------
IERIMTotalFileEntries PROC PUBLIC USES EBX hIERIM:DWORD
    .IF hIERIM == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIERIM
    mov ebx, [ebx].RIMINFO.RIMHeaderPtr
    mov eax, [ebx].RIM_HEADER.FileEntriesCount
    ret
IERIMTotalFileEntries ENDP

;-------------------------------------------------------------------------------------
; IERIMFileEntries - Returns in eax a pointer to file entries or -1 if not valid
;-------------------------------------------------------------------------------------
IERIMFileEntries PROC PUBLIC USES EBX hIERIM:DWORD
    .IF hIERIM == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIERIM
    mov eax, [ebx].RIMINFO.RIMFileEntriesPtr
    ret
IERIMFileEntries ENDP

;-------------------------------------------------------------------------------------
; IERIMFileName - returns in eax pointer to zero terminated string contained filename that is open or -1 if not opened, 0 if in memory ?
;-------------------------------------------------------------------------------------
IERIMFileName PROC PUBLIC USES EBX hIERIM:DWORD
    LOCAL RimFilename:DWORD
    .IF hIERIM == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIERIM
    lea eax, [ebx].RIMINFO.RIMFilename
    mov RimFilename, eax
    Invoke szLen, RimFilename
    .IF eax == 0
        mov eax, -1
    .ELSE
        mov eax, RimFilename
        ;IFDEF DEBUG32
        ;    mov DbgVar, eax
        ;    PrintStringByAddr DbgVar
        ;ENDIF
    .ENDIF
    ;IFDEF DEBUG32
    ;    PrintDec eax
    ;ENDIF
    ret

IERIMFileName endp

;-------------------------------------------------------------------------------------
; IERIMFileNameOnly - returns in eax true or false if it managed to pass to the buffer pointed at lpszFileNameOnly, the stripped filename without extension
;-------------------------------------------------------------------------------------
IERIMFileNameOnly PROC PUBLIC USES EBX hIERIM:DWORD, lpszFileNameOnly:DWORD
    
    Invoke IERIMFileName, hIERIM
    .IF eax == -1
        mov eax, FALSE
        ret
    .ENDIF
    
    Invoke RIMJustFname, eax, lpszFileNameOnly
    
    mov eax, TRUE
    ret

IERIMFileNameOnly endp


;-------------------------------------------------------------------------------------
; IERIMFileSize - returns in eax size of file or -1
;-------------------------------------------------------------------------------------
IERIMFileSize PROC PUBLIC USES EBX hIERIM:DWORD
    .IF hIERIM == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIERIM
    mov eax, [ebx].RIMINFO.RIMFilesize
    ret

IERIMFileSize endp

;-------------------------------------------------------------------------------------
; 0 = No rim file, 1 = RIM V1
;-------------------------------------------------------------------------------------
IERIMVersion PROC PUBLIC USES EBX hIERIM:DWORD
    
    .IF hIERIM == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIERIM
    mov eax, [ebx].RIMINFO.RIMVersion
    ret

IERIMVersion endp


;-------------------------------------------------------------------------------------
; IERIMFileData - returns in eax pointer to file data or -1 if not found
;-------------------------------------------------------------------------------------
IERIMFileData PROC PUBLIC USES EBX hIERIM:DWORD, nFileEntry:DWORD
    LOCAL FileEntryOffset:DWORD
    LOCAL ResourceOffset:DWORD
    
    .IF hIERIM == NULL
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IERIMFileEntry, hIERIM, nFileEntry
    .IF eax == -1
        ret
    .ENDIF
    mov FileEntryOffset, eax
    
    mov ebx, FileEntryOffset
    mov eax, [ebx].RIM_FILE_ENTRY.ResourceOffset
    mov ResourceOffset, eax
    
    mov ebx, hIERIM
    mov eax, [ebx].RIMINFO.RIMMemMapPtr
    mov ebx, ResourceOffset
    add eax, ebx
    ret

IERIMFileData ENDP

;-------------------------------------------------------------------------------------
; IERIMExtractFile - returns in eax size of file extracted or -1 if failed
;-------------------------------------------------------------------------------------
IERIMExtractFile PROC PUBLIC USES EBX hIERIM:DWORD, nFileEntry:DWORD, lpszOutputFilename:DWORD
    LOCAL FileEntryOffset:DWORD
    LOCAL ResourceSize:DWORD
    LOCAL ResourceData:DWORD
    LOCAL ResourceOffset:DWORD
    LOCAL hOutputFile:DWORD
    LOCAL MemMapHandle:DWORD
    LOCAL MemMapPtr:DWORD
    LOCAL Version:DWORD
    
    .IF hIERIM == NULL
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IERIMFileEntry, hIERIM, nFileEntry
    .IF eax == -1
        ret
    .ENDIF
    mov FileEntryOffset, eax

    mov ebx, FileEntryOffset
    mov eax, [ebx].RIM_FILE_ENTRY.ResourceSize
    mov ResourceSize, eax
    mov eax, [ebx].RIM_FILE_ENTRY.ResourceOffset
    mov ResourceOffset, eax

    
    mov ebx, hIERIM
    mov eax, [ebx].RIMINFO.RIMMemMapPtr
    mov ebx, ResourceOffset
    add eax, ebx
    mov ResourceData, eax
    
    ;PrintDec FileEntryOffset
    ;PrintDec ResourceOffset
    ;PrintDec ResourceSize
    ;PrintDec ResourceData
    
    Invoke CreateFile, lpszOutputFilename, GENERIC_READ+GENERIC_WRITE, FILE_SHARE_READ+FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_FLAG_WRITE_THROUGH, NULL
    .IF eax == INVALID_HANDLE_VALUE
        mov eax, -1
        ret
    .ENDIF
    mov hOutputFile, eax
    
    ; just in case we find a 0 byte resource
    .IF ResourceSize == 0
        Invoke CloseHandle, hOutputFile
        mov eax, 0
        ret
    .ENDIF
    
    ;PrintDec hOutputFile
    Invoke CreateFileMapping, hOutputFile, NULL, PAGE_READWRITE, 0, ResourceSize, NULL
    .IF eax == NULL
        Invoke CloseHandle, hOutputFile
        mov eax, -1
        ret
    .ENDIF
    mov MemMapHandle, eax
    ;PrintDec MemMapHandle
    Invoke MapViewOfFile, MemMapHandle, FILE_MAP_ALL_ACCESS, 0, 0, 0
    .IF eax == NULL
        Invoke CloseHandle, MemMapHandle
        Invoke CloseHandle, hOutputFile
        mov eax, -1
        ret        
    .ENDIF
    mov MemMapPtr, eax
    
    
    ;PrintDec MemMapPtr
    Invoke RtlMoveMemory, MemMapPtr, ResourceData, ResourceSize
    
    Invoke FlushViewOfFile, MemMapPtr, ResourceSize
    Invoke UnmapViewOfFile, MemMapPtr
    Invoke CloseHandle, MemMapHandle 
    Invoke CloseHandle, hOutputFile
    mov eax, ResourceSize
    ret

IERIMExtractFile endp


;-------------------------------------------------------------------------------------
; Peek at resource files actual signature - helps to determine actual resource type
; returns in eax SIG dword and ebx the version dword. -1 eax, -1 ebx if not valid entry or ierim handle
;
; Returned dword is reverse of sig and version:
; CHR sig will be ' RHC' 
; EFF sig will be ' FFE'
; Version will be '  1V' of usual V1__ and '0.1V' for V1.0
;-------------------------------------------------------------------------------------
IERIMPeekFileSignature PROC PUBLIC hIERIM:DWORD, nFileEntry:DWORD
    LOCAL FileEntryOffset:DWORD
    LOCAL ResourceOffset:DWORD
        
    .IF hIERIM == NULL
        mov eax, -1
        mov ebx, -1
        ret
    .ENDIF

    Invoke IERIMFileEntry, hIERIM, nFileEntry
    .IF eax == -1
        mov eax, -1
        mov ebx, -1
        ret
    .ENDIF
    mov FileEntryOffset, eax
    
    mov ebx, FileEntryOffset
    mov eax, [ebx].RIM_FILE_ENTRY.ResourceOffset
    mov ResourceOffset, eax
    mov ebx, hIERIM
    mov eax, [ebx].RIMINFO.RIMMemMapPtr
    mov ebx, ResourceOffset
    add eax, ebx        
    mov ebx, dword ptr [eax+4] ; save ebx first for the version dword
    mov eax, dword ptr [eax] ; overwrite eax with the sig dword

    ret

IERIMPeekFileSignature endp











;**************************************************************************
; Strip path name to just filename Without extention
;**************************************************************************
RIMJustFname PROC szFilePathName:DWORD, szFileName:DWORD
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
RIMJustFname ENDP







END
