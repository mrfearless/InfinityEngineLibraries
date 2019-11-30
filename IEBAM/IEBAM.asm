;==============================================================================
;
; IEBAM
;
; Copyright (c) 2019 by fearless
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

includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib


;DEBUG32 EQU 1
;IFDEF DEBUG32
;    PRESERVEXMMREGS equ 1
;    includelib M:\Masm32\lib\Debug32.lib
;    DBG32LIB equ 1
;    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
;    include M:\Masm32\include\debug32.inc
;ENDIF

include IEBAM.inc

; Internal functions start with BAM
; External functions start with IEBAM

;------------------------------------------------------------------------------
; Internal functions:
;------------------------------------------------------------------------------
BAMSignature              PROTO pBAM:DWORD
BAMUncompress             PROTO hBAMFile:DWORD, pBAM:DWORD, dwSize:DWORD
BAMJustFname              PROTO szFilePathName:DWORD, szFileName:DWORD

BAMV1Mem                  PROTO pBAMInMemory:DWORD, lpszBamFilename:DWORD, dwBamFilesize:DWORD, dwOpenMode:DWORD
BAMV2Mem                  PROTO pBAMInMemory:DWORD, lpszBamFilename:DWORD, dwBamFilesize:DWORD, dwOpenMode:DWORD

BAMCalcDwordAligned       PROTO dwWidthOrHeight:DWORD
BAMFrameDataBitmap        PROTO dwFrameWidth:DWORD, dwFrameHeight:DWORD, pFrameBMP:DWORD, dwFrameSizeBMP:DWORD, pFramePalette:DWORD

BAMFrameUnRLESize         PROTO pFrameRLE:DWORD, FrameRLESize:DWORD
BAMFrameUnRLE             PROTO pFrameRLE:DWORD, FrameRLESize:DWORD, pFrameRAW:DWORD, FrameRAWSize:DWORD

BAMFrameRAWToFrameBMP      PROTO pFrameRAW:DWORD, pFrameBMP:DWORD, FrameRAWSize:DWORD, FrameBMPSize:DWORD, FrameWidth:DWORD




.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMOpen - Returns handle in eax of opened bam file. NULL if could not alloc enough mem
;------------------------------------------------------------------------------
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
        mov eax, NULL
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
        Invoke CloseHandle, hBAMFile
        mov eax, NULL
        ret
    .ENDIF
    mov BAMMemMapHandle, eax
    
    .IF dwOpenMode == IEBAM_MODE_READONLY ; readonly
        Invoke MapViewOfFileEx, BAMMemMapHandle, FILE_MAP_READ, 0, 0, 0, NULL
    .ELSE
        Invoke MapViewOfFileEx, BAMMemMapHandle, FILE_MAP_ALL_ACCESS, 0, 0, 0, NULL
    .ENDIF
    .IF eax == NULL
        Invoke CloseHandle, BAMMemMapHandle
        Invoke CloseHandle, hBAMFile
        mov eax, NULL
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
            ;Invoke UnmapViewOfFile, BAMMemMapPtr
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
    ; save original version to handle for later use so we know if orignal file opened was standard BAM or a compressed BAMC file, if 0 then it was in mem so we assume BAM
    mov ebx, hIEBAM
    mov eax, SigReturn
    mov [ebx].BAMINFO.BAMVersion, eax
    mov eax, hIEBAM
    ret
