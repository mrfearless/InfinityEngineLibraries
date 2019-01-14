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


;-----------------------------------------------------------------------------------------
; IEBAM Prototypes
;-----------------------------------------------------------------------------------------
IEBAMOpen                   PROTO :DWORD, :DWORD            ; lpszBamFilename, dwOpenMode. Returns in eax a handle used in other functions: hIEBAM
IEBAMMem                    PROTO :DWORD, :DWORD, :DWORD, :DWORD ; pBAMInMemory, lpszBamFilename, dwBamFilesize, dwOpenMode. Returns in eax a handle used in other functions: hIEBAM
IEBAMClose                  PROTO :DWORD                    ; hIEBAM returned from IEBAMOpen.

;-----------------------------------------------------------------------------------------
; Functions for returning pointers to internal bam structure areas of interest
IEBAMHeader                 PROTO :DWORD                    ; hIEBAM. Returns in eax pointer to a BAMV1_HEADER structure.
IEBAMFrameEntry             PROTO :DWORD, :DWORD            ; hIEBAM, nFrameEntry. Returns in eax pointer to a FRAMEV1_ENTRY or FRAMEV2_ENTRY structure.
IEBAMCycleEntry             PROTO :DWORD, :DWORD            ; hIEBAM, nCycleEntry. Returns in eax pointer to a CYCLEV1_ENTRY or CYCLEV2_ENTRY structure.
IEBAMBlockEntry             PROTO :DWORD, :DWORD            ; hIEBAM, nBlockEntry. Returns in eax pointer to a DATABLOCK_ENTRY structure. For BAM V2 Only

IEBAMFrameEntries           PROTO :DWORD                    ; hIEBAM. Returns in eax pointer to Frame Entries
IEBAMCycleEntries           PROTO :DWORD                    ; hIEBAM. Returns in eax pointer to Cycle Entries
IEBAMBlockEntries           PROTO :DWORD                    ; hIEBAM. Returns in eax pointer to Datablock Entries. For BAM V2 Only

IEBAMFrameDataEntries       PROTO :DWORD                    ; hIEBAM. Returns in eax pointer to FrameData Entries
IEBAMFrameDataEntry         PROTO :DWORD, :DWORD            ; hIEBAM, nFrameEntry. Returns in eax pointer to frame data

IEBAMFrameLookupEntry       PROTO :DWORD, :DWORD            ; hIEBAM, nCycleEntry. Returns in eax frame lookup 
IEBAMFrameLookupEntries     PROTO :DWORD                    ; hIEBAM. Returns in eax pointer to the frame lookup indexes

IEBAMPalette                PROTO :DWORD                    ; hIEBAM. Returns in eax pointer to the palette of 256 x RQBQUADs
IEBAMPaletteEntry           PROTO :DWORD, :DWORD            ; hIEBAM, PaletteIndex. Returns in eax pointer to RGBAQUAD for index 0-255 (256 entries) or NULL if unsuccessful


; Bam file information
IEBAMTotalFrameEntries      PROTO :DWORD                    ; hIEBAM. Returns in eax total no of Frame entries.
IEBAMTotalCycleEntries      PROTO :DWORD                    ; hIEBAM. Returns in eax total no of Cycle entries.
IEBAMTotalBlockEntries      PROTO :DWORD                    ; hIEBAM. Returns in eax total no of Datablock entries. For BAM V2 Only

IEBAMFileName               PROTO :DWORD                    ; hIEBAM. Returns in eax pointer to bam full path filename
IEBAMFileNameOnly           PROTO :DWORD, :DWORD            ; hIEBAM, lpszFileNameOnly. eax contains True or false if succesfull. strips filename of path and ext information.
IEBAMFileSize               PROTO :DWORD                    ; hIEBAM. Returns in eax size of bam file in bytes
IEBAMFileCompression        PROTO :DWORD                    ; hIEBAM. Returns in eax -1 = No Bam file, TRUE for BAMCV1, FALSE for BAM V1 or BAM V2 
IEBAMVersion                PROTO :DWORD                    ; hIEBAM. Returns in eax 0 no bam, 1 = BAM V1, 2 = BAM V2, 3 = BAMC 


