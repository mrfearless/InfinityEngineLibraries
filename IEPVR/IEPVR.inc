;==============================================================================
;
; IEPVR
;
; Copyright (c) 2019 by fearless
;
; All Rights Reserved
;
; http://github.com/mrfearless
;
;
; This software is provided 'as-is', without any express or implied warranty. 
; In no event will the author be held liable for any damages arising from the 
; use of this software.
;
; Permission is granted to anyone to use this software for any non-commercial 
; program. If you use the library in an application, an acknowledgement in the
; application or documentation is appreciated but not required. 
;
; You are allowed to make modifications to the source code, but you must leave
; the original copyright notices intact and not misrepresent the origin of the
; software. It is not allowed to claim you wrote the original software. 
; Modified files must have a clear notice that the files are modified, and not
; in the original state. This includes the name of the person(s) who modified 
; the code. 
;
; If you want to distribute or redistribute any portion of this package, you 
; will need to include the full package in it's original state, including this
; license and all the copyrights.  
;
; While distributing this package (in it's original state) is allowed, it is 
; not allowed to charge anything for this. You may not sell or include the 
; package in any commercial package without having permission of the author. 
; Neither is it allowed to redistribute any of the package's components with 
; commercial applications.
;
;==============================================================================

;------------------------------------------------------------------------------
; IEPVR Prototypes
;------------------------------------------------------------------------------
IEPVROpen                   PROTO lpszPvrFilename:DWORD, dwOpenMode:DWORD ; eax = handle used in other functions: hIEPVR
IEPVRMem                    PROTO pPVRInMemory:DWORD, lpszPvrFilename:DWORD, dwPvrFilesize:DWORD, dwOpenMode:DWORD ; Returns in eax a handle used in other functions: hIEPVR
IEPVRClose                  PROTO hIEPVR:DWORD

; Pointers to parts of PVR file:
IEPVRHeader                 PROTO hIEPVR:DWORD ; eax = pointer to a PVR3_HEADER structure.

;------------------------------------------------------------------------------
; IEPVR Structures
;------------------------------------------------------------------------------
IFNDEF PVR3_HEADER
PVR3_HEADER         STRUCT
    Version         DD 0 ; 0x0004   4 (bytes)       Version ('PVR',0x3) 50,56,52,03 = 0x03525650
    Flags           DD 0 ; 0x0008   4 (dword)       Flags
    PixelFormat     DQ 0 ; 0x000C   8 (QWORD)       Pixel format
    ColorSpace      DD 0 ; 0x0014   4 (dword)       Color space
    ChannelType     DD 0 ; 0x0018   4 (dword)       Channel type - data type of the colour channels within the texture data
    ImageHeight     DD 0 ; 0x001C   4 (dword)       Height of the texture stored in the texture data
    ImageWidth      DD 0 ; 0x0020   4 (dword)       Width of the texture stored in the texture data
    ImageDepth      DD 0 ; 0x0024   4 (dword)       Depth of the texture stored in the texture data
    NoSurfaces      DD 0 ; 0x0028   4 (dword)       Number of surfaces within the texture array
    NoFaces         DD 0 ; 0x002C   4 (dword)       Nnumber of faces in a cube map
    MIPMapCount     DD 0 ; 0x0030   4 (dword)       Number of MIP-Map levels present including the top level
    MetaDataSize    DD 0 ; 0x0034   4 (dword)       Total size (in bytes) of all the metadata following the header
PVR3_HEADER         ENDS
ENDIF

IFNDEF PVR3_METADATA
PVR3_METADATA       STRUCT
    FourCC          DD 0 ; 0x0004   4 (bytes)       Four byte array: 'PVR',0x3
    Key             DD 0 ; 0x0008   4 (dword)       
    DataSize        DD 0 ; 0x000C   4 (dword)       
    Data            DB 0 ; 0x0010   * (byte)        Variable sized based on DataSize
PVR3_METADATA       ENDS
ENDIF

IFNDEF PVRZ_HEADER
PVRZ_HEADER             STRUCT
    UncompressedSize    DD 0
    UncompressedData    DD 0
PVRZ_HEADER             ENDS
ENDIF

IFNDEF PVRINFO
PVRINFO                     STRUCT
    PVROpenMode             DD 0
    PVRFilename             DB MAX_PATH DUP (0)
    PVRFilesize             DD 0
    PVRVersion              DD 0
    PVRCompressed           DD 0
    PVRHeaderPtr            DD 0
    PVRHeaderSize           DD 0
    PVRMetaDataPtr          DD 0
    PVRMetaDataSize         DD 0
    PVRTextureDataPtr       DD 0
    PVRTextureDataSize      DD 0
    PVRMemMapPtr            DD 0
    PVRMemMapHandle         DD 0
    PVRFileHandle           DD 0    
PVRINFO                     ENDS
ENDIF

.CONST

;------------------------------------------
; Conditional for IEPVR Library DLL compiling
;------------------------------------------
IFDEF IEPVR_DLL
    IEPVR_LIBEND TEXTEQU <>
ELSE
    IEPVR_LIBEND TEXTEQU <END>
ENDIF
IEPVR_ALIGN                 TEXTEQU <ALIGN 16>
; IEPVROpen open mode:
IEPVR_MODE_WRITE            EQU 0
IEPVR_MODE_READONLY         EQU 1
; PVR Versions:
PVR_VERSION_INVALID         EQU 0 ; Not a PVR or invalid
PVR_VERSION_PVR3            EQU 1 ; PVR3
PVR_VERSION_PVRZ            EQU 3 ; PVRZ (Compressed PVR)

; PVR Version:
PVR_SIG                     EQU 03525650h
PVR_SIG_                    EQU 50565203h

; PVR Flags:
PVR_FLAG_NOFLAG             EQU 0 ; No flag has been set
PVR_FLAG_PREMULTIPLIED      EQU 2 ; When this flag is set, colour values within the texture have been pre-multiplied by the alpha values

; PVR Pixel Format:
PVRTC_2BPP_RGB              EQU 0
PVRTC_2BPP_RGBA             EQU 1
PVRTC_4BPP_RGB              EQU 2
PVRTC_4BPP_RGBA             EQU 3
PVRTC2_2BPP                 EQU 4
PVRTC2_4BPP                 EQU 5
ETC1                        EQU 6
DXT1                        EQU 7
DXT2                        EQU 8
DXT3                        EQU 9
DXT4                        EQU 10
DXT5                        EQU 11
BC1                         EQU 7
BC2                         EQU 9
BC3                         EQU 11
BC4                         EQU 12
BC5                         EQU 13
BC6                         EQU 14
BC7                         EQU 15
UYVY                        EQU 16
YUY2                        EQU 17
BW1BPP                      EQU 18
R9G9B9E5                    EQU 19
RGBG8888                    EQU 20
GRGB8888                    EQU 21
ETC2_RGB                    EQU 22
ETC2_RGBA                   EQU 23
ETC2_RGB_A1                 EQU 24
EAC_R11                     EQU 25
EAC_RG11                    EQU 26
ASTC_4X4                    EQU 27
ASTC_5X4                    EQU 28
ASTC_5X5                    EQU 29
ASTC_6X5                    EQU 30
ASTC_6X6                    EQU 31
ASTC_8X5                    EQU 32
ASTC_8X6                    EQU 33
ASTC_8X8                    EQU 34
ASTC_10X5                   EQU 35
ASTC_10X6                   EQU 36
ASTC_10X8                   EQU 37
ASTC_10X10                  EQU 38
ASTC_12X10                  EQU 39
ASTC_12X12                  EQU 40
ASTC_3X3X3                  EQU 41
ASTC_4X3X3                  EQU 42
ASTC_4X4X3                  EQU 43
ASTC_4X4X4                  EQU 44
ASTC_5X4X4                  EQU 45
ASTC_5X5X4                  EQU 46
ASTC_5X5X5                  EQU 47
ASTC_6X5X5                  EQU 48
ASTC_6X6X5                  EQU 49
ASTC_6X6X6                  EQU 50

; Color Space:
PVR_COLORSPACE_RGB          EQU 0 ; Texture data is in the Linear RGB colour space
PVR_COLORSPACE_SRGB         EQU 1 ; Texture data is in the Standard RGB colour space

; Channel Type:
PVR_CHANNELTYPE_UBYTE_NORM  EQU 0 ; Unsigned Byte Normalised
PVR_CHANNELTYPE_SBYTE_NORM  EQU 1 ; Signed Byte Normalised
PVR_CHANNELTYPE_UBYTE       EQU 2 ; Unsigned Byte
PVR_CHANNELTYPE_SBYTE       EQU 3 ; Signed Byte 
PVR_CHANNELTYPE_USHORT_NORM EQU 4 ; Unsigned Short Normalised
PVR_CHANNELTYPE_SSHORT_NORM EQU 5 ; Signed Short Normalised
PVR_CHANNELTYPE_USHORT      EQU 6 ; Unsigned Short
PVR_CHANNELTYPE_SSHORT      EQU 7 ; Signed Short 
PVR_CHANNELTYPE_UINT_NORM   EQU 8 ; Unsigned Integer Normalised
PVR_CHANNELTYPE_SINT_NORM   EQU 9 ; Signed Integer Normalised
PVR_CHANNELTYPE_UINT        EQU 10; Unsigned Integer
PVR_CHANNELTYPE_SINT        EQU 11; Signed Integer
PVR_CHANNELTYPE_FLOAT       EQU 12; Float

; PVR Metadata key:
PVR3_KEY0                   EQU 0
PVR3_KEY1                   EQU 1
PVR3_KEY2                   EQU 2
PVR3_KEY3                   EQU 3
PVR3_KEY4                   EQU 4
PVR3_KEY5                   EQU 5

; PVR Metadata key data sizes:
PVR3_KEY0_DATASIZE          EQU 0 ; variable
PVR3_KEY1_DATASIZE          EQU 8
PVR3_KEY2_DATASIZE          EQU 6
PVR3_KEY3_DATASIZE          EQU 3
PVR3_KEY4_DATASIZE          EQU 12
PVR3_KEY5_DATASIZE          EQU 0 ; variable



