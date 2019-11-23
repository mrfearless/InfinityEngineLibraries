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

EXTERNDEF IEBAMFrameEntry   :PROTO hIEBAM:DWORD, nFrameEntry:DWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Returns in eax TRUE if sucessful or FALSE otherwise. On return lpdwFrameHeight and 
; lpdwFrameWidth will contain the values
;------------------------------------------------------------------------------
IEBAMFrameDimensions PROC USES EBX hIEBAM:DWORD, nFrame:DWORD, lpdwFrameWidth:DWORD, lpdwFrameHeight:DWORD
    LOCAL FrameEntryOffset:DWORD
    LOCAL FrameWidth:DWORD
    LOCAL FrameHeight:DWORD
    
    .IF hIEBAM == NULL
        mov eax, FALSE
        ret
    .ENDIF

    Invoke IEBAMFrameEntry, hIEBAM, nFrame
    .IF eax == NULL
        mov eax, FALSE
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
    
    mov eax, TRUE
    ret
IEBAMFrameDimensions ENDP



IEBAM_LIBEND

