\ FloorPlan.f - Create SVG output of node layout

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

[defined] svgFloorPlan.version 0= [IF]

1 constant svgFloorPlan.version

: svgCentered ( str len line -- )   <text  >r dup >r  FpNode >rectXY
    swap 33 +  maxWidth r> - textWidth 2 */ +
    swap 84 +  r> 1+ textHeight * +
    <tspan>*10  text>  fileCr ;

: svgNumbered ( -- )   <text  nodeId pathId place  pathId count
    FpNode >rectXY  swap 33 +  swap 84 +  <tspan>*10  text>  fileCr ;

: svgDirections ( -- )
    FpNode #cols /   1 and if  s" U"  else  s" D"  then  <text  FpNode >rectXY
    swap        0 +              swap        0 +               <tspan>*10  text>  fileCr
    FpNode #rows mod 1 and if  s" L"  else  s" R"  then  <text  FpNode >rectXY
    swap nodeWide +              swap            textHeight +  <tspan>*10  text>  fileCr
    FpNode #cols /   1 and if  s" D"  else  s" U"  then  <text  FpNode >rectXY
    swap nodeWide + textWidth -  swap nodeHigh + textHeight +  <tspan>*10  text>  fileCr
    FpNode #rows mod 1 and if  s" R"  else  s" L"  then  <text  FpNode >rectXY
    swap            textWidth -  swap nodeHigh + textHeight -  <tspan>*10  text>  fileCr
;

: addId ( str len -- )   pathId place  nodeId pathId append ;

: pathText ( str len r>l -- )   >r <text pathId count
    textWidth  r> if  2*  then  <textPath>  text>  fileCr ;

: markPath ( str1 len1 str2 len2 -- )   pathId append  pathId count <path  >fileStr ;

: svgHorizontal ( str1 len1 x y x' y r>l str2 len2 -- )   addId  dup >r
    if  s" marker-start='url(#startMarker)'" s" B" markPath
    else  s" marker-end='url(#endMarker)'" s" A" markPath  then
    =d  drop >r moveTo  r> horizontalTo  file' path> r> pathText ;
: svgVertical ( str1 len 1 x y x y' r>l str2 len2 -- )   addId  dup >r
    if  s" marker-start='url(#startMarker)'" s" B" markPath
    else  s" marker-end='url(#endMarker)'" s" A" markPath  then
    =d  nip >r moveTo  r> verticalTo  file' path> r> pathText ;
: svgDiagonal ( str1 len1 x y x' y' r>l str2 len2 n -- )   drop addId  dup >r
    if  s" marker-start='url(#startMarker)'" s" B" markPath \ bidirectional ???
    else  s" marker-end='url(#endMarker)'" s" A" markPath  then
    =d  2swap moveTo  lineTo  file' path> r> pathText ;

: svgFloorPlan ( -- )   base @ decimal
    72 to textWidth  120 to textHeight
    ['] svgCentered 'nodeCentered !
    ['] svgNumbered 'nodeNumbered !
    ['] svgDirections 'nodeDirections !
    ['] svgHorizontal 'horizontalPath !
    ['] svgVertical 'verticalPath !
    ['] svgDiagonal 'diagonalPath !
    projectFolder c@ if
        FpTitle s" FloorPlan.svg" projectFile
    else  s" ../data/FloorPlan.svg"
    then  ['] fileCreate catch if
        2drop s" FloorPlan.svg" fileCreate
    then  AdjustFloorPlanFrame  xmlVersion docType
    svgWidth svgHeight 0 0 #cols sizeX * offsetX 2* + 10 /
        #rows sizeY * offsetX 2* + 10 / s" svg1" <svg
        <style .styleFont .styleBox .styleStop style>
        s" defs4" <defs
            s" nodeBox" <symbol
                s" node00" nodeWide nodeHigh <rect>*10
            symbol>
            s" arrowMarker" <g
                6 -2 0 0 s" styleStop" <line>
                6  2 0 0 s" styleStop" <line>
            g>
            480 240 -4 -4 25 5 s" startMarker" <marker
                3 fileIndents  s" <g>" >fileStr fileCr
                    4 fileIndents  s" <use xlink:href='#arrowMarker' transform='rotate(0)' " >fileStr
                        s" styleStop" =class  s" />" >fileStr fileCr
                2 fileIndents  g>
            marker>
            480 240 -4 -4 25 5 s" endMarker" <marker
                3 fileIndents  s" <g>" >fileStr fileCr
                    4 fileIndents  s" <use xlink:href='#arrowMarker' transform='rotate(180)' " >fileStr
                        s" styleStop" =class  s" />" >fileStr fileCr
                2 fileIndents  g>
            marker>
        defs>
        s" layer1" <g  #nodes 0 do  i to FpNode
            FpName @ ?dup if
                s" nodeBox"  FpNode >rectXY <use>*10
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
            then
        loop  g>
    svg>  fileClose
    base ! ;

[THEN]
