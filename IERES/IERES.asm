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

.686
.MMX
.XMM
.model flat,stdcall
option casemap:none

include windows.inc
include kernel32.inc
include user32.inc
include masm32.inc

includelib kernel32.lib
includelib user32.lib
includelib masm32.lib


include IERES.inc

;DEBUGLOG EQU 1
IFDEF DEBUGLOG
    include DebugLogLIB.asm
ENDIF
;DEBUG32 EQU 1

IFDEF DEBUG32
    PRESERVEXMMREGS equ 1
    includelib M:\Masm32\lib\Debug32.lib
    DBG32LIB equ 1
    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
    include M:\Masm32\include\debug32.inc
ENDIF

;-------------------------------------------------------------------------
; Prototypes for internal use
;-------------------------------------------------------------------------
RESutoa_ex              PROTO :DWORD, :DWORD



;-------------------------------------------------------------------------
; Structures for internal use
;-------------------------------------------------------------------------


.CONST



.DATA
IFDEF DEBUG32
DbgVar                      DD 0
ENDIF

;=======================================================================================
; DWORD FILE EXTENSION STRINGS FOR RESOURCE TYPES
;=======================================================================================

dwCBFExt                  dd '.cbf'
dwTLKExt                  dd '.tlk'
dwACMExt                  dd '.acm'
dwMUSExt                  dd '.mus'
;---------------------------------------------------------------------------------------
; 0 - 20 - Common files
;---------------------------------------------------------------------------------------
dwBMPExt                  dd '.bmp'
dwMVEExt                  dd '.mve'
dwTGAExt                  dd '.tga'
dwWAVExt                  dd '.wav'
dwWFXExt                  dd '.wfx'
dwPLTExt                  dd '.plt'
dwINIExt                  dd '.ini'
dwMP3Ext                  dd '.mp3'
dwMPGExt                  dd '.mpg'
dwTXTExt                  dd '.txt'
dwXMLExt                  dd '.xml'
dwWMAExt                  dd '.wma'
dwWMVExt                  dd '.wmv'
dwXMVExt                  dd '.xmv'
dwTWODA3Ext               dd '.2da'

;---------------------------------------------------------------------------------------
; 1000 - 2000 :: (0x03E8 - 0x07D0) Infinity Engine resource types
;---------------------------------------------------------------------------------------
dwBAMExt                  dd '.bam'
dwWEDExt                  dd '.wed'
dwCHUExt                  dd '.chu'
dwTISExt                  dd '.tis'
dwMOSExt                  dd '.mos'
dwITMExt                  dd '.itm'
dwSPLExt                  dd '.spl'
dwBCSExt                  dd '.bcs'
dwIDSExt                  dd '.ids'
dwCREExt                  dd '.cre'
dwAREExt                  dd '.are'
dwDLGExt                  dd '.dlg'
dwTWODAExt                dd '.2da'
dwGAMExt                  dd '.gam'
dwSTOExt                  dd '.sto'
dwWMPExt                  dd '.wmp'
dwCHRExt                  dd '.chr' ; shares resourceid 03F8h (1016) with EFF
dwEFFExt                  dd '.eff' ; shares resourceid 03F8h (1016) with CHR
dwBSExt                   dd '.bs',0
dwCHR2Ext                 dd '.chr'
dwVVCExt                  dd '.vvc'
dwVEFExt                  dd '.vef'
dwPROExt                  dd '.pro'
dwBIOExt                  dd '.bio'
dwBAHExt                  dd '.bah'
dwBAFExt                  dd '.baf'
dwFONExt                  dd '.fon' ; EE 
dwWBMExt                  dd '.wbm' ; EE
dwGUIExt                  dd '.gui' ; EE
dwSQLExt                  dd '.sql' ; EE
dwPVRExt                  dd 'pvrz' ; EE
dwGLSLExt                 dd 'glsl' ; EE
dwMENUExt                 dd 'menu' ; EE 2.0
dwLUA2Ext                 dd '.lua' ; EE 2.0
dwTTF2Ext                 dd '.ttf' ; EE 2.0 
dwPNG2Ext                 dd '.png' ; EE 2.0


dwINI2Ext                 dd '.ini'
dwSRCExt                  dd '.src'
dwTOHExt                  dd '.toh'
dwTOTExt                  dd '.tot'
dwVARExt                  dd '.var'
dwSAVExt                  dd '.sav'

;---------------------------------------------------------------------------------------
; 2000 - 3000 :: (0x07D0 - 0x0BB8) NWN resource types
;---------------------------------------------------------------------------------------
dwPLHExt                  dd '.plh'
dwTEXExt                  dd '.tex'
dwMDLExt                  dd '.mdl'
dwTHGExt                  dd '.thg'
dwFNTExt                  dd '.fnt'
dwLUAExt                  dd '.lua'
dwSLTExt                  dd '.slt'
dwNSSExt                  dd '.nss'
dwNCSExt                  dd '.ncs'
dwMODExt                  dd '.mod'
dwARE2Ext                 dd '.are'
dwSETExt                  dd '.set'
dwIFOExt                  dd '.ifo'
dwBICExt                  dd '.bic'
dwWOKExt                  dd '.wok'
dwTWODA2Ext               dd '.2da'
;dwTLKExt                 dd '.tlk'
dwTXIExt                  dd '.txi'
dwGITExt                  dd '.git'
dwBTIExt                  dd '.bti' 
dwUTIExt                  dd '.uti'
dwBTCExt                  dd '.btc'
dwUTCExt                  dd '.utc'
dwDLG2Ext                 dd '.dlg'
dwITPExt                  dd '.itp'
dwPALExt                  dd '.pal'
dwBTTExt                  dd '.btt'
dwTRGExt                  dd '.trg'
dwUTTExt                  dd '.utt'
dwDDSExt                  dd '.dds'
dwBTSExt                  dd '.bts'
dwSNDExt                  dd '.snd'
dwUTSExt                  dd '.uts'
dwLTRExt                  dd '.ltr'
dwGFFExt                  dd '.gff'
dwFACExt                  dd '.fac'
dwBTEExt                  dd '.bte'
dwENCExt                  dd '.enc'
dwUTEExt                  dd '.ute'
dwCONExt                  dd '.ute'
dwBTDExt                  dd '.btd'
dwDORExt                  dd '.dor'
dwUTDExt                  dd '.utd'
dwBTPExt                  dd '.btp'
dwPLAExt                  dd '.pla'
dwUTPExt                  dd '.utp'
dwDFTExt                  dd '.dft'
dwGICExt                  dd '.gic'
dwGUI2Ext                 dd '.gui'
dwBTWExt                  dd '.btw'

;---------------------------------------------------------------------------------------
; 2048 - 2110 Witcher
;---------------------------------------------------------------------------------------
dwCSSExt                  dd '.css'
dwCCSExt                  dd '.ccs'
dwBTMExt                  dd '.btm'
dwMERExt                  dd '.mer'
dwUTMExt                  dd '.utm'
dwDWKExt                  dd '.dwk'
dwPWKExt                  dd '.pwk'
dwBTGExt                  dd '.btg'
dwUTGExt                  dd '.utg'
dwGENExt                  dd '.gen'
dwJRLExt                  dd '.jrl'
dwSAV2Ext                 dd '.sav'
dwUTWExt                  dd '.utw'
dwWAYExt                  dd '.way'
dwFOURPCExt               dd '.4pc'
dwSSFExt                  dd '.ssf'
dwHAKExt                  dd '.hak'
dwNWMExt                  dd '.nwm'
dwBIKExt                  dd '.bik'
dwNDBExt                  dd '.ndb'
dwPTMExt                  dd '.ptm'
dwPTTExt                  dd '.ptt'
dwNCMExt                  dd '.ncm'
dwXSBExt                  dd '.xsb'
dwMFXExt                  dd '.mfx'
dwBINExt                  dd '.bin'
dwMATExt                  dd '.mat'
dwMDBExt                  dd '.mdb'
dwSAYExt                  dd '.say'
dwTTFExt                  dd '.ttf'
dwTTCExt                  dd '.ttc'
dwCUTExt                  dd '.cut'
dwKAExt                   dd '.ka',0
dwJPGExt                  dd '.jpg'
dwICOExt                  dd '.ico'
dwOGGExt                  dd '.ogg'
dwSPTExt                  dd '.spt'
dwSPWExt                  dd '.spw'
dwWFX2Ext                 dd '.wfx'
dwUGMExt                  dd '.ugm'
dwQDBExt                  dd '.qdb'
dwQSTExt                  dd '.qst'
dwNPCExt                  dd '.npc'
dwSPNExt                  dd '.spn'
dwUTXExt                  dd '.utx'
dwMMDExt                  dd '.mmd'
dwSMMExt                  dd '.smm'
dwUTAExt                  dd '.uta'
dwMDEExt                  dd '.mde'
dwMDVExt                  dd '.mdv'
dwMDAExt                  dd '.mda'
dwMBAExt                  dd '.mba'
dwOCTExt                  dd '.oct'
dwBFXExt                  dd '.bfx'
dwPDBExt                  dd '.pdb'
;dwTHEWITCHERSAVEExt       dd '.The','Witc','herS','ave'
dwPVSExt                  dd '.pvs'
dwCFXExt                  dd '.cfx'
dwLUCExt                  dd '.luc'
dwPRBExt                  dd '.prb'
dwCAMExt                  dd '.cam'
dwVDSExt                  dd '.vds'
dwWOBExt                  dd '.wob'
dwAPIExt                  dd '.api'
;dwPROPERTIESExt           dd '.pro','pert','ies'
dwPNGExt                  dd '.png'

;---------------------------------------------------------------------------------------
; 3000 - 4000 :: (0x0BB8 - 0x0FA0) SW:KOTOR resource types
;---------------------------------------------------------------------------------------
dwLYTExt                  dd '.lyt'
dwVISExt                  dd '.vis'
dwRIMExt                  dd '.rim'
dwPTHExt                  dd '.pth'
dwLIPExt                  dd '.lip'
dwBWMExt                  dd '.bwm'
dwTXBExt                  dd '.txb'
dwTPCExt                  dd '.tpc'
dwCWDExt                  dd '.cwd'
dwMDXExt                  dd '.mdx'
dwRSVExt                  dd '.rsv'
dwAOEExt                  dd '.aoe'
dwSIGExt                  dd '.sig'
dwMABExt                  dd '.mab'
dwQST2Ext                 dd '.qst'     ; 3012, 
dwSTO2Ext                 dd '.sto'     ; 3013,
dwAPLExt                  dd '.apl'     ; 3015,
dwHEXExt                  dd '.hex'     ; 3015, 
dwMDX2Ext                 dd '.mdx'     ; 3016, 
dwTXB2Ext                 dd '.txb'     ; 3017, 
dwTPC2Ext                 dd '.tpc'     ; 3017,
dwFSMExt                  dd '.fsm'     ; 3022, 
dwARTExt                  dd '.art'     ; 3023, 
dwAMPExt                  dd '.amp'     ; 3028,
dwCWAExt                  dd '.cwa'     ; 3028,
dwXLSExt                  dd '.xls'     ; 3028,
dwSPFExt                  dd '.spf'     ; 3028,
dwBIPExt                  dd '.bip'     ; 3028, 
dwMDB2Ext                 dd '.mdb'     ; 4000,
dwMDA2Ext                 dd '.mda'     ; 4001,
dwSPT2Ext                 dd '.spt'     ; 4002,
dwGR2Ext                  dd '.gr',0        ; 4003,
dwFXAExt                  dd '.fxa'     ; 4004,
dwFXEExt                  dd '.fxe'     ; 4005,
dwJPG2Ext                 dd '.jpg'     ; 4007,
dwPWCExt                  dd '.pwc'     ; 4008,

;---------------------------------------------------------------------------------------
; 9997-9999: Common resource types 
;---------------------------------------------------------------------------------------
dwBIGExt                  dd '.big'
dwIDS2Ext                 dd '.ids'
dwERFExt                  dd '.erf'
dwBIFExt                  dd '.bif'
dwKEYExt                  dd '.key'

;---------------------------------------------------------------------------------------
; Found in NWN: Visual Foxpro database formats: dbf=database, cdx=index, fpt=memo
;---------------------------------------------------------------------------------------
dwVFPEXEExt               dd '.exe'; 19000, 
dwVFPDBFExt               dd '.dbf'; 19001, 
dwVFPCDXExt               dd '.cdx'; 19002, 
dwVFPFPTExt               dd '.fpt'; 19003, 
















;ResIndexStrings100          DB '  0',0,'  1',0,'  2',0,'  3',0,'  4',0,'  5',0,'  6',0,'  7',0,'  8',0,'  9',0
;                            DB ' 10',0,' 11',0,' 12',0,' 13',0,' 14',0,' 15',0,' 16',0,' 17',0,' 18',0,' 19',0
;                            DB ' 20',0,' 21',0,' 22',0,' 23',0,' 24',0,' 25',0,' 26',0,' 27',0,' 28',0,' 29',0
;                            DB ' 30',0,' 31',0,' 32',0,' 33',0,' 34',0,' 35',0,' 36',0,' 37',0,' 38',0,' 39',0
;                            DB ' 40',0,' 41',0,' 42',0,' 43',0,' 44',0,' 45',0,' 46',0,' 47',0,' 48',0,' 49',0
;                            DB ' 50',0,' 51',0,' 52',0,' 53',0,' 54',0,' 55',0,' 56',0,' 57',0,' 58',0,' 59',0
;                            DB ' 60',0,' 61',0,' 62',0,' 63',0,' 64',0,' 65',0,' 66',0,' 67',0,' 68',0,' 69',0
;                            DB ' 70',0,' 71',0,' 72',0,' 73',0,' 74',0,' 75',0,' 76',0,' 77',0,' 78',0,' 79',0
;                            DB ' 80',0,' 81',0,' 82',0,' 83',0,' 84',0,' 85',0,' 86',0,' 87',0,' 88',0,' 89',0
;                            DB ' 90',0,' 91',0,' 92',0,' 93',0,' 94',0,' 95',0,' 96',0,' 97',0,' 98',0,' 99',0
;                            DB '100',0,'101',0,'102',0,'103',0,'104',0,'105',0,'106',0,'107',0,'108',0,'109',0,0,0,0,0
                            




;=======================================================================================
; FILE EXTENSION STRINGS FOR RESOURCE TYPES
;=======================================================================================
UnknownExt              db ".???",0
CBFExt                  db ".cbf",0
TLKExt                  db ".tlk",0
ACMExt                  db '.acm',0
MUSExt                  db '.mus',0
;---------------------------------------------------------------------------------------
; 0 - 20 - Common files
;---------------------------------------------------------------------------------------
BMPExt                  db '.bmp',0
MVEExt                  db '.mve',0
TGAExt                  db '.tga',0
WAVExt                  db '.wav',0
WAVCExt                 db '.wavc',0
WFXExt                  db '.wfx',0
PLTExt                  db '.plt',0
INIExt                  db '.ini',0
MP3Ext                  db '.mp3',0
MPGExt                  db '.mpg',0
TXTExt                  db '.txt',0
XMLExt                  db '.xml',0
WMAExt                  db '.wma',0
WMVExt                  db '.wmv',0
XMVExt                  db '.xmv',0
TWODA3Ext               db '.2da',0

