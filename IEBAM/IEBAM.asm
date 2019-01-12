;==============================================================================
;
; IEBAM
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
include gdi32.inc
include masm32.inc
include zlibstat.inc

includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib
includelib masm32.lib
includelib zlibstat.lib

include IEBAM.inc


;DEBUG32 EQU 1
;IFDEF DEBUG32
;    PRESERVEXMMREGS equ 1
;    includelib M:\Masm32\lib\Debug32.lib
;    DBG32LIB equ 1
;    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
;    include M:\Masm32\include\debug32.inc
;ENDIF


BAMSignature            PROTO :DWORD
BAMUncompress           PROTO :DWORD, :DWORD, :DWORD
BAMJustFname            PROTO :DWORD, :DWORD
BAMCalcDwordAligned     PROTO :DWORD

BAMV1Mem                PROTO :DWORD, :DWORD, :DWORD, :DWORD
BAMV2Mem                PROTO :DWORD, :DWORD, :DWORD, :DWORD



RGBCOLOR macro r:REQ,g:REQ,b:REQ    
exitm <( ( ( ( r )  or  ( ( ( g ) )  shl  8 ) )  or  ( ( ( b ) )  shl  16 ) ) ) >
ENDM



BAMINFO                     STRUCT
    BAMOpenMode             DD 0
    BAMFilename             DB MAX_PATH DUP (0)
    BAMFilesize             DD 0
    BAMVersion              DD 0
    BAMCompressed           DD 0
    BAMHeaderPtr            DD 0
    BAMHeaderSize           DD 0
    BAMTotalFrames          DD 0
    BAMTotalCycles          DD 0
    BAMTotalBlocks          DD 0 ; for BAM V2
    BAMFrameEntriesPtr      DD 0
    BAMFrameEntriesSize     DD 0
    BAMCycleEntriesPtr      DD 0
    BAMCycleEntriesSize     DD 0
    BAMBlockEntriesPtr      DD 0 ; for BAM V2
    BAMBlockEntriesSize     DD 0 ; for BAM V2
    BAMPalettePtr           DD 0 ; no interal palette for BAM V2
    BAMPaletteSize          DD 1024d
    BAMFrameLookupPtr       DD 0
    BAMFrameLookupSize      DD 0
    BAMFrameDataEntriesPtr  DD 0 ; custom array of FRAMEDATA
    BAMFrameDataEntriesSize DD 0
    BAMMemMapPtr            DD 0
    BAMMemMapHandle         DD 0
    BAMFileHandle           DD 0    
BAMINFO                     ENDS


.DATA
BAMV1Header             db "BAM V1  ",0
BAMV2Header             db "BAM V2  ",0
BAMCHeader              db "BAMCV1  ",0
BAMXHeader              db 12 dup (0)
;BAMBMPInfo              BITMAPINFO <{40d, 0, 0, 1, 8, BI_RGB, 0, 0, 0, 0, 0 }, {0}>
BAMBMPInfo              BITMAPINFOHEADER <40d, 0, 0, 1, 8, BI_RGB, 0, 0, 0, 0, 0> ;Header
BAMBMPPalette           db 1024 dup (0) ; BITMAPFILEHEADER <'BM', 0, 0, 0, 54d>



.CODE


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; IEBAMOpen - Returns handle in eax of opened bam file. NULL if could not alloc enough mem
;-------------------------------------------------------------------------------------
IEBAMOpen PROC USES EBX lpszBamFilename:DWORD, dwOpenMode:DWORD
    LOCAL hIEBAM:DWORD
    LOCAL hBAMFile:DWORD
    LOCAL BAMFilesize:DWORD
    LOCAL SigReturn:DWORD
    LOCAL BAMMemMapHandle:DWORD
    LOCAL BAMMemMapPtr:DWORD
    LOCAL pBAM:DWORD

    .IF dwOpenMode == IEBAM_MODE_READONLY ; readonly
        Invoke CreateFile, lpszBamFilename, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ELSE
        Invoke CreateFile, lpszBamFilename, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ENDIF
 
    .IF eax == INVALID_HANDLE_VALUE
        mov eax, FALSE
        ret
    .ENDIF
    mov hBAMFile, eax

    Invoke GetFileSize, hBAMFile, NULL
    mov BAMFilesize, eax

    ;---------------------------------------------------                
    ; File Mapping: Create file mapping for main .bam
    ;---------------------------------------------------
    .IF dwOpenMode == IEBAM_MODE_READONLY ; readonly
        Invoke CreateFileMapping, hBAMFile, NULL, PAGE_READONLY, 0, 0, NULL ; Create memory mapped file
    .ELSE
        Invoke CreateFileMapping, hBAMFile, NULL, PAGE_READWRITE, 0, 0, NULL ; Create memory mapped file
    .ENDIF   
    .IF eax == NULL
        mov eax, FALSE
        ret
    .ENDIF
    mov BAMMemMapHandle, eax
    
    .IF dwOpenMode == IEBAM_MODE_READONLY ; readonly
        Invoke MapViewOfFileEx, BAMMemMapHandle, FILE_MAP_READ, 0, 0, 0, NULL
    .ELSE
        Invoke MapViewOfFileEx, BAMMemMapHandle, FILE_MAP_ALL_ACCESS, 0, 0, 0, NULL
    .ENDIF
    .IF eax == NULL
        mov eax, FALSE
        ret
    .ENDIF
    mov BAMMemMapPtr, eax

    Invoke BAMSignature, BAMMemMapPtr
    mov SigReturn, eax
    .IF SigReturn == BAM_VERSION_INVALID ; not a valid bam file
        Invoke UnmapViewOfFile, BAMMemMapPtr
        Invoke CloseHandle, BAMMemMapHandle
        Invoke CloseHandle, hBAMFile
        mov eax, NULL
        ret    
    
    .ELSEIF SigReturn == BAM_VERSION_BAM_V10 ; BAM
        Invoke IEBAMMem, BAMMemMapPtr, lpszBamFilename, BAMFilesize, dwOpenMode
        mov hIEBAM, eax
        .IF hIEBAM == NULL
            Invoke UnmapViewOfFile, BAMMemMapPtr
            Invoke CloseHandle, BAMMemMapHandle
            Invoke CloseHandle, hBAMFile
            mov eax, NULL
            ret    
        .ENDIF
        .IF dwOpenMode == IEBAM_MODE_WRITE ; write (default)
            Invoke UnmapViewOfFile, BAMMemMapPtr
            Invoke CloseHandle, BAMMemMapHandle
            Invoke CloseHandle, hBAMFile
        .ELSE ; else readonly, so keep mapping around till we close file
            mov ebx, hIEBAM
            mov eax, BAMMemMapHandle
            mov [ebx].BAMINFO.BAMMemMapHandle, eax
            mov eax, hBAMFile
            mov [ebx].BAMINFO.BAMFileHandle, eax
        .ENDIF

    .ELSEIF SigReturn == BAM_VERSION_BAM_V20 ; BAMV2 - return false for the mo
      Invoke IEBAMMem, BAMMemMapPtr, lpszBamFilename, BAMFilesize, dwOpenMode
        mov hIEBAM, eax
        .IF hIEBAM == NULL
            Invoke UnmapViewOfFile, BAMMemMapPtr
            Invoke CloseHandle, BAMMemMapHandle
            Invoke CloseHandle, hBAMFile
            mov eax, NULL
            ret    
        .ENDIF
        .IF dwOpenMode == IEBAM_MODE_WRITE ; write (default)
            Invoke UnmapViewOfFile, BAMMemMapPtr
            Invoke CloseHandle, BAMMemMapHandle
            Invoke CloseHandle, hBAMFile
        .ELSE ; else readonly, so keep mapping around till we close file
            mov ebx, hIEBAM
            mov eax, BAMMemMapHandle
            mov [ebx].BAMINFO.BAMMemMapHandle, eax
            mov eax, hBAMFile
            mov [ebx].BAMINFO.BAMFileHandle, eax
        .ENDIF    
;        Invoke UnmapViewOfFile, BAMMemMapPtr
;        Invoke CloseHandle, BAMMemMapHandle
;        Invoke CloseHandle, hBAMFile
;        mov eax, NULL
;        ret    

    .ELSEIF SigReturn == BAM_VERSION_BAMCV10 ; BAMC
        Invoke BAMUncompress, hBAMFile, BAMMemMapPtr, Addr BAMFilesize
        .IF eax == 0
            Invoke UnmapViewOfFile, BAMMemMapPtr
            Invoke CloseHandle, BAMMemMapHandle
            Invoke CloseHandle, hBAMFile        
            mov eax, NULL
            ret
        .ENDIF
        mov pBAM, eax ; save uncompressed location to this var
        Invoke UnmapViewOfFile, BAMMemMapPtr
        Invoke CloseHandle, BAMMemMapHandle
        Invoke CloseHandle, hBAMFile        
        Invoke IEBAMMem, pBAM, lpszBamFilename, BAMFilesize, dwOpenMode
        mov hIEBAM, eax
        .IF hIEBAM == NULL
            Invoke GlobalFree, pBAM
            mov eax, NULL
            ret
        .ENDIF
   
    .ENDIF
    ; save original version to handle for later use so we know if orignal file opened was standard BIFF or a compressed BIF_ or BIFC file, if 0 then it was in mem so we assume BIFF
    mov ebx, hIEBAM
    mov eax, SigReturn
    mov [ebx].BAMINFO.BAMVersion, eax
    mov eax, hIEBAM
    ret
IEBAMOpen ENDP


