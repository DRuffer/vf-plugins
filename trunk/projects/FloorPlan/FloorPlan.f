cr .( FloorPlan.f ) \ Example of a Floor Plan application

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

v.VF +include" Plugins/idForth.f"  idForth.version 5 checkPlugin
\ v.VF +include" Plugins/FileNames.f"  FileNames.version 3 checkPlugin
v.VF +include" c7Dr03/romconfig.f" \ Program is meant to run on 7Dr3, FORTHdrive
v.VF +include" Plugins/FloorPlan.f"  FloorPlan.version 9 checkPlugin

/projectFolder \ Set project folder name

0 value iter \ Execution options are not really used in this version

\ Floor plan pages
( <title exterior> )    \ shows measurement of exterior nodes

\ Manual measurements (counts-watcher) taken on 30 Dec 08
00 to FpNode ( <function 12020-1> <function 11955-6>  )
01 to FpNode ( <function 11984-2>  <function 11932-7>  <function ?-0> )
02 to FpNode ( <function 12055-1>  <function 12001-3>  <function 11946-8> )
03 to FpNode ( <function 12009-2>  <function 12044-4>  <function 11973-9> )
04 to FpNode ( <function 11911-3>  <function 12031-5>  <function 11978-10> )
05 to FpNode ( <function 11833-4>  <function 11869-11> )
06 to FpNode ( <function 11891-0>  <function 11946-7>  <function 11868-12> )
07 to FpNode ( <function 11945-1>  <function 11995-6>  )
             ( <function 11952-8>  <function 11880-13> )
08 to FpNode ( <function 11939-2>  <function 12003-7>  )
             ( <function 11994-9>  <function 11891-14> )
09 to FpNode ( <function 12041-3>  <function 12082-8>  )
             ( <function 12200-10> <function 12064-15> )
10 to FpNode ( <function 11839-4>  <function 11855-9>  )
             ( <function 11937-11> <function 11857-16> )
11 to FpNode ( <function 11991-5>  <function 12001-10> <function 11905-17> )
12 to FpNode ( <function 11930-6>  <function 12001-10> <function 11905-17> )
13 to FpNode ( <function 11896-7>  <function 11931-12> <function 11894-14> )
14 to FpNode ( <function 11997-8>  <function 12042-13> )
             ( <function 12071-15> <function 11902-20> )
15 to FpNode ( <function 11894-9>  <function 11880-14> )
             ( <function 11983-16> <function 11887-21> )
16 to FpNode ( <function 11933-10> <function 11887-15> )
             ( <function 11903-17> <function 11790-22> )
17 to FpNode ( <function 11923-11> <function 11907-16> <function 11771-23> )
18 to FpNode ( <function 11988-12> )
20 to FpNode ( <function 11997-14> <function 12094-21> )
21 to FpNode ( <function 11946-15> <function 11869-20> <function 11934-22> )
22 to FpNode ( <function 12038-16> <function 12030-21> <function 11950-23> )
23 to FpNode ( <function 11981-17> <function 11928-22> )

include FloorPlan.vf

( exterior ) svgFloorPlan pdfFloorPlan