IEBAMFrameUnRLE             PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
IEBAMFrameRAWToFrameBMP     PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
IEBAMFrameBitmap            PROTO :DWORD, :DWORD, :DWORD    ; hWin, hIEBAM, nFrame. Returns in eax handle to bitmap of frame data or NULL
IEBAMFrameLookupSequence    PROTO :DWORD, :DWORD, :DWORD    ; hIEBAM, nCycle, SequenceIndex. Returns frame no in eax or -1 otherwise
IEBAMCycleFrameCount        PROTO :DWORD, :DWORD            ; hIEBAM, nCycle. Returns frame count for cycle in eax or 0 otherwise
IEBAMFrameWidthHeight       PROTO :DWORD, :DWORD, :DWORD, :DWORD ; hIEBAM, nFrame, lpdwFrameWidth, lpdwFrameHeight. Returns in eax TRUE if succesful or FALSE otherwise. lpdwX contain values
IEBAMFindMaxWidthHeight     PROTO :DWORD, :DWORD, :DWORD    ; hIEBAM, lpdwFrameWidth, lpdwFrameHeight. Returns in eax TRUE if succesful or FALSE otherwise. lpdwX contain max values on success


IEBAMRLEColorIndexColorRef  PROTO :DWORD                    ; hIEBAM. Returns in eax ColorRef RGB of RLEColorIndex.
IEBAMConvertABGRtoARGB      PROTO :DWORD                    ; hIEBAM, ABGR. Returns ColorRef RGB in eax
IEBAMConvertARGBtoABGR      PROTO :DWORD                    ; hIEBAM, ARGB. Returns RGBQUAD (ABGR) in eax

;-----------------------------------------------------------------------------------------
; IEBAM Structures
;-----------------------------------------------------------------------------------------

IFNDEF BAMV1_HEADER
BAMV1_HEADER            STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('BAM ')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V1 ')
    FrameEntriesCount   DW 0 ; 0x0008   2 (word)        Count of frames
    CycleEntriesCount   DB 0 ; 0x000a   1 (byte)        Count of cycles
    ColorIndexRLE       DB 0 ; 0x000b   1 (byte)        The compressed colour index for RLE encoded bams (ie. this is the colour that is compressed)
    FrameEntriesOffset  DD 0 ; 0x000c   4 (dword)       Offset (from start of file) to frame entries (which are immediately followed by cycle entries)
    PaletteOffset       DD 0 ; 0x0010   4 (dword)       Offset (from start of file) to palette
    FrameLookupOffset   DD 0 ; 0x0014   4 (dword)       Offset (from start of file) to frame lookup table
BAMV1_HEADER            ENDS
ENDIF

IFNDEF BAMV2_HEADER
BAMV2_HEADER            STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('BAM ')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V2 ')
    FrameEntriesCount   DD 0 ; 0x0008   4 (dword)       Number of frames
    CycleEntriesCount   DD 0 ; 0x000C   4 (dword)       Number of cycles
    BlockEntriesCount   DD 0 ; 0x0010   4 (dword)       Number of data blocks
    FrameEntriesOffset  DD 0 ; 0x0014   4 (dword)       Start offset of frame entries
    CycleEntriesOffset  DD 0 ; 0x0018   4 (dword)       Start offset of cycle entries
    BlockEntriesOffset  DD 0 ; 0x001C   4 (dword)       Start offset of data blocks
BAMV2_HEADER            ENDS
ENDIF

IFNDEF BAMC_HEADER
BAMC_HEADER             STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('BAMC')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V1 ')
    UncompressedLength  DD 0 ; 0x0008   4 (dword)       Uncompressed data length
BAMC_HEADER             ENDS
ENDIF