;---------------------------------------------------------------------------------------
; 1000 - 2000 :: (0x03E8 - 0x07D0) Infinity Engine resource types
;---------------------------------------------------------------------------------------
BAMExt                  db '.bam',0
BAMCExt                 db '.bamc',0
BAMUExt                 db '.bamu',0
WEDExt                  db '.wed',0
CHUExt                  db '.chu',0
TISExt                  db '.tis',0
MOSExt                  db '.mos',0
MOSCExt                 db '.mosc',0
MOSUExt                 db '.mosu',0
ITMExt                  db '.itm',0
SPLExt                  db '.spl',0
BCSExt                  db '.bcs',0
IDSExt                  db '.ids',0
CREExt                  db '.cre',0
AREExt                  db '.are',0
DLGExt                  db '.dlg',0
TWODAExt                db '.2da',0
GAMExt                  db '.gam',0
STOExt                  db '.sto',0
WMPExt                  db '.wmp',0
CHRExt                  db '.chr',0 ; shares resourceid 03F8h (1016) with EFF
EFFExt                  db '.eff',0 ; shares resourceid 03F8h (1016) with CHR
BSExt                   db '.bs',0
CHR2Ext                 db '.chr',0
VVCExt                  db '.vvc',0
VEFExt                  db '.vef',0
PROExt                  db '.pro',0
BIOExt                  db '.bio',0
BAHExt                  db '.bah',0
BAFExt                  db '.baf',0
FONExt                  db '.fon',0 ; EE 
WBMExt                  db '.wbm',0 ; EE
GUIExt                  db '.gui',0 ; EE
SQLExt                  db '.sql',0 ; EE
PVRExt                  db '.pvrz',0 ; EE
GLSLExt                 db '.glsl',0 ; EE
MENUExt                 db '.menu',0 ; EE 2.0
LUA2Ext                 db '.lua',0  ; EE 2.0
TTF2Ext                 db '.ttf',0  ; EE 2.0
PNG2Ext                 db '.png',0  ; EE 2.0

INI2Ext                 db '.ini',0
SRCExt                  db '.src',0
TOHExt                  db '.toh',0
TOTExt                  db '.tot',0
VARExt                  db '.var',0
SAVExt                  db '.sav',0

;---------------------------------------------------------------------------------------
; 2000 - 3000 :: (0x07D0 - 0x0BB8) NWN resource types
;---------------------------------------------------------------------------------------
PLHExt                  db '.plh',0
TEXExt                  db '.tex',0
MDLExt                  db '.mdl',0
THGExt                  db '.thg',0
FNTExt                  db '.fnt',0
LUAExt                  db '.lua',0
SLTExt                  db '.slt',0
NSSExt                  db '.nss',0
NCSExt                  db '.ncs',0
MODExt                  db '.mod',0
ARE2Ext                 db '.are',0
SETExt                  db '.set',0
IFOExt                  db '.ifo',0
BICExt                  db '.bic',0
WOKExt                  db '.wok',0
TWODA2Ext               db '.2da',0
;TLKExt                 db '.tlk',0
TXIExt                  db '.txi',0
GITExt                  db '.git',0
BTIExt                  db '.bti',0 
UTIExt                  db '.uti',0
BTCExt                  db '.btc',0
UTCExt                  db '.utc',0
DLG2Ext                 db '.dlg',0
ITPExt                  db '.itp',0
PALExt                  db '.pal',0
BTTExt                  db '.btt',0
TRGExt                  db '.trg',0
UTTExt                  db '.utt',0
DDSExt                  db '.dds',0
BTSExt                  db '.bts',0
SNDExt                  db '.snd',0
UTSExt                  db '.uts',0
LTRExt                  db '.ltr',0
GFFExt                  db '.gff',0
FACExt                  db '.fac',0
BTEExt                  db '.bte',0
ENCExt                  db '.enc',0
UTEExt                  db '.ute',0
CONExt                  db '.ute',0
BTDExt                  db '.btd',0
DORExt                  db '.dor',0
UTDExt                  db '.utd',0
BTPExt                  db '.btp',0
PLAExt                  db '.pla',0
UTPExt                  db '.utp',0
DFTExt                  db '.dft',0
GICExt                  db '.gic',0
GUI2Ext                 db '.gui',0

;---------------------------------------------------------------------------------------
; 2048 - 2110 Witcher
;---------------------------------------------------------------------------------------
CSSExt                  db '.css',0
CCSExt                  db '.ccs',0
BTMExt                  db '.btm',0
MERExt                  db '.mer',0
UTMExt                  db '.utm',0
DWKExt                  db '.dwk',0
PWKExt                  db '.pwk',0
BTGExt                  db '.btg',0
UTGExt                  db '.utg',0
GENExt                  db '.gen',0
JRLExt                  db '.jrl',0
SAV2Ext                 db '.sav',0
UTWExt                  db '.utw',0
WAYExt                  db '.way',0
FOURPCExt               db '.4pc',0
SSFExt                  db '.ssf',0
HAKExt                  db '.hak',0
NWMExt                  db '.nwm',0
BIKExt                  db '.bik',0
NDBExt                  db '.ndb',0
PTMExt                  db '.ptm',0
PTTExt                  db '.ptt',0
NCMExt                  db '.ncm',0
XSBExt                  db '.xsb',0
MFXExt                  db '.mfx',0
BINExt                  db '.bin',0
MATExt                  db '.mat',0
MDBExt                  db '.mdb',0
SAYExt                  db '.say',0
TTFExt                  db '.ttf',0
TTCExt                  db '.ttc',0
CUTExt                  db '.cut',0
KAExt                   db '.ka',0
JPGExt                  db '.jpg',0
ICOExt                  db '.ico',0
OGGExt                  db '.ogg',0
SPTExt                  db '.spt',0
SPWExt                  db '.spw',0
WFX2Ext                 db '.wfx',0
UGMExt                  db '.ugm',0
QDBExt                  db '.qdb',0
QSTExt                  db '.qst',0
NPCExt                  db '.npc',0
SPNExt                  db '.spn',0
UTXExt                  db '.utx',0
MMDExt                  db '.mmd',0
SMMExt                  db '.smm',0
UTAExt                  db '.uta',0
MDEExt                  db '.mde',0
MDVExt                  db '.mdv',0
MDAExt                  db '.mda',0
MBAExt                  db '.mba',0
OCTExt                  db '.oct',0
BFXExt                  db '.bfx',0
PDBExt                  db '.pdb',0
THEWITCHERSAVEExt       db '.TheWitcherSave',0
PVSExt                  db '.pvs',0
CFXExt                  db '.cfx',0
LUCExt                  db '.luc',0
PRBExt                  db '.prb',0
CAMExt                  db '.cam',0
VDSExt                  db '.vds',0
WOBExt                  db '.wob',0
APIExt                  db '.api',0
PROPERTIESExt           db '.properties',0
PNGExt                  db '.png',0

;---------------------------------------------------------------------------------------
; 3000 - 4000 :: (0x0BB8 - 0x0FA0) SW:KOTOR resource types
;---------------------------------------------------------------------------------------
LYTExt                  db '.lyt',0
VISExt                  db '.vis',0
RIMExt                  db '.rim',0
PTHExt                  db '.pth',0
LIPExt                  db '.lip',0
BWMExt                  db '.bwm',0
TXBExt                  db '.txb',0
TPCExt                  db '.tpc',0
CWDExt                  db '.cwd',0
MDXExt                  db '.mdx',0
RSVExt                  db '.rsv',0
AOEExt                  db '.aoe',0
SIGExt                  db '.sig',0
MABExt                  db '.mab',0
QST2Ext                 db '.qst',0     ; 3012, 
STO2Ext                 db '.sto',0     ; 3013,
APLExt                  db '.apl',0     ; 3015,
HEXExt                  db '.hex',0     ; 3015, 
MDX2Ext                 db '.mdx',0     ; 3016, 
TXB2Ext                 db '.txb',0     ; 3017, 
TPC2Ext                 db '.tpc',0     ; 3017,
FSMExt                  db '.fsm',0     ; 3022, 
ARTExt                  db '.art',0     ; 3023, 
AMPExt                  db '.amp',0     ; 3028,
CWAExt                  db '.cwa',0     ; 3028,
XLSExt                  db '.xls',0     ; 3028,
SPFExt                  db '.spf',0     ; 3028,
BIPExt                  db '.bip',0     ; 3028, 
MDB2Ext                 db '.mdb',0     ; 4000,
MDA2Ext                 db '.mda',0     ; 4001,
SPT2Ext                 db '.spt',0     ; 4002,
GR2Ext                  db '.gr',0      ; 4003,
FXAExt                  db '.fxa',0     ; 4004,
FXEExt                  db '.fxe',0     ; 4005,
JPG2Ext                 db '.jpg',0     ; 4007,
PWCExt                  db '.pwc',0     ; 4008,

;---------------------------------------------------------------------------------------
; 9997-9999: Common resource types 
;---------------------------------------------------------------------------------------
BIGExt                  db '.big',0
IDS2Ext                 db '.ids',0
ERFExt                  db '.erf',0
BIFExt                  db '.bif',0
KEYExt                  db '.key',0

;---------------------------------------------------------------------------------------
; Found in NWN: Visual Foxpro database formats: dbf=database, cdx=index, fpt=memo
;---------------------------------------------------------------------------------------
VFPEXEExt               db '.exe',0; 19000, 
VFPDBFExt               db '.dbf',0; 19001, 
VFPCDXExt               db '.cdx',0; 19002, 
VFPFPTExt               db '.fpt',0; 19003, 



;=======================================================================================
; RESOURCE TYPE HEX STRINGS FOR RESOURCE TYPES
;=======================================================================================
szRES_TYPE_UNKNOWN      db '?',0
szRES_TYPE_NONE         db '0x0000',0       ; 'none'
;---------------------------------------------------------------------------------------
; 0 - 20 - Common files
;---------------------------------------------------------------------------------------
szRES_TYPE_BMP          db '0x0001',0       ; '.BMP'
szRES_TYPE_MVE          db '0x0002',0       ; '.MVE'
szRES_TYPE_TGA          db '0x0003',0       ; tga Targa Graphics Format
szRES_TYPE_WAV          db '0x0004',0       ; '.WAV'
szRES_TYPE_WAVC         db '0x0004',0       ; '.WAVC'
szRES_TYPE_WFX          db '0x0005',0       ; '.WFX'
szRES_TYPE_PLT          db '0x0006',0       ; '.PLT'
szRES_TYPE_INI          db '0x0007',0       ; ini Windows INI
szRES_TYPE_MP3          db '0x0008',0       ; mp3 MP3
szRES_TYPE_MPG          db '0x0009',0       ; mpg MPEG
szRES_TYPE_TXT          db '0x000A',0       ; txt Text file
szRES_TYPE_XML          db '0x000B',0       ; xml
szRES_TYPE_WMA          db '0x000B',0       ; wma Windows Media audio?
szRES_TYPE_WMV          db '0x000C',0       ; wmv Windows Media video?
szRES_TYPE_XMV          db '0x000D',0       ; xmv
szRES_TYPE_2DA3         db '0x014B',0       ; 2da witcher

;---------------------------------------------------------------------------------------
; 1000 - 2000 :: (0x03E8 - 0x07D0) Infinity Engine resource types
;---------------------------------------------------------------------------------------
szRES_TYPE_BAM          db '0x03E8',0       ; '.BAM'
szRES_TYPE_WED          db '0x03E9',0       ; '.WED'
szRES_TYPE_CHU          db '0x03EA',0       ; '.CHU'
szRES_TYPE_TIS          db '0x03EB',0       ; '.TIS'
szRES_TYPE_MOS          db '0x03EC',0       ; '.MOS'
szRES_TYPE_ITM          db '0x03ED',0       ; '.ITM'
szRES_TYPE_SPL          db '0x03EE',0       ; '.SPL'
szRES_TYPE_BCS          db '0x03EF',0       ; '.BCS'
szRES_TYPE_IDS          db '0x03F0',0       ; '.IDS'
szRES_TYPE_CRE          db '0x03F1',0       ; '.CRE'
szRES_TYPE_ARE          db '0x03F2',0       ; '.ARE'
szRES_TYPE_DLG          db '0x03F3',0       ; '.DLG'
szRES_TYPE_2DA          db '0x03F4',0       ; '.2DA'
szRES_TYPE_GAM          db '0x03F5',0       ; '.GAM'
szRES_TYPE_STO          db '0x03F6',0       ; '.STO'
szRES_TYPE_WMP          db '0x03F7',0       ; '.WMP'
szRES_TYPE_CHR          db '0x03F8',0       ; '.CHR'
szRES_TYPE_EFF          db '0x03F8',0       ; '.EFF'; ToTSC and IWD and BG2 Effects; a replacement for the 30-byte effect structure found in CRE and ITM files. The EFF V2.0 format can be found either as a standalone file or embedded in CRE, ITM and SPL files.
;szRES_TYPE_EFF2         db '0x03F8',0      ; '.EFF'; once decided we can use this id temporarily
szRES_TYPE_BS           db '0x03F9',0       ; '.BS'
szRES_TYPE_CHR2         db '0x03FA',0       ; '.CHR'
szRES_TYPE_VVC          db '0x03FB',0       ; '.WC'
szRES_TYPE_VEF          db '0x03FC',0       ; '.VEF'
szRES_TYPE_PRO          db '0x03FD',0       ; '.PRO'
szRES_TYPE_BIO          db '0x03FE',0       ; '.BIO'
szRES_TYPE_WBM          db '0x03FF',0       ; '.WBM'; EE
szRES_TYPE_FON          db '0x0400',0       ; '.FON'; EE 
szRES_TYPE_GUI          db '0x0402',0       ; '.GUI'; EE
szRES_TYPE_SQL          db '0x0403',0       ; '.SQL'; EE
szRES_TYPE_PVR          db '0x0404',0       ; '.PVRZ'; EE
szRES_TYPE_GLSL         db '0x0405',0       ; '.GLSL'; EE
szRES_TYPE_MENU         db '0x0408',0       ; '.menu'; EE 2.0
szRES_TYPE_LUA2         db '0x0409',0       ; '.lua' ; EE 2.0
szRES_TYPE_TTF2         db '0x040A',0       ; '.ttf' ; EE 2.0
szRES_TYPE_PNG2         db '0x040B',0       ; '.png' ; EE 2.0
szRES_TYPE_BAH          db '0x044C',0       ; '.BAH'

;---------------------------------------------------------------------------------------
; 2000 - 3000 :: (0x07D0 - 0x0BB8) NWN resource types
;---------------------------------------------------------------------------------------
szRES_TYPE_PLH          db '0x07D0',0       ; plh
szRES_TYPE_TEX          db '0x07D1',0       ; tex
szRES_TYPE_MDL          db '0x07D2',0       ; mdl Model
szRES_TYPE_THG          db '0x07D3',0       ; thg
szRES_TYPE_FNT          db '0x07D5',0       ; fnt Font
szRES_TYPE_LUA          db '0x07D7',0       ; lua
szRES_TYPE_SLT          db '0x07D8',0       ; slt
szRES_TYPE_NSS          db '0x07D9',0       ; nss NWScript source code
szRES_TYPE_NCS          db '0x07DA',0       ; ncs NWScript bytecode
szRES_TYPE_MOD          db '0x07DB',0       ; mod Module
szRES_TYPE_ARE2         db '0x07DC',0       ; are Area (GFF)
szRES_TYPE_SET          db '0x07DD',0       ; set Tileset (unused in KOTOR?)
szRES_TYPE_IFO          db '0x07DE',0       ; ifo Module information
szRES_TYPE_BIC          db '0x07DF',0       ; bic Character sheet (unused)
szRES_TYPE_WOK          db '0x07E0',0       ; wok
szRES_TYPE_2DA2         db '0x07E1',0       ; 2da 2-dimensional array
szRES_TYPE_TLK          db '0x07E2',0       ; tlk
szRES_TYPE_TXI          db '0x07E6',0       ; txi Texture information
szRES_TYPE_GIT          db '0x07E7',0       ; git Dynamic area information
szRES_TYPE_BTI          db '0x07E8',0       ; bti / itm
szRES_TYPE_ITM2         db '0x07E8',0       ; 
szRES_TYPE_UTI          db '0x07E9',0       ; uti
szRES_TYPE_BTC          db '0x07EA',0       ; btc / cre
szRES_TYPE_CRE2         db '0x07EA',0       ; 
szRES_TYPE_UTC          db '0x07EB',0       ; utc Creature blueprint
szRES_TYPE_DLG2         db '0x07ED',0       ; dlg Dialogue
szRES_TYPE_ITP          db '0x07EE',0       ; itp / pal
szRES_TYPE_PAL          db '0x07EE',0       ; 
szRES_TYPE_BTT          db '0x07EF',0       ; btt / trg
szRES_TYPE_TRG          db '0x07EF',0       ; 
szRES_TYPE_UTT          db '0x07F0',0       ; utt
szRES_TYPE_DDS          db '0x07F1',0       ; dds
szRES_TYPE_BTS          db '0x07F2',0       ; bts / snd
szRES_TYPE_SND          db '0x07F2',0       ; 
szRES_TYPE_UTS          db '0x07F3',0       ; uts
szRES_TYPE_LTR          db '0x07F4',0       ; ltr
szRES_TYPE_GFF          db '0x07F5',0       ; gff Generic File Format
szRES_TYPE_FAC          db '0x07F6',0       ; fac
szRES_TYPE_BTE          db '0x07F7',0       ; bte / enc
szRES_TYPE_ENC          db '0x07F7',0       ; 
szRES_TYPE_UTE          db '0x07F8',0       ; ute / con
szRES_TYPE_CON          db '0x07F8',0       ; 
szRES_TYPE_BTD          db '0x07F9',0       ; btd / dor
szRES_TYPE_DOR          db '0x07F9',0       ; 
szRES_TYPE_UTD          db '0x07FA',0       ; utd
szRES_TYPE_BTP          db '0x07FB',0       ; btp / pla
szRES_TYPE_PLA          db '0x07FB',0       ; 
szRES_TYPE_UTP          db '0x07FC',0       ; utp
szRES_TYPE_DFT          db '0x07FD',0       ; dft
szRES_TYPE_GIC          db '0x07FE',0       ; gic
szRES_TYPE_GUI2         db '0x07FF',0       ; gui GUI definition (GFF)

