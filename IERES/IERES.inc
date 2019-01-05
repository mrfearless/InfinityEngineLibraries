;==============================================================================
;
; IERES
;
; Copyright (c) 2018 by fearless
;
; All Rights Reserved
;
; http://www.LetTheLight.in
;
; http://github.com/mrfearless/InfinityEngineLibraries
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

;-----------------------------------------------------------------------------------------
; IERES Prototypes
;-----------------------------------------------------------------------------------------
IERESResNameTypeToString    PROTO :DWORD, :DWORD, :DWORD    ; lpszResName, dwResType, lpdwResourceNameString. Resource name with extension returned it to buffer at lpszResourceNameString.
IERESResTypeToString        PROTO :DWORD                    ; dwResourceType. Returns in eax pointer to zero terminated string contained file extension for resource type specified,
IERESResSizeToString        PROTO :DWORD, :DWORD, :DWORD    ; dwResourceSize, dwTilesCount (optional maybe be NULL for file entries), lpszResourceSize. if dwTilesCount > 0 then size is calc'd as size x count and string is returned with 'size (tile size x tile count)'
IERESResIndexToString       PROTO :DWORD, :DWORD            ; dwResourceIndex, lpszResourceIndex. string returned to buffer pointed at by lpszResourceIndex
IERESResOffsetToString      PROTO :DWORD, :DWORD            ; dwResourceOffset, lpszResourceOffset. string returned to buffer pointed at by lpszResourceOffset
IERESResFlagsToString       PROTO :DWORD, :DWORD            ; dwResourceFlags, lpszResourceFlags. string returned to buffer pointed at by lpszResourceFlags (For BIF V1.1 FILE_ENTRY_V11)
IERESExtToResType           PROTO :DWORD


;-----------------------------------------------------------------------------------------
; IERES Structures
;-----------------------------------------------------------------------------------------


.CONST
;-----------------------------------------------------------------------------------------
; IERES Constants
;-----------------------------------------------------------------------------------------

; Bioware Resource Types:


;    0-10: Common files
;    1000-2000: (0x03E8 - 0x07D0) Infinity Engine resource types
;    2000-3000: (0x07D0 - 0x0BB8) NWN resource types
;    3000-4000: (0x0BB8 - 0x0FA0) SW:KOTOR resource types
;    9997-9999: Common resource types 
;    A000-AFFF: Reserved for internally resolving of shared resource types and designating a temporary resource id to one of the conflicting resources
;---------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------
; Shared Resource Types: Check actual files header to determine real resource type
; assign a temporary id for processing (getting correct file extension for example)
;---------------------------------------------------------------------------------------
; RES_TYPE_CHR & RES_TYPE_EFF   03F8h   1016    chr/eff
; RES_TYPE_BTI & RES_TYPE_ITM2  07E8h   2024    bti/itm
; RES_TYPE_BTC & RES_TYPE_CRE2  07EAh   2026    btc/cre
; RES_TYPE_ITP & RES_TYPE_PAL   07EEh   2030    itp/pal
; RES_TYPE_BTT & RES_TYPE_TRG   07EFh   2031    btt/trg
; RES_TYPE_BTS & RES_TYPE_SND   07F2h   2034    bts/snd
; RES_TYPE_BTE & RES_TYPE_ENC   07F7h   2039    bte/enc
; RES_TYPE_UTE & RES_TYPE_CON   07F8h   2040    ute/con
; RES_TYPE_BTD & RES_TYPE_DOR   07F9h   2041    btd/dor
; RES_TYPE_BTP & RES_TYPE_PLA   07FBh   2043    btp/pla
; RES_TYPE_BTM & RES_TYPE_MER   0802h   2050    btm/mer
; RES_TYPE_UTG & RES_TYPE_GEN   0807h   2055    utg/gen
; RES_TYPE_UTW & RES_TYPE_WAY   080Ah   2058    utw/way
; RES_TYPE_NCM & RES_TYPE_XSB   0813h   2067    ncm/xsb
; RES_TYPE_MFX & RES_TYPE_BIN   0814h   2068    mfx/bin
; RES_TYPE_TPC & RES_TYPE_CWD   0BBFh   3007    tpc/cwd
; RES_TYPE_MDX & RES_TYPE_PRO2  0BC0h   3008    mdx/pro
; RES_TYPE_RSV & RES_TYPE_AOE   0BC1h   3009    rsv/aoe
; RES_TYPE_SIG & RES_TYPE_MAT2  0BC2h   3010    mat/sig



;---------------------------------------------------------------------------------------


;---------------------------------------------------------------------------------------
RES_TYPE_ASKUSER        equ -1          ; '.???'
RES_TYPE_UNKNOWN        equ 0
RES_TYPE_CBF            equ 0           ; '.CBF'
RES_TYPE_ACM            equ 0           ; '.ACM'
RES_TYPE_MUS            equ 0           ; '.MUS'
;---------------------------------------------------------------------------------------
; 0 - 20 - Common files
;---------------------------------------------------------------------------------------
RES_TYPE_BMP            equ 0001h       ;  0001 bmp     Microsoft Windows Bitmap
RES_TYPE_MVE            equ 0002h       ;  0002 mve     Movie format
RES_TYPE_TGA            equ 0003h       ;  0003 tga     Targa Graphics Format
RES_TYPE_WAV            equ 0004h       ;  0004 wav     Standard RIFF Wav sound file
RES_TYPE_WAVC           equ 0004h       ;       wav     Compressed wav file 'WAVC'
RES_TYPE_WFX            equ 0005h       ;  0005 wfx     Sound effects
RES_TYPE_PLT            equ 0006h       ;  0006 plt     Bioware Packed Layer Texture
RES_TYPE_INI            equ 0007h       ;  0007 ini     Windows INI
RES_TYPE_MP3            equ 0008h       ;  0008 mp3     Audio file MP3
RES_TYPE_MPG            equ 0009h       ;  0009 mpg     MPEG movie file
RES_TYPE_TXT            equ 000Ah       ;  0010 txt     Standard Text file
RES_TYPE_XML            equ 000Bh       ;  0011 xml     XML formatted text file
RES_TYPE_WMA            equ 000Bh       ;  0012 wma     Windows Media audio
RES_TYPE_WMV            equ 000Ch       ;  0013 wmv     Windows Media video
RES_TYPE_XMV            equ 000Dh       ;  0014 xmv
; witcher
RES_TYPE_2DA3           equ 014Bh       ;  0331 2da     Witcher .2da file 

