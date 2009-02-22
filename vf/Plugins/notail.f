\ notail.f - Selectively disable tail recursion in the optimizing compiler

\ Copyright (c) 2009 Rick VanNorman

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

\ This utility is required by the GLOSSARY and any application that needs
\ this organized method of managing files. If most tasks use it, it should
\ be loaded in the system electives.  Then the applications should begin
\ with EMPTY instead of FILE-TASK MARKER FILE-TASK .

0 [IF] ----------------------------------------------------------------------
NO-TAIL-RECURSION is used just like IMMEDIATE, and disables the
tail recursion behavior of the last defined word.

The actual rule compiled for the optimizing compiler is
equivalent to

OPTIMIZE ANY foo WITH foo WITH /OPT


Note that the same effect could have been obtained via a rule
which triggered on "foo ;" instead of "ANY FOO" but this would
require the optimizer to evaluate the rule on every ";" to see
if it was preceeded by the reference to foo.
---------------------------------------------------------------------- [THEN]

[defined] notail.version 0= [IF]

1 constant notail.version

[defined] OPTIMIZING-COMPILER [IF]

OPTIMIZING-COMPILER +ORDER

: (NO-TAIL-RECURSION) ( -- )
  0 RULE@ 3 CELLS + @ (COMPILE,) /OPT ;

: NO-TAIL-RECURSION ( -- )
  LAST CELL+ CELL+ @ CODE>  ['] ANY  OVER  OPTIMIZING  >LINK ,
  ['] (NO-TAIL-RECURSION) ,  , ;

OPTIMIZING-COMPILER -ORDER

0 [IF] \ simple example:

: EMBARK ( n n -- )   R>  SWAP >R  SWAP >R  >R ; NO-TAIL-RECURSION
: DEBARK ( -- n n )   R>  R> SWAP  R> SWAP  >R ; NO-TAIL-RECURSION

: TEST ( -- 3 4 )
  1 2 3 4 EMBARK DROP DROP DEBARK ;
[THEN]
[ELSE] : NO-TAIL-RECURSION ; [THEN]
[THEN]
