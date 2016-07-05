/* WLA Common Grammar */
grammar WLACommon;

/***************************************
* Common WLA Parse Logic
***************************************/
program
    :   (rootLevelCommand)+ EOF;

rootLevelCommand
    :   directiveMacro
    |   macrolessCommand
    ;

macrolessCommand
    :   directive
    |   opcode
    |   labelDeclaration
    |   macroCall
    |   NewLine
    ;

macroCall
    :   (label | MacroArg) macroArgList?
    ;

macroArgList
    :   macroArg ((Comma macroArg) | macroArg)*
    |   macroArg
    ;

macroArg
    :   expression
    |   label
    |   Number
    |   StringLiteral
    |   MacroArg
    |   CharLiteral
    ;

/***************************************
* WLA Common Directives
***************************************/
directive
    :   commonDirectives
    ;

commonDirectives
    :   directiveAsc
    |   directiveAsciiTable
    |   directiveAsm
    |   directiveBackground
    |   directiveBank
    |   directiveBlock
    |   directiveBreakpoint
    |   directiveDb
    |   directiveDbm
    |   directiveRomBankSize
    |   directiveDbCos
    |   directiveDbRnd
    |   directiveDbSin
    |   directiveDefine
    |   directiveDs
    |   directiveOutname
    |   directiveIf
    |   directiveDStruct
    |   directiveDsw
    |   directiveDw
    |   directiveDwm
    |   directiveDwCos
    |   directiveDwRnd
    |   directiveDwSin
    |   directiveEnum
    |   directiveEmptyFill
    |   directiveExport
    |   Fail
    |   directiveFClose
    |   directiveFOpen
    |   directiveFRead
    |   directiveFSize
    |   directiveInclude
    |   directiveIncBin
    |   directiveInput
    |   directiveMemoryMap
    |   directiveOrg
    |   directivePrintt
    |   directivePrintv
    |   directiveRamSection
    |   directiveRepeat
    |   directiveRomBankMap
    |   directiveRomBanks
    |   directiveSeed
    |   directiveSection
    |   Shift
    |   directiveStruct
    |   directiveSymbol
    |   directiveUnbackground
    ;

directiveAsc
    :   Asc stringValue
    ;

directiveAsciiTable
    :   (AsciiTable | AscTable) NewLine
        ( MAP (CharLiteral | stringValue | expression) TO (CharLiteral | stringValue | expression) Assign Number NewLine
        | ( MAP (CharLiteral | stringValue | expression) Assign Number ) NewLine )*
        EndA
    ;

directiveAsm
    :   EndAsm NewLine
        (directiveAsm|.|'.')*?
        Asm
    |   Asm
    ;

directiveBackground
    :   Background stringValue
    ;

directiveBank
    :   Bank expression
    |   Bank expression SLOT expression
    ;

directiveBlock
    :   Block stringValue NewLine
        (rootLevelCommand)*
        EndB
    ;

directiveBreakpoint
    :   BreakPoint
    |   Br
    ;

directiveDb
    :   (Db | Byt) (expression | stringValue) ((Comma)? (expression | stringValue))*
    ;

directiveDbm
    :   Dbm label (expression | stringValue) ((Comma)? (expression | stringValue))*
    ;

directiveRomBankSize
    :   RomBankSize expression
    ;

directiveDbCos
    :   DbCos cosSinArgs
    ;

cosSinArgs
    :   expression Comma expression Comma expression Comma expression Comma expression
    ;

directiveDbRnd
    :   DbRnd expression Comma expression Comma expression
    ;

directiveDbSin
    :   DbSin cosSinArgs
    ;

directiveDefine
    :   (Define | Def | Equ) label
    |   (Define | Def | Equ | Redefine | Redef) label argList
    |   (Undefine | Undef) label (Comma label)*
    ;

directiveDs
    :   (Ds | Dsb) expression Comma expression
    ;

directiveDStruct
    :   Dstruct label INSTANCEOF label (DATA argList)*
    |   Dstruct label Comma argList
    |   Dstruct label
    ;

argList
    :   (expression | stringValue | CharLiteral)
        (Comma (expression | stringValue | CharLiteral))*
    ;

directiveDw
    :   (Dw | Word) expression ((Comma)? expression)*
    ;

directiveDsw
    :   Dsw expression Comma expression
    ;

directiveDwm
    :   Dwm label expression ((Comma)? expression)*
    ;

directiveDwCos
    :   DwCos cosSinArgs
    ;

directiveDwRnd
    :   DwRnd expression Comma expression Comma expression
    ;

directiveDwSin
    :   DwSin cosSinArgs
    ;

