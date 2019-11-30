;==============================================================================
;
; IEPVR Library
;
; Copyright (c) 2019 by fearless
;
; http://github.com/mrfearless/InfinityEngineLibraries
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

include zlibstat1211.inc
includelib zlibstat1211.lib

include IEPVR.inc

EXTERNDEF PVRUncompress     :PROTO hPVRFile:DWORD, pPVR:DWORD, dwSize:DWORD
EXTERNDEF PVRSignature      :PROTO pPVR:DWORD
EXTERNDEF PVRJustFname      :PROTO szFilePathName:DWORD, szFileName:DWORD

.DATA
UncompressTmpExt            DB ".tmp",0
UncompressPVRExt            DB ".pvr",0


.CODE


IEPVR_ALIGN
;-------------------------------------------------------------------------------------
; Uncompress specified pvr file name
;-------------------------------------------------------------------------------------
IEPVRUncompressPVR PROC USES EBX lpszPvrFilenameIN:DWORD, lpszPvrFilenameOUT:DWORD
    LOCAL szPvrFilenameOUT[MAX_PATH]:BYTE
    LOCAL szPvrFilenameALT[MAX_PATH]:BYTE
    LOCAL hPvrIN:DWORD
    LOCAL hPvrOUT:DWORD
    LOCAL PvrMemMapHandleIN:DWORD
    LOCAL PvrMemMapHandleOUT:DWORD
    LOCAL PvrMemMapPtrIN:DWORD
    LOCAL PvrMemMapPtrOUT:DWORD
    LOCAL PvrFilesizeIN:DWORD
    LOCAL PvrFilesizeHighIN:DWORD
    LOCAL FilesizeOUT:DWORD
    LOCAL ptrUncompressedData:DWORD
    LOCAL Version:DWORD
    LOCAL TmpFileFlag:DWORD
    
    mov TmpFileFlag, FALSE
    
    ; ---------------------------------------------------------------------------------------------------------------------------
    ; Input File
    ; ---------------------------------------------------------------------------------------------------------------------------
    Invoke CreateFile, lpszPvrFilenameIN, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL ; readonly
    .IF eax == INVALID_HANDLE_VALUE
        mov eax, PU_PVR_INPUTFILE_OPEN
        ret
    .ENDIF
    mov hPvrIN, eax
    
    ; check file size is not 0
    Invoke GetFileSize, hPvrIN, Addr PvrFilesizeHighIN
    mov PvrFilesizeIN, eax
    .IF PvrFilesizeIN == 0 && PvrFilesizeHighIN == 0
        Invoke CloseHandle, hPvrIN
        mov eax, PU_PVR_INPUTFILE_ZEROSIZE
        ret
    .ENDIF   
    
    .IF PvrFilesizeIN > 20000000h || PvrFilesizeHighIN > 0 ; 2^29 = 536870912 = 536,870,912 bytes = 536MB
        mov eax, PU_PVR_TOO_LARGE
        ret
    .ENDIF
    
    Invoke CreateFileMapping, hPvrIN, NULL, PAGE_READONLY, 0, 0, NULL ; Create memory mapped file
    .IF eax == NULL
        Invoke CloseHandle, hPvrIN
        mov eax, PU_PVR_INPUTFILE_MAPPING
        ret        
    .ENDIF
    mov PvrMemMapHandleIN, eax

    Invoke MapViewOfFileEx, PvrMemMapHandleIN, FILE_MAP_READ, 0, 0, 0, NULL
    .IF eax == NULL
        Invoke CloseHandle, PvrMemMapHandleIN
        Invoke CloseHandle, hPvrIN
        mov eax, PU_PVR_INPUTFILE_VIEW
        ret
    .ENDIF
    mov PvrMemMapPtrIN, eax
    
    Invoke PVRSignature, PvrMemMapPtrIN
    mov Version, eax

    .IF Version == PVR_VERSION_PVRZ ; PVRZ compressed, ready to uncompress
        Invoke PVRUncompress, hPvrIN, PvrMemMapPtrIN, Addr FilesizeOUT
        .IF eax == 0
            Invoke UnmapViewOfFile, PvrMemMapPtrIN
            Invoke CloseHandle, PvrMemMapHandleIN
            Invoke CloseHandle, hPvrIN        
            mov eax, PU_PVR_UNCOMPRESS_ERROR
            ret
        .ENDIF
        mov ptrUncompressedData, eax

    .ELSE ; if 0,1,2 or other
        Invoke UnmapViewOfFile, PvrMemMapPtrIN
        Invoke CloseHandle, PvrMemMapHandleIN
        Invoke CloseHandle, hPvrIN
        .IF Version == PVR_VERSION_INVALID ; invalid pvr
            mov eax, PU_PVR_INVALID
        .ELSEIF Version == PVR_VERSION_PVR3 ; already uncompressed
            mov eax, PU_PVR_ALREADY_UNCOMPRESSED
        .ELSE
            mov eax, PU_PVR_FORMAT_UNSUPPORTED
        .ENDIF
        ret
    .ENDIF
    
    ; ---------------------------------------------------------------------------------------------------------------------------
    ; Output File 
    ; ---------------------------------------------------------------------------------------------------------------------------
    mov eax, lpszPvrFilenameOUT
    .IF eax == NULL ;|| (lpszPvrFilenameIN == eax) ; use same name for output, but temporarily use another file name before copying over exiting one
        Invoke szCopy, lpszPvrFilenameIN, Addr szPvrFilenameOUT
        Invoke szCatStr, Addr szPvrFilenameOUT, Addr UncompressTmpExt
        mov TmpFileFlag, TRUE
    .ELSE
        
        Invoke Cmpi, lpszPvrFilenameOUT, lpszPvrFilenameIN
        .IF eax == 0 ; match        
            Invoke szCopy, lpszPvrFilenameIN, Addr szPvrFilenameOUT
            Invoke szCatStr, Addr szPvrFilenameOUT, Addr UncompressTmpExt
            mov TmpFileFlag, TRUE
        .ELSE
            Invoke szCopy, lpszPvrFilenameOUT, Addr szPvrFilenameOUT
            mov TmpFileFlag, FALSE
        .ENDIF
    .ENDIF
    
    Invoke CreateFile, Addr szPvrFilenameOUT, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_TEMPORARY, NULL    
    .IF eax == INVALID_HANDLE_VALUE
        Invoke GlobalFree, ptrUncompressedData
        Invoke UnmapViewOfFile, PvrMemMapPtrIN
        Invoke CloseHandle, PvrMemMapHandleIN
        Invoke CloseHandle, hPvrIN    
        mov eax, PU_PVR_OUTPUTFILE_CREATION
        ret
    .ENDIF
    mov hPvrOUT, eax

    Invoke CreateFileMapping, hPvrOUT, NULL, PAGE_READWRITE, 0, FilesizeOUT, NULL ; Create memory mapped file
    .IF eax == NULL
        Invoke GlobalFree, ptrUncompressedData
        Invoke UnmapViewOfFile, PvrMemMapPtrIN
        Invoke CloseHandle, PvrMemMapHandleIN
        Invoke CloseHandle, hPvrIN    
        Invoke CloseHandle, hPvrOUT
        mov eax, PU_PVR_OUTPUTFILE_MAPPING
        ret        
    .ENDIF
    mov PvrMemMapHandleOUT, eax

    Invoke MapViewOfFileEx, PvrMemMapHandleOUT, FILE_MAP_ALL_ACCESS, 0, 0, 0, NULL
    .IF eax == NULL
        Invoke GlobalFree, ptrUncompressedData
        Invoke UnmapViewOfFile, PvrMemMapPtrIN
        Invoke CloseHandle, PvrMemMapHandleIN
        Invoke CloseHandle, hPvrIN    
        Invoke CloseHandle, PvrMemMapHandleOUT
        Invoke CloseHandle, hPvrOUT
        mov eax, PU_PVR_OUTPUTFILE_VIEW
        ret
    .ENDIF
    mov PvrMemMapPtrOUT, eax

    ; ---------------------------------------------------------------------------------------------------------------------------
    ; Copy uncompressed data in memory to output file mapping, close files and then copy over filenames if applicable
    ; ---------------------------------------------------------------------------------------------------------------------------
    Invoke RtlMoveMemory, PvrMemMapPtrOUT, ptrUncompressedData, FilesizeOUT

    Invoke GlobalFree, ptrUncompressedData
    Invoke UnmapViewOfFile, PvrMemMapPtrIN
    Invoke CloseHandle, PvrMemMapHandleIN
    Invoke CloseHandle, hPvrIN
    Invoke UnmapViewOfFile, PvrMemMapPtrOUT
    Invoke CloseHandle, PvrMemMapHandleOUT
    Invoke CloseHandle, hPvrOUT
    
    ;mov eax, lpszPvrFilenameOUT
    .IF TmpFileFlag == TRUE  ;eax == NULL || (lpszPvrFilenameIN == eax)  ; we need to copy over outfile to infile
        Invoke CopyFile, Addr szPvrFilenameOUT, lpszPvrFilenameIN, FALSE
        Invoke DeleteFile, Addr szPvrFilenameOUT
    .ENDIF
    
    mov eax, PU_SUCCESS
    ret
IEPVRUncompressPVR ENDP



IEPVR_LIBEND

