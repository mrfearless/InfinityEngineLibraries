;==============================================================================
;
; IEPAL
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
; IEPAL Prototypes
;-----------------------------------------------------------------------------------------
IEPALOpen                   PROTO :DWORD, :DWORD            ; lpszPalFilename, dwOpenMode. Returns in eax a handle used in other functions: hIEPAL
IEPALMem                    PROTO :DWORD, :DWORD, :DWORD, :DWORD ; pPALInMemory, lpszPalFilename, dwPalFilesize, dwOpenMode. Returns in eax a handle used in other functions: hIEPAL
IEPALClose                  PROTO :DWORD                    ; hIEPAL returned from IEPALOpen.
IEPALVersion                PROTO :DWORD                    ; hIEPAL. Returns in eax value from defined constants Palette File Types

IEPALRGBtoBGR               PROTO :DWORD
IEPALBGRtoRGB               PROTO :DWORD





.CONST
; Palette File Types
PAL_FILEINVALID                 EQU 0 ; invalid not a recognised pal file format
PAL_FILETYPE_MSPAL              EQU 1 ; Microsoft RIFF Pal File Format
PAL_FILETYPE_ACT                EQU 2 ; Adobe .ACT Color Table File Format 76bytes long
PAL_FILETYPE_BAM                EQU 3 ; BAMV1 file format - Not BAMC or BAMV2
PAL_FILETYPE_BMP                EQU 4 ; 8 bit BMP
PAL_FILETYPE_PAL                EQU 5 ; raw .bin or .pal palette 1024 bytes long
PAL_FILETYPE_JASC               EQU 6 ; JASC Palette
PAL_FILETYPE_BAMC               EQU 7 ; BAMC compressed BAM file
PAL_FILETYPE8                   EQU 8
PAL_FILETYPE9                   EQU 9






