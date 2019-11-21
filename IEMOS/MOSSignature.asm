.686
.MMX
.XMM
.model flat,stdcall
option casemap:none

include IEMOS.inc

MOSSignature      PROTO :DWORD

.CODE


IEMOS_ALIGN
;******************************************************************************
; Checks the MOS signatures to determine if they are valid and if MOS file is 
; compressed
;******************************************************************************
MOSSignature PROC USES EBX pMOS:DWORD
    ; check signatures to determine version
    mov ebx, pMOS
    mov eax, [ebx]
    .IF eax == ' SOM' ; MOS
        add ebx, 4
        mov eax, [ebx]
        .IF eax == '  1V' ; V1.0
            mov eax, MOS_VERSION_MOS_V10
        .ELSEIF eax == '  2V' ; V2.0
            mov eax, MOS_VERSION_MOS_V20
        .ELSE
            mov eax, MOS_VERSION_INVALID
        .ENDIF

    .ELSEIF eax == 'CSOM' ; MOSC
        add ebx, 4
        mov eax, [ebx]
        .IF eax == '  1V' ; V1.0
            mov eax, MOS_VERSION_MOSCV10
        .ELSE
            mov eax, MOS_VERSION_INVALID
        .ENDIF            
    .ELSE
        mov eax, MOS_VERSION_INVALID
    .ENDIF
    ret
MOSSignature endp

END

