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
.686
.MMX
.XMM
.model flat,stdcall
option casemap:none
include \masm32\macros\macros.asm

;DEBUG32 EQU 1

IFDEF DEBUG32
    PRESERVEXMMREGS equ 1
    includelib M:\Masm32\lib\Debug32.lib
    DBG32LIB equ 1
    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
    include M:\Masm32\include\debug32.inc
ENDIF

include windows.inc

include user32.inc
includelib user32.lib

include gdi32.inc
includelib gdi32.lib

include kernel32.inc
includelib kernel32.lib

include masm32.inc
includelib masm32.lib

include zlibstat.inc
includelib zlibstat.lib

include IEPAL.inc

;DEBUGLOG EQU 1
IFDEF DEBUGLOG
    include DebugLogLIB.asm
ENDIF

;-------------------------------------------------------------------------
; Prototypes for internal use
;-------------------------------------------------------------------------

PALConvertRGBPalToBGRPal    PROTO :DWORD

PALConvertACTtoBAMPalette   PROTO :DWORD
PALConvertJASCToBAMPalette  PROTO :DWORD
PALBAMUncompress            PROTO :DWORD, :DWORD, :DWORD
PALSignature                PROTO :DWORD, :DWORD, :DWORD
PALJustFname                PROTO :DWORD, :DWORD
PALJustExt                  PROTO :DWORD, :DWORD





RGBCOLOR macro r:REQ,g:REQ,b:REQ    
    exitm <( ( ( ( r )  or  ( ( ( g ) )  shl  8 ) )  or  ( ( ( b ) )  shl  16 ) ) ) >
ENDM

RgbSwap MACRO rgb ; mov eax,RgbSwap(804020h) ;EAX = 204080h ; http://masm32.com/board/index.php?topic=338.msg2170#msg2170
    EXITM % ((rgb AND 0FF0000h) SHR 16) OR (rgb AND 0FF00h) OR ((rgb AND 0FFh) SHL 16)
ENDM


;-------------------------------------------------------------------------
; Structures for internal use
;-------------------------------------------------------------------------
PALINFO                     STRUCT 
    PALOpenMode             DD 0
    PALFilename             DB MAX_PATH DUP (0)
    PALFilesize             DD 0
    PALVersion              DD 0 ; type of pal file we are using
    PALHeaderPtr            DD 0
    PALHeaderSize           DD 0
    BAMPalettePtr           DD 0
    BAMPaletteSize          DD 1024d ; RGBQUAD style color array x 256 entries for BAM files
    PALPalettePtr           DD 0
    PALPaletteSize          DD 1024d ; ColorRef style color array x 256 entries for GDI color display
    PALBitmapPtr            DD 0 ; pointer to bitmap representation of the palette.
    PALBitmapSize           DD 0
    PALMemMapPtr            DD 0
    PALMemMapHandle         DD 0
    PALFileHandle           DD 0   
PALINFO                     ENDS

IFNDEF BAMC_HEADER
BAMC_HEADER             STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('BAMC')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V1 ')
    UncompressedLength  DD 0 ; 0x0008   4 (dword)       Uncompressed data length
BAMC_HEADER             ENDS
ENDIF





.DATA
IFDEF DEBUG32
DbgVar                      DD 0
ENDIF
PALBMPInfo                  BITMAPINFOHEADER <40d, 0, 0, 1, 8, BI_RGB, 0, 0, 0, 0, 0> ;Header
PALBMPPalette               db 1024 dup (0) ; BITMAPFILEHEADER <'BM', 0, 0, 0, 54d>

PALExt                      db 'pal',0
BINExt                      db 'bin',0
BAMExt                      db 'bam',0
ACTExt                      db 'act',0
BMPExt                      db 'bmp',0
MSPALHeader                 db 'RIFF',0
JASCPALHeader               db 'JASC-PAL',0
BAMV1Header                 db "BAM V1  ",0
BAMV2Header                 db "BAM V2  ",0
BAMCHeader                  db "BAMCV1  ",0
BMPHeader                   db "BM",0
XHeader                     db 12 dup (0)
dwCRLF                      dd 2573d ;0Ah,0Dh
.CODE

