\ svg.f - Support for Scalable Vector Graphics (SVG)

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

[defined] svg.version 0= [IF]

1 constant svg.version

750 value svgWidth
800 value svgHeight

create svgXratio   forth 2 cells allot host    1 1 svgXratio 2!
create svgYratio   forth 2 cells allot host   20 1 svgYratio 2!

: svgXscale ( n -- n' )   svgXratio 2@ */ ;
: svgYscale ( n -- n' )   svgYratio 2@ */ ;

: xmlVersion ( -- )   s" <?xml version='1.0' standalone='no'?>" >fileStr fileCr fileCr ;

: docType ( -- )   s" <!DOCTYPE svg PUBLIC '-//W3C//DTD SVG 1.0//EN'" >fileStr fileCr  fileIndent
    s" 'http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd'>" >fileStr fileCr  fileCr ;

: svg*1000. ( n*1000 -- )   dup abs s>d <# # # # [char] . hold #s rot sign #> >fileStr ;
: svg*10. ( n*10 -- )   dup abs s>d <# # [char] . hold #s rot sign #> >fileStr ;
: svgN. ( n -- )   dup abs s>d <# #s rot sign #> >fileStr ;

: 'n' ( n -- )   file' svgN. file' ;

: =width ( n -- )   s" width=" >fileStr 'n' fileSpace ;
: =height ( n -- )   s" height=" >fileStr 'n' fileSpace ;
: =width*10 ( n*10 -- )   s" width=" >fileStr file' svg*10. file' fileSpace ;
: =height*10 ( n*10 -- )   s" height=" >fileStr file' svg*10. file' fileSpace ;
: =markerWidth*10 ( n*10 -- )   s" markerWidth=" >fileStr file' svg*10. file' fileSpace ;
: =markerHeight*10 ( n*10 -- )   s" markerHeight=" >fileStr file' svg*10. file' fileSpace ;
: =x1 ( n -- )   s" x1=" >fileStr 'n' fileSpace ;
: =x1*10 ( n*10 -- )   s" x1=" >fileStr file' svg*10. file' fileSpace ;
: =y1 ( n -- )   s" y1=" >fileStr 'n' fileSpace ;
: =y1*10 ( n*10 -- )   s" y1=" >fileStr file' svg*10. file' fileSpace ;
: =x2 ( n -- )   s" x2=" >fileStr 'n' fileSpace ;
: =x2*10 ( n*10 -- )   s" x2=" >fileStr file' svg*10. file' fileSpace ;
: =y2 ( n -- )   s" y2=" >fileStr 'n' fileSpace ;
: =y2*10 ( n*10 -- )   s" y2=" >fileStr file' svg*10. file' fileSpace ;
: =x ( n -- )   s" x=" >fileStr 'n' fileSpace ;
: =x*10 ( n*10 -- )   s" x=" >fileStr file' svg*10. file' fileSpace ;
: =y ( n -- )   s" y=" >fileStr 'n' fileSpace ;
: =y*10 ( n*10 -- )   s" y=" >fileStr file' svg*10. file' fileSpace ;

: =viewBox ( min-x min-y width height -- )
    s" viewBox='" >fileStr  swap 2swap swap
    svgN. fileSpace  svgN. fileSpace
    svgN. fileSpace  svgN.
    file'  fileSpace ;

: =preserveAspectRatio ( str len -- )   s" preserveAspectRatio='" >fileStr >fileStr file' ;
: =xlink:href ( str len -- )   s" xlink:href='#" >fileStr >fileStr file' ;
: =xml:space ( str len -- )   s" xml:space='" >fileStr >fileStr file' ;
: =class ( str len -- )   s" class='" >fileStr >fileStr file' ;

: =id ( str1 len1 str2 len2 -- )   >fileStr s"  id='" >fileStr >fileStr file' ;

: <svg ( width height viewBox str len -- )   s" <svg" =id fileSpace
    =viewBox  swap =width  =height  s" none" =preserveAspectRatio  fileCr
    fileIndent s" xmlns:xlink='http://www.w3.org/1999/xlink'" >fileStr fileCr
    fileIndent s" xmlns='http://www.w3.org/2000/svg'>" >fileStr fileCr ;
: svg> ( -- )   s" </svg>" >fileStr fileCr ;

: <style ( -- )   fileCr  fileIndent  s" <style type='text/css'>" >fileStr fileCr
    2 fileIndents  s" <![CDATA[" >fileStr fileCr ;
: style> ( -- )   2 fileIndents  s" ]]>" >fileStr fileCr
    fileIndent  s" </style>" >fileStr fileCr  fileCr ;

: .styleFont ( -- )   3 fileIndents  s" .styleFont  {" >fileStr
    s" font-size:12;" >fileStr
    s" font-style:normal;" >fileStr
    s" font-weight:normal;" >fileStr
    s" fill:black;" >fileStr
    s" fill-opacity:1;" >fileStr
    s" stroke:none;" >fileStr
    s" stroke-width:1;" >fileStr
    s" stroke-linecap:butt;" >fileStr
    s" stroke-linejoin:miter;" >fileStr
    s" stroke-opacity:1;" >fileStr
    s" font-family:Courier New;}" >fileStr fileCr ;
: .styleBox ( -- )   3 fileIndents  s" .styleBox   {" >fileStr
    s" opacity:1;" >fileStr
    s" fill:none;" >fileStr
    s" fill-opacity:1;" >fileStr
    s" fill-rule:evenodd;" >fileStr
    s" stroke:black;" >fileStr
    s" stroke-width:1;" >fileStr
    s" stroke-linecap:butt;" >fileStr
    s" stroke-linejoin:round;" >fileStr
    s" stroke-opacity:1;}" >fileStr fileCr ;
: .styleLeft ( -- )   3 fileIndents  s" .styleLeft  {" >fileStr
    s" fill:none;" >fileStr
    s" fill-rule:evenodd;" >fileStr
    s" stroke:blue;" >fileStr
    s" stroke-width:3;" >fileStr
    s" stroke-linecap:butt;" >fileStr
    s" stroke-linejoin:miter;" >fileStr
    s" stroke-opacity:1;}" >fileStr fileCr ;
: .styleRight ( -- )   3 fileIndents  s" .styleRight  {" >fileStr
    s" fill:none;" >fileStr
    s" fill-rule:evenodd;" >fileStr
    s" stroke:green;" >fileStr
    s" stroke-width:3;" >fileStr
    s" stroke-linecap:butt;" >fileStr
    s" stroke-linejoin:miter;" >fileStr
    s" stroke-opacity:1;}" >fileStr fileCr ;
: .styleWork ( -- )   3 fileIndents  s" .styleWork  {" >fileStr
    s" fill:none;" >fileStr
    s" fill-rule:evenodd;" >fileStr
    s" stroke:black;" >fileStr
    s" stroke-width:3;" >fileStr
    s" stroke-linecap:butt;" >fileStr
    s" stroke-linejoin:miter;" >fileStr
    s" stroke-opacity:1;}" >fileStr fileCr ;
: .styleStop ( -- )   3 fileIndents  s" .styleStop  {" >fileStr
    s" fill:none;" >fileStr
    s" fill-rule:evenodd;" >fileStr
    s" stroke:black;" >fileStr
    s" stroke-width:1;" >fileStr
    s" stroke-linecap:butt;" >fileStr
    s" stroke-linejoin:miter;" >fileStr
    s" stroke-opacity:1;}" >fileStr fileCr ;
: .styleXchg ( -- )   3 fileIndents  s" .styleXchg  {" >fileStr
    s" fill:none;" >fileStr
    s" fill-rule:evenodd;" >fileStr
    s" stroke:black;" >fileStr
    s" stroke-width:1;" >fileStr
    s" stroke-linecap:butt;" >fileStr
    s" stroke-linejoin:miter;" >fileStr
    s" stroke-opacity:1;}" >fileStr fileCr ;
: .styleScale ( -- )   3 fileIndents  s" .styleScale {" >fileStr
    s" fill:none;" >fileStr
    s" fill-rule:evenodd;" >fileStr
    s" stroke:black;" >fileStr
    s" stroke-width:1;" >fileStr
    s" stroke-linecap:butt;" >fileStr
    s" stroke-linejoin:miter;" >fileStr
    s" stroke-opacity:1;" >fileStr
    s" stroke-dasharray:4,4;}" >fileStr fileCr ;

: <defs ( str len -- )   fileIndent  s" <defs" =id s" >" >fileStr fileCr ;
: defs> ( -- )   fileIndent  s" </defs>" >fileStr fileCr  fileCr ;

: <symbol ( str len -- )   2 fileIndents  s" <symbol" =id s" >" >fileStr fileCr ;
: symbol> ( -- )   2 fileIndents  s" </symbol>" >fileStr fileCr ;

: <marker ( width height viewBox str len -- )   2 fileIndents  s" <marker" =id  fileSpace
    =viewBox  swap =markerWidth*10  =markerHeight*10  fileCr 3 fileIndents
    s" orient='auto' refX='0' refY='0' markerUnits='strokeWidth'>" >fileStr fileCr ;
: marker> ( -- )   2 fileIndents  s" </marker>" >fileStr fileCr ;

: <rect> ( str len width height -- )   3 fileIndents  2swap s" <rect" =id
    fileSpace  s" styleBox" =class  fileSpace
    swap =width =height  s" />" >fileStr fileCr ;
: <rect>*10 ( str len width*10 height*10 -- )   3 fileIndents  2swap s" <rect" =id
    fileSpace  s" styleBox" =class  fileSpace
    swap =width*10 =height*10  s" />" >fileStr fileCr ;

: <g ( str len -- )   fileIndent s" <g" =id s" >" >fileStr fileCr ;
: g> ( -- )   fileIndent s" </g>" >fileStr fileCr ;

: <use> ( str len x y -- )   2 fileIndents s" <use " >fileStr
    swap =x =y  =xlink:href  s"  />" >fileStr fileCr ;
: <use>*10 ( str len x*10 y*10 -- )   2 fileIndents s" <use " >fileStr
    swap =x*10 =y*10  =xlink:href  s"  />" >fileStr fileCr ;

: <transformScale ( sx sy -- )   2 fileIndents
    s" <g transform='scale(" >fileStr swap svg*1000. file, svg*1000. s" )'>" >fileStr fileCr ;
: transform> ( -- )   s" </g>" >fileStr fileCr ;

: r>f ( n d -- n*1000/d )   1000 swap */ ;

: <text ( -- )   3 fileIndents  s" <text " >fileStr  s" preserve" =xml:space
    fileSpace  s" styleFont" =class  s" >" >fileStr fileCr ;
: text> ( -- )   3 fileIndents  s" </text>" >fileStr ;

: <tspan> ( str len x y -- )
    4 fileIndents  s" <tspan " >fileStr  swap =x =y  s" >" >fileStr >fileStr s" </tspan>" >fileStr fileCr ;
: <tspan>*10 ( str len x*10 y*10 -- )
    4 fileIndents  s" <tspan " >fileStr  swap =x*10 =y*10  s" >" >fileStr >fileStr s" </tspan>" >fileStr fileCr ;
: <textPath> ( str len str1 len1 offset*10 -- )
    4 fileIndents  s" <textPath startOffset='" >fileStr  svg*10.
    s" ' xlink:href='#" >fileStr  >fileStr  s" '>" >fileStr  >fileStr  s" </textPath>" >fileStr fileCr ;

:  moveTo ( x*10 y*10 -- )   s" M " >fileStr  swap svg*10. fileSpace  svg*10. fileSpace ;
:  lineTo ( x*10 y*10 -- )   s" L " >fileStr  swap svg*10. fileSpace  svg*10. fileSpace ;
: horizontalTo ( x*10 -- )   s" H " >fileStr  svg*10. fileSpace ;
:   verticalTo ( y*10 -- )   s" V " >fileStr  svg*10. fileSpace ;

: <path ( str len -- )   2 fileIndents  s" <path " =id
    fileSpace  s" styleStop" =class  fileSpace ;
: =d ( -- )   fileCr  3 fileIndents  s" d='" >fileStr ;
: path> ( -- )   s" />" >fileStr fileCr ;

: <line> ( x1 y1 x2 y2 style.len -- )   2 fileIndents  s" <line " >fileStr
    =class  fileSpace  swap 2swap swap  =x1 =y1 =x2 =y2  s" />" >fileStr fileCr ;

[THEN]
