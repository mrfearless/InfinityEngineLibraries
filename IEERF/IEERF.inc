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

;-----------------------------------------------------------------------------------------
; IEERF Prototypes
;-----------------------------------------------------------------------------------------
IEERFOpen                   PROTO :DWORD, :DWORD            ; lpszErfFilename, dwOpenMode. Returns in eax a handle used in other functions: hIEERF
IEERFMem                    PROTO :DWORD, :DWORD, :DWORD, :DWORD ; pERFInMemory, lpszErfFilename, dwErfFilesize, dwOpenMode. Returns in eax a handle used in other functions: hIEERF
IEERFClose                  PROTO :DWORD                    ; hIEERF returned from IEERFOpen.

; Functions for returning pointers to internal erf structure areas of interest
IEERFHeader                 PROTO :DWORD                    ; hIEERF. Returns in eax pointer to a ERF_HEADER structure.
IEERFFileEntry              PROTO :DWORD, :DWORD            ; hIEERF, nFileEntry. Returns in eax pointer to a ERF_FILE_ENTRY structure.
IEERFResEntry               PROTO :DWORD, :DWORD            ; hIEERF, nFileEntry. Returns in eax pointer to a ERF_RES_ENTRY structure.
IEERFFileEntries            PROTO :DWORD                    ; hIEERF. Returns in eax pointer to File Entries
IEERFResEntries             PROTO :DWORD                    ; hIEERF. Returns in eax pointer to Resource Entries
IEERFFileData               PROTO :DWORD, :DWORD            ; hIEERF, nFileEntry. Returns in eax pointer to File data

; Erf file information
IEERFTotalFileEntries       PROTO :DWORD                    ; hIEERF. Returns in eax total no of file entries.

IEERFFileName               PROTO :DWORD                    ; hIEERF. Returns in eax pointer to erf full path filename
IEERFFileNameOnly           PROTO :DWORD, :DWORD            ; hIEERF, lpszFileNameOnly. eax contains True or false if succesfull. strips filename of path and ext information.
IEERFFileSize               PROTO :DWORD                    ; hIEERF. Returns in eax size of erf file in bytes
IEERFVersion                PROTO :DWORD                    ; hIEERF. Returns in eax 0 no ERF, 1 = ERF V1

IEERFExtractFile            PROTO :DWORD, :DWORD, :DWORD    ; hIEERF, nFileEntry, lpszOutputFilename. Returns in eax size of file extracted or -1 if failed
IEERFPeekFileSignature      PROTO :DWORD, :DWORD

;-----------------------------------------------------------------------------------------
; IEERF Structures
;-----------------------------------------------------------------------------------------
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


.CONST

IEERF_ALIGN                 TEXTEQU <ALIGN 16>
; IEERFOpen open mode:
IEERF_MODE_WRITE            EQU 0
IEERF_MODE_READONLY         EQU 1
; ERF Versions:
ERF_VERSION_INVALID         EQU 0 ; Not a ERF or invalid
ERF_VERSION_ERF_V10         EQU 1 ; ERF V1.0