IEBAM_ALIGN
;----------------------------------------------------------------------------
; IEBAMClose - Close BAM File
;----------------------------------------------------------------------------
IEBAMClose PROC USES EAX EBX hIEBAM:DWORD
    LOCAL FrameDataEntriesPtr:DWORD
    LOCAL FrameDataOffset:DWORD
    LOCAL FrameLookupEntriesPtr:DWORD
    LOCAL FrameLookupOffset:DWORD
    LOCAL TotalFrames:DWORD
    LOCAL TotalCycles:DWORD
    LOCAL nFrame:DWORD
    LOCAL nCycle:DWORD
    
    .IF hIEBAM == NULL
        mov eax, 0
        ret
    .ENDIF
        
    ; clear mem for alloc'd cycle sequence lookups, and clear mem for the whole lookup data structure
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMFrameLookupPtr
    .IF eax != NULL
        mov FrameLookupEntriesPtr, eax
        mov FrameLookupOffset, eax
        Invoke IEBAMTotalCycleEntries, hIEBAM
        mov TotalCycles, eax
        mov nCycle, 0
        mov eax, 0
        .WHILE eax < TotalCycles
            mov ebx, FrameLookupOffset
            mov eax, [ebx].FRAMELOOKUPTABLE.SequenceData
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF
            
            add FrameLookupOffset, SIZEOF FRAMELOOKUPTABLE
            inc nCycle
            mov eax, nCycle
        .ENDW
    .ENDIF        

    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMFrameLookupPtr   
    .IF eax != NULL
        Invoke GlobalFree, eax
    .ENDIF

    ; clear mem for alloc'd frames, delete handle to bitmaps for each frame if there is one and clear mem for the whole frame data structure
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMFrameDataEntriesPtr
    .IF eax != NULL
        mov FrameDataEntriesPtr, eax
        mov FrameDataOffset, eax
        Invoke IEBAMTotalFrameEntries, hIEBAM
        mov TotalFrames, eax
        mov nFrame, 0
        mov eax, 0
        .WHILE eax < TotalFrames
            mov ebx, FrameDataOffset
            mov eax, [ebx].FRAMEDATA.FrameRAW
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF
            mov ebx, FrameDataOffset
            mov eax, [ebx].FRAMEDATA.FrameRLE
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF
;            mov ebx, FrameDataOffset
;            mov eax, [ebx].FRAMEDATA.FrameBitmapHandle
;            .IF eax != NULL
;                Invoke DeleteObject, eax
;                IFDEF DEBUGLOG
;                DebugLogMsg "IEBAMClose::DeleteObject-FrameBitmapHandle::Success", DEBUGLOG_INFO, 3
;                ENDIF                  
;            .ENDIF
            mov ebx, FrameDataOffset
            mov eax, [ebx].FRAMEDATA.FrameBMP
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF
            
            add FrameDataOffset, SIZEOF FRAMEDATA
            inc nFrame
            mov eax, nFrame
        .ENDW
    .ENDIF

    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMFrameDataEntriesPtr
    .IF eax != NULL
        Invoke GlobalFree, eax
    .ENDIF

    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMOpenMode
    .IF eax == IEBAM_MODE_WRITE ; Write Mode
        mov ebx, hIEBAM
        mov eax, [ebx].BAMINFO.BAMHeaderPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF

        mov ebx, hIEBAM
        mov eax, [ebx].BAMINFO.BAMPalettePtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
        
        mov ebx, hIEBAM
        mov eax, [ebx].BAMINFO.BAMBlockEntriesPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF        
        
        mov ebx, hIEBAM
        mov eax, [ebx].BAMINFO.BAMFrameEntriesPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
        
        mov ebx, hIEBAM
        mov eax, [ebx].BAMINFO.BAMCycleEntriesPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
    .ENDIF

    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMVersion
    .IF eax == BAM_VERSION_BAMCV10 ; BAMC in read or write mode uncompresed bam in memory needs to be cleared
        mov ebx, hIEBAM
        mov eax, [ebx].BAMINFO.BAMMemMapPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF    
    
    .ELSE ; BAM V1 or BAM V2 so if  opened in readonly, unmap file etc, otherwise free mem

        mov ebx, hIEBAM
        mov eax, [ebx].BAMINFO.BAMOpenMode
        .IF eax == IEBAM_MODE_READONLY ; Read Only
            mov ebx, hIEBAM
            mov eax, [ebx].BAMINFO.BAMMemMapPtr
            .IF eax != NULL
                Invoke UnmapViewOfFile, eax
            .ENDIF
            
            mov ebx, hIEBAM
            mov eax, [ebx].BAMINFO.BAMMemMapHandle
            .IF eax != NULL
                Invoke CloseHandle, eax
            .ENDIF

            mov ebx, hIEBAM
            mov eax, [ebx].BAMINFO.BAMFileHandle
            .IF eax != NULL
                Invoke CloseHandle, eax
            .ENDIF
       
        .ELSE ; free mem if write mode
            mov ebx, hIEBAM
            mov eax, [ebx].BAMINFO.BAMMemMapPtr
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF
        .ENDIF

    .ENDIF
    
    mov eax, hIEBAM
    .IF eax != NULL
        Invoke GlobalFree, eax
    .ENDIF

    mov eax, 0
    ret
IEBAMClose ENDP


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; IEBAMMem - Returns handle in eax of opened bam file that is already loaded into memory. NULL if could not alloc enough mem
; calls BAMV1Mem or BAMV2Mem depending on version of file found
;-------------------------------------------------------------------------------------
IEBAMMem PROC pBAMInMemory:DWORD, lpszBamFilename:DWORD, dwBamFilesize:DWORD, dwOpenMode:DWORD
    ; check signatures to determine version
    Invoke BAMSignature, pBAMInMemory

    .IF eax == BAM_VERSION_INVALID ; invalid file
        mov eax, NULL
        ret

    .ELSEIF eax == BAM_VERSION_BAM_V10
        Invoke BAMV1Mem, pBAMInMemory, lpszBamFilename, dwBamFilesize, dwOpenMode

    .ELSEIF eax == BAM_VERSION_BAM_V20
        Invoke BAMV2Mem, pBAMInMemory, lpszBamFilename, dwBamFilesize, dwOpenMode

    .ELSEIF eax == BAM_VERSION_BAMCV10
        Invoke BAMV1Mem, pBAMInMemory, lpszBamFilename, dwBamFilesize, dwOpenMode

    .ENDIF
    ret