;---------------------------------------------------------------------------------------
; 1000 - 2000 :: (0x03E8 - 0x07D0) Infinity Engine resource types
;---------------------------------------------------------------------------------------
RES_TYPE_BAM            equ 03E8h       ;  1000 bam     Animation image format
RES_TYPE_BAMC           equ 03E8h       ;       bam     Compressed bam format 'BAMC'
RES_TYPE_WED            equ 03E9h       ;  1001 wed     Area information '.WED'
RES_TYPE_CHU            equ 03EAh       ;  1002 chu     Graphic used for GUI
RES_TYPE_TIS            equ 03EBh       ;  1003 tis     Tileset
RES_TYPE_MOS            equ 03ECh       ;  1004 mos     Tiled image format
RES_TYPE_MOSC           equ 03ECh       ;       mos     Compressed mos file 'MOSC'
RES_TYPE_ITM            equ 03EDh       ;  1005 itm     Item
RES_TYPE_SPL            equ 03EEh       ;  1006 spl     Spell
RES_TYPE_BCS            equ 03EFh       ;  1007 bcs     Script '.BCS'
RES_TYPE_IDS            equ 03F0h       ;  1008 ids     Action Identifiers '.IDS'
RES_TYPE_CRE            equ 03F1h       ;  1009 cre     Creature
RES_TYPE_ARE            equ 03F2h       ;  1010 are     Area
RES_TYPE_DLG            equ 03F3h       ;  1011 dlg     Dialog / banter
RES_TYPE_2DA            equ 03F4h       ;  1012 2da     2DA
RES_TYPE_GAM            equ 03F5h       ;  1013 gam     Game file
RES_TYPE_STO            equ 03F6h       ;  1014 sto     Merchant stores
RES_TYPE_WMP            equ 03F7h       ;  1015 wmp     Worldmap
RES_TYPE_CHR_OR_EFF     equ 03F8h       ;  1016 chr/eff Character
RES_TYPE_CHR            equ 03F8h       ;       chr     Character
RES_TYPE_EFF            equ 03F8h       ;       eff     ToTSC and IWD and BG2 Effects; a replacement for the 30-byte effect structure found in CRE and ITM files. 
RES_TYPE_EFF_           equ 0A3F8h      ;       eff     The EFF V2.0 format can be found either as a standalone file or embedded in CRE, ITM and SPL files.     

RES_TYPE_BS             equ 03F9h       ;  1017 bs      Compiled script '.BS'
RES_TYPE_CHR2           equ 03FAh       ;  1018 chr     '.CHR'
RES_TYPE_VVC            equ 03FBh       ;  1019 vvc     Effects '.VVC'
RES_TYPE_VEF            equ 03FCh       ;  1020 vef     Effects '.VEF'
RES_TYPE_PRO            equ 03FDh       ;  1021 pro     Projectiles
RES_TYPE_BIO            equ 03FEh       ;  1022 bio     Biography of Character. Text format
RES_TYPE_WBM            equ 03FFh       ;  1023 wbm     Beamdog EE: '.WBM'  
RES_TYPE_FON            equ 0400h       ;  1024 fon     Beamdog EE: '.FON'  Font
RES_TYPE_GUI            equ 0402h       ;  1026 gui     Beamdog EE: '.GUI'  Graphical User Interface definitions
RES_TYPE_SQL            equ 0403h       ;  1027 sql     Beamdog EE: '.SQL'  SQL database queries
RES_TYPE_PVR            equ 0404h       ;  1028 pvrz    Beamdog EE: '.PVRZ' PowerVR DXT1/5 compressed image tiles
RES_TYPE_GLSL           equ 0405h       ;  1029 glsl    Beamdog EE: '.GLSL' Graphic Shader Language Script
RES_TYPE_MENU           equ 0408h       ;  1032         Beamdog EE 2.0 Menu file: UI.menu
RES_TYPE_LUA2           equ 0409h       ;  1033         Beamdog EE 2.0 Lua
RES_TYPE_TTF2           equ 040Ah       ;  1034         Beamdog EE 2.0 ttf true type font files
RES_TYPE_PNG2           equ 040Bh       ;  1035         Beamdog EE 2.0 png
RES_TYPE_BAH            equ 044Ch       ;  1100 bah     .BAH'
RES_TYPE_BAF            equ 0           ;               .BAF'

;---------------------------------------------------------------------------------------
; 2000 - 3000 :: (0x07D0 - 0x0BB8) NWN resource types SWKotoR share these resource as well
;---------------------------------------------------------------------------------------
RES_TYPE_PLH            equ 07D0h       ;  2000 plh     Polyhedron
RES_TYPE_TEX            equ 07D1h       ;  2001 tex     Texture
RES_TYPE_MDL            equ 07D2h       ;  2002 mdl     Model - Text format of MDX - These are 3D item models created using 3D Studio MAX. These are 3D mesh models created using 3D Studio MAX. 
RES_TYPE_THG            equ 07D3h       ;  2003 thg     
RES_TYPE_FNT            equ 07D5h       ;  2005 fnt     Font
RES_TYPE_LUA            equ 07D7h       ;  2007 lua     Lua script source code ( http://www.lua.org/ )
RES_TYPE_SLT            equ 07D8h       ;  2008 slt     Slot file
RES_TYPE_NSS            equ 07D9h       ;  2009 nss     NWScript source code
RES_TYPE_NCS            equ 07DAh       ;  2010 ncs     NWScript bytecode
RES_TYPE_MOD            equ 07DBh       ;  2011 mod     Module (ERF)
RES_TYPE_ARE2           equ 07DCh       ;  2012 are     Area (GFF) Static Area Info
RES_TYPE_SET            equ 07DDh       ;  2013 set     Tileset (unused in KOTOR?). these files contain areas and information about the 3D models used for the given area, e.g. a type of grass
RES_TYPE_IFO            equ 07DEh       ;  2014 ifo     Module information
RES_TYPE_BIC            equ 07DFh       ;  2015 bic     Character sheet (unused)
RES_TYPE_WOK            equ 07E0h       ;  2016 wok     walk-mesh. these files contain model navigation and collisions. They are used exclusively by the areas
RES_TYPE_2DA2           equ 07E1h       ;  2017 2da     2-dimensional array
RES_TYPE_TLK            equ 07E2h       ;  2018 tlk     Talk table file TLK
RES_TYPE_TXI            equ 07E6h       ;  2022 txi     Extra Texture information. these are not graphics files, but they contain additional data (e.g. filters) used for the given graphics file. They have the same name as the given graphics file
RES_TYPE_GIT            equ 07E7h       ;  2023 git     Dynamic area information, game instance file, all area and objects that are scriptable

RES_TYPE_BTI_OR_ITM2    equ 07E8h       ;  2024 bti/itm [Shared ResourceType]
RES_TYPE_BTI            equ 07E8h       ;       bti     Item template (GFF)
RES_TYPE_ITM2           equ 07E8h       ;       itm     
RES_TYPE_ITM2_          equ 0A7E8h      ;       itm     

RES_TYPE_UTI            equ 07E9h       ;  2025 itm     item blueprint

RES_TYPE_BTC_OR_CRE2    equ 07EAh       ;  2026 btc/cre [Shared ResourceType]
RES_TYPE_BTC            equ 07EAh       ;       btc     BioWare Template for Creatures
RES_TYPE_CRE2           equ 07EAh       ;       cre     Creature template (GFF))
RES_TYPE_CRE2_          equ 0A7EAh      ;       cre     

