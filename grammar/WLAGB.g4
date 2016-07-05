/* WLA Gameboy Grammar */
grammar WLAGB;

import WLACommon;

/***************************************
* Gameboy WLA entry point.
***************************************/
wlagb
    : program
    ;

/***************************************
* Opcode Override
****************************************
* Defines Gameboy Specific opcodes.
***************************************/
opcode
    :   opcodeAdc
    |   opcodeAdd
    |   opcodeAnd
    |   opcodeBit
    |   opcodeCall
    |   CcfOpcode
    |   opcodeCp
    |   CplOpcode
    |   DaaOpcode
    |   opcodeDec
    |   DiOpcode
    |   EiOpcode
    |   HaltOpcode
    |   opcodeInc
    |   opcodeLd
    |   NopOpcode
    |   opcodeOr
    |   opcodePush
    |   opcodePop
    |   opcodeRes
    |   RetiOpcode
    |   opcodeRet
    |   RlaOpcode
    |   opcodeRL
    |   RlcaOpcode
    |   opcodeRLC
    |   RraOpcode
    |   opcodeRR
    |   RrcaOpcode
    |   opcodeRRC
    |   opcodeRst
    |   opcodeSbc
    |   ScfOpcode
    |   opcodeSet
    |   opcodeSla
    |   opcodeSra
    |   opcodeSrl
    |   StopOpcode
    |   opcodeSub
    |   opcodeSwap
    |   opcodeXor
    ;

wordRegister
    :   RegisterAF
    |   RegisterBC
    |   RegisterDE
    |   RegisterHL
    |   RegisterSP
    ;

byteRegister
    :   RegisterA
    |   RegisterB
    |   RegisterC
    |   RegisterD
    |   RegisterE
    |   RegisterH
    |   RegisterL;

registerHLLookup : LeftParen RegisterHL RightParen;

opcodeAdc
    :   AdcOpcode byteRegister
    |   AdcOpcode registerHLLookup
    |   AdcOpcode expression
    ;

opcodeAdd
    :   AddOpcode byteRegister
    |   AddOpcode RegisterHL Comma wordRegister
    |   AddOpcode registerHLLookup
    |   AddOpcode RegisterSP Comma expression
    |   AddOpcode expression
    ;

opcodeAnd
    :   AndOpcode byteRegister
    |   AndOpcode registerHLLookup
    |   AndOpcode expression
    ;

opcodeBit
    :   BitOpcode expression Comma byteRegister
    |   BitOpcode expression Comma registerHLLookup
    ;

opcodeCall
    :   (CallOpcode | JpOpcode | JrOpcode) (callCondition Comma)? (expression)
    ;

callCondition
    :   (RegisterC | FlagNC | FlagZ | FlagNZ)
    ;

opcodeCp
    :   CpOpcode byteRegister
    |   CpOpcode registerHLLookup
    |   CpOpcode expression
    ;

opcodeDec
    :   DecOpcode byteRegister
    |   DecOpcode wordRegister
    |   DecOpcode registerHLLookup
    ;

opcodeInc
    :   IncOpcode byteRegister
    |   IncOpcode wordRegister
    |   IncOpcode registerHLLookup
    ;

opcodeLd
    :   LdOpcode byteRegister Comma byteRegister
    |   LdOpcode byteRegister Comma expression
    |   LdOpcode wordRegister Comma expression
    |   LdOpcode byteRegister Comma registerHLLookup
    |   LdOpcode registerHLLookup Comma byteRegister
    |   LdOpcode RegisterPC Comma RegisterHL
    |   LdOpcode RegisterSP Comma RegisterHL
    |   LdOpcode RegisterHL Comma RegisterSP (Add | Subtract) expression
    |   LdOpcode registerHLLookup Comma expression
    |   LddOpcode RegisterA Comma registerHLLookup
    |   LddOpcode registerHLLookup Comma RegisterA
    |   LdiOpcode RegisterA Comma registerHLLookup
    |   LdiOpcode registerHLLookup Comma RegisterA
    |   LdhOpcode RegisterA Comma addressLookup
    |   LdhOpcode addressLookup Comma RegisterA
    |   LdOpcode addressLookup Comma RegisterSP
    |   LdOpcode RegisterA Comma
            (LeftParen
                (('$FF00' Add (RegisterC | expression))
                |   RegisterBC
                |   RegisterDE
                |   (RegisterHL Add)
                |   (RegisterHL Subtract)
                |   RegisterHLD
                |   RegisterHLI
                |   expression)
             RightParen)
    |   LdOpcode (LeftParen
                     (('$FF00' Add (RegisterC | expression))
                     |   RegisterBC
                     |   RegisterDE
                     |   (RegisterHL Add)
                     |   (RegisterHL Subtract)
                     |   RegisterHLD
                     |   RegisterHLI
                     |   expression)
                  RightParen) Comma RegisterA
    ;