IFNDEF FRAMEV1_ENTRY
FRAMEV1_ENTRY           STRUCT
    FrameWidth          DW 0 ; 0x0000   2 (word)        Frame width
    FrameHeight         DW 0 ; 0x0002   2 (word)        Frame height
    FrameXcoord         DW 0 ; 0x0004   2 (signed word) Frame center X coordinate
    FrameYcoord         DW 0 ; 0x0006   2 (signed word) Frame center Y coordinate
    FrameInfo           DD 0 ; 0x0008   4 (dword)       * bits 30-0: Offset to frame data * bit 31: 0=Compressed (RLE), 1=Uncompressed    
FRAMEV1_ENTRY           ENDS
ENDIF

IFNDEF FRAMEV2_ENTRY
FRAMEV2_ENTRY           STRUCT
    FrameWidth          DW 0 ; 0x0000   2 (word)        Frame width
    FrameHeight         DW 0 ; 0x0002   2 (word)        Frame height
    FrameXcoord         DW 0 ; 0x0004   2 (signed word) Frame center X coordinate
    FrameYcoord         DW 0 ; 0x0006   2 (signed word) Frame center Y coordinate
    DataBlockIndex      DW 0 
    DataBlockCount      DW 0
FRAMEV2_ENTRY           ENDS
ENDIF

IFNDEF CYCLEV1_ENTRY
CYCLEV1_ENTRY           STRUCT
    CycleFrameCount     DW 0 ; 0x0000   2 (word)        Count of frame indices in this cycle
    CycleStartFrame     DW 0 ; 0x0002   2 (word)        Index into frame lookup table of first frame index in this cycle
CYCLEV1_ENTRY           ENDS
ENDIF

IFNDEF CYCLEV2_ENTRY
CYCLEV2_ENTRY           STRUCT
    CycleFrameCount     DW 0 ; 0x0000   2 (word)        Number of frame entries in this cycle
    CycleStartFrame     DW 0 ; 0x0002   2 (word)        Start index of frame entries in this cycle
CYCLEV2_ENTRY           ENDS
ENDIF

IFNDEF DATABLOCK_ENTRY  ; Used in BAM V2
DATABLOCK_ENTRY         STRUCT
    PVRZPage            DD 0
    SourceXCoord        DD 0
    SourceYCoord        DD 0
    FrameWidth          DD 0
    FrameHeight         DD 0
    TargetXCoord        DD 0
    TargetYCoord        DD 0
DATABLOCK_ENTRY         ENDS
ENDIF


IFNDEF FRAMELOOKUPTABLE
FRAMELOOKUPTABLE        STRUCT
    SequenceSize        DD 0 ; length of sequence data - same as CycleFrameCount
    SequenceData        DD 0 ; pointer to word array that has sequence of frame indicies in it
FRAMELOOKUPTABLE        ENDS
ENDIF

IFNDEF FRAMEDATA
FRAMEDATA               STRUCT
    FrameCompressed     DD 0 ; Flag for compressed RLE encoding or not
    FrameWidth          DD 0
    FrameHeight         DD 0
    FrameSizeRAW        DD 0 ; total dimension size of FrameRAW = width * height
    FrameSizeRLE        DD 0
    FrameSizeBMP        DD 0
    FrameRAW            DD 0 ; Pointer to RAW unRLE'd frame data
    FrameRLE            DD 0
    FrameBMP            DD 0 ; memory for bitmap pixels, (unrle'd data) raw data converted to bmp pixel data.  
    FrameBitmapHandle   DD 0 ; bitmap handle from CreateDibBitmap
    FrameDataBlockIndex DD 0 ; BAM V2 only
    FrameDataBlockCount DD 0 ; BAM V2 only
FRAMEDATA               ENDS
ENDIF


.CONST

IEBAM_ALIGN                 TEXTEQU <ALIGN 16>
; IEBAMOpen open mode:
IEBAM_MODE_WRITE            EQU 0
IEBAM_MODE_READONLY         EQU 1
; BAM Versions:
BAM_VERSION_INVALID         EQU 0 ; Not a BAM or invalid
BAM_VERSION_BAM_V10         EQU 1 ; BAM_V1.0
BAM_VERSION_BAM_V20         EQU 2 ; BAM_V2.0
BAM_VERSION_BAMCV10         EQU 3 ; BAMCV1.0 (Compressed Blocks)



