RES_TYPE_UTC            equ 07EBh       ;  2027 utc     Creature blueprint User Template for Creatures. These are templates for characters
RES_TYPE_DLG2           equ 07EDh       ;  2029 dlg     Dialogue

RES_TYPE_ITP_OR_PAL     equ 07EEh       ;  2030 itp/pal [Shared ResourceType]
RES_TYPE_ITP            equ 07EEh       ;       itp     Tile blueprint pallet file
RES_TYPE_PAL            equ 07EEh       ;       pal     Palette (GFF)
RES_TYPE_PAL_           equ 0A7EEh      ;       pal     

RES_TYPE_BTT_OR_TRG     equ 07EFh       ;  2031 btt/trg [Shared ResourceType]
RES_TYPE_BTT            equ 07EFh       ;       btt     BioWare Template for Triggers
RES_TYPE_TRG            equ 07EFh       ;       trg     [Jade Empire = TRG]    Triggers (GFF)
RES_TYPE_TRG_           equ 0A7EFh      ;       trg     

RES_TYPE_UTT            equ 07F0h       ;  2032 utt     Trigger blueprint. These are templates for triggers
RES_TYPE_DDS            equ 07F1h       ;  2033 dds     Compressed texture file DXTC Compressed texture

RES_TYPE_BTS_OR_SND     equ 07F2h       ;  2034 bts/snd [Shared ResourceType]
RES_TYPE_BTS            equ 07F2h       ;       bts     BioWare Template for Sounds
RES_TYPE_SND            equ 07F2h       ;       snd     Sounds (???)
RES_TYPE_SND_           equ 0A7F2h      ;       snd     

RES_TYPE_UTS            equ 07F3h       ;  2035 uts     Sound blueprint. These are templates for sounds
RES_TYPE_LTR            equ 07F4h       ;  2036 ltr     Letter combo probability info
RES_TYPE_GFF            equ 07F5h       ;  2037 gff     Generic File Format
RES_TYPE_FAC            equ 07F6h       ;  2038 fac     Faction file

RES_TYPE_BTE_OR_ENC     equ 07F7h       ;  2039 bte/enc [Shared ResourceType]
RES_TYPE_BTE            equ 07F7h       ;       bte     BioWare Template for Encounters
RES_TYPE_ENC            equ 07F7h       ;       enc     Encounter template (GFF)
RES_TYPE_ENC_           equ 0A7F7h      ;       enc     

; CON files always appear to be UTE
RES_TYPE_UTE_OR_CON     equ 07F8h       ;  2040 ute/con [Shared ResourceType]
RES_TYPE_UTE            equ 07F8h       ;       ute     Encounter blueprint
RES_TYPE_CON            equ 07F8h       ;       con     Container template (GFF)
RES_TYPE_CON_           equ 0A7F8h      ;       con     

RES_TYPE_BTD_OR_DOR     equ 07F9h       ;  2041 btd/dor [Shared ResourceType]
RES_TYPE_BTD            equ 07F9h       ;       btd     BioWare Template for Doors
RES_TYPE_DOR            equ 07F9h       ;       dor     Door template (GFF)
RES_TYPE_DOR_           equ 0A7F9h      ;       dor     

RES_TYPE_UTD            equ 07FAh       ;  2042 utd     Door blueprint User Template for Doors. These are templates for doors used to move between areas, from the street into a building, for example, 

RES_TYPE_BTP_OR_PLA     equ 07FBh       ;  2043 btp/pla [Shared ResourceType]
RES_TYPE_BTP            equ 07FBh       ;       btp     BioWare Template for Placeable Objects
RES_TYPE_PLA            equ 07FBh       ;       pla     [Jade Empire = PLA]     Placeable template (GFF)
RES_TYPE_PLA_           equ 0A7FBh      ;       pla     


RES_TYPE_UTP            equ 07FCh       ;  2044 utp     Placeable object blueprint User Template for Placeable Objects. These are templates for placeables
RES_TYPE_DFT            equ 07FDh       ;  2045 dft     Default values file (text-ini)
RES_TYPE_GIC            equ 07FEh       ;  2046 gic     Game instance comments
RES_TYPE_GUI2           equ 07FFh       ;  2047 gui     GUI definition (GFF)
RES_TYPE_BTW            equ 0010h       ;               Unknown - but based on UTW should be one perhaps? set to 0x10 for the moment 

;---------------------------------------------------------------------------------------
; 2048 - 2110 Witcher
;---------------------------------------------------------------------------------------
;RES_TYPE_INI2          equ 0802h       ;  2050 ini
RES_TYPE_SRC            equ 0803h       ;  2051 src

RES_TYPE_CSS            equ 0800h       ;  2048 css     Conditional Source Script
RES_TYPE_CCS            equ 0801h       ;  2049 ccs     Conditional Compiled Script 

; mer stores havnt found in any game, ini2 does share resource type with this
RES_TYPE_BTM_OR_INI2    equ 0802h       ;  2050 btm/ini [Shared ResourceType]
RES_TYPE_BTM            equ 0802h       ;       btm     BioWare Template for Market/Merchants (Stores) 
RES_TYPE_INI2           equ 0802h       ;       ini     ini file                    (mer     Merchants (Stores)) 
RES_TYPE_INI2_          equ 0A802h      ;       ini  

