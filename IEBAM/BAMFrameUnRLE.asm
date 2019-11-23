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


.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Unroll RLE compressed bam frame to RAW data. Returns Frame Size or NULL
;------------------------------------------------------------------------------
BAMFrameUnRLE PROC USES EDI ESI pFrameRLE:DWORD, pFrameRAW:DWORD, FrameRLESize:DWORD, FrameRAWSize:DWORD, FrameWidth:DWORD
    LOCAL FrameWidthDwordAligned:DWORD
    LOCAL pZeroExpandedRLE:DWORD
    LOCAL RLECurrentPos:DWORD
    LOCAL RAWCurrentPos:DWORD
    LOCAL ZEROCurrentPos:DWORD
    LOCAL ZeroCount:DWORD
    LOCAL ZeroTotal:DWORD
    LOCAL LastWidth:DWORD
    LOCAL ZeroSize:DWORD
    LOCAL FrameSize:DWORD
    LOCAL TotalBytesWritten:DWORD

    .IF pFrameRLE == NULL
        mov eax, NULL
        ret
    .ENDIF
    
    .IF pFrameRAW == NULL
        mov eax, NULL
        ret
    .ENDIF

    mov ZEROCurrentPos, 0
    mov RLECurrentPos, 0
    mov RAWCurrentPos, 0
    mov FrameSize, 0
    
    mov eax, 0
    .WHILE eax < FrameRLESize
        mov esi, pFrameRLE
        add esi, RLECurrentPos
        
        movzx eax, byte ptr [esi]
        .IF al == 0h
            mov ecx, RLECurrentPos ; check not at end for next char
            inc ecx
            .IF ecx < FrameRLESize
                inc esi
                movzx eax, byte ptr [esi] ; al contains amount of 0's to copy
                inc eax ; for +1 count
                mov ZeroTotal, eax
                mov ZeroCount, 0
                mov eax, 0
                mov edi, pFrameRAW ;pZeroExpandedRLE
                add edi, RAWCurrentPos ;ZEROCurrentPos
                .WHILE eax < ZeroTotal
                    mov byte ptr [edi], 0h
                    inc edi
                    inc RAWCurrentPos ;ZEROCurrentPos
                    inc FrameSize ;ZeroSize
                    inc ZeroCount
                    mov eax, ZeroCount
                .ENDW
                inc RLECurrentPos
                inc RLECurrentPos

            .ELSE ; if this char is the last one and we have a 0 then just copy it
                mov edi, pFrameRAW ;pZeroExpandedRLE
                add edi, RAWCurrentPos ;ZEROCurrentPos
                mov byte ptr [edi], al
                inc RAWCurrentPos ;ZEROCurrentPos
                inc FrameSize ;ZeroSize
                inc RLECurrentPos
            .ENDIF
        .ELSE
            mov edi, pFrameRAW ;pZeroExpandedRLE
            add edi, RAWCurrentPos ;ZEROCurrentPos
            mov byte ptr [edi], al
            inc RAWCurrentPos ;ZEROCurrentPos
            inc FrameSize ;ZeroSize
            inc RLECurrentPos
        .ENDIF
    
        mov eax, RLECurrentPos
    .ENDW

    mov eax, FrameSize
    ret
BAMFrameUnRLE endp



IEBAM_LIBEND

