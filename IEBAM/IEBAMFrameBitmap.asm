;==============================================================================
;
; IEBAM Library
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

include IEBAM.inc

EXTERNDEF IEBAMFrameDataEntry   :PROTO hIEBAM:DWORD, nFrameEntry:DWORD
EXTERNDEF IEBAMPalette          :PROTO hIEBAM:DWORD
EXTERNDEF BAMFrameDataBitmap    :PROTO dwFrameWidth:DWORD, dwFrameHeight:DWORD, pFrameBMP:DWORD, dwFrameSizeBMP:DWORD, pFramePalette:DWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMFrameBitmap - Returns in eax HBITMAP or NULL. Optional variables pointed 
; to, are filled in if eax is a HBITMAP (!NULL), otherwise vars (if supplied) 
; will be set to 0
;------------------------------------------------------------------------------
IEBAMFrameBitmap PROC USES EBX hIEBAM:DWORD, nFrame:DWORD, lpdwFrameWidth:DWORD, lpdwFrameHeight:DWORD, lpdwFrameXCoord:DWORD, lpdwFrameYCoord:DWORD
    LOCAL FramePalette:DWORD
    LOCAL FrameDataEntry:DWORD
    LOCAL FrameWidth:DWORD
    LOCAL FrameHeight:DWORD
    LOCAL FrameXCoord:DWORD
    LOCAL FrameYCoord:DWORD
    LOCAL FrameSizeBMP:DWORD
    LOCAL FrameBMP:DWORD
    LOCAL FrameBitmapHandle:DWORD
    
    mov FrameWidth, 0
    mov FrameHeight, 0
    mov FrameXCoord, 0
    mov FrameYCoord, 0
    mov FrameBitmapHandle, 0
    
    .IF hIEBAM == NULL
        jmp IEBAMFrameBitmapExit
    .ENDIF    
    
    Invoke IEBAMFrameDataEntry, hIEBAM, nFrame
    .IF eax == NULL
        jmp IEBAMFrameBitmapExit
    .ENDIF
    mov FrameDataEntry, eax

    mov ebx, FrameDataEntry
    mov eax, [ebx].FRAMEDATA.FrameWidth
    .IF eax == 0
        jmp IEBAMFrameBitmapExit
    .ENDIF
    mov FrameWidth, eax
    mov eax, [ebx].FRAMEDATA.FrameHeight
    .IF eax == 0
        jmp IEBAMFrameBitmapExit
    .ENDIF
    mov FrameHeight, eax
    mov eax, [ebx].FRAMEDATA.FrameXcoord
    mov FrameXCoord, eax
    mov eax, [ebx].FRAMEDATA.FrameYcoord
    mov FrameYCoord, eax
    
    mov eax, [ebx].FRAMEDATA.FrameBitmapHandle
    .IF eax != 0
        mov FrameBitmapHandle, eax
        jmp IEBAMFrameBitmapExit
    .ENDIF    
    
    mov eax, [ebx].FRAMEDATA.FrameSizeBMP
    .IF eax == 0
        jmp IEBAMFrameBitmapExit
    .ENDIF
    mov FrameSizeBMP, eax
    mov eax, [ebx].FRAMEDATA.FrameBMP
    .IF eax == 0
        jmp IEBAMFrameBitmapExit
    .ENDIF
    mov FrameBMP, eax

    Invoke IEBAMPalette, hIEBAM
    .IF eax == NULL
        jmp IEBAMFrameBitmapExit
    .ENDIF
    mov FramePalette, eax

    Invoke BAMFrameDataBitmap, FrameWidth, FrameHeight, FrameBMP, FrameSizeBMP, FramePalette
    .IF eax != NULL ; save bitmap handle back to TILEDATA struct
        mov FrameBitmapHandle, eax
        mov ebx, FrameDataEntry
        mov [ebx].FRAMEDATA.FrameBitmapHandle, eax
    .ENDIF

IEBAMFrameBitmapExit:

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
   
    .IF lpdwFrameXCoord != NULL
        mov ebx, lpdwFrameXCoord
        mov eax, FrameXCoord
        mov [ebx], eax
    .ENDIF
    
    .IF lpdwFrameYCoord != NULL
        mov ebx, lpdwFrameYCoord
        mov eax, FrameYCoord
        mov [ebx], eax
    .ENDIF
    
    mov eax, FrameBitmapHandle
    ret
IEBAMFrameBitmap ENDP




IEBAM_LIBEND

