\ cfdis.f - Disassembler support for OkadWork.cf the arrayForth for GA144-1.10

: <?> ( n -- )   .S DROP S" <?>" TYPE CR ;	\ a fence post to isolate issues

INCLUDE Restore.f

\ ******************************************************************************
\ The following are used to fetch data that is in known Endian format.  E.g.
\ in file system structures or network packets.  These words work on un-aligned
\ entities.

: 1C!-LE ( x a n -- )   BEGIN ?DUP WHILE
		1- ROT DUP 8 RSHIFT SWAP 2OVER DROP C! ROT 1+ ROT
	REPEAT 2DROP ;

: 1C!-BE ( x a n -- )   BEGIN ?DUP WHILE
        1- ROT DUP 8 RSHIFT SWAP 2OVER +    C! ROT    ROT
    REPEAT 2DROP ;

: 1C@-LE ( a n -- x )   0 SWAP BEGIN ?DUP WHILE
 		1- ROT 2DUP +      C@ >R ROT 8 LSHIFT R> + ROT
 	REPEAT  SWAP DROP ;

: 1C@-BE ( a n -- x )   0 SWAP BEGIN ?DUP WHILE
        1- ROT DUP 1+ SWAP C@ >R ROT 8 LSHIFT R> + ROT
    REPEAT  SWAP DROP ;

