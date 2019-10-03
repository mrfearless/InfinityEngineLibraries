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
.686
.MMX
.XMM
.model flat,stdcall
option casemap:none
include \masm32\macros\macros.asm

include windows.inc
include kernel32.inc
include user32.inc
include masm32.inc

includelib kernel32.lib
includelib user32.lib
includelib masm32.lib

;DEBUG32 EQU 1
;IFDEF DEBUG32
;    PRESERVEXMMREGS equ 1
;    includelib M:\Masm32\lib\Debug32.lib
;    DBG32LIB equ 1
;    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
;    include M:\Masm32\include\debug32.inc
;ENDIF


include IETLK.inc

;------------------------------------------------------------------------------
; Prototypes for internal use
;------------------------------------------------------------------------------
TLKSignature            PROTO :DWORD
TLKJustFname            PROTO :DWORD, :DWORD



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


;------------------------------------------------------------------------------
; Structures for internal use
;------------------------------------------------------------------------------
IFNDEF TLKINFO
TLKINFO                     STRUCT
    TLKOpenMode             DD 0
    TLKFilename             DB MAX_PATH DUP (0)
    TLKFilesize             DD 0
    TLKVersion              DD 0
    TLKHeaderPtr            DD 0
    TLKHeaderSize           DD 0
    TLKStringDataOffset     DD 0
    TLKStrRefEntriesPtr     DD 0
    TLKStrRefEntriesSize    DD 0
    TLKMemMapPtr            DD 0
    TLKMemMapHandle         DD 0
    TLKFileHandle           DD 0    
TLKINFO                     ENDS
ENDIF


.CONST



.DATA
TLKV1Header             DB "TLK V1  ",0
NEWTLKHeader            TLKV1_HEADER <"TLK ", "V1  ", 0, 0, 0>
szTlkExt                db '.tlk',0


.CODE

IETLK_ALIGN
;------------------------------------------------------------------------------
; IETLKOpen - Returns handle in eax of opened TLK file. NULL if could not alloc enough mem
;------------------------------------------------------------------------------
IETLKOpen PROC USES EBX lpszTLKFilename:DWORD, dwOpenMode:DWORD
    LOCAL hIETLK:DWORD
    LOCAL hTLKFile:DWORD
    LOCAL TLKFilesize:DWORD
    LOCAL SigReturn:DWORD
    LOCAL TLKMemMapHandle:DWORD
    LOCAL TLKMemMapPtr:DWORD
    LOCAL pTLK:DWORD

    .IF dwOpenMode == IETLK_MODE_READONLY ; readonly
        Invoke CreateFile, lpszTLKFilename, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ELSE
        Invoke CreateFile, lpszTLKFilename, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ENDIF

    .IF eax == INVALID_HANDLE_VALUE
        mov eax, NULL
        ret
    .ENDIF
    mov hTLKFile, eax

    Invoke GetFileSize, hTLKFile, NULL
    mov TLKFilesize, eax

    ;---------------------------------------------------                
    ; File Mapping: Create file mapping for main .tlk
    ;---------------------------------------------------
    .IF dwOpenMode == IETLK_MODE_READONLY ; readonly
        Invoke CreateFileMapping, hTLKFile, NULL, PAGE_READONLY, 0, 0, NULL ; Create memory mapped file
    .ELSE
        Invoke CreateFileMapping, hTLKFile, NULL, PAGE_READWRITE, 0, 0, NULL ; Create memory mapped file
    .ENDIF   
    .IF eax == NULL
        Invoke CloseHandle, hTLKFile
        mov eax, NULL
        ret
    .ENDIF
    mov TLKMemMapHandle, eax
    
    .IF dwOpenMode == IETLK_MODE_READONLY ; readonly
        Invoke MapViewOfFileEx, TLKMemMapHandle, FILE_MAP_READ, 0, 0, 0, NULL
    .ELSE
        Invoke MapViewOfFileEx, TLKMemMapHandle, FILE_MAP_ALL_ACCESS, 0, 0, 0, NULL
    .ENDIF
    .IF eax == NULL
        Invoke CloseHandle, TLKMemMapHandle
        Invoke CloseHandle, hTLKFile
        mov eax, NULL
        ret
    .ENDIF
    mov TLKMemMapPtr, eax

    Invoke TLKSignature, TLKMemMapPtr
    mov SigReturn, eax
    .IF SigReturn == TLK_VERSION_INVALID ; not a valid erf file
        Invoke UnmapViewOfFile, TLKMemMapPtr
        Invoke CloseHandle, TLKMemMapHandle
        Invoke CloseHandle, hTLKFile
        mov eax, NULL
        ret    
    
    .ELSE ; TLK V1
        Invoke IETLKMem, TLKMemMapPtr, lpszTLKFilename, TLKFilesize, dwOpenMode
        mov hIETLK, eax
        .IF hIETLK == NULL
            Invoke UnmapViewOfFile, TLKMemMapPtr
            Invoke CloseHandle, TLKMemMapHandle
            Invoke CloseHandle, hTLKFile
            mov eax, NULL
            ret    
        .ENDIF
        .IF dwOpenMode == IETLK_MODE_WRITE ; write (default)
            Invoke UnmapViewOfFile, TLKMemMapPtr
            Invoke CloseHandle, TLKMemMapHandle
            Invoke CloseHandle, hTLKFile
        .ELSE ; else readonly, so keep mapping around till we close file
            mov ebx, hIETLK
            mov eax, TLKMemMapHandle
            mov [ebx].TLKINFO.TLKMemMapHandle, eax
            mov eax, hTLKFile
            mov [ebx].TLKINFO.TLKFileHandle, eax
        .ENDIF

    .ENDIF
    ; save original version to handle for later use so we know if orignal file opened was standard TLK
    mov ebx, hIETLK
    mov eax, SigReturn
    mov [ebx].TLKINFO.TLKVersion, eax
    mov eax, hIETLK
    ret