IEBAMOpen ENDP


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMClose - Close BAM File
;------------------------------------------------------------------------------
IEBAMClose PROC USES EBX hIEBAM:DWORD
    LOCAL FrameDataEntriesPtr:DWORD
    LOCAL FrameDataOffset:DWORD
    LOCAL FrameLookupEntriesPtr:DWORD
    LOCAL FrameLookupOffset:DWORD
    LOCAL TotalFrames:DWORD
    LOCAL TotalCycles:DWORD
    LOCAL nFrame:DWORD
    LOCAL nCycle:DWORD
    LOCAL dwOpenMode:DWORD
    
    .IF hIEBAM == NULL
        mov eax, 0
        ret
    .ENDIF
    
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMOpenMode
    mov dwOpenMode, eax
    
    Invoke IEBAMTotalFrameEntries, hIEBAM
    mov TotalFrames, eax

    Invoke IEBAMTotalCycleEntries, hIEBAM
    mov TotalCycles, eax
    
    ;PrintText 'clear mem for allocd cycle sequence lookups'
    ; clear mem for alloc'd cycle sequence lookups, and clear mem for the whole lookup data structure
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMFrameLookupPtr
    .IF eax != NULL
        mov FrameLookupEntriesPtr, eax
        mov FrameLookupOffset, eax

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

    ;PrintText 'clear mem for BAMFrameLookupPtr'
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMFrameLookupPtr   
    .IF eax != NULL
        Invoke GlobalFree, eax
    .ENDIF
    
    ;PrintText 'clear mem allocd frames'
    ; clear mem for alloc'd frames, delete handle to bitmaps for each frame if there is one and clear mem for the whole frame data structure
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMFrameDataEntriesPtr
    .IF eax != NULL
        mov FrameDataEntriesPtr, eax
        mov FrameDataOffset, eax

        mov nFrame, 0
        mov eax, 0
        .WHILE eax < TotalFrames
            .IF dwOpenMode == IEBAM_MODE_WRITE
                ;PrintText 'clear FrameRAW'
                mov ebx, FrameDataOffset
                mov eax, [ebx].FRAMEDATA.FrameRAW
                .IF eax != NULL
                    Invoke GlobalFree, eax
                .ENDIF
            .ENDIF
            ;PrintText 'clear FrameRLE'
            mov ebx, FrameDataOffset
            mov eax, [ebx].FRAMEDATA.FrameRLE
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF
            ;PrintText 'clear FrameBitmapHandle'
            mov ebx, FrameDataOffset
            mov eax, [ebx].FRAMEDATA.FrameBitmapHandle
            .IF eax != NULL
                Invoke DeleteObject, eax
            .ENDIF
            ;PrintText 'clear FrameBMP'
            mov ebx, FrameDataOffset
            mov eax, [ebx].FRAMEDATA.FrameBMP
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF
            
            add FrameDataOffset, SIZEOF FRAMEDATA
            inc nFrame
            mov eax, nFrame
        .ENDW
        ;PrintText 'finished frame data clearing'
    .ENDIF
    
    ;PrintText 'clear mem BAMFrameDataEntriesPtr'
    mov ebx, hIEBAM
    mov eax, [ebx].BAMINFO.BAMFrameDataEntriesPtr
    .IF eax != NULL
        Invoke GlobalFree, eax
    .ENDIF

    .IF dwOpenMode == IEBAM_MODE_WRITE ; Write Mode
        ;PrintText 'clear mem headers'
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
    ;PrintDec eax
    .IF eax == BAM_VERSION_BAMCV10 ; BAMC in read or write mode uncompresed bam in memory needs to be cleared
        ;PrintText 'BAM_VERSION_BAMCV10'
        mov ebx, hIEBAM
        mov eax, [ebx].BAMINFO.BAMMemMapPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
    
    .ELSE ; BAM V1 or BAM V2 so if  opened in readonly, unmap file etc, otherwise free mem
        ;PrintText 'BAM V1 or BAM V2'
        .IF dwOpenMode == IEBAM_MODE_READONLY ; Read Only
            
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
    
    ;PrintText 'Final GlobalFree'
    mov eax, hIEBAM
    .IF eax != NULL
        Invoke GlobalFree, eax
    .ENDIF

    mov eax, 0
    ret
IEBAMClose ENDP


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMMem - Returns handle in eax of opened bam file that is already loaded into memory. NULL if could not alloc enough mem
; calls BAMV1Mem or BAMV2Mem depending on version of file found
;------------------------------------------------------------------------------
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
;------------------------------------------------------------------------------
; BAMV1Mem - Returns handle in eax of opened bam file that is already loaded into memory. NULL if could not alloc enough mem
;------------------------------------------------------------------------------
BAMV1Mem PROC USES EBX pBAMInMemory:DWORD, lpszBamFilename:DWORD, dwBamFilesize:DWORD, dwOpenMode:DWORD
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
    LOCAL FrameXcoord:DWORD
    LOCAL FrameYcoord:DWORD
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
    Invoke lstrcpyn, eax, lpszBamFilename, MAX_PATH
    ;Invoke szCopy, lpszBamFilename, eax
    
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