;---------------------------------------------------------------------------------------
; 2048 - 2110 Witcher
;---------------------------------------------------------------------------------------
szRES_TYPE_CSS          db '0x0800',0       ; css
szRES_TYPE_CCS          db '0x0801',0       ; ccs
szRES_TYPE_BTM          db '0x0802',0       ; btm / mer / ini
szRES_TYPE_MER          db '0x0802',0       ; 
szRES_TYPE_INI2         db '0x0802',0       ; 
szRES_TYPE_UTM          db '0x0803',0       ; utm / src
szRES_TYPE_SRC          db '0x0803',0       ; 
szRES_TYPE_DWK          db '0x0804',0       ; dwk
szRES_TYPE_PWK          db '0x0805',0       ; pwk
szRES_TYPE_BTG          db '0x0806',0       ; btg
szRES_TYPE_UTG          db '0x0807',0       ; utg / gen
szRES_TYPE_GEN          db '0x0807',0       ; 
szRES_TYPE_JRL          db '0x0808',0       ; jrl Journal
szRES_TYPE_SAV2         db '0x0809',0       ; sav Saved game (ERF)
szRES_TYPE_UTW          db '0x080A',0       ; utw / way
szRES_TYPE_WAY          db '0x080A',0       ; 
szRES_TYPE_4PC          db '0x080B',0       ; 4pc
szRES_TYPE_SSF          db '0x080C',0       ; ssf
szRES_TYPE_HAK          db '0x080D',0       ; hak Hak pak (unused)
szRES_TYPE_NWM          db '0x080E',0       ; nwm
szRES_TYPE_BIK          db '0x080F',0       ; bik
szRES_TYPE_NDB          db '0x0810',0       ; 'ndb'script debugger file
szRES_TYPE_PTM          db '0x0811',0       ; 'ptm',        #plot manager/plot instance
szRES_TYPE_PTT          db '0x0812',0       ; 'ptt',        #plot wizard blueprint
szRES_TYPE_NCM          db '0x0813',0       ; ncm / xsb
szRES_TYPE_XSB          db '0x0813',0       ; 
szRES_TYPE_MFX          db '0x0814',0       ; mfx / bin
szRES_TYPE_BIN          db '0x0814',0       ; 
szRES_TYPE_MAT          db '0x0815',0       ; 'mat',
szRES_TYPE_MDB          db '0x0816',0       ; 'mdb',        #not the standard MDB, multiple file formats present despite same type
szRES_TYPE_SAY          db '0x0817',0       ; 'say',
szRES_TYPE_TTF          db '0x0818',0       ; 'ttf',        #standard .ttf font files
szRES_TYPE_TTC          db '0x0819',0       ; 'ttc',
szRES_TYPE_CUT          db '0x081A',0       ; 'cut',        #cutscene? (GFF)
szRES_TYPE_KA           db '0x081B',0       ; 'ka',         #karma file (XML)
szRES_TYPE_JPG          db '0x081C',0       ; 'jpg',        #jpg image
szRES_TYPE_ICO          db '0x081D',0       ; 'ico',        #standard windows .ico files
szRES_TYPE_OGG          db '0x081E',0       ; 'ogg',        #ogg vorbis sound file
szRES_TYPE_SPT          db '0x081F',0       ; 'spt',
szRES_TYPE_SPW          db '0x0820',0       ; 'spw',
szRES_TYPE_WFX2         db '0x0821',0       ; 'wfx',        #woot effect class (XML)
szRES_TYPE_UGM          db '0x0822',0       ; 'ugm',        # 2082 ??? [textures00.bif]
szRES_TYPE_QDB          db '0x0823',0       ; 'qdb',        #quest database (GFF v3.38)
szRES_TYPE_QST          db '0x0824',0       ; 'qst',        #quest (GFF)
szRES_TYPE_NPC          db '0x0825',0       ; 'npc',
szRES_TYPE_SPN          db '0x0826',0       ; 'spn',
szRES_TYPE_UTX          db '0x0827',0       ; 'utx',        #spawn point? (GFF)
szRES_TYPE_MMD          db '0x0828',0       ; 'mmd',
szRES_TYPE_SMM          db '0x0829',0       ; 'smm',
szRES_TYPE_UTA          db '0x082A',0       ; 'uta',        #uta (GFF)
szRES_TYPE_MDE          db '0x082B',0       ; 'mde',
szRES_TYPE_MDV          db '0x082C',0       ; 'mdv',
szRES_TYPE_MDA          db '0x082D',0       ; 'mda',
szRES_TYPE_MBA          db '0x082E',0       ; 'mba',
szRES_TYPE_OCT          db '0x082F',0       ; 'oct',
szRES_TYPE_BFX          db '0x0830',0       ; 'bfx',
szRES_TYPE_PDB          db '0x0831',0       ; 'pdb',
szRES_TYPE_THEWITCHERSAVE db '0x0832',0     ; 'TheWitcherSave',
szRES_TYPE_PVS          db '0x0833',0       ; 'pvs',
szRES_TYPE_CFX          db '0x0834',0       ; 'cfx',
szRES_TYPE_LUC          db '0x0835',0       ; 'luc',        #compiled lua script
szRES_TYPE_PRB          db '0x0837',0       ; 'prb',
szRES_TYPE_CAM          db '0x0838',0       ; 'cam',
szRES_TYPE_VDS          db '0x0839',0       ; 'vds',
szRES_TYPE_BIN2         db '0x083A',0       ; 'bin',
szRES_TYPE_WOB          db '0x083B',0       ; 'wob',
szRES_TYPE_API          db '0x083C',0       ; 'api',
szRES_TYPE_PROPERTIES   db '0x083D',0       ; 'properties',
szRES_TYPE_PNG          db '0x083E',0       ; 'png',

;---------------------------------------------------------------------------------------
; 3000 - 4000 :: (0x0BB8 - 0x0FA0) SW:KOTOR resource types
;---------------------------------------------------------------------------------------
szRES_TYPE_LYT          db '0x0BB8',0       ;  3000 lyt     Layout information
szRES_TYPE_VIS          db '0x0BB9',0       ; vis
szRES_TYPE_RIM          db '0x0BBA',0       ; rim See RIM File Format
szRES_TYPE_PTH          db '0x0BBB',0       ; pth Path information? (GFF)
szRES_TYPE_LIP          db '0x0BBC',0       ; lip
szRES_TYPE_BWM          db '0x0BBD',0       ; bwm
szRES_TYPE_TXB          db '0x0BBE',0       ; txb
szRES_TYPE_TPC          db '0x0BBF',0       ; tpc / cwd
szRES_TYPE_CWD          db '0x0BBF',0       ; 
szRES_TYPE_MDX          db '0x0BC0',0       ; mdx / pro
szRES_TYPE_PRO2         db '0x0BC0',0       ; 
szRES_TYPE_RSV          db '0x0BC1',0       ; rsv / aoe
szRES_TYPE_AOE          db '0x0BC1',0       ; 
szRES_TYPE_SIG          db '0x0BC2',0       ; sig / mat
szRES_TYPE_MAT2         db '0x0BC2',0       ; 
szRES_TYPE_MAB          db '0x0BC3',0       ; 3011
szRES_TYPE_QST2         db '0x0BC4',0       ; 3012 
szRES_TYPE_STO2         db '0x0BC5',0       ; 3013 
szRES_TYPE_APL          db '0x0BC6',0       ; 3013
szRES_TYPE_HEX          db '0x0BC7',0       ; 3015 
szRES_TYPE_MDX2         db '0x0BC8',0       ; 3016 
szRES_TYPE_TXB2         db '0x0BC9',0       ; 3017 
szRES_TYPE_TPC2         db '0x0BCA',0       ; 3018
szRES_TYPE_FSM          db '0x0BCE',0       ; 3022 
szRES_TYPE_ART          db '0x0BCF',0       ; 3023 
szRES_TYPE_AMP          db '0x0BD0',0       ;  3024 amp     ??? (binary)
szRES_TYPE_CWA          db '0x0BD1',0       ;  3025 cwa     Crowd Attribute (GFF)
szRES_TYPE_XLS          db '0x0BD2',0       ;  3026 xls     MS Excel spreadsheet
szRES_TYPE_SPF          db '0x0BD3',0       ;  3027 spf     NGF: Style profiles
szRES_TYPE_BIP          db '0x0BD4',0       ; 3028 
szRES_TYPE_MDB2         db '0x0FA0',0       ; 4000
szRES_TYPE_MDA2         db '0x0FA1',0       ; 4001
szRES_TYPE_SPT2         db '0x0FA2',0       ; 4002
szRES_TYPE_GR2          db '0x0FA3',0       ; 4003
szRES_TYPE_FXA          db '0x0FA4',0       ; 4004
szRES_TYPE_FXE          db '0x0FA5',0       ; 4005
szRES_TYPE_JPG2         db '0x0FA7',0       ; 4007
szRES_TYPE_PWC          db '0x0FA8',0       ; 4008

;---------------------------------------------------------------------------------------
; 9997-9999: Common resource types 
;---------------------------------------------------------------------------------------
szRES_TYPE_BIG          db '0x270B',0       ; 'big',
szRES_TYPE_IDS2         db '0x270C',0       ; '1da',
szRES_TYPE_ERF          db '0x270D',0       ; erf Encapsulated Resource Format
szRES_TYPE_BIF          db '0x270E',0       ; bif
szRES_TYPE_KEY          db '0x270F',0       ; key

;---------------------------------------------------------------------------------------
; Found in NWN: Visual Foxpro database formats: dbf=database, cdx=index, fpt=memo
;---------------------------------------------------------------------------------------
szRES_TYPE_VFPEXE       db '0x4A38',0       ; 19000, 
szRES_TYPE_VFPDBF       db '0x4A39',0       ; 19001, 
szRES_TYPE_VFPCDX       db '0x4A3A',0       ; 19002, 
szRES_TYPE_VFPFPT       db '0x4A3B',0       ; 19003, 



;=======================================================================================
; .DATA Strings & Buffers
;=======================================================================================
szUnknownRes            db 16 dup (0)
szHex                   db '0x',0
szBackslash             db '\',0
szSpace                 db ' ',0
szLeftBracket           db '(',0
szRightBracket          db ')',0
szTimes                 db 'x',0
szUnderscore            db '_',0
szFullstop              db '.',0

.CODE

;-------------------------------------------------------------------------------------
; -1 = ask user, 0 = unknown resource, otherwise returns resource type in eax
;-------------------------------------------------------------------------------------
IERESExtToResType PROC PUBLIC USES EBX lpszFileExtension:DWORD
    LOCAL szFileExt[16]:BYTE
    mov ebx, lpszFileExtension
    movzx eax, byte ptr [ebx]
    .IF al != '.'
        Invoke szCopy, Addr szFullstop, Addr szFileExt
        Invoke szCatStr, Addr szFileExt, lpszFileExtension
    .ELSE
        Invoke szCopy, lpszFileExtension, Addr szFileExt
    .ENDIF
    Invoke szLower, Addr szFileExt
    
    lea ebx, szFileExt
    mov eax, [ebx] ; get ext as a dword to compare against
    bswap eax ; get it into reverse format to compare

;---------------------------------------------------------------------------------------
; 0 - 20 - Common files
;---------------------------------------------------------------------------------------     
;    .ELSEIF eax == 
;        mov eax, 
     
    .IF eax == dwBMPExt
        mov eax, RES_TYPE_BMP
    .ELSEIF eax == dwMVEExt
        mov eax, RES_TYPE_MVE
    .ELSEIF eax == dwTGAExt
        mov eax, RES_TYPE_TGA
    .ELSEIF eax == dwWAVExt
        mov eax, RES_TYPE_WAV
    .ELSEIF eax == dwWFXExt
        mov eax, RES_TYPE_WFX
    .ELSEIF eax == dwPLTExt
        mov eax, RES_TYPE_PLT
    .ELSEIF eax == dwINIExt     ; ?
        mov eax, RES_TYPE_INI   ; ? RES_TYPE_INI2_ ?
    .ELSEIF eax == dwMP3Ext       
        mov eax, RES_TYPE_MP3
    .ELSEIF eax == dwMPGExt
        mov eax, RES_TYPE_MPG
    .ELSEIF eax == dwTXTExt
        mov eax, RES_TYPE_TXT
    .ELSEIF eax == dwXMLExt
        mov eax, RES_TYPE_XML
    .ELSEIF eax == dwWMAExt
        mov eax, RES_TYPE_WMA
    .ELSEIF eax == dwWMVExt
        mov eax, RES_TYPE_WMV
    .ELSEIF eax == dwXMVExt
        mov eax, RES_TYPE_XMV
        