;-------------------------------------------------------------------------------------
; IEPALOpen - Returns handle in eax of opened pal file. NULL if could not alloc enough mem
;-------------------------------------------------------------------------------------
IEPALOpen PROC PUBLIC USES EBX lpszPalFilename:DWORD, dwOpenMode:DWORD
    LOCAL hIEPAL:DWORD
    LOCAL hPALFile:DWORD
    LOCAL PALFilesize:DWORD
    LOCAL SigReturn:DWORD
    LOCAL PALMemMapHandle:DWORD
    LOCAL PALMemMapPtr:DWORD
    LOCAL pPAL:DWORD

    IFDEF DEBUGLOG
    DebugLogMsg "IEPALOpen", DEBUGLOG_FUNCTION, 2
    ENDIF
    
    .IF dwOpenMode == 1 ; readonly
        Invoke CreateFile, lpszPalFilename, GENERIC_READ, FILE_SHARE_READ+FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ELSE
        Invoke CreateFile, lpszPalFilename, GENERIC_READ+GENERIC_WRITE, FILE_SHARE_READ+FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ENDIF
    ;PrintDec eax
    .IF eax == INVALID_HANDLE_VALUE
        mov eax, NULL
        ret
    .ENDIF
    
    mov hPALFile, eax

    Invoke GetFileSize, hPALFile, NULL
    mov PALFilesize, eax

    ;---------------------------------------------------                
    ; File Mapping: Create file mapping for main .pal
    ;---------------------------------------------------
    .IF dwOpenMode == 1 ; readonly
        Invoke CreateFileMapping, hPALFile, NULL, PAGE_READONLY, 0, 0, NULL ; Create memory mapped file
    .ELSE
        Invoke CreateFileMapping, hPALFile, NULL, PAGE_READWRITE, 0, 0, NULL ; Create memory mapped file
    .ENDIF   
    .IF eax == NULL
        Invoke CloseHandle, hPALFile
        mov eax, NULL
        ret
    .ENDIF
    mov PALMemMapHandle, eax
    
    .IF dwOpenMode == 1 ; readonly
        Invoke MapViewOfFileEx, PALMemMapHandle, FILE_MAP_READ, 0, 0, 0, NULL
    .ELSE
        Invoke MapViewOfFileEx, PALMemMapHandle, FILE_MAP_ALL_ACCESS, 0, 0, 0, NULL
    .ENDIF
    .IF eax == NULL
        Invoke CloseHandle, PALMemMapHandle
        Invoke CloseHandle, hPALFile
        mov eax, NULL
        ret
    .ENDIF
    mov PALMemMapPtr, eax

    ; detect type of pal from file extension etc

    Invoke PALSignature, PALMemMapPtr, lpszPalFilename, PALFilesize ;hBIFFile
    mov SigReturn, eax
    ;PrintDec SigReturn
    .IF SigReturn == 0 ; not a valid pal file
        Invoke UnmapViewOfFile, PALMemMapPtr
        Invoke CloseHandle, PALMemMapHandle
        Invoke CloseHandle, hPALFile
        mov eax, NULL
        ret    
    
    .ELSEIF SigReturn == PAL_FILETYPE_MSPAL ;1 ; 
        Invoke IEPALMem, PALMemMapPtr, lpszPalFilename, PALFilesize, dwOpenMode
        mov hIEPAL, eax
        .IF hIEPAL == NULL
            Invoke UnmapViewOfFile, PALMemMapPtr
            Invoke CloseHandle, PALMemMapHandle
            Invoke CloseHandle, hPALFile
            mov eax, NULL
            ret    
        .ENDIF
        .IF dwOpenMode == 0 ; write (default)
            Invoke UnmapViewOfFile, PALMemMapPtr
            Invoke CloseHandle, PALMemMapHandle
            Invoke CloseHandle, hPALFile
        .ELSE ; else readonly, so keep mapping around till we close file
            mov ebx, hIEPAL
            mov eax, PALMemMapHandle
            mov [ebx].PALINFO.PALMemMapHandle, eax
            mov eax, hPALFile
            mov [ebx].PALINFO.PALFileHandle, eax
        .ENDIF

    .ELSEIF SigReturn == PAL_FILETYPE_ACT ;2
        Invoke IEPALMem, PALMemMapPtr, lpszPalFilename, PALFilesize, dwOpenMode
        mov hIEPAL, eax
        .IF hIEPAL == NULL
            Invoke UnmapViewOfFile, PALMemMapPtr
            Invoke CloseHandle, PALMemMapHandle
            Invoke CloseHandle, hPALFile
            mov eax, NULL
            ret    
        .ENDIF
        .IF dwOpenMode == 0 ; write (default)
            Invoke UnmapViewOfFile, PALMemMapPtr
            Invoke CloseHandle, PALMemMapHandle
            Invoke CloseHandle, hPALFile
        .ELSE ; else readonly, so keep mapping around till we close file
            mov ebx, hIEPAL
            mov eax, PALMemMapHandle
            mov [ebx].PALINFO.PALMemMapHandle, eax
            mov eax, hPALFile
            mov [ebx].PALINFO.PALFileHandle, eax
        .ENDIF

    .ELSEIF SigReturn == PAL_FILETYPE_BAM ;3 
        Invoke IEPALMem, PALMemMapPtr, lpszPalFilename, PALFilesize, dwOpenMode
        mov hIEPAL, eax
        .IF hIEPAL == NULL
            Invoke UnmapViewOfFile, PALMemMapPtr
            Invoke CloseHandle, PALMemMapHandle
            Invoke CloseHandle, hPALFile
            mov eax, NULL
            ret    
        .ENDIF
        .IF dwOpenMode == 0 ; write (default)
            Invoke UnmapViewOfFile, PALMemMapPtr
            Invoke CloseHandle, PALMemMapHandle
            Invoke CloseHandle, hPALFile
        .ELSE ; else readonly, so keep mapping around till we close file
            mov ebx, hIEPAL
            mov eax, PALMemMapHandle
            mov [ebx].PALINFO.PALMemMapHandle, eax
            mov eax, hPALFile
            mov [ebx].PALINFO.PALFileHandle, eax
        .ENDIF
        
    .ELSEIF SigReturn == PAL_FILETYPE_BMP ;4
        Invoke IEPALMem, PALMemMapPtr, lpszPalFilename, PALFilesize, dwOpenMode
        mov hIEPAL, eax
        .IF hIEPAL == NULL
            Invoke UnmapViewOfFile, PALMemMapPtr
            Invoke CloseHandle, PALMemMapHandle
            Invoke CloseHandle, hPALFile
            mov eax, NULL
            ret    
        .ENDIF
        .IF dwOpenMode == 0 ; write (default)
            Invoke UnmapViewOfFile, PALMemMapPtr
            Invoke CloseHandle, PALMemMapHandle
            Invoke CloseHandle, hPALFile
        .ELSE ; else readonly, so keep mapping around till we close file
            mov ebx, hIEPAL
            mov eax, PALMemMapHandle
            mov [ebx].PALINFO.PALMemMapHandle, eax
            mov eax, hPALFile
            mov [ebx].PALINFO.PALFileHandle, eax
        .ENDIF
        
    .ELSEIF SigReturn == PAL_FILETYPE_PAL ; 5
        Invoke IEPALMem, PALMemMapPtr, lpszPalFilename, PALFilesize, dwOpenMode
        mov hIEPAL, eax
        .IF hIEPAL == NULL
            Invoke UnmapViewOfFile, PALMemMapPtr
            Invoke CloseHandle, PALMemMapHandle
            Invoke CloseHandle, hPALFile
            mov eax, NULL
            ret    
        .ENDIF
        .IF dwOpenMode == 0 ; write (default)
            Invoke UnmapViewOfFile, PALMemMapPtr
            Invoke CloseHandle, PALMemMapHandle
            Invoke CloseHandle, hPALFile
        .ELSE ; else readonly, so keep mapping around till we close file
            mov ebx, hIEPAL
            mov eax, PALMemMapHandle
            mov [ebx].PALINFO.PALMemMapHandle, eax
            mov eax, hPALFile
            mov [ebx].PALINFO.PALFileHandle, eax
        .ENDIF

        
    .ELSEIF SigReturn == PAL_FILETYPE_JASC ; 6
        Invoke IEPALMem, PALMemMapPtr, lpszPalFilename, PALFilesize, dwOpenMode
        mov hIEPAL, eax
        .IF hIEPAL == NULL
            Invoke UnmapViewOfFile, PALMemMapPtr
            Invoke CloseHandle, PALMemMapHandle
            Invoke CloseHandle, hPALFile
            mov eax, NULL
            ret    
        .ENDIF
        .IF dwOpenMode == 0 ; write (default)
            Invoke UnmapViewOfFile, PALMemMapPtr
            Invoke CloseHandle, PALMemMapHandle
            Invoke CloseHandle, hPALFile
        .ELSE ; else readonly, so keep mapping around till we close file
            mov ebx, hIEPAL
            mov eax, PALMemMapHandle
            mov [ebx].PALINFO.PALMemMapHandle, eax
            mov eax, hPALFile
            mov [ebx].PALINFO.PALFileHandle, eax
        .ENDIF

    .ELSEIF SigReturn == PAL_FILETYPE_BAMC ; 7 ; uncompress bam first
        Invoke PALBAMUncompress, hPALFile, PALMemMapPtr, Addr PALFilesize
        .IF eax == 0
            Invoke UnmapViewOfFile, PALMemMapPtr
            Invoke CloseHandle, PALMemMapHandle
            Invoke CloseHandle, hPALFile        
            mov eax, NULL
            ret
        .ENDIF
        mov pPAL, eax ; save uncompressed location to this var
        Invoke UnmapViewOfFile, PALMemMapPtr
        Invoke CloseHandle, PALMemMapHandle
        Invoke CloseHandle, hPALFile        
        Invoke IEPALMem, pPAL, lpszPalFilename, PALFilesize, dwOpenMode
        mov hIEPAL, eax
        .IF hIEPAL == NULL
            Invoke GlobalFree, pPAL
            mov eax, NULL
            ret
        .ENDIF
        
    .ENDIF
    ; save original version to handle for later use so we know if orignal file version
    mov ebx, hIEPAL
    mov eax, SigReturn
    mov [ebx].PALINFO.PALVersion, eax

    IFDEF DEBUGLOG
    DebugLogMsg "IEPALOpen::Finished", DEBUGLOG_INFO, 2
    ENDIF
    
    mov eax, hIEPAL

    IFDEF DEBUG32
        PrintDec hIEPAL
    ENDIF
    ret
