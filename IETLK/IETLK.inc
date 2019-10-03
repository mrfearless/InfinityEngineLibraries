;==============================================================================
;
; IETLK
;
; Copyright (c) 2018 by fearless
;
; All Rights Reserved
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

;------------------------------------------------------------------------------
; IETLK Prototypes
;------------------------------------------------------------------------------
IETLKOpen                   PROTO :DWORD,:DWORD             ; lpszTlkFilename, dwOpenMode. Returns in eax a handle used in other functions: hIETLK
IETLKMem                    PROTO :DWORD,:DWORD,:DWORD,:DWORD ; pTLKInMemory, lpszTlkFilename, dwTlkFilesize, dwOpenMode. Returns in eax a handle used in other functions: hIETLK
IETLKClose                  PROTO :DWORD                    ; hIETLK returned from IETLKOpen.

; Pointers to parts of TLK file:
IETLKHeader                 PROTO :DWORD                    ; hIETLK. Returns in eax pointer to a TLKV1_HEADER structure.
IETLKStringDataOffset       PROTO :DWORD                    ; hIETLK. Returns in eax pointer to a strings section in memory
IETLKStrRefEntries          PROTO :DWORD                    ; hIETLK. Returns in eax pointer to TLKV1_ENTRY array entries
IETLKStrRefEntry            PROTO :DWORD,:DWORD             ; hIETLK, nStrRef. Returns in eax pointer to specific TLKV1_ENTRY entry

; TLK Basic Information:
IETLKTotalStrRefs           PROTO :DWORD                    ; hIETLK. Returns in eax total StrRef entries in TLK file

; TLK File & Version Information:
IETLKFileName               PROTO :DWORD                    ; hIETLK. Returns in eax pointer to tis full path filename
IETLKFileNameOnly           PROTO :DWORD,:DWORD             ; hIETLK, lpszFileNameOnly. eax contains True or false if succesfull. strips filename of path and ext information.
IETLKFileSize               PROTO :DWORD                    ; hIETLK. Returns in eax size of tlk file in bytes
IETLKVersion                PROTO :DWORD                    ; hIETLK. Returns in eax 0 no tlk, 1 = TLK V1

;------------------------------------------------------------------------------
; IETLK Structures
;------------------------------------------------------------------------------
IFNDEF TLKV1_HEADER
TLKV1_HEADER            STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('TLK ')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V1  ')
    LangID              DW 0 ; 0x0008   2 (word)        Language ID
    NoStrRefEntries     DD 0 ; 0x000a   4 (dword)       Number of strref entries in this file
    StringDataOffset    DD 0 ; 0x000e   4 (dword)       Offset to string data
TLKV1_HEADER            ENDS
ENDIF

IFNDEF TLKV1_ENTRY ; (StrRef)
TLKV1_ENTRY             STRUCT
    StrRefType          DW 0 ; 0x0000   2 (word)        Bit field: 00 No message data, 01 Text exists, 02 Sound exists, 03 Standard message, 04 Token exists
    StrRefSound         DB 8 DUP (0) ;  8 (resref) 	    Resource name of associated sound
    StrRefVolume        DD 0 ; 0x000a 	4 (dword) 	    Volume variance (Unused, at minimum in BG1)
    StrRefPitch         DD 0 ; 0x000e 	4 (dword) 	    Pitch variance (Unused, at minimum in BG1)
    StrRefStringOffset  DD 0 ; 0x0012 	4 (dword) 	    Offset of this string relative to the strings section
    StrRefStringLength  DD 0 ; 0x0016 	4 (dword) 	    Length of this string
TLKV1_ENTRY             ENDS
ENDIF

.CONST
;------------------------------------------------------------------------------
; IETLK Constants
;------------------------------------------------------------------------------

IETLK_ALIGN                 TEXTEQU <ALIGN 16>
; IETLKOpen open mode:
IETLK_MODE_WRITE            EQU 0
IETLK_MODE_READONLY         EQU 1
; TLK Versions:
TLK_VERSION_INVALID         EQU 0 ; Not a TLK or invalid
TLK_VERSION_TLK_V1          EQU 1 ; TLK_V1