;---------------------------------------------------------------------------------------
; 1000 - 2000 :: (0x03E8 - 0x07D0) Infinity Engine resource types
;---------------------------------------------------------------------------------------
    .ELSEIF eax == dwBAMExt
        mov eax, RES_TYPE_BAM
    .ELSEIF eax == dwWEDExt
        mov eax, RES_TYPE_WED
    .ELSEIF eax == dwCHUExt
        mov eax, RES_TYPE_CHU
    .ELSEIF eax == dwTISExt
        mov eax, RES_TYPE_TIS
    .ELSEIF eax == dwMOSExt
        mov eax, RES_TYPE_MOS
    .ELSEIF eax == dwITMExt     ; ?
        mov eax, RES_TYPE_ITM   ; ? RES_TYPE_ITM2_ ?
    .ELSEIF eax == dwSPLExt
        mov eax, RES_TYPE_SPL
    .ELSEIF eax == dwBCSExt
        mov eax, RES_TYPE_BCS
    .ELSEIF eax == dwIDSExt
        mov eax, RES_TYPE_IDS
    .ELSEIF eax == dwCREExt     ; ?
        mov eax, RES_TYPE_CRE   ; ? RES_TYPE_CRE2_ ?
    .ELSEIF eax == dwAREExt 
        mov eax, RES_TYPE_ARE
    .ELSEIF eax == dwDLGExt
        mov eax, RES_TYPE_DLG   ; ? RES_TYPE_DLG2 ?
    .ELSEIF eax == dwTWODAExt
        mov eax, RES_TYPE_2DA   ; ? RES_TYPE_2DA1 RES_TYPE_2DA2 RES_TYPE_2DA3 ?
    .ELSEIF eax == dwGAMExt
        mov eax, RES_TYPE_GAM
    .ELSEIF eax == dwSTOExt
        mov eax, RES_TYPE_STO
    .ELSEIF eax == dwWMPExt
        mov eax, RES_TYPE_WMP
    .ELSEIF eax == dwCHRExt
        mov eax, RES_TYPE_CHR   ; ? RES_TYPE_CHR2
    .ELSEIF eax == dwEFFExt
        mov eax, RES_TYPE_EFF_  ; fake
    .ELSEIF eax == dwBSExt
        mov eax, RES_TYPE_BS
    .ELSEIF eax == dwVVCExt
        mov eax, RES_TYPE_VVC
    .ELSEIF eax == dwVEFExt
        mov eax, RES_TYPE_VEF
    .ELSEIF eax == dwPROExt
        mov eax, RES_TYPE_PRO
    .ELSEIF eax == dwBIOExt
        mov eax, RES_TYPE_BIO
    .ELSEIF eax == dwWBMExt
        mov eax, RES_TYPE_WBM
    .ELSEIF eax == dwFONExt
        mov eax, RES_TYPE_FON
    .ELSEIF eax == dwGUIExt
        mov eax, RES_TYPE_GUI
    .ELSEIF eax == dwSQLExt
        mov eax, RES_TYPE_SQL
    .ELSEIF eax == dwPVRExt
        mov eax, RES_TYPE_PVR
    .ELSEIF eax == dwGLSLExt
        mov eax, RES_TYPE_GLSL
    .ELSEIF eax == RES_TYPE_MENU
        mov eax, dwMENUExt
    .ELSEIF eax == RES_TYPE_LUA2
        mov eax, dwLUA2Ext
    .ELSEIF eax == RES_TYPE_TTF2
        mov eax, dwTTF2Ext
    .ELSEIF eax == RES_TYPE_PNG2
        mov eax, dwPNG2Ext
        
        
    .ELSEIF eax == dwBAHExt
        mov eax, RES_TYPE_BAH
    .ELSEIF eax == dwBAFExt
        mov eax, RES_TYPE_BAF
    .ELSEIF eax == dwSRCExt     ; ?
        mov eax, RES_TYPE_SRC   ; ?
    .ELSEIF eax == dwTOHExt   
        mov eax, RES_TYPE_TOH
    .ELSEIF eax == dwTOTExt
        mov eax, RES_TYPE_TOT
    .ELSEIF eax == dwVARExt
        mov eax, RES_TYPE_VAR
    .ELSEIF eax == dwSAVExt
        mov eax, RES_TYPE_SAV
        
;---------------------------------------------------------------------------------------
; 2000 - 3000 :: (0x07D0 - 0x0BB8) NWN resource types SWKotoR share these resource as well
;---------------------------------------------------------------------------------------
    .ELSEIF eax == dwPLHExt
        mov eax, RES_TYPE_PLH
    .ELSEIF eax == dwTEXExt
        mov eax, RES_TYPE_TEX
    .ELSEIF eax == dwMDLExt
        mov eax, RES_TYPE_MDL
    .ELSEIF eax == dwTHGExt
        mov eax, RES_TYPE_THG
    .ELSEIF eax == dwFNTExt
        mov eax, RES_TYPE_FNT
    .ELSEIF eax == dwLUAExt
        mov eax, RES_TYPE_LUA
    .ELSEIF eax == dwSLTExt
        mov eax, RES_TYPE_SLT
    .ELSEIF eax == dwNSSExt
        mov eax, RES_TYPE_NSS
    .ELSEIF eax == dwNCSExt
        mov eax, RES_TYPE_NCS
    .ELSEIF eax == dwMODExt
        mov eax, RES_TYPE_MOD
    .ELSEIF eax == dwSETExt
        mov eax, RES_TYPE_SET
    .ELSEIF eax == dwIFOExt
        mov eax, RES_TYPE_IFO
    .ELSEIF eax == dwBICExt
        mov eax, RES_TYPE_BIC
    .ELSEIF eax == dwWOKExt
        mov eax, RES_TYPE_WOK
    .ELSEIF eax == dwTXIExt
        mov eax, RES_TYPE_TXI
    .ELSEIF eax == dwGITExt
        mov eax, RES_TYPE_GIT
    .ELSEIF eax == dwBTIExt
        mov eax, RES_TYPE_BTI
    .ELSEIF eax == dwUTIExt
        mov eax, RES_TYPE_UTI
    .ELSEIF eax == dwBTCExt
        mov eax, RES_TYPE_BTC
    .ELSEIF eax == dwUTCExt
        mov eax, RES_TYPE_UTC
    .ELSEIF eax == dwITPExt
        mov eax, RES_TYPE_ITP
    .ELSEIF eax == dwPALExt
        mov eax, RES_TYPE_PAL_  ; fake
    .ELSEIF eax == dwBTTExt
        mov eax, RES_TYPE_BTT
    .ELSEIF eax == dwTRGExt
        mov eax, RES_TYPE_TRG_  ; fale
    .ELSEIF eax == dwUTTExt
        mov eax, RES_TYPE_UTT
    .ELSEIF eax == dwDDSExt
        mov eax, RES_TYPE_DDS
    .ELSEIF eax == dwBTSExt
        mov eax, RES_TYPE_BTS
    .ELSEIF eax == dwSNDExt
        mov eax, RES_TYPE_SND_  ; fale
    .ELSEIF eax == dwUTSExt
        mov eax, RES_TYPE_UTS
    .ELSEIF eax == dwLTRExt
        mov eax, RES_TYPE_LTR
    .ELSEIF eax == dwGFFExt
        mov eax, RES_TYPE_GFF
    .ELSEIF eax == dwFACExt
        mov eax, RES_TYPE_FAC
    .ELSEIF eax == dwBTEExt
        mov eax, RES_TYPE_BTE
    .ELSEIF eax == dwENCExt
        mov eax, RES_TYPE_ENC_  ; fake
    .ELSEIF eax == dwUTEExt
        mov eax, RES_TYPE_UTE
    .ELSEIF eax == dwCONExt
        mov eax, RES_TYPE_CON_  ; fake
    .ELSEIF eax == dwBTDExt
        mov eax, RES_TYPE_BTD
    .ELSEIF eax == dwDORExt
        mov eax, RES_TYPE_DOR_  ; fake
    .ELSEIF eax == dwUTDExt
        mov eax, RES_TYPE_UTD
    .ELSEIF eax == dwBTPExt
        mov eax, RES_TYPE_BTP
    .ELSEIF eax == dwPLAExt
        mov eax, RES_TYPE_PLA_  ; fake
    .ELSEIF eax == dwUTPExt
        mov eax, RES_TYPE_UTP
    .ELSEIF eax == dwDFTExt
        mov eax, RES_TYPE_DFT
    .ELSEIF eax == dwGICExt
        mov eax, RES_TYPE_GIC
    .ELSEIF eax == dwGUI2Ext   ; ?
        mov eax, RES_TYPE_GUI2 ; ?
    .ELSEIF eax == dwBTWExt
        mov eax, RES_TYPE_BTW

;---------------------------------------------------------------------------------------
; 2048 - 2110 Witcher
;---------------------------------------------------------------------------------------
    .ELSEIF eax == dwSRCExt
        mov eax, RES_TYPE_SRC
    .ELSEIF eax == dwCSSExt
        mov eax, RES_TYPE_CSS
    .ELSEIF eax == dwCCSExt
        mov eax, RES_TYPE_CCS
    .ELSEIF eax == dwBTMExt
        mov eax, RES_TYPE_BTM
    .ELSEIF eax == dwMERExt
        mov eax, RES_TYPE_BTM
    .ELSEIF eax == dwUTMExt
        mov eax, RES_TYPE_UTM
    .ELSEIF eax == dwDWKExt
        mov eax, RES_TYPE_DWK
    .ELSEIF eax == dwPWKExt
        mov eax, RES_TYPE_PWK
    .ELSEIF eax == dwBTGExt
        mov eax, RES_TYPE_BTG
    .ELSEIF eax == dwUTGExt
        mov eax, RES_TYPE_UTG
    .ELSEIF eax == dwGENExt
        mov eax, RES_TYPE_GEN_  ; fake
    .ELSEIF eax == dwJRLExt
        mov eax, RES_TYPE_JRL
    .ELSEIF eax == dwUTWExt
        mov eax, RES_TYPE_UTW
    .ELSEIF eax == dwWAYExt
        mov eax, RES_TYPE_WAY_  ; fake
    .ELSEIF eax == dwFOURPCExt
        mov eax, RES_TYPE_4PC
    .ELSEIF eax == dwSSFExt
        mov eax, RES_TYPE_SSF
    .ELSEIF eax == dwHAKExt
        mov eax, RES_TYPE_HAK
    .ELSEIF eax == dwNWMExt
        mov eax, RES_TYPE_NWM
    .ELSEIF eax == dwBIKExt
        mov eax, RES_TYPE_BIK
    .ELSEIF eax == dwNDBExt
        mov eax, RES_TYPE_NDB
    .ELSEIF eax == dwPTMExt
        mov eax, RES_TYPE_PTM
    .ELSEIF eax == dwPTTExt
        mov eax, RES_TYPE_PTT
    .ELSEIF eax == dwNCMExt
        mov eax, RES_TYPE_NCM
    .ELSEIF eax == dwXSBExt
        mov eax, RES_TYPE_XSB_  ; fake
    .ELSEIF eax == dwMFXExt
        mov eax, RES_TYPE_MFX
    .ELSEIF eax == dwBINExt
        mov eax, RES_TYPE_BIN_  ; fake
    .ELSEIF eax == dwMATExt
        mov eax, RES_TYPE_MAT
    .ELSEIF eax == dwMDBExt
        mov eax, RES_TYPE_MDB
    .ELSEIF eax == dwSAYExt
        mov eax, RES_TYPE_SAY
    .ELSEIF eax == dwTTFExt
        mov eax, RES_TYPE_TTF
    .ELSEIF eax == dwTTCExt
        mov eax, RES_TYPE_TTC
    .ELSEIF eax == dwCUTExt
        mov eax, RES_TYPE_CUT
    .ELSEIF eax == dwKAExt
        mov eax, RES_TYPE_KA
    .ELSEIF eax == dwJPGExt
        mov eax, RES_TYPE_JPG
    .ELSEIF eax == dwICOExt
        mov eax, RES_TYPE_ICO
    .ELSEIF eax == dwOGGExt
        mov eax, RES_TYPE_OGG
    .ELSEIF eax == dwSPTExt
        mov eax, RES_TYPE_SPT
    .ELSEIF eax == dwSPWExt
        mov eax, RES_TYPE_SPW
    .ELSEIF eax == dwUGMExt
        mov eax, RES_TYPE_UGM
    .ELSEIF eax == dwQDBExt
        mov eax, RES_TYPE_QDB
    .ELSEIF eax == dwQSTExt
        mov eax, RES_TYPE_QST
    .ELSEIF eax == dwNPCExt
        mov eax, RES_TYPE_NPC
    .ELSEIF eax == dwSPNExt
        mov eax, RES_TYPE_SPN
    .ELSEIF eax == dwUTXExt
        mov eax, RES_TYPE_UTX
    .ELSEIF eax == dwMMDExt
        mov eax, RES_TYPE_MMD
    .ELSEIF eax == dwSMMExt
        mov eax, RES_TYPE_SMM
    .ELSEIF eax == dwUTAExt
        mov eax, RES_TYPE_UTA
    .ELSEIF eax == dwMDEExt
        mov eax, RES_TYPE_MDE
    .ELSEIF eax == dwMDVExt
        mov eax, RES_TYPE_MDV
    .ELSEIF eax == dwMDAExt
        mov eax, RES_TYPE_MDA
    .ELSEIF eax == dwMBAExt
        mov eax, RES_TYPE_MBA
    .ELSEIF eax == dwOCTExt
        mov eax, RES_TYPE_OCT
    .ELSEIF eax == dwBFXExt
        mov eax, RES_TYPE_BFX
    .ELSEIF eax == dwPDBExt
        mov eax, RES_TYPE_PDB
    .ELSEIF eax == dwPVSExt
        mov eax, RES_TYPE_PVS
    .ELSEIF eax == dwCFXExt
        mov eax, RES_TYPE_CFX
    .ELSEIF eax == dwLUCExt
        mov eax, RES_TYPE_LUC
    .ELSEIF eax == dwPRBExt
        mov eax, RES_TYPE_PRB
    .ELSEIF eax == dwCAMExt
        mov eax, RES_TYPE_CAM
    .ELSEIF eax == dwVDSExt
        mov eax, RES_TYPE_VDS
    .ELSEIF eax == dwWOBExt
        mov eax, RES_TYPE_WOB
    .ELSEIF eax == dwAPIExt
        mov eax, RES_TYPE_API
    .ELSEIF eax == dwPNGExt
        mov eax, RES_TYPE_PNG
        
;---------------------------------------------------------------------------------------
; 3000 - 4000 :: (0x0BB8 - 0x0FA0) SW:KOTOR resource types
;---------------------------------------------------------------------------------------
    .ELSEIF eax == dwLYTExt
        mov eax, RES_TYPE_LYT
    .ELSEIF eax == dwVISExt
        mov eax, RES_TYPE_VIS
    .ELSEIF eax == dwRIMExt
        mov eax, RES_TYPE_RIM
    .ELSEIF eax == dwPTHExt
        mov eax, RES_TYPE_PTH
    .ELSEIF eax == dwLIPExt
        mov eax, RES_TYPE_LIP
    .ELSEIF eax == dwBWMExt
        mov eax, RES_TYPE_BWM
    .ELSEIF eax == dwTXBExt
        mov eax, RES_TYPE_TXB
    .ELSEIF eax == dwTPCExt
        mov eax, RES_TYPE_TPC
    .ELSEIF eax == dwCWDExt
        mov eax, RES_TYPE_CWD_  ; fake
    .ELSEIF eax == dwMDXExt
        mov eax, RES_TYPE_MDX
    .ELSEIF eax == dwRSVExt
        mov eax, RES_TYPE_RSV
    .ELSEIF eax == dwAOEExt
        mov eax, RES_TYPE_AOE_  ; fake
    .ELSEIF eax == dwSIGExt
        mov eax, RES_TYPE_SIG
    .ELSEIF eax == dwMABExt
        mov eax, RES_TYPE_MAB
    .ELSEIF eax == dwAPLExt
        mov eax, RES_TYPE_APL
    .ELSEIF eax == dwHEXExt
        mov eax, RES_TYPE_HEX
    .ELSEIF eax == dwFSMExt
        mov eax, RES_TYPE_FSM
    .ELSEIF eax == dwARTExt
        mov eax, RES_TYPE_ART
    .ELSEIF eax == dwAMPExt
        mov eax, RES_TYPE_AMP
    .ELSEIF eax == dwCWAExt
        mov eax, RES_TYPE_CWA
    .ELSEIF eax == dwXLSExt
        mov eax, RES_TYPE_XLS
    .ELSEIF eax == dwSPFExt
        mov eax, RES_TYPE_SPF
    .ELSEIF eax == dwBIPExt
        mov eax, RES_TYPE_BIP
    .ELSEIF eax == dwFXAExt
        mov eax, RES_TYPE_FXA
    .ELSEIF eax == dwFXEExt
        mov eax, RES_TYPE_FXE
    .ELSEIF eax == dwPWCExt
        mov eax, RES_TYPE_PWC

;---------------------------------------------------------------------------------------
; 9997-9999: Common resource types 
;---------------------------------------------------------------------------------------
    .ELSEIF eax == dwBIGExt
        mov eax, RES_TYPE_BIG
    .ELSEIF eax == dwERFExt
        mov eax, RES_TYPE_ERF
    .ELSEIF eax == dwBIFExt
        mov eax, RES_TYPE_BIF
    .ELSEIF eax == dwKEYExt
        mov eax, RES_TYPE_KEY