RES_TYPE_UTM            equ 0803h       ;  2051 utm     Store merchant blueprint User Template for Market/Merchants (Stores). These are templates for shops and warehouses
RES_TYPE_DWK            equ 0804h       ;  2052 dwk     Door walkmesh.  these files contain placeables and door collisions
RES_TYPE_PWK            equ 0805h       ;  2053 pwk     Placeable object walkmesh.  these files contain placeables and door collisions
RES_TYPE_BTG            equ 0806h       ;  2054 btg     BioWare Template for Random Item Generator 

RES_TYPE_UTG_OR_GEN     equ 0807h       ;  2055 utg/gen [Shared ResourceType]
RES_TYPE_UTG            equ 0807h       ;       utg     User Template for Encounters 
RES_TYPE_GEN            equ 0807h       ;       gen     Random Item Generator
RES_TYPE_GEN_           equ 0A807h      ;       gen 




RES_TYPE_JRL            equ 0808h       ;  2056 jrl     Journal file (GFF)
RES_TYPE_SAV2           equ 0809h       ;  2057 sav     Saved game (ERF)

RES_TYPE_UTW_OR_WAY     equ 080Ah       ;  2058 utw/way [Shared ResourceType]
RES_TYPE_UTW            equ 080Ah       ;       utw     Waypoint blueprint.
RES_TYPE_WAY            equ 080Ah       ;       way     These are templates for waypoints
RES_TYPE_WAY_           equ 0A80Ah      ;       way     

RES_TYPE_4PC            equ 080Bh       ;  2059 4pc     Custom 16-bit RGBA texture format
RES_TYPE_SSF            equ 080Ch       ;  2060 ssf     Sound set file
RES_TYPE_HAK            equ 080Dh       ;  2061 hak     Hak pak (unused)
RES_TYPE_NWM            equ 080Eh       ;  2062 nwm     NWN Official Campaign module (ERF)
RES_TYPE_BIK            equ 080Fh       ;  2063 bik     BINK movie (Bink video)
RES_TYPE_NDB            equ 0810h       ;  2064 ndb     Script debugger file
RES_TYPE_PTM            equ 0811h       ;  2065 ptm     Plot manager/plot instance
RES_TYPE_PTT            equ 0812h       ;  2066 ptt     Plot wizard blueprint

RES_TYPE_NCM_OR_XSB     equ 0813h       ;  2067 ncm/xsb [Shared ResourceType]
RES_TYPE_NCM            equ 0813h       ;       ncm     Neverwinter Console Macro
RES_TYPE_XSB            equ 0813h       ;       xsb     XACT SoundBank
RES_TYPE_XSB_           equ 0A813h      ;       xsb

RES_TYPE_MFX_OR_BIN     equ 0814h       ;  2068 mfx/bin [Shared ResourceType]
RES_TYPE_MFX            equ 0814h       ;       mfx     
RES_TYPE_BIN            equ 0814h       ;       bin     XBOX DSP filter
RES_TYPE_BIN_           equ 0A814h      ;       bin

RES_TYPE_MAT            equ 0815h       ;  2069 mat     These are files containing material definitions for the 3D models. 
RES_TYPE_MDB            equ 0816h       ;  2070 mdb     Not the standard MDB, multiple file formats present despite same type
RES_TYPE_SAY            equ 0817h       ;  2071 say     These are not sound files. They contain information about lip movements used by the characters during conversations. They have the same name as the given sound file
RES_TYPE_TTF            equ 0818h       ;  2072 ttf     Standard .ttf font files

;NWN:EE added resources:
;+    NwnResType_BAK              = 0x0813,
;+    NwnResType_DAT              = 0x0814,
;+    NwnResType_SHD              = 0x0815,
;+    NwnResType_XBC              = 0x0816,
;+    NwnResType_WBM              = 0x0817,
;+    NwnResType_MTR              = 0x0818,


RES_TYPE_TTC            equ 0819h       ;  2073 ttc
RES_TYPE_CUT            equ 081Ah       ;  2074 cut     Cutscene? (GFF)
RES_TYPE_KA             equ 081Bh       ;  2075 ka      Karma file (XML). these files contain information about game physics. They are used by the Karma System employed by The Witcher
RES_TYPE_JPG            equ 081Ch       ;  2076 jpg     Jpeg image
RES_TYPE_ICO            equ 081Dh       ;  2077 ico     Standard windows .ico files
RES_TYPE_OGG            equ 081Eh       ;  2078 ogg     Ogg vorbis sound file
RES_TYPE_SPT            equ 081Fh       ;  2079 spt     Namely SpeedTree Data file, is a Tree Data file format created by SpeedTreeCAD. SPT files belong to a kind of 3D image file, 
                                        ;               thus it could be opened by other 3D image program. SPT files are used for tree geometry construction, LOD data implementation, 
                                        ;               wind animation and cloning. open spt file on Windows: * IDV SpeedTreeCAD * Autodesk 3ds max with SpeedTreeMAX plugin 
                                        ;               * Autodesk Maya with SpeedTreeMAYA plugin 
RES_TYPE_SPW            equ 0820h       ;  2080 spw     Speed of wind ini text file
RES_TYPE_WFX2           equ 0821h       ;  2081 wfx     Woot effect class (XML) - These are files with special effects.
RES_TYPE_UGM            equ 0822h       ;  2082 ugm     [textures00.bif] Unity Game Material?
RES_TYPE_QDB            equ 0823h       ;  2083 qdb     Quest database (GFF v3.38) the .qst and .qdb format files. The .qst files are the quests, whereas the .qdb files are databases containing sets of quests. 
RES_TYPE_QST            equ 0824h       ;  2084 qst     Quest (GFF)
RES_TYPE_NPC            equ 0825h       ;  2085 npc     These are templates for NPCs
RES_TYPE_SPN            equ 0826h       ;  2086 spn     These are templates for spawn sets
RES_TYPE_UTX            equ 0827h       ;  2087 utx     Spawn point? (GFF) These are templates for spawn points
RES_TYPE_MMD            equ 0828h       ;  2088 mmd     Meta Module
RES_TYPE_SMM            equ 0829h       ;  2089 smm
RES_TYPE_UTA            equ 082Ah       ;  2090 uta     These are templates for action points (GFF)
RES_TYPE_MDE            equ 082Bh       ;  2091 mde     These files contain events, e.g. sounds for the animations
RES_TYPE_MDV            equ 082Ch       ;  2092 mdv     These files contain “virtual animations”. They have the same name as the given .mdl file. If there is no .mdv file for the .mdl file, it means that the given model has no “virtual animation”
RES_TYPE_MDA            equ 082Dh       ;  2093 mda     These files contain animations
RES_TYPE_MBA            equ 082Eh       ;  2094 mba
RES_TYPE_OCT            equ 082Fh       ;  2095 oct     File includes texture,index,vertex and maybe bones OCT = scene graph format
RES_TYPE_BFX            equ 0830h       ;  2096 bfx
RES_TYPE_PDB            equ 0831h       ;  2097 pdb
RES_TYPE_THEWITCHERSAVE equ 0832h       ;  2098 TheWitcherSave
RES_TYPE_PVS            equ 0833h       ;  2099 pvs     PolyView Slide Show Script (Polybytes Inc.)?
RES_TYPE_CFX            equ 0834h       ;  2100 cfx     Co-efficients for wfx effects? file contains string table of float values.
RES_TYPE_LUC            equ 0835h       ;  2101 luc     Compiled lua script
RES_TYPE_PRB            equ 0837h       ;  2103 prb     Probabilities file
RES_TYPE_CAM            equ 0838h       ;  2104 cam     These are templates for camera spheres
RES_TYPE_VDS            equ 0839h       ;  2105 vds
RES_TYPE_BIN2           equ 083Ah       ;  2106 bin
RES_TYPE_WOB            equ 083Bh       ;  2107 wob     World of Battles model and textures archive?
RES_TYPE_API            equ 083Ch       ;  2108 api
RES_TYPE_PROPERTIES     equ 083Dh       ;  2109 properties
RES_TYPE_PNG            equ 083Eh       ;  2110 png