IETLKOpen ENDP


IETLK_ALIGN
;------------------------------------------------------------------------------
; IETLKMem
;------------------------------------------------------------------------------
IETLKMem PROC USES EBX pTLKInMemory:DWORD, lpszTlkFilename:DWORD, dwTlkFilesize:DWORD, dwOpenMode:DWORD
    LOCAL hIETLK:DWORD
    LOCAL TLKMemMapPtr:DWORD
    LOCAL NoStrRefEntries:DWORD
    LOCAL StringDataOffset:DWORD
    LOCAL StrRefEntriesPtr:DWORD
    LOCAL StrRefEntriesSize:DWORD

    LOCAL Version:DWORD

    mov eax, pTLKInMemory
    mov TLKMemMapPtr, eax       

    ;----------------------------------
    ; Alloc mem for our IETLK Handle
    ;----------------------------------
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF TLKINFO
    .IF eax == NULL
        ret
    .ENDIF
    mov hIETLK, eax
    
    mov ebx, hIETLK
    mov eax, dwOpenMode
    mov [ebx].TLKINFO.TLKOpenMode, eax
    mov eax, TLKMemMapPtr
    mov [ebx].TLKINFO.TLKMemMapPtr, eax
    
    lea eax, [ebx].TLKINFO.TLKFilename
    Invoke szCopy, lpszTlkFilename, eax
    
    mov ebx, hIETLK
    mov eax, dwTlkFilesize
    mov [ebx].TLKINFO.TLKFilesize, eax

    ;----------------------------------
    ; TLK Header
    ;----------------------------------
    .IF dwOpenMode == IETLK_MODE_WRITE
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF TLKV1_HEADER
        .IF eax == NULL
            Invoke GlobalFree, hIETLK
            mov eax, NULL
            ret
        .ENDIF    
        mov ebx, hIETLK
        mov [ebx].TLKINFO.TLKHeaderPtr, eax
        mov ebx, TLKMemMapPtr
        Invoke RtlMoveMemory, eax, ebx, SIZEOF TLKV1_HEADER
    .ELSE
        mov ebx, hIETLK
        mov eax, TLKMemMapPtr
        mov [ebx].TLKINFO.TLKHeaderPtr, eax
    .ENDIF
    mov ebx, hIETLK
    mov eax, SIZEOF TLKV1_HEADER
    mov [ebx].TLKINFO.TLKHeaderSize, eax   

    ;----------------------------------
    ; File Counts, Offsets & Sizes
    ;----------------------------------
    mov ebx, [ebx].TLKINFO.TLKHeaderPtr
    mov eax, [ebx].TLKV1_HEADER.NoStrRefEntries
    mov NoStrRefEntries, eax
    mov eax, [ebx].TLKV1_HEADER.StringDataOffset
    mov StringDataOffset, eax

    mov ebx, hIETLK
    mov eax, TLKMemMapPtr
    add eax, StringDataOffset
    mov [ebx].TLKINFO.TLKStringDataOffset, eax

    mov eax, NoStrRefEntries
    mov ebx, SIZEOF TLKV1_ENTRY
    mul ebx
    mov StrRefEntriesSize, eax

    ;----------------------------------
    ; StrRef Entries
    ;----------------------------------
    .IF NoStrRefEntries > 0
        .IF dwOpenMode == IETLK_MODE_WRITE
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, StrRefEntriesSize
            .IF eax == NULL
                mov ebx, hIETLK
                mov eax, [ebx].TLKINFO.TLKHeaderPtr
                Invoke GlobalFree, eax    
                Invoke GlobalFree, hIETLK
                mov eax, NULL    
                ret
            .ENDIF    
            mov ebx, hIETLK
            mov [ebx].TLKINFO.TLKStrRefEntriesPtr, eax
        
            mov ebx, TLKMemMapPtr
            add ebx, SIZEOF TLKV1_HEADER
            Invoke RtlMoveMemory, eax, ebx, StrRefEntriesSize
        .ELSE
            mov ebx, hIETLK
            mov eax, TLKMemMapPtr
            add eax, SIZEOF TLKV1_HEADER
            mov [ebx].TLKINFO.TLKStrRefEntriesPtr, eax
        .ENDIF
        mov ebx, hIETLK
        mov eax, StrRefEntriesSize
        mov [ebx].TLKINFO.TLKStrRefEntriesSize, eax

    .ELSE
        mov ebx, hIETLK
        mov [ebx].TLKINFO.TLKStrRefEntriesPtr, 0
        mov [ebx].TLKINFO.TLKStrRefEntriesSize, 0
    .ENDIF
    mov eax, hIETLK
    ret