IEPALOpen ENDP


;----------------------------------------------------------------------------
; IEPALClose - Close PAL File
;----------------------------------------------------------------------------
IEPALClose PROC PUBLIC USES EAX EBX hIEPAL:DWORD

    IFDEF DEBUGLOG
    DebugLogMsg "IEPALClose", DEBUGLOG_FUNCTION, 2
    ENDIF
    
    mov ebx, hIEPAL
    mov eax, [ebx].PALINFO.BAMPalettePtr
    .IF eax != NULL
        Invoke GlobalFree, eax
        IFDEF DEBUGLOG
        DebugLogMsg "IEPALClose::GlobalFree-BAMPalettePtr::Success", DEBUGLOG_INFO, 3
        ENDIF              
    .ENDIF
    
    mov ebx, hIEPAL
    mov eax, [ebx].PALINFO.PALPalettePtr
    .IF eax != NULL
        Invoke GlobalFree, eax
        IFDEF DEBUGLOG
        DebugLogMsg "IEPALClose::GlobalFree-PALPalettePtr::Success", DEBUGLOG_INFO, 3
        ENDIF
    .ENDIF

    mov ebx, hIEPAL
    mov eax, [ebx].PALINFO.PALVersion
    ;PrintDec eax
    .IF eax == PAL_FILETYPE_BAMC ; BAMC in read or write mode uncompresed bam in memory needs to be cleared
        mov ebx, hIEPAL
        mov eax, [ebx].PALINFO.PALMemMapPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
            IFDEF DEBUGLOG
            DebugLogMsg "IEPALClose::GlobalFree-BAMC-PALMemMapPtr::Success", DEBUGLOG_INFO, 3
            ENDIF              
        .ENDIF
    
    .ELSE ; opened in readonly so unmap file and close handles, otherwise free mem
     
        mov ebx, hIEPAL
        mov eax, [ebx].PALINFO.PALOpenMode
        .IF eax == 1 ; Read Only
            ;PrintText 'Read Only'
            mov ebx, hIEPAL
            mov eax, [ebx].PALINFO.PALMemMapPtr
            .IF eax != NULL
                Invoke UnmapViewOfFile, eax
                IFDEF DEBUGLOG
                DebugLogMsg "IEPALClose::UnmapViewOfFile-PALMemMapPtr::Success", DEBUGLOG_INFO, 3
                ENDIF                 
            .ENDIF
            
            mov ebx, hIEPAL
            mov eax, [ebx].PALINFO.PALMemMapHandle
            .IF eax != NULL
                Invoke CloseHandle, eax
                IFDEF DEBUGLOG
                DebugLogMsg "IEPALClose::CloseHandle-PALMemMapHandle::Success", DEBUGLOG_INFO, 3
                ENDIF                  
            .ENDIF

            mov ebx, hIEPAL
            mov eax, [ebx].PALINFO.PALFileHandle
            .IF eax != NULL
                Invoke CloseHandle, eax
                IFDEF DEBUGLOG
                DebugLogMsg "IEPALClose::CloseHandle-PALFileHandle::Success", DEBUGLOG_INFO, 3
                ENDIF                     
            .ENDIF
       
        .ELSE ; free mem if write mode
            ;PrintText 'Read/Write'
            mov ebx, hIEPAL
            mov eax, [ebx].PALINFO.PALMemMapPtr
            .IF eax != NULL
                Invoke GlobalFree, eax
                IFDEF DEBUGLOG
                DebugLogMsg "IEPALClose::GlobalFree-PAL-PALMemMapPtr::Success", DEBUGLOG_INFO, 3
                ENDIF                   
            .ENDIF
        .ENDIF
    .ENDIF
    
    mov eax, hIEPAL
    .IF eax != NULL
        Invoke GlobalFree, eax
        IFDEF DEBUGLOG
        DebugLogMsg "IEPALClose::GlobalFree-hIEPAL::Success", DEBUGLOG_INFO, 3
        ENDIF          
    .ENDIF

    IFDEF DEBUGLOG
    DebugLogMsg "IEPALClose::Finished", DEBUGLOG_INFO, 2
    ENDIF

    ;mov eax, 0
    ret