;---------------------------------------------------------------------------------------
; 3000 - 4000 :: (0x0BB8 - 0x0FA0) SW:KOTOR resource types
;---------------------------------------------------------------------------------------
RES_TYPE_LYT            equ 0BB8h       ;  3000 lyt     Layout information
RES_TYPE_VIS            equ 0BB9h       ;  3001 vis     Area visibility graph (plaintext)
RES_TYPE_RIM            equ 0BBAh       ;  3002 rim     Resource In Memory file: used by engine at runtime for fast data retrieval in native memory format 
RES_TYPE_PTH            equ 0BBBh       ;  3003 pth     Path information? (GFF)
RES_TYPE_LIP            equ 0BBCh       ;  3004 lip     Lipsync Visemes data
RES_TYPE_BWM            equ 0BBDh       ;  3005 bwm     
RES_TYPE_TXB            equ 0BBEh       ;  3006 txb     TXB files contain compressed bitmaps which come in one resolution

RES_TYPE_TPC_OR_CWD     equ 0BBFh       ;  3007 tpc/cwd [Shared ResourceType]
RES_TYPE_TPC            equ 0BBFh       ;       tpc     Compressed image with TXI data
RES_TYPE_CWD            equ 0BBFh       ;       cwd     Crowd game object template (GFF)
RES_TYPE_CWD_           equ 0ABBFh      ;       cwd 

; after looking at files suspect pro2 is actually an mdx file and not a .pro file type.
RES_TYPE_MDX_OR_PRO2    equ 0BC0h       ;  3008 mdx/pro [Shared ResourceType]
RES_TYPE_MDX            equ 0BC0h       ;       pro     Projectile static resource type
RES_TYPE_PRO2           equ 0BC0h       ;       mdx     3d model files
RES_TYPE_PRO2_          equ 0ABC0h      ;       mdx 

RES_TYPE_RSV_OR_AOE     equ 0BC1h       ;  3009 rsv/aoe [Shared ResourceType]
RES_TYPE_RSV            equ 0BC1h       ;       rsv     
RES_TYPE_AOE            equ 0BC1h       ;       aoe     Area of Effect static resouce type
RES_TYPE_AOE_           equ 0ABC1h      ;       aoe     

RES_TYPE_SIG_OR_MAT2    equ 0BC2h       ;  3010 mat/sig [Shared ResourceType]
RES_TYPE_SIG            equ 0BC2h       ;       sig     
RES_TYPE_MAT2           equ 0BC2h       ;       mat     material file (plaintext)
RES_TYPE_MAT2_          equ 0ABC2h      ;       mat     

RES_TYPE_MAB            equ 0BC3h       ;  3011 mab     Jade empire - model format [xbx]
RES_TYPE_QST2           equ 0BC4h       ;  3012 qst     Quest/journal data (GFF)
RES_TYPE_STO2           equ 0BC5h       ;  3013 sto     Store static resource file (GFF) [used with MER file?]
RES_TYPE_APL            equ 0BC6h       ;  3014 apl     Artist placeabl
RES_TYPE_HEX            equ 0BC7h       ;  3015 hex     Hex grid (plaintext) [appears to be map-related in some way]
RES_TYPE_MDX2           equ 0BC8h       ;  3016 mdx     Model     
RES_TYPE_TXB2           equ 0BC9h       ;  3017 txb     Jade Empire Effects file Compressed image with TXI data ;RES_TYPE_FX
RES_TYPE_TPC2           equ 0BCAh       ;  3018 tpc     Compressed image with TXI data
;3019    CAM     ???
;3020    SPT     ???
;3021    STYLE   ???
RES_TYPE_FSM            equ 0BCEh       ;  3022 fsm     Finite State Machine file   
RES_TYPE_ART            equ 0BCFh       ;  3023 art     
RES_TYPE_AMP            equ 0BD0h       ;  3024 amp     ??? (binary)
RES_TYPE_CWA            equ 0BD1h       ;  3025 cwa     Crowd Attribute (GFF) jade empire 
RES_TYPE_XLS            equ 0BD2h       ;  3026 xls     MS Excel spreadsheet
RES_TYPE_SPF            equ 0BD3h       ;  3027 spf     NGF: Style profiles
RES_TYPE_BIP            equ 0BD4h       ;  3028 bip     Biped Motion Capture PATL: Binary LIP. - [lipsync/Sound file?]
RES_TYPE_MDB2           equ 0FA0h       ;  4000 mdb     
RES_TYPE_MDA2           equ 0FA1h       ;  4001 mda     Model animation?
RES_TYPE_SPT2           equ 0FA2h       ;  4002 spt     
RES_TYPE_GR2            equ 0FA3h       ;  4003 gr      
RES_TYPE_FXA            equ 0FA4h       ;  4004 fxa     
RES_TYPE_FXE            equ 0FA5h       ;  4005 fxe     
RES_TYPE_JPG2           equ 0FA7h       ;  4007 jpg     
RES_TYPE_PWC            equ 0FA8h       ;  4008 pwc     