IEBAMMem ENDP


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; BAMV1Mem - Returns handle in eax of opened bam file that is already loaded into memory. NULL if could not alloc enough mem
;-------------------------------------------------------------------------------------
BAMV1Mem PROC USES EBX ECX EDX pBAMInMemory:DWORD, lpszBamFilename:DWORD, dwBamFilesize:DWORD, dwOpenMode:DWORD
    LOCAL hIEBAM:DWORD
    LOCAL BAMMemMapPtr:DWORD
    LOCAL TotalFrameEntries:DWORD
    LOCAL TotalCycleEntries:DWORD
    LOCAL FrameEntriesSize:DWORD
    LOCAL CycleEntriesSize:DWORD
    LOCAL FrameLookupSize:DWORD
    LOCAL OffsetFrameEntries:DWORD
    LOCAL OffsetCycleEntries:DWORD
    LOCAL OffsetPalette:DWORD
    LOCAL OffsetFrameLookup:DWORD
    LOCAL FrameLookupOriginal:DWORD
    LOCAL FrameEntriesPtr:DWORD
    LOCAL FrameEntryPtr:DWORD
    LOCAL CycleEntriesPtr:DWORD
    LOCAL CycleEntryPtr:DWORD
    LOCAL PalettePtr:DWORD
    LOCAL FrameLookupEntriesPtr:DWORD
    LOCAL FrameLookupEntryPtr:DWORD
    LOCAL FrameDataEntriesPtr:DWORD
    LOCAL FrameDataEntryPtr:DWORD
    LOCAL nCycle:DWORD
    LOCAL nFrame:DWORD
    LOCAL nCycleIndexStart:DWORD
    LOCAL nCycleIndexCount:DWORD
    LOCAL SequenceSize:DWORD
    LOCAL SequencePtr:DWORD
    LOCAL AllFramesDataSize:DWORD
    LOCAL tFrameDataRawPtr:DWORD
    LOCAL tFrameDataRlePtr:DWORD
    LOCAL tFrameDataBmpPtr:DWORD
    LOCAL FrameCompressed:DWORD
    LOCAL FrameDataOffset:DWORD
    LOCAL FrameDataOffsetN1:DWORD
    LOCAL FrameDataRLE:DWORD
    LOCAL FrameWidth:DWORD
    LOCAL FrameHeight:DWORD
    LOCAL FrameWidthDwordAligned:DWORD
    LOCAL FrameInfo:DWORD
    LOCAL FrameSize:DWORD
    LOCAL FrameSizeRAW:DWORD
    LOCAL FrameSizeRLE:DWORD
    LOCAL FrameSizeBMP:DWORD
    LOCAL FrameDataRawPtr:DWORD
    LOCAL FrameDataRlePtr:DWORD
    LOCAL FrameDataBmpPtr:DWORD

    mov eax, pBAMInMemory
    mov BAMMemMapPtr, eax       
    
    ;----------------------------------
    ; Alloc mem for our IEBAM Handle
    ;----------------------------------
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF BAMINFO
    .IF eax == NULL
        ret
    .ENDIF
    mov hIEBAM, eax
    
    mov ebx, hIEBAM
    mov eax, dwOpenMode
    mov [ebx].BAMINFO.BAMOpenMode, eax
    mov eax, BAMMemMapPtr
    mov [ebx].BAMINFO.BAMMemMapPtr, eax
    
    lea eax, [ebx].BAMINFO.BAMFilename
    Invoke szCopy, lpszBamFilename, eax
    
    mov ebx, hIEBAM
    mov eax, dwBamFilesize
    mov [ebx].BAMINFO.BAMFilesize, eax

    ;----------------------------------
    ; BAM Header
    ;----------------------------------
    .IF dwOpenMode == IEBAM_MODE_WRITE
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF BAMV1_HEADER
        .IF eax == NULL
            Invoke GlobalFree, hIEBAM
            mov eax, NULL
            ret
        .ENDIF    
        mov ebx, hIEBAM
        mov [ebx].BAMINFO.BAMHeaderPtr, eax
        mov ebx, BAMMemMapPtr
        Invoke RtlMoveMemory, eax, ebx, SIZEOF BAMV1_HEADER
    .ELSE
        mov ebx, hIEBAM
        mov eax, BAMMemMapPtr
        mov [ebx].BAMINFO.BAMHeaderPtr, eax
    .ENDIF
    mov ebx, hIEBAM
    mov eax, SIZEOF BAMV1_HEADER
    mov [ebx].BAMINFO.BAMHeaderSize, eax   

    ;----------------------------------
    ; Double check file in mem is BAM
    ;----------------------------------
    Invoke RtlZeroMemory, Addr BAMXHeader, SIZEOF BAMXHeader
    Invoke RtlMoveMemory, Addr BAMXHeader, BAMMemMapPtr, 8d
    Invoke szCmp, Addr BAMXHeader, Addr BAMV1Header
    .IF eax == 0 ; no match    
        mov ebx, hIEBAM
        mov eax, [ebx].BAMINFO.BAMHeaderPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
        Invoke GlobalFree, hIEBAM
        mov eax, NULL    
        ret
    .ENDIF

    ;----------------------------------
    ; Frame & Cycle Counts, Offsets & Sizes
    ;----------------------------------
    mov ebx, [ebx].BAMINFO.BAMHeaderPtr
    movzx eax, word ptr [ebx].BAMV1_HEADER.FrameEntriesCount
    mov TotalFrameEntries, eax
    movzx eax, byte ptr [ebx].BAMV1_HEADER.CycleEntriesCount
    mov TotalCycleEntries, eax
    mov eax, [ebx].BAMV1_HEADER.FrameEntriesOffset
    mov OffsetFrameEntries, eax
    mov eax, [ebx].BAMV1_HEADER.PaletteOffset
    mov OffsetPalette, eax    
    mov eax, [ebx].BAMV1_HEADER.FrameLookupOffset
    mov OffsetFrameLookup, eax
    add eax, BAMMemMapPtr
    mov FrameLookupOriginal, eax
    
    ;mov eax, [ebx].BIFV1_HEADER.OffsetResEntries
    ;mov OffsetResEntries, eax
    
    mov eax, TotalFrameEntries
    mov ebx, SIZEOF FRAMEV1_ENTRY
    mul ebx
    mov FrameEntriesSize, eax
    
    mov eax, TotalCycleEntries
    mov ebx, SIZEOF CYCLEV1_ENTRY
    mul ebx
    mov CycleEntriesSize, eax
    
    mov eax, FrameEntriesSize
    add eax, OffsetFrameEntries ;SIZEOF BAMV1_HEADER
    mov OffsetCycleEntries, eax

    ;----------------------------------
    ; Frame Entries
    ;----------------------------------
    .IF TotalFrameEntries > 0
        .IF dwOpenMode == IEBAM_MODE_WRITE
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, FrameEntriesSize
            .IF eax == NULL
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMHeaderPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                Invoke GlobalFree, hIEBAM
                mov eax, NULL    
                ret
            .ENDIF    
            mov ebx, hIEBAM
            mov [ebx].BAMINFO.BAMFrameEntriesPtr, eax
            mov FrameEntriesPtr, eax
        
            mov ebx, BAMMemMapPtr
            add ebx, OffsetFrameEntries
            Invoke RtlMoveMemory, eax, ebx, FrameEntriesSize
        .ELSE
            mov ebx, hIEBAM
            mov eax, BAMMemMapPtr
            add eax, OffsetFrameEntries
            mov [ebx].BAMINFO.BAMFrameEntriesPtr, eax
            mov FrameEntriesPtr, eax
        .ENDIF
        mov ebx, hIEBAM
        mov eax, FrameEntriesSize
        mov [ebx].BAMINFO.BAMFrameEntriesSize, eax    
    .ELSE
        mov ebx, hIEBAM
        mov [ebx].BAMINFO.BAMFrameEntriesPtr, 0
        mov [ebx].BAMINFO.BAMFrameEntriesSize, 0
        mov FrameEntriesPtr, 0
    .ENDIF

    ;----------------------------------
    ; Cycle Entries
    ;----------------------------------
    .IF TotalCycleEntries > 0
        .IF dwOpenMode == IEBAM_MODE_WRITE
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, CycleEntriesSize
            .IF eax == NULL
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMFrameEntriesPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMHeaderPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                Invoke GlobalFree, hIEBAM
                mov eax, NULL    
                ret
            .ENDIF    
            mov ebx, hIEBAM
            mov [ebx].BAMINFO.BAMCycleEntriesPtr, eax
            mov CycleEntriesPtr, eax
        
            mov ebx, BAMMemMapPtr
            add ebx, OffsetCycleEntries
            Invoke RtlMoveMemory, eax, ebx, CycleEntriesSize
        .ELSE
            mov ebx, hIEBAM
            mov eax, BAMMemMapPtr
            add eax, OffsetCycleEntries
            mov [ebx].BAMINFO.BAMCycleEntriesPtr, eax
            mov CycleEntriesPtr, eax
        .ENDIF
        mov ebx, hIEBAM
        mov eax, CycleEntriesSize
        mov [ebx].BAMINFO.BAMCycleEntriesSize, eax   
    .ELSE
        mov ebx, hIEBAM
        mov [ebx].BAMINFO.BAMCycleEntriesPtr, 0
        mov [ebx].BAMINFO.BAMCycleEntriesSize, 0
        mov CycleEntriesPtr, 0
    .ENDIF

    ;----------------------------------
    ; Palette
    ;----------------------------------      
  
    .IF dwOpenMode == IEBAM_MODE_WRITE
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, 1024d ; alloc space for palette
        .IF eax == NULL
            mov ebx, hIEBAM
            mov eax, [ebx].BAMINFO.BAMCycleEntriesPtr
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF
            mov ebx, hIEBAM
            mov eax, [ebx].BAMINFO.BAMFrameEntriesPtr
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF
            mov ebx, hIEBAM
            mov eax, [ebx].BAMINFO.BAMHeaderPtr
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF
            Invoke GlobalFree, hIEBAM
            mov eax, NULL    
            ret
        .ENDIF
        mov ebx, hIEBAM
        mov [ebx].BAMINFO.BAMPalettePtr, eax
        mov PalettePtr, eax

        mov ebx, BAMMemMapPtr
        add ebx, OffsetPalette
        Invoke RtlMoveMemory, eax, ebx, 1024d
    .ELSE
        mov ebx, hIEBAM
        mov eax, BAMMemMapPtr
        add eax, OffsetPalette
        mov [ebx].BAMINFO.BAMPalettePtr, eax
        mov PalettePtr, eax
    .ENDIF
    ; copy palette to our bitmap header palette var
    Invoke RtlMoveMemory, Addr BAMBMPPalette, PalettePtr, 1024    
    
    ;mov ebx, hIEBAM
    ;mov eax, 1024d
    ;mov [ebx].BAMINFO.BAMPaletteSize, eax   

    ;----------------------------------
    ; Alloc space for FrameLookup
    ;----------------------------------
    ; Calc size of FrameLookup Table
    .IF TotalCycleEntries > 0
        mov eax, TotalCycleEntries
        mov ebx, SIZEOF FRAMELOOKUPTABLE
        mul ebx
        mov FrameLookupSize, eax 

        ; Alloc space for framelookup table
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, FrameLookupSize
        .IF eax == NULL
            .IF dwOpenMode == IEBAM_MODE_WRITE
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMPalettePtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMCycleEntriesPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMFrameEntriesPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMHeaderPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
            .ENDIF
            Invoke GlobalFree, hIEBAM
            mov eax, NULL    
            ret
        .ENDIF
        mov ebx, hIEBAM
        mov [ebx].BAMINFO.BAMFrameLookupPtr, eax
        mov FrameLookupEntriesPtr, eax
        mov eax, FrameLookupSize
        mov [ebx].BAMINFO.BAMFrameLookupSize, eax
        
        mov eax, CycleEntriesPtr
        mov CycleEntryPtr, eax
        
        mov eax, FrameLookupEntriesPtr
        mov FrameLookupEntryPtr, eax

        ; loop through cycles, get framelookup start index and count, get this data and copy it to a mem entry of our own lookup table
        mov nCycle, 0
        mov eax, 0
        .WHILE eax < TotalCycleEntries
            mov ebx, CycleEntryPtr
            movzx eax, word ptr [ebx].CYCLEV1_ENTRY.CycleFrameCount
            mov nCycleIndexCount, eax
            movzx eax, word ptr [ebx].CYCLEV1_ENTRY.CycleStartFrame
            mov nCycleIndexStart, eax

            .IF nCycleIndexCount > 0
                ; calc size of sequence
                mov eax, nCycleIndexCount
                mov ebx, 2d ; word sized array
                mul ebx
                mov SequenceSize, eax
            .ELSE
                mov SequenceSize, 0
            .ENDIF

            ; alloc mem for sequence
            .IF nCycleIndexCount > 0 
                Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SequenceSize ;nCycleIndexCount ;SequenceSize
                mov SequencePtr, eax
                mov eax, nCycleIndexStart
                mov ebx, 2d ; word array size
                mul ebx
                add eax, FrameLookupOriginal ; offset to index of cycle sequence is now in eax  
                ; copy sequence memory data
                Invoke RtlMoveMemory, SequencePtr, eax, SequenceSize ;nCycleIndexCount ;SequenceSize
            .ELSE
                mov SequencePtr, 0
            .ENDIF

            ; Assign memory ptr of sequence to our own lookup table entry
            mov ebx, FrameLookupEntryPtr
            mov eax, SequenceSize ;nCycleIndexCount ;SequenceSize
            mov [ebx].FRAMELOOKUPTABLE.SequenceSize, eax
            mov eax, SequencePtr
            mov [ebx].FRAMELOOKUPTABLE.SequenceData, eax
            
            add CycleEntryPtr, SIZEOF CYCLEV1_ENTRY
            add FrameLookupEntryPtr, SIZEOF FRAMELOOKUPTABLE
            
            inc nCycle
            mov eax, nCycle
        .ENDW

    .ELSE
        mov ebx, hIEBAM
        mov [ebx].BAMINFO.BAMFrameLookupPtr, 0
        mov [ebx].BAMINFO.BAMFrameLookupSize, 0
    .ENDIF

    ;----------------------------------
    ; Alloc space for FrameDataEntries
    ;----------------------------------
    ; loop through frame entries, get frame data for each frame and save to our own structure
    .IF TotalFrameEntries > 0
        mov eax, TotalFrameEntries
        mov ebx, SIZEOF FRAMEDATA
        mul ebx
        mov AllFramesDataSize, eax
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, AllFramesDataSize
        .IF eax == NULL
            .IF dwOpenMode == IEBAM_MODE_WRITE
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMFrameLookupPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF    
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMPalettePtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMCycleEntriesPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMFrameEntriesPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMHeaderPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
            .ENDIF    
            Invoke GlobalFree, hIEBAM
            mov eax, NULL    
            ret
        .ENDIF
        mov ebx, hIEBAM
        mov [ebx].BAMINFO.BAMFrameDataEntriesPtr, eax
        mov FrameDataEntriesPtr, eax
        mov eax, AllFramesDataSize
        mov [ebx].BAMINFO.BAMFrameDataEntriesSize, eax

        mov eax, FrameEntriesPtr
        mov FrameEntryPtr, eax
        mov eax, FrameDataEntriesPtr
        mov FrameDataEntryPtr, eax

        mov nFrame, 0
        mov eax, 0
        .WHILE eax < TotalFrameEntries
            mov ebx, FrameEntryPtr
            movzx eax, word ptr [ebx].FRAMEV1_ENTRY.FrameWidth
            mov FrameWidth, eax
            movzx eax, word ptr [ebx].FRAMEV1_ENTRY.FrameHeight
            mov FrameHeight, eax
            mov eax, [ebx].FRAMEV1_ENTRY.FrameInfo
            mov FrameInfo, eax

            .IF FrameWidth != 0 && FrameHeight != 0
                ; calc dword aligned width
                xor edx, edx
                mov eax, FrameWidth
                mov ecx, 4
                div ecx ;edx contains remainder
                .IF edx != 0
                    mov eax, 4
                    sub eax, edx
                    add eax, FrameWidth
                .ELSE
                    mov eax, FrameWidth
                .ENDIF
                mov FrameWidthDwordAligned, eax
            .ELSE
                mov FrameWidthDwordAligned, 0
            .ENDIF    

            ; Get FrameOffset to data and compression status
            mov eax, FrameInfo
            AND eax, 80000000h ; mask for compression bit
            shr eax, 31d
            mov FrameCompressed, eax
            .IF FrameCompressed == 1
                ;PrintText 'Uncompressed Frame'
            .endif
            mov eax, FrameInfo
            AND eax, 7FFFFFFFh ; mask for offset to frame data
            mov FrameDataOffset, eax

            ; Get framedata entry (our structure) for specified frame
            mov eax, TotalFrameEntries
            dec eax ; for 0 based frame index
            .IF nFrame == eax ; end of frames, use filesize instead
                mov eax, dwBamFilesize
                mov FrameDataOffsetN1, eax
            .ELSE 
                mov eax, FrameEntryPtr
                add eax, SIZEOF FRAMEV1_ENTRY ; frame N + 1
                mov ebx, eax
                mov eax, [ebx].FRAMEV1_ENTRY.FrameInfo
                AND eax, 7FFFFFFFh; mask for offset to frame data
                mov FrameDataOffsetN1, eax
            .ENDIF
            mov ebx, FrameDataOffset
            sub eax, ebx
            .IF FrameCompressed == 1 ; uncompressed
                mov FrameSizeRAW, eax
                mov FrameSizeRLE, 0
            .ELSE ; else compressed
                mov FrameSizeRLE, eax
                mov eax, FrameWidthDwordAligned
                mov ebx, FrameHeight
                mul ebx
                mov FrameSizeRAW, eax ; got to set max to what would be max dword width x height as raw size is unknown - during unrle we get the actual size
            .ENDIF
            mov eax, FrameWidthDwordAligned
            mov ebx, FrameHeight
            mul ebx
            mov FrameSizeBMP, eax

            .IF FrameSizeRAW != 0
                Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, FrameSizeRAW
                mov FrameDataRawPtr, eax
            .ELSE
                mov FrameDataRawPtr, 0
            .ENDIF
            .IF FrameSizeRLE != 0
                Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, FrameSizeRLE
                mov FrameDataRlePtr, eax
            .ELSE
                mov FrameDataRlePtr, 0
            .ENDIF
            .IF FrameSizeBMP != 0
                Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, FrameSizeBMP
                mov FrameDataBmpPtr, eax
            .ELSE
                mov FrameDataBmpPtr, 0
            .ENDIF

            mov ebx, FrameDataEntryPtr
            mov eax, FrameCompressed
            mov [ebx].FRAMEDATA.FrameCompressed, eax
            mov eax, FrameSizeRAW
            mov [ebx].FRAMEDATA.FrameSizeRAW, eax
            mov eax, FrameSizeRLE
            mov [ebx].FRAMEDATA.FrameSizeRLE, eax
            mov eax, FrameSizeBMP
            mov [ebx].FRAMEDATA.FrameSizeBMP, eax
            mov eax, FrameWidth
            mov [ebx].FRAMEDATA.FrameWidth, eax
            mov eax, FrameHeight
            mov [ebx].FRAMEDATA.FrameHeight, eax
            mov eax, FrameDataRawPtr
            mov [ebx].FRAMEDATA.FrameRAW, eax
            mov eax, FrameDataRlePtr
            mov [ebx].FRAMEDATA.FrameRLE, eax
            mov eax, FrameDataBmpPtr
            mov [ebx].FRAMEDATA.FrameBMP, eax
            
            mov eax, BAMMemMapPtr
            add eax, FrameDataOffset
            .IF FrameCompressed == 1 ; uncompressed
                .IF FrameDataRawPtr != 0
                    Invoke RtlMoveMemory, FrameDataRawPtr, eax, FrameSizeRAW
                .ENDIF
                Invoke IEBAMFrameRAWToFrameBMP, FrameDataRawPtr, FrameDataBmpPtr, FrameSizeRAW, FrameSizeBMP, FrameWidth

            .ELSE ; compressed
                Invoke RtlMoveMemory, FrameDataRlePtr, eax, FrameSizeRLE
                mov eax, FrameSizeRLE
                .IF eax == FrameSizeRAW ; already uncompressed so just copy memory
                    Invoke RtlMoveMemory, FrameDataRawPtr, FrameDataRlePtr, FrameSizeRLE
                    Invoke RtlMoveMemory, FrameDataBmpPtr, FrameDataRlePtr, FrameSizeRLE
                
                .ELSEIF eax > FrameSizeRAW ; invalid bam, copy last bam frame to this
                    mov eax, nFrame
                    inc eax
                    .IF eax == TotalFrameEntries ; last frame problem RIPPLES_2.BAM
                        ; save pointers to current frame data info raw and rle data
                        mov eax, FrameDataRawPtr
                        mov tFrameDataRawPtr, eax
                        mov eax, FrameDataRlePtr
                        mov tFrameDataRlePtr, eax
                        mov eax, FrameDataBmpPtr
                        mov tFrameDataBmpPtr, eax
                        
                        mov ebx, FrameDataEntryPtr
                        sub ebx, SIZEOF FRAMEDATA ; get frame before
                        mov eax, [ebx].FRAMEDATA.FrameSizeRLE
                        mov FrameSizeRLE, eax
                        mov eax, [ebx].FRAMEDATA.FrameSizeBMP
                        mov FrameSizeBMP, eax
                        mov eax, [ebx].FRAMEDATA.FrameWidth
                        mov FrameWidth, eax
                        mov eax, [ebx].FRAMEDATA.FrameHeight
                        mov FrameHeight, eax
                        mov eax, [ebx].FRAMEDATA.FrameRAW
                        mov FrameDataRawPtr, eax
                        mov eax, [ebx].FRAMEDATA.FrameRLE
                        mov FrameDataRlePtr, eax
                        mov eax, [ebx].FRAMEDATA.FrameBMP
                        mov FrameDataBmpPtr, eax

                        .IF FrameDataRawPtr != 0
                            Invoke RtlMoveMemory, tFrameDataRawPtr, FrameDataRawPtr, FrameSizeRAW
                            Invoke RtlMoveMemory, tFrameDataBmpPtr, FrameDataBmpPtr, FrameSizeBMP
                        .ENDIF
                        .IF FrameDataRlePtr != 0
                            Invoke RtlMoveMemory, tFrameDataRlePtr, FrameDataRlePtr, FrameSizeRLE
                        .ENDIF
                        
                        mov ebx, FrameDataEntryPtr ; back to current frame to update sizes
                        mov eax, FrameSizeRLE
                        mov [ebx].FRAMEDATA.FrameSizeRLE, eax

                    .ENDIF
                        
                .ELSE ; otherwise unRLE mem to raw storage
                    Invoke IEBAMFrameUnRLE, FrameDataRlePtr, FrameDataRawPtr, FrameSizeRLE, FrameSizeRAW, FrameWidth ; unRLE compressed frame
                    .IF eax == -1
                    .ENDIF
                    mov FrameSizeRAW, eax
                    mov ebx, FrameDataEntryPtr
                    mov [ebx].FRAMEDATA.FrameSizeRAW, eax ; put correct raw size here
                    
                    Invoke IEBAMFrameRAWToFrameBMP, FrameDataRawPtr, FrameDataBmpPtr, FrameSizeRAW, FrameSizeBMP, FrameWidth
                .ENDIF
            .ENDIF
            
            ; copy data to our framedata entry.
            add FrameEntryPtr, SIZEOF FRAMEV1_ENTRY
            add FrameDataEntryPtr, SIZEOF FRAMEDATA
            
            inc nFrame
            mov eax, nFrame
        .ENDW

    .ELSE
        mov ebx, hIEBAM
        mov [ebx].BAMINFO.BAMFrameDataEntriesPtr, 0
        mov [ebx].BAMINFO.BAMFrameDataEntriesSize, 0
    .ENDIF

    mov eax, hIEBAM
    ret