IEPALClose ENDP




;-------------------------------------------------------------------------------------
; IEPALMem - Returns handle in eax of opened pal file that is already loaded into memory. NULL if could not alloc enough mem
; depending on file type have to handle each seperately, sub functions for each type?
;-------------------------------------------------------------------------------------
IEPALMem PROC PUBLIC USES EBX ECX EDX pPALInMemory:DWORD, lpszPalFilename:DWORD, dwPalFilesize:DWORD, dwOpenMode:DWORD
    LOCAL hIEPAL:DWORD
    LOCAL PALMemMapPtr:DWORD
    LOCAL dwPalVersion:DWORD
    LOCAL OffsetPalette:DWORD
    LOCAL PALPalettePtr:DWORD
    LOCAL BAMPalettePtr:DWORD
    
    mov eax, pPALInMemory
    mov PALMemMapPtr, eax
    
    ;----------------------------------
    ; Alloc mem for our IEPAL Handle
    ;----------------------------------
    IFDEF DEBUGLOG
    DebugLogMsg "IEPALMem::GlobalAlloc-hIEPAL", DEBUGLOG_INFO, 3
    ENDIF         
    Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, SIZEOF PALINFO
    .IF eax == NULL
        ret
    .ENDIF
    mov hIEPAL, eax
    
    mov ebx, hIEPAL
    mov eax, dwOpenMode
    mov [ebx].PALINFO.PALOpenMode, eax
    mov eax, PALMemMapPtr
    mov [ebx].PALINFO.PALMemMapPtr, eax
    
    lea eax, [ebx].PALINFO.PALFilename
    Invoke szCopy, lpszPalFilename, eax
    
    mov ebx, hIEPAL
    mov eax, dwPalFilesize
    mov [ebx].PALINFO.PALFilesize, eax

    Invoke PALSignature, PALMemMapPtr, lpszPalFilename, dwPalFilesize ;hBIFFile
    mov dwPalVersion, eax

    ;----------------------------------
    ; PAL Header (File contents for palette type)
    ;----------------------------------
    mov eax, dwPalVersion
    .IF eax == 0
        mov eax, hIEPAL
        .IF eax != NULL
            Invoke GlobalFree, eax
            mov eax, NULL
            ret
        .ENDIF
        
    .ELSEIF eax == PAL_FILETYPE_BAM 
        
    .ELSEIF eax == PAL_FILETYPE_BAMC ; already uncompressed BAMC so same as BAM at this point
        mov ebx, hIEPAL
        mov eax, PALMemMapPtr
        mov [ebx].PALINFO.PALHeaderPtr, eax
        mov ebx, hIEPAL
        mov eax, dwPalFilesize
        mov [ebx].PALINFO.PALHeaderSize, eax

    .ELSE
        .IF dwOpenMode == 0
            IFDEF DEBUGLOG
            DebugLogMsg "IEPALMem::GlobalAlloc-PALHeaderPtr", DEBUGLOG_INFO, 3
            ENDIF
            Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, dwPalFilesize
            .IF eax == NULL
                Invoke GlobalFree, hIEPAL
                mov eax, NULL
                ret
            .ENDIF    
            mov ebx, hIEPAL
            mov [ebx].PALINFO.PALHeaderPtr, eax
            mov ebx, PALMemMapPtr
            Invoke RtlMoveMemory, eax, ebx, dwPalFilesize
        .ELSE
            mov ebx, hIEPAL
            mov eax, PALMemMapPtr
            mov [ebx].PALINFO.PALHeaderPtr, eax
        .ENDIF
        mov ebx, hIEPAL
        mov eax, dwPalFilesize
        mov [ebx].PALINFO.PALHeaderSize, eax
                
    .ENDIF
    
    ;----------------------------------
    ; Palette ColorRef Version
    ;----------------------------------      
    IFDEF DEBUGLOG
    DebugLogMsg "IEPALMem::Palette-ColorRef", DEBUGLOG_INFO, 3
    ENDIF  

    IFDEF DEBUGLOG
    DebugLogMsg "IEPALMem::GlobalAlloc-PALPalettePtr", DEBUGLOG_INFO, 3
    ENDIF
    Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, 1024d ; alloc space for palette
    .IF eax == NULL
        mov ebx, hIEPAL
        mov eax, [ebx].PALINFO.PALHeaderPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
        Invoke GlobalFree, hIEPAL
        mov eax, NULL    
        ret
    .ENDIF
    mov ebx, hIEPAL
    mov [ebx].PALINFO.PALPalettePtr, eax
    mov PALPalettePtr, eax

    ;----------------------------------
    ; BAM Palette RGBQUAD Version
    ;----------------------------------      
    IFDEF DEBUGLOG
    DebugLogMsg "IEPALMem::Palette-RGBQUAD", DEBUGLOG_INFO, 3
    ENDIF  

    IFDEF DEBUGLOG
    DebugLogMsg "IEPALMem::GlobalAlloc-BAMPalettePtr", DEBUGLOG_INFO, 3
    ENDIF
    Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, 1024d ; alloc space for palette
    .IF eax == NULL
        mov ebx, hIEPAL
        mov eax, [ebx].PALINFO.PALPalettePtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF    
        mov ebx, hIEPAL
        mov eax, [ebx].PALINFO.PALHeaderPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
        Invoke GlobalFree, hIEPAL
        mov eax, NULL    
        ret
    .ENDIF
    mov ebx, hIEPAL
    mov [ebx].PALINFO.BAMPalettePtr, eax
    mov BAMPalettePtr, eax

    mov ebx, hIEPAL
    mov eax, 1024d
    mov [ebx].PALINFO.PALPaletteSize, eax
    mov [ebx].PALINFO.BAMPaletteSize, eax


    ;----------------------------------
    ; Read in file data to convert to Palette RGBQUAD Version
    ;----------------------------------      
    mov eax, dwPalVersion
    .IF eax == PAL_FILETYPE_MSPAL
        mov OffsetPalette, 20d ; to verify this
        
    .ELSEIF eax == PAL_FILETYPE_ACT
        
    .ELSEIF eax == PAL_FILETYPE_BAM || eax == PAL_FILETYPE_BAMC 
        mov ebx, PALMemMapPtr
        add ebx, 16d ; BAMV1_HEADER.PaletteOffset
        mov eax, [ebx]
        mov OffsetPalette, eax
        mov eax, BAMPalettePtr
        mov ebx, PALMemMapPtr
        add ebx, OffsetPalette
        Invoke RtlMoveMemory, eax, ebx, 1024d
        
    .ELSEIF eax == PAL_FILETYPE_BMP
        mov eax, BAMPalettePtr
        mov ebx, PALMemMapPtr
        add ebx, BITMAPFILEHEADER
        add ebx, BITMAPINFOHEADER
        Invoke RtlMoveMemory, eax, ebx, 1024d
        
    .ELSEIF eax == PAL_FILETYPE_PAL
        mov eax, BAMPalettePtr
        mov ebx, PALMemMapPtr
        Invoke RtlMoveMemory, eax, ebx, 1024d
        
    .ELSEIF eax == PAL_FILETYPE_JASC
        mov OffsetPalette, 14d ; JASC-PAL,0A,0D,256,0A,0D
        
    .ENDIF

          
    ret
