\ testSim.f  run the simulator to test machine Forth algorithms

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

forth
v.VF +include" Plugins/links.f"  links.version 2 checkPlugin
[defined] TestCase 0= [IF] v.VF +include" Plugins/xUnit.f" [THEN]
v.VF +include" Plugins/comments.f"  comments.version 2 checkPlugin

[defined] tesSim.version 0= [IF]

2 constant testSim.version

[defined] 'step 0= [IF]
    cr .( This plugin works best with a hook in T18's step logic that looks like this: )
    cr .( variable 'step   0 'step ! )
    cr .( )
    cr .( : +time   time 2@  1 m+  time 2! ; )
    cr .( : /step   +time  #nodes 0 do  i node !  /clock recall  loop ; )
    cr .( : step   reset-slog  node @ >r  +time )
    cr .(    #nodes 0 do  i node !  \clock recall  loop )
    cr .(    'step @ ?dup if  execute  then )
    cr .(    /step  r> node ! ; )
    cr \ 'step drop
[THEN]

v.VF +include" Plugins/TestSuite.f" \ The documentation for this

variable ignore-.?. \ true ignore-.?. !

variable assertions  0 assertions !

0   xField assertion-link       \ host address of next assertion
    xField assertion-node       \ node where assertion is found
    xField assertion-trigger    \ target address of assertion
    xField assertion-method     \ test method of assertion
    xField assertion-exec       \ test function to execute
constant |assertion|

: .assertions ( -- )   assertions
    begin  @link ?dup while  >r  cr
        ." node=" r@ assertion-node ?
        ." trigger=" r@ assertion-trigger @
            base @ hex swap u. base ! r>
    repeat ;

: >trigger ( adr slot rest -- x )
    rot 2 lshift  rot + 2 lshift  + ;

: add-assertion ( -- a )   align here >r
    assertions <link  |assertion| 1 cells - allot
    host node @ r@ assertion-node !
    here  slot @ dup 0= if
        swap 1+ swap  then  0 >trigger
    r@ assertion-trigger !  r> ;

host

: .dstack ( -- )   cr
    sp @  #stk 0
    do  cell + dup sp =
        if  drop s cell +
        then  dup @ 6 u.r
    loop  drop
    s @ 6 u.r  t @ 6 u.r  space ;

: .rstack ( -- )   cr 6 spaces
    rp @  #stk 0
    do  cell + dup rp =
        if  drop r cell +
        then  dup @ 6 u.r
    loop  drop
    r @ 6 u.r  space ;

: matchAssertion ( x x -- flag )   2dup = dup >r
    if \ cr ."  Assert @ Node " node @ 2 u.r ."  trigger " dup .
    else  over $1FFC and  over $1FFC and =
        if \ cr ." ~Assert @ Node " node @ 2 u.r ."  trigger " dup . ." <> " over .
            opcode 4 = if  \ exception for unext
                dup 3 and 1 = if  r> 0= >r  then  then
    then  then  2drop  r> ;

: TestAssertions ( -- )     base @ >r hex  node @ >r  assertions
    begin  @link ?dup while  >r
        r@ assertion-node @ node !
        r@ assertion-trigger @
		pc @  slot @  rest 2@ d>s
        [undefined] 'step [IF]
            dup -1 = if  1+  then
		[THEN]  >trigger matchAssertion
        if  r@ assertion-method @ ?dup
            if  r@ assertion-exec @
                r@ assertion-trigger @
                rot test 2drop
            else  ignore-.?. @ 0= if  .dstack
                r@ assertion-exec ? ." .?."
        then  then  then  r>
        errorCount @ abort" failure detected" \ comment out to see all failures
    repeat  r> node !  r> base ! ;

[defined] 'step [IF]
    ' TestAssertions 'step !
[THEN]

-warning

comments
: assert: ( -- flag )   forth
    add-assertion self over assertion-method !
    s"  ;" dup >r  [char] ; word count  dup r> + >r
    s" :noname " dup r> + dup >r allocate throw dup >r
    2dup + >r  swap cmove r>
    2dup + >r  swap cmove r>
    swap cmove  get-order  r> r> over >r  postpone host
    evaluate >r set-order r> r> free throw
    ( a xt ) swap assertion-exec ! ; immediate

comments
: .?. ( n -- )   forth
    add-assertion 0 over assertion-method !
    ( n a ) assertion-exec ! ; immediate

+warning

host

[defined] xFinished 0= [IF] variable xFinished

: continue ( -- )   begin
      [undefined] 'step [IF]
          TestAssertions  [THEN]
      step  xFinished @ 0> 0=  key? or
   until  key? if  key abort"  type: continue"  then ;
: goes ( n -- )   xFinished !  continue ;

: FinishTests ( -- true )   -1 xFinished +!  true ;
[THEN]

: autoTerminate ( -- )
    errorCount @ IF
        abort  ELSE  bye    \ exit with error flag
    THEN ;
[THEN]
