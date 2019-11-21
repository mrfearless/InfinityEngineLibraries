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

include IEMOS.inc

MOSUncompress           PROTO :DWORD, :DWORD, :DWORD


EXTERNDEF MOSSignature      :PROTO :DWORD
EXTERNDEF MOSJustFname      :PROTO :DWORD, :DWORD

.DATA
UncompressTmpExt        DB ".tmp",0
UncompressMOSExt        DB ".mos",0


.CODE

IEMOS_ALIGN
;-------------------------------------------------------------------------------------
; Uncompress specified mos file name
;-------------------------------------------------------------------------------------
IEMOSUncompressMOS PROC USES EBX lpszMosFilenameIN:DWORD, lpszMosFilenameOUT:DWORD
    LOCAL szMosFilenameOUT[MAX_PATH]:BYTE
    LOCAL szMosFilenameALT[MAX_PATH]:BYTE
    LOCAL hMosIN:DWORD
    LOCAL hMosOUT:DWORD
    LOCAL MosMemMapHandleIN:DWORD
    LOCAL MosMemMapHandleOUT:DWORD
    LOCAL MosMemMapPtrIN:DWORD
    LOCAL MosMemMapPtrOUT:DWORD
    LOCAL MosFilesizeIN:DWORD
    LOCAL MosFilesizeHighIN:DWORD
    LOCAL FilesizeOUT:DWORD
    LOCAL ptrUncompressedData:DWORD
    LOCAL Version:DWORD
    LOCAL TmpFileFlag:DWORD
    
    mov TmpFileFlag, FALSE
    
    ; ---------------------------------------------------------------------------------------------------------------------------
    ; Input File
    ; ---------------------------------------------------------------------------------------------------------------------------
    Invoke CreateFile, lpszMosFilenameIN, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL ; readonly
    .IF eax == INVALID_HANDLE_VALUE
        mov eax, MU_MOS_INPUTFILE_OPEN
        ret
    .ENDIF
    mov hMosIN, eax
    
    ; check file size is not 0
    Invoke GetFileSize, hMosIN, Addr MosFilesizeHighIN
    mov MosFilesizeIN, eax
    .IF MosFilesizeIN == 0 && MosFilesizeHighIN == 0
        Invoke CloseHandle, hMosIN
        mov eax, MU_MOS_INPUTFILE_ZEROSIZE
        ret
    .ENDIF   
    
    .IF MosFilesizeIN > 20000000h || MosFilesizeHighIN > 0 ; 2^29 = 536870912 = 536,870,912 bytes = 536MB
        mov eax, MU_MOS_TOO_LARGE
        ret
    .ENDIF
    
    Invoke CreateFileMapping, hMosIN, NULL, PAGE_READONLY, 0, 0, NULL ; Create memory mapped file
    .IF eax == NULL
        Invoke CloseHandle, hMosIN
        mov eax, MU_MOS_INPUTFILE_MAPPING
        ret        
    .ENDIF
    mov MosMemMapHandleIN, eax

    Invoke MapViewOfFileEx, MosMemMapHandleIN, FILE_MAP_READ, 0, 0, 0, NULL
    .IF eax == NULL
        Invoke CloseHandle, MosMemMapHandleIN
        Invoke CloseHandle, hMosIN
        mov eax, MU_MOS_INPUTFILE_VIEW
        ret
    .ENDIF
    mov MosMemMapPtrIN, eax
    
    Invoke MOSSignature, MosMemMapPtrIN
    mov Version, eax

    .IF Version == MOS_VERSION_MOSCV10 ; MOSC compressed, ready to uncompress
        Invoke MOSUncompress, hMosIN, MosMemMapPtrIN, Addr FilesizeOUT
        .IF eax == 0
            Invoke UnmapViewOfFile, MosMemMapPtrIN
            Invoke CloseHandle, MosMemMapHandleIN
            Invoke CloseHandle, hMosIN        
            mov eax, MU_MOS_UNCOMPRESS_ERROR
            ret
        .ENDIF
        mov ptrUncompressedData, eax

    .ELSE ; if 0,1,2 or other
        Invoke UnmapViewOfFile, MosMemMapPtrIN
        Invoke CloseHandle, MosMemMapHandleIN
        Invoke CloseHandle, hMosIN
        .IF Version == MOS_VERSION_INVALID ; invalid mos
            mov eax, MU_MOS_INVALID
        .ELSEIF Version == MOS_VERSION_MOS_V10 ; already uncompressed
            mov eax, MU_MOS_ALREADY_UNCOMPRESSED
        .ELSEIF Version == MOS_VERSION_MOS_V20 ; MOS 2.0 not supported
            mov eax, MU_MOS_FORMAT_UNSUPPORTED
        .ELSE
            mov eax, MU_MOS_FORMAT_UNSUPPORTED
        .ENDIF
        ret
    .ENDIF
    
    ; ---------------------------------------------------------------------------------------------------------------------------
    ; Output File 
    ; ---------------------------------------------------------------------------------------------------------------------------
    mov eax, lpszMosFilenameOUT
    .IF eax == NULL ;|| (lpszMosFilenameIN == eax) ; use same name for output, but temporarily use another file name before copying over exiting one
        Invoke szCopy, lpszMosFilenameIN, Addr szMosFilenameOUT
        Invoke szCatStr, Addr szMosFilenameOUT, Addr UncompressTmpExt
        mov TmpFileFlag, TRUE
    .ELSE
        
        Invoke Cmpi, lpszMosFilenameOUT, lpszMosFilenameIN
        .IF eax == 0 ; match        
            Invoke szCopy, lpszMosFilenameIN, Addr szMosFilenameOUT
            Invoke szCatStr, Addr szMosFilenameOUT, Addr UncompressTmpExt
            mov TmpFileFlag, TRUE
        .ELSE
            Invoke szCopy, lpszMosFilenameOUT, Addr szMosFilenameOUT
            mov TmpFileFlag, FALSE
        .ENDIF
    .ENDIF
    
    Invoke CreateFile, Addr szMosFilenameOUT, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_TEMPORARY, NULL    
    .IF eax == INVALID_HANDLE_VALUE
        Invoke GlobalFree, ptrUncompressedData
        Invoke UnmapViewOfFile, MosMemMapPtrIN
        Invoke CloseHandle, MosMemMapHandleIN
        Invoke CloseHandle, hMosIN    
        mov eax, MU_MOS_OUTPUTFILE_CREATION
        ret
    .ENDIF
    mov hMosOUT, eax

    Invoke CreateFileMapping, hMosOUT, NULL, PAGE_READWRITE, 0, FilesizeOUT, NULL ; Create memory mapped file
    .IF eax == NULL
        Invoke GlobalFree, ptrUncompressedData
        Invoke UnmapViewOfFile, MosMemMapPtrIN
        Invoke CloseHandle, MosMemMapHandleIN
        Invoke CloseHandle, hMosIN    
        Invoke CloseHandle, hMosOUT
        mov eax, MU_MOS_OUTPUTFILE_MAPPING
        ret        
    .ENDIF
    mov MosMemMapHandleOUT, eax

    Invoke MapViewOfFileEx, MosMemMapHandleOUT, FILE_MAP_ALL_ACCESS, 0, 0, 0, NULL
    .IF eax == NULL
        Invoke GlobalFree, ptrUncompressedData
        Invoke UnmapViewOfFile, MosMemMapPtrIN
        Invoke CloseHandle, MosMemMapHandleIN
        Invoke CloseHandle, hMosIN    
        Invoke CloseHandle, MosMemMapHandleOUT
        Invoke CloseHandle, hMosOUT
        mov eax, MU_MOS_OUTPUTFILE_VIEW
        ret
    .ENDIF
    mov MosMemMapPtrOUT, eax

    ; ---------------------------------------------------------------------------------------------------------------------------
    ; Copy uncompressed data in memory to output file mapping, close files and then copy over filenames if applicable
    ; ---------------------------------------------------------------------------------------------------------------------------
    Invoke RtlMoveMemory, MosMemMapPtrOUT, ptrUncompressedData, FilesizeOUT

    Invoke GlobalFree, ptrUncompressedData
    Invoke UnmapViewOfFile, MosMemMapPtrIN
    Invoke CloseHandle, MosMemMapHandleIN
    Invoke CloseHandle, hMosIN
    Invoke UnmapViewOfFile, MosMemMapPtrOUT
    Invoke CloseHandle, MosMemMapHandleOUT
    Invoke CloseHandle, hMosOUT
    
    ;mov eax, lpszMosFilenameOUT
    .IF TmpFileFlag == TRUE  ;eax == NULL || (lpszMosFilenameIN == eax)  ; we need to copy over outfile to infile
        Invoke CopyFile, Addr szMosFilenameOUT, lpszMosFilenameIN, FALSE
        Invoke DeleteFile, Addr szMosFilenameOUT
    .ENDIF
    
    mov eax, MU_SUCCESS
    ret