IEPALMem ENDP


;-----------------------------------------------------------------------------------------
; IEPALRGBtoBGR - Converts RGBQUAD to BGR (ColorRef), returns in eax
;-----------------------------------------------------------------------------------------
IEPALRGBtoBGR PROC PUBLIC USES EDX dwRGB:DWORD 
;How to convert 00RRGGBBh to 00BBGGRRh without bswap
;http://masm32.com/board/index.php?topic=338.msg2086#msg2086
; 0RGB
; 0BGR
    mov eax, dwRGB
    movzx edx, al   ; 000B
    shl edx, 2*8    ; 0B00
    shr eax, 8  ; eax=00RG
    mov dh, al  ; 0BG
    mov dl, ah  ; 0BGR

    ret
IEPALRGBtoBGR ENDP


;-----------------------------------------------------------------------------------------
; IEPALBGRtoRGB - Converts RGB ColorRef to RGBQUAD, returns in eax
;-----------------------------------------------------------------------------------------
IEPALBGRtoRGB PROC PUBLIC USES EDX dwBGR:DWORD 
; 0BGR
; 0RGB
    mov eax, dwBGR
    movzx edx, al   ; 000R
    shl edx, 2*8    ; 0R00
    shr eax, 8  ; eax=00RG
    mov dh, al  ; 0RG
    mov dl, ah  ; 0RGB

    ret
IEPALBGRtoRGB ENDP


;-------------------------------------------------------------------------------------
; 0 = Invalid, 1 = MSPAL, 2 = ACT, 3 = BAM, 4 = BMP, 5 = RAW .BIN or .PAL, 6 = JASC PAL, 7 = BAMC
;-------------------------------------------------------------------------------------
IEPALVersion PROC PUBLIC USES EBX hIEPAL:DWORD
    
    .IF hIEPAL == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEPAL
    mov eax, [ebx].PALINFO.PALVersion
    ret

IEPALVersion endp


