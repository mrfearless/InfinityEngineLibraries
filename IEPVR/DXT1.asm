;==============================================================================
;
; IEPVR Library
;
; DXT Decompressor by Matej Tomcik
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
include IEPVR.inc

DXTDBlockDxt1             PROTO block:DWORD, pixels:DWORD ; Decmopresses single DXT1 block
DXTDImageBackscanDxt1     PROTO ImageWidth:DWORD, ImageHeight:DWORD, inputImage:DWORD, outputPixels:DWORD ; Decompresses entire DXT1 image into a backscan bitmap (ie HBITMAP)
DXTDImageBackscanDxt1PURE PROTO ImageWidth:DWORD, ImageHeight:DWORD, inputImage:DWORD, outputPixels:DWORD ; Decompresses entire DXT1 image into a backscan bitmap (ie HBITMAP)
DXTDImageBackscanDxt1SSE  PROTO ImageWidth:DWORD, ImageHeight:DWORD, inputImage:DWORD, outputPixels:DWORD ; Decompresses entire DXT1 image into a backscan bitmap (ie HBITMAP)

EXTERNDEF DXTSSE :PROTO

.DATA
; External definition of aRGB565Lookup lookup table
EXTERNDEF aRGB565Lookup:DWORD

.CODE


IEPVR_ALIGN
;------------------------------------------------------------------------------
; Decompresses entire DXT1 image
;------------------------------------------------------------------------------
DXTDImageBackscanDxt1 PROC dwWidth:DWORD, dwHeight:DWORD, pbBlock:DWORD, pdwPixels:DWORD
    Invoke DXTSSE
    .IF eax == TRUE
        Invoke DXTDImageBackscanDxt1SSE, dwWidth, dwHeight, pbBlock, pdwPixels
    .ELSE
        Invoke DXTDImageBackscanDxt1PURE, dwWidth, dwHeight, pbBlock, pdwPixels
    .ENDIF
    ret
DXTDImageBackscanDxt1 ENDP


IEPVR_ALIGN
;------------------------------------------------------------------------------
; Decompresses DXT1 block
;------------------------------------------------------------------------------
OPTION PROLOGUE:NONE
OPTION EPILOGUE:NONE
DXTDBlockDxt1 PROC pbBlock:DWORD, pdwPixels:DWORD
	; Allocate space for color table
	sub esp, 16
	; Save registers
	push esi
	push edi

	; Unpack first two colors
	mov esi, pbBlock			; Move to the first color
	mov edi, pdwPixels			; Setup destination where we generate pixels
	movzx eax, word ptr [esi]	; Get first color word
	mov eax, dword ptr [offset aRGB565Lookup + eax * 4]
	mov [ebp - 4], eax			; Save RGB24 to color table
	movzx eax, word ptr [esi + 2]	; Get second color word
	mov eax, dword ptr [offset aRGB565Lookup + eax * 4]
	mov [ebp - 8], eax			; Save RGB24 to color table

	; Calculate midpoint colors
	cmp [ebp - 4], eax
	jae fcgts
	; First color is less than or equal to the second
	; Calculate third color
	mov dword ptr [ebp - 12], 0FF000000h
	movzx eax, byte ptr [ebp - 2]
	movzx edx, byte ptr [ebp - 6]
	add eax, edx
	shr eax, 1
	shl eax, 16
	or dword ptr [ebp - 12], eax
	movzx eax, byte ptr [ebp - 3]
	movzx edx, byte ptr [ebp - 7]
	add eax, edx
	shr eax, 1
	shl eax, 8
	or dword ptr [ebp - 12], eax
	movzx eax, byte ptr [ebp - 4]
	movzx edx, byte ptr [ebp - 8]
	add eax, edx
	shr eax, 1
	or dword ptr [ebp - 12], eax
	; Calculate fourth color
	mov dword ptr [ebp - 16], 0h ; Set fourth color to transparent
	jmp copy