;---------------------------------------------------------------------------------------
; Found in NWN: Visual Foxpro database formats: dbf=database, cdx=index, fpt=memo
;---------------------------------------------------------------------------------------
    .ELSEIF eax == dwVFPEXEExt
        mov eax, RES_TYPE_VFPEXE
    .ELSEIF eax == dwVFPDBFExt
        mov eax, RES_TYPE_VFPDBF
    .ELSEIF eax == dwVFPCDXExt
        mov eax, RES_TYPE_VFPCDX
    .ELSEIF eax == dwVFPFPTExt
        mov eax, RES_TYPE_VFPFPT
 

    .ELSE
        mov eax, RES_TYPE_UNKNOWN
    .ENDIF


     
    
    ret

IERESExtToResType endp


;-------------------------------------------------------------------------------------

;-------------------------------------------------------------------------------------
IERESResIndexToString PROC PUBLIC USES EBX dwResourceIndex:DWORD, lpszResourceIndex:DWORD
;    LOCAL lpdwString:DWORD
    
;    .IF dwResourceIndex >= 0 && dwResourceIndex <= 100
;        lea ebx, ResIndexStrings100
;        mov eax, dwResourceIndex
;        lea eax, [ebx+eax*4]
;        mov lpdwString, eax
;        Invoke RtlMoveMemory, lpszResourceIndex, lpdwString, 4
;    .ELSE
        Invoke RESutoa_ex, dwResourceIndex, lpszResourceIndex
;    .ENDIF
    ret

IERESResIndexToString endp


;-------------------------------------------------------------------------------------

;-------------------------------------------------------------------------------------
IERESResOffsetToString PROC PUBLIC dwResourceOffset:DWORD, lpszResourceOffset:DWORD
    
    Invoke RESutoa_ex, dwResourceOffset, lpszResourceOffset
    ret

IERESResOffsetToString endp


;-------------------------------------------------------------------------------------
; converts size to a string, if tilescount > 0 then size is calc'd as size x count and string is returned with 'size (tile size x tile count)'
;-------------------------------------------------------------------------------------
IERESResSizeToString PROC PUBLIC USES EBX dwResourceSize:DWORD, dwTilesCount:DWORD, lpszResourceSize:DWORD
    LOCAL dwSize:DWORD
    LOCAL szTileSize[12]:BYTE
    LOCAL szTilesCount[12]:BYTE
    
    .IF dwTilesCount > 0
        mov eax, dwResourceSize
        mov ebx, dwTilesCount
        mul ebx
    .ELSE
        mov eax, dwResourceSize
    .ENDIF
    mov dwSize, eax
    
    Invoke RESutoa_ex, dwSize, lpszResourceSize
    
    .IF dwTilesCount > 0
        Invoke RESutoa_ex, dwResourceSize, Addr szTileSize
        Invoke RESutoa_ex, dwTilesCount, Addr szTilesCount
        Invoke szCatStr, lpszResourceSize, Addr szSpace
        Invoke szCatStr, lpszResourceSize, Addr szLeftBracket
        Invoke szCatStr, lpszResourceSize, Addr szTilesCount
        Invoke szCatStr, lpszResourceSize, Addr szTimes
        Invoke szCatStr, lpszResourceSize, Addr szTileSize
        Invoke szCatStr, lpszResourceSize, Addr szRightBracket
    .ENDIF
    ret

IERESResSizeToString endp


;-------------------------------------------------------------------------------------
; IERESResNameTypeToString - converts resref (8 bytes) with resource type to a 8.3 resource name string
;-------------------------------------------------------------------------------------
IERESResNameTypeToString PROC PUBLIC lpszResName:DWORD, dwResType:DWORD, lpszResourceNameString:DWORD
    
    Invoke szCopy, lpszResName, lpszResourceNameString 
    
    mov eax, dwResType
;---------------------------------------------------------------------------------------
; 0 - 20 - Common files
;---------------------------------------------------------------------------------------        
    .IF eax == RES_TYPE_BMP
        Invoke szCatStr, lpszResourceNameString, Addr BMPExt
    .ELSEIF eax == RES_TYPE_MVE
        Invoke szCatStr, lpszResourceNameString, Addr MVEExt
    .ELSEIF eax == RES_TYPE_TGA
        Invoke szCatStr, lpszResourceNameString, Addr TGAExt
    .ELSEIF eax == RES_TYPE_WAV
        Invoke szCatStr, lpszResourceNameString, Addr WAVExt
    .ELSEIF eax == RES_TYPE_WFX
        Invoke szCatStr, lpszResourceNameString, Addr WFXExt
    .ELSEIF eax == RES_TYPE_PLT
        Invoke szCatStr, lpszResourceNameString, Addr PLTExt
    .ELSEIF eax == RES_TYPE_INI
        Invoke szCatStr, lpszResourceNameString, Addr INIExt
    .ELSEIF eax == RES_TYPE_MP3
        Invoke szCatStr, lpszResourceNameString, Addr MP3Ext
    .ELSEIF eax == RES_TYPE_MPG
        Invoke szCatStr, lpszResourceNameString, Addr MPGExt
    .ELSEIF eax == RES_TYPE_TXT
        Invoke szCatStr, lpszResourceNameString, Addr TXTExt
    .ELSEIF eax == RES_TYPE_WMA
        Invoke szCatStr, lpszResourceNameString, Addr WMAExt
    .ELSEIF eax == RES_TYPE_WMV
        Invoke szCatStr, lpszResourceNameString, Addr WMVExt
    .ELSEIF eax == RES_TYPE_XMV
        Invoke szCatStr, lpszResourceNameString, Addr XMVExt
    .ELSEIF eax == RES_TYPE_XML
        Invoke szCatStr, lpszResourceNameString, Addr XMLExt
    .ELSEIF eax == RES_TYPE_2DA3
        Invoke szCatStr, lpszResourceNameString, Addr TWODA3Ext
        
;---------------------------------------------------------------------------------------
; 1000 - 2000 :: (0x03E8 - 0x07D0) Infinity Engine resource types
;---------------------------------------------------------------------------------------        
    .ELSEIF eax == RES_TYPE_BAM
        Invoke szCatStr, lpszResourceNameString, Addr BAMExt
    .ELSEIF eax == RES_TYPE_WED
        Invoke szCatStr, lpszResourceNameString, Addr WEDExt
    .ELSEIF eax == RES_TYPE_CHU
        Invoke szCatStr, lpszResourceNameString, Addr CHUExt
    .ELSEIF eax == RES_TYPE_TIS
        Invoke szCatStr, lpszResourceNameString, Addr TISExt
    .ELSEIF eax == RES_TYPE_MOS
        Invoke szCatStr, lpszResourceNameString, Addr MOSExt
    .ELSEIF eax == RES_TYPE_ITM
        Invoke szCatStr, lpszResourceNameString, Addr ITMExt
    .ELSEIF eax == RES_TYPE_SPL
        Invoke szCatStr, lpszResourceNameString, Addr SPLExt
    .ELSEIF eax == RES_TYPE_BCS
        Invoke szCatStr, lpszResourceNameString, Addr BCSExt
    .ELSEIF eax == RES_TYPE_IDS
        Invoke szCatStr, lpszResourceNameString, Addr IDSExt
    .ELSEIF eax == RES_TYPE_CRE
        Invoke szCatStr, lpszResourceNameString, Addr CREExt
    .ELSEIF eax == RES_TYPE_ARE
        Invoke szCatStr, lpszResourceNameString, Addr AREExt
    .ELSEIF eax == RES_TYPE_DLG
        Invoke szCatStr, lpszResourceNameString, Addr DLGExt
    .ELSEIF eax == RES_TYPE_2DA
        Invoke szCatStr, lpszResourceNameString, Addr TWODAExt
    .ELSEIF eax == RES_TYPE_GAM
        Invoke szCatStr, lpszResourceNameString, Addr GAMExt
    .ELSEIF eax == RES_TYPE_STO
        Invoke szCatStr, lpszResourceNameString, Addr STOExt
    .ELSEIF eax == RES_TYPE_WMP
        Invoke szCatStr, lpszResourceNameString, Addr WMPExt
    .ELSEIF eax == RES_TYPE_CHR 
        Invoke szCatStr, lpszResourceNameString, Addr CHRExt
    .ELSEIF eax == RES_TYPE_EFF_ ; check file header to see which we have before hand
        Invoke szCatStr, lpszResourceNameString, Addr EFFExt
    .ELSEIF eax == RES_TYPE_BS
        Invoke szCatStr, lpszResourceNameString, Addr BSExt
    .ELSEIF eax == RES_TYPE_CHR2
        Invoke szCatStr, lpszResourceNameString, Addr CHRExt
    .ELSEIF eax == RES_TYPE_VVC
        Invoke szCatStr, lpszResourceNameString, Addr VVCExt
    .ELSEIF eax == RES_TYPE_VEF
        Invoke szCatStr, lpszResourceNameString, Addr VEFExt
    .ELSEIF eax == RES_TYPE_PRO
        Invoke szCatStr, lpszResourceNameString, Addr PROExt
    .ELSEIF eax == RES_TYPE_BIO
        Invoke szCatStr, lpszResourceNameString, Addr BIOExt
    .ELSEIF eax == RES_TYPE_FON
        Invoke szCatStr, lpszResourceNameString, Addr FONExt
    .ELSEIF eax == RES_TYPE_WBM
        Invoke szCatStr, lpszResourceNameString, Addr WBMExt
    .ELSEIF eax == RES_TYPE_GUI
        Invoke szCatStr, lpszResourceNameString, Addr GUIExt
    .ELSEIF eax == RES_TYPE_SQL
        Invoke szCatStr, lpszResourceNameString, Addr SQLExt
    .ELSEIF eax == RES_TYPE_PVR
        Invoke szCatStr, lpszResourceNameString, Addr PVRExt
    .ELSEIF eax == RES_TYPE_GLSL
        Invoke szCatStr, lpszResourceNameString, Addr GLSLExt
    .ELSEIF eax == RES_TYPE_MENU
        Invoke szCatStr, lpszResourceNameString, Addr MENUExt
    .ELSEIF eax == RES_TYPE_LUA2
        Invoke szCatStr, lpszResourceNameString, Addr LUA2Ext
    .ELSEIF eax == RES_TYPE_TTF2
        Invoke szCatStr, lpszResourceNameString, Addr TTF2Ext
    .ELSEIF eax == RES_TYPE_PNG2
        Invoke szCatStr, lpszResourceNameString, Addr PNG2Ext
    .ELSEIF eax == RES_TYPE_BAH
        Invoke szCatStr, lpszResourceNameString, Addr BAHExt
        
;---------------------------------------------------------------------------------------
; 2000 - 3000 :: (0x07D0 - 0x0BB8) NWN resource types
;---------------------------------------------------------------------------------------     
    .ELSEIF eax == RES_TYPE_PLH
        Invoke szCatStr, lpszResourceNameString, Addr PLHExt
    .ELSEIF eax == RES_TYPE_TEX
        Invoke szCatStr, lpszResourceNameString, Addr TEXExt
    .ELSEIF eax == RES_TYPE_MDL
        Invoke szCatStr, lpszResourceNameString, Addr MDLExt
    .ELSEIF eax == RES_TYPE_THG
        Invoke szCatStr, lpszResourceNameString, Addr THGExt
    .ELSEIF eax == RES_TYPE_FNT
        Invoke szCatStr, lpszResourceNameString, Addr FNTExt
    .ELSEIF eax == RES_TYPE_LUA
        Invoke szCatStr, lpszResourceNameString, Addr LUAExt
    .ELSEIF eax == RES_TYPE_SLT
        Invoke szCatStr, lpszResourceNameString, Addr SLTExt
    .ELSEIF eax == RES_TYPE_NSS
        Invoke szCatStr, lpszResourceNameString, Addr NSSExt
    .ELSEIF eax == RES_TYPE_NCS
        Invoke szCatStr, lpszResourceNameString, Addr NCSExt
    .ELSEIF eax == RES_TYPE_MOD
        Invoke szCatStr, lpszResourceNameString, Addr MODExt
    .ELSEIF eax == RES_TYPE_ARE2
        Invoke szCatStr, lpszResourceNameString, Addr ARE2Ext
    .ELSEIF eax == RES_TYPE_SET
        Invoke szCatStr, lpszResourceNameString, Addr SETExt
    .ELSEIF eax == RES_TYPE_IFO
        Invoke szCatStr, lpszResourceNameString, Addr IFOExt
    .ELSEIF eax == RES_TYPE_BIC
        Invoke szCatStr, lpszResourceNameString, Addr BICExt
    .ELSEIF eax == RES_TYPE_WOK
        Invoke szCatStr, lpszResourceNameString, Addr WOKExt
    .ELSEIF eax == RES_TYPE_2DA2
        Invoke szCatStr, lpszResourceNameString, Addr TWODA2Ext
    .ELSEIF eax == RES_TYPE_TLK
        Invoke szCatStr, lpszResourceNameString, Addr TLKExt
    .ELSEIF eax == RES_TYPE_TXI
        Invoke szCatStr, lpszResourceNameString, Addr TXIExt
    .ELSEIF eax == RES_TYPE_GIT
        Invoke szCatStr, lpszResourceNameString, Addr GITExt
    .ELSEIF eax == RES_TYPE_BTI
        Invoke szCatStr, lpszResourceNameString, Addr BTIExt
    .ELSEIF eax == RES_TYPE_ITM2_ ; check file header to see which we have before hand
        Invoke szCatStr, lpszResourceNameString, Addr ITMExt        
        
    .ELSEIF eax == RES_TYPE_UTI
        Invoke szCatStr, lpszResourceNameString, Addr UTIExt
    .ELSEIF eax == RES_TYPE_BTC
        Invoke szCatStr, lpszResourceNameString, Addr BTCExt
    .ELSEIF eax == RES_TYPE_CRE2_ ; check file header to see which we have before hand
        Invoke szCatStr, lpszResourceNameString, Addr CREExt        
        
    .ELSEIF eax == RES_TYPE_UTC
        Invoke szCatStr, lpszResourceNameString, Addr UTCExt
    .ELSEIF eax == RES_TYPE_DLG2
        Invoke szCatStr, lpszResourceNameString, Addr DLG2Ext
    .ELSEIF eax == RES_TYPE_ITP
        Invoke szCatStr, lpszResourceNameString, Addr ITPExt
    .ELSEIF eax == RES_TYPE_PAL_ ; check file header to see which we have before hand
        Invoke szCatStr, lpszResourceNameString, Addr PALExt        
        
    .ELSEIF eax == RES_TYPE_BTT
        Invoke szCatStr, lpszResourceNameString, Addr BTTExt
    .ELSEIF eax == RES_TYPE_TRG_ ; check file header to see which we have before hand
        Invoke szCatStr, lpszResourceNameString, Addr TRGExt        
        
        
    .ELSEIF eax == RES_TYPE_UTT
        Invoke szCatStr, lpszResourceNameString, Addr UTTExt
    .ELSEIF eax == RES_TYPE_DDS
        Invoke szCatStr, lpszResourceNameString, Addr DDSExt
    .ELSEIF eax == RES_TYPE_BTS
        Invoke szCatStr, lpszResourceNameString, Addr BTSExt
    .ELSEIF eax == RES_TYPE_SND_ ; check file header to see which we have before hand
        Invoke szCatStr, lpszResourceNameString, Addr SNDExt        
        
    .ELSEIF eax == RES_TYPE_UTS
        Invoke szCatStr, lpszResourceNameString, Addr UTSExt
    .ELSEIF eax == RES_TYPE_LTR
        Invoke szCatStr, lpszResourceNameString, Addr LTRExt
    .ELSEIF eax == RES_TYPE_GFF
        Invoke szCatStr, lpszResourceNameString, Addr GFFExt
    .ELSEIF eax == RES_TYPE_FAC
        Invoke szCatStr, lpszResourceNameString, Addr FACExt
    .ELSEIF eax == RES_TYPE_BTE
        Invoke szCatStr, lpszResourceNameString, Addr BTEExt
    .ELSEIF eax == RES_TYPE_ENC_ ; check file header to see which we have before hand
        Invoke szCatStr, lpszResourceNameString, Addr ENCExt        
        
    .ELSEIF eax == RES_TYPE_UTE
        Invoke szCatStr, lpszResourceNameString, Addr UTEExt
    .ELSEIF eax == RES_TYPE_CON_ ; check file header to see which we have before hand
        Invoke szCatStr, lpszResourceNameString, Addr CONExt        
        
    .ELSEIF eax == RES_TYPE_BTD
        Invoke szCatStr, lpszResourceNameString, Addr BTDExt
    .ELSEIF eax == RES_TYPE_DOR_ ; check file header to see which we have before hand
        Invoke szCatStr, lpszResourceNameString, Addr DORExt        
        
    .ELSEIF eax == RES_TYPE_UTD
        Invoke szCatStr, lpszResourceNameString, Addr UTDExt
    .ELSEIF eax == RES_TYPE_BTP
        Invoke szCatStr, lpszResourceNameString, Addr BTPExt
    .ELSEIF eax == RES_TYPE_PLA_ ; check file header to see which we have before hand
        Invoke szCatStr, lpszResourceNameString, Addr PLAExt        
        
    .ELSEIF eax == RES_TYPE_UTP
        Invoke szCatStr, lpszResourceNameString, Addr UTPExt
    .ELSEIF eax == RES_TYPE_DFT
        Invoke szCatStr, lpszResourceNameString, Addr DFTExt
    .ELSEIF eax == RES_TYPE_GIC
        Invoke szCatStr, lpszResourceNameString, Addr GICExt
    .ELSEIF eax == RES_TYPE_GUI2
        Invoke szCatStr, lpszResourceNameString, Addr GUI2Ext
        