;**************************************************************************
; Checks the PAL signatures to determine if they are valid. Returns file type in eax, 0 if not valid
;**************************************************************************
PALSignature PROC pPAL:DWORD, lpszPalFilename:DWORD, PALFilesize:DWORD
    LOCAL szFileExt[32]:BYTE
    LOCAL dwLenExt:DWORD
    
    .IF PALFilesize < 768d ; not a palette format
        mov eax, 0
        ret
    .ENDIF
    
    Invoke PALJustExt, lpszPalFilename, Addr szFileExt
    .IF eax == FALSE
        mov eax, PALFilesize
        .IF eax == 768d || eax == 772d
            mov eax, PAL_FILETYPE_ACT
            ret
        .ELSEIF eax == 1024d
            mov eax, PAL_FILETYPE_PAL
            ret
        .ELSE
            mov eax, 0
            ret
        .ENDIF
    .ENDIF
    
    
    Invoke szLen, Addr szFileExt
    mov dwLenExt, eax
    
    ; check for file formats that have fixed file size
    
    mov eax, PALFilesize
    .IF eax == 768d || eax == 772d
        Invoke szCmpi, Addr szFileExt, Addr ACTExt, dwLenExt
        .IF eax != 0 ; no match
            mov eax, 0
            ret
        .ELSE
            mov eax, PAL_FILETYPE_ACT
            ret
        .ENDIF
    
    .ELSEIF eax == 1024d
        Invoke szCmpi, Addr szFileExt, Addr BINExt, dwLenExt
        .IF eax != 0 ; no match
            Invoke szCmpi, Addr szFileExt, Addr PALExt, dwLenExt
            .IF eax != 0 ; no match
                mov eax, 0
                ret
            .ELSE
                mov eax, PAL_FILETYPE_PAL
                ret
            .ENDIF
        .ELSE
            mov eax, PAL_FILETYPE_PAL
            ret
        .ENDIF
    .ENDIF
    
   ; Invoke RtlMoveMemory, Addr XHeader, pPAL, 12d
    
    ; check other file formats based on ext and header contents
    Invoke szCmpi, Addr szFileExt, Addr BMPExt, dwLenExt
    .IF eax == 0 ; match, so verify header, 8bpp, BI_RGB
        mov ebx, pPAL
        movzx eax, word ptr [ebx]
        .IF ax == 'MB' ; BMP?
            add ebx, SIZEOF BITMAPFILEHEADER
            movzx eax, word ptr [ebx].BITMAPINFOHEADER.biBitCount
            .IF eax == 8d
                mov eax, [ebx].BITMAPINFOHEADER.biCompression
                .IF eax == BI_RGB
                    mov eax, PAL_FILETYPE_BMP
                    ret
                .ENDIF
            .ENDIF
        .ENDIF
    .ENDIF
    
    Invoke szCmpi, Addr szFileExt, Addr PALExt, dwLenExt
    .IF eax == 0 ; match, so verify header, RIFF
        mov ebx, pPAL
        mov eax, [ebx]
        .IF eax == 'FFIR' ; RIFF PAL ?
            add ebx, 8d
            mov eax, [ebx]
            .IF eax == ' LAP' 
                mov eax, PAL_FILETYPE_MSPAL
                ret
            .ENDIF
        .ENDIF
    .ENDIF
    
    Invoke szCmpi, Addr szFileExt, Addr BAMExt, dwLenExt
    .IF eax == 0 ; match, so verify header, RIFF
        mov ebx, pPAL
        mov eax, [ebx]
        .IF eax == ' MAB' ; BAM?
            add ebx, 4d
            mov eax, [ebx]
            .IF eax == '  1V'
                mov eax, PAL_FILETYPE_BAM
                ret
            .ENDIF    
        .ELSEIF eax == 'CMAB' ; BAMC
            mov eax, PAL_FILETYPE_BAMC
            ret
        .ENDIF
    .ENDIF
    
    ; check header contents for all other files to see if they are known
    mov ebx, pPAL
    mov eax, [ebx]
    .IF ax == 'MB' ; BMP?
        add ebx, SIZEOF BITMAPFILEHEADER
        movzx eax, word ptr [ebx].BITMAPINFOHEADER.biBitCount
        .IF eax == 8d
            mov eax, [ebx].BITMAPINFOHEADER.biCompression
            .IF eax == BI_RGB
                mov eax, PAL_FILETYPE_BMP
                ret
            .ENDIF
        .ENDIF
    .ENDIF

    mov ebx, pPAL
    mov eax, [ebx]    
    .IF eax == 'FFIR' ; RIFF PAL ?
        add ebx, 8d
        mov eax, [ebx]
        .IF eax == ' LAP' 
            mov eax, PAL_FILETYPE_MSPAL
            ret
        .ENDIF  
    .ENDIF

    mov ebx, pPAL
    mov eax, [ebx]    
    .IF eax == ' MAB' ; BAM?
        add ebx, 4d
        mov eax, [ebx]
        .IF eax == '  1V'
            mov eax, PAL_FILETYPE_BAM
            ret
        .ENDIF        
    .ENDIF
    
    mov ebx, pPAL
    mov eax, [ebx]  
    .IF eax == 'CMAB' ; BAMC
        mov eax, PAL_FILETYPE_BAMC
        ret
    .ENDIF

    mov ebx, pPAL
    mov eax, [ebx]    
    .IF eax == 'CSAJ' ; JASC PAL?
        add ebx, 4d
        mov eax, [ebx]
        .IF eax == '-LAP' ; PAL-
            mov eax, PAL_FILETYPE_JASC
            ret
        .ENDIF    
    .ENDIF
    
    mov eax, 0
    ret

PALSignature endp


;**************************************************************************
; Strip path name to just filename Without extention
;**************************************************************************
PALJustFname PROC szFilePathName:DWORD, szFileName:DWORD
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
PALJustFname ENDP


;===============================================================================
; Procedure / Function: JustExt
;===============================================================================
PALJustExt PROC USES ESI EDI szFilePathName:DWORD, szFileExtention:DWORD
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
        .IF al == '.'
            inc esi
            .BREAK
        .ENDIF
        dec esi
        dec nPosition
        mov eax, nPosition
        .IF eax == 0 ; not found .
            mov eax, FALSE
            ret
        .ENDIF
    .ENDW
    mov edi, szFileExtention
    mov eax, nPosition
    .WHILE eax != LenFilePathName
        movzx eax, byte ptr [esi]
        mov byte ptr [edi], al
        inc edi
        inc esi
        inc nPosition
        mov eax, nPosition
    .ENDW
    mov byte ptr [edi], 0h ; null out filename
    mov eax, TRUE
    ret
PALJustExt  ENDP


