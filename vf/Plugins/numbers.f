\ numbers.f - Number parsing support

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

v.VF +include" Plugins/Plugins.f"  Plugins.version 7 checkPlugin
v.VF +include" Plugins/idForth.f"  idForth.version 6 checkPlugin

[defined] numbers.version 0= [IF]

4 constant numbers.version

: ?setbase ( addr len -- addr' len' )
   over c@ [char] $ =  if  1- swap 1+ swap  hex  then
;

: ?neg ( addr len -- addr' len' neg? )
   over c@ [char] - =  if
      1- swap 1+ swap  true
   else
     false
   then
;

[defined] -warning [IF] -warning [THEN]
: number ( c-addr - n true | false ) \ convert to unsigned single or abort
   base @ >r           ( r: base )
   count       ( addr len )
   ?neg  -rot  ( neg?  addr len)
   ?setbase
   0 0 2swap  >number            ( neg?  ud addr #unconverted )
   r> base !
   \ create fwd ref if undefined
   if  2drop 2drop  false  exit  then
   drop
   abort" Number conversion overflow"               \ abort if double
   swap if negate  $3ffff and  then  true
;
[defined] +warning [IF] +warning [THEN]

\ for testing the number words
: num-test  ( -- n ) bl word find if ." xt = " . else number then ;

: parseNumber ( str len -- n )   0 0 2swap >number 2drop drop ;

[defined] >float [IF]
: parseFloating ( str len -- F: r )   >float 0= abort" not a floating point number" ;
[THEN]

0 value Places
0 value Neg

: parseDecimal ( str len -- n*100 )   base @ >r decimal
	0 to Neg  0 0 2swap >number  dup to Places
	begin ?dup while  over c@ case
			[char] - of  true to Neg  endof
			[char] . of  dup to Places  endof
		endcase  1 /string  >number
	repeat  2drop  Places 1 max 3 swap - 0	\ assumes no more than 2 decimal places
	?do  10 *  loop  Neg if  negate
	then  r> base ! ;

[THEN]