;---------------------------------------------------------------------------------------
; 2048 - 2110 Witcher
;---------------------------------------------------------------------------------------              
    .ELSEIF eax == RES_TYPE_CSS
        Invoke szCatStr, lpszResourceNameString, Addr CSSExt
    .ELSEIF eax == RES_TYPE_CCS
        Invoke szCatStr, lpszResourceNameString, Addr CCSExt
    .ELSEIF eax == RES_TYPE_BTM
        Invoke szCatStr, lpszResourceNameString, Addr BTMExt
    .ELSEIF eax == RES_TYPE_INI2_ ; check file header to see which we have before hand
        Invoke szCatStr, lpszResourceNameString, Addr INIExt        
        
    .ELSEIF eax == RES_TYPE_UTM
        Invoke szCatStr, lpszResourceNameString, Addr UTMExt
;    .ELSEIF eax == RES_TYPE_INI2
;        Invoke szCatStr, lpszResourceNameString, Addr INIExt
;    .ELSEIF eax == RES_TYPE_SRC
;        Invoke szCatStr, lpszResourceNameString, Addr SRCExt
    .ELSEIF eax == RES_TYPE_DWK
        Invoke szCatStr, lpszResourceNameString, Addr DWKExt
    .ELSEIF eax == RES_TYPE_PWK
        Invoke szCatStr, lpszResourceNameString, Addr PWKExt
    .ELSEIF eax == RES_TYPE_BTG
        Invoke szCatStr, lpszResourceNameString, Addr BTGExt
    .ELSEIF eax == RES_TYPE_UTG
        Invoke szCatStr, lpszResourceNameString, Addr UTGExt
    .ELSEIF eax == RES_TYPE_GEN_ ; check file header to see which we have before hand
        Invoke szCatStr, lpszResourceNameString, Addr GENExt        
        
    .ELSEIF eax == RES_TYPE_JRL
        Invoke szCatStr, lpszResourceNameString, Addr JRLExt
    .ELSEIF eax == RES_TYPE_SAV2
        Invoke szCatStr, lpszResourceNameString, Addr SAV2Ext
    .ELSEIF eax == RES_TYPE_UTW
        Invoke szCatStr, lpszResourceNameString, Addr UTWExt
    .ELSEIF eax == RES_TYPE_WAY_ ; check file header to see which we have before hand
        Invoke szCatStr, lpszResourceNameString, Addr WAYExt        
        
    .ELSEIF eax == RES_TYPE_4PC
        Invoke szCatStr, lpszResourceNameString, Addr FOURPCExt
    .ELSEIF eax == RES_TYPE_SSF
        Invoke szCatStr, lpszResourceNameString, Addr SSFExt
    .ELSEIF eax == RES_TYPE_HAK
        Invoke szCatStr, lpszResourceNameString, Addr HAKExt
    .ELSEIF eax == RES_TYPE_NWM
        Invoke szCatStr, lpszResourceNameString, Addr NWMExt
    .ELSEIF eax == RES_TYPE_BIK
        Invoke szCatStr, lpszResourceNameString, Addr BIKExt
    .ELSEIF eax == RES_TYPE_NDB
        Invoke szCatStr, lpszResourceNameString, Addr NDBExt
    .ELSEIF eax == RES_TYPE_PTM
        Invoke szCatStr, lpszResourceNameString, Addr PTMExt
    .ELSEIF eax == RES_TYPE_PTT
        Invoke szCatStr, lpszResourceNameString, Addr PTTExt
    .ELSEIF eax == RES_TYPE_NCM
        Invoke szCatStr, lpszResourceNameString, Addr NCMExt
    .ELSEIF eax == RES_TYPE_XSB_ ; check file header to see which we have before hand
        Invoke szCatStr, lpszResourceNameString, Addr XSBExt        
        
    .ELSEIF eax == RES_TYPE_MFX
        Invoke szCatStr, lpszResourceNameString, Addr MFXExt
    .ELSEIF eax == RES_TYPE_BIN_ ; check file header to see which we have before hand
        Invoke szCatStr, lpszResourceNameString, Addr BINExt        
        
    .ELSEIF eax == RES_TYPE_MAT
        Invoke szCatStr, lpszResourceNameString, Addr MATExt
    .ELSEIF eax == RES_TYPE_MDB
        Invoke szCatStr, lpszResourceNameString, Addr MDBExt
    .ELSEIF eax == RES_TYPE_SAY
        Invoke szCatStr, lpszResourceNameString, Addr SAYExt
    .ELSEIF eax == RES_TYPE_TTF
        Invoke szCatStr, lpszResourceNameString, Addr TTFExt
    .ELSEIF eax == RES_TYPE_TTC
        Invoke szCatStr, lpszResourceNameString, Addr TTCExt
    .ELSEIF eax == RES_TYPE_CUT
        Invoke szCatStr, lpszResourceNameString, Addr CUTExt
    .ELSEIF eax == RES_TYPE_KA
        Invoke szCatStr, lpszResourceNameString, Addr KAExt
    .ELSEIF eax == RES_TYPE_JPG
        Invoke szCatStr, lpszResourceNameString, Addr JPGExt
    .ELSEIF eax == RES_TYPE_ICO
        Invoke szCatStr, lpszResourceNameString, Addr ICOExt
    .ELSEIF eax == RES_TYPE_OGG
        Invoke szCatStr, lpszResourceNameString, Addr OGGExt
    .ELSEIF eax == RES_TYPE_SPT
        Invoke szCatStr, lpszResourceNameString, Addr SPTExt
    .ELSEIF eax == RES_TYPE_SPW
        Invoke szCatStr, lpszResourceNameString, Addr SPWExt
    .ELSEIF eax == RES_TYPE_WFX2
        Invoke szCatStr, lpszResourceNameString, Addr WFX2Ext
    .ELSEIF eax == RES_TYPE_UGM
        Invoke szCatStr, lpszResourceNameString, Addr UGMExt
    .ELSEIF eax == RES_TYPE_QDB
        Invoke szCatStr, lpszResourceNameString, Addr QDBExt
    .ELSEIF eax == RES_TYPE_QST
        Invoke szCatStr, lpszResourceNameString, Addr QSTExt
    .ELSEIF eax == RES_TYPE_NPC
        Invoke szCatStr, lpszResourceNameString, Addr NPCExt
    .ELSEIF eax == RES_TYPE_SPN
        Invoke szCatStr, lpszResourceNameString, Addr SPNExt
    .ELSEIF eax == RES_TYPE_UTX
        Invoke szCatStr, lpszResourceNameString, Addr UTXExt
    .ELSEIF eax == RES_TYPE_MMD
        Invoke szCatStr, lpszResourceNameString, Addr MMDExt
    .ELSEIF eax == RES_TYPE_UTA
        Invoke szCatStr, lpszResourceNameString, Addr UTAExt        
    .ELSEIF eax == RES_TYPE_SMM
        Invoke szCatStr, lpszResourceNameString, Addr SMMExt
    .ELSEIF eax == RES_TYPE_MDE
        Invoke szCatStr, lpszResourceNameString, Addr MDEExt
    .ELSEIF eax == RES_TYPE_MDV
        Invoke szCatStr, lpszResourceNameString, Addr MDVExt
    .ELSEIF eax == RES_TYPE_MDA
        Invoke szCatStr, lpszResourceNameString, Addr MDAExt
    .ELSEIF eax == RES_TYPE_MBA
        Invoke szCatStr, lpszResourceNameString, Addr MBAExt
    .ELSEIF eax == RES_TYPE_OCT
        Invoke szCatStr, lpszResourceNameString, Addr OCTExt
    .ELSEIF eax == RES_TYPE_BFX
        Invoke szCatStr, lpszResourceNameString, Addr BFXExt
    .ELSEIF eax == RES_TYPE_PDB
        Invoke szCatStr, lpszResourceNameString, Addr PDBExt
    .ELSEIF eax == RES_TYPE_THEWITCHERSAVE
        Invoke szCatStr, lpszResourceNameString, Addr THEWITCHERSAVEExt
    .ELSEIF eax == RES_TYPE_PVS
        Invoke szCatStr, lpszResourceNameString, Addr PVSExt
    .ELSEIF eax == RES_TYPE_CFX
        Invoke szCatStr, lpszResourceNameString, Addr CFXExt
    .ELSEIF eax == RES_TYPE_LUC
        Invoke szCatStr, lpszResourceNameString, Addr LUCExt
    .ELSEIF eax == RES_TYPE_PRB
        Invoke szCatStr, lpszResourceNameString, Addr PRBExt
    .ELSEIF eax == RES_TYPE_CAM
        Invoke szCatStr, lpszResourceNameString, Addr CAMExt
    .ELSEIF eax == RES_TYPE_VDS
        Invoke szCatStr, lpszResourceNameString, Addr VDSExt
    .ELSEIF eax == RES_TYPE_BIN2
        Invoke szCatStr, lpszResourceNameString, Addr BINExt
    .ELSEIF eax == RES_TYPE_WOB
        Invoke szCatStr, lpszResourceNameString, Addr WOBExt
    .ELSEIF eax == RES_TYPE_API
        Invoke szCatStr, lpszResourceNameString, Addr APIExt
    .ELSEIF eax == RES_TYPE_PROPERTIES
        Invoke szCatStr, lpszResourceNameString, Addr PROPERTIESExt
    .ELSEIF eax == RES_TYPE_PNG
        Invoke szCatStr, lpszResourceNameString, Addr PNGExt

;---------------------------------------------------------------------------------------
; 3000 - 4000 :: (0x0BB8 - 0x0FA0) SW:KOTOR resource types
;---------------------------------------------------------------------------------------
    .ELSEIF eax == RES_TYPE_LYT
        Invoke szCatStr, lpszResourceNameString, Addr LYTExt
    .ELSEIF eax == RES_TYPE_VIS
        Invoke szCatStr, lpszResourceNameString, Addr VISExt
    .ELSEIF eax == RES_TYPE_RIM
        Invoke szCatStr, lpszResourceNameString, Addr RIMExt
    .ELSEIF eax == RES_TYPE_PTH
        Invoke szCatStr, lpszResourceNameString, Addr PTHExt
    .ELSEIF eax == RES_TYPE_LIP
        Invoke szCatStr, lpszResourceNameString, Addr LIPExt
    .ELSEIF eax == RES_TYPE_BWM
        Invoke szCatStr, lpszResourceNameString, Addr BWMExt
    .ELSEIF eax == RES_TYPE_TXB
        Invoke szCatStr, lpszResourceNameString, Addr TXBExt
    .ELSEIF eax == RES_TYPE_TPC
        Invoke szCatStr, lpszResourceNameString, Addr TPCExt
    .ELSEIF eax == RES_TYPE_CWD_ ; check file header to see which we have before hand
        Invoke szCatStr, lpszResourceNameString, Addr CWDExt        
        
    .ELSEIF eax == RES_TYPE_MDX
        Invoke szCatStr, lpszResourceNameString, Addr MDXExt
    .ELSEIF eax == RES_TYPE_PRO2_ ; check file header to see which we have before hand
        Invoke szCatStr, lpszResourceNameString, Addr PROExt        
        
    .ELSEIF eax == RES_TYPE_RSV
        Invoke szCatStr, lpszResourceNameString, Addr RSVExt
    .ELSEIF eax == RES_TYPE_AOE_ ; check file header to see which we have before hand
        Invoke szCatStr, lpszResourceNameString, Addr AOEExt        
        
    .ELSEIF eax == RES_TYPE_SIG
        Invoke szCatStr, lpszResourceNameString, Addr SIGExt
    .ELSEIF eax == RES_TYPE_MAT2_ ; check file header to see which we have before hand
        Invoke szCatStr, lpszResourceNameString, Addr MATExt        
        
    .ELSEIF eax == RES_TYPE_MAB
        Invoke szCatStr, lpszResourceNameString, Addr MABExt
    .ELSEIF eax == RES_TYPE_QST2
        Invoke szCatStr, lpszResourceNameString, Addr QST2Ext
    .ELSEIF eax == RES_TYPE_STO2
        Invoke szCatStr, lpszResourceNameString, Addr STO2Ext
    .ELSEIF eax == RES_TYPE_HEX
        Invoke szCatStr, lpszResourceNameString, Addr HEXExt
    .ELSEIF eax == RES_TYPE_MDX2
        Invoke szCatStr, lpszResourceNameString, Addr MDX2Ext
    .ELSEIF eax == RES_TYPE_TXB2
        Invoke szCatStr, lpszResourceNameString, Addr TXB2Ext
    .ELSEIF eax == RES_TYPE_FSM
        Invoke szCatStr, lpszResourceNameString, Addr FSMExt
    .ELSEIF eax == RES_TYPE_ART
        Invoke szCatStr, lpszResourceNameString, Addr ARTExt
    .ELSEIF eax == RES_TYPE_AMP
        Invoke szCatStr, lpszResourceNameString, Addr AMPExt
    .ELSEIF eax == RES_TYPE_CWA
        Invoke szCatStr, lpszResourceNameString, Addr CWAExt
    .ELSEIF eax == RES_TYPE_XLS
        Invoke szCatStr, lpszResourceNameString, Addr XLSExt
    .ELSEIF eax == RES_TYPE_SPF
        Invoke szCatStr, lpszResourceNameString, Addr SPFExt
    .ELSEIF eax == RES_TYPE_BIP
        Invoke szCatStr, lpszResourceNameString, Addr BIPExt
    .ELSEIF eax == RES_TYPE_MDB2
        Invoke szCatStr, lpszResourceNameString, Addr MDB2Ext
    .ELSEIF eax == RES_TYPE_MDA2
        Invoke szCatStr, lpszResourceNameString, Addr MDA2Ext
    .ELSEIF eax == RES_TYPE_SPT2
        Invoke szCatStr, lpszResourceNameString, Addr SPT2Ext
    .ELSEIF eax == RES_TYPE_GR2
        Invoke szCatStr, lpszResourceNameString, Addr GR2Ext
    .ELSEIF eax == RES_TYPE_FXA
        Invoke szCatStr, lpszResourceNameString, Addr FXAExt
    .ELSEIF eax == RES_TYPE_FXE
        Invoke szCatStr, lpszResourceNameString, Addr FXEExt
    .ELSEIF eax == RES_TYPE_JPG2
        Invoke szCatStr, lpszResourceNameString, Addr JPG2Ext
    .ELSEIF eax == RES_TYPE_PWC
        Invoke szCatStr, lpszResourceNameString, Addr PWCExt

