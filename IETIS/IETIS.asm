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

;-------------------------------------------------------------------------
; Structures for internal use
;-------------------------------------------------------------------------
IFNDEF TISV1_HEADER
TISV1_HEADER            STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('TIS ')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V1  ')
    TilesCount          DD 0 ; 0x0008   4 (dword)       Count of tiles within this tileset
    TilesSectionLength  DD 0 ; 0x000c   4 (dword)       Length of tiles section
    OffsetTilesData     DD 0 ; 0x0010   4 (dword)       Tile header size, offset to tiles, always 24d
    TileDimension       DD 0 ; 0x0014   4 (dword)       Dimension of 1 tile in pixels (64x64) 64 ?
TISV1_HEADER            ENDS
ENDIF


.CONST



.DATA
NEWTISHeader            TISV1_HEADER <"TIS ", "V1  ", 0, 0, 24d, 64d>

IFDEF DEBUG32
DbgVar                      DD 0
ENDIF


.CODE

;**************************************************************************
; IETIS
;**************************************************************************























END
