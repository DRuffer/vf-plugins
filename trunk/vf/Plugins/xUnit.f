\ xUnit from Kent Beck's Test-Driven Development By Example
\ Publisher: Addison Wesley Professional
\ Pub Date: November 08, 2002
\ Print ISBN-10: 0-321-14653-0
\ Print ISBN-13: 978-0-321-14653-3

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

: logName ( -- str len )   s" TestSuite.log" ;

variable runCount       0 runCount !    \ holds number of tests started
variable errorCount     0 errorCount !  \ holds number of tests that failed

-warning
0 value self            \ holds method we are working on
+warning

: xField ( _ offset -- offset' )
    create dup , cell+
    does> ( a -- a' )
        @ + ;

-warning
0   xField Method       \ address of counted string
    xField Run          \ execution vector to Run the test
    xField setUp        \ execution vector to setUp the test
    xField tearDown     \ execution vector to tearDown the test
constant |xUnit|
+warning

create logBuffer   128 allot

: log ( str len -- )
    logName R/W OPEN-FILE if  drop
        logName R/W CREATE-FILE abort" Can't create log file" >r
    else  dup >r FILE-SIZE abort" Can't get log file size"
        r@ REPOSITION-FILE abort" Can't find end of log file"
    then  logBuffer 128 blank  >r logBuffer r@ cmove
    self Method @ count tuck  logBuffer r@ + 1+ swap cmove
    logBuffer swap r> + 1+ r@ WRITE-LINE abort" Can't write to log file"
    r> CLOSE-FILE abort" Can't close log file" ;

: testStarted ( -- )   1 runCount +! ;
: testFailed ( -- )   1 errorCount +!  s" Fail" log ;

: WasRun ( -- )   self Run @ catch
    s" Run" logBuffer over compare or
    if  testFailed  then ;

: testSetUp ( -- )
    self setUp @ ?dup if  catch abort" test setUp failed"
        s" setUp" logBuffer over compare abort" test didn't setUp"
    then ;

: testTearDown ( -- )
    self tearDown @ ?dup if  catch abort" test tearDown failed"
        s" tearDown" logBuffer over compare abort" test didn't tearDown"
    then ;

: TestCaseTest ( -- )   testStarted testSetUp WasRun testTearDown ;

: TestCase ( method -- )   to self ;

: summary ( -- )   runCount ? ." run, " errorCount ? ." failed " ;

-warning
: test ( method -- )   TestCase TestCaseTest ;
+warning

: xUnit: ( _ -- ) \ Usage: xUnit: <name>
    >in @  create  here dup to self  |xUnit| dup allot erase
    >in !  bl word count  here self Method !
    dup c,  here swap dup allot cmove ;

: simUnit: ( _ -- )   xUnit: \ s" ../TestSuite/Support/simUnit.f" included ;
    \ This follows the declaration of the xUnit method name-NN-AAA
    \ The NN will be overwritten with the node number
        s" node @ 0 <# # # #> self Method @ count + 6 - swap move" evaluate

    \ The execution token is bound at compile time
    s" Run: ( xt addr -- xt addr )   over execute 0= if abort then ;Run" evaluate

    \ The AAA will be overwritten with the shifted address/slot/rest
    s" setUp: ( addr -- addr )   base @ >r hex" evaluate
        s" dup 0 <# # # # #> self Method @ count + 3 - swap cmove" evaluate
        s" r> base ! ;setUp" evaluate ;

-warning
: +Run  ( -- )   s" Run" log ;
:  Run: ( -- )   self Run @ abort" can't redefine Run" :noname ;
: ;Run  ( -- )   postpone +Run postpone ; self Run ! ; immediate

: +setUp  ( -- )   s" setUp" log ;
:  setUp: ( -- )   self setUp @ abort" can't redefine setUp" :noname ;
: ;setUp  ( -- )   postpone +setUp postpone ; self setUp ! ; immediate

: +tearDown  ( -- )   s" tearDown" log ;
:  tearDown: ( -- )   self tearDown @ abort" can't redefine tearDown" :noname ;
: ;tearDown  ( -- )   postpone +tearDown postpone ; self tearDown ! ; immediate
+warning

0 [IF] \ Test example
xUnit: testMethod ( -- method )

Run: ( -- ) ;Run

setUp: ( -- ) ;setUp

tearDown: ( -- ) ;tearDown

testMethod test

summary
[THEN]