BAMV1Mem ENDP


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; BAMV2Mem - Returns handle in eax of opened bam file that is already loaded into memory. NULL if could not alloc enough mem
;-------------------------------------------------------------------------------------
BAMV2Mem PROC USES EBX ECX EDX pBAMInMemory:DWORD, lpszBamFilename:DWORD, dwBamFilesize:DWORD, dwOpenMode:DWORD
    LOCAL hIEBAM:DWORD
    LOCAL BAMMemMapPtr:DWORD
    LOCAL TotalFrameEntries:DWORD
    LOCAL TotalCycleEntries:DWORD
    LOCAL TotalBlockEntries:DWORD
    LOCAL FrameEntriesSize:DWORD
    LOCAL CycleEntriesSize:DWORD
    LOCAL BlockEntriesSize:DWORD
    LOCAL FrameLookupSize:DWORD
    LOCAL OffsetFrameEntries:DWORD
    LOCAL OffsetCycleEntries:DWORD
    LOCAL OffsetBlockEntries:DWORD
    LOCAL FrameEntriesPtr:DWORD
    LOCAL FrameEntryPtr:DWORD
    LOCAL CycleEntriesPtr:DWORD
    LOCAL CycleEntryPtr:DWORD
    LOCAL BlockEntriesPtr:DWORD
    LOCAL FrameLookupEntriesPtr:DWORD
    LOCAL FrameLookupEntryPtr:DWORD
    LOCAL AllFramesDataSize:DWORD
    LOCAL FrameDataEntriesPtr:DWORD
    LOCAL FrameDataEntryPtr:DWORD
    LOCAL nCycle:DWORD
    LOCAL nFrame:DWORD
    LOCAL nCycleIndexStart:DWORD
    LOCAL nCycleIndexCount:DWORD
    LOCAL SequenceSize:DWORD
    LOCAL SequencePtr:DWORD
    LOCAL FrameCompressed:DWORD
    LOCAL FrameDataOffset:DWORD
    LOCAL FrameDataRLE:DWORD
    LOCAL FrameWidth:DWORD
    LOCAL FrameHeight:DWORD
    LOCAL FrameWidthDwordAligned:DWORD
    LOCAL FrameHeightDwordAligned:DWORD
    LOCAL FrameSize:DWORD
    LOCAL FrameSizeRAW:DWORD
    LOCAL FrameSizeRLE:DWORD
    LOCAL FrameSizeBMP:DWORD
    LOCAL FrameDataRawPtr:DWORD
    LOCAL FrameDataRlePtr:DWORD
    LOCAL FrameDataBmpPtr:DWORD
    LOCAL DataBlockIndex:DWORD
    LOCAL DataBlockCount:DWORD

    mov eax, pBAMInMemory
    mov BAMMemMapPtr, eax      

    ;----------------------------------
    ; Alloc mem for our IEBAM Handle
    ;----------------------------------
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF BAMINFO
    .IF eax == NULL
        ret
    .ENDIF
    mov hIEBAM, eax
    
    mov ebx, hIEBAM
    mov eax, dwOpenMode
    mov [ebx].BAMINFO.BAMOpenMode, eax
    mov eax, BAMMemMapPtr
    mov [ebx].BAMINFO.BAMMemMapPtr, eax
    
    lea eax, [ebx].BAMINFO.BAMFilename
    Invoke szCopy, lpszBamFilename, eax
    
    mov ebx, hIEBAM
    mov eax, dwBamFilesize
    mov [ebx].BAMINFO.BAMFilesize, eax

    ;----------------------------------
    ; BAM Header
    ;----------------------------------
    .IF dwOpenMode == IEBAM_MODE_WRITE
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF BAMV2_HEADER
        .IF eax == NULL
            Invoke GlobalFree, hIEBAM
            mov eax, NULL
            ret
        .ENDIF    
        mov ebx, hIEBAM
        mov [ebx].BAMINFO.BAMHeaderPtr, eax
        mov ebx, BAMMemMapPtr
        Invoke RtlMoveMemory, eax, ebx, SIZEOF BAMV2_HEADER
    .ELSE
        mov ebx, hIEBAM
        mov eax, BAMMemMapPtr
        mov [ebx].BAMINFO.BAMHeaderPtr, eax
    .ENDIF
    mov ebx, hIEBAM
    mov eax, SIZEOF BAMV2_HEADER
    mov [ebx].BAMINFO.BAMHeaderSize, eax   

    ;----------------------------------
    ; Frame & Cycle Counts, Offsets & Sizes
    ;----------------------------------
    mov ebx, [ebx].BAMINFO.BAMHeaderPtr
    mov eax, [ebx].BAMV2_HEADER.FrameEntriesCount
    mov TotalFrameEntries, eax
    mov eax, [ebx].BAMV2_HEADER.CycleEntriesCount
    mov TotalCycleEntries, eax
    mov eax, [ebx].BAMV2_HEADER.BlockEntriesCount
    mov TotalBlockEntries, eax
    mov eax, [ebx].BAMV2_HEADER.FrameEntriesOffset
    mov OffsetFrameEntries, eax
    mov eax, [ebx].BAMV2_HEADER.CycleEntriesOffset
    mov OffsetCycleEntries, eax    
    mov eax, [ebx].BAMV2_HEADER.BlockEntriesOffset
    mov OffsetBlockEntries, eax
    
    mov eax, TotalFrameEntries
    mov ebx, SIZEOF FRAMEV2_ENTRY
    mul ebx
    mov FrameEntriesSize, eax
    
    mov eax, TotalCycleEntries
    mov ebx, SIZEOF CYCLEV2_ENTRY
    mul ebx
    mov CycleEntriesSize, eax
    
    mov eax, TotalBlockEntries
    mov ebx, SIZEOF DATABLOCK_ENTRY
    mul ebx
    mov BlockEntriesSize, eax

    ;----------------------------------
    ; No Palette for BAM V2!
    ;----------------------------------
    mov ebx, hIEBAM
    mov [ebx].BAMINFO.BAMPalettePtr, 0
    mov [ebx].BAMINFO.BAMPaletteSize, 0

    ;----------------------------------
    ; Frame Entries
    ;----------------------------------
    .IF TotalFrameEntries > 0
        .IF dwOpenMode == IEBAM_MODE_WRITE
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, FrameEntriesSize
            .IF eax == NULL
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMHeaderPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                Invoke GlobalFree, hIEBAM
                mov eax, NULL    
                ret
            .ENDIF    
            mov ebx, hIEBAM
            mov [ebx].BAMINFO.BAMFrameEntriesPtr, eax
            mov FrameEntriesPtr, eax
        
            mov ebx, BAMMemMapPtr
            add ebx, OffsetFrameEntries
            Invoke RtlMoveMemory, eax, ebx, FrameEntriesSize
        .ELSE
            mov ebx, hIEBAM
            mov eax, BAMMemMapPtr
            add eax, OffsetFrameEntries
            mov [ebx].BAMINFO.BAMFrameEntriesPtr, eax
            mov FrameEntriesPtr, eax
        .ENDIF
        mov ebx, hIEBAM
        mov eax, FrameEntriesSize
        mov [ebx].BAMINFO.BAMFrameEntriesSize, eax    
    .ELSE
        mov ebx, hIEBAM
        mov [ebx].BAMINFO.BAMFrameEntriesPtr, 0
        mov [ebx].BAMINFO.BAMFrameEntriesSize, 0
        mov FrameEntriesPtr, 0
    .ENDIF

    ;----------------------------------
    ; Cycle Entries
    ;----------------------------------
    .IF TotalCycleEntries > 0
        .IF dwOpenMode == IEBAM_MODE_WRITE
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, CycleEntriesSize
            .IF eax == NULL
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMFrameEntriesPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMHeaderPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                Invoke GlobalFree, hIEBAM
                mov eax, NULL    
                ret
            .ENDIF    
            mov ebx, hIEBAM
            mov [ebx].BAMINFO.BAMCycleEntriesPtr, eax
            mov CycleEntriesPtr, eax
        
            mov ebx, BAMMemMapPtr
            add ebx, OffsetCycleEntries
            Invoke RtlMoveMemory, eax, ebx, CycleEntriesSize
        .ELSE
            mov ebx, hIEBAM
            mov eax, BAMMemMapPtr
            add eax, OffsetCycleEntries
            mov [ebx].BAMINFO.BAMCycleEntriesPtr, eax
            mov CycleEntriesPtr, eax
        .ENDIF
        mov ebx, hIEBAM
        mov eax, CycleEntriesSize
        mov [ebx].BAMINFO.BAMCycleEntriesSize, eax   
    .ELSE
        mov ebx, hIEBAM
        mov [ebx].BAMINFO.BAMCycleEntriesPtr, 0
        mov [ebx].BAMINFO.BAMCycleEntriesSize, 0
        mov CycleEntriesPtr, 0
    .ENDIF

    ;----------------------------------
    ; Data Block Entries
    ;----------------------------------
    .IF TotalBlockEntries > 0
        .IF dwOpenMode == IEBAM_MODE_WRITE
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, BlockEntriesSize
            .IF eax == NULL
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMCycleEntriesPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF            
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMFrameEntriesPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMHeaderPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                Invoke GlobalFree, hIEBAM
                mov eax, NULL    
                ret
            .ENDIF    
            mov ebx, hIEBAM
            mov [ebx].BAMINFO.BAMBlockEntriesPtr, eax
            mov BlockEntriesPtr, eax
        
            mov ebx, BAMMemMapPtr
            add ebx, OffsetBlockEntries
            Invoke RtlMoveMemory, eax, ebx, BlockEntriesSize
        .ELSE
            mov ebx, hIEBAM
            mov eax, BAMMemMapPtr
            add eax, OffsetBlockEntries
            mov [ebx].BAMINFO.BAMBlockEntriesPtr, eax
            mov BlockEntriesPtr, eax
        .ENDIF
        mov ebx, hIEBAM
        mov eax, BlockEntriesSize
        mov [ebx].BAMINFO.BAMBlockEntriesSize, eax   
    .ELSE
        mov ebx, hIEBAM
        mov [ebx].BAMINFO.BAMBlockEntriesPtr, 0
        mov [ebx].BAMINFO.BAMBlockEntriesSize, 0
        mov BlockEntriesPtr, 0
    .ENDIF

    ;----------------------------------
    ; Alloc space for FrameLookup
    ;----------------------------------
    ; Calc size of FrameLookup Table
    .IF TotalCycleEntries > 0
        mov eax, TotalCycleEntries
        mov ebx, SIZEOF FRAMELOOKUPTABLE
        mul ebx
        mov FrameLookupSize, eax 

        ; Alloc space for framelookup table
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, FrameLookupSize
        .IF eax == NULL
            .IF dwOpenMode == IEBAM_MODE_WRITE
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMBlockEntriesPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMCycleEntriesPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMFrameEntriesPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMHeaderPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
            .ENDIF
            Invoke GlobalFree, hIEBAM
            mov eax, NULL    
            ret
        .ENDIF
        mov ebx, hIEBAM
        mov [ebx].BAMINFO.BAMFrameLookupPtr, eax
        mov FrameLookupEntriesPtr, eax
        mov eax, FrameLookupSize
        mov [ebx].BAMINFO.BAMFrameLookupSize, eax
        
        mov eax, FrameLookupEntriesPtr
        mov FrameLookupEntryPtr, eax
        
        mov eax, CycleEntriesPtr
        mov CycleEntryPtr, eax

        ; loop through cycles, get framelookup start index and count, get this data and copy it to a mem entry of our own lookup table
        mov nCycle, 0
        mov eax, 0
        .WHILE eax < TotalCycleEntries
            mov ebx, CycleEntryPtr
            movzx eax, word ptr [ebx].CYCLEV1_ENTRY.CycleFrameCount
            mov nCycleIndexCount, eax
            movzx eax, word ptr [ebx].CYCLEV1_ENTRY.CycleStartFrame
            mov nCycleIndexStart, eax

            .IF nCycleIndexCount > 0
                ; calc size of sequence
                mov eax, nCycleIndexCount
                mov ebx, 2d ; word sized array
                mul ebx
                mov SequenceSize, eax
            .ELSE
                mov SequenceSize, 0
            .ENDIF

            ; alloc mem for sequence
            .IF nCycleIndexCount > 0 
                Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SequenceSize ;nCycleIndexCount ;SequenceSize
                mov SequencePtr, eax
                
                ; create fake lookup table for each cycles sequence - BAM V2 has start frame in cycle, and count - no lookup
                ; loop cycle count amount of times, place a word value for sequence, incremented each loop till end of loop
                mov eax, nCycleIndexStart
                mov ebx, SequencePtr
                mov ecx, 0
                .WHILE ecx < nCycleIndexCount
                    mov word ptr [ebx], ax
                    add ebx, 2d ; word array size
                    inc eax ; increment frame index for next iteration
                    inc ecx ; inc counter
                .ENDW
                
            .ELSE
                mov SequencePtr, 0
            .ENDIF
            
            ; Assign memory ptr of sequence to our own lookup table entry
            mov ebx, FrameLookupEntryPtr
            mov eax, SequenceSize ;nCycleIndexCount ;SequenceSize
            mov [ebx].FRAMELOOKUPTABLE.SequenceSize, eax
            mov eax, SequencePtr
            mov [ebx].FRAMELOOKUPTABLE.SequenceData, eax

            add CycleEntryPtr, SIZEOF CYCLEV2_ENTRY
            add FrameLookupEntryPtr, SIZEOF FRAMELOOKUPTABLE            
            
            inc nCycle
            mov eax, nCycle
        .ENDW
    .ELSE
        mov ebx, hIEBAM
        mov [ebx].BAMINFO.BAMFrameLookupPtr, 0
        mov [ebx].BAMINFO.BAMFrameLookupSize, 0
    .ENDIF

    ;----------------------------------
    ; Alloc space for FrameDataEntries
    ;----------------------------------
    ; loop through frame entries, get frame data for each frame and save to our own structure
    .IF TotalFrameEntries > 0
        mov eax, TotalFrameEntries
        mov ebx, SIZEOF FRAMEDATA
        mul ebx
        mov AllFramesDataSize, eax
      
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, AllFramesDataSize
        .IF eax == NULL
            .IF dwOpenMode == IEBAM_MODE_WRITE
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMFrameLookupPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF    
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMBlockEntriesPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMCycleEntriesPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMFrameEntriesPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
                mov ebx, hIEBAM
                mov eax, [ebx].BAMINFO.BAMHeaderPtr
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
            .ENDIF    
            Invoke GlobalFree, hIEBAM
            mov eax, NULL    
            ret
        .ENDIF
        mov ebx, hIEBAM
        mov [ebx].BAMINFO.BAMFrameDataEntriesPtr, eax
        mov FrameDataEntriesPtr, eax
        mov eax, AllFramesDataSize
        mov [ebx].BAMINFO.BAMFrameDataEntriesSize, eax

        mov eax, FrameEntriesPtr
        mov FrameEntryPtr, eax
        
        mov eax, FrameDataEntriesPtr
        mov FrameDataEntryPtr, eax
        
        mov nFrame, 0
        mov eax, 0
        .WHILE eax < TotalFrameEntries
            mov ebx, FrameEntryPtr
            movzx eax, word ptr [ebx].FRAMEV2_ENTRY.FrameWidth
            mov FrameWidth, eax
            movzx eax, word ptr [ebx].FRAMEV2_ENTRY.FrameHeight
            mov FrameHeight, eax
            movzx eax, word ptr [ebx].FRAMEV2_ENTRY.DataBlockIndex
            mov DataBlockIndex, eax
            movzx eax, word ptr [ebx].FRAMEV2_ENTRY.DataBlockCount
            mov DataBlockCount, eax
            
            ; calc dword aligned width and height
            Invoke BAMCalcDwordAligned, FrameWidth
            mov FrameWidthDwordAligned, eax
            
            Invoke BAMCalcDwordAligned, FrameHeight
            mov FrameHeightDwordAligned, eax

            mov FrameCompressed, -1 ; not applicable
            mov FrameSizeRLE, 0

            mov eax, FrameWidthDwordAligned
            mov ebx, FrameHeightDwordAligned
            mul ebx
            mov FrameSizeRAW, eax ; set max dword size for pvrz textures
            mov FrameSizeBMP, eax
            
            .IF FrameSizeRAW != 0
                Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, FrameSizeRAW
                mov FrameDataRawPtr, eax
            .ELSE
                mov FrameDataRawPtr, 0
            .ENDIF
            mov FrameDataRlePtr, 0

            .IF FrameSizeBMP != 0
                Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, FrameSizeBMP
                mov FrameDataBmpPtr, eax
            .ELSE
                mov FrameDataBmpPtr, 0
            .ENDIF

            ; calc offset to our frame data array, 
            mov ebx, FrameDataEntryPtr

            mov eax, FrameCompressed
            mov [ebx].FRAMEDATA.FrameCompressed, eax
            mov eax, FrameSizeRAW
            mov [ebx].FRAMEDATA.FrameSizeRAW, eax
            mov eax, FrameSizeRLE
            mov [ebx].FRAMEDATA.FrameSizeRLE, eax
            mov eax, FrameSizeBMP
            mov [ebx].FRAMEDATA.FrameSizeBMP, eax
            mov eax, FrameWidth
            mov [ebx].FRAMEDATA.FrameWidth, eax
            mov eax, FrameHeight
            mov [ebx].FRAMEDATA.FrameHeight, eax
            mov eax, FrameDataRawPtr
            mov [ebx].FRAMEDATA.FrameRAW, eax
            mov eax, FrameDataRlePtr
            mov [ebx].FRAMEDATA.FrameRLE, eax
            mov eax, FrameDataBmpPtr
            mov [ebx].FRAMEDATA.FrameBMP, eax
            mov eax, DataBlockIndex
            mov [ebx].FRAMEDATA.FrameDataBlockIndex, eax
            mov eax, DataBlockCount
            mov [ebx].FRAMEDATA.FrameDataBlockCount, eax
            
            add FrameEntryPtr, SIZEOF FRAMEV2_ENTRY
            add FrameDataEntryPtr, SIZEOF FRAMEDATA
            
            inc nFrame
            mov eax, nFrame
        .ENDW

    .ELSE
        mov ebx, hIEBAM
        mov [ebx].BAMINFO.BAMFrameDataEntriesPtr, 0
        mov [ebx].BAMINFO.BAMFrameDataEntriesSize, 0
    .ENDIF
    
    mov eax, hIEBAM 
    ret
