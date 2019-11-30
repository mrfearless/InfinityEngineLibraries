;==============================================================================
;
; IEPVR
;
; Copyright (c) 2019 by fearless
;
; All Rights Reserved
;
; http://github.com/mrfearless
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
;IFDEF DEBUG32
;    PRESERVEXMMREGS equ 1
;    includelib M:\Masm32\lib\Debug32.lib
;    DBG32LIB equ 1
;    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
;    include M:\Masm32\include\debug32.inc
;ENDIF

include windows.inc
include kernel32.inc
include user32.inc
include gdi32.inc

includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib

include IEPVR.inc

; Internal functions start with PVR
; External functions start with IEPVR

;------------------------------------------------------------------------------
; Internal functions:
;------------------------------------------------------------------------------
PVRSignature              PROTO pPVR:DWORD, dwPVRFilesize:DWORD
PVRUncompress             PROTO hPVRFile:DWORD, pPVR:DWORD, dwSize:DWORD
PVRJustFname              PROTO szFilePathName:DWORD, szFileName:DWORD

PVRMem                    PROTO pPVRInMemory:DWORD, lpszPvrFilename:DWORD, dwPvrFilesize:DWORD, dwOpenMode:DWORD

PVRCalcDwordAligned       PROTO dwWidthOrHeight:DWORD

; DXT Decompressor asm functions by Matej Tomcik
DXTDBlockDxt1             PROTO block:DWORD, pixels:DWORD ; Decmopresses single DXT1 block
DXTDImageBackscanDxt1     PROTO ImageWidth:DWORD, ImageHeight:DWORD, inputImage:DWORD, outputPixels:DWORD ; Decompresses entire DXT1 image into a backscan bitmap (ie HBITMAP)
DXTDBlockDxt3             PROTO block:DWORD, pixels:DWORD ; Decmopresses single DXT3 block
DXTDImageBackscanDxt3     PROTO ImageWidth:DWORD, ImageHeight:DWORD, inputImage:DWORD, outputPixels:DWORD ; Decompresses entire DXT3 image into a backscan bitmap (ie HBITMAP)
DXTDBlockDxt5             PROTO block:DWORD, pixels:DWORD ; Decmopresses single DXT5 block
DXTDImageBackscanDxt5     PROTO ImageWidth:DWORD, ImageHeight:DWORD, inputImage:DWORD, outputPixels:DWORD ; Decompresses entire DXT5 image into a backscan bitmap (ie HBITMAP)


.CODE