;-----------------------------------------------------------------------------------------
; Uncompresses BAMC file to an area of memory that we allocate for the exact size of data
;-----------------------------------------------------------------------------------------
PALBAMUncompress PROC PRIVATE USES EBX hBAMFile:DWORD, pBAM:DWORD, dwSize:DWORD
    LOCAL dest:DWORD ; Heap
    ;LOCAL destLen:DWORD ; BAMC_UncompressedSize
    LOCAL src:DWORD ; BAMMemMapPtr
    ;LOCAL srcLen:DWORD ; BAMC_CompressedSize  
    LOCAL BAMU_Size:DWORD
    LOCAL BytesRead:DWORD
    LOCAL BAMFilesize:DWORD
    LOCAL BAMC_UncompressedSize:DWORD
    LOCAL BAMC_CompressedSize:DWORD
    
    Invoke GetFileSize, hBAMFile, NULL
    mov BAMFilesize, eax

    ;Invoke SetFilePointer, hBAM, 08h, NULL, FILE_BEGIN
    ;Invoke ReadFile, hBAM, Addr BAMC_UncompressedSize, 4, Addr BytesRead, NULL
    mov ebx, pBAM
    mov eax, [ebx].BAMC_HEADER.UncompressedLength
    mov BAMC_UncompressedSize, eax
    mov eax, BAMFilesize
    sub eax, 0Ch ; take away the BAMC header 12 bytes = 0xC
    mov BAMC_CompressedSize, eax ; set correct compressed size = length of file minus BAMC header length
    
    ;mov eax, BAMC_UncompressedSize
    ;add eax, 0Ch ; add BAMU header size
    ;mov BAMU_Size, eax
    
    ;PrintText 'BIFUncompress::ZLIB->Uncompress'
    
    Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, BAMC_UncompressedSize
    .IF eax != NULL
        ;mov hMemDest, eax
        ;Invoke GlobalLock, hMemDest
        ;.IF eax != NULL
        ;    mov mDestBAM, eax ; save handle to memory area
            ;add eax, 0Ch ; add BAMU Header size to memory offset so we start uncompressing at right place
        mov dest, eax
        ;mov dest, eax
        ;mov eax, BAMC_UncompressedSize
        ; Copy BAMU header to correct location in memory
        ;Invoke CopyMemory, mDestBAM, Addr BAMUHeader, 08h
        ;mov destlen, eax
        mov eax, pBAM ;BAMMemMapPtr
        add eax, 0Ch ; add BAMC Header to Memory map to start at correct offset for uncompressing
        mov src, eax
        ; Invoke uncompress, dest, Addr destLen, src, srcLen
        Invoke uncompress, dest, Addr BAMC_UncompressedSize, src, BAMC_CompressedSize
        .IF eax == Z_OK ; ok
        
            mov eax, BAMC_UncompressedSize
            mov ebx, dwSize
            mov [ebx], eax
        
            mov eax, dest
            ;PrintText 'BIFUncompress::ZLIB->Uncompress::Success'
            ;mov eax, TRUE
            ret
        .ENDIF
    .ENDIF                  
    mov eax, 0        
    ret

PALBAMUncompress endp

;An ACT file is in binary form and is at least 768 bytes long. If it is only 768 bytes, then it specifies exactly 256 colors. 
;If it is longer (probably 772 bytes), then byte 769 specifies how many colors there are. Panoply ignores bytes 770-772 if they are present. 
;The first 768 bytes of an ACT file are arranged as 256 triplets., each of which specifies the RGB value of a color. 
;Bytes 1-3 define the first color, with byte 1 specifying its red value, byte 2 the green value and byte 3 the blue value. 
;Bytes 4-6 define the second color, and so on until the correct number of colors is reached. Any remaining bytes are ignored.

;.act file, internally structured as a fixed-size 772-byte table with 256 3-byte RGB triplets, followed by a two-byte
;unsigned int with the number of defined colors (may be less than 256) and a finaly two-byte unsigned int with the optional index of a transparent color
;in the lookup table. If the final byte is 0xFFFF, there is no transparency.

;-----------------------------------------------------------------------------------------
; Converts Adobe ACT file format palette to RGBQUAD format into our memory alloc'd for it
; returns true if succesful or -1 otherwise
;-----------------------------------------------------------------------------------------
PALConvertACTtoBAMPalette PROC PRIVATE USES EBX EDX hIEPAL:DWORD
    LOCAL BAMPalettePtr:DWORD
    LOCAL PALMemMapPtr:DWORD
    LOCAL dwActPosition:DWORD
    LOCAL clrRed:DWORD
    LOCAL clrGreen:DWORD
    LOCAL clrBlue:DWORD
    LOCAL clrAlpha:DWORD
    LOCAL dwARGB:DWORD
    LOCAL PaletteIndex:DWORD
    
    .IF hIEPAL == NULL
        mov eax, -1
        ret
    .ENDIF
    
    mov ebx, hIEPAL
    mov eax, [ebx].PALINFO.BAMPalettePtr
    .IF eax == 0
        mov eax, -1
        ret
    .ENDIF
    mov BAMPalettePtr, eax
    
    mov ebx, hIEPAL
    mov eax, [ebx].PALINFO.PALMemMapPtr
    mov PALMemMapPtr, eax
    
    mov edx, BAMPalettePtr
    mov ebx, PALMemMapPtr
    mov clrAlpha, 0
    mov PaletteIndex, 0
    mov dwActPosition, 0
    mov eax, 0
    .WHILE eax < 768d ; max size of ACT file
        mov ebx, PALMemMapPtr
        add ebx, dwActPosition
        movzx eax, byte ptr [ebx]
        mov clrRed, eax
        inc ebx
        movzx eax, byte ptr [ebx]
        mov clrGreen, eax
        inc ebx
        movzx eax, byte ptr [ebx]
        mov clrBlue, eax
    
        ; convert seperate bytes to dword value of ARGB
        xor eax, eax
        xor ebx, ebx
        mov eax, clrAlpha
        mov ebx, clrBlue
        shl eax, 8d
        mov al, bl
        shl eax, 16d ; alpha and red in upper dword
        mov ebx, clrGreen
        mov ah, bl
        mov ebx, clrRed
        mov al, bl
        mov dwARGB, eax
        
        ; save dword to palette
        add edx, PaletteIndex
        mov eax, dwARGB
        mov [edx], eax
        
        add PaletteIndex, 4 ; adjust for next dword pointer to palette entry
        add dwActPosition, 3
        mov eax, dwActPosition
    .ENDW
    
    mov eax, TRUE
    ret

PALConvertACTtoBAMPalette endp