BAMV2Mem ENDP


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; IEBAMHeader - Returns in eax a pointer to header or -1 if not valid
;-------------------------------------------------------------------------------------
IEBAMHeader PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMHeaderPtr
    ret
IEBAMHeader ENDP


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; IEBAMTotalFrameEntries - Returns in eax the total no of frame entries
;-------------------------------------------------------------------------------------
IEBAMTotalFrameEntries PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMVersion
    .IF eax == 2 ; BAM V2
        mov ebx, [ebx].BAMINFO.BAMHeaderPtr
        mov eax, [ebx].BAMV2_HEADER.FrameEntriesCount
    .ELSE
        mov ebx, [ebx].BAMINFO.BAMHeaderPtr
        movzx eax, word ptr [ebx].BAMV1_HEADER.FrameEntriesCount
    .ENDIF
    ret
IEBAMTotalFrameEntries ENDP


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; IEBAMTotalCycleEntries - Returns in eax the total no of cycle entries
;-------------------------------------------------------------------------------------
IEBAMTotalCycleEntries PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMVersion
    .IF eax == 2 ; BAM V2
        mov ebx, [ebx].BAMINFO.BAMHeaderPtr
        mov eax, [ebx].BAMV2_HEADER.CycleEntriesCount
    .ELSE
        mov ebx, [ebx].BAMINFO.BAMHeaderPtr
        movzx eax, byte ptr [ebx].BAMV1_HEADER.CycleEntriesCount
    .ENDIF
    ret