;---------------------------------------------------------------------------------------
; 9997-9999: Common resource types 
;---------------------------------------------------------------------------------------
RES_TYPE_BIG            equ 270Bh       ;  9995 big     Big file archive
RES_TYPE_IDS2           equ 270Ch       ;  9996 IDS     Legacy BG Script File
RES_TYPE_ERF            equ 270Dh       ;  9997 erf     Encapsulated Resource Format / Neverwinter Nights Toolset Exported Resource
RES_TYPE_BIF            equ 270Eh       ;  9998 bif     Bioware File Archive
RES_TYPE_KEY            equ 270Fh       ;  9999 key     Index key for bif files

;---------------------------------------------------------------------------------------
; Found in NWN: Visual Foxpro database formats: dbf=database, cdx=index, fpt=memo
;---------------------------------------------------------------------------------------
RES_TYPE_VFPEXE         equ 4A38h       ;  19000 
RES_TYPE_VFPDBF         equ 4A39h       ;  19001 
RES_TYPE_VFPCDX         equ 4A3Ah       ;  19002 
RES_TYPE_VFPFPT         equ 4A3Bh       ;  19003 

;---------------------------------------------------------------------------------------
;Found in NWN2's ZIP files
;---------------------------------------------------------------------------------------
;  195     kFileTypeZIP            = 4E20 ; 20000, 
;  196     kFileTypeFXM            = 20001, 
;  197     kFileTypeFXS            = 20002, 
;  198     kFileTypeXML            = 20003, 
;  199     kFileTypeWLK            = 20004, 
;  200     kFileTypeUTR            = 20005, 
;  201     kFileTypeSEF            = 20006, 
;  202     kFileTypePFX            = 20007, 
;  203     kFileTypeTFX            = 20008, 
;  204     kFileTypeIFX            = 20009,
;  205     kFileTypeLFX            = 20010, 
;  206     kFileTypeBBX            = 20011, 
;  207     kFileTypePFB            = 20012, 
;  208     kFileTypeUPE            = 20013,
;  209     kFileTypeUSC            = 20014,
;  210     kFileTypeULT            = 20015, 
;  211     kFileTypeFX             = 20016,
;  212     kFileTypeMAX            = 20017,
;  213     kFileTypeDOC            = 20018,
;  214     kFileTypeSCC            = 20019,
;  215     kFileTypeWMP            = 20020, 
;  216     kFileTypeOSC            = 20021,
;  217     kFileTypeTRN            = 20022,
;  218     kFileTypeUEN            = 20023,
;  219     kFileTypeROS            = 20024,
;  220     kFileTypeRST            = 20025,
;  221     kFileTypePTX            = 20026,
;  222     kFileTypeLTX            = 20027,
;  223     kFileTypeTRX            = 20028,
;
;---------------------------------------------------------------------------------------
;  225     // Found in Sonic Chronicles: The Dark Brotherhood
;---------------------------------------------------------------------------------------

;  226     kFileTypeNDS            = 21000, 
;  227     kFileTypeHERF           = 21001, 
;  228     kFileTypeDICT           = 21002, 
;  229     kFileTypeSMALL          = 21023, 
;  230     kFileTypeCBGT           = 21004,
;  231     kFileTypeCDPTH          = 21005,
;  232     kFileTypeEMIT           = 21006,
;  233     kFileTypeITM2            = 21007, 
;  234     kFileTypeNANR           = 21008, 
;  235     kFileTypeNBFP           = 21009, 
;  236     kFileTypeNBFS           = 21010, 
;  237     kFileTypeNCER           = 21011, 
;  238     kFileTypeNCGR           = 21012, 
;  239     kFileTypeNCLR           = 21013, 
;  240     kFileTypeNFTR           = 21014, 
;  241     kFileTypeNSBCA          = 21015, 
;  242     kFileTypeNSBMD          = 21016, 
;  243     kFileTypeNSBTA          = 21017, 
;  244     kFileTypeNSBTP          = 21018, 
;  245     kFileTypeNSBTX          = 21019, 
;  246     kFileTypePAL            = 21020, 
;  247     kFileTypeRAW            = 21021, 
;  248     kFileTypeSADL           = 21022,
;  249     kFileTypeSDAT           = 21023, 
;  250     kFileTypeSMP            = 21024,
;  251     kFileTypeSPL2            = 21025, 
;  252     kFileTypeVX             = 21026, 

;---------------------------------------------------------------------------------------
;  254     // Found in Dragon Age: Origins
;---------------------------------------------------------------------------------------
;  255     kFileTypeANB            = 22000, 
;  256     kFileTypeANI            = 22001, 
;  257     kFileTypeCNS            = 22002,  Client scripting source
;  258     kFileTypeCUR            = 22003, 
;  259     kFileTypeEVT            = 22004, 
;  260     kFileTypeFDL            = 22005,
;  261     kFileTypeFXO            = 22006,
;  262     kFileTypeGAD            = 22007, 
;  263     kFileTypeGDA            = 22008, 
;  264     kFileTypeGFX            = 22009, 
;  265     kFileTypeLDF            = 22010, 
;  266     kFileTypeLST            = 22011, 
;  267     kFileTypeMAL            = 22012, 
;  268     kFileTypeMAO            = 22013, 
;  269     kFileTypeMMH            = 22014, 
;  270     kFileTypeMOP            = 22015,
;  271     kFileTypeMOR            = 22016, 
;  272     kFileTypeMSH            = 22017, 
;  273     kFileTypeMTX            = 22018,
;  274     kFileTypeNCC            = 22019, 
;  275     kFileTypePHY            = 22020, 
;  276     kFileTypePLO            = 22021, 
;  277     kFileTypeSTG            = 22022, 
;  278     kFileTypeTBI            = 22023,
;  279     kFileTypeTNT            = 22024, 
;  280     kFileTypeARL            = 22025, 
;  281     kFileTypeFEV            = 22026, 
;  282     kFileTypeFSB            = 22027, 
;  283     kFileTypeOPF            = 22028,
;  284     kFileTypeCRF            = 22029,
;  285     kFileTypeRIMP           = 22030,
;  286     kFileTypeMET            = 22031, 
;  287     kFileTypeMETA           = 22032, 
;  288     kFileTypeFXR            = 22033, 
;  289     kFileTypeFXT            = 22033, 
;  290     kFileTypeCIF            = 22034, ; Campaign Information File 
;  291     kFileTypeCUB            = 22035,
;  292     kFileTypeDLB            = 22036,

