\ FloorPlan.f - Create PDF output of node layout

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

[defined] pdfFloorPlan.version 0= [IF]

2 constant pdfFloorPlan.version

: pdfCentered ( str len line -- )   <BT>  >r dup >r  FpNode >rectXY
    swap 33 +  maxWidth r> - textWidth 2 */ +
    swap 84 +  r> 1+ textHeight * +
    <Tf> <Td> <Tj>  <ET> ;

: pdfNumbered ( -- )   <BT>  nodeId pathId place  pathId count
    FpNode >rectXY  swap 33 +  swap 84 +  <Tf> <Td> <Tj>  <ET> ;

: pdfDirections ( -- )
    FpNode #cols /   1 and if  s" U"  else  s" D"  then  <BT>  FpNode >rectXY
    swap        0 +              swap        0 +               <Tf> <Td> <Tj>  <ET>
    FpNode #rows mod 1 and if  s" L"  else  s" R"  then  <BT>  FpNode >rectXY
    swap nodeWide +              swap            textHeight +  <Tf> <Td> <Tj>  <ET>
    FpNode #cols /   1 and if  s" D"  else  s" U"  then  <BT>  FpNode >rectXY
    swap nodeWide + textWidth -  swap nodeHigh + textHeight +  <Tf> <Td> <Tj>  <ET>
    FpNode #rows mod 1 and if  s" R"  else  s" L"  then  <BT>  FpNode >rectXY
    swap            textWidth -  swap nodeHigh + textHeight -  <Tf> <Td> <Tj>  <ET>
;


: horizontalText ( str len x y r>l -- )   >r <BT>
    textWidth  r> if  2*  then rot + swap <Tf> <Td> <Tj>  <ET> ;
: verticalText ( str len x y r>l -- )   <q textWidth swap
    if  2*  then + 10 0 0 10 2rot viewHeight swap - <cm*10> rot90
    <BT>  <Tf> 0 viewHeight <Td> <Tj>  <ET> Q> ;
: diagonal1Text ( str len x y r>l n -- )   >r <q textWidth swap
    if  2*  swap 32 + swap  then rot + swap
    10 0 0 10 2rot viewHeight swap - r> - <cm*10> rot45
    <BT>  <Tf> 0 viewHeight <Td> <Tj>  <ET> Q> ;
: diagonal2Text ( str len x y r>l n -- )   >r <q textWidth swap
    if  2*  else  swap 32 + swap  then rot + swap
    10 0 0 10 2rot viewHeight swap - r> + <cm*10> rot-45
    <BT>  <Tf> 0 viewHeight <Td> <Tj>  <ET> Q> ;

: startHMarker ( x y -- )   2dup <m>  over 60 + over 20 - <l>
                            2dup <m>  swap 60 + swap 20 + <l> ;
: endHMarker ( x y -- )     2dup <m>  over 60 - over 20 - <l>
                            2dup <m>  swap 60 - swap 20 + <l> ;

: startVMarker ( x y -- )   2dup <m>  over 20 - over 60 + <l>
                            2dup <m>  swap 20 + swap 60 + <l> ;
: endVMarker ( x y -- )     2dup <m>  over 20 - over 60 - <l>
                            2dup <m>  swap 20 + swap 60 - <l> ;

: startD1Marker ( x y -- )  2dup <m>  over 28 + over 56 + <l>
                            2dup <m>  swap 56 + swap 28 + <l> ;
: endD1Marker ( x y -- )    2dup <m>  over 56 - over 28 - <l>
                            2dup <m>  swap 28 - swap 56 - <l> ;

: startD2Marker ( x y -- )  2dup <m>  over 28 + over 56 - <l>
                            2dup <m>  swap 56 + swap 28 - <l> ;
: endD2Marker ( x y -- )    2dup <m>  over 56 - over 28 + <l>
                            2dup <m>  swap 28 - swap 56 + <l> ;