IEBAMTotalCycleEntries ENDP


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; IEBAMTotalBlockEntries - Returns in eax the total no of data block entries
;-------------------------------------------------------------------------------------
IEBAMTotalBlockEntries PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov ebx, [ebx].BAMINFO.BAMHeaderPtr
    mov eax, [ebx].BAMV2_HEADER.BlockEntriesCount
    ret
IEBAMTotalBlockEntries ENDP


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; IEBAMFrameEntries - Returns in eax a pointer to frame entries or -1 if not valid
;-------------------------------------------------------------------------------------
IEBAMFrameEntries PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMFrameEntriesPtr
    .IF eax == NULL
        mov eax, -1
    .ENDIF
    ret
IEBAMFrameEntries ENDP


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; IEBAMCycleEntries - Returns in eax a pointer to cycle entries or -1 if not valid
;-------------------------------------------------------------------------------------
IEBAMCycleEntries PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMCycleEntriesPtr
    .IF eax == NULL
        mov eax, -1
    .ENDIF    
    ret
IEBAMCycleEntries ENDP


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; IEBAMBlockEntries - Returns in eax a pointer to data block entries or -1 if not valid
;-------------------------------------------------------------------------------------
IEBAMBlockEntries PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMBlockEntriesPtr
    .IF eax == NULL
        mov eax, -1
    .ENDIF    
    ret
IEBAMBlockEntries ENDP


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; IEBAMFrameEntry - Returns in eax a pointer to the specified frame entry or -1 
;-------------------------------------------------------------------------------------
IEBAMFrameEntry PROC USES EBX hIEBAM:DWORD, nFrameEntry:DWORD
    LOCAL TotalFrameEntries:DWORD
    LOCAL FrameEntriesPtr:DWORD
    
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEBAMTotalFrameEntries, hIEBAM
    mov TotalFrameEntries, eax
    .IF TotalFrameEntries == 0
        mov eax, -1
        ret
    .ENDIF    

    mov eax, TotalFrameEntries
    .IF nFrameEntry >= eax
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEBAMFrameEntries, hIEBAM
    mov FrameEntriesPtr, eax
    .IF eax == -1
        ret
    .ENDIF    
    
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMVersion
    .IF eax == 2 ; BAM V2
        mov eax, nFrameEntry
        mov ebx, SIZEOF FRAMEV2_ENTRY
    .ELSE
        mov eax, nFrameEntry
        mov ebx, SIZEOF FRAMEV1_ENTRY
    .ENDIF
    mul ebx
    add eax, FrameEntriesPtr
    
    ret
IEBAMFrameEntry ENDP


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; IEBAMCycleEntry - Returns in eax a pointer to the specified cycle entry or -1 
;-------------------------------------------------------------------------------------
IEBAMCycleEntry PROC USES EBX hIEBAM:DWORD, nCycleEntry:DWORD
    LOCAL TotalCycleEntries:DWORD
    LOCAL CycleEntriesPtr:DWORD
    
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEBAMTotalCycleEntries, hIEBAM
    mov TotalCycleEntries, eax
    .IF TotalCycleEntries == 0
        mov eax, -1
        ret
    .ENDIF    

    mov eax, TotalCycleEntries
    .IF nCycleEntry >= eax
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEBAMCycleEntries, hIEBAM
    mov CycleEntriesPtr, eax
    .IF eax == -1
        ret
    .ENDIF    
    
    mov eax, nCycleEntry
    mov ebx, SIZEOF CYCLEV1_ENTRY
    mul ebx
    add eax, CycleEntriesPtr
    ret
IEBAMCycleEntry ENDP


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; IEBAMBlockEntry - Returns in eax a pointer to the specified Datablock entry or -1 
;-------------------------------------------------------------------------------------
IEBAMBlockEntry PROC USES EBX hIEBAM:DWORD, nBlockEntry:DWORD
    LOCAL TotalBlockEntries:DWORD
    LOCAL BlockEntriesPtr:DWORD
    
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEBAMTotalBlockEntries, hIEBAM
    mov TotalBlockEntries, eax
    .IF TotalBlockEntries == 0
        mov eax, -1
        ret
    .ENDIF    

    mov eax, TotalBlockEntries
    .IF nBlockEntry >= eax
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEBAMBlockEntries, hIEBAM
    mov BlockEntriesPtr, eax
    .IF eax == -1
        ret
    .ENDIF    
    
    mov eax, nBlockEntry
    mov ebx, SIZEOF DATABLOCK_ENTRY
    mul ebx
    add eax, BlockEntriesPtr
    ret
IEBAMBlockEntry ENDP


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; IEBAMPalette - Returns in eax a pointer to the palette or -1 if not valid
;-------------------------------------------------------------------------------------
IEBAMPalette PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMPalettePtr
    .IF eax == NULL
        mov eax, -1
    .ENDIF
    ret
IEBAMPalette ENDP


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; IEBAMFrameLookupEntries - Returns in eax a pointer to the frame lookup indexes or -1 if not valid
;-------------------------------------------------------------------------------------
IEBAMFrameLookupEntries PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMFrameLookupPtr
    .IF eax == 0
        mov eax, -1
    .ENDIF
    ret
IEBAMFrameLookupEntries ENDP


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; IEBAMFrameLookupEntry - Returns in eax a pointer to the frame lookup -1 if not valid
;-------------------------------------------------------------------------------------
IEBAMFrameLookupEntry PROC USES EBX hIEBAM:DWORD, nCycle:DWORD
    LOCAL FrameLookupEntries:DWORD
    LOCAL TotalCycleEntries:DWORD
    
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF

    Invoke IEBAMTotalCycleEntries, hIEBAM
    mov TotalCycleEntries, eax
    .IF TotalCycleEntries == 0
        mov eax, -1
        ret
    .ENDIF   
   
    Invoke IEBAMFrameLookupEntries, hIEBAM
    mov FrameLookupEntries, eax    
    .IF eax == -1
        ret
    .ENDIF

    mov eax, nCycle
    mov ebx, SIZEOF FRAMELOOKUPTABLE
    mul ebx
    add eax, FrameLookupEntries
    ret
IEBAMFrameLookupEntry ENDP


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; IEBAMFrameDataEntries - Returns in eax a pointer to the framedata entries or -1 if not valid
;-------------------------------------------------------------------------------------
IEBAMFrameDataEntries PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMFrameDataEntriesPtr
    .IF eax == NULL
        mov eax, -1
        ret
    .ENDIF    
    ret
IEBAMFrameDataEntries ENDP


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; IEBAMFrameDataEntry - returns in eax pointer to frame data or -1 if not found
;-------------------------------------------------------------------------------------
IEBAMFrameDataEntry PROC USES EBX hIEBAM:DWORD, nFrameEntry:DWORD
    LOCAL FrameDataEntriesPtr:DWORD
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEBAMFrameDataEntries, hIEBAM
    .IF eax == -1
        ret
    .ENDIF
    mov FrameDataEntriesPtr, eax
    
    mov eax, nFrameEntry
    mov ebx, SIZEOF FRAMEDATA
    mul ebx
    add eax, FrameDataEntriesPtr
    ret
IEBAMFrameDataEntry ENDP


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; IEBAMFileName - returns in eax pointer to zero terminated string contained filename that is open or -1 if not opened, 0 if in memory ?
;-------------------------------------------------------------------------------------
IEBAMFileName PROC USES EBX hIEBAM:DWORD
    LOCAL BamFilename:DWORD
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEBAM
    lea eax, [ebx].BAMINFO.BAMFilename
    mov BamFilename, eax
    Invoke szLen, BamFilename
    .IF eax == 0
        mov eax, -1
    .ELSE
        mov eax, BamFilename
    .ENDIF
    ret
IEBAMFileName endp


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; IEBAMFileNameOnly - returns in eax true or false if it managed to pass to the buffer pointed at lpszFileNameOnly, the stripped filename without extension
;-------------------------------------------------------------------------------------
IEBAMFileNameOnly PROC hIEBAM:DWORD, lpszFileNameOnly:DWORD
    Invoke IEBAMFileName, hIEBAM
    .IF eax == -1
        mov eax, FALSE
        ret
    .ENDIF
    
    Invoke BAMJustFname, eax, lpszFileNameOnly
    
    mov eax, TRUE
    ret
IEBAMFileNameOnly endp


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; IEBAMFileSize - returns in eax size of file or -1
;-------------------------------------------------------------------------------------
IEBAMFileSize PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMFilesize
    ret
IEBAMFileSize endp


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; -1 = No Bam file, TRUE for BAMCV1, FALSE for BAM V1 or BAM V2 
;-------------------------------------------------------------------------------------
IEBAMFileCompression PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMVersion
    .IF eax == 3
        mov eax, TRUE
    .ELSE
        mov eax, FALSE
    .ENDIF
    ret
