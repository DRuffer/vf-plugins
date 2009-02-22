\ Timing.f - Create PDF output of timing events

: AdjustPdfFrame ( -- flag )
    files TimeFrame host  dup to 1stTime  over to lastTime  or dup if
        nodeSize nodeSpace + numberNodes * nodeScale + nodeMargin + numberMargin +
            pdfWidth swap pdfXratio 2!
        lastTime 1stTime - nodeSize + nodeMargin + 1000 + pdfHeight pdfYratio 2!
        nodeSize nodeMargin + pdfYscale to baseLine
        lastTime 1stTime - baseLine + nodeMargin pdfYscale + to lastLine
    then ;

: pdfCenter ( i -- px )   nodeColumn nodeScale + nodeMargin + nodeSize 2/ 1+ + pdfXscale ;

: pdfBox ( i -- )   dup >r nodeColumn nodeScale + nodeMargin + pdfXscale
        nodeMargin pdfYscale  nodeSize pdfXscale  nodeSize pdfYscale <re> <S>
    <q  r@ bufferNumber  r> nodeColumn nodeScale + nodeMargin + 8 +
        over 1- if  6 -  then pdfXscale  28 pdfYscale
        10 0 0 10 2rot viewHeight swap - <cm*10>
        pdfXratio 2@ r>f 7 / 0 0  pdfYratio 2@ r>f 7 / 0 0 <cm*1000>
    <BT>  <Tf> 0 viewHeight <Td> <Tj>  <ET> Q> ;

: pdfXchg ( x y -- )   iocsEvent if
        xchgSize 2/ pdfYscale -  swap xchgSize 2/ - swap
        2dup <m>  over xchgSize +  over xchgSize pdfYscale + <l>
        2dup xchgSize pdfYscale + <m>  swap xchgSize + swap <l>
    else  pathDirection if
        2dup <m>  over xchgSize 2/ +  over xchgSize 2/ pdfYscale - <l>
        2dup <m>  swap xchgSize 2/ +  swap xchgSize 2/ pdfYscale + <l>
        nodeX xchgSize 2/ - nodeY
        2dup <m>  over xchgSize 2/ +  over xchgSize 2/ pdfYscale - <l>
        2dup <m>  swap xchgSize 2/ +  swap xchgSize 2/ pdfYscale + <l>
    else
        2dup <m>  over xchgSize 2/ -  over xchgSize 2/ pdfYscale - <l>
        2dup <m>  swap xchgSize 2/ -  swap xchgSize 2/ pdfYscale + <l>
        nodeX xchgSize 2/ + nodeY
        2dup <m>  over xchgSize 2/ -  over xchgSize 2/ pdfYscale - <l>
        2dup <m>  swap xchgSize 2/ -  swap xchgSize 2/ pdfYscale + <l>
    then then ;

: pdfSleep ( i -- )   nodeCenter dup baseLine <m>  lastLine <l> ;
: pdfScale ( i -- )   2 pdfXscale dup baseLine <m>  lastLine <l>
    calculateIncrement do  i scaleIncrement mod 0= if
        <q  10 <d>  2 pdfXscale  i 1stTime - baseLine + dup >r <m>
            pdfWidth r> <l> Q>
        <q  i bufferNumber  textWidth 30 / pdfXScale
            i 1stTime - textHeight 30 / pdfYscale + baseline +
            10 0 0 10 2rot viewHeight swap - <cm*10>
            pdfXratio 2@ r>f 30 / 0 0  pdfYratio 2@ r>f 30 / 0 0 <cm*1000>
        <BT>  <Tf> 0 viewHeight <Td> <Tj>  <ET> Q>
        <q  i bufferTime  pdfWidth over textWidth 30 */ pdfXscale -
            i 1stTime - textHeight 30 / pdfYscale + baseline +
            10 0 0 10 2rot viewHeight swap - <cm*10>
            pdfXratio 2@ r>f 30 / 0 0  pdfYratio 2@ r>f 30 / 0 0 <cm*1000>
        <BT>  <Tf> 0 viewHeight <Td> <Tj>  <ET> Q>
    then  loop ;

: pdfStart ( i -- )   fileCr  dup nodeBox
    dup drawSleep  nodeCenter to nodeX  baseLine to nodeY ;
: pdfFinish ( i -- )   1+ if  nodeX dup saveY ?dup if
        <q 1 <w> <m>  lastLine <l> Q>  0 to nodeX  0 to nodeY
    else 2drop then then ;
: pdfWork ( time -- )   baseLine + >r
    nodeX dup nodeY <q 1 <w> <m>  r@ <l> Q>  r> to NodeY ;
: pdfPath ( x y -- x y )   pathLeft if
        <q 0 0 100 <RGS>    \ blue to the left
    else <q 0 100 0 <RGS>   \ green to the right
    then  2swap <m> <l> Q> ;

: pdfTiming ( -- )   base @ >r decimal
    72 to textWidth  120 to textHeight
    ['] AdjustPdfFrame 'AdjustTimingFrame !
    ['] pdfCenter 'nodeCenter !
    ['] pdfBox 'nodeBox !
    ['] pdfXchg 'drawXchg !
    ['] pdfSleep 'drawSleep !
    ['] pdfScale 'drawScale !
    ['] pdfStart 'startPath !
    ['] pdfFinish 'finishPath !
    ['] pdfWork 'workPath !
    ['] pdfPath 'drawPath !
    projectFolder c@ if
        0 0 s" Timing.pdf" projectFile
    else  s" Timing.pdf"
    then  fileCreate
    1 to pdfObject  0 pdfObjects !  AdjustTimingFrame
    if  pdfHeader  pdfCatalog  pdfOutlines  pdfPages  0 pdfPage  <pdfStream
            pdfWidth to viewWidth
            pdfYratio cell+ @ to viewHeight
            10 0 0 10 360 360 <cm*10>               \ translate margins
            pdfWidth 72 - 10000 viewWidth */ 0 0
            pdfHeight 72 - 10000 viewHeight */ 0 0 <cm*1000>  fileCr
            0 <w>  drawScale  drawPaths  pdfStream>
        pdfLength  pdfProcSet  pdfFont  pdfXref  pdfTrailer
    then  fileClose  r> base ! ;
