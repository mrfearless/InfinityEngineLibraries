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

include IEBAM.inc

BAMUncompress               PROTO hBAMFile:DWORD, pBAM:DWORD, dwSize:DWORD


EXTERNDEF BAMSignature      :PROTO pBAM:DWORD
EXTERNDEF BAMJustFname      :PROTO szFilePathName:DWORD, szFileName:DWORD

.DATA
UncompressTmpExt            DB ".tmp",0
UncompressBAMExt            DB ".bam",0


.CODE

IEBAM_ALIGN
;-------------------------------------------------------------------------------------
; Uncompress specified bam file name
;-------------------------------------------------------------------------------------
IEBAMUncompressBAM PROC USES EBX lpszBamFilenameIN:DWORD, lpszBamFilenameOUT:DWORD
    LOCAL szBamFilenameOUT[MAX_PATH]:BYTE
    LOCAL szBamFilenameALT[MAX_PATH]:BYTE
    LOCAL hBamIN:DWORD
    LOCAL hBamOUT:DWORD
    LOCAL BamMemMapHandleIN:DWORD
    LOCAL BamMemMapHandleOUT:DWORD
    LOCAL BamMemMapPtrIN:DWORD
    LOCAL BamMemMapPtrOUT:DWORD
    LOCAL BamFilesizeIN:DWORD
    LOCAL BamFilesizeHighIN:DWORD
    LOCAL FilesizeOUT:DWORD
    LOCAL ptrUncompressedData:DWORD
    LOCAL Version:DWORD
    LOCAL TmpFileFlag:DWORD
    
    mov TmpFileFlag, FALSE
    
    ; ---------------------------------------------------------------------------------------------------------------------------
    ; Input File
    ; ---------------------------------------------------------------------------------------------------------------------------
    Invoke CreateFile, lpszBamFilenameIN, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL ; readonly
    .IF eax == INVALID_HANDLE_VALUE
        mov eax, BU_BAM_INPUTFILE_OPEN
        ret
    .ENDIF
    mov hBamIN, eax
    
    ; check file size is not 0
    Invoke GetFileSize, hBamIN, Addr BamFilesizeHighIN
    mov BamFilesizeIN, eax
    .IF BamFilesizeIN == 0 && BamFilesizeHighIN == 0
        Invoke CloseHandle, hBamIN
        mov eax, BU_BAM_INPUTFILE_ZEROSIZE
        ret
    .ENDIF   
    
    .IF BamFilesizeIN > 20000000h || BamFilesizeHighIN > 0 ; 2^29 = 536870912 = 536,870,912 bytes = 536MB
        mov eax, BU_BAM_TOO_LARGE
        ret
    .ENDIF
    
    Invoke CreateFileMapping, hBamIN, NULL, PAGE_READONLY, 0, 0, NULL ; Create memory mapped file
    .IF eax == NULL
        Invoke CloseHandle, hBamIN
        mov eax, BU_BAM_INPUTFILE_MAPPING
        ret        
    .ENDIF
    mov BamMemMapHandleIN, eax

    Invoke MapViewOfFileEx, BamMemMapHandleIN, FILE_MAP_READ, 0, 0, 0, NULL
    .IF eax == NULL
        Invoke CloseHandle, BamMemMapHandleIN
        Invoke CloseHandle, hBamIN
        mov eax, BU_BAM_INPUTFILE_VIEW
        ret
    .ENDIF
    mov BamMemMapPtrIN, eax
    
    Invoke BAMSignature, BamMemMapPtrIN
    mov Version, eax

    .IF Version == BAM_VERSION_BAMCV10 ; BAMC compressed, ready to uncompress
        Invoke BAMUncompress, hBamIN, BamMemMapPtrIN, Addr FilesizeOUT
        .IF eax == 0
            Invoke UnmapViewOfFile, BamMemMapPtrIN
            Invoke CloseHandle, BamMemMapHandleIN
            Invoke CloseHandle, hBamIN        
            mov eax, BU_BAM_UNCOMPRESS_ERROR
            ret
        .ENDIF
        mov ptrUncompressedData, eax

    .ELSE ; if 0,1,2 or other
        Invoke UnmapViewOfFile, BamMemMapPtrIN
        Invoke CloseHandle, BamMemMapHandleIN
        Invoke CloseHandle, hBamIN
        .IF Version == BAM_VERSION_INVALID ; invalid bam
            mov eax, BU_BAM_INVALID
        .ELSEIF Version == BAM_VERSION_BAM_V10 ; already uncompressed
            mov eax, BU_BAM_ALREADY_UNCOMPRESSED
        .ELSEIF Version == BAM_VERSION_BAM_V20 ; BAM 2.0 not supported
            mov eax, BU_BAM_FORMAT_UNSUPPORTED
        .ELSE
            mov eax, BU_BAM_FORMAT_UNSUPPORTED
        .ENDIF
        ret
    .ENDIF
    
    ; ---------------------------------------------------------------------------------------------------------------------------
    ; Output File 
    ; ---------------------------------------------------------------------------------------------------------------------------
    mov eax, lpszBamFilenameOUT
    .IF eax == NULL ;|| (lpszBamFilenameIN == eax) ; use same name for output, but temporarily use another file name before copying over exiting one
        Invoke szCopy, lpszBamFilenameIN, Addr szBamFilenameOUT
        Invoke szCatStr, Addr szBamFilenameOUT, Addr UncompressTmpExt
        mov TmpFileFlag, TRUE
    .ELSE
        
        Invoke Cmpi, lpszBamFilenameOUT, lpszBamFilenameIN
        .IF eax == 0 ; match        
            Invoke szCopy, lpszBamFilenameIN, Addr szBamFilenameOUT
            Invoke szCatStr, Addr szBamFilenameOUT, Addr UncompressTmpExt
            mov TmpFileFlag, TRUE
        .ELSE
            Invoke szCopy, lpszBamFilenameOUT, Addr szBamFilenameOUT
            mov TmpFileFlag, FALSE
        .ENDIF
    .ENDIF
    
    Invoke CreateFile, Addr szBamFilenameOUT, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_TEMPORARY, NULL    
    .IF eax == INVALID_HANDLE_VALUE
        Invoke GlobalFree, ptrUncompressedData
        Invoke UnmapViewOfFile, BamMemMapPtrIN
        Invoke CloseHandle, BamMemMapHandleIN
        Invoke CloseHandle, hBamIN    
        mov eax, BU_BAM_OUTPUTFILE_CREATION
        ret
    .ENDIF
    mov hBamOUT, eax

    Invoke CreateFileMapping, hBamOUT, NULL, PAGE_READWRITE, 0, FilesizeOUT, NULL ; Create memory mapped file
    .IF eax == NULL
        Invoke GlobalFree, ptrUncompressedData
        Invoke UnmapViewOfFile, BamMemMapPtrIN
        Invoke CloseHandle, BamMemMapHandleIN
        Invoke CloseHandle, hBamIN    
        Invoke CloseHandle, hBamOUT
        mov eax, BU_BAM_OUTPUTFILE_MAPPING
        ret        
    .ENDIF
    mov BamMemMapHandleOUT, eax

    Invoke MapViewOfFileEx, BamMemMapHandleOUT, FILE_MAP_ALL_ACCESS, 0, 0, 0, NULL
    .IF eax == NULL
        Invoke GlobalFree, ptrUncompressedData
        Invoke UnmapViewOfFile, BamMemMapPtrIN
        Invoke CloseHandle, BamMemMapHandleIN
        Invoke CloseHandle, hBamIN    
        Invoke CloseHandle, BamMemMapHandleOUT
        Invoke CloseHandle, hBamOUT
        mov eax, BU_BAM_OUTPUTFILE_VIEW
        ret
    .ENDIF
    mov BamMemMapPtrOUT, eax

    ; ---------------------------------------------------------------------------------------------------------------------------
    ; Copy uncompressed data in memory to output file mapping, close files and then copy over filenames if applicable
    ; ---------------------------------------------------------------------------------------------------------------------------
    Invoke RtlMoveMemory, BamMemMapPtrOUT, ptrUncompressedData, FilesizeOUT

    Invoke GlobalFree, ptrUncompressedData
    Invoke UnmapViewOfFile, BamMemMapPtrIN
    Invoke CloseHandle, BamMemMapHandleIN
    Invoke CloseHandle, hBamIN
    Invoke UnmapViewOfFile, BamMemMapPtrOUT
    Invoke CloseHandle, BamMemMapHandleOUT
    Invoke CloseHandle, hBamOUT
    
    ;mov eax, lpszBamFilenameOUT
    .IF TmpFileFlag == TRUE  ;eax == NULL || (lpszBamFilenameIN == eax)  ; we need to copy over outfile to infile
        Invoke CopyFile, Addr szBamFilenameOUT, lpszBamFilenameIN, FALSE
        Invoke DeleteFile, Addr szBamFilenameOUT
    .ENDIF
    
    mov eax, BU_SUCCESS
    ret
IEBAMUncompressBAM ENDP



IEBAM_ALIGN
;------------------------------------------------------------------------------
; Uncompresses BAMC file to an area of memory that we allocate for the exact size of data
;------------------------------------------------------------------------------
BAMUncompress PROC USES EBX hBAMFile:DWORD, pBAM:DWORD, dwSize:DWORD
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



END