fcgts:
	; First color is greater than the second
	; Calculate third color
	mov dword ptr [ebp - 12], 0FF000000h
	movzx eax, byte ptr [ebp - 2]
	movzx ecx, byte ptr [ebp - 6]
	lea ecx, [ecx + eax * 2]
	mov eax, 0AAAAAAABh
	mul ecx
	shr edx, 1
	shl edx, 16
	or dword ptr [ebp - 12], edx
	movzx eax, byte ptr [ebp - 3]
	movzx ecx, byte ptr [ebp - 7]
	lea ecx, [ecx + eax * 2]
	mov eax, 0AAAAAAABh
	mul ecx
	shr edx, 1
	shl edx, 8
	or dword ptr [ebp - 12], edx
	movzx eax, byte ptr [ebp - 4]
	movzx ecx, byte ptr [ebp - 8]
	lea ecx, [ecx + eax * 2]
	mov eax, 0AAAAAAABh
	mul ecx
	shr edx, 1
	or dword ptr [ebp - 12], edx
	; Calculate fourth color
	mov dword ptr [ebp - 16], 0FF000000h
	movzx eax, byte ptr [ebp - 6]
	movzx ecx, byte ptr [ebp - 2]
	lea ecx, [ecx + eax * 2]
	mov eax, 0AAAAAAABh
	mul ecx
	shr edx, 1
	shl edx, 16
	or dword ptr [ebp - 16], edx
	movzx eax, byte ptr [ebp - 7]
	movzx ecx, byte ptr [ebp - 3]
	lea ecx, [ecx + eax * 2]
	mov eax, 0AAAAAAABh
	mul ecx
	shr edx, 1
	shl edx, 8
	or dword ptr [ebp - 16], edx
	movzx eax, byte ptr [ebp - 8]
	movzx ecx, byte ptr [ebp - 4]
	lea ecx, [ecx + eax * 2]
	mov eax, 0AAAAAAABh
	mul ecx
	shr edx, 1
	or dword ptr [ebp - 16], edx

copy:
	; Set EBP to point to the last color. Color table is at lower addresses than EBP.
	; Since memory reference operator can only add offsets, we invert
	; indicies and set EBP to point to the last color thus adding inverted index to the ebp
	; will become the same as substracting non inverted index from the ebp.
	sub ebp, 16

	; Get indices
	mov eax, dword ptr [esi + 4]
	not eax	; Invert indices since we can only add offsets in mov operator []

	; Setup location where our cycle ends (64 bit because 4x4 32bit color pixel table)
	lea ecx, [edi + 64]
lp:
	mov edx, eax
	and edx, 03h
	mov edx, [ebp + edx * 4]
	mov [edi], edx
	shr eax, 2
	add edi, 4
	cmp edi, ecx
	jne lp

	; Restore original EBP position
	add ebp, 16
	; Restore registers
	pop edi
	pop esi
	; Deallocate color table
	mov esp, ebp

	ret
DXTDBlockDxt1 ENDP
OPTION PROLOGUE:PrologueDef
OPTION EPILOGUE:EpilogueDef


IEPVR_ALIGN
;------------------------------------------------------------------------------
; Decompresses entire DXT1 image into a backscan bitmap (ie HBITMAP)
; Width and height must be a multiple of 4. To align dim, use this formula: ((dim + 3) / 4) * 4
; Pixels must be DWORDs
;------------------------------------------------------------------------------
OPTION PROLOGUE:NONE
OPTION EPILOGUE:NONE
DXTDImageBackscanDxt1PURE PROC dwWidth:DWORD, dwHeight:DWORD, pbBlock:DWORD, pdwPixels:DWORD
	sub esp, 64			; Allocate pixel block
	push edi			; Save registers
	push esi
	push ebx

	lea esi, [ebp - 64]	; Setup ESI to point to the intermediate pixel buffer

	shl dwWidth, 2		; Multiply width by 4 to get scanline size
	mov eax, dwHeight	; Multiply height by scanline size to get the bitmap size
	mul dwWidth
	mov dwHeight, eax
row:
	xor ebx, ebx		; Reset column counter