;-----------------------------------------------------------------------------------------
; Converts JASC Pal file format palette to RGBQUAD format
; returns true if succesful or -1 otherwise
;-----------------------------------------------------------------------------------------
PALConvertJASCToBAMPalette PROC PRIVATE USES EBX EDX hIEPAL:DWORD
    LOCAL BAMPalettePtr:DWORD
    LOCAL PALMemMapPtr:DWORD
    LOCAL dwJascPosition:DWORD
    LOCAL clrRed:DWORD
    LOCAL clrGreen:DWORD
    LOCAL clrBlue:DWORD
    LOCAL clrAlpha:DWORD
    LOCAL dwARGB:DWORD
    LOCAL PaletteIndex:DWORD
    LOCAL dwFilesize:DWORD
    LOCAL szColorVar1[12]:BYTE
    LOCAL szColorVar2[12]:BYTE
    LOCAL szColorVar3[12]:BYTE
    LOCAL dwClrVar:DWORD
    LOCAL dwColorCountVar:DWORD
    LOCAL szColorCountVar[12]:BYTE
    
    ; JASC-PAL, 0A,0D
    ; No colors, usually 256 0A,0D - read from start of line to CR LF
    ; loop till end of filesize
    ; read until space or CRLF into szVar3
    ; read until space or CRLF into szVar2
    ; read until space or CRLF into szVar1
    ; count vars read
    ; if reach CRLF, and varcount =3, convert szVar3 to blue atol, svVar2 to green atol, szVar3 to red
    ; if reach CRLF, and varcount =2, convert szVar3 to green atol, szVar2 to red atol
    ; if reach CRLF, and varcount =1, convert szVar3 to red atol
    .IF hIEPAL == NULL
        mov eax, -1
        ret
    .ENDIF
    
    mov ebx, hIEPAL
    mov eax, [ebx].PALINFO.BAMPalettePtr
    .IF eax == 0
        mov eax, -1
        ret
    .ENDIF
    mov BAMPalettePtr, eax
    
    mov ebx, hIEPAL
    mov eax, [ebx].PALINFO.PALMemMapPtr
    mov PALMemMapPtr, eax
    mov eax, [ebx].PALINFO.PALFilesize
    mov dwFilesize, eax
    
    mov edx, BAMPalettePtr
    mov ebx, PALMemMapPtr
    mov dwColorCountVar, 0
    mov clrAlpha, 0
    mov PaletteIndex, 0
    mov dwJascPosition, 0
    
    mov ebx, PALMemMapPtr
    mov eax, [ebx]    
    .IF eax == 'CSAJ' ; JASC PAL?
        add ebx, 4d
        mov eax, [ebx]
        .IF eax == '-LAP' ; PAL-
            add ebx, 4d
            movzx eax, word ptr [ebx]
            .IF eax == dwCRLF
                mov dwJascPosition, 10d ; JASC-PAL0D0A 
                movzx eax, byte ptr [ebx]
                lea edx, szColorCountVar
                .WHILE al != 0Dh || al != 0Ah
                    mov byte ptr [edx], al
                    inc edx
                    inc ebx
                    inc dwJascPosition
                    movzx eax, byte ptr [ebx]
                .ENDW
                mov byte ptr [edx], 0h
                Invoke atol, Addr szColorCountVar
                mov dwColorCountVar, eax
            .ELSE
                mov eax, -1
                ret
            .ENDIF
        .ELSE
            mov eax, -1
            ret
        .ENDIF
    .ELSE
        mov eax, -1
        ret
    .ENDIF
    
    lea edx, szColorVar3
    mov dwClrVar, 1
    mov ebx, PALMemMapPtr
    add ebx, dwJascPosition ; update ebx to point to start of color array
    
    mov eax, dwJascPosition
    .WHILE eax < dwFilesize
        movzx eax, byte ptr [ebx] ; get byte from ebx
        
        .IF al == 0Dh
            mov byte ptr [edx], 0h ; null out szColorVarX

            ; build ABGR var, update palette index and update palette
            .IF dwClrVar == 1
                ; we have 1 var for red (var3)
                Invoke atol, Addr szColorVar3
                mov clrRed, eax
                mov clrGreen, 0
                mov clrBlue, 0
                
            .ELSEIF dwClrVar == 2
                ; we have 2 vars for green (var3) and red (var2)
                Invoke atol, Addr szColorVar2
                mov clrRed, eax
                Invoke atol, Addr szColorVar3
                mov clrGreen, eax
                mov clrBlue, 0
                                
            .ELSEIF dwClrVar == 3
                ; we have 3 vars for blue (var3) and green (var2) and red (var1). 
                Invoke atol, Addr szColorVar1
                mov clrRed, eax
                Invoke atol, Addr szColorVar2
                mov clrGreen, eax
                Invoke atol, Addr szColorVar3
                mov clrBlue, eax
                
            .ENDIF

            ; convert seperate bytes to dword value of ARGB
            xor eax, eax
            xor ebx, ebx
            mov eax, clrAlpha
            mov ebx, clrBlue
            shl eax, 8d
            mov al, bl
            shl eax, 16d ; alpha and red in upper dword
            mov ebx, clrGreen
            mov ah, bl
            mov ebx, clrRed
            mov al, bl
            mov dwARGB, eax

            ; save dword to palette
            add edx, PaletteIndex
            mov eax, dwARGB
            mov [edx], eax
            add PaletteIndex, 4 ; adjust for next dword pointer to palette entry
            
            ; reset for next RGB vars 
            lea edx, szColorVar3
            mov dwClrVar, 1            
            
        .ELSEIF al == 0Ah

        .ELSEIF al == 20h ; space
            mov byte ptr [edx], 0h ; null out szColorVarX
            .IF dwClrVar == 1
                lea edx, szColorVar2
                inc dwClrVar
            .ELSEIF dwClrVar == 2
                lea edx, szColorVar1
                inc dwClrVar
            .ELSEIF dwClrVar == 3
                lea edx, szColorVar3
                mov dwClrVar, 1
            .ENDIF
            
        .ELSE
            mov byte ptr [edx], al ; copy byte to szColorVarX
            inc edx ; advance position of szColorVarX to next byte
         .ENDIF
        
        inc ebx
        inc dwJascPosition
        mov eax, dwJascPosition
    .ENDW
    
    ret

PALConvertJASCToBAMPalette endp


;-----------------------------------------------------------------------------------------
; Converts BAMPalette RGBQUAD to PALPalette ColorRef format
; returns true if succesful or -1 otherwise
;-----------------------------------------------------------------------------------------
PALConvertRGBPalToBGRPal PROC PRIVATE USES EBX EDX hIEPAL:DWORD
    
    
    ret

PALConvertRGBPalToBGRPal endp






END