: SIGN-EXTEND ( x n -- x' )  32 SWAP - DUP >R
	LSHIFT  R> 0 DO  2/  LOOP ;

: @-LE ( a -- x )   4 1C@-LE ;
: !-LE ( x a -- )   4 1C!-LE ;

: W@-BE ( a -- x )   2 1C@-BE ;
: W!-BE ( x a -- )   2 1C!-BE ;

: ?? ( "name" -- flag )  BL WORD FIND SWAP DROP 0= 0= ;
: uses ( flag -- )  0= IF POSTPONE \ THEN ;

?? CTRL 0= uses : CTRL CHAR 31 AND ;
?? [CTRL] 0= uses : [CTRL] CTRL POSTPONE LITERAL ; IMMEDIATE

?? ForGForth uses ALSO
ASSEMBLER

: :COMMENT ( x -line- )   HERE [CTRL] J PARSE $, $@ ROT COMMENT ;

: .ICON-ROW ( x -- )   BASE @ >R  2 BASE !  S>D
	<#  16 0 DO  #  LOOP  #>  TYPE  R> BASE ! ;

16 CONSTANT ICON-COLUMNS
24 CONSTANT ICON-ROWS

: |ICON| ( -- n )   ICON-COLUMNS 8 / ICON-ROWS * ;

: IH. ( n -- a n )   0 <HEX  <# # #>  HEX>  TYPE SPACE ;

: DUMP-ICONS ( a2 a1 -- )   DUP S" icons " CR+GENERIC  2DUP - |ICON| /
	0 DO  I  ICON-ROWS 0 DO  CR  4 0 DO  DUP I +
				J 0= IF  16 / IH.  ELSE
					J 1 = IF  16 MOD IH.  ELSE
						DROP 2 SPACES  THEN  THEN
				OVER |ICON| I * + J 2* + W@-BE .ICON-ROW  SPACE
		LOOP  LOOP  CR  DROP  4 |ICON| * +  4 +LOOP
	2DUP - IF  (DUMP-B)  ELSE  2DROP  THEN ;

: DIS-ICONS ( a1 a2 -- )   TARGET>HOST SWAP TARGET>HOST
	DUP NEXT-CUT ! DUMP-ICONS ;
: -icons ( a n -- )   2>R ['] DIS-ICONS 2R> RANGE ;
: -icons: ( -name- )   BL WORD COUNT -icons ;
: -icons- ( -- )   NONAME$ -icons ;
' DIS-ICONS  ' -icons:  ARE-COUPLED

\ unpack cf word to ascii text

\ 4-bit 0.xxx 0-7
\ 5-bit 10.xxx 8-15
\ 7-bit 11xx.xxx 16-47
: UNPACK ( n -- n' chr )   DUP  DUP 0<
    IF     1 LSHIFT DUP 0<
      IF   6 LSHIFT SWAP 25 RSHIFT 63 AND  16 -    \ 11xxxxx.. 16-47
      ELSE 4 LSHIFT SWAP 27 RSHIFT  7 AND  8 XOR   \ 10xxx..    8-15
      THEN
    ELSE   4 LSHIFT SWAP 28 RSHIFT  7 AND          \ 0xxx..     0-7
    THEN ;

: PRESHIFT ( n -- n' )   32 0 DO  [ HEX ]
		DUP F0000000 AND IF
			UNLOOP EXIT
		THEN  2*
	LOOP ;

: s, ( a n -- )   DUP C,  0 ?DO  COUNT C,  LOOP  DROP ;

S"  rtoeanismcylgfwdvpbhxuq0123456789j-k.z/;'!+@*,?"
CREATE cf-ii ( -- adr)   s,  0 cf-ii 1+ C!

: CH ( n -- n' chr )   0FFFFFFF0 AND UNPACK DUP cf-ii COUNT
	ROT < ABORT" invalid character" + C@ ;
DECIMAL

VARIABLE PHERE
: PAD, ( chr -- )   PHERE @ C!  1 PHERE +! ;
: PADDECODE ( n -- )   BEGIN  CH DUP WHILE PAD,  REPEAT  2DROP ;
: PADCOUNT ( n -- adr len )   PAD 1+ PHERE !
	PADDECODE PAD 1+ PHERE @ OVER - DUP PAD C! ;

: DUMP-NAMES ( a2 a1 -- )   DO  I DUP S" names " CR+$
		@-LE PRESHIFT PADCOUNT TYPE SPACE
	0 CELL+ +LOOP  CR ;
: DIS-NAMES ( a1 a2 -- )   TARGET>HOST SWAP TARGET>HOST
	DUP NEXT-CUT !  DUMP-NAMES ;
: -names ( a n -- )   2>R ['] DIS-NAMES  2R> RANGE ;
: -names: ( -name- )   BL WORD COUNT -names ;
: -names- ( -- )   NONAME$ -names ;
' DIS-NAMES  ' -names:  ARE-COUPLED

VARIABLE curcolor   0 curcolor ! \ color of current token

: TRANSITION ( new -- x )   \ check against multiple transitions
   ( new    <-- )  curcolor @
    OVER 14 <>  OVER 14 =  AND IF  S"  }" TYPE CR  THEN   \  b -> ~b
    OVER 13 <>  OVER 13 =  AND IF  S"  }" TYPE     THEN   \  g -> ~g
    OVER  9 <>  OVER  9 =  AND IF  S"  )" TYPE     THEN   \  w -> ~w
    OVER  1 <>  OVER  1 =  AND IF  S"  ]" TYPE     THEN   \  y -> ~y
    OVER  7 <>  OVER  7 =  AND IF  S"  >" TYPE     THEN   \  c -> ~c
    OVER  7 =   OVER  7 <> AND IF  S"  <" TYPE     THEN   \ ~c ->  c
    OVER  1 =   OVER  1 <> AND IF  S"  [" TYPE     THEN   \ ~y ->  y
    OVER  9 =   OVER  9 <> AND IF  S"  (" TYPE     THEN   \ ~w ->  w
    OVER 13 =   OVER 13 <> AND IF  S"  {" TYPE     THEN   \ ~g ->  g
    OVER 14 =   OVER 14 <> AND IF  S"  {" TYPE     THEN   \ ~b ->  b
    SWAP curcolor ! ;

: NEWC ( new -- )   DUP curcolor @ XOR IF  TRANSITION  THEN  DROP ;

: gnn ( a -- a' n )   DUP >R  CELL+  R> @-LE ;
: n32 ( a x -- a' n )   DROP gnn ;
: n27 ( n -- n' )   2/ 2/ 2/ 2/ 2/ ;

HEX
: .NUMBER ( n -- )   DUP 1F AND
	DUP 02 = IF DROP S" D# " TYPE n32 0 .R EXIT THEN \  y: execute 32-bit dec
	DUP 12 = IF DROP S" H# " TYPE n32  H.  EXIT THEN \ dy: execute 32-bit hex
	DUP 05 = IF DROP S" D# " TYPE n32 0 .R EXIT THEN \  g: compile 32-bit dec
	DUP 15 = IF DROP S" H# " TYPE n32  H.  EXIT THEN \ dg: compile 32-bit hex
	DUP 06 = IF DROP S" d# " TYPE n27 0 .R EXIT THEN \  g: compile 27-bit dec
	DUP 16 = IF DROP S" h# " TYPE n27  H.  EXIT THEN \ dg: compile 27-bit hex
	DUP 08 = IF DROP S" d# " TYPE n27 0 .R EXIT THEN \  y: execute 27-bit dec
	DUP 18 = IF DROP S" h# " TYPE n27  H.  EXIT THEN \ dy: execute 27-bit hex
    DROP ;
DECIMAL

VARIABLE capext   0 capext !

: 1CAP ( addr -- )   DUP C@ [CHAR] a [CHAR] z 1+ WITHIN
    IF  DUP C@ 32 - SWAP C!  ELSE  DROP  THEN ;
: CAPS ( addr len -- )   0 ?DO  DUP 1CAP 1+  LOOP  DROP ;

: .WORD ( n -- )   0 capext !  PADCOUNT TYPE ;
: .CAPWORD ( n -- )   0 capext !  PADCOUNT OVER 1CAP TYPE ;
: .ALLCAPS ( n -- )   -1 capext !  PADCOUNT 2DUP CAPS TYPE ;
: .EXTENSION ( n -- )   PADCOUNT capext @ IF  2DUP CAPS  THEN  TYPE ;
: .COLONDEF ( -- )   S" : " TYPE .WORD ;
: .VARIABLE ( -- )   S" :# " TYPE .WORD gnn  SPACE 0 .R ;

HEX
: .TOKEN ( n -- )   DUP 0F AND
	DUP  0 = IF DROP               .EXTENSION EXIT THEN \ --- extension word
	DUP  1 = IF DROP  1 NEWC SPACE .WORD      EXIT THEN \ yel execute word
	DUP  2 = IF DROP  1 NEWC SPACE .NUMBER    EXIT THEN \ yel execute 32-bit
	DUP  3 = IF DROP  3 NEWC CR    .COLONDEF  EXIT THEN \ red define word
	DUP  4 = IF DROP  4 NEWC SPACE .WORD      EXIT THEN \ gre compile word
	DUP  5 = IF DROP  4 NEWC SPACE .NUMBER    EXIT THEN \ gre compile 32-bit
	DUP  6 = IF DROP  4 NEWC SPACE .NUMBER    EXIT THEN \ gre compile 27-bit
	DUP  7 = IF DROP  7 NEWC SPACE .WORD      EXIT THEN \ cya compile a macro
	DUP  8 = IF DROP  1 NEWC SPACE .NUMBER    EXIT THEN \ yel execute 27-bit
	DUP  9 = IF DROP  9 NEWC SPACE .WORD      EXIT THEN \ whi comment word
	DUP 0A = IF DROP  9 NEWC SPACE .CAPWORD   EXIT THEN \ whi Capitalized Word
	DUP 0B = IF DROP  9 NEWC SPACE .ALLCAPS   EXIT THEN \ whi ALL CAPS WORD
	DUP 0C = IF DROP 0C NEWC CR    .VARIABLE  EXIT THEN \ mag variable + number
	DUP 0D = IF DROP 0D NEWC SPACE H.         EXIT THEN \ gre compiler feedback
	DUP 0E = IF DROP 0E NEWC SPACE .WORD      EXIT THEN \ blu display word
                DROP SPACE S" { " TYPE H. S"  }" TYPE ; \ $F commented number
DECIMAL

: ABLOCK ( a -- )   DUP 1020 + SWAP  0 curcolor !
	BEGIN  2DUP >  OVER @ 0= 0=  AND WHILE  gnn .TOKEN
	REPEAT  6 NEWC  2DROP ;   \ dummy color to mark end of block

: DUMP-BLOCKS ( a2 a1 -- )   \ display blocks ready to be translated back
	CUT-SIZE @ >R  1024 CUT-SIZE !  BASE @ >R  DECIMAL
	DO  I CODE-SPACE - 1024 /  S" D# " PAD $!  DUP S>D <# #S #> PAD $+!
		1 AND IF  S"  shadow{ "  ELSE  S"  code{ "  THEN  PAD $+!
		I PAD $@ CR+$  CR  I ABLOCK  S"  }block" TYPE  CR
	1024 +LOOP  R> BASE !  R> CUT-SIZE !  CR ;

68 CONSTANT TRIM#
VARIABLE #OUT  0 #OUT !

?? ForGForth uses : GET-TYPE   'TYPE @ ;
?? ForGForth uses : SET-TYPE   'TYPE ! ;

?? ForGForth 0= uses : GET-TYPE   'TYPE >DFA @ ;
?? ForGForth 0= uses : SET-TYPE   'TYPE >DFA ! ;

: TRIM-EMIT ( c -- )   GET-TYPE  'TYPE RESTORED  SWAP
		DUP BL = IF  #OUT @ TRIM# > IF
				CR  SPACE  1 #OUT !
			THEN  BL EMIT  1 #OUT +!  ELSE
		DUP 10 = IF  10 EMIT  0 #OUT !  ELSE
		DUP EMIT  1 #OUT +!
	THEN THEN  DROP  SET-TYPE ;

: TRIM-TYPE ( a n -- )   0 ?DO  COUNT TRIM-EMIT  LOOP  DROP ;

?? ForGForth uses : GET-TRIM   ['] TRIM-TYPE ;
?? ForGForth 0= uses : GET-TRIM   'TRIM-TYPE >DFA @ ;
		
: DUMP-TRIM-BLOCKS   GET-TRIM SET-TYPE  DUMP-BLOCKS  'TYPE RESTORED ;

: DIS-BLOCKS ( a1 a2 -- )   TARGET>HOST SWAP TARGET>HOST
	DUP NEXT-CUT !  DUMP-TRIM-BLOCKS ;
: -blocks ( a n -- )   2>R ['] DIS-BLOCKS  2R> RANGE ;
: -blocks: ( -name- )   BL WORD COUNT -blocks ;
: -blocks- ( -- )   NONAME$ -blocks ;
' DIS-BLOCKS  ' -blocks:  ARE-COUPLED

PREVIOUS