;    ;----------------------------------
;    ; Double check file in mem is BAM
;    ;----------------------------------
;    Invoke RtlZeroMemory, Addr BAMXHeader, SIZEOF BAMXHeader
;    Invoke RtlMoveMemory, Addr BAMXHeader, BAMMemMapPtr, 8d
;    Invoke szCmp, Addr BAMXHeader, Addr BAMV1Header
;    .IF eax == 0 ; no match    
;        mov ebx, hIEBAM
;        mov eax, [ebx].BAMINFO.BAMHeaderPtr
;        .IF eax != NULL
;            Invoke GlobalFree, eax
;        .ENDIF
;        Invoke GlobalFree, hIEBAM
;        mov eax, NULL    
;        ret
;    .ENDIF

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
    ;Invoke RtlMoveMemory, Addr BAMBMPPalette, PalettePtr, 1024    
    
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
                .IF eax == NULL
                    ret
                .ENDIF
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
            movzx eax, word ptr [ebx].FRAMEV1_ENTRY.FrameXcoord
            mov FrameXcoord, eax
            movzx eax, word ptr [ebx].FRAMEV1_ENTRY.FrameYcoord
            mov FrameYcoord, eax
            mov eax, [ebx].FRAMEV1_ENTRY.FrameInfo
            mov FrameInfo, eax

            .IF FrameWidth != 0 && FrameHeight != 0
                Invoke BAMCalcDwordAligned, FrameWidth
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
            
            IFDEF DEBUG32
            .IF nFrame == 97
                PrintText '-------------'
                PrintDec nFrame
                PrintDec FrameWidth
                PrintDec FrameHeight
                PrintDec FrameWidthDwordAligned
                PrintDec FrameSizeRAW
                PrintDec FrameSizeRLE
                PrintDec FrameSizeBMP
            .ENDIF
            ENDIF
            
            
            .IF FrameSizeRAW != 0
                mov eax, FrameSizeRAW
                add eax, 4d ; extra margin for overread
                Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, eax ;FrameSizeRAW
                mov FrameDataRawPtr, eax
            .ELSE
                mov FrameDataRawPtr, 0
            .ENDIF
            .IF FrameSizeRLE != 0
                mov eax, FrameSizeRLE
                add eax, 4d ; extra margin for overread
                Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, eax ;FrameSizeRLE
                mov FrameDataRlePtr, eax
            .ELSE
                mov FrameDataRlePtr, 0
            .ENDIF
            .IF FrameSizeBMP != 0
                mov eax, FrameSizeBMP
                add eax, 1024d 
                ; added for bad BAMC compressed rle bam frames: sphorpuf.bam frame 97 etc - to prevent stack/heap corruption 0xc0000374 on exit
                ; classic sphorpuf.bam seems to be issue, EE version is different - resized (and doesnt crash)
                Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, eax ;FrameSizeBMP
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
            mov eax, FrameXcoord
            mov [ebx].FRAMEDATA.FrameXcoord, eax
            mov eax, FrameYcoord
            mov [ebx].FRAMEDATA.FrameYcoord, eax
            mov eax, FrameDataRawPtr
            mov [ebx].FRAMEDATA.FrameRAW, eax
            mov eax, FrameDataRlePtr
            mov [ebx].FRAMEDATA.FrameRLE, eax
            mov eax, FrameDataBmpPtr
            mov [ebx].FRAMEDATA.FrameBMP, eax
            
            mov eax, BAMMemMapPtr
            add eax, FrameDataOffset
            .IF FrameCompressed == 1 ; uncompressed
                ;PrintText 'uncompressed frame'
                .IF FrameDataRawPtr != 0
                    Invoke RtlMoveMemory, FrameDataRawPtr, eax, FrameSizeRAW
                .ENDIF
                Invoke BAMFrameRAWToFrameBMP, FrameDataRawPtr, FrameDataBmpPtr, FrameSizeRAW, FrameSizeBMP, FrameWidth

            .ELSE ; compressed
                Invoke RtlMoveMemory, FrameDataRlePtr, eax, FrameSizeRLE
                mov eax, FrameSizeRLE
                .IF eax == FrameSizeRAW ; already uncompressed so just copy memory
                    ;PrintText 'compressed - already uncompressed frame'
                    Invoke RtlMoveMemory, FrameDataRawPtr, FrameDataRlePtr, FrameSizeRLE
                    Invoke RtlMoveMemory, FrameDataBmpPtr, FrameDataRlePtr, FrameSizeRLE
                
                .ELSEIF eax > FrameSizeRAW ; invalid bam, copy last bam frame to this
                    ;PrintText 'compressed - invalid bam'
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
                        mov eax, [ebx].FRAMEDATA.FrameXcoord
                        mov FrameXcoord, eax
                        mov eax, [ebx].FRAMEDATA.FrameYcoord
                        mov FrameYcoord, eax
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
                    ;PrintText 'compressed - unRLE bam'
                    IFDEF DEBUG32
                    .IF nFrame == 97
                        DbgDump FrameDataRlePtr, FrameSizeRLE
                    .ENDIF
                    ENDIF
                    