directiveEmptyFill
    :   EmptyFill expression
    ;

directiveEnum
    :   Enum expression EXPORT? NewLine
        enumEntry+
        EndE
    ;

enumEntry
    :   (label ':'? '.'?(DB | DW)) NewLine
    |   (label ':'? '.'?(DS | DSB | DSW) expression) NewLine
    |   (label ':'? INSTANCEOF label expression?) NewLine
    ;

directiveExport
    :   Export label (Comma? label)*
    ;

directiveFClose
    :   FClose label
    ;

directiveFOpen
    :   FOpen stringValue label
    ;

directiveFRead
    :   FRead label label
    ;

directiveFSize
    :   FSize label label
    ;

directiveInclude
    :   (IncDir | Include) stringValue
    ;

directiveIncBin
    :   IncBin stringValue (SKIPVAL expression)? (READ expression)? (SWAP)? (FSIZE label)? (FILTER label)?
    ;

directiveInput
    :   Input label
    ;

directiveIf
    :   directiveIfStart NewLine
        (macrolessCommand)*
        (Else NewLine
         (macrolessCommand)*)?
        EndIf
    ;

directiveIfMacro
    :   directiveIfMacroStart NewLine
        (macrolessCommand)*
        (Else NewLine
         (macrolessCommand)*)?
        EndIf
    ;

directiveIfStart
    :   If expressionValue CompareOperator expressionValue
    |   (IfEq | IfNEq | IfLe | IfLeEq | IfGr | IfGrEq) expressionValue expressionValue
    |   (IfDef | IfNDef) label
    |   IfExists stringValue
    ;

directiveIfMacroStart
    :   (IfDefM | IfNDefM) label
    |   directiveIfStart
    ;

directiveMemoryMap
    :   MemoryMap NewLine
        (memoryMapEntry)*
        EndMe
    ;

memoryMapEntry
    :   (DEFAULTSLOT expression) NewLine
    |   (SLOTSIZE expression) NewLine
    |   (SLOT expression (START)? expression ((SIZE)? expression)?) NewLine
    ;

directiveMacro
    :   Macro label (ARGS argList)? NewLine
        (macrolessCommand | directiveIfMacro)*
        EndM
    ;

directiveOrg
    :   (Org | OrgA) expression
    ;

directiveOutname
    :   OutName stringValue
    ;

directivePrintt
    :   Printt stringValue
    ;

directivePrintv
    :   Printv (DEC | HEX) expression
    ;

directiveRamSection
    :   RamSection stringValue (BANK expression SLOT expression)? NewLine
        enumEntry+
        EndS
    ;

directiveRepeat
    :   (Repeat | Rept) expression (INDEX label)? NewLine
        (rootLevelCommand)*
        EndR
    ;

directiveRomBankMap
    :   RomBankMap NewLine
        (romBankMapCommand)+
        EndRo
    ;

romBankMapCommand
    :   (BANKSTOTAL expression NewLine)
    |   (BANKSIZE expression NewLine)
    |   (BANKS expression NewLine)
    ;

directiveRomBanks
    :   RomBanks expression
    ;

directiveSeed
    :   Seed expression
    ;

directiveSection
    :   Section stringValue (NAMESPACE stringValue)?
            (SIZE expression)? (ALIGN expression)?
            (FREE | FORCE | SEMISUBFREE | SEMIFREE | SUPERFREE | OVERWRITE)?
            (RETURNORG)? NewLine
        (rootLevelCommand)+
        EndS
    ;

directiveStruct
    :   Struct label NewLine
        (enumEntry)+
        EndSt
    ;

directiveSymbol
    :   (Sym | Symbol) label
    ;

directiveUnbackground
    :   Unbackground expression expression
    ;

/***************************************
* WLA Common Opcodes
****************************************
* Note: This section should be overridden by each hardware configuration.
***************************************/
opcode
    :   'E'
    ;

expressionValue
    :   Number
    |   label
    |   MacroArg
    |   CharLiteral
    |   labelAddress
    ;

label
    :   Label
    |   sharedWords
    |   relativeLabel
    ;

expression
    :   expression operator expression
    |   LeftParen expression RightParen
    |   unaryOperator expression
    |   expressionValue
    ;

labelDeclaration
    :   label ':'
    |   relativeLabel
    ;

relativeLabel
    :   Add
    |   Subtract
    |   DirectionalJump
    ;

labelAddress
    :   ':' label
    ;

operator
    :   Add
    |   Subtract
    |   Multiply
    |   Divide
    |   Or
    |   And
    |   Exp
    |   Mod
    |   Xor
    |   LeftShift
    |   RightShift
    ;

