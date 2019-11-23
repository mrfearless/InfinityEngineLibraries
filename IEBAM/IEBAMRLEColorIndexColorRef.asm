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

EXTERNDEF IEBAMHeader               :PROTO hIEBAM:DWORD
EXTERNDEF IEBAMPaletteEntry         :PROTO hIEBAM:DWORD, PaletteIndex:DWORD
EXTERNDEF IEBAMConvertABGRtoARGB    :PROTO dwBGRA:DWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Returns in eax ColorRef of the RLEColorIndex or -1 otherwise
;------------------------------------------------------------------------------
IEBAMRLEColorIndexColorRef PROC USES EBX hIEBAM:DWORD
    LOCAL BamHeaderPtr:DWORD
    LOCAL RLEColorIndex:DWORD
    LOCAL ABGR:DWORD
    
    .IF hIEBAM == NULL
        mov eax, -1
        ret
    .ENDIF
    
    Invoke IEBAMHeader, hIEBAM
    .IF eax == NULL
        mov eax, -1
        ret
    .ENDIF
    mov BamHeaderPtr, eax
    mov ebx, BamHeaderPtr
    
    movzx eax, byte ptr [ebx].BAMV1_HEADER.ColorIndexRLE
    mov RLEColorIndex, eax
    
    Invoke IEBAMPaletteEntry, hIEBAM, RLEColorIndex
    mov ebx, [eax]
    mov ABGR, ebx
    
    Invoke IEBAMConvertABGRtoARGB, ABGR
    AND eax, 00FFFFFFh ; to mask off alpha
    ret
IEBAMRLEColorIndexColorRef endp



IEBAM_LIBEND