IEBAMFileCompression endp


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; 0 = No Bam file, 1 = BAM V1, 2 = BAM V2, 3 = BAMCV1 
;-------------------------------------------------------------------------------------
IEBAMVersion PROC USES EBX hIEBAM:DWORD
    .IF hIEBAM == NULL
        mov eax, 0
        ret
    .ENDIF
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMVersion
    ret
IEBAMVersion ENDP


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; Unroll RLE compressed bam frame to RAW data
;-------------------------------------------------------------------------------------
IEBAMFrameUnRLE PROC USES EBX ECX EDX pFrameRLE:DWORD, pFrameRAW:DWORD, FrameRLESize:DWORD, FrameRAWSize:DWORD, FrameWidth:DWORD
    LOCAL FrameWidthDwordAligned:DWORD
    LOCAL pZeroExpandedRLE:DWORD
    LOCAL RLECurrentPos:DWORD
    LOCAL RAWCurrentPos:DWORD
    LOCAL ZEROCurrentPos:DWORD
    LOCAL ZeroCount:DWORD
    LOCAL ZeroTotal:DWORD
    LOCAL LastWidth:DWORD
    LOCAL ZeroSize:DWORD
    LOCAL FrameSize:DWORD
    LOCAL TotalBytesWritten:DWORD

    .IF pFrameRLE == NULL
        mov eax, -1
        ret
    .ENDIF
    
    .IF pFrameRAW == NULL
        mov eax, -1
        ret
    .ENDIF

    mov ZEROCurrentPos, 0
    mov RLECurrentPos, 0
    mov RAWCurrentPos, 0
    mov FrameSize, 0
    
    mov eax, 0
    .WHILE eax < FrameRLESize
        mov ebx, pFrameRLE
        add ebx, RLECurrentPos
        
        movzx eax, byte ptr [ebx]
        .IF al == 0h
            mov ecx, RLECurrentPos ; check not at end for next char
            inc ecx
            .IF ecx < FrameRLESize
                inc ebx
                movzx eax, byte ptr [ebx] ; al contains amount of 0's to copy
                inc eax ; for +1 count
                mov ZeroTotal, eax
                mov ZeroCount, 0
                mov eax, 0
                mov edx, pFrameRAW ;pZeroExpandedRLE
                add edx, RAWCurrentPos ;ZEROCurrentPos
                .WHILE eax < ZeroTotal
                    mov byte ptr [edx], 0h
                    inc edx
                    inc RAWCurrentPos ;ZEROCurrentPos
                    inc FrameSize ;ZeroSize
                    inc ZeroCount
                    mov eax, ZeroCount
                .ENDW
                inc RLECurrentPos
                inc RLECurrentPos

            .ELSE ; if this char is the last one and we have a 0 then just copy it
                mov edx, pFrameRAW ;pZeroExpandedRLE
                add edx, RAWCurrentPos ;ZEROCurrentPos
                mov byte ptr [edx], al
                inc RAWCurrentPos ;ZEROCurrentPos
                inc FrameSize ;ZeroSize
                inc RLECurrentPos
            .ENDIF
        .ELSE
            mov edx, pFrameRAW ;pZeroExpandedRLE
            add edx, RAWCurrentPos ;ZEROCurrentPos
            mov byte ptr [edx], al
            inc RAWCurrentPos ;ZEROCurrentPos
            inc FrameSize ;ZeroSize
            inc RLECurrentPos
        .ENDIF
    
        mov eax, RLECurrentPos
    .ENDW

    mov eax, FrameSize
    ret
IEBAMFrameUnRLE endp


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; Converts FrameRAW data to FrameBMP for use in bitmap creation
;-------------------------------------------------------------------------------------
IEBAMFrameRAWToFrameBMP PROC USES EBX ECX EDX pFrameRAW:DWORD, pFrameBMP:DWORD, FrameRAWSize:DWORD, FrameBMPSize:DWORD, FrameWidth:DWORD
    LOCAL TotalBytesWritten:DWORD
    LOCAL RAWCurrentPos:DWORD
    LOCAL BMPCurrentPos:DWORD
    LOCAL LastWidth:DWORD
    LOCAL FrameWidthDwordAligned:DWORD
    Invoke RtlZeroMemory, pFrameBMP, FrameBMPSize
    
    xor edx, edx
    mov eax, FrameWidth
    mov ecx, 4
    div ecx ;edx contains remainder
    .IF edx != 0
        mov eax, 4
        sub eax, edx
        add eax, FrameWidth
    .ELSE
        mov eax, FrameWidth
    .ENDIF    
    mov FrameWidthDwordAligned, eax

    mov TotalBytesWritten, 0
    mov RAWCurrentPos, 0
    mov eax, FrameRAWSize
    mov BMPCurrentPos, eax
    .WHILE eax > 0
        
        mov eax, BMPCurrentPos
        .IF eax < FrameWidth
            mov eax, FrameWidth
            mov ebx, BMPCurrentPos
            sub eax, ebx
            mov LastWidth, eax
            add TotalBytesWritten, eax
 
            mov ebx, pFrameRAW
            mov edx, pFrameBMP
            add edx, RAWCurrentPos
            Invoke RtlMoveMemory, edx, ebx, LastWidth
            .BREAK

        .ELSE
            mov ebx, pFrameRAW
            add ebx, BMPCurrentPos
            sub ebx, FrameWidth
            
            mov edx, pFrameBMP
            add edx, RAWCurrentPos
            
            Invoke RtlMoveMemory, edx, ebx, FrameWidth
            mov eax, FrameWidthDwordAligned
            add TotalBytesWritten, eax
            
            mov eax, RAWCurrentPos
            add eax, FrameWidthDwordAligned
            mov RAWCurrentPos, eax
            mov eax, BMPCurrentPos
            sub eax, FrameWidth
            mov BMPCurrentPos, eax
        .ENDIF
        
        mov eax, BMPCurrentPos
    .ENDW
    ret
IEBAMFrameRAWToFrameBMP endp


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; Gets handle to BAM Frame and returns it in eax as a bitmap handle or NULL otherwise
;-------------------------------------------------------------------------------------
IEBAMFrameBitmap PROC USES EBX hWin:DWORD, hIEBAM:DWORD, nFrame:DWORD
    LOCAL PalettePtr:DWORD
    LOCAL FrameDataOffset:DWORD
    LOCAL FrameDataBMP:DWORD
    LOCAL FrameWidth:DWORD
    LOCAL FrameHeight:DWORD
    LOCAL FrameSizeBMP:DWORD
    LOCAL FrameBitmapHandle:DWORD
    LOCAL hdc:HDC

    .IF hIEBAM == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEBAMTotalFrameEntries, hIEBAM
    .IF nFrame >= eax
        mov eax, NULL
        ret
    .ENDIF
    
    Invoke IEBAMFrameDataEntry, hIEBAM, nFrame
    .IF eax == NULL
        ret
    .ENDIF
    mov FrameDataOffset, eax

    mov ebx, FrameDataOffset
    mov eax, [EBX].FRAMEDATA.FrameSizeBMP
    mov FrameSizeBMP, eax
    mov eax, [EBX].FRAMEDATA.FrameWidth
    mov FrameWidth, eax
    mov eax, [EBX].FRAMEDATA.FrameHeight
    mov FrameHeight, eax
    mov eax, [EBX].FRAMEDATA.FrameBMP
    mov FrameDataBMP, eax

    Invoke IEBAMPalette, hIEBAM
    mov PalettePtr, eax

    ; fill bitmapinfoheader values
    lea ebx, BAMBMPInfo
    mov eax, FrameSizeBMP
    mov [ebx].BITMAPINFOHEADER.biSizeImage, eax        

    mov eax, FrameWidth
    mov [ebx].BITMAPINFOHEADER.biWidth, eax
    mov eax, FrameHeight
    mov [ebx].BITMAPINFOHEADER.biHeight, eax
    
    Invoke GetDC, hWin
    mov hdc, eax
    .IF hdc == NULL
        mov eax, NULL
        ret
    .ENDIF

    Invoke CreateDIBitmap, hdc, Addr BAMBMPInfo, CBM_INIT, FrameDataBMP, PalettePtr, DIB_RGB_COLORS  ;PalettePtr
    mov FrameBitmapHandle, eax

    Invoke ReleaseDC, hWin, hdc
    mov eax, FrameBitmapHandle
    ret
IEBAMFrameBitmap endp


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; Returns frame no for particular cycle and index into sequence
;-------------------------------------------------------------------------------------
IEBAMFrameLookupSequence PROC USES EBX hIEBAM:DWORD, nCycle:DWORD, CycleIndex:DWORD
    LOCAL FrameLookupOffset:DWORD
    LOCAL SequenceSize:DWORD
    LOCAL SequenceData:DWORD
    LOCAL Index:DWORD
    
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEBAMFrameLookupEntry, hIEBAM, nCycle
    .IF eax == -1
        ret
    .ENDIF
    mov FrameLookupOffset, eax
    
    mov ebx, FrameLookupOffset
    mov eax, [ebx].FRAMELOOKUPTABLE.SequenceSize
    mov SequenceSize, eax
    mov eax, [ebx].FRAMELOOKUPTABLE.SequenceData
    mov SequenceData, eax
    
    .IF SequenceSize > 0
        
        mov eax, CycleIndex
        shl eax, 1 ; x2
        mov Index, eax
    
        .IF eax >= SequenceSize
            mov eax, -1
            ret
        .ENDIF
        
        .IF SequenceData != NULL
            mov ebx, SequenceData
            add ebx, Index ; for dword array 
            movzx eax, word ptr [ebx]
        .ELSE
            mov eax, -1
        .ENDIF
    .ELSE
        mov eax, -1
    .ENDIF    
    ret
IEBAMFrameLookupSequence endp


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; Returns count of frames in particular cycle
;-------------------------------------------------------------------------------------
IEBAMCycleFrameCount PROC USES EBX hIEBAM:DWORD, nCycle:DWORD
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEBAMCycleEntry, hIEBAM, nCycle
    .IF eax == -1
        ret
    .ENDIF
    mov ebx, eax
    movzx eax, word ptr [ebx].CYCLEV1_ENTRY.CycleFrameCount
    ret
IEBAMCycleFrameCount endp


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; Returns in eax 0 if sucessful or -1 otherwise. On return lpdwFrameHeight and 
; lpdwFrameWidth will contain the values
;-------------------------------------------------------------------------------------
IEBAMFrameWidthHeight PROC USES EBX hIEBAM:DWORD, nFrame:DWORD, lpdwFrameWidth:DWORD, lpdwFrameHeight:DWORD
    LOCAL FrameEntryOffset:DWORD
    LOCAL FrameWidth:DWORD
    LOCAL FrameHeight:DWORD
    
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF

    Invoke IEBAMFrameEntry, hIEBAM, nFrame
    .IF eax == -1
        ret
    .ENDIF
    mov FrameEntryOffset, eax
    mov ebx, FrameEntryOffset
    
    movzx eax, word ptr [ebx].FRAMEV1_ENTRY.FrameWidth
    mov FrameWidth, eax
    movzx eax, word ptr [ebx].FRAMEV1_ENTRY.FrameHeight
    mov FrameHeight, eax
    
    .IF lpdwFrameWidth != NULL
        mov ebx, lpdwFrameWidth
        mov eax, FrameWidth
        mov [ebx], eax
    .ENDIF
    .IF lpdwFrameHeight != NULL
        mov ebx, lpdwFrameHeight
        mov eax, FrameHeight
        mov [ebx], eax
    .ENDIF
    
    mov eax, 0
    ret
