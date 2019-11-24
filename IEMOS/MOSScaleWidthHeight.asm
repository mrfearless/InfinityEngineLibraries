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
; 
;------------------------------------------------------------------------------
MOSScaleWidthHeight PROC USES EBX dwImageWidth:DWORD, dwImageHeight:DWORD, dwPreferredWidth:DWORD, dwPreferredHeight:DWORD, lpdwScaledWidth:DWORD, lpdwScaledHeight:DWORD
    LOCAL dwScaledWidth:DWORD
    LOCAL dwScaledHeight:DWORD
    LOCAL fScaling1:REAL4
    LOCAL fScaling2:REAL4
    LOCAL fScaling:REAL4
    
    finit
    fild dwPreferredWidth
    fild dwImageWidth
    fdiv
    fstp fScaling1
    
    fild dwPreferredHeight
    fild dwImageHeight
    fdiv
    fstp fScaling2
    
    finit               ; init fpu
    fld fScaling1
    fcom fScaling2      ; compare ST(0) with the value of the real4_var variable: 180.0
    fstsw ax            ;copy the Status Word containing the result to AX
    fwait               ;insure the previous instruction is completed
    sahf                ;transfer the condition codes to the CPU's flag register
    fstp st(0)
    jpe error_handler   ;the comparison was indeterminate
                        ;this condition should be verified first
                        ;then only two of the next three conditional jumps
                        ;should become necessary, in whatever order is preferred,
                        ;the third jump being replaced by code to handle that case
    ja    st0_greater   ;when all flags are 0
    jb    st0_lower     ;only the C0 bit (CF flag) would be set if no error
    jz    both_equal    ;only the C3 bit (ZF flag) would be set if no error
    
error_handler:
jmp both_equal
    
st0_greater:
    fld fScaling2
    fstp fScaling
jmp cont

st0_lower:
    fld fScaling1
    fstp fScaling
jmp cont

both_equal:
    mov eax, dwImageWidth
    mov dwScaledWidth, eax
    mov eax, dwImageHeight
    mov dwScaledHeight, eax
jmp exitx


cont:

    finit
    fld fScaling
    fild dwImageWidth
    fmul
    fistp dwScaledWidth

    fld fScaling
    fild dwImageHeight
    fmul
    fistp dwScaledHeight
    
exitx:    
    
    .IF lpdwScaledWidth != 0
        mov ebx, lpdwScaledWidth
        mov eax, dwScaledWidth
        mov [ebx], eax
    .ENDIF
    .IF lpdwScaledHeight != 0
        mov ebx, lpdwScaledHeight
        mov eax, dwScaledHeight
        mov [ebx], eax
    .ENDIF
    
    ret
MOSScaleWidthHeight ENDP


IEMOS_LIBEND