;---------------------------------------------------------------------------------------
;     // Found in KotOR Mac
;---------------------------------------------------------------------------------------
;  295     kFileTypeMOV            = 23000, 
;  296     kFileTypeCURS           = 23001, 
;  297     kFileTypePICT           = 23002, 
;  298     kFileTypeRSRC           = 23003, 
;  299     kFileTypePLIST          = 23004, 
;  300 
;---------------------------------------------------------------------------------------
;  301     // Found Jade Empire
;---------------------------------------------------------------------------------------
;  302     kFileTypeCRE3            = 24000, 
;  303     kFileTypePSO            = 24001, 
;  304     kFileTypeVSO            = 24002, 
;  305     kFileTypeABC            = 24003, 
;  306     kFileTypeSBM            = 24004, 
;  307     kFileTypePVD            = 24005,
;  308     kFileTypeAMP            = 24006,
;  309     kFileTypePLA            = 24007, 
;  310     kFileTypeTRG            = 24008, 
;  311     kFileTypePK             = 24009,
;  312 
;---------------------------------------------------------------------------------------
;  313     // Found in Dragon Age II
;---------------------------------------------------------------------------------------
;  314     kFileTypeALS            = 25000,
;  315     kFileTypeAPL            = 25001,
;  316     kFileTypeAssembly       = 25002,
;  317     kFileTypeBAK            = 25003,
;  318     kFileTypeBNK            = 25004,
;  319     kFileTypeCL             = 25005,
;  320     kFileTypeCNV            = 25006,
;  321     kFileTypeCON            = 25007,
;  322     kFileTypeDAT            = 25008,
;  323     kFileTypeDX11           = 25009,
;  324     kFileTypeIDS2            = 25010,
;  325     kFileTypeLOG2            = 25011,
;  326     kFileTypeMAP            = 25012,
;  327     kFileTypeMML            = 25013,
;  328     kFileTypeMP32            = 25014,
;  329     kFileTypePCK            = 25015,
;  330     kFileTypeRML            = 25016,
;  331     kFileTypeS              = 25017,
;  332     kFileTypeSTA            = 25018,
;  333     kFileTypeSVR            = 25019,
;  334     kFileTypeVLM            = 25020,
;  335     kFileTypeWBD            = 25021,
;  336     kFileTypeXBX            = 25022,
;  337     kFileTypeXLS            = 25023,
;  338 
;---------------------------------------------------------------------------------------
;  339     // Found in the iOS version of Knights of the Old Republic
;---------------------------------------------------------------------------------------
;  340     kFileTypeBZF            = 26000, 
;  341 
;---------------------------------------------------------------------------------------
;  342     // Found in The Witcher
;---------------------------------------------------------------------------------------
;  343     kFileTypeADV            = 27000,     This is the format used for saving modules. 


RES_TYPE_TOH            equ 0           ; '.TOH'
RES_TYPE_TOT            equ 0           ; '.TOT'
RES_TYPE_VAR            equ 0           ; '.VAR'
RES_TYPE_SAV            equ 0           ; '.SAV'

;; Extra bif resource types from SWKotoR


;ResType Type    Comment/speculation
;------- ----    ---------------------------------------
;0       RES     ???
;1       BMP     Bitmap image
;2       MVE     ???
;3       TGA     Targa image file
;4       WAV     Wave sound
;5       WFX     Wave extra info
;7       INI     Configuration file (plaintext)
;8       MP3     MP3 sound
;9       MPG     MPG video
;10      TXT     Text file
;11      PVD     Binary data (Pointer to Void Data).
;
;2000    PLH     Polyhedron
;2001    TEX     Texture
;2002    MDL     Model data (MDL) [used along with MDX file with the same name]
;2003    THG     Thing (???)
;2005    FNT     Font
;2007    LUA     Lua script
;2008    SLT     Slot file
;2009    NSS     Script sourcecode (plaintext)
;2010    NCS     Script bytecode (NCS)
;2011    MOD     Module (ERF)
;2012    ARE     Static area info (GFF)
;2013    SET     Tileset file
;2014    IFO     Module information (GFF)
;2016    WOK     Area Walkmesh
;2017    2DA     Data table (plaintext or 2DA V2.b binary)
;2018    TLK     Talk table file (TLK)
;2022    TXI     Extra Texture Info (plaintext)
;2023    GIT     Game Instance File (dynamic area info) (GFF)
;2024    ITM     Item template (GFF)
;2026    CRE     Creature template (GFF)
;2029    DLG     Dialog file (GFF)
;2030    PAL     Palette (GFF)
;2031    TRG     Triggers (GFF)
;2033    DDS     DXTC Compressed texture
;2034    SND     Sounds (???)
;2036    LTR     ???
;2037    GFF     Generic GFF file (GFF... duh)
;2038    FAC     Faction file (GFF)
;2039    ENC     Encounter template (GFF)
;2040    CON     Container template (GFF)
;2041    DOR     Door template (GFF)
;2043    PLA     Placeable template (GFF)
;2045    DFT     ???
;2046    GIC     Game Instance Comments (area editor comment data)
;2047    GUI     Graphical User Interface definition file. (GFF)
;2048    CSS     Conditional Source Script
;2049    CCS     Conditional Compiled Script
;2050    MER     Merchant/store template (GFF)
;2052    DWK     Door walkmesh
;2053    PWK     Placeable walkmesh (plaintext)
;2054    GEN     Random Item Generator
;2056    JRL     Journal file (GFF)
;2057    SAV     Area game state data (GFF)
;2058    WAY     waypoint template (GFF)
;2059    4PC     Custom 16-bit RGBA texture format
;2060    SSF     sound set file (SSF)
;2061    HAK     HAK file (ERF)
;2062    NWM     NWN Official Campaign module (ERF)
;2063    BIK     BINK movie (Bink video)
;2064    MIN     MiniGame data (GFF)
;2065    NDB     Script debugger data (toolset)
;2066    XWB     XACT WaveBank
;2067    XSB     XACT SoundBank
;2068    BIN     XBOX DSP filter
;
;3000    LYT     Area model layout (plaintext)
;3001    VIS     Area visibility graph (plaintext)
;3002    RIM     Resource Image File (RIM)
;3004    LIP     Lipsync Visemes data
;3005    XMV     ???
;3006    WMA     ???
;3007    CWD     Crowd game object template (GFF)
;3008    PRO     Projectile static resource type
;3009    AOE     Area of Effect static resouce type
;3010    MAT     material file (plaintext)
;3011    MAB     material file (binary)
;3012    QST     Quest/journal data (GFF)
;3013    STO     Store static resource file (GFF) [used with MER file?]
;3014    APL     Artist placeable
;3015    HEX     Hex grid (plaintext) [appears to be map-related in some way]
;3016    MDX     Extra model data (binary) [used along with MDL file]
;3017    TXB     Compressed image with TXI data
;3018    TPC     Compressed image with TXI data
;3019    CAM     ???
;3020    SPT     ???
;3021    STYLE   ???
;3022    FSM     Finite State Machine (FSM) data
;3023    ART     [Weather/Light data for area?] (INI/plaintext)
;3024    AMP     ??? (binary)
;3025    CWA     Crowd Attribute (GFF)
;3026    XLS      MS Excel spreadsheet
;3027    SPF     NGF: Style profiles
;3028    BIP     PATL: Binary LIP. - [lipsync/Sound file?]
;
;9996    IDS     Legacy BG Script File
;9997    ERF     Encapsulated file
;9998    BIF     BIFF file
;9999    KEY     Key file