;---------------------------------------------------------------------------------------
; 9997-9999: Common resource types 
;---------------------------------------------------------------------------------------     
    .ELSEIF eax == RES_TYPE_BIG
        Invoke szCatStr, lpszResourceNameString, Addr BIGExt
    .ELSEIF eax == RES_TYPE_ERF
        Invoke szCatStr, lpszResourceNameString, Addr ERFExt
    .ELSEIF eax == RES_TYPE_BIF
        Invoke szCatStr, lpszResourceNameString, Addr BIFExt
    .ELSEIF eax == RES_TYPE_KEY
        Invoke szCatStr, lpszResourceNameString, Addr KEYExt

;---------------------------------------------------------------------------------------
; Found in NWN: Visual Foxpro database formats: dbf=database, cdx=index, fpt=memo
;---------------------------------------------------------------------------------------
    .ELSEIF eax == RES_TYPE_VFPEXE
        Invoke szCatStr, lpszResourceNameString, Addr VFPEXEExt
    .ELSEIF eax == RES_TYPE_VFPDBF
        Invoke szCatStr, lpszResourceNameString, Addr VFPDBFExt
    .ELSEIF eax == RES_TYPE_VFPCDX
        Invoke szCatStr, lpszResourceNameString, Addr VFPCDXExt
    .ELSEIF eax == RES_TYPE_VFPFPT
        Invoke szCatStr, lpszResourceNameString, Addr VFPFPTExt
    
    .ELSE
        mov eax, RES_TYPE_UNKNOWN
    
    .ENDIF

    ret
IERESResNameTypeToString ENDP


;-------------------------------------------------------------------------------------
; IERESResTypeToString - returns in eax pointer to zero terminated string contained file extension for resource type specified
;-------------------------------------------------------------------------------------
IERESResTypeToString PROC PUBLIC dwResType:DWORD
    LOCAL szResUnknown[12]:BYTE
    mov eax, dwResType
;---------------------------------------------------------------------------------------
; 0 - 20 - Common files
;---------------------------------------------------------------------------------------    
    .IF eax == 0
        lea eax, szRES_TYPE_NONE
    .ELSEIF eax == RES_TYPE_BMP
        lea eax, szRES_TYPE_BMP
    .ELSEIF eax == RES_TYPE_MVE
        lea eax, szRES_TYPE_MVE
    .ELSEIF eax == RES_TYPE_TGA
        lea eax, szRES_TYPE_TGA
    .ELSEIF eax == RES_TYPE_WAV
        lea eax, szRES_TYPE_WAV
    .ELSEIF eax == RES_TYPE_WFX
        lea eax, szRES_TYPE_WFX
    .ELSEIF eax == RES_TYPE_PLT
        lea eax, szRES_TYPE_PLT
    .ELSEIF eax == RES_TYPE_INI
        lea eax, szRES_TYPE_INI
    .ELSEIF eax == RES_TYPE_MP3
        lea eax, szRES_TYPE_MP3
    .ELSEIF eax == RES_TYPE_MPG
        lea eax, szRES_TYPE_MPG
    .ELSEIF eax == RES_TYPE_TXT
        lea eax, szRES_TYPE_TXT
    .ELSEIF eax == RES_TYPE_WMA
        lea eax, szRES_TYPE_WMA
    .ELSEIF eax == RES_TYPE_WMV
        lea eax, szRES_TYPE_WMV
    .ELSEIF eax == RES_TYPE_XMV
        lea eax, szRES_TYPE_XMV
    .ELSEIF eax == RES_TYPE_2DA3
        lea eax, szRES_TYPE_2DA3
        
;---------------------------------------------------------------------------------------
; 1000 - 2000 :: (0x03E8 - 0x07D0) Infinity Engine resource types
;---------------------------------------------------------------------------------------
    .ELSEIF eax == RES_TYPE_BAM
        lea eax, szRES_TYPE_BAM
    .ELSEIF eax == RES_TYPE_WED
        lea eax, szRES_TYPE_WED
    .ELSEIF eax == RES_TYPE_CHU
        lea eax, szRES_TYPE_CHU
    .ELSEIF eax == RES_TYPE_TIS
        lea eax, szRES_TYPE_TIS
    .ELSEIF eax == RES_TYPE_MOS
        lea eax, szRES_TYPE_MOS
    .ELSEIF eax == RES_TYPE_ITM
        lea eax, szRES_TYPE_ITM
    .ELSEIF eax == RES_TYPE_SPL
        lea eax, szRES_TYPE_SPL
    .ELSEIF eax == RES_TYPE_BCS
        lea eax, szRES_TYPE_BCS
    .ELSEIF eax == RES_TYPE_IDS
        lea eax, szRES_TYPE_IDS
    .ELSEIF eax == RES_TYPE_CRE
        lea eax, szRES_TYPE_CRE
    .ELSEIF eax == RES_TYPE_ARE
        lea eax, szRES_TYPE_ARE
    .ELSEIF eax == RES_TYPE_DLG
        lea eax, szRES_TYPE_DLG
    .ELSEIF eax == RES_TYPE_2DA
        lea eax, szRES_TYPE_2DA
    .ELSEIF eax == RES_TYPE_GAM
        lea eax, szRES_TYPE_GAM
    .ELSEIF eax == RES_TYPE_STO
        lea eax, szRES_TYPE_STO
    .ELSEIF eax == RES_TYPE_WMP
        lea eax, szRES_TYPE_WMP
    .ELSEIF eax == RES_TYPE_CHR 
        lea eax, szRES_TYPE_CHR
    .ELSEIF eax == RES_TYPE_EFF_ ; check file header to see which we have before hand
        lea eax, szRES_TYPE_EFF
    .ELSEIF eax == RES_TYPE_BS
        lea eax, szRES_TYPE_BS
    .ELSEIF eax == RES_TYPE_CHR2
        lea eax, szRES_TYPE_CHR2
    .ELSEIF eax == RES_TYPE_VVC
        lea eax, szRES_TYPE_VVC
    .ELSEIF eax == RES_TYPE_VEF
        lea eax, szRES_TYPE_VEF
    .ELSEIF eax == RES_TYPE_PRO
        lea eax, szRES_TYPE_PRO
    .ELSEIF eax == RES_TYPE_BIO
        lea eax, szRES_TYPE_BIO
    .ELSEIF eax == RES_TYPE_FON
        lea eax, szRES_TYPE_FON
    .ELSEIF eax == RES_TYPE_WBM
        lea eax, szRES_TYPE_WBM
    .ELSEIF eax == RES_TYPE_GUI
        lea eax, szRES_TYPE_GUI
    .ELSEIF eax == RES_TYPE_SQL
        lea eax, szRES_TYPE_SQL
    .ELSEIF eax == RES_TYPE_PVR
        lea eax, szRES_TYPE_PVR
    .ELSEIF eax == RES_TYPE_GLSL
        lea eax, szRES_TYPE_GLSL
    .ELSEIF eax == RES_TYPE_MENU
        lea eax, szRES_TYPE_MENU
    .ELSEIF eax == RES_TYPE_LUA2
        lea eax, szRES_TYPE_LUA2
    .ELSEIF eax == RES_TYPE_TTF2
        lea eax, szRES_TYPE_TTF2
    .ELSEIF eax == RES_TYPE_PNG2
        lea eax, szRES_TYPE_PNG2
    .ELSEIF eax == RES_TYPE_BAH
        lea eax, szRES_TYPE_BAH
        
;---------------------------------------------------------------------------------------
; 2000 - 3000 :: (0x07D0 - 0x0BB8) NWN resource types
;---------------------------------------------------------------------------------------        
    .ELSEIF eax == RES_TYPE_PLH
        lea eax, szRES_TYPE_PLH
    .ELSEIF eax == RES_TYPE_TEX
        lea eax, szRES_TYPE_TEX
    .ELSEIF eax == RES_TYPE_MDL
        lea eax, szRES_TYPE_MDL
    .ELSEIF eax == RES_TYPE_THG
        lea eax, szRES_TYPE_THG
    .ELSEIF eax == RES_TYPE_FNT
        lea eax, szRES_TYPE_FNT
    .ELSEIF eax == RES_TYPE_LUA
        lea eax, szRES_TYPE_LUA
    .ELSEIF eax == RES_TYPE_SLT
        lea eax, szRES_TYPE_SLT
    .ELSEIF eax == RES_TYPE_NSS
        lea eax, szRES_TYPE_NSS
    .ELSEIF eax == RES_TYPE_NCS
        lea eax, szRES_TYPE_NCS
    .ELSEIF eax == RES_TYPE_MOD
        lea eax, szRES_TYPE_MOD
    .ELSEIF eax == RES_TYPE_ARE2
        lea eax, szRES_TYPE_ARE2
    .ELSEIF eax == RES_TYPE_SET
        lea eax, szRES_TYPE_SET
    .ELSEIF eax == RES_TYPE_IFO
        lea eax, szRES_TYPE_IFO
    .ELSEIF eax == RES_TYPE_BIC
        lea eax, szRES_TYPE_BIC
    .ELSEIF eax == RES_TYPE_WOK
        lea eax, szRES_TYPE_WOK
    .ELSEIF eax == RES_TYPE_2DA2
        lea eax, szRES_TYPE_2DA2
    .ELSEIF eax == RES_TYPE_TLK
        lea eax, szRES_TYPE_TLK
    .ELSEIF eax == RES_TYPE_TXI
        lea eax, szRES_TYPE_TXI
    .ELSEIF eax == RES_TYPE_GIT
        lea eax, szRES_TYPE_GIT
    .ELSEIF eax == RES_TYPE_BTI
        lea eax, szRES_TYPE_BTI
    .ELSEIF eax == RES_TYPE_ITM2_
        lea eax, szRES_TYPE_ITM2
        
    .ELSEIF eax == RES_TYPE_UTI
        lea eax, szRES_TYPE_UTI
    .ELSEIF eax == RES_TYPE_BTC
        lea eax, szRES_TYPE_BTC
    .ELSEIF eax == RES_TYPE_CRE2_
        lea eax, szRES_TYPE_CRE2
        
    .ELSEIF eax == RES_TYPE_UTC
        lea eax, szRES_TYPE_UTC
    .ELSEIF eax == RES_TYPE_DLG2
        lea eax, szRES_TYPE_DLG2
    .ELSEIF eax == RES_TYPE_ITP
        lea eax, szRES_TYPE_ITP
    .ELSEIF eax == RES_TYPE_PAL_
        lea eax, szRES_TYPE_PAL       
    .ELSEIF eax == RES_TYPE_BTT
        lea eax, szRES_TYPE_BTT
    .ELSEIF eax == RES_TYPE_TRG_
        lea eax, szRES_TYPE_TRG       
    .ELSEIF eax == RES_TYPE_UTT
        lea eax, szRES_TYPE_UTT
    .ELSEIF eax == RES_TYPE_DDS
        lea eax, szRES_TYPE_DDS
    .ELSEIF eax == RES_TYPE_BTS
        lea eax, szRES_TYPE_BTS
    .ELSEIF eax == RES_TYPE_SND_
        lea eax, szRES_TYPE_SND        
    .ELSEIF eax == RES_TYPE_UTS
        lea eax, szRES_TYPE_UTS
    .ELSEIF eax == RES_TYPE_LTR
        lea eax, szRES_TYPE_LTR
    .ELSEIF eax == RES_TYPE_GFF
        lea eax, szRES_TYPE_GFF
    .ELSEIF eax == RES_TYPE_FAC
        lea eax, szRES_TYPE_FAC
    .ELSEIF eax == RES_TYPE_BTE
        lea eax, szRES_TYPE_BTE
    .ELSEIF eax == RES_TYPE_ENC_
        lea eax, szRES_TYPE_ENC        
    .ELSEIF eax == RES_TYPE_UTE
        lea eax, szRES_TYPE_UTE
    .ELSEIF eax == RES_TYPE_CON_
        lea eax, szRES_TYPE_CON        
    .ELSEIF eax == RES_TYPE_BTD
        lea eax, szRES_TYPE_BTD
    .ELSEIF eax == RES_TYPE_DOR_
        lea eax, szRES_TYPE_DOR        
    .ELSEIF eax == RES_TYPE_UTD
        lea eax, szRES_TYPE_UTD
    .ELSEIF eax == RES_TYPE_BTP
        lea eax, szRES_TYPE_BTP
    .ELSEIF eax == RES_TYPE_PLA_
        lea eax, szRES_TYPE_PLA        
    .ELSEIF eax == RES_TYPE_UTP
        lea eax, szRES_TYPE_UTP
    .ELSEIF eax == RES_TYPE_DFT
        lea eax, szRES_TYPE_DFT
    .ELSEIF eax == RES_TYPE_GIC
        lea eax, szRES_TYPE_GIC
    .ELSEIF eax == RES_TYPE_GUI2
        lea eax, szRES_TYPE_GUI2
        
;---------------------------------------------------------------------------------------
; 2048 - 2110 Witcher
;---------------------------------------------------------------------------------------        
    .ELSEIF eax == RES_TYPE_CSS
        lea eax, szRES_TYPE_CSS
    .ELSEIF eax == RES_TYPE_CCS
        lea eax, szRES_TYPE_CCS
    .ELSEIF eax == RES_TYPE_BTM
        lea eax, szRES_TYPE_BTM
    .ELSEIF eax == RES_TYPE_INI2_
        lea eax, szRES_TYPE_INI2        
    .ELSEIF eax == RES_TYPE_UTM
        lea eax, szRES_TYPE_UTM
