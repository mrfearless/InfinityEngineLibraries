.686
.MMX
.XMM
.model flat,stdcall
option casemap:none

include IEBIF.inc

BIFSignature      PROTO :DWORD

.CODE


IEBIF_ALIGN
;-----------------------------------------------------------------------------------------
; Checks the BIF signatures to determine if they are valid and if BAM file is compressed
;-----------------------------------------------------------------------------------------
BIFSignature PROC USES EBX pBIF:DWORD
    ; check signatures to determine version
    mov ebx, pBIF
    mov eax, [ebx]
    .IF eax == 'FFIB' ; BIFF
        add ebx, 4
        mov eax, [ebx]
        .IF eax == '  1V' ; V1.0 standard uncompressed BIF v1
            mov eax, BIF_VERSION_BIFFV10
        .ELSEIF eax == '1.1V' ; V1.1 ; witcher NWN etc
            mov eax, BIF_VERSION_BIFFV11
        .ELSE
            mov eax, BIF_VERSION_INVALID
        .ENDIF
    .ELSEIF eax == 'CFIB' ; BIFC ; compressed BIF
        add ebx, 4
        mov eax, [ebx]
        .IF eax == '0.1V' ; V1.0
            mov eax, BIF_VERSION_BIFCV10
        .ELSEIF eax == '1.1V' ; V1.1 BIFC - 09.11.2015 added just in case we use this or it is used in some game in future
            mov eax, BIF_VERSION_BIFCV11
        .ELSE
            mov eax, BIF_VERSION_INVALID
        .ENDIF
    .ELSEIF eax == ' FIB' ; BIF_ ; compressed BIF_
        add ebx, 4
        mov eax, [ebx]
        .IF eax == '0.1V' ; V1.0
            mov eax, BIF_VERSION_BIF_V10
        .ELSEIF eax == '1.1V' ; V1.1 BIF_ - 09.11.2015 added just in case we use this or it is used in some game in future
            mov eax, BIF_VERSION_BIF_V11
        .ELSE
            mov eax, BIF_VERSION_INVALID
        .ENDIF
    .ELSE
        mov eax, BIF_VERSION_INVALID
    .ENDIF
    ret
BIFSignature ENDP


END