unaryOperator
    :   Add
    |   Subtract
    |   HighByte
    |   LowByte
    ;

stringValue
    :   StringLiteral
    |   label
    |   MacroArg
    ;

/***************************************
* WLA Shared Words
****************************************
* Note: This is a nasty workaround to allow the language specification
* words as identifiers/label declarations. Ideally these would be treated
* as reserved words that could not be used as identifier/labels.
***************************************/
sharedWords
    :   commonSharedWords
    ;

commonSharedWords
    :   ARGS
    |   ALIGN
    |   BANK
    |   BANKS
    |   BANKSIZE
    |   BANKSTOTAL
    |   DATA
    |   DEC
    |   DEFAULTSLOT
    |   DB
    |   DS
    |   DSB
    |   DSW
    |   DW
    |   EXPORT
    |   FSIZE
    |   FILTER
    |   FREE
    |   FORCE
    |   HEX
    |   INSTANCEOF
    |   INDEX
    |   MAP
    |   NAMESPACE
    |   OVERWRITE
    |   READ
    |   RETURNORG
    |   SEMIFREE
    |   SEMISUBFREE
    |   SIZE
    |   SKIPVAL
    |   SLOT
    |   SLOTSIZE
    |   START
    |   SUPERFREE
    |   SWAP
    |   TO
    ;


LeftParen : '(';
RightParen : ')';
LeftBracket : '[';
RightBracket : ']';

Assign : '=';
Comma : ',';
Add : '+';
Subtract : '-';
Multiply : '*';
Divide : '/';
Or : '|';
And : '&';
Exp : '^';
Mod : '#';
Xor : '~';
LowByte : '<';
HighByte : '>';
LeftShift : '<<';
RightShift : '>>';

// Character definitions to remove case sensitivitiy.
fragment A : ('a'|'A');
fragment B : ('b'|'B');
fragment C : ('c'|'C');
fragment D : ('d'|'D');
fragment E : ('e'|'E');
fragment F : ('f'|'F');
fragment G : ('g'|'G');
fragment H : ('h'|'H');
fragment I : ('i'|'I');
fragment J : ('j'|'J');
fragment K : ('k'|'K');
fragment L : ('l'|'L');
fragment M : ('m'|'M');
fragment N : ('n'|'N');
fragment O : ('o'|'O');
fragment P : ('p'|'P');
fragment Q : ('q'|'Q');
fragment R : ('r'|'R');
fragment S : ('s'|'S');
fragment T : ('t'|'T');
fragment U : ('u'|'U');
fragment V : ('v'|'V');
fragment W : ('w'|'W');
fragment X : ('x'|'X');
fragment Y : ('y'|'Y');
fragment Z : ('z'|'Z');

/* Common Directives */
Asc : '.' A S C;
AscTable : '.' A S C T A B L E;
AsciiTable :'.' A S C I I T A B L E;
Asm : '.' A S M;
Background : '.' B A C K G R O U N D;
Bank : '.' B A N K;
Block : '.' B L O C K;
Br : '.' B R;
BreakPoint : '.' B R E A K P O I N T;
Byt : '.' B Y T;
RomBankSize : '.' R O M B A N K S I Z E;
Db : '.' D B;
Dbm : '.' D B M;
DbCos : '.' D B C O S;
DbRnd : '.' D B R N D;
DbSin : '.' D B S I N;
Define : '.' D E F I N E;
Def : '.' D E F;
Ds : '.' D S;
Dsb : '.' D S B;
Dstruct : '.' D S T R U C T;
Dsw : '.' D S W;
Dw : '.' D W;
Dwm : '.' D W M;
DwCos : '.' D W C O S;
DwRnd : '.' D W R N D;
DwSin : '.' D W S I N;
Else : '.' E L S E;
EmptyFill : '.' E M P T Y F I L L;
EndA : '.' E N D A;
EndAsm : '.' E N D A S M;
EndB : '.' E N D B;
EndE : '.' E N D E;
EndIf : '.' E N D I F;
EndM : '.' E N D M;
EndMe :'.' E N D M E;
EndR : '.' E N D R;
EndRo : '.' E N D R O;
EndS : '.' E N D S;
EndSt : '.' E N D S T;
Enum : '.' E N U M;
Equ : '.' E Q U;
Export : '.' E X P O R T;
Fail : '.' F A I L;
FClose : '.' F C L O S E;
FOpen : '.' F O P E N;
FRead : '.' F R E A D;
FSize : '.' F S I Z E;
If : '.' I F;
IfDef : '.' I F D E F;
IfDefM : '.' I F D E F M;
IfEq : '.' I F E Q;
IfExists : '.' I F E X I S T S;
IfGr : '.' I F G R;
IfGrEq : '.' I F G R E Q;
IfLe : '.' I F L E;
IfLeEq : '.' I F L E E Q;
IfNDef : '.' I F N D E F;
IfNDefM : '.' I F N D E F M;
IfNEq : '.' I F N E Q;
IncBin : '.' I N C B I N;
IncDir : '.' I N C D I R;
Include : '.' I N C L U D E;
Input : '.' I N P U T;
Macro : '.' M A C R O;
MemoryMap : '.' M E M O R Y M A P;
Org : '.' O R G;
OrgA : '.' O R G A;
OutName : '.' O U T N A M E;
Printt : '.' P R I N T T;
Printv : '.' P R I N T V;
RamSection : '.' R A M S E C T I O N;
Redefine : '.' R E D E F I N E;
Redef : '.' R E D E F;
Repeat : '.' R E P E A T;
Rept : '.' R E P T;
RomBankMap : '.' R O M B A N K M A P;
RomBanks : '.' R O M B A N K S;
Seed : '.' S E E D;
Section : '.' S E C T I O N;
Shift : '.' S H I F T;
Slot : '.' S L O T;
Struct : '.' S T R U C T;
Sym : '.' S Y M;
Symbol : '.' S Y M B O L;
Unbackground : '.' U N B A C K G R O U N D;
Undefine : '.' U N D E F I N E;
Undef : '.' U N D E F;
Word : '.' W O R D;