col:
	push esi			; Address of the pixel block
	push pbBlock		; Address of the source block
	call DXTDBlockDxt1
	add esp, 8
	add pbBlock, 8		; Increment block pointer by 8 (DXT1 block size)

	mov edi, pdwPixels	; Get pointer to the beginning of the the current block
	add edi, dwHeight

	; Copy first line
	sub edi, dwWidth	; Substract one scanline
	mov eax, [esi]
	mov dword ptr [edi + ebx], eax
	mov eax, [esi + 04h]
	mov dword ptr [edi + ebx + 4], eax
	mov eax, [esi + 08h]
	mov dword ptr [edi + ebx + 8], eax
	mov eax, [esi + 0Ch]
	mov dword ptr [edi + ebx + 12], eax

	; Copy second line
	sub edi, dwWidth	; Substract one scanline
	mov eax, [esi + 010h]
	mov dword ptr [edi + ebx], eax
	mov eax, [esi + 014h]
	mov dword ptr [edi + ebx + 4], eax
	mov eax, [esi + 018h]
	mov dword ptr [edi + ebx + 8], eax
	mov eax, [esi + 01Ch]
	mov dword ptr [edi + ebx + 12], eax

	; Copy third line
	sub edi, dwWidth	; Substract one scanline
	mov eax, [esi + 020h]
	mov dword ptr [edi + ebx], eax
	mov eax, [esi + 024h]
	mov dword ptr [edi + ebx + 4], eax
	mov eax, [esi + 028h]
	mov dword ptr [edi + ebx + 8], eax
	mov eax, [esi + 02Ch]
	mov dword ptr [edi + ebx + 12], eax

	; Copy fourth line
	sub edi, dwWidth	; Substract one scanline
	mov eax, [esi + 030h]
	mov dword ptr [edi + ebx], eax
	mov eax, [esi + 034h]
	mov dword ptr [edi + ebx + 4], eax
	mov eax, [esi + 038h]
	mov dword ptr [edi + ebx + 8], eax
	mov eax, [esi + 03Ch]
	mov dword ptr [edi + ebx + 12], eax

	add ebx, 16			; Increment used width (4 pixels * 32 bits each)
	cmp ebx, dwWidth	; Check whether there are more columns to process
	jne col				; Process more columns

	shl ebx, 2			; EBX contains scanline size, multiply by 4 to get block scanline
	sub dwHeight, ebx	; Substract block scanline from height
	cmp dwHeight, 0		; Check whether there are more rows to process
	jne row				; Process more rows

	pop ebx				; Restore registers
	pop esi
	pop edi
	add esp, 64			; Deallocate pixel block
	ret
DXTDImageBackscanDxt1PURE ENDP
OPTION PROLOGUE:PrologueDef
OPTION EPILOGUE:EpilogueDef


IEPVR_ALIGN
;------------------------------------------------------------------------------
; Decompresses entire DXT1 image into a backscan bitmap (ie HBITMAP). Uses SSE instructions
; Width and height must be a multiple of 4. To align dim, use this formula: ((dim + 3) / 4) * 4
; Pixels must be DWORDs
;------------------------------------------------------------------------------
OPTION PROLOGUE:NONE
OPTION EPILOGUE:NONE
DXTDImageBackscanDxt1SSE PROC dwWidth:DWORD, dwHeight:DWORD, pbBlock:DWORD, pdwPixels:DWORD
	sub esp, 64			; Allocate pixel block
	push edi			; Save registers
	push esi
	push ebx

	lea esi, [ebp - 64]	; Setup ESI to point to the intermediate pixel buffer

	shl dwWidth, 2		; Multiply width by 4 to get scanline size
	mov eax, dwHeight	; Multiply height by scanline size to get the bitmap size
	mul dwWidth
	mov dwHeight, eax
row:
	xor ebx, ebx		; Reset column counter
col:
	push esi			; Address of the pixel block
	push pbBlock		; Address of the source block
	call DXTDBlockDxt1
	add esp, 8
	add pbBlock, 8		; Increment block pointer by 8 (DXT1 block size)

	mov edi, pdwPixels	; Get pointer to the beginning of the the current block
	add edi, dwHeight

	; Copy first line
	sub edi, dwWidth	; Substract one scanline
	movups xmm0, [esi]
	movups [edi + ebx], xmm0

	; Copy second line
	sub edi, dwWidth	; Substract one scanline
	movups xmm0, [esi + 010h]
	movups [edi + ebx], xmm0

	; Copy third line
	sub edi, dwWidth	; Substract one scanline
	movups xmm0, [esi + 020h]
	movups [edi + ebx], xmm0

	; Copy fourth line
	sub edi, dwWidth	; Substract one scanline
	movups xmm0, [esi + 030h]
	movups [edi + ebx], xmm0

	add ebx, 16			; Increment used width (4 pixels * 32 bits each)
	cmp ebx, dwWidth	; Check whether there are more columns to process
	jne col				; Process more columns

	shl ebx, 2			; EBX contains scanline size, multiply by 4 to get block scanline
	sub dwHeight, ebx	; Substract block scanline from height
	cmp dwHeight, 0		; Check whether there are more rows to process
	jne row				; Process more rows

	pop ebx				; Restore registers
	pop esi
	pop edi
	add esp, 64			; Deallocate pixel block
	ret
DXTDImageBackscanDxt1SSE ENDP
OPTION PROLOGUE:PrologueDef
OPTION EPILOGUE:EpilogueDef

IEPVR_LIBEND

