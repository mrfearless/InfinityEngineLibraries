.686
.MMX
.XMM
.model flat,stdcall
option casemap:none

include windows.inc
include kernel32.inc
include user32.inc
include masm32.inc
include zlibstat.inc

includelib kernel32.lib
includelib user32.lib
includelib masm32.lib
includelib zlibstat128.lib
;includelib zlib-ng.lib

include IEBIF.inc

;USE_BIF_EXTENSION_FOR_UNCOMPRESSBIF EQU 1

;DEBUG32 EQU 1
;IFDEF DEBUG32
;    PRESERVEXMMREGS equ 1
;    includelib M:\Masm32\lib\Debug32.lib
;    DBG32LIB equ 1
;    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
;    include M:\Masm32\include\debug32.inc
;ENDIF

BIFUncompressBIF_       PROTO :DWORD, :DWORD
BIFUncompressBIFC       PROTO :DWORD, :DWORD
EXTERNDEF BIFSignature :PROTO :DWORD
EXTERNDEF BIFJustFname :PROTO :DWORD, :DWORD

.DATA
UncompressTmpExt        DB ".tmp",0
UncompressCBFExt        DB ".cbf",0
UncompressBIFExt        DB ".bif",0

.CODE


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; Uncompress specified bif file name
;-------------------------------------------------------------------------------------
IEBIFUncompressBIF PROC PUBLIC USES EBX lpszBifFilenameIN:DWORD, lpszBifFilenameOUT:DWORD
    LOCAL szBifFilenameOUT[MAX_PATH]:BYTE
    LOCAL szBifFilenameALT[MAX_PATH]:BYTE
    LOCAL hBifIN:DWORD
    LOCAL hBifOUT:DWORD
    LOCAL BifMemMapHandleIN:DWORD
    LOCAL BifMemMapHandleOUT:DWORD
    LOCAL BifMemMapPtrIN:DWORD
    LOCAL BifMemMapPtrOUT:DWORD
    LOCAL BifFilesizeIN:DWORD
    LOCAL BifFilesizeHighIN:DWORD
    LOCAL FilesizeOUT:DWORD
    LOCAL ptrUncompressedData:DWORD
    LOCAL Version:DWORD
    LOCAL TmpFileFlag:DWORD
    
    mov TmpFileFlag, FALSE
    
    ; ---------------------------------------------------------------------------------------------------------------------------
    ; Input File
    ; ---------------------------------------------------------------------------------------------------------------------------
    Invoke CreateFile, lpszBifFilenameIN, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL ; readonly
    .IF eax == INVALID_HANDLE_VALUE
        mov eax, BU_BIF_INPUTFILE_OPEN
        ret
    .ENDIF
    mov hBifIN, eax
    
    ; check file size is not 0
    Invoke GetFileSize, hBifIN, Addr BifFilesizeHighIN
    mov BifFilesizeIN, eax
    .IF BifFilesizeIN == 0 && BifFilesizeHighIN == 0
        Invoke CloseHandle, hBifIN
        mov eax, BU_BIF_INPUTFILE_ZEROSIZE
        ret
    .ENDIF   
    
    .IF BifFilesizeIN > 20000000h || BifFilesizeHighIN > 0 ; 2^29 = 536870912 = 536,870,912 bytes = 536MB
        mov eax, BU_BIF_TOO_LARGE
        ret
    .ENDIF
    
    Invoke CreateFileMapping, hBifIN, NULL, PAGE_READONLY, 0, 0, NULL ; Create memory mapped file
    .IF eax == NULL
        Invoke CloseHandle, hBifIN
        mov eax, BU_BIF_INPUTFILE_MAPPING
        ret        
    .ENDIF
    mov BifMemMapHandleIN, eax

    Invoke MapViewOfFileEx, BifMemMapHandleIN, FILE_MAP_READ, 0, 0, 0, NULL
    .IF eax == NULL
        Invoke CloseHandle, BifMemMapHandleIN
        Invoke CloseHandle, hBifIN
        mov eax, BU_BIF_INPUTFILE_VIEW
        ret
    .ENDIF
    mov BifMemMapPtrIN, eax
    
    Invoke BIFSignature, BifMemMapPtrIN
    mov Version, eax

    .IF Version == 2 ; BIF_ compressed, ready to uncompress
        Invoke BIFUncompressBIF_, BifMemMapPtrIN, Addr FilesizeOUT
        .IF eax == 0
            Invoke UnmapViewOfFile, BifMemMapPtrIN
            Invoke CloseHandle, BifMemMapHandleIN
            Invoke CloseHandle, hBifIN        
            mov eax, BU_BIF_UNCOMPRESS_ERROR
            ret
        .ENDIF
        mov ptrUncompressedData, eax
        
    .ELSEIF Version == 3 ; BIFC compressed, ready to uncompress
        Invoke BIFUncompressBIFC, BifMemMapPtrIN, Addr FilesizeOUT
        .IF eax == 0
            Invoke UnmapViewOfFile, BifMemMapPtrIN
            Invoke CloseHandle, BifMemMapHandleIN
            Invoke CloseHandle, hBifIN        
            mov eax, BU_BIF_UNCOMPRESS_ERROR
            ret
        .ENDIF
        mov ptrUncompressedData, eax

    .ELSE ; if 0,1,4 or other
        Invoke UnmapViewOfFile, BifMemMapPtrIN
        Invoke CloseHandle, BifMemMapHandleIN
        Invoke CloseHandle, hBifIN
        .IF Version == 0 ; invalid bif
            mov eax, BU_BIF_INVALID
        .ELSEIF Version == 1 ; already uncompressed
            mov eax, BU_BIF_ALREADY_UNCOMPRESSED
        .ELSEIF Version == 4 ; BIF V1.1 not supported
            mov eax, BU_BIF_FORMAT_UNSUPPORTED
        .ELSE
            mov eax, BU_BIF_FORMAT_UNSUPPORTED
        .ENDIF
        ret
    .ENDIF
    
    ; ---------------------------------------------------------------------------------------------------------------------------
    ; Output File 
    ; ---------------------------------------------------------------------------------------------------------------------------
    mov eax, lpszBifFilenameOUT
    .IF eax == NULL ;|| (lpszBifFilenameIN == eax) ; use same name for output, but temporarily use another file name before copying over exiting one
        Invoke szCopy, lpszBifFilenameIN, Addr szBifFilenameOUT
        Invoke szCatStr, Addr szBifFilenameOUT, Addr UncompressTmpExt
        mov TmpFileFlag, TRUE
    .ELSE
        
        Invoke Cmpi, lpszBifFilenameOUT, lpszBifFilenameIN
        .IF eax == 0 ; match        
            Invoke szCopy, lpszBifFilenameIN, Addr szBifFilenameOUT
            Invoke szCatStr, Addr szBifFilenameOUT, Addr UncompressTmpExt
            mov TmpFileFlag, TRUE
        .ELSE
            Invoke szCopy, lpszBifFilenameOUT, Addr szBifFilenameOUT
            mov TmpFileFlag, FALSE
        .ENDIF
    .ENDIF
    
    ; check for .cbf extension, if we have it we change it to .bif
    
    Invoke CreateFile, Addr szBifFilenameOUT, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_TEMPORARY, NULL    
    .IF eax == INVALID_HANDLE_VALUE
        Invoke GlobalFree, ptrUncompressedData
        Invoke UnmapViewOfFile, BifMemMapPtrIN
        Invoke CloseHandle, BifMemMapHandleIN
        Invoke CloseHandle, hBifIN    
        mov eax, BU_BIF_OUTPUTFILE_CREATION
        ret
    .ENDIF
    mov hBifOUT, eax

    Invoke CreateFileMapping, hBifOUT, NULL, PAGE_READWRITE, 0, FilesizeOUT, NULL ; Create memory mapped file
    .IF eax == NULL
        Invoke GlobalFree, ptrUncompressedData
        Invoke UnmapViewOfFile, BifMemMapPtrIN
        Invoke CloseHandle, BifMemMapHandleIN
        Invoke CloseHandle, hBifIN    
        Invoke CloseHandle, hBifOUT
        mov eax, BU_BIF_OUTPUTFILE_MAPPING
        ret        
    .ENDIF
    mov BifMemMapHandleOUT, eax

    Invoke MapViewOfFileEx, BifMemMapHandleOUT, FILE_MAP_ALL_ACCESS, 0, 0, 0, NULL
    .IF eax == NULL
        Invoke GlobalFree, ptrUncompressedData
        Invoke UnmapViewOfFile, BifMemMapPtrIN
        Invoke CloseHandle, BifMemMapHandleIN
        Invoke CloseHandle, hBifIN    
        Invoke CloseHandle, BifMemMapHandleOUT
        Invoke CloseHandle, hBifOUT
        mov eax, BU_BIF_OUTPUTFILE_VIEW
        ret
    .ENDIF
    mov BifMemMapPtrOUT, eax

    ; ---------------------------------------------------------------------------------------------------------------------------
    ; Copy uncompressed data in memory to output file mapping, close files and then copy over filenames if applicable
    ; ---------------------------------------------------------------------------------------------------------------------------
    Invoke RtlMoveMemory, BifMemMapPtrOUT, ptrUncompressedData, FilesizeOUT

    Invoke GlobalFree, ptrUncompressedData
    Invoke UnmapViewOfFile, BifMemMapPtrIN
    Invoke CloseHandle, BifMemMapHandleIN
    Invoke CloseHandle, hBifIN
    Invoke UnmapViewOfFile, BifMemMapPtrOUT
    Invoke CloseHandle, BifMemMapHandleOUT
    Invoke CloseHandle, hBifOUT
    
    ;mov eax, lpszBifFilenameOUT
    .IF TmpFileFlag == TRUE  ;eax == NULL || (lpszBifFilenameIN == eax)  ; we need to copy over outfile to infile
        ; check for cbf extention and copy output file to a bif extension instead
        IFDEF USE_BIF_EXTENSION_FOR_UNCOMPRESSBIF
            Invoke InString, 1, lpszBifFilenameIN, Addr UncompressCBFExt
            .IF eax == 0
                Invoke CopyFile, Addr szBifFilenameOUT, lpszBifFilenameIN, FALSE
            .ELSE
                Invoke szRep, lpszBifFilenameIN, Addr szBifFilenameALT, Addr UncompressCBFExt, Addr UncompressBIFExt
                Invoke CopyFile, Addr szBifFilenameOUT, Addr szBifFilenameALT, FALSE
            .ENDIF
        ELSE
            Invoke CopyFile, Addr szBifFilenameOUT, lpszBifFilenameIN, FALSE
        ENDIF
        Invoke DeleteFile, Addr szBifFilenameOUT
    .ENDIF
    
    mov eax, BU_SUCCESS
    ret
