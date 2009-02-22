\ links.f - Linked lists

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

[defined] links.version 0= [IF]

3 constant links.version

[defined] -warning [IF] -warning [THEN]

\ @LINK  and  !LINK  do relocation translation, if needed.

: @LINK ( a -- a )   [defined] @REL [IF]
        @REL  [ELSE]  @  [THEN] ;
: !LINK ( a1 a2 -- )   [defined] !REL [IF]
        !REL  [ELSE]  !  [THEN] ;
: ,LINK ( a -- )   [defined] ,REL [IF]
        ,REL  [ELSE]  ,  [THEN] ;

\ LINKS  searches the linked list until it finds the last entry
\    in the list (the one with a 0 link).

: LINKS ( a -- a' )   BEGIN  DUP @LINK ?DUP WHILE  NIP  REPEAT ;

\ >LINK  adds the top of the dictionary to the given linked list.

: >LINK ( a -- )   ALIGN HERE  OVER @LINK ,LINK  SWAP !LINK ;

\ <LINK  adds the top of the dictionary to the end of the given
\    linked list.

: <LINK ( a -- )   LINKS  >LINK ;

\ UNLINK  breaks the link of the given entry, resetting it to the link
\ pointed to by the element on top of the stack.

: UNLINK ( a a' -- a )   @LINK OVER !LINK ;

\ CALLS  runs down a linked list, executing the high level code
\    that follows each entry in the list.

: CALLS ( a -- )
   BEGIN
      @LINK ?DUP WHILE
      DUP >R  1 CELLS + @LINK EXECUTE  R>
   REPEAT ;

[defined] +warning [IF] +warning [THEN]

[THEN]