opcodeOr
    :   OrOpcode byteRegister
    |   OrOpcode registerHLLookup
    |   OrOpcode expression
    ;


opcodePush
    :   PushOpcode wordRegister
    ;

opcodePop
    :   PopOpcode wordRegister
    ;

opcodeRes
    :   ResOpcode expression Comma byteRegister
    |   ResOpcode expression Comma registerHLLookup
    ;

opcodeRet
    :   RetOpcode callCondition?
    ;

opcodeRL
    :   RlOpcode byteRegister
    |   RlOpcode registerHLLookup
    ;

opcodeRLC
    :   RlcOpcode byteRegister
    |   RlcOpcode registerHLLookup
    ;

opcodeRR
    :   RrOpcode byteRegister
    |   RrOpcode registerHLLookup
    ;

opcodeRRC
    :   RrcOpcode byteRegister
    |   RrcOpcode registerHLLookup
    ;

opcodeRst
    :   RstOpcode expression
    ;

opcodeSbc
    :   SbcOpcode byteRegister
    |   SbcOpcode registerHLLookup
    |   SbcOpcode expression
    ;

opcodeSet
    :   SetOpcode expression Comma byteRegister
    |   SetOpcode expression Comma registerHLLookup
    ;

opcodeSla
    :   SlaOpcode byteRegister
    |   SlaOpcode registerHLLookup
    ;

opcodeSra
    :   SraOpcode byteRegister
    |   SraOpcode registerHLLookup
    ;

opcodeSrl
    :   SrlOpcode byteRegister
    |   SrlOpcode registerHLLookup
    ;

opcodeSub
    :   SubOpcode byteRegister
    |   SubOpcode registerHLLookup
    |   SubOpcode expression
    ;

opcodeSwap
    :   SwapOpcode byteRegister
    |   SwapOpcode registerHLLookup
    ;

opcodeXor
    :   XorOpcode byteRegister
    |   XorOpcode registerHLLookup
    ;

addressLookup
    :   (LeftParen | LeftBracket) expression (RightParen | RightBracket)
    ;

/***************************************
* Directive Override
****************************************
* Override to combine common and Gameboy specific directives.
***************************************/
directive
    :   directivesGB
    |   commonDirectives
    ;

directivesGB
    :   ComputeGbChecksum
    |   ComputeChecksum
    |   directiveCartridgeType
    |   ComputeGbComplementCheck
    |   ComputeComplementCheck
    |   directiveCountryCode
    |   directiveDesinationCode
    |   NintendoLogo
    |   GbHeader
    |   directiveLicenseCodeNew
    |   directiveLicenseCodeOld
    |   directiveName
    |   directiveRamSize
    |   RomDMG
    |   RomGBC
    |   RomSGB
    ;

directiveCartridgeType
    :   CartridgeType expression
    ;

directiveCountryCode
    :   CountryCode expression
    ;

directiveDesinationCode
    :   DesinationCode expression
    ;

directiveLicenseCodeNew
    :   LicenseeCodeNew stringValue
    ;

directiveLicenseCodeOld
    :   LicenseeCodeOld expression
    ;

directiveName
    :   Name stringValue
    ;

directiveRamSize
    :   RamSize expression
    ;

