.686
.MMX
.XMM
.model flat,stdcall
option casemap:none

include windows.inc

include IEBAM.inc

BAMSignature      PROTO pBAM:DWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Checks the BAM signatures to determine if they are valid and if BAM file is compressed
;------------------------------------------------------------------------------
BAMSignature PROC pBAM:DWORD
    ; check signatures to determine version
    mov ebx, pBAM
    mov eax, [ebx]
    .IF eax == ' MAB' ; BAM
        add ebx, 4
        mov eax, [ebx]
        .IF eax == '  1V' ; V1.0
            mov eax, BAM_VERSION_BAM_V10
        .ELSEIF eax == '  2V' ; V2.0
            mov eax, BAM_VERSION_BAM_V20
        .ELSE
            mov eax, BAM_VERSION_INVALID
        .ENDIF

    .ELSEIF eax == 'CMAB' ; BAMC
        add ebx, 4
        mov eax, [ebx]
        .IF eax == '  1V' ; V1.0
            mov eax, BAM_VERSION_BAMCV10
        .ELSE
            mov eax, BAM_VERSION_INVALID
        .ENDIF            
    .ELSE
        mov eax, BAM_VERSION_INVALID
    .ENDIF
    ret
BAMSignature ENDP


IEBAM_LIBEND