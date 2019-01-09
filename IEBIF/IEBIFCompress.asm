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

;USE_CBF_EXTENSION_FOR_COMPRESSBIF EQU 1


;DEBUG32 EQU 1
;IFDEF DEBUG32
;    PRESERVEXMMREGS equ 1
;    includelib M:\Masm32\lib\Debug32.lib
;    DBG32LIB equ 1
;    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
;    include M:\Masm32\include\debug32.inc
;ENDIF

BIFCompressBIFF         PROTO :DWORD, :DWORD, :DWORD
BIFCompressBound        PROTO :DWORD
EXTERNDEF BIFSignature :PROTO :DWORD
EXTERNDEF BIFJustFname :PROTO :DWORD, :DWORD

.DATA
CompressTmpExt          DB ".tmp",0
CompressCBFExt          DB ".cbf",0
CompressBIFExt          DB ".bif",0

.CODE


IEBIF_ALIGN
;-------------------------------------------------------------------------------------
; Compress specified bif file name
;-------------------------------------------------------------------------------------
IEBIFCompressBIF PROC PUBLIC USES EBX lpszBifFilenameIN:DWORD, lpszBifFilenameOUT:DWORD, dwCompressionFormat:DWORD
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
    LOCAL dwCompressedSize:DWORD
    LOCAL dwUncompressedSize:DWORD
    LOCAL ptrCompressedData:DWORD
    LOCAL OffsetCompressedData:DWORD
    LOCAL Version:DWORD
    LOCAL OffsetFilename:DWORD
    LOCAL dwInternalFilenameSize:DWORD
    LOCAL szInternalFilename[MAX_PATH]:BYTE
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
        mov eax, BC_BIF_INPUTFILE_ZEROSIZE
        ret
    .ENDIF   
    
    .IF BifFilesizeIN > 20000000h || BifFilesizeHighIN > 0 ; 2^29 = 536870912 = 536,870,912 bytes = 536MB
        ;PrintText 'BC_BIF_TOO_LARGE'
        mov eax, BC_BIF_TOO_LARGE
        ret
    .ENDIF
    mov eax, BifFilesizeIN
    mov dwUncompressedSize, eax
    
    Invoke CreateFileMapping, hBifIN, NULL, PAGE_READONLY, 0, 0, NULL ; Create memory mapped file
    .IF eax == NULL
        Invoke CloseHandle, hBifIN
        mov eax, BC_BIF_INPUTFILE_MAPPING
        ret        
    .ENDIF
    mov BifMemMapHandleIN, eax

    Invoke MapViewOfFileEx, BifMemMapHandleIN, FILE_MAP_READ, 0, 0, 0, NULL
    .IF eax == NULL
        Invoke CloseHandle, BifMemMapHandleIN
        Invoke CloseHandle, hBifIN
        mov eax, BC_BIF_INPUTFILE_VIEW
        ret
    .ENDIF
    mov BifMemMapPtrIN, eax
    
    Invoke BIFSignature, BifMemMapPtrIN
    mov Version, eax

    .IF Version == BIF_VERSION_BIFFV10
        ; BIFF uncompressed, ready to compress
        mov eax, BifFilesizeIN
        mov dwCompressedSize, eax
        Invoke BIFCompressBIFF, BifMemMapPtrIN, Addr dwCompressedSize, dwCompressionFormat ; we pass filesize in via dwCompressedSize to alloc at least that amount of data, on return we have actual compressed size
        .IF eax == 0
            Invoke UnmapViewOfFile, BifMemMapPtrIN
            Invoke CloseHandle, BifMemMapHandleIN
            Invoke CloseHandle, hBifIN
            mov eax, BC_BIF_COMPRESS_ERROR
            ret
        .ELSEIF eax == -1
            Invoke UnmapViewOfFile, BifMemMapPtrIN
            Invoke CloseHandle, BifMemMapHandleIN
            Invoke CloseHandle, hBifIN
            mov eax, BC_BIF_COMPRESS_TOOLARGE
            ret
        .ENDIF
        mov ptrCompressedData, eax

    .ELSE ; if 0,2,3,4 or other
        Invoke UnmapViewOfFile, BifMemMapPtrIN
        Invoke CloseHandle, BifMemMapHandleIN
        Invoke CloseHandle, hBifIN
        .IF Version == 0 ; invalid bif
            mov eax, BC_BIF_INVALID
        .ELSEIF Version == 2 ; BIF_ already compressed
            mov eax, BC_BIF_ALREADY_COMPRESSED
        .ELSEIF Version == 3 ; BIFC already compressed
            mov eax, BC_BIF_ALREADY_COMPRESSED
        .ELSEIF Version == 4 ; BIF V1.1 not supported
            mov eax, BC_BIF_FORMAT_UNSUPPORTED
        .ELSE
            mov eax, BC_BIF_FORMAT_UNSUPPORTED
        .ENDIF
        ret
    .ENDIF

    .IF dwCompressionFormat == IEBIF_COMPRESS_MODE_BIF_ ; BIF_
        Invoke BIFJustFname, lpszBifFilenameIN, Addr szInternalFilename
        Invoke szCatStr, Addr szInternalFilename, Addr CompressBIFExt
        Invoke szLen, Addr szInternalFilename
        mov dwInternalFilenameSize, eax
        inc dwInternalFilenameSize
        mov eax, dwCompressedSize
        add eax, SIZEOF BIF__HEADER
        sub eax, 4d ; filename is not a dword we just use dword for pointer to data
        add eax, dwInternalFilenameSize
        ;add eax, 1 ; include the null byte
        add eax, SIZEOF BIF__HEADER_DATA
        mov FilesizeOUT, eax

    .ELSE ; BIFC

        mov eax, dwCompressedSize ; this includes all the BIFC_BLOCKs as well
        add eax, SIZEOF BIFC_HEADER
        mov FilesizeOUT, eax
    .ENDIF
    
    ; ---------------------------------------------------------------------------------------------------------------------------
    ; Output File 
    ; ---------------------------------------------------------------------------------------------------------------------------
    mov eax, lpszBifFilenameOUT
    .IF eax == NULL ; use same name for output, but temporarily use another file name before copying over exiting one
        Invoke szCopy, lpszBifFilenameIN, Addr szBifFilenameOUT
        Invoke szCatStr, Addr szBifFilenameOUT, Addr CompressTmpExt  
        mov TmpFileFlag, TRUE
    .ELSE
        
        Invoke Cmpi, lpszBifFilenameOUT, lpszBifFilenameIN
        .IF eax == 0 ; match
            Invoke szCopy, lpszBifFilenameIN, Addr szBifFilenameOUT
            Invoke szCatStr, Addr szBifFilenameOUT, Addr CompressTmpExt  
            mov TmpFileFlag, TRUE
        .ELSE
            Invoke szCopy, lpszBifFilenameOUT, Addr szBifFilenameOUT
            mov TmpFileFlag, FALSE
        .ENDIF
    .ENDIF
    Invoke CreateFile, Addr szBifFilenameOUT, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_TEMPORARY, NULL    
    .IF eax == INVALID_HANDLE_VALUE
        Invoke GlobalFree, ptrCompressedData
        Invoke UnmapViewOfFile, BifMemMapPtrIN
        Invoke CloseHandle, BifMemMapHandleIN
        Invoke CloseHandle, hBifIN    
        mov eax, BC_BIF_OUTPUTFILE_CREATION
        ret
    .ENDIF
    mov hBifOUT, eax

    Invoke CreateFileMapping, hBifOUT, NULL, PAGE_READWRITE, 0, FilesizeOUT, NULL ; Create memory mapped file
    .IF eax == NULL
        Invoke GlobalFree, ptrCompressedData
        Invoke UnmapViewOfFile, BifMemMapPtrIN
        Invoke CloseHandle, BifMemMapHandleIN
        Invoke CloseHandle, hBifIN    
        Invoke CloseHandle, hBifOUT
        mov eax, BC_BIF_OUTPUTFILE_MAPPING
        ret        
    .ENDIF
    mov BifMemMapHandleOUT, eax

    Invoke MapViewOfFileEx, BifMemMapHandleOUT, FILE_MAP_ALL_ACCESS, 0, 0, 0, NULL
    .IF eax == NULL
        Invoke GlobalFree, ptrCompressedData
        Invoke UnmapViewOfFile, BifMemMapPtrIN
        Invoke CloseHandle, BifMemMapHandleIN
        Invoke CloseHandle, hBifIN    
        Invoke CloseHandle, BifMemMapHandleOUT
        Invoke CloseHandle, hBifOUT
        mov eax, BC_BIF_OUTPUTFILE_VIEW
        ret
    .ENDIF
    mov BifMemMapPtrOUT, eax

    ; ---------------------------------------------------------------------------------------------------------------------------
    ; Fill in header data and copy compressed data in memory to output file mapping, close files and then copy over filenames if applicable
    ; ---------------------------------------------------------------------------------------------------------------------------
    .IF dwCompressionFormat == IEBIF_COMPRESS_MODE_BIF_ ; BIF_
        mov ebx, BifMemMapPtrOUT ;ptrCompressedData
        mov eax, ' FIB'
        mov [ebx].BIF__HEADER.Signature, eax
        mov eax, '0.1V'
        mov [ebx].BIF__HEADER.Version, eax
        mov eax, dwInternalFilenameSize

        mov [ebx].BIF__HEADER.FilenameLength, eax
        lea eax, [ebx].BIF__HEADER.Filename
        mov OffsetFilename, eax

        Invoke lstrcpyn, OffsetFilename, Addr szInternalFilename, dwInternalFilenameSize
        mov ebx, BifMemMapPtrOUT ;ptrCompressedData
        add ebx, SIZEOF BIF__HEADER
        sub ebx, 4d ; dont include dword for filename
        add ebx, dwInternalFilenameSize ; which does include null in this case
        ; ebx is pointer to BIF__HEADER_DATA
        mov eax, dwUncompressedSize
        mov [ebx].BIF__HEADER_DATA.UncompressedSize, eax
        mov eax, dwCompressedSize
        mov [ebx].BIF__HEADER_DATA.CompressedSize, eax
        lea eax, [ebx].BIF__HEADER_DATA.CompressedData
        mov OffsetCompressedData, eax

    .ELSE ; BIFC

        mov ebx, BifMemMapPtrOUT ;ptrCompressedData
        mov eax, 'CFIB'
        mov [ebx].BIFC_HEADER.Signature, eax
        mov eax, '0.1V'
        mov [ebx].BIFC_HEADER.Version, eax
        mov eax, dwUncompressedSize
        mov [ebx].BIFC_HEADER.UncompressedSize, eax
        mov eax, BifMemMapPtrOUT ;ptrCompressedData
        add eax, SIZEOF BIFC_HEADER
        mov OffsetCompressedData, eax
    .ENDIF
    
    ;PrintText 'Copy compressed data to outfile'
    Invoke RtlMoveMemory, OffsetCompressedData, ptrCompressedData, dwCompressedSize

    ;PrintText 'tidy up'
    Invoke GlobalFree, ptrCompressedData
    Invoke UnmapViewOfFile, BifMemMapPtrIN
    Invoke CloseHandle, BifMemMapHandleIN
    Invoke CloseHandle, hBifIN
    Invoke UnmapViewOfFile, BifMemMapPtrOUT
    Invoke CloseHandle, BifMemMapHandleOUT
    Invoke CloseHandle, hBifOUT
    
    ;mov eax, lpszBifFilenameOUT
    .IF TmpFileFlag == TRUE ;eax == NULL || (lpszBifFilenameIN == eax)  ; we need to copy over outfile to infile
        ;Invoke CopyFile, Addr szBifFilenameOUT, lpszBifFilenameIN, FALSE
        ;Invoke DeleteFile, Addr szBifFilenameOUT
        
        ; check for bif extention and copy output file to a cbf extension instead
        IFDEF USE_CBF_EXTENSION_FOR_COMPRESSBIF
            Invoke InString, 1, lpszBifFilenameIN, Addr CompressBIFExt
            .IF eax == 0
                Invoke CopyFile, Addr szBifFilenameOUT, lpszBifFilenameIN, FALSE
            .ELSE
                Invoke szRep, lpszBifFilenameIN, Addr szBifFilenameALT, Addr CompressBIFExt, Addr CompressCBFExt 
                Invoke CopyFile, Addr szBifFilenameOUT, Addr szBifFilenameALT, FALSE
            .ENDIF
        ELSE
            Invoke CopyFile, Addr szBifFilenameOUT, lpszBifFilenameIN, FALSE
        ENDIF
        Invoke DeleteFile, Addr szBifFilenameOUT
        
    .ENDIF ; else file mapped outfile is closed and no copy needed

    mov eax, BC_SUCCESS
    ret
