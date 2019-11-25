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
include user32.inc
include kernel32.inc

includelib user32.lib
includelib kernel32.lib

include IEBAM.inc

EXTERNDEF BAMCalcDwordAligned   :PROTO dwWidthOrHeight:DWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Converts FrameRAW data to FrameBMP for use in bitmap creation
;------------------------------------------------------------------------------
BAMFrameRAWToFrameBMP PROC USES EDI ESI pFrameRAW:DWORD, pFrameBMP:DWORD, FrameRAWSize:DWORD, FrameBMPSize:DWORD, FrameWidth:DWORD
    LOCAL TotalBytesWritten:DWORD
    LOCAL RAWCurrentPos:DWORD
    LOCAL BMPCurrentPos:DWORD
    LOCAL LastWidth:DWORD
    LOCAL FrameWidthDwordAligned:DWORD
    
    Invoke RtlZeroMemory, pFrameBMP, FrameBMPSize
    
    Invoke BAMCalcDwordAligned, FrameWidth
    mov FrameWidthDwordAligned, eax

    mov TotalBytesWritten, 0
    mov RAWCurrentPos, 0
    mov eax, FrameRAWSize
    mov BMPCurrentPos, eax
    .WHILE eax > 0
        
        mov eax, BMPCurrentPos
        .IF eax < FrameWidth
            mov eax, FrameWidth
            sub eax, BMPCurrentPos
            ;mov ebx, BMPCurrentPos
            ;sub eax, ebx
            mov LastWidth, eax
            add TotalBytesWritten, eax
 
            mov esi, pFrameRAW
            mov edi, pFrameBMP
            add edi, RAWCurrentPos
            Invoke RtlMoveMemory, edi, esi, LastWidth
            .BREAK

        .ELSE
            mov esi, pFrameRAW
            add esi, BMPCurrentPos
            sub esi, FrameWidth
            
            mov edi, pFrameBMP
            add edi, RAWCurrentPos
            
            Invoke RtlMoveMemory, edi, esi, FrameWidth
            mov eax, FrameWidthDwordAligned
            add TotalBytesWritten, eax
            
            mov eax, RAWCurrentPos
            add eax, FrameWidthDwordAligned
            mov RAWCurrentPos, eax
            mov eax, BMPCurrentPos
            sub eax, FrameWidth
            mov BMPCurrentPos, eax
        .ENDIF
        
        mov eax, BMPCurrentPos
    .ENDW
    ret
BAMFrameRAWToFrameBMP ENDP



IEBAM_LIBEND