/***************************************
* Gameboy specific shared words override.
****************************************
* Note: This is a nasty workaround to allow the language specification
* words as identifiers/label declarations. Ideally these would be treated
* as reserved words that could not be used as identifier/labels.
***************************************/
sharedWords
    :   commonSharedWords
    |   FlagNC
    |   FlagNZ
    |   FlagZ   /*
    |   AdcOpcode
    |   AddOpcode
    |   AndOpcode
    |   BitOpcode
    |   CallOpcode
    |   CcfOpcode
    |   CpOpcode
    |   CplOpcode
    |   DaaOpcode
    |   DecOpcode
    |   DiOpcode
    |   EiOpcode
    |   HaltOpcode
    |   IncOpcode
    |   JpOpcode
    |   JrOpcode
    |   LdOpcode
    |   LddOpcode
    |   LdhOpcode
    |   LdiOpcode
    |   NopOpcode
    |   OrOpcode
    |   PopOpcode
    |   PushOpcode
    |   ResOpcode
    |   RetiOpcode
    |   RetOpcode
    |   RlaOpcode
    |   RlOpcode
    |   RlcaOpcode
    |   RlcOpcode
    |   RraOpcode
    |   RrOpcode
    |   RrcaOpcode
    |   RrcOpcode
    |   RstOpcode
    |   SbcOpcode
    |   ScfOpcode
    |   SetOpcode
    |   SlaOpcode
    |   SraOpcode
    |   SrlOpcode
    |   StopOpcode
    |   SubOpcode
    |   SwapOpcode
    |   XorOpcode */
    |   RegisterAF
    |   RegisterBC
    |   RegisterDE
    |   RegisterHL
    |   RegisterSP
    |   RegisterHLD
    |   RegisterHLI
    |   RegisterPC
    |   RegisterA
    |   RegisterB
    |   RegisterC
    |   RegisterD
    |   RegisterE
    |   RegisterH
    |   RegisterL
    ;

// Redefine of Dec.
DEC : D E C;
SWAP : SwapOpcode;

// Gameboy opcode flags.
FlagNC : N C;
FlagNZ : N Z;
FlagZ : Z;
// NOTE: C is mapped as RegisterC

// Gameboy Opcodes
AdcOpcode : A D C;
AddOpcode : A D D;
AndOpcode : A N D;
BitOpcode : B I T;
CallOpcode : C A L L;
CcfOpcode : C C F;
CpOpcode : C P;
CplOpcode : C P L;
DaaOpcode : D A A;
DecOpcode : D E C;
DiOpcode : D I;
EiOpcode : E I;
HaltOpcode : H A L T;
IncOpcode : I N C;
JpOpcode : J P;
JrOpcode : J R;
LdOpcode : L D;
LddOpcode : L D D;
LdhOpcode : L D H;
LdiOpcode : L D I;
NopOpcode : N O P;
OrOpcode : O R;
PopOpcode : P O P;
PushOpcode : P U S H;
ResOpcode : R E S;
RetiOpcode : R E T I;
RetOpcode : R E T;
RlaOpcode : R L A;
RlOpcode : R L;
RlcaOpcode : R L C A;
RlcOpcode : R L C;
RraOpcode : R R A;
RrOpcode : R R;
RrcaOpcode : R R C A;
RrcOpcode : R R C;
RstOpcode : R S T;
SbcOpcode : S B C;
ScfOpcode : S C F;
SetOpcode : S E T;
SlaOpcode : S L A;
SraOpcode : S R A;
SrlOpcode : S R L;
StopOpcode : S T O P;
SubOpcode : S U B;
SwapOpcode : S W A P;
XorOpcode : X O R;

// Registers
RegisterAF : A F;
RegisterBC : B C;
RegisterDE : D E;
RegisterHL : H L;
RegisterSP : S P;

RegisterHLD : RegisterHL D;
RegisterHLI : RegisterHL I;
RegisterPC : P C;

RegisterA : A;
RegisterB : B;
RegisterC : C;
RegisterD : D;
RegisterE : E;
RegisterH : H;
RegisterL : L;

// Game Boy Specific Directives
ComputeGbChecksum : '.' C O M P U T E G B C H E C K S U M;
ComputeChecksum : '.' C O M P U T E C H E C K S U M;
CartridgeType : '.' C A R T R I D G E T Y P E;
CountryCode : '.' C O U N T R Y C O D E;
DesinationCode : '.' D E S T I N A T I O N C O D E;
NintendoLogo : '.' N I N T E N D O L O G O;
GbHeader : '.' G B H E A D E R;
ComputeGbComplementCheck : '.' C O M P U T E G B C O M P L E M E N T C H E C K;
ComputeComplementCheck : '.' C O M P U T E C O M P L E M E N T C H E C K;
LicenseeCodeNew : '.' L I C E N S E E C O D E N E W;
LicenseeCodeOld : '.' L I C E N S E E C O D E O L D;
Name : '.' N A M E;
RamSize : '.' R A M S I Z E;
RomDMG : '.' R O M D M G;
RomGBC : '.' R O M G B C;
RomSGB : '.' R O M S G B;
