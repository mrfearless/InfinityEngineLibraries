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

EXTERNDEF IEBAMTotalFrameEntries    :PROTO hIEBAM:DWORD
EXTERNDEF IEBAMFrameEntries         :PROTO hIEBAM:DWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Find the max width and height for all frames stored in bam. TRUE success, FALSE failure
;------------------------------------------------------------------------------
IEBAMFindMaxWidthHeight PROC USES EBX hIEBAM:DWORD, lpdwMaxWidth:DWORD, lpdwMaxHeight:DWORD
    LOCAL FrameEntries:DWORD
    LOCAL FrameEntryOffset:DWORD
    LOCAL MaxWidth:DWORD
    LOCAL MaxHeight:DWORD
    LOCAL nFrame:DWORD
    LOCAL TotalFrameEntries:DWORD
    
    .IF hIEBAM == NULL
        mov eax, FALSE
        ret
    .ENDIF
    
    Invoke IEBAMTotalFrameEntries, hIEBAM
    .IF eax == NULL
        mov eax, FALSE
        ret
    .ENDIF
    mov TotalFrameEntries, eax
    
    Invoke IEBAMFrameEntries, hIEBAM
    .IF eax == NULL
        mov eax, FALSE
        ret
    .ENDIF
    mov FrameEntries, eax
    mov FrameEntryOffset, eax

    mov MaxWidth, 0
    mov MaxHeight, 0
    mov nFrame, 0

    mov eax, 0
    .WHILE eax < TotalFrameEntries
        mov ebx, FrameEntryOffset
        
        movzx eax, word ptr [ebx].FRAMEV1_ENTRY.FrameWidth
        .IF eax > MaxWidth
            mov MaxWidth, eax
        .ENDIF
        movzx eax, word ptr [ebx].FRAMEV1_ENTRY.FrameHeight
        .IF eax > MaxHeight
            mov MaxHeight, eax
        .ENDIF

        add FrameEntryOffset, SIZEOF FRAMEV1_ENTRY
        
        inc nFrame
        mov eax, nFrame
    .ENDW    
    
    mov ebx, lpdwMaxWidth
    mov eax, MaxWidth
    mov [ebx], eax
    
    mov ebx, lpdwMaxHeight
    mov eax, MaxHeight
    mov [ebx], eax
    
    mov eax, 0    
    ret

IEBAMFindMaxWidthHeight ENDP




IEBAM_LIBEND