IEBIFUncompressBIF ENDP


IEBIF_ALIGN
;-----------------------------------------------------------------------------------------
; Uncompresses BIF_ file to an area of memory that we allocate for the exact size of data
;-----------------------------------------------------------------------------------------
BIFUncompressBIF_ PROC PRIVATE USES EBX pBIF:DWORD, dwSize:DWORD
    LOCAL dest:DWORD ; Heap
    LOCAL src:DWORD ; BIFMemMapPtr
    LOCAL BIF__UncompressedSize:DWORD
    LOCAL BIF__CompressedSize:DWORD
    
    
    ;mov eax, pBIF ;BIFMemMapPtr
    mov ebx, pBIF
    movzx eax, word ptr [ebx].BIF__HEADER.FilenameLength
    add eax, 12d
    add eax, pBIF
    mov ebx, eax ; ebx contains ptr to BIF__HEADER_DATA
    mov eax, [ebx].BIF__HEADER_DATA.UncompressedSize

    mov BIF__UncompressedSize, eax
    mov eax, [ebx].BIF__HEADER_DATA.CompressedSize
    mov BIF__CompressedSize, eax
    lea eax, [ebx].BIF__HEADER_DATA.CompressedData
    mov src, eax

;    PrintDec src
;    PrintDec pBIF
;    DbgDump src, 20d
;    DbgDump pBIF, 20d
;    PrintDec BIF__UncompressedSize
;    PrintDec BIF__CompressedSize
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, BIF__UncompressedSize
    .IF eax != NULL
        ;PrintText 'alloc ok'
        mov dest, eax
        ;add eax, 0Ch ; add BIF_ Header to Memory map to start at correct offset for uncompressing
        ;mov src, eax
        ; Invoke uncompress, dest, Addr destLen, src, srcLen
        Invoke uncompress, dest, Addr BIF__UncompressedSize, src, BIF__CompressedSize
        .IF eax == Z_OK ; ok
            ;PrintText 'Z_OK'
            mov eax, BIF__UncompressedSize 
            mov ebx, dwSize ; save size in user provided addr var
            mov [ebx], eax
        
            mov eax, dest
            ret
        .ELSE
            Invoke GlobalFree, dest
            mov eax, 0
            ret
        .ENDIF
    .ELSE
        ;PrintText 'Not Z_OK'
        Invoke GlobalFree, dest
        mov eax, 0
        ret
    .ENDIF
    ;PrintText 'No alloc'
    mov eax, 0        
    ret