IEMOSUncompressMOS ENDP



IEMOS_ALIGN
;******************************************************************************
; Uncompresses MOSC file to an area of memory that we allocate for the exact 
; size of data
;******************************************************************************
MOSUncompress PROC USES EBX hMOSFile:DWORD, pMOS:DWORD, dwSize:DWORD
    LOCAL dest:DWORD
    LOCAL src:DWORD
    LOCAL MOSU_Size:DWORD
    LOCAL BytesRead:DWORD
    LOCAL MOSFilesize:DWORD
    LOCAL MOSC_UncompressedSize:DWORD
    LOCAL MOSC_CompressedSize:DWORD
    
    Invoke GetFileSize, hMOSFile, NULL
    mov MOSFilesize, eax
    mov ebx, pMOS
    mov eax, [ebx].MOSC_HEADER.UncompressedLength
    mov MOSC_UncompressedSize, eax
    mov eax, MOSFilesize
    sub eax, 0Ch ; take away the MOSC header 12 bytes = 0xC
    mov MOSC_CompressedSize, eax ; set correct compressed size = length of file minus MOSC header length

    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, MOSC_UncompressedSize
    .IF eax != NULL
        mov dest, eax
        mov eax, pMOS ;MOSMemMapPtr
        add eax, 0Ch ; add MOSC Header to Memory map to start at correct offset for uncompressing
        mov src, eax
        Invoke uncompress, dest, Addr MOSC_UncompressedSize, src, MOSC_CompressedSize
        .IF eax == Z_OK ; ok
            mov eax, MOSC_UncompressedSize
            mov ebx, dwSize
            mov [ebx], eax
        
            mov eax, dest
            ret
        .ENDIF
    .ENDIF                  
    mov eax, 0        
    ret
MOSUncompress ENDP



END