;
;; Extra bif resource types from the Witcher
;0x0000 => 'res',   #Misc. GFF resources
;0x0001 => 'bmp',   #Microsoft Windows Bitmap
;0x0002 => 'mve',
;0x0003 => 'tga',   #Targa Graphics Format
;0x0004 => 'wav',   #Wave
;
;0x0006 => 'plt',   #Bioware Packed Layer Texture
;0x0007 => 'ini',   #Windows INI
;0x0008 => 'mp3',   #MP3
;0x0009 => 'mpg',   #MPEG
;0x000A => 'txt',   #Text file
;0x000B => 'xml',
;
;0x07D0 => 'plh',
;0x07D1 => 'tex',
;0x07D2 => 'mdl',   #Model
;0x07D3 => 'thg',
;
;0x07D5 => 'fnt',   #Font
;
;0x07D7 => 'lua',   #Lua script source code ( http://www.lua.org/ )
;0x07D8 => 'slt',
;0x07D9 => 'nss',   #NWScript source code
;0x07DA => 'ncs',   #NWScript bytecode
;0x07DB => 'mod',   #Module
;0x07DC => 'are',   #Area (GFF)
;0x07DD => 'set',   #Tileset (unused in KOTOR?)
;0x07DE => 'ifo',   #Module information
;0x07DF => 'bic',   #Character sheet (unused)
;0x07E0 => 'wok',   # walk-mesh
;0x07E1 => '2da',   #2-dimensional array
;0x07E2 => 'tlk',   #conversation file
;
;0x07E6 => 'txi',   #Texture information
;0x07E7 => 'git',   #Dynamic area information, game instance file, all area and objects that are scriptable
;0x07E8 => 'bti',
;0x07E9 => 'uti',   #item blueprint
;0x07EA => 'btc',
;0x07EB => 'utc',   #Creature blueprint
;
;0x07ED => 'dlg',   #Dialogue
;0x07EE => 'itp',   #tile blueprint pallet file
;0x07EF => 'btt',
;0x07F0 => 'utt',   #trigger blueprint
;0x07F1 => 'dds',   #compressed texture file
;0x07F2 => 'bts',
;0x07F3 => 'uts',   #sound blueprint
;0x07F4 => 'ltr',   #letter combo probability info
;0x07F5 => 'gff',   #Generic File Format
;0x07F6 => 'fac',   #faction file
;0x07F7 => 'bte',
;0x07F8 => 'ute',   #encounter blueprint
;0x07F9 => 'btd',
;0x07FA => 'utd',   #door blueprint
;0x07FB => 'btp',
;0x07FC => 'utp',   #placeable object blueprint
;0x07FD => 'dft',   #default values file (text-ini)
;0x07FE => 'gic',   #game instance comments
;0x07FF => 'gui',   #GUI definition (GFF)
;0x0800 => 'css',
;0x0801 => 'ccs',
;0x0802 => 'btm',
;0x0803 => 'utm',   #store merchant blueprint
;0x0804 => 'dwk',   #door walkmesh
;0x0805 => 'pwk',   #placeable object walkmesh
;0x0806 => 'btg',
;
;0x0808 => 'jrl',   #Journal
;0x0809 => 'sav',   #Saved game (ERF)
;0x080A => 'utw',   #waypoint blueprint
;0x080B => '4pc',
;0x080C => 'ssf',   #sound set file
;
;0x080F => 'bik',   #movie file (bik format)
;0x0810 => 'ndb',        #script debugger file
;0x0811 => 'ptm',        #plot manager/plot instance
;0x0812 => 'ptt',        #plot wizard blueprint
;0x0813 => 'ncm',
;0x0814 => 'mfx',
;0x0815 => 'mat',
;0x0816 => 'mdb',        #not the standard MDB, multiple file formats present despite same type
;0x0817 => 'say',
;0x0818 => 'ttf',        #standard .ttf font files
;0x0819 => 'ttc',
;0x081A => 'cut',        #cutscene? (GFF)
;0x081B => 'ka',         #karma file (XML)
;0x081C => 'jpg',        #jpg image
;0x081D => 'ico',        #standard windows .ico files
;0x081E => 'ogg',        #ogg vorbis sound file
;0x081F => 'spt',
;0x0820 => 'spw',
;0x0821 => 'wfx',        #woot effect class (XML)
;0x0822 => 'ugm',        # 2082 ??? [textures00.bif]
;0x0823 => 'qdb',        #quest database (GFF v3.38)
;0x0824 => 'qst',        #quest (GFF)
;0x0825 => 'npc',
;0x0826 => 'spn',
;0x0827 => 'utx',        #spawn point? (GFF)
;0x0828 => 'mmd',
;0x0829 => 'smm',
;0x082A => 'uta',        #uta (GFF)
;0x082B => 'mde',
;0x082C => 'mdv',
;0x082D => 'mda',
;0x082E => 'mba',
;0x082F => 'oct',
;0x0830 => 'bfx',
;0x0831 => 'pdb',
;0x0832 => 'TheWitcherSave',
;0x0833 => 'pvs',
;0x0834 => 'cfx',
;0x0835 => 'luc',        #compiled lua script
;
;0x0837 => 'prb',
;0x0838 => 'cam',
;0x0839 => 'vds',
;0x083A => 'bin',
;0x083B => 'wob',
;0x083C => 'api',
;0x083D => 'properties',
;0x083E => 'png',
;
;0x270B => 'big',
;
;0x270D => 'erf',   #Encapsulated Resource Format
;0x270E => 'bif',
;0x270F => 'key',   












