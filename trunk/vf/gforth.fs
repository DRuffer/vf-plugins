\ VentureForth application launcher for gforth in Mac OS X or Windows

\ Put in project.vfp:
\ #! /usr/bin/env gforth
\ [undefined] v.VF [IF]
\    S" gforth" ENVIRONMENT? [IF]
\       warnings off 2drop include ../../vf/gforth.fs warnings on
\ [THEN] [THEN]

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

: ,REL ( n -- )   , ;
: @REL ( a -- n )   @ ;
: @+ ( a -- a' n )   DUP CELL+ SWAP @ ;
: zcount ( a -- a n )   DUP DUP  BEGIN  COUNT 0= UNTIL  1- SWAP - ;
: -? ; \ Not quite sure how to do this one yet

: $+ ( cs1 u1 cs2 u2 -- cs1 u1+u2 )
    >R >R  2DUP CHARS +  R> SWAP R@ CHARS MOVE  R> + ;

s" OS-TYPE" environment? [IF]
    2dup s" cygwin" compare 0= [IF]
        4 constant HostForth     \ host is gForth Windows = GFWhost
    [ELSE]
    drop s" darwin" rot over compare 0= [IF]
        13 constant HostForth    \ host is gForth OSX = GFXhost
    [ELSE]
        5 constant HostForth     \ host is gForth Linux = GFLhost
[THEN] [THEN] [THEN]

13 constant GFXhost     \ host is gForth OSX

FPATH+ ~+/

CREATE v.VF.path
    s" PWD" getenv ?DUP [IF]
        CHAR / scan-back 1- CHAR / scan-back
        DUP CHAR+ ALLOT  v.VF.path place
    [ELSE]  DROP ," C:/IntellaSys/VentureForth/"
    [THEN]  v.VF.path COUNT s" vf/" DUP ALLOT $+ ALIGN
    v.VF.path C! DROP

: v.VF ( -- a u )   v.VF.path COUNT ;

: \\ begin refill 0= until ;

HostForth GFXhost = [IF]
    \ still working on these
    : sys_open ;
    : sys_close ;
    : sys_ioctl ;
[THEN]

variable 'logFileName  ' 2drop 'LogFileName !

PAD 0 v.VF $+  s" HostConfig.f" $+ INCLUDED

HostForth GFWhost = [IF] \ USB GForth Windows host after patching
    v.VF +include" USBdriveGW.f" [THEN]

HostForth GFXhost = [IF] \ USB GForth OSX host after patching
    v.VF +include" USBdriveGX.f" [THEN]