IEBAMFrameWidthHeight ENDP


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Find the max width and height for all frames stored in bam. 0 success, -1 failure
;------------------------------------------------------------------------------
IEBAMFindMaxWidthHeight PROC USES EBX hIEBAM:DWORD, lpdwMaxWidth:DWORD, lpdwMaxHeight:DWORD
    LOCAL FrameEntries:DWORD
    LOCAL FrameEntryOffset:DWORD
    LOCAL MaxWidth:DWORD
    LOCAL MaxHeight:DWORD
    LOCAL nFrame:DWORD
    LOCAL TotalFrameEntries:DWORD
    
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEBAMTotalFrameEntries, hIEBAM
    .IF eax == 0
        mov eax, -1
        ret
    .ENDIF
    mov TotalFrameEntries, eax
    
    Invoke IEBAMFrameEntries, hIEBAM
    .IF eax == -1
        ret
    .ENDIF
    mov FrameEntries, eax
    mov FrameEntryOffset, eax

    mov MaxWidth, 0
    mov MaxHeight, 0
    mov nFrame, 0

    mov eax, 0
    .WHILE eax < TotalFrameEntries
        mov ebx, FrameEntryOffset
        
        movzx eax, word ptr [ebx].FRAMEV1_ENTRY.FrameWidth
        .IF eax > MaxWidth
            mov MaxWidth, eax
        .ENDIF
        movzx eax, word ptr [ebx].FRAMEV1_ENTRY.FrameHeight
        .IF eax > MaxHeight
            mov MaxHeight, eax
        .ENDIF

        add FrameEntryOffset, SIZEOF FRAMEV1_ENTRY
        
        inc nFrame
        mov eax, nFrame
    .ENDW    
    
    mov ebx, lpdwMaxWidth
    mov eax, MaxWidth
    mov [ebx], eax
    
    mov ebx, lpdwMaxHeight
    mov eax, MaxHeight
    mov [ebx], eax
    
    mov eax, 0    
    ret

IEBAMFindMaxWidthHeight endp


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; Returns in eax pointer to palette RGBAQUAD entry, or -1 otherwise
;-------------------------------------------------------------------------------------
IEBAMPaletteEntry PROC USES EBX hIEBAM:DWORD, PaletteIndex:DWORD
    LOCAL PaletteOffset:DWORD

    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    
    .IF PaletteIndex > 255
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEBAMPalette, hIEBAM
    .IF eax == -1
        ret
    .ENDIF
    mov PaletteOffset, eax
    
    mov eax, PaletteIndex
    mov ebx, 4 ; dword RGBA array size
    mul ebx
    add eax, PaletteOffset
    ret
IEBAMPaletteEntry endp


IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; Returns in eax ColorRef of the RLEColorIndex or -1 otherwise
;-------------------------------------------------------------------------------------
IEBAMRLEColorIndexColorRef PROC USES EBX hIEBAM
    LOCAL BamHeaderPtr:DWORD
    LOCAL RLEColorIndex:DWORD
    LOCAL ABGR:DWORD
    
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEBAMHeader, hIEBAM
    .IF eax == -1
        ret
    .ENDIF
    mov BamHeaderPtr, eax
    mov ebx, BamHeaderPtr
    
    movzx eax, byte ptr [ebx].BAMV1_HEADER.ColorIndexRLE
    mov RLEColorIndex, eax
    
    Invoke IEBAMPaletteEntry, hIEBAM, RLEColorIndex
    mov ebx, [eax]
    mov ABGR, ebx
    
    Invoke IEBAMConvertABGRtoARGB, ABGR
    AND eax, 00FFFFFFh ; to mask off alpha
    ret
IEBAMRLEColorIndexColorRef endp


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Convert to RGB ColorRef (ARGB) format from RGBQUAD (BGRA) Returns Alpha as well
; to mask off use AND, 00FFFFFFh for just RGB.
;------------------------------------------------------------------------------
IEBAMConvertABGRtoARGB PROC USES EBX dwBGRA:DWORD
    LOCAL clrRed:DWORD
    LOCAL clrGreen:DWORD
    LOCAL clrBlue:DWORD
    LOCAL clrAlpha:DWORD
    
    xor eax, eax
    mov eax, dwBGRA ; stored in reverse format ARGB in memory

    xor ebx, ebx
    mov bl, al
    mov clrBlue, ebx
    xor ebx, ebx
    mov bl, ah
    mov clrGreen, ebx

    shr eax, 16d

    xor ebx, ebx
    mov bl, al
    mov clrRed, ebx
    xor ebx, ebx
    mov bl, ah
    mov clrAlpha, ebx

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
    ; eax contains ARGB
    ret
IEBAMConvertABGRtoARGB ENDP


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Convert to RGBQUAD (BGRA) format from RGB ColorRef (ARGB)
;------------------------------------------------------------------------------
IEBAMConvertARGBtoABGR PROC USES EBX dwARGB:DWORD
    LOCAL clrRed:DWORD
    LOCAL clrGreen:DWORD
    LOCAL clrBlue:DWORD
    LOCAL clrAlpha:DWORD
    
    xor eax, eax
    mov eax, dwARGB

    xor ebx, ebx
    mov bl, al
    mov clrRed, ebx
    xor ebx, ebx
    mov bl, ah
    mov clrGreen, ebx

    shr eax, 16d

    xor ebx, ebx
    mov bl, al
    mov clrBlue, ebx
    xor ebx, ebx
    mov bl, ah
    mov clrAlpha, ebx

    xor eax, eax
    xor ebx, ebx
    mov eax, clrAlpha
    mov ebx, clrRed
    shl eax, 8d
    mov al, bl
    shl eax, 16d ; alpha and red in upper dword
    mov ebx, clrGreen
    mov ah, bl
    mov ebx, clrBlue
    mov al, bl
    ; eax contains BGRA - RGBQUAD
    ret
IEBAMConvertARGBtoABGR ENDP


IEBAM_ALIGN
;-----------------------------------------------------------------------------------------
; Checks the BAM signatures to determine if they are valid and if BAM file is compressed
;-----------------------------------------------------------------------------------------
BAMSignature PROC pBAM:DWORD
    ; check signatures to determine version
    mov ebx, pBAM
    mov eax, [ebx]
    .IF eax == ' MAB' ; BAM
        add ebx, 4
        mov eax, [ebx]
        .IF eax == '  1V' ; V1.0
            mov eax, BAM_VERSION_BAM_V10
        .ELSEIF eax == '  2V' ; V2.0
            mov eax, BAM_VERSION_BAM_V20
        .ELSE
            mov eax, BAM_VERSION_INVALID
        .ENDIF

    .ELSEIF eax == 'CMAB' ; BAMC
        add ebx, 4
        mov eax, [ebx]
        .IF eax == '  1V' ; V1.0
            mov eax, BAM_VERSION_BAMCV10
        .ELSE
            mov eax, BAM_VERSION_INVALID
        .ENDIF            
    .ELSE
        mov eax, BAM_VERSION_INVALID
    .ENDIF
    ret
BAMSignature endp


IEBAM_ALIGN
;-----------------------------------------------------------------------------------------
; Uncompresses BAMC file to an area of memory that we allocate for the exact size of data
;-----------------------------------------------------------------------------------------
BAMUncompress PROC PRIVATE USES EBX hBAMFile:DWORD, pBAM:DWORD, dwSize:DWORD
    LOCAL dest:DWORD
    LOCAL src:DWORD
    LOCAL BAMU_Size:DWORD
    LOCAL BytesRead:DWORD
    LOCAL BAMFilesize:DWORD
    LOCAL BAMC_UncompressedSize:DWORD
    LOCAL BAMC_CompressedSize:DWORD
    
    Invoke GetFileSize, hBAMFile, NULL
    mov BAMFilesize, eax
    mov ebx, pBAM
    mov eax, [ebx].BAMC_HEADER.UncompressedLength
    mov BAMC_UncompressedSize, eax
    mov eax, BAMFilesize
    sub eax, 0Ch ; take away the BAMC header 12 bytes = 0xC
    mov BAMC_CompressedSize, eax ; set correct compressed size = length of file minus BAMC header length

    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, BAMC_UncompressedSize
    .IF eax != NULL
        mov dest, eax
        mov eax, pBAM ;BAMMemMapPtr
        add eax, 0Ch ; add BAMC Header to Memory map to start at correct offset for uncompressing
        mov src, eax
        Invoke uncompress, dest, Addr BAMC_UncompressedSize, src, BAMC_CompressedSize
        .IF eax == Z_OK ; ok
            mov eax, BAMC_UncompressedSize
            mov ebx, dwSize
            mov [ebx], eax
        
            mov eax, dest
            ret
        .ENDIF
    .ENDIF                  
    mov eax, 0        
    ret
BAMUncompress endp


IEBAM_ALIGN
;**************************************************************************
; Strip path name to just filename Without extention
;**************************************************************************
BAMJustFname PROC szFilePathName:DWORD, szFileName:DWORD
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
BAMJustFname ENDP


IEBAM_ALIGN
;**************************************************************************
; Calc dword aligned size for height or width value
;**************************************************************************
BAMCalcDwordAligned PROC USES EDX dwWidthOrHeight:DWORD
    .IF dwWidthOrHeight == 0
        mov eax, 0
        ret
    .ENDIF
    
    xor edx, edx
    mov eax, dwWidthOrHeight
    mov ecx, 4
    div ecx ;edx contains remainder
    .IF edx != 0
        mov eax, 4
        sub eax, edx
        add eax, dwWidthOrHeight
    .ELSE
        mov eax, dwWidthOrHeight
    .ENDIF
    ; eax contains dword aligned value   
    ret
BAMCalcDwordAligned endp





















;;-----------------------------------------------------------------------------------------
;; _GetFrameDataOffset
;;-----------------------------------------------------------------------------------------
;_GetFrameDataOffset PROC PRIVATE USES EBX hIEBAM:DWORD, nFrame:DWORD
;    LOCAL FrameEntriesPtr:DWORD
;    
;    _GetFrameEntriesPtr hIEBAM
;    mov FrameEntriesPtr, eax
;    
;    mov eax, nFrame
;    mov ebx, SIZEOF FRAMEV1_ENTRY
;    mul ebx
;    add eax, FrameEntriesPtr
;    mov ebx, eax
;    
;    mov eax, [ebx].FRAMEV1_ENTRY.FrameInfo
;    AND eax, 7FFFFFFFh ; mask for offset to frame data
;    ret
;
;_GetFrameDataOffset ENDP
;
;;-----------------------------------------------------------------------------------------
;; _GetFrameDataRLE
;;-----------------------------------------------------------------------------------------
;_GetFrameDataRLE PROC PRIVATE USES EBX hIEBAM:DWORD, nFrame:DWORD
;    LOCAL FrameEntriesPtr:DWORD
;    
;    _GetFrameEntriesPtr hIEBAM
;    mov FrameEntriesPtr, eax
;    
;    mov eax, nFrame
;    mov ebx, SIZEOF FRAMEV1_ENTRY
;    mul ebx
;    add eax, FrameEntriesPtr
;    mov ebx, eax
;    
;    mov eax, [ebx].FRAMEV1_ENTRY.FrameInfo
;    AND eax, 80000000h ; mask for compression bit
;    ret
;
;_GetFrameDataRLE ENDP











END