: pdfHorizontal ( str1 len1 x y x' y r>l str2 len2 -- )
    2drop >r  2over <m>  2dup <l>  r@
    if  2over startHMarker  else  2dup endHMarker
    then  2drop r> horizontalText ;
: pdfVertical ( str1 len1 x y x y' r>l str2 len2 -- )
    2drop >r  2over <m>  2dup <l>  r@
    if  2over startVMarker  else  2dup endVMarker
    then  2drop r> verticalText ;
: pdfDiagonal ( str1 len1 x y x' y' r>l str2 len2 n -- )
    -rot 2drop swap >r >r  2over <m>  2dup <l>  r> case
        0 of  r@ if  2over startD1Marker  else  2dup endD1Marker  then
            2drop r> dup if 120 else  80 then diagonal1Text  endof
        1 of  r@ if  2over startD2Marker  else  2dup endD2Marker  then
            2drop r> dup if 140 else  80 then diagonal2Text  endof
        2 of  r@ if  2over startD1Marker  else  2dup endD1Marker  then
            2drop r> dup if 120 else  80 then diagonal1Text  endof
        3 of  r@ if  2over startD2Marker  else  2dup endD2Marker  then
            2drop r> dup if 140 else 100 then diagonal2Text  endof
    endcase ;

: pdfFloorPlan ( -- )   base @ >r decimal
    72 to textWidth  120 to textHeight
    ['] pdfCentered 'nodeCentered !
    ['] pdfNumbered 'nodeNumbered !
    ['] pdfDirections 'nodeDirections !
    ['] pdfHorizontal 'horizontalPath !
    ['] pdfVertical 'verticalPath !
    ['] pdfDiagonal 'diagonalPath !
    projectFolder c@ if
        FpTitle s" FloorPlan.pdf" projectFile
    else  s" ../data/FloorPlan.pdf"
    then  ['] fileCreate catch if
        2drop s" FloorPlan.pdf" fileCreate
    then  1 to pdfObject  0 pdfObjects !
    AdjustFloorPlanFrame  pdfHeader
    pdfCatalog  pdfOutlines  pdfPages  90 pdfPage  <pdfStream
    #cols sizeX * offsetX 2* + to viewWidth
    #rows sizeY * offsetX 2* + to viewHeight
    10 0 0 10 pdfWidth 10 * 360 -  360 <cm*10>  \ translate x and margins
    0 10 -10 0 0 0 <cm*10>                      \ rotate 90 degrees
    pdfHeight 72 - 10000 viewWidth */ 0 0
    pdfWidth 72 - 10000 viewHeight */ 0 0 <cm*1000>  fileCr
    #nodes 0 do  i to FpNode
        FpName @ ?dup if
            <q  FpColor count swap count swap c@ <rgf>
                FpNode >rectXY nodeWide nodeHigh <re>
            <b> Q>
            nodeNumbered  nodeDirections  count 0 nodeCentered
            2  FpFunction  begin  @link ?dup while
                2dup >r >r cell+ @ count r> nodeCentered 1+ r>
            repeat  drop
            FpStatus @ ?dup if
                s" Status" maxLines 2 - nodeCentered
                count maxLines 1- nodeCentered
            then
            FpWrites  begin  @link ?dup while
                dup >r cell+ dup cell+ @ swap @ count writeConnector r>
            repeat
            FpReads  begin  @link ?dup while
                dup >r cell+ dup cell+ @ swap @ count readConnector r>
            repeat
            i #nodes 1- - if  fileCr  then
        else  showUnusedNodes if
            <q  75 75 75 <RGS>
                FpNode >rectXY nodeWide nodeHigh <re>
            <S> Q>  nodeNumbered
        then then
    loop  pdfStream>  pdfLength
    pdfProcSet  pdfFont  pdfXref  pdfTrailer
    fileClose  r> base ! ;

[THEN]