BIFUncompressBIF_ endp


IEBIF_ALIGN
;-----------------------------------------------------------------------------------------
; Uncompresses BIFC file to an area of memory that we allocate for the exact size of data
;-----------------------------------------------------------------------------------------
BIFUncompressBIFC PROC PRIVATE USES EBX pBIF:DWORD, dwSize:DWORD
    LOCAL dest:DWORD ; Heap
    LOCAL src:DWORD ; BIFMemMapPtr
    LOCAL BIFC_UncompressedSize:DWORD
    LOCAL BIFC_CompressedSize:DWORD
    LOCAL BlockUncompressedSize:DWORD
    LOCAL BlockCompressedSize:DWORD
    LOCAL BlockHeader:DWORD
    LOCAL CompressedData:DWORD
    LOCAL UncompressedData:DWORD
    LOCAL TotalBytesRead:DWORD
    LOCAL nBlock:DWORD
    
    mov ebx, pBIF
    mov eax, [ebx].BIFC_HEADER.UncompressedSize
    mov BIFC_UncompressedSize, eax
    mov eax, SIZEOF BIFC_HEADER
    add eax, ebx
    mov BlockHeader, eax
    
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, BIFC_UncompressedSize
    .IF eax != NULL
        mov dest, eax
        mov UncompressedData, eax
        
        mov nBlock, 0
        mov TotalBytesRead, 0
        mov eax, 0
        .WHILE eax != BIFC_UncompressedSize ; loop for getting each block until we reach final size
        
            mov ebx, BlockHeader
            mov eax, [ebx].BIFC_BLOCK.UncompressedSize
            mov BlockUncompressedSize, eax
            mov eax, [ebx].BIFC_BLOCK.CompressedSize
            mov BlockCompressedSize, eax
            lea eax, [ebx].BIFC_BLOCK.CompressedData
            mov CompressedData, eax
        
            Invoke uncompress, UncompressedData, Addr BlockUncompressedSize, CompressedData, BlockCompressedSize
            .IF eax != Z_OK ; ok
                ;PrintText 'uncompress BIFC error'
                ;PrintDec eax
                ;PrintDec nBlock
                Invoke GlobalFree, dest
                mov eax, 0
                ret
            .ENDIF
            
            ; adjust block header to next block 
            mov eax, BlockHeader
            add eax, BlockCompressedSize
            add eax, 8d ; for compressed and uncompressed fields
            mov BlockHeader, eax
            
            ; adjust destination = UncompressedData for next block
            mov eax, UncompressedData
            add eax, BlockUncompressedSize
            mov UncompressedData, eax
            
            inc nBlock
            
            ; adjust total bytes read so we know when to exit loop
            mov eax, TotalBytesRead
            mov ebx, BlockUncompressedSize
            add eax, ebx
            mov TotalBytesRead, eax
            mov eax, TotalBytesRead
        .ENDW
    .ELSE
        mov eax, 0
        ret    
    .ENDIF                  

    mov eax, BIFC_UncompressedSize 
    mov ebx, dwSize ; save size in user provided addr var
    mov [ebx], eax
    mov eax, dest
      
    ret

BIFUncompressBIFC ENDP


END