\ strings.f - String support

\ Copyright (c) 2009 Dennis Ruffer

\ Permission is hereby granted, free of charge, to any person obtaining a copy
\ of this software and associated documentation files (the "Software"), to deal
\ in the Software without restriction, including without limitation the rights
\ to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
\ copies of the Software, and to permit persons to whom the Software is
\ furnished to do so, subject to the following conditions:

\ The above copyright notice and this permission notice shall be included in
\ all copies or substantial portions of the Software.

\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
\ IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
\ FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
\ AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
\ LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
\ OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
\ THE SOFTWARE.

v.VF +include" Plugins/Plugins.f"  Plugins.version 6 checkPlugin
v.VF +include" Plugins/numbers.f"  numbers.version 3 checkPlugin

[defined] strings.version 0= [IF]

3 constant strings.version

[defined] -warning [IF] -warning [THEN]
: append ( from len to -- )   2DUP >R >R  COUNT + SWAP MOVE  R> R@ C@ + R> C! ;
: place ( from len to -- )   0 OVER C! SWAP 255 MIN SWAP append ;
[defined] +warning [IF] +warning [THEN]

: prepend ( from len to -- )   dup count  dup 1+ allocate throw  dup >r place
    dup >r place  r> r@ count rot append  r> free throw ;

: cappend ( char to -- )   DUP >R COUNT + C! R@ C@ 1+ R> C! ;
: ,string ( str len -- a )   HERE DUP >R OVER 1+ ALLOT place R> ;
: substitute ( str len to-chr from-chr -- str len )
    2OVER OVER + SWAP ?DO
        DUP I C@ = IF
            OVER I C!
        THEN
    LOOP  2DROP ;

: $c, ( str len -- )   OVER + SWAP ?DO  I C@ C,  LOOP ;

: >here ( a n -- a )   HERE C!  HERE COUNT MOVE  HERE ;
: >asciz ( a n -- a )   >here  0 HERE COUNT + C!  1+ ;      
: >count ( a -- n )   DUP  BEGIN  COUNT 0= UNTIL  1- SWAP - ;

[defined] -warning [IF] -warning [THEN]
: ," ( "string"<"> -- )   [char] " WORD COUNT DUP C, $C, ;

: null? DUP 0= IF NIP DUP THEN ;
[defined] +warning [IF] +warning [THEN]

: $create ( str len -- )   dup 8 + allocate throw >r
    s" create " r@ place  r@ append  r@ count evaluate
    r> free throw ;

: left-parse-string ( str len char -- rstr rlen lstr llen ) \ IEEE 1275 parser from left
    OVER IF
        >R 2DUP R> ROT ROT OVER + SWAP 2DUP = IF  2DROP  ELSE  DO
            DUP I C@ = IF
                DROP 2DUP + I 1+ SWAP OVER - null?      ( rstr rlen | 0 0 )
                2SWAP DROP I OVER - null?           ( lstr llen | 0 0 )
                UNLOOP EXIT  THEN
        LOOP THEN  DROP 0 0 2SWAP
    ELSE  DROP 0 0 2SWAP  THEN ;

: right-parse-string ( str len char -- rstr rlen lstr llen ) \ parse from right
    >R 2DUP 0 BEGIN                 \ keep parsing from left
        R@ SWAP >R left-parse-string        \  as far as we can
        2OVER NIP WHILE  R> + 1+ NIP
    REPEAT  2DROP 2DROP             \ we really don't care about its result
    R@ IF  OVER R@ + SWAP R@ - ROT R@ 1-        \ update to point to last one found
    ELSE  0 0 2SWAP                             ( 0 0 lstr llen )
    THEN  R> R> 2DROP ;

0 [IF]
: macro ( -name- )  \ create multi-line string for evaluation later
    CREATE  HERE >R  0 C,  BEGIN BEGIN
            BL WORD COUNT DUP 0= WHILE
                2DROP REFILL 0= IF R> DROP EXIT THEN
        REPEAT 2DUP S" end" COMPARE WHILE
        DUP 1+ ALLOT R@ append
        BL R@ cappend
    REPEAT  R> DROP 2DROP ;

macro tryMacro
    line one
    line two
end
[THEN]
[THEN]