IEPVR_ALIGN
;------------------------------------------------------------------------------
; IEPVROpen - Returns handle in eax of opened pvr file. NULL if could not alloc enough mem
;------------------------------------------------------------------------------
IEPVROpen PROC USES EBX lpszPvrFilename:DWORD, dwOpenMode:DWORD
    LOCAL hIEPVR:DWORD
    LOCAL hPVRFile:DWORD
    LOCAL PVRFilesize:DWORD
    LOCAL SigReturn:DWORD
    LOCAL PVRMemMapHandle:DWORD
    LOCAL PVRMemMapPtr:DWORD
    LOCAL pPVR:DWORD

    .IF dwOpenMode == IEPVR_MODE_READONLY ; readonly
        Invoke CreateFile, lpszPvrFilename, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ELSE
        Invoke CreateFile, lpszPvrFilename, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ENDIF
 
    .IF eax == INVALID_HANDLE_VALUE
        mov eax, NULL
        ret
    .ENDIF
    mov hPVRFile, eax

    Invoke GetFileSize, hPVRFile, NULL
    mov PVRFilesize, eax

    ;---------------------------------------------------                
    ; File Mapping: Create file mapping for main .pvr
    ;---------------------------------------------------
    .IF dwOpenMode == IEPVR_MODE_READONLY ; readonly
        Invoke CreateFileMapping, hPVRFile, NULL, PAGE_READONLY, 0, 0, NULL ; Create memory mapped file
    .ELSE
        Invoke CreateFileMapping, hPVRFile, NULL, PAGE_READWRITE, 0, 0, NULL ; Create memory mapped file
    .ENDIF   
    .IF eax == NULL
        Invoke CloseHandle, hPVRFile
        mov eax, NULL
        ret
    .ENDIF
    mov PVRMemMapHandle, eax
    
    .IF dwOpenMode == IEPVR_MODE_READONLY ; readonly
        Invoke MapViewOfFileEx, PVRMemMapHandle, FILE_MAP_READ, 0, 0, 0, NULL
    .ELSE
        Invoke MapViewOfFileEx, PVRMemMapHandle, FILE_MAP_ALL_ACCESS, 0, 0, 0, NULL
    .ENDIF
    .IF eax == NULL
        Invoke CloseHandle, PVRMemMapHandle
        Invoke CloseHandle, hPVRFile
        mov eax, NULL
        ret
    .ENDIF
    mov PVRMemMapPtr, eax

    Invoke PVRSignature, PVRMemMapPtr, PVRFilesize
    mov SigReturn, eax
    .IF SigReturn == PVR_VERSION_INVALID ; not a valid pvr file
        Invoke UnmapViewOfFile, PVRMemMapPtr
        Invoke CloseHandle, PVRMemMapHandle
        Invoke CloseHandle, hPVRFile
        mov eax, NULL
        ret    
    
    .ELSEIF SigReturn == PVR_VERSION_PVR3 ; PVR
        Invoke IEPVRMem, PVRMemMapPtr, lpszPvrFilename, PVRFilesize, dwOpenMode
        mov hIEPVR, eax
        .IF hIEPVR == NULL
            Invoke UnmapViewOfFile, PVRMemMapPtr
            Invoke CloseHandle, PVRMemMapHandle
            Invoke CloseHandle, hPVRFile
            mov eax, NULL
            ret    
        .ENDIF
        .IF dwOpenMode == IEPVR_MODE_WRITE ; write (default)
            Invoke UnmapViewOfFile, PVRMemMapPtr
            Invoke CloseHandle, PVRMemMapHandle
            Invoke CloseHandle, hPVRFile
        .ELSE ; else readonly, so keep mapping around till we close file
            mov ebx, hIEPVR
            mov eax, PVRMemMapHandle
            mov [ebx].PVRINFO.PVRMemMapHandle, eax
            mov eax, hPVRFile
            mov [ebx].PVRINFO.PVRFileHandle, eax
        .ENDIF
        
    .ELSEIF SigReturn == PVR_VERSION_PVRZ ; PVRZ
        Invoke PVRUncompress, hPVRFile, PVRMemMapPtr, Addr PVRFilesize
        .IF eax == 0
            ;Invoke UnmapViewOfFile, PVRMemMapPtr
            Invoke CloseHandle, PVRMemMapHandle
            Invoke CloseHandle, hPVRFile        
            mov eax, NULL
            ret
        .ENDIF
        mov pPVR, eax ; save uncompressed location to this var
        Invoke UnmapViewOfFile, PVRMemMapPtr
        Invoke CloseHandle, PVRMemMapHandle
        Invoke CloseHandle, hPVRFile        
        Invoke IEPVRMem, pPVR, lpszPvrFilename, PVRFilesize, dwOpenMode
        mov hIEPVR, eax
        .IF hIEPVR == NULL
            Invoke GlobalFree, pPVR ; pPVR is uncompressed data to clear
            mov eax, NULL
            ret
        .ENDIF
   
    .ENDIF
    ; save original version to handle for later use so we know if orignal file opened was standard PVR or a compressed PVRZ file, if 0 then it was in mem so we assume PVR
    mov ebx, hIEPVR
    mov eax, SigReturn
    mov [ebx].PVRINFO.PVRVersion, eax
    mov eax, hIEPVR
    ret
IEPVROpen ENDP


