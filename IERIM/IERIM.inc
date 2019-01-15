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

;-----------------------------------------------------------------------------------------
; IERIM Prototypes
;-----------------------------------------------------------------------------------------
IERIMOpen                   PROTO :DWORD, :DWORD            ; lpszRimFilename, dwOpenMode. Returns in eax a handle used in other functions: hIERIM
IERIMMem                    PROTO :DWORD, :DWORD, :DWORD, :DWORD ; pRIMInMemory, lpszRimFilename, dwRimFilesize, dwOpenMode. Returns in eax a handle used in other functions: hIERIM
IERIMClose                  PROTO :DWORD                    ; hIERIM returned from IERIMOpen.

; Functions for returning pointers to internal rim structure areas of interest
IERIMHeader                 PROTO :DWORD                    ; hIERIM. Returns in eax pointer to a RIM_HEADER structure.
IERIMFileEntry              PROTO :DWORD, :DWORD            ; hIERIM, nFileEntry. Returns in eax pointer to a RIM_FILE_ENTRY structure.
IERIMFileEntries            PROTO :DWORD                    ; hIERIM. Returns in eax pointer to File Entries
IERIMFileData               PROTO :DWORD, :DWORD            ; hIERIM, nFileEntry. Returns in eax pointer to File data

; Rim file information
IERIMTotalFileEntries       PROTO :DWORD                    ; hIERIM. Returns in eax total no of file entries.

IERIMFileName               PROTO :DWORD                    ; hIERIM. Returns in eax pointer to rim full path filename
IERIMFileNameOnly           PROTO :DWORD, :DWORD            ; hIERIM, lpszFileNameOnly. eax contains True or false if succesfull. strips filename of path and ext information.
IERIMFileSize               PROTO :DWORD                    ; hIERIM. Returns in eax size of rim file in bytes
IERIMVersion                PROTO :DWORD                    ; hIERIM. Returns in eax 0 no rim, 1 = RIM V1

IERIMExtractFile            PROTO :DWORD, :DWORD, :DWORD    ; hIERIM, nFileEntry, lpszOutputFilename. Returns in eax size of file extracted or -1 if failed
IERIMPeekFileSignature      PROTO :DWORD, :DWORD




;-----------------------------------------------------------------------------------------
; IERIM Structures
;-----------------------------------------------------------------------------------------

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



.CONST
IERIM_ALIGN                 TEXTEQU <ALIGN 16>
; IERIMOpen open mode:
IERIM_MODE_WRITE            EQU 0
IERIM_MODE_READONLY         EQU 1
; RIM Versions:
RIM_VERSION_INVALID         EQU 0 ; Not a RIM or invalid
RIM_VERSION_RIM_V10         EQU 1 ; RIM V1.0



