IETLKMem ENDP


IETLK_ALIGN
;------------------------------------------------------------------------------
; IETLKClose - Frees memory used by control data structure
;------------------------------------------------------------------------------
IETLKClose PROC USES EBX hIETLK:DWORD
    .IF hIETLK == NULL
        mov eax, 0
        ret
    .ENDIF

    mov ebx, hIETLK
    mov eax, [ebx].TLKINFO.TLKOpenMode
    .IF eax == IETLK_MODE_WRITE ; Write Mode
        mov ebx, hIETLK
        mov eax, [ebx].TLKINFO.TLKHeaderPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
    
        mov ebx, hIETLK
        mov eax, [ebx].TLKINFO.TLKStrRefEntriesPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
    .ENDIF
    
    mov ebx, hIETLK
    mov eax, [ebx].TLKINFO.TLKVersion
    .IF eax == TLK_VERSION_INVALID ; non TLK
        ; do nothing

    .ELSE ; TLK - straight raw TLK, so if  opened in readonly, unmap file, otherwise free mem

        mov ebx, hIETLK
        mov eax, [ebx].TLKINFO.TLKOpenMode
        .IF eax == IETLK_MODE_READONLY ; Read Only
            mov ebx, hIETLK
            mov eax, [ebx].TLKINFO.TLKMemMapPtr
            .IF eax != NULL
                Invoke UnmapViewOfFile, eax
            .ENDIF

            mov ebx, hIETLK
            mov eax, [ebx].TLKINFO.TLKMemMapHandle
            .IF eax != NULL
                Invoke CloseHandle, eax
            .ENDIF

            mov ebx, hIETLK
            mov eax, [ebx].TLKINFO.TLKFileHandle
            .IF eax != NULL
                Invoke CloseHandle, eax
            .ENDIF

        .ELSE ; free mem if write mode
            mov ebx, hIETLK
            mov eax, [ebx].TLKINFO.TLKMemMapPtr
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF
        .ENDIF
    .ENDIF
    
    mov eax, hIETLK
    .IF eax != NULL
        Invoke GlobalFree, eax
    .ENDIF

    mov eax, 0
    ret
IETLKClose ENDP


IETLK_ALIGN
;------------------------------------------------------------------------------
; IETLKHeader - Returns in eax a pointer to header or NULL if not valid
;------------------------------------------------------------------------------
IETLKHeader PROC USES EBX hIETLK:DWORD
    .IF hIETLK == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIETLK
    mov eax, [ebx].TLKINFO.TLKHeaderPtr
    ret
IETLKHeader ENDP


IETLK_ALIGN
;------------------------------------------------------------------------------
; IETLKStrRefEntries - Returns in eax a pointer to the array of TLKV1_ENTRY
; or NULL if not valid
;------------------------------------------------------------------------------
IETLKStrRefEntries PROC USES EBX hIETLK:DWORD
    .IF hIETLK == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIETLK
    mov eax, [ebx].TLKINFO.TLKStrRefEntriesPtr
    ret
IETLKStrRefEntries ENDP