IEPVR_ALIGN
;------------------------------------------------------------------------------
; IEPVRClose - Close PVR File
;------------------------------------------------------------------------------
IEPVRClose PROC USES EBX hIEPVR:DWORD
    LOCAL dwOpenMode:DWORD
    
    .IF hIEPVR == NULL
        mov eax, 0
        ret
    .ENDIF
    
    mov ebx, hIEPVR
    mov eax, [ebx].PVRINFO.PVROpenMode
    mov dwOpenMode, eax

    mov ebx, hIEPVR
    mov eax, [ebx].PVRINFO.PVRVersion
    .IF eax == PVR_VERSION_PVRZ ; PVRZ in read or write mode uncompresed pvr in memory needs to be cleared
        mov ebx, hIEPVR
        mov eax, [ebx].PVRINFO.PVRMemMapPtr
        .IF eax != NULL
            Invoke GlobalFree, eax
        .ENDIF
    .ELSE ; PVR3 opened in readonly, unmap file etc, otherwise free mem
        .IF dwOpenMode == IEPVR_MODE_READONLY ; Read Only
            mov ebx, hIEPVR
            mov eax, [ebx].PVRINFO.PVRMemMapPtr
            .IF eax != NULL
                Invoke UnmapViewOfFile, eax
            .ENDIF
            mov ebx, hIEPVR
            mov eax, [ebx].PVRINFO.PVRMemMapHandle
            .IF eax != NULL
                Invoke CloseHandle, eax
            .ENDIF
            mov ebx, hIEPVR
            mov eax, [ebx].PVRINFO.PVRFileHandle
            .IF eax != NULL
                Invoke CloseHandle, eax
            .ENDIF
        .ELSE ; free mem if write mode
            mov ebx, hIEPVR
            mov eax, [ebx].PVRINFO.PVRMemMapPtr
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF
        .ENDIF
    .ENDIF
    
    mov eax, hIEPVR
    .IF eax != NULL
        Invoke GlobalFree, eax
    .ENDIF

    mov eax, 0
    ret
IEPVRClose ENDP


IEPVR_ALIGN
;------------------------------------------------------------------------------
; PVRMem - Returns handle in eax of opened pvr file that is already loaded into memory. NULL if could not alloc enough mem
;------------------------------------------------------------------------------
PVRMem PROC USES EBX pPVRInMemory:DWORD, lpszPvrFilename:DWORD, dwPvrFilesize:DWORD, dwOpenMode:DWORD
    LOCAL hIEPVR:DWORD
    LOCAL PVRMemMapPtr:DWORD

    mov eax, pPVRInMemory
    mov PVRMemMapPtr, eax       
    
    ;----------------------------------
    ; Alloc mem for our IEPVR Handle
    ;----------------------------------
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF PVRINFO
    .IF eax == NULL
        ret
    .ENDIF
    mov hIEPVR, eax
    
    mov ebx, hIEPVR
    mov eax, dwOpenMode
    mov [ebx].PVRINFO.PVROpenMode, eax
    mov eax, PVRMemMapPtr
    mov [ebx].PVRINFO.PVRMemMapPtr, eax
    
    lea eax, [ebx].PVRINFO.PVRFilename
    Invoke lstrcpyn, eax, lpszPvrFilename, MAX_PATH
    
    mov ebx, hIEPVR
    mov eax, dwPvrFilesize
    mov [ebx].PVRINFO.PVRFilesize, eax

    ;----------------------------------
    ; PVR Header
    ;----------------------------------
    .IF dwOpenMode == IEPVR_MODE_WRITE
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF PVR3_HEADER
        .IF eax == NULL
            Invoke GlobalFree, hIEPVR
            mov eax, NULL
            ret
        .ENDIF    
        mov ebx, hIEPVR
        mov [ebx].PVRINFO.PVRHeaderPtr, eax
        mov ebx, PVRMemMapPtr
        Invoke RtlMoveMemory, eax, ebx, SIZEOF PVR3_HEADER
    .ELSE
        mov ebx, hIEPVR
        mov eax, PVRMemMapPtr
        mov [ebx].PVRINFO.PVRHeaderPtr, eax
    .ENDIF
    mov ebx, hIEPVR
    mov eax, SIZEOF PVR3_HEADER
    mov [ebx].PVRINFO.PVRHeaderSize, eax   

    ;----------------------------------
    ; Double check file in mem is PVR
    ;----------------------------------
    Invoke PVRSignature, PVRMemMapPtr, dwPvrFilesize
    .IF eax != PVR_VERSION_PVR3
        .IF dwOpenMode == IEPVR_MODE_WRITE
            mov eax, PVRMemMapPtr
            .IF eax != NULL
                Invoke GlobalFree, eax
            .ENDIF
        .ENDIF
        Invoke GlobalFree, hIEPVR
        mov eax, NULL
        ret
    .ENDIF
    

    mov eax, hIEPVR
    ret
PVRMem ENDP



IEPVR_LIBEND


