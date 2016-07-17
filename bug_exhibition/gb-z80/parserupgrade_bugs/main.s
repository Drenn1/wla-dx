
.MEMORYMAP
DEFAULTSLOT 0
SLOTSIZE $2000
SLOT 0 $0000
SLOT 1 $2000
SLOT 2 $4000
SLOT 3 $6000
SLOT 4 $A000
.ENDME

.ROMBANKMAP
BANKSTOTAL 4
BANKSIZE $2000
BANKS 4
.ENDRO

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; main
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

.macro macro1
	.db \1&$ff \2|(\1>>8)
.endm

.macro macro2
	.db \1&$ff
	.db \2|(\1>>8)
.endm

.ORGA $0150

	; Error
	macro1 $108 ($48)

	; Works dandy
	macro1 $108 $48

	; Works dandy
	macro2 $108 ($48)
