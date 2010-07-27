\ Restore.f - Pulled out of OkadWork.cf blocks

\ Copyright (c) 2010 Dennis Ruffer

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

CREATE cfca 0 , \ address of compressed allocation
CREATE ebx 0 ,
CREATE ecx 0 ,

: 2*d ( n -- n )   DUP 32 ecx @ - RSHIFT  ebx @ ecx @ LSHIFT  + ebx ! ;
: 2*c ( n -- n' )   ecx @ LSHIFT ;

CREATE [na] 26 , \ bits remaining in source word
CREATE [nb] -6 , \ bits remaining in ebx
CREATE [h] 67510272 , \ destination address
CREATE [an] 0 ,
CREATE [aa] 67977026 ,
CREATE [nz] 4 ,

: NEW ( 32-bits in current word )   [aa] @ @ [an] !
	1 CELLS [aa] +!  32 [na] ! ;
: ?NEW ( fetch new word if necessary )   [na] @ 0= IF  NEW  THEN ;
: SHIFT ( n -- n ) ( into ebx, decrement nb )
	DUP NEGATE DUP [nb] +!  [na] +!  ecx !
	[an] @ 2*d 2*c [an] ! ;
: BITS ( n -- ) ( shift bits into ebx. overflow into next word )
	?NEW DUP NEGATE [na] @ +  DUP 0< IF
		DUP >R + SHIFT NEW R> NEGATE SHIFT
	ELSE  DROP SHIFT  THEN ;

: h, ( n -- ) ( store at destination )   [h] @ !  1 CELLS [h] +! ;
: TBITS ( n n -- ) ( fill ebx with tag )   [nb] @ 8 + ecx !  2*c OR h, ;

: TZ ( n n -- n ? )   OVER [nz] !  DUP NEGATE >R + ebx @
	R> 0 DO  DUP 1 AND IF
			2DROP  UNLOOP  [nz] @ 0 EXIT
		THEN  2/
	LOOP  ebx ! DUP [nz] @ INVERT + INVERT [nb] +!  1 ;

: ?FULL ( n -- n ) ( is there room in ebx? )
	[nb] @ DUP AND DUP 0< IF
		TZ IF  EXIT  THEN
		DUP >R  4 - [nb] +!  TBITS
		0 DUP R> DUP INVERT 29 + [nb] !
	ELSE  DROP  THEN ;

: CHR ( -- n 1 | 0 ) \ examine high bits; shift 4, 5 or 7 bits
	0 ebx ! ( ?NEW )  4 BITS ebx @ 8 AND IF
		ebx @ 4 AND IF
			3 BITS 7 1 EXIT
		THEN  1 BITS 5 1 EXIT
	THEN  4 ebx @ 15 AND IF  1 EXIT
	THEN  DROP 0 ;
: CHRS ( n -- n ) \ shift characters until 0
	CHR IF  ?FULL ecx !  2*c ebx @ OR RECURSE  THEN ;
: WRD ( n -- ) \ shift characters, then tag
	28 [nb] !  DUP CHRS TBITS ;

: t, ( -- )   -4 [nb] !  ebx @ TBITS ;
: SHORT ( n -- ) ( 28-bit value+tag )   28 BITS t, ;
: 32BITS ( -- ) ( for values )   16 BITS  16 BITS  ebx @ h, ;
: LITRAL ( n -- ) \  1-bit base base, tag. value in next word
	0 ebx !  1 BITS t,  32BITS ;
: VAR ( n -- ) ( word, value )   WRD 32BITS ;

: TAG ( -- n 1 | 0 ) \ vector
        ebx @ 15 AND DUP
        DUP  0 = IF  2DROP          0 EXIT  THEN
        DUP  1 = IF   DROP  WRD     1 EXIT  THEN
        DUP  2 = IF   DROP  LITRAL  1 EXIT  THEN
        DUP  3 = IF   DROP  WRD     1 EXIT  THEN
        DUP  4 = IF   DROP  WRD     1 EXIT  THEN
        DUP  5 = IF   DROP  LITRAL  1 EXIT  THEN
        DUP  6 = IF   DROP  SHORT   1 EXIT  THEN
        DUP  7 = IF   DROP  WRD     1 EXIT  THEN
        DUP  8 = IF   DROP  SHORT   1 EXIT  THEN
        DUP  9 = IF   DROP  WRD     1 EXIT  THEN
        DUP 10 = IF   DROP  WRD     1 EXIT  THEN
        DUP 11 = IF   DROP  WRD     1 EXIT  THEN
        DUP 12 = IF   DROP  VAR     1 EXIT  THEN
        DUP 13 = IF   DROP  SHORT   1 EXIT  THEN
        DUP 14 = IF   DROP  WRD     1 EXIT  THEN
        DUP 15 = IF   DROP  SHORT   1 EXIT  THEN ;

: WRDS ( ?new -- ) \ examine tags
	4 BITS TAG IF  RECURSE  THEN ;

: BLOCKS ( blks -- bytes)   1024 * ;
: CFBLOCK ( blk -- addr)   BLOCKS CODE-SPACE + ;
: ERASEBLKS ( b n -- )   >R CFBLOCK R> BLOCKS ERASE ;

: BLOCK-RANGE ( a n n -- ) \ process each block
	OVER CFBLOCK [h] !  DUP >R ERASEBLKS  [aa] !  0 [na] !
	R> 0 DO  WRDS
		[h] @ CODE-SPACE - 1024 + -1024 AND
		CODE-SPACE + [h] !
	LOOP ;

: ns ( -- n )   18 CFBLOCK 1 CELLS + ;    \ compressed if negative
: cfc ( -- n )   CP @ CODE-SPACE - ;      \ size of compressed file
: nblk ( -- n )   18 CFBLOCK 3 CELLS + ;  \ size of uncompressed file

: RESTORE ( -- ) \ restore compressed blocks
	ns @ 0< IF  nblk @ BLOCKS CODE-LENGTH @ > ABORT" Too big!"
		36 CFBLOCK  HERE DUP cfca !  cfc 36 BLOCKS - DUP ALLOT
		MOVE  cfca @ 36 nblk @ OVER - BLOCK-RANGE
		nblk @ BLOCKS CODE-SPACE + CP !
	THEN ;
