;==============================================================================
;
; IEMOS Library
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

include IEMOS.inc


.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSColumnsRows - Returns columns and rows in pointer to variables 
; provided
;------------------------------------------------------------------------------
IEMOSColumnsRows PROC USES EBX hIEMOS:DWORD, lpdwColumns:DWORD, lpdwRows:DWORD
    LOCAL dwColumns:DWORD
    LOCAL dwRows:DWORD
    
    mov dwColumns, 0
    mov dwRows, 0
    .IF hIEMOS != NULL
        mov ebx, hIEMOS
        mov ebx, [ebx].MOSINFO.MOSHeaderPtr
        .IF ebx != NULL
            movzx eax, word ptr [ebx].MOSV1_HEADER.BlockColumns
            mov dwColumns, eax
            movzx eax, word ptr [ebx].MOSV1_HEADER.BlockRows
            mov dwRows, eax
        .ENDIF
    .ENDIF
    .IF lpdwColumns != NULL
        mov ebx, lpdwColumns
        mov eax, dwColumns
        mov [ebx], eax
    .ENDIF
    .IF lpdwRows != NULL
        mov ebx, lpdwRows
        mov eax, dwRows
        mov [ebx], eax
    .ENDIF
    xor eax, eax
    ret
IEMOSColumnsRows ENDP



IEMOS_LIBEND