ARGS : A R G S;
ALIGN : A L I G N;
BANK : B A N K;
BANKS : B A N K S;
BANKSIZE : B A N K S I Z E;
BANKSTOTAL : B A N K S T O T A L;
DATA : D A T A;
DEC : D E C;
DEFAULTSLOT : D E F A U L T S L O T;
DB : D B;
DS : D S;
DSB : D S B;
DSW : D S W;
DW : D W;
EXPORT : E X P O R T;
FSIZE : F S I Z E;
FILTER : F I L T E R;
FREE : F R E E;
FORCE : F O R C E;
HEX : H E X;
INSTANCEOF : I N S T A N C E O F;
INDEX : I N D E X;
MAP : M A P;
NAMESPACE : N A M E S P A C E;
OVERWRITE : O V E R W R I T E;
READ : R E A D;
RETURNORG : R E T U R N O R G;
SEMIFREE : S E M I F R E E;
SEMISUBFREE : S E M I S U B F R E E;
SIZE : S I Z E;
SKIPVAL : S K I P;
SLOT : S L O T;
SLOTSIZE : S L O T S I Z E;
START : S T A R T;
SUPERFREE : S U P E R F R E E;
SWAP : S W A P;
TO : T O;

CompareOperator
    : Greater
    | Less
    | Gequal
    | Lequal
    | Equal
    | NotEqual
    ;

Greater : '>';
Less : '<';
Gequal : '>=';
Lequal : '<=';
Equal : '==';
NotEqual : '!=';

StringLiteral
    :   '\"' StringChar* '\"'
    ;

CharLiteral
    :   '\'' CharChar '\''
    ;

Number
    :   Decimal
    |   Integer
    |   HexInteger
    |   BinaryInteger
    ;

Label
    :   (~[ \t\r\n'":;.,()\[\]\+\-*/<>]) (~[ \t\r\n'":;,\[\]()\+\-*/<>])*
    ;

DirectionalJump
    :   [\+]+
    |   [\-]+
    ;

MacroArg
    :   '\\' (Integer | '@')
    ;

Integer
    :   BaseTenDigit+
    ;

Decimal
    :   BaseTenDigit+ '.' BaseTenDigit+
    ;

HexInteger
    :   '$' (HexDigit+)
    |   (HexDigit+) 'h'
    ;

BinaryInteger
    :   '%' BinaryDigit+
    ;

fragment
BinaryDigit
    :   [01]
    ;

fragment
BaseTenDigit
    :   [0-9]
    ;

fragment
HexDigit
    :   [0-9a-fA-F]
    ;

fragment
StringChar
    :   ~["\\\r\n] | EscapeChar
    ;

fragment
CharChar
    :   ~['\\\r\n]
    ;

fragment
EscapeChar
    : '\\' ('n' | '"') | '\\'
    ;

LineComment
    :   ';' ~[\r\n]* -> skip
    ;

StarComment
    :   (NewLine '*' ~[\r\n]*) -> skip
    ;

BlockComment
    :   '/*' .*? '*/' -> skip
    ;

Whitespace : (' ' | '\t')+ -> skip;


NewLine : ('\r' | '\r\n' | '\n');