;                    Invoke BAMFrameUnRLESize, FrameDataRlePtr, FrameSizeRLE
;                    .IF eax > FrameSizeRAW ; resize buffers for unrle and raw to bmp
;                        mov FrameSizeRAW, eax
;                        IFDEF DEBUG32
;                        PrintText 'resizing raw buffer!'
;                        ENDIF
;                        mov eax, FrameDataRawPtr
;                        .IF eax != 0
;                            Invoke GlobalFree, eax
;                        .ENDIF
;                        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, FrameSizeRAW
;                        mov FrameDataRawPtr, eax
;                        
;                        mov ebx, FrameDataEntryPtr
;                        mov eax, FrameDataRawPtr
;                        mov [ebx].FRAMEDATA.FrameRAW, eax
;                        mov eax, FrameSizeRAW
;                        mov [ebx].FRAMEDATA.FrameSizeRAW, eax 
;                        
;                        Invoke BAMFrameUnRLE, FrameDataRlePtr, FrameSizeRLE, FrameDataRawPtr
;                        
;                        ;Invoke RtlMoveMemory, FrameDataBmpPtr, FrameDataRawPtr, FrameSizeRAW
;                        Invoke BAMFrameRAWToFrameBMP, FrameDataRawPtr, FrameDataBmpPtr, FrameSizeRAW, FrameSizeBMP, FrameWidth
;                        
;                    .ELSE
                        
                        Invoke BAMFrameUnRLE, FrameDataRlePtr, FrameSizeRLE, FrameDataRawPtr, FrameSizeRAW ;, FrameWidth ; unRLE compressed frame
                        mov FrameSizeRAW, eax
                        IFDEF DEBUG32
                        .IF nFrame == 97
                            PrintText 'New size: '
                            PrintDec FrameSizeRAW
                        .ENDIF
                        ENDIF
                        mov ebx, FrameDataEntryPtr
                        mov [ebx].FRAMEDATA.FrameSizeRAW, eax ; put correct raw size here
                        
                        Invoke BAMFrameRAWToFrameBMP, FrameDataRawPtr, FrameDataBmpPtr, FrameSizeRAW, FrameSizeBMP, FrameWidth
;                    .ENDIF
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
;------------------------------------------------------------------------------
; BAMV2Mem - Returns handle in eax of opened bam file that is already loaded into memory. NULL if could not alloc enough mem
;------------------------------------------------------------------------------
BAMV2Mem PROC USES EBX pBAMInMemory:DWORD, lpszBamFilename:DWORD, dwBamFilesize:DWORD, dwOpenMode:DWORD
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
    LOCAL FrameXcoord:DWORD
    LOCAL FrameYcoord:DWORD
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
    Invoke lstrcpyn, eax, lpszBamFilename, MAX_PATH
    ;Invoke lstrcpy, eax, lpszBamFilename
    ;Invoke szCopy, lpszBamFilename, eax
    
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
            movzx eax, word ptr [ebx].FRAMEV2_ENTRY.FrameXcoord
            mov FrameXcoord, eax
            movzx eax, word ptr [ebx].FRAMEV2_ENTRY.FrameYcoord
            mov FrameYcoord, eax
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
            mov eax, FrameXcoord
            mov [ebx].FRAMEDATA.FrameXcoord, eax
            mov eax, FrameYcoord
            mov [ebx].FRAMEDATA.FrameYcoord, eax
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




IEBAM_LIBEND