;    .ELSEIF eax == RES_TYPE_INI2
;        lea eax, szRES_TYPE_INI2
;    .ELSEIF eax == RES_TYPE_SRC
;        lea eax, szRES_TYPE_SRC
    .ELSEIF eax == RES_TYPE_DWK
        lea eax, szRES_TYPE_DWK
    .ELSEIF eax == RES_TYPE_PWK
        lea eax, szRES_TYPE_PWK
    .ELSEIF eax == RES_TYPE_BTG
        lea eax, szRES_TYPE_BTG
    .ELSEIF eax == RES_TYPE_UTG
        lea eax, szRES_TYPE_UTG
    .ELSEIF eax == RES_TYPE_GEN_
        lea eax, szRES_TYPE_GEN        
    .ELSEIF eax == RES_TYPE_JRL
        lea eax, szRES_TYPE_JRL
    .ELSEIF eax == RES_TYPE_SAV2
        lea eax, szRES_TYPE_SAV2
    .ELSEIF eax == RES_TYPE_UTW
        lea eax, szRES_TYPE_UTW
    .ELSEIF eax == RES_TYPE_WAY_
        lea eax, szRES_TYPE_WAY        
    .ELSEIF eax == RES_TYPE_4PC
        lea eax, szRES_TYPE_4PC
    .ELSEIF eax == RES_TYPE_SSF
        lea eax, szRES_TYPE_SSF
    .ELSEIF eax == RES_TYPE_HAK
        lea eax, szRES_TYPE_HAK
    .ELSEIF eax == RES_TYPE_NWM
        lea eax, szRES_TYPE_NWM
    .ELSEIF eax == RES_TYPE_BIK
        lea eax, szRES_TYPE_BIK
    .ELSEIF eax == RES_TYPE_NDB
        lea eax, szRES_TYPE_NDB
    .ELSEIF eax == RES_TYPE_PTM
        lea eax, szRES_TYPE_PTM
    .ELSEIF eax == RES_TYPE_PTT
        lea eax, szRES_TYPE_PTT
    .ELSEIF eax == RES_TYPE_NCM
        lea eax, szRES_TYPE_NCM
    .ELSEIF eax == RES_TYPE_XSB_
        lea eax, szRES_TYPE_XSB
        
    .ELSEIF eax == RES_TYPE_MFX
        lea eax, szRES_TYPE_MFX
    .ELSEIF eax == RES_TYPE_BIN_
        lea eax, szRES_TYPE_BIN        
    .ELSEIF eax == RES_TYPE_MAT
        lea eax, szRES_TYPE_MAT
    .ELSEIF eax == RES_TYPE_MDB
        lea eax, szRES_TYPE_MDB
    .ELSEIF eax == RES_TYPE_SAY
        lea eax, szRES_TYPE_SAY
    .ELSEIF eax == RES_TYPE_TTF
        lea eax, szRES_TYPE_TTF
    .ELSEIF eax == RES_TYPE_TTC
        lea eax, szRES_TYPE_TTC
    .ELSEIF eax == RES_TYPE_CUT
        lea eax, szRES_TYPE_CUT
    .ELSEIF eax == RES_TYPE_KA
        lea eax, szRES_TYPE_KA
    .ELSEIF eax == RES_TYPE_JPG
        lea eax, szRES_TYPE_JPG
    .ELSEIF eax == RES_TYPE_ICO
        lea eax, szRES_TYPE_ICO
    .ELSEIF eax == RES_TYPE_OGG
        lea eax, szRES_TYPE_OGG
    .ELSEIF eax == RES_TYPE_SPT
        lea eax, szRES_TYPE_SPT
    .ELSEIF eax == RES_TYPE_SPW
        lea eax, szRES_TYPE_SPW
    .ELSEIF eax == RES_TYPE_WFX2
        lea eax, szRES_TYPE_WFX2
    .ELSEIF eax == RES_TYPE_UGM
        lea eax, szRES_TYPE_UGM
    .ELSEIF eax == RES_TYPE_QDB
        lea eax, szRES_TYPE_QDB
    .ELSEIF eax == RES_TYPE_QST
        lea eax, szRES_TYPE_QST
    .ELSEIF eax == RES_TYPE_NPC
        lea eax, szRES_TYPE_NPC
    .ELSEIF eax == RES_TYPE_SPN
        lea eax, szRES_TYPE_SPN
    .ELSEIF eax == RES_TYPE_UTX
        lea eax, szRES_TYPE_UTX
    .ELSEIF eax == RES_TYPE_MMD
        lea eax, szRES_TYPE_MMD
    .ELSEIF eax == RES_TYPE_SMM
        lea eax, szRES_TYPE_SMM
    .ELSEIF eax == RES_TYPE_UTA
        lea eax, szRES_TYPE_UTA
    .ELSEIF eax == RES_TYPE_MDE
        lea eax, szRES_TYPE_MDE
    .ELSEIF eax == RES_TYPE_MDV
        lea eax, szRES_TYPE_MDV
    .ELSEIF eax == RES_TYPE_MDA
        lea eax, szRES_TYPE_MDA
    .ELSEIF eax == RES_TYPE_MBA
        lea eax, szRES_TYPE_MBA
    .ELSEIF eax == RES_TYPE_OCT
        lea eax, szRES_TYPE_OCT
    .ELSEIF eax == RES_TYPE_BFX
        lea eax, szRES_TYPE_BFX
    .ELSEIF eax == RES_TYPE_PDB
        lea eax, szRES_TYPE_PDB
    .ELSEIF eax == RES_TYPE_THEWITCHERSAVE
        lea eax, szRES_TYPE_THEWITCHERSAVE
    .ELSEIF eax == RES_TYPE_PVS
        lea eax, szRES_TYPE_PVS
    .ELSEIF eax == RES_TYPE_CFX
        lea eax, szRES_TYPE_CFX
    .ELSEIF eax == RES_TYPE_LUC
        lea eax, szRES_TYPE_LUC
    .ELSEIF eax == RES_TYPE_PRB
        lea eax, szRES_TYPE_PRB
    .ELSEIF eax == RES_TYPE_CAM
        lea eax, szRES_TYPE_CAM
    .ELSEIF eax == RES_TYPE_VDS
        lea eax, szRES_TYPE_VDS
    .ELSEIF eax == RES_TYPE_BIN2
        lea eax, szRES_TYPE_BIN2
    .ELSEIF eax == RES_TYPE_WOB
        lea eax, szRES_TYPE_WOB
    .ELSEIF eax == RES_TYPE_API
        lea eax, szRES_TYPE_API
    .ELSEIF eax == RES_TYPE_PROPERTIES
        lea eax, szRES_TYPE_PROPERTIES
    .ELSEIF eax == RES_TYPE_PNG
        lea eax, szRES_TYPE_PNG
        
;---------------------------------------------------------------------------------------
; 3000 - 4000 :: (0x0BB8 - 0x0FA0) SW:KOTOR resource types
;---------------------------------------------------------------------------------------
    .ELSEIF eax == RES_TYPE_LYT
        lea eax, szRES_TYPE_LYT
    .ELSEIF eax == RES_TYPE_VIS
        lea eax, szRES_TYPE_VIS
    .ELSEIF eax == RES_TYPE_RIM
        lea eax, szRES_TYPE_RIM
    .ELSEIF eax == RES_TYPE_PTH
        lea eax, szRES_TYPE_PTH
    .ELSEIF eax == RES_TYPE_LIP
        lea eax, szRES_TYPE_LIP
    .ELSEIF eax == RES_TYPE_BWM
        lea eax, szRES_TYPE_BWM
    .ELSEIF eax == RES_TYPE_TXB
        lea eax, szRES_TYPE_TXB
    .ELSEIF eax == RES_TYPE_TPC
        lea eax, szRES_TYPE_TPC
    .ELSEIF eax == RES_TYPE_CWD_
        lea eax, szRES_TYPE_CWD
    .ELSEIF eax == RES_TYPE_MDX
        lea eax, szRES_TYPE_MDX
    .ELSEIF eax == RES_TYPE_PRO2_
        lea eax, szRES_TYPE_PRO2        
    .ELSEIF eax == RES_TYPE_RSV
        lea eax, szRES_TYPE_RSV
    .ELSEIF eax == RES_TYPE_AOE_
        lea eax, szRES_TYPE_AOE        
    .ELSEIF eax == RES_TYPE_SIG
        lea eax, szRES_TYPE_SIG
    .ELSEIF eax == RES_TYPE_MAT2_
        lea eax, szRES_TYPE_MAT2        
    .ELSEIF eax == RES_TYPE_MAB
        lea eax, szRES_TYPE_MAB
    .ELSEIF eax == RES_TYPE_QST2
        lea eax, szRES_TYPE_QST2
    .ELSEIF eax == RES_TYPE_STO2
        lea eax, szRES_TYPE_STO2
    .ELSEIF eax == RES_TYPE_APL
        lea eax, szRES_TYPE_APL
    .ELSEIF eax == RES_TYPE_HEX
        lea eax, szRES_TYPE_HEX
    .ELSEIF eax == RES_TYPE_MDX2
        lea eax, szRES_TYPE_MDX2
    .ELSEIF eax == RES_TYPE_TXB2
        lea eax, szRES_TYPE_TXB2
    .ELSEIF eax == RES_TYPE_TPC2
        lea eax, szRES_TYPE_TPC2     
    .ELSEIF eax == RES_TYPE_FSM
        lea eax, szRES_TYPE_FSM
    .ELSEIF eax == RES_TYPE_ART
        lea eax, szRES_TYPE_ART
    .ELSEIF eax == RES_TYPE_AMP
        lea eax, szRES_TYPE_AMP
    .ELSEIF eax == RES_TYPE_CWA
        lea eax, szRES_TYPE_CWA
    .ELSEIF eax == RES_TYPE_XLS
        lea eax, szRES_TYPE_XLS
    .ELSEIF eax == RES_TYPE_SPF
        lea eax, szRES_TYPE_SPF                
    .ELSEIF eax == RES_TYPE_BIP
        lea eax, szRES_TYPE_BIP
    .ELSEIF eax == RES_TYPE_MDB2
        lea eax, szRES_TYPE_MDB2
    .ELSEIF eax == RES_TYPE_MDA2
        lea eax, szRES_TYPE_MDA2
    .ELSEIF eax == RES_TYPE_SPT2
        lea eax, szRES_TYPE_SPT2
    .ELSEIF eax == RES_TYPE_GR2
        lea eax, szRES_TYPE_GR2
    .ELSEIF eax == RES_TYPE_FXA
        lea eax, szRES_TYPE_FXA
    .ELSEIF eax == RES_TYPE_FXE
        lea eax, szRES_TYPE_FXE
    .ELSEIF eax == RES_TYPE_JPG2
        lea eax, szRES_TYPE_JPG2
    .ELSEIF eax == RES_TYPE_PWC
        lea eax, szRES_TYPE_PWC        
        
;---------------------------------------------------------------------------------------
; 9997-9999: Common resource types 
;---------------------------------------------------------------------------------------        
    .ELSEIF eax == RES_TYPE_BIG
        lea eax, szRES_TYPE_BIG
    .ELSEIF eax == RES_TYPE_IDS2
        lea eax, szRES_TYPE_IDS2
    .ELSEIF eax == RES_TYPE_ERF
        lea eax, szRES_TYPE_ERF
    .ELSEIF eax == RES_TYPE_BIF
        lea eax, szRES_TYPE_BIF
    .ELSEIF eax == RES_TYPE_KEY
        lea eax, szRES_TYPE_KEY

;---------------------------------------------------------------------------------------
; Found in NWN: Visual Foxpro database formats: dbf=database, cdx=index, fpt=memo
;---------------------------------------------------------------------------------------
    .ELSEIF eax == RES_TYPE_VFPEXE
        lea eax, szRES_TYPE_VFPEXE
    .ELSEIF eax == RES_TYPE_VFPDBF
        lea eax, szRES_TYPE_VFPDBF
    .ELSEIF eax == RES_TYPE_VFPCDX
        lea eax, szRES_TYPE_VFPCDX
    .ELSEIF eax == RES_TYPE_VFPFPT
        lea eax, szRES_TYPE_VFPFPT
        
    .ELSE
        IFDEF DEBUG32
            PrintDec dwResType
        ENDIF
    
        Invoke szCopy, Addr szHex, Addr szUnknownRes
        Invoke dw2hex, dwResType, Addr szResUnknown ; local var
        Invoke szCatStr, Addr szUnknownRes, Addr szResUnknown
        ;Invoke BIFutoa_ex, dwResType, Addr szUnknownRes
        lea eax, szUnknownRes
    .ENDIF
 
    ret

IERESResTypeToString endp




; Paul Dixon's utoa_ex function. unsigned dword to ascii. 

OPTION PROLOGUE:NONE
OPTION EPILOGUE:NONE

align 16

RESutoa_ex proc uvar:DWORD,pbuffer:DWORD

  ; --------------------------------------------------------------------------------
  ; this algorithm was written by Paul Dixon and has been converted to MASM notation
  ; --------------------------------------------------------------------------------

    mov eax, [esp+4]                ; uvar      : unsigned variable to convert
    mov ecx, [esp+8]                ; pbuffer   : pointer to result buffer

    push esi
    push edi

    jmp udword

  align 4
  chartab:
    dd "00","10","20","30","40","50","60","70","80","90"
    dd "01","11","21","31","41","51","61","71","81","91"
    dd "02","12","22","32","42","52","62","72","82","92"
    dd "03","13","23","33","43","53","63","73","83","93"
    dd "04","14","24","34","44","54","64","74","84","94"
    dd "05","15","25","35","45","55","65","75","85","95"
    dd "06","16","26","36","46","56","66","76","86","96"
    dd "07","17","27","37","47","57","67","77","87","97"
    dd "08","18","28","38","48","58","68","78","88","98"
    dd "09","19","29","39","49","59","69","79","89","99"

  udword:
    mov esi, ecx                    ; get pointer to answer
    mov edi, eax                    ; save a copy of the number

    mov edx, 0D1B71759h             ; =2^45\10000    13 bit extra shift
    mul edx                         ; gives 6 high digits in edx

    mov eax, 68DB9h                 ; =2^32\10000+1

    shr edx, 13                     ; correct for multiplier offset used to give better accuracy
    jz short skiphighdigits         ; if zero then don't need to process the top 6 digits

    mov ecx, edx                    ; get a copy of high digits
    imul ecx, 10000                 ; scale up high digits
    sub edi, ecx                    ; subtract high digits from original. EDI now = lower 4 digits

    mul edx                         ; get first 2 digits in edx
    mov ecx, 100                    ; load ready for later

    jnc short next1                 ; if zero, supress them by ignoring
    cmp edx, 9                      ; 1 digit or 2?
    ja   ZeroSupressed              ; 2 digits, just continue with pairs of digits to the end

    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dh                   ; but only write the 1 we need, supress the leading zero
    inc esi                         ; update pointer by 1
    jmp  ZS1                        ; continue with pairs of digits to the end

  align 16
  next1:
    mul ecx                         ; get next 2 digits
    jnc short next2                 ; if zero, supress them by ignoring
    cmp edx, 9                      ; 1 digit or 2?
    ja   ZS1a                       ; 2 digits, just continue with pairs of digits to the end

    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dh                   ; but only write the 1 we need, supress the leading zero
    add esi, 1                      ; update pointer by 1
    jmp  ZS2                        ; continue with pairs of digits to the end

  align 16
  next2:
    mul ecx                         ; get next 2 digits
    jnc short next3                 ; if zero, supress them by ignoring
    cmp edx, 9                      ; 1 digit or 2?
    ja   ZS2a                       ; 2 digits, just continue with pairs of digits to the end

    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dh                   ; but only write the 1 we need, supress the leading zero
    add esi, 1                      ; update pointer by 1
    jmp  ZS3                        ; continue with pairs of digits to the end

  align 16
  next3:

  skiphighdigits:
    mov eax, edi                    ; get lower 4 digits
    mov ecx, 100

    mov edx, 28F5C29h               ; 2^32\100 +1
    mul edx
    jnc short next4                 ; if zero, supress them by ignoring
    cmp edx, 9                      ; 1 digit or 2?
    ja  short ZS3a                  ; 2 digits, just continue with pairs of digits to the end

    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dh                   ; but only write the 1 we need, supress the leading zero
    inc esi                         ; update pointer by 1
    jmp short  ZS4                  ; continue with pairs of digits to the end

  align 16
  next4:
    mul ecx                         ; this is the last pair so don; t supress a single zero
    cmp edx, 9                      ; 1 digit or 2?
    ja  short ZS4a                  ; 2 digits, just continue with pairs of digits to the end

    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dh                   ; but only write the 1 we need, supress the leading zero
    mov byte ptr [esi+1], 0         ; zero terminate string

    pop edi
    pop esi
    ret 8

  align 16
  ZeroSupressed:
    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dx
    add esi, 2                      ; write them to answer

  ZS1:
    mul ecx                         ; get next 2 digits
  ZS1a:
    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dx                   ; write them to answer
    add esi, 2

  ZS2:
    mul ecx                         ; get next 2 digits
  ZS2a:
    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dx                   ; write them to answer
    add esi, 2

  ZS3:
    mov eax, edi                    ; get lower 4 digits
    mov edx, 28F5C29h               ; 2^32\100 +1
    mul edx                         ; edx= top pair
  ZS3a:
    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dx                   ; write to answer
    add esi, 2                      ; update pointer

  ZS4:
    mul ecx                         ; get final 2 digits
  ZS4a:
    mov edx, chartab[edx*4]         ; look them up
    mov [esi], dx                   ; write to answer

    mov byte ptr [esi+2], 0         ; zero terminate string

  sdwordend:

    pop edi
    pop esi

    ret 8

RESutoa_ex endp

OPTION PROLOGUE:PrologueDef
OPTION EPILOGUE:EpilogueDef







END
