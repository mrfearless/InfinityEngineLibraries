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
include gdi32.inc

includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib

;DEBUG32 EQU 1
;IFDEF DEBUG32
;    PRESERVEXMMREGS equ 1
;    includelib M:\Masm32\lib\Debug32.lib
;    DBG32LIB equ 1
;    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
;    include M:\Masm32\include\debug32.inc
;ENDIF

include IEBAM.inc

RGBCOLOR macro r:REQ,g:REQ,b:REQ    
exitm <( ( ( ( r )  or  ( ( ( g ) )  shl  8 ) )  or  ( ( ( b ) )  shl  16 ) ) ) >
ENDM

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Returns in eax HBITMAP of bam frame specified or bam frames if nFrame = -1
; HBITMAP returned in not freed when library closes, use DeleteObject when it
; is no longer required.
; Bitmap is formatted to max width and height of all frames 
;------------------------------------------------------------------------------
IEBAMBitmap PROC USES EBX hIEBAM:DWORD, nFrame:DWORD, dwBackColor:DWORD, dwGridColor:DWORD
    LOCAL hdc:DWORD
    LOCAL hdcMem:DWORD
    LOCAL hdcFrame:DWORD
    LOCAL SavedDCFrame:DWORD
    LOCAL hBitmap:DWORD
    LOCAL hOldBitmap:DWORD
    LOCAL hFrameBitmap:DWORD
    LOCAL hFrameBitmapOld:DWORD
    LOCAL hBrush:DWORD
    LOCAL hBrushOld:DWORD
    LOCAL dwImageWidth:DWORD
    LOCAL dwImageHeight:DWORD
    LOCAL FrameX:DWORD
    LOCAL FrameY:DWORD
    LOCAL FrameW:DWORD
    LOCAL FrameH:DWORD
    LOCAL TotalFrames:DWORD
    LOCAL nFrameCnt:DWORD
    LOCAL RowXadjust:DWORD
    LOCAL ColYadjust:DWORD
    LOCAL nRow:DWORD
    LOCAL nCol:DWORD
    LOCAL RowX:DWORD
    LOCAL ColY:DWORD
    LOCAL xpos:DWORD
    LOCAL ypos:DWORD
    LOCAL rect:RECT
    
    .IF hIEBAM == NULL
        mov eax, NULL
        ret
    .ENDIF  
    
    Invoke IEBAMTotalFrameEntries, hIEBAM
    .IF eax == 0
        ret
    .ENDIF
    mov TotalFrames, eax
    
    Invoke IEBAMFindMaxWidthHeight, hIEBAM, Addr dwImageWidth, Addr dwImageHeight
    .IF dwImageWidth == 0 && dwImageHeight == 0
        mov eax, NULL
        ret
    .ENDIF
    
    ;Invoke CreateDC, Addr szMOSDisplayDC, NULL, NULL, NULL
    Invoke GetDC, 0
    mov hdc, eax

    Invoke CreateCompatibleDC, hdc
    mov hdcMem, eax

    Invoke CreateCompatibleDC, hdc
    mov hdcFrame, eax
    
    .IF nFrame == -1
        mov eax, dwImageWidth
        mov RowXadjust, eax
        mov eax, dwImageHeight
        mov ColYadjust, eax
        ;.IF TotalFrames >= 16 ; create a 4x4 grid of bam frames
        
        ;.ELSE ; create a 4
            
        ;.ENDIF
        shl dwImageWidth, 2 ; x4
        shl dwImageHeight, 2 ; x4
    .ELSE    
        
    .ENDIF
    Invoke CreateCompatibleBitmap, hdc, dwImageWidth, dwImageHeight
    mov hBitmap, eax
    
    Invoke SelectObject, hdcMem, hBitmap
    mov hOldBitmap, eax
    
    ; fill background of grid image
    mov rect.left, 0
    mov rect.top, 0
    mov eax, dwImageWidth
    mov rect.right, eax
    mov eax, dwImageHeight
    mov rect.bottom, eax
    
    inc rect.right
    inc rect.bottom
    Invoke GetStockObject, DC_BRUSH
    mov hBrush, eax
    Invoke SelectObject, hdcMem, eax
    mov hBrushOld, eax
    .IF dwBackColor == -1
        Invoke IEBAMRLEColorIndexColorRef, hIEBAM
        Invoke SetDCBrushColor, hdcMem, eax ;RGBCOLOR(0,0,0)
    .ELSE
        Invoke SetDCBrushColor, hdcMem, dwBackColor;RGBCOLOR(0,0,0)
    .ENDIF
    Invoke FillRect, hdcMem, Addr rect, hBrush
    Invoke SelectObject, hdcMem, hBrushOld
    Invoke DeleteObject, hBrushOld
    Invoke DeleteObject, hBrush
    
    Invoke SaveDC, hdcFrame
    mov SavedDCFrame, eax
    
    .IF nFrame == -1

        mov nCol, 0
        mov nRow, 0
        mov RowX, 0
        mov ColY, 0
        
        mov eax, 0
        mov nFrameCnt, 0
        .WHILE eax < TotalFrames
            Invoke IEBAMFrameBitmap, hIEBAM, nFrameCnt, Addr FrameW, Addr FrameH, Addr FrameX, Addr FrameY, dwBackColor
            .IF eax != NULL
                mov hFrameBitmap, eax
                Invoke SelectObject, hdcFrame, hFrameBitmap
                mov hFrameBitmapOld, eax
                
                ; center in frame if less than max width and height
                mov eax, FrameW
                .IF sdword ptr eax < RowXadjust
                    mov eax, RowXadjust
                    shr eax, 1
                    mov ebx, FrameW
                    shr ebx, 1
                    sub eax, ebx
                    add eax, RowX
                .ELSE
                    mov eax, RowX
                .ENDIF
                mov xpos, eax
                
                mov eax, FrameH
                .IF sdword ptr eax < ColYadjust
                    mov eax, ColYadjust
                    shr eax, 1
                    mov ebx, FrameH
                    shr ebx, 1
                    sub eax, ebx
                    add eax, ColY
                .ELSE
                    mov eax, ColY
                .ENDIF
                mov ypos, eax
                
                ;mov eax, FrameX
                ;add eax, RowX
                ;mov xpos, eax
                
                ;mov eax, FrameY
                ;add eax, ColY
                ;mov ypos, eax
                
                IFDEF DEBUG32
                PrintText '---------'
                PrintDec nFrameCnt
                PrintDec FrameX
                PrintDec FrameY
                PrintDec FrameW
                PrintDec FrameH
                PrintDec RowX
                PrintDec ColY
                PrintDec xpos
                PrintDec ypos
                PrintText '---------'
                ENDIF
                
                
                Invoke BitBlt, hdcMem, xpos, ypos, FrameW, FrameH, hdcFrame, 0, 0, SRCCOPY
                Invoke SelectObject, hdcFrame, hFrameBitmapOld
                Invoke DeleteObject, hFrameBitmapOld
                
                .IF dwGridColor != -1
                    mov eax, RowX
                    ;inc eax
                    mov rect.left, eax
                    mov eax, ColY
                    ;inc eax
                    mov rect.top, eax
    
                    mov eax, RowXadjust
                    add eax, RowX
                    ;sub eax, 2
                    mov rect.right, eax
                    mov eax, ColYadjust
                    add eax, ColY
                    ;sub eax, 2
                    mov rect.bottom, eax
    
                    Invoke GetStockObject, DC_BRUSH
                    mov hBrush, eax
                    Invoke SelectObject, hdcMem, eax
                    mov hBrushOld, eax
                    Invoke SetDCBrushColor, hdcMem, dwGridColor ;RGBCOLOR(255,255,255)
                    Invoke FrameRect, hdcMem, Addr rect, hBrush
                    Invoke SelectObject, hdcMem, hBrushOld
                    Invoke DeleteObject, hBrushOld
                    Invoke DeleteObject, hBrush
                .ENDIF
                
            .ENDIF
            
            inc nRow
            .IF nRow == 4
                mov nRow, 0
                mov RowX, 0
                inc nCol
                .IF nCol == 4 ; end of 4 x 4 grid
                    .BREAK
                .ENDIF
                mov eax, ColYadjust
                add ColY, eax
            .ELSE
                mov eax, RowXadjust
                add RowX, eax
            .ENDIF

            inc nFrameCnt
            mov eax, nFrameCnt
        .ENDW
        
    .ELSE
        
        Invoke IEBAMFrameBitmap, hIEBAM, nFrame, Addr FrameW, Addr FrameH, Addr FrameX, Addr FrameY, dwBackColor
        .IF eax != NULL
            mov hFrameBitmap, eax
            Invoke SelectObject, hdcFrame, hFrameBitmap
            mov hFrameBitmapOld, eax
            Invoke BitBlt, hdcMem, FrameX, FrameY, FrameW, FrameH, hdcFrame, 0, 0, SRCCOPY
            Invoke SelectObject, hdcFrame, hFrameBitmapOld
            Invoke DeleteObject, hFrameBitmapOld
        .ENDIF
        
    .ENDIF
    
    .IF hOldBitmap != 0
        Invoke SelectObject, hdcMem, hOldBitmap
        Invoke DeleteObject, hOldBitmap
    .ENDIF
    Invoke RestoreDC, hdcFrame, SavedDCFrame
    Invoke DeleteDC, hdcFrame
    Invoke DeleteDC, hdcMem
    ;Invoke DeleteDC, hdc
    Invoke ReleaseDC, 0, hdc
    
    mov eax, hBitmap
    ret
IEBAMBitmap ENDP


IEBAM_LIBEND

