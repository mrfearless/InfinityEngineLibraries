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
.model flat,C
option casemap:none

include windows.inc
include IEPVR.inc

DXTDBlockDxt3             PROTO C block:DWORD, pixels:DWORD ; Decmopresses single DXT3 block
DXTDImageBackscanDxt3     PROTO STDCALL ImageWidth:DWORD, ImageHeight:DWORD, inputImage:DWORD, outputPixels:DWORD ; Decompresses entire DXT3 image into a backscan bitmap (ie HBITMAP)
DXTDImageBackscanDxt3PURE PROTO ImageWidth:DWORD, ImageHeight:DWORD, inputImage:DWORD, outputPixels:DWORD ; Decompresses entire DXT3 image into a backscan bitmap (ie HBITMAP)
DXTDImageBackscanDxt3SSE  PROTO ImageWidth:DWORD, ImageHeight:DWORD, inputImage:DWORD, outputPixels:DWORD ; Decompresses entire DXT3 image into a backscan bitmap (ie HBITMAP)

EXTERNDEF DXTSSE          :PROTO

.DATA
; External definition of aRGB565Lookup lookup table
EXTERNDEF aRGB565Lookup:DWORD
; External definition of aAlphaLookup lookup table
EXTERNDEF aAlphaDxt3Lookup:DWORD


.CODE


IEPVR_ALIGN
;------------------------------------------------------------------------------
; Decompresses entire DXT3 image
;------------------------------------------------------------------------------
DXTDImageBackscanDxt3 PROC STDCALL dwWidth:DWORD, dwHeight:DWORD, pbBlock:DWORD, pdwPixels:DWORD
    Invoke DXTSSE
    .IF eax == TRUE
        Invoke DXTDImageBackscanDxt3SSE, dwWidth, dwHeight, pbBlock, pdwPixels
    .ELSE
        Invoke DXTDImageBackscanDxt3PURE, dwWidth, dwHeight, pbBlock, pdwPixels
    .ENDIF
    ret
DXTDImageBackscanDxt3 ENDP


IEPVR_ALIGN
;------------------------------------------------------------------------------
; Decompresses DXT3 block
;------------------------------------------------------------------------------
DXTDBlockDxt3 PROC C pbBlock:DWORD, pdwPixels:DWORD
	; Allocate space for color table
	sub esp, 16
	; Save registers
	push esi
	push edi
	push ebx

	; Unpack first two colors
	mov esi, pbBlock			; Move to the first color
	mov edi, pdwPixels			; Setup destination where we generate pixels
	movzx eax, word ptr [esi + 8]	; Get first color word
	mov eax, dword ptr [offset aRGB565Lookup + eax * 4]
	and eax, 0FFFFFFh
	mov [ebp - 4], eax			; Save RGB24 to color table
	movzx eax, word ptr [esi + 10]	; Get second color word
	mov eax, dword ptr [offset aRGB565Lookup + eax * 4]
	and eax, 0FFFFFFh
	mov [ebp - 8], eax			; Save RGB24 to color table

	; Calculate midpoint colors
	; Calculate third color
	mov dword ptr [ebp - 12], 0
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
	mov dword ptr [ebp - 16], 0
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

	; Set EBP to point to the last color. Color table is at lower addresses than EBP.
	; Since memory reference operator can only add offsets, we invert
	; indicies and set EBP to point to the last color thus adding inverted index to the ebp
	; will become the same as substracting non inverted index from the ebp.
	sub ebp, 16

	; Get indices
	mov eax, dword ptr [esi + 12]
	not eax	; Invert indices since we can only add offsets in mov operator []

	; Get first 8 alpha values
	mov ebx, [esi]
	; Setup location where the cycle ends
	lea ecx, [edi + 32]
lp:
	mov edx, eax
	and edx, 03h
	mov edx, [ebp + edx * 4]
	mov [edi], edx				; Set color
	mov edx, ebx
	and edx, 0Fh				; Get alpha index
	mov edx, [offset aAlphaDxt3Lookup + edx * 4]
	or [edi], edx				; Set alpha
	shr eax, 2
	shr ebx, 4

	add edi, 4
	cmp edi, ecx
	jne lp

	; Get next 8 alpha values
	mov ebx, [esi + 4]
	; Setup location where the cycle ends
	lea ecx, [edi + 32]
lp1:
	mov edx, eax
	and edx, 03h
	mov edx, [ebp + edx * 4]
	mov [edi], edx				; Set color
	mov edx, ebx
	and edx, 0Fh				; Get alpha index
	mov edx, [offset aAlphaDxt3Lookup + edx * 4]
	or [edi], edx				; Set alpha
	shr eax, 2
	shr ebx, 4

	add edi, 4
	cmp edi, ecx
	jne lp1

	; Restore original EBP position
	add ebp, 16
	; Restore registers
	pop ebx
	pop edi
	pop esi
	; Deallocate color table
	mov esp, ebp

	ret
DXTDBlockDxt3 ENDP


IEPVR_ALIGN
;------------------------------------------------------------------------------
; Decompresses entire DXT3 image into a backscan bitmap (ie HBITMAP)
; Width and height must be a multiple of 4. To align dim, use this formula: ((dim + 3) / 4) * 4
; Pixels must be DWORDs
;------------------------------------------------------------------------------
DXTDImageBackscanDxt3PURE PROC dwWidth:DWORD, dwHeight:DWORD, pbBlock:DWORD, pdwPixels:DWORD
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
	call DXTDBlockDxt3
	add esp, 8
	add pbBlock, 16		; Increment block pointer by 16 (DXT3/5 block size)

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
DXTDImageBackscanDxt3PURE ENDP


IEPVR_ALIGN
;------------------------------------------------------------------------------
; Decompresses entire DXT3 image into a backscan bitmap (ie HBITMAP). Uses SSE instructions
; Width and height must be a multiple of 4. To align dim, use this formula: ((dim + 3) / 4) * 4
; Pixels must be DWORDs
;------------------------------------------------------------------------------
DXTDImageBackscanDxt3SSE PROC dwWidth:DWORD, dwHeight:DWORD, pbBlock:DWORD, pdwPixels:DWORD
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
	call DXTDBlockDxt3
	add esp, 8
	add pbBlock, 16		; Increment block pointer by 16 (DXT3/5 block size)

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
DXTDImageBackscanDxt3SSE ENDP


IEPVR_LIBEND