IEBIFCompressBIF ENDP


IEBIF_ALIGN
;-----------------------------------------------------------------------------------------
; Compresses BIFF file to an area of memory that we allocate for the exact size of data
;-----------------------------------------------------------------------------------------
BIFCompressBIFF PROC PRIVATE USES EBX pBIF:DWORD, dwSize:DWORD, dwFormat:DWORD
    LOCAL dest:DWORD ; Heap
    LOCAL src:DWORD ; pBIF
    LOCAL UncompressedSize:DWORD
    LOCAL CompressedSize:DWORD
    LOCAL BlockUncompressedSize:DWORD
    LOCAL BlockCompressedSize:DWORD
    LOCAL BlockHeader:DWORD
    LOCAL CompressedData:DWORD
    LOCAL UncompressedData:DWORD
    LOCAL TotalBytesWritten:DWORD
    LOCAL CurrentPos:DWORD
    LOCAL CompressedDataOffset:DWORD
    LOCAL UncompressedDataOffset:DWORD
    LOCAL UncompressedMemSize:DWORD ; from compressBound
    LOCAL nBlock:DWORD
    
    mov ebx, pBIF
    mov UncompressedData, ebx
    
    mov ebx, dwSize
    mov eax, [ebx] ; get size of file
    mov UncompressedSize, eax

    Invoke compressBound, UncompressedSize
    mov UncompressedMemSize, eax
    mov CompressedSize, eax
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, UncompressedMemSize ;UncompressedSize ; alloc at least this amount of space, it will be smaller after compression anyhow
    .IF eax != NULL
        mov dest, eax
        mov CompressedData, eax
        
        .IF dwFormat == IEBIF_COMPRESS_MODE_BIF_ ; BIF_
            Invoke compress, CompressedData, Addr CompressedSize, UncompressedData, UncompressedSize ;UncompressedSize
            .IF eax == Z_OK ; ok
                mov eax, CompressedSize
                .IF eax > UncompressedSize
                    Invoke GlobalFree, dest
                    mov eax, -1 ; return saying file output would be larger than out input file - no point compressing
                    ret
                .ELSE
                    mov eax, CompressedSize 
                    mov ebx, dwSize ; save size in user provided addr var
                    mov [ebx], eax
                    mov eax, dest
                    ret
                .ENDIF
            .ELSE
                Invoke GlobalFree, dest
                mov eax, 0
                ret    
            .ENDIF
            
        .ELSE ; BIFC

            mov TotalBytesWritten, 0
            mov CurrentPos, 0
            mov nBlock, 0
            
            .IF UncompressedSize < 8192d
                mov eax, UncompressedSize
                mov BlockUncompressedSize, eax
            .ELSE
                mov BlockUncompressedSize, 8192d
                mov eax, BlockUncompressedSize
            .ENDIF
            
            Invoke compressBound, BlockUncompressedSize
            mov BlockCompressedSize, eax

            mov eax, pBIF
            mov UncompressedDataOffset, eax
            mov eax, CompressedData
            mov CompressedDataOffset, eax

            mov eax, 0
            .WHILE eax < UncompressedSize
                mov ebx, CompressedDataOffset
                mov eax, BlockUncompressedSize
                mov [ebx], eax ;[ebx].BIFC_BLOCK.UncompressedSize
                add CompressedDataOffset, 8d ; skip over block header
                Invoke compress, CompressedDataOffset, Addr BlockCompressedSize, UncompressedDataOffset, BlockUncompressedSize
                .IF eax != Z_OK ; not ok
                    Invoke GlobalFree, dest
                    mov eax, 0
                    ret
                .ENDIF
                
                inc nBlock
                ; calc CompressedDataOffset for next block
                sub CompressedDataOffset, 4d ; move back to block header compressed size
                mov ebx, CompressedDataOffset
                mov eax, BlockCompressedSize
                mov  [ebx], eax ;[ebx].BIFC_BLOCK.CompressedSize
                add CompressedDataOffset, 4d ; size of block header now
                mov eax, CompressedDataOffset
                add eax, BlockCompressedSize
                mov CompressedDataOffset, eax ; add 4 from BIFC_BLOCK.CompressedSize + length of compressed data to get next blocks start offset

                ; calc UncompressedDataOffset for next block
                mov eax, BlockUncompressedSize
                add UncompressedDataOffset, eax 

                ; calc total bytes written so far
                mov eax, TotalBytesWritten
                add eax, BlockCompressedSize
                add eax, 8 ; sizeof BIFC_BLOCK
                mov TotalBytesWritten, eax
                add eax, 8192d
                .IF eax > UncompressedSize
                    Invoke GlobalFree, dest
                    mov eax, -1 ; return saying file output would be larger than out input file - no point compressing
                    ret
                .ENDIF
                ; calc current position and block sizes till last block is < 8192 to fetch
                mov eax, CurrentPos
                add eax, 8192d
                mov CurrentPos, eax
                .IF eax > UncompressedSize
                    .BREAK
                .ENDIF
                add eax, 8192d
                .IF eax < UncompressedSize
                    mov BlockUncompressedSize, 8192d
                    Invoke compressBound, BlockUncompressedSize
                    mov BlockCompressedSize, eax
                .ELSE
                    ;PrintText 'last bit'
                    mov eax, UncompressedSize
                    mov ebx, CurrentPos
                    sub eax, ebx
                    mov BlockUncompressedSize, eax
                    Invoke compressBound, BlockUncompressedSize
                    mov BlockCompressedSize, eax
                .ENDIF
                mov eax, CurrentPos
               
            .ENDW
            ; should be all blocks compressed into our storage
            mov eax, TotalBytesWritten
            mov ebx, dwSize ; save size in user provided addr var
            mov [ebx], eax
            mov eax, dest
            ret             
        .ENDIF

    .ELSE
        mov eax, 0
        ret    
    .ENDIF      
    
    mov eax, CompressedSize 
    mov ebx, dwSize ; save size in user provided addr var
    mov [ebx], eax
    mov eax, dest
    ret

BIFCompressBIFF endp


IEBIF_ALIGN
;-----------------------------------------------------------------------------------------
; zlib compressBound copy
;-----------------------------------------------------------------------------------------
BIFCompressBound PROC srclen:DWORD
    LOCAL sourceLen:DWORD
    LOCAL sourcelen12:DWORD
    LOCAL sourcelen14:DWORD
    LOCAL sourcelen25:DWORD
    mov eax, srclen
    shr eax, 12d
    mov sourcelen12, eax
    mov eax, srclen
    shr eax, 14d
    mov sourcelen14, eax
    mov eax, srclen
    shr eax, 25
    mov sourcelen25, eax
    
    mov eax, srclen
    add eax, sourcelen12
    add eax, sourcelen14
    add eax, sourcelen25
    add eax, 13d
    ;sourceLen + (sourceLen >> 12) + (sourceLen >> 14) +           (sourceLen >> 25) + 13;    
    ret

BIFCompressBound endp


END