IETLK_ALIGN
;------------------------------------------------------------------------------
; IETLKStrRefEntry - Returns in eax a pointer to a specific TLKV1_ENTRY 
; entry or NULL if not valid
;------------------------------------------------------------------------------
IETLKStrRefEntry PROC USES EBX hIETLK:DWORD, nStrRef:DWORD
    LOCAL StrRefEntries:DWORD

    .IF hIETLK == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IETLKTotalStrRefs, hIETLK
    .IF nStrRef >= eax ; 0 based StrRef index
        mov eax, NULL
        ret
    .ENDIF        
    
    Invoke IETLKStrRefEntries, hIETLK
    .IF eax == NULL
        ret
    .ENDIF
    .IF nStrRef == 0
        ; eax contains StrRefEntries which is TLKV1_ENTRY 0's start
        ret
    .ENDIF    
    mov StrRefEntries, eax    
    
    Invoke IETLKVersion, hIETLK
    .IF eax == TLK_VERSION_TLK_V1
        mov ebx, SIZEOF TLKV1_ENTRY
    .ELSE
        mov eax, 0
        ret
    .ENDIF
    mov eax, nStrRef
    mul ebx
    add eax, StrRefEntries    
    
    ret
IETLKStrRefEntry ENDP


IETLK_ALIGN
;------------------------------------------------------------------------------
; IETLKTotalStrRefs - Returns in eax total StrRef entries in tlk
;------------------------------------------------------------------------------
IETLKTotalStrRefs PROC USES EBX hIETLK:DWORD
    .IF hIETLK == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIETLK
    mov ebx, [ebx].TLKINFO.TLKHeaderPtr
    .IF ebx != 0
        mov eax, [ebx].TLKV1_HEADER.NoStrRefEntries
    .ELSE
        mov eax, 0
    .ENDIF
    ret
IETLKTotalStrRefs ENDP


IETLK_ALIGN
;------------------------------------------------------------------------------
; IETLKStringDataOffset - Returns in eax pointer to strings section
;------------------------------------------------------------------------------
IETLKStringDataOffset PROC USES EBX hIETLK:DWORD
    .IF hIETLK == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIETLK
    mov eax, [ebx].TLKINFO.TLKStringDataOffset
    ret
IETLKStringDataOffset ENDP


IETLK_ALIGN
;------------------------------------------------------------------------------
; IETLKFileName - returns in eax pointer to zero terminated string contained 
; filename that is open or NULL if not opened
;------------------------------------------------------------------------------
IETLKFileName PROC USES EBX hIETLK:DWORD
    LOCAL TlkFilename:DWORD
    .IF hIETLK == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIETLK
    lea eax, [ebx].TLKINFO.TLKFilename
    mov TlkFilename, eax
    Invoke szLen, TlkFilename
    .IF eax == 0
        mov eax, NULL
    .ELSE
        mov eax, TlkFilename
    .ENDIF
    ret
IETLKFileName endp


IETLK_ALIGN
;------------------------------------------------------------------------------
; IETLKFileNameOnly - returns in eax true or false if it managed to pass to the 
; buffer pointed at lpszFileNameOnly, the stripped filename without extension
;------------------------------------------------------------------------------
IETLKFileNameOnly PROC hIETLK:DWORD, lpszFileNameOnly:DWORD
    Invoke IETLKFileName, hIETLK
    .IF eax == NULL
        mov eax, FALSE
        ret
    .ENDIF
    
    Invoke TLKJustFname, eax, lpszFileNameOnly
    
    mov eax, TRUE
    ret
IETLKFileNameOnly endp


IETLK_ALIGN
;------------------------------------------------------------------------------
; IETLKFileSize - returns in eax size of file or NULL
;------------------------------------------------------------------------------
IETLKFileSize PROC USES EBX hIETLK:DWORD
    .IF hIETLK == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIETLK
    mov eax, [ebx].TLKINFO.TLKFilesize
    ret
IETLKFileSize endp


IETLK_ALIGN
;------------------------------------------------------------------------------
; 0 = No Tlk file, 1 = TLK V1 
;------------------------------------------------------------------------------
IETLKVersion PROC USES EBX hIETLK:DWORD
    .IF hIETLK == NULL
        mov eax, NULL
        ret
    .ENDIF
    mov ebx, hIETLK
    mov eax, [ebx].TLKINFO.TLKVersion
    ret
IETLKVersion ENDP


IETLK_ALIGN
;******************************************************************************
; Checks the TLK signatures to determine if they are valid
;******************************************************************************
TLKSignature PROC USES EBX pTLK:DWORD
    ; check signatures to determine version
    mov ebx, pTLK
    mov eax, [ebx]
    .IF eax == ' KLT' ; TLK
        add ebx, 4
        mov eax, [ebx]
        .IF eax == '  1V' ; V1
            mov eax, TLK_VERSION_TLK_V1
        .ELSE
            mov eax, TLK_VERSION_INVALID
        .ENDIF
    .ELSE
        mov eax, TLK_VERSION_INVALID
    .ENDIF
    ret
TLKSignature endp


IETLK_ALIGN
;******************************************************************************
; Strip path name to just filename Without extention
;******************************************************************************
TLKJustFname PROC szFilePathName:DWORD, szFileName:DWORD
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
TLKJustFname ENDP



END
