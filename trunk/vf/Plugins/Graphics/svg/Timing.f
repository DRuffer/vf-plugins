\ Timing.f - Create SVG output of timing events

: AdjustSvgFrame ( -- flag )
    files TimeFrame host  dup to 1stTime  over to lastTime  or dup if
        nodeSize nodeSpace + numberNodes * nodeScale + nodeMargin + numberMargin +
            svgWidth swap svgXratio 2!
        lastTime 1stTime - nodeSize + nodeMargin + 1000 + svgHeight svgYratio 2!
        nodeSize nodeMargin + svgYscale to baseLine
        lastTime 1stTime - baseLine + nodeMargin svgYscale + to lastLine
    then ;

: svgCenter ( i -- px )   nodeColumn nodeScale + nodeMargin + nodeSize 2/ 1+ + svgXscale ;

: svgBox ( i -- )   >r s" nodeBox"
    r@ nodeColumn nodeScale + nodeMargin + svgXscale
        nodeMargin svgYscale <use>
    svgXratio 2@ r>f svgYratio 2@ r>f <transformScale <text
        r@ bufferNumber  r> nodeColumn nodeScale + nodeMargin + 10 +
        over 1- if  5 -  then  26 <tspan>
    text> transform> ;

: svgXchg ( x y -- )   iocsEvent if  s" nodeXchg"
        2swap xchgSize 2/ svgYscale -
        swap xchgSize 2/ - swap <use>
    else  pathDirection if  s" rightXchg"
        2swap  xchgSize 2/ svgYscale - <use>
        s" rightXchg" nodeX nodeY swap xchgSize 2/ -
        swap xchgSize 2/ svgYscale - <use>
    else  s" leftXchg"  2swap  swap xchgSize 2/ -
        swap xchgSize 2/ svgYscale - <use>
        s" leftXchg" nodeX nodeY
        xchgSize 2/ svgYscale - <use>
    then then ;

: svgSleep ( i -- )   nodeCenter baseLine over lastLine s" styleStop" <line> ;
: svgScale ( i -- )   2 svgXscale baseLine over lastLine s" styleScale" <line>
    calculateIncrement do  i scaleIncrement mod 0= if
        2 svgXscale baseLine i + 1stTime - svgXratio @ svgXscale over s" styleScale" <line>
        svgXratio 2@ 2* r>f svgYratio 2@ 2* r>f <transformScale <text
            i bufferNumber  5 2*  baseline i + 1stTime - 2* svgYratio 2@ swap */ 12 + <tspan>
        text> transform>
        svgXratio 2@ 2* r>f svgYratio 2@ 2* r>f <transformScale <text
            i bufferTime  svgWidth 2* svgXratio 2@ swap */ numberMargin 5 + 2* -
            baseline i + 1stTime - 2* svgYratio 2@ swap */ 15 + <tspan>
        text> transform>
    then  loop ;

: svgStart ( i -- )   fileCr  dup nodeBox
    dup drawSleep  nodeCenter to nodeX  baseLine to nodeY ;
: svgFinish ( i -- )   1+ if  nodeX saveY ?dup if
        over lastLine  s" styleWork" <line>  0 to nodeX  0 to nodeY
    else drop then then ;
: svgWork ( time -- )   baseLine + >r
    nodeX nodeY over r@ s" styleWork" <line>  r> to NodeY ;
: svgPath ( x y -- x y )   pathLeft if
        s" styleLeft"               \ blue to the left
    else  s" styleRight"            \ green to the right
    then  <line> ;

: svgTiming ( -- )   base @ >r decimal
    72 to textWidth  120 to textHeight
    ['] AdjustSvgFrame 'AdjustTimingFrame !
    ['] svgCenter 'nodeCenter !
    ['] svgBox 'nodeBox !
    ['] svgXchg 'drawXchg !
    ['] svgSleep 'drawSleep !
    ['] svgScale 'drawScale !
    ['] svgStart 'startPath !
    ['] svgFinish 'finishPath !
    ['] svgWork 'workPath !
    ['] svgPath 'drawPath !
    projectFolder c@ if
        0 0 s" Timing.svg" projectFile
    else  s" Timing.svg"
    then  fileCreate
    AdjustTimingFrame
    if  xmlVersion docType
        svgWidth svgHeight 0 0 0 svgHeight svgYscale s" svg1" <svg
            <style .styleFont .styleBox .styleWork .styleLeft .styleRight
                .styleStop .styleXchg .styleScale style>
            s" defs4" <defs
                s" nodeBox" <symbol
                    s" node00" nodeSize svgXscale nodeSize svgYscale <rect>
                symbol>
                s" nodeXchg" <symbol
                    fileIndent         0 xchgSize svgYscale xchgSize 0 s" styleXchg" <line>
                    fileIndent  xchgSize xchgSize svgYscale        0 0 s" styleXchg" <line>
                symbol>
                s" leftXchg" <symbol
                    fileIndent  0                   0  xchgSize 2/  xchgSize 2/ svgYscale s" styleXchg" <line>
                    fileIndent  0  xchgSize svgYscale  xchgSize 2/  xchgSize 2/ svgYscale s" styleXchg" <line>
                symbol>
                s" rightXchg" <symbol
                    fileIndent  0  xchgSize 2/ svgYscale  xchgSize 2/                   0 s" styleXchg" <line>
                    fileIndent  0  xchgSize 2/ svgYscale  xchgSize 2/  xchgSize svgYscale s" styleXchg" <line>
                symbol>
            defs>
            s" layer1" <g drawScale drawPaths g>
        svg>
    then  fileClose  r> base ! ;
