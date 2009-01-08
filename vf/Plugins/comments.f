\ comments.f - Support for executing keywords within comments

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

[defined] comments.version 0= [IF]

2 constant comments.version

wordlist constant comments-wordlist

: comments   forth-wordlist
   host-wordlist
   comments-wordlist
      3 set-order  definitions ;  immediate

host variable save-in

: ( ( -- )      \ parse comments for extensions
   begin
      >in @  [char] ) parse nip
      >in @ dup save-in ! rot dup >in ! - =   \ is there no delimter?
      >r depth >r
      begin
         >in @ save-in @ <
      while
         bl word dup count comments-wordlist search-wordlist if
            nip execute
         else
            number drop
         then
      repeat
      depth r> - ?dup if
         dup 0< abort" Stack underflow in comment"
         0 do  drop  loop
      then
   r> while
      refill 0= abort" Error refilling comment stream"
   repeat
   save-in @ >in !
; immediate

target
-warning
:t ( ( -- )   host postpone ( ; immediate
+warning
forth

[THEN]
