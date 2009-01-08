\ FloorPlan.f - Create graphical output of node layout

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

FORTH
v.VF +include" Plugins/Plugins.f"  Plugins.version 6 checkPlugin
v.VF +include" Plugins/links.f"  links.version 2 checkPlugin
v.VF +include" Plugins/strings.f"  strings.version 3 checkPlugin
v.VF +include" Plugins/numbers.f"  numbers.version 1 checkPlugin
v.VF +include" Plugins/comments.f"  comments.version 2 checkPlugin
v.VF +include" Plugins/Projects.f"  Projects.version 9 checkPlugin

[defined] FloorPlan.version 0= [IF]

8 constant FloorPlan.version

fileList FloorPlanFiles   addZip ," vf/Plugins/FloorPlan.zip"
    addFile ," vf/Plugins/doc/FloorPlan.pdf"
    addFile ," vf/Plugins/FloorPlan.f"
    addFile ," vf/Plugins/Graphics/pdf/FloorPlan.f"
    addFile ," vf/Plugins/Graphics/pdf/pdf.f"
    addFile ," vf/Plugins/Graphics/svg/FloorPlan.f"
    addFile ," vf/Plugins/Graphics/svg/svg.f"
    addFile ," vf/Plugins/comments.f"
    addFile ," vf/Plugins/idForth.f"
    addFile ," vf/Plugins/LaTeX.f"
    addFile ," vf/Plugins/links.f"
    addFile ," vf/Plugins/Plugins.f"
    addFile ," vf/Plugins/Projects.f"
    addFile ," vf/Plugins/strings.f"
    addFile ," vf/Plugins/numbers.f"
    addFile ," vf/gforth.fs"
    addFile ," projects/FloorPlan/FloorPlan.f"
    addFile ," projects/FloorPlan/FloorPlan.vf"
    addFile ," projects/FloorPlan/exterior/FloorPlan.htm"
    addFile ," projects/FloorPlan/exterior/FloorPlan.pdf"
    addFile ," projects/FloorPlan/exterior/FloorPlan.svg"
    addFile ," projects/FloorPlan/project.bat"
    addFile ," projects/FloorPlan/project.vfp"

: FloorPlan.zip ( -- ) \ create archive of FloorPlan plug in
    FloorPlanFiles zipFiles ;

: FloorPlanHelp ( -- )
    s" The following words are the user interface for the Floor Plan descriptions." >fileLine
    s" They are each used within parenthesis, so they do not need to be removed if" >fileLine
    s" this plugin is not loaded.  They model HTML tags (somewhat), so that they" >fileLine
    s" can be evaluated inside quoted strings.  They affect the following lines:" >fileLine
    s" \begin{description}" >fileLine
    s" \item[\texttt{<noname>}]Sets the current node" >fileLine
    s" \item[\texttt{<name ...>}]Sets the text on the top line and sets the current node" >fileLine
    s" \item[\texttt{<rgb r g b>}]Sets the background color of the node's box (only in PDF)." >fileLine
            s" The r, g and b numbers can have 0, 1 or 2 decimal places." >fileLine
    s" \item[\texttt{<status ...>}]Sets the text on the bottom line of the current node" >fileLine
    s" \item[\texttt{<function ...>}]Adds lines to the middle of the current node" >fileLine
    s" \item[\texttt{<title ...>}]Adds a named page of arrow entries.  Name sets page." >fileLine
    s" \item[\texttt{<read ...>}]Adds a named arrow into the current node" >fileLine
    s" \item[\texttt{<write ...>}]Adds a named arrow out of the current node" >fileLine
    s" \end{description}" >fileLine
    s" The read and write arrow directions are based upon the port address that is" >fileLine
    s" on top of the stack when they are executed.  Typically, this address will be" >fileLine
    s" compiled as a literal immediately following these comments, but the affect" >fileLine
    s" will need to be emulated (with a \begin{bf}drop\end{bf}) if this is not the case." >fileLine
        fileCr
    s" An alternative to having an address on the stack is also available, which can" >fileLine
    s" make these tags less obtrusive.  If the tag is immediately followed by a neighbor" >fileLine
    s" direction word, such as:\begin{verbatim}<read 'rdlu ...>\end{verbatim} then that will be used to" >fileLine
    s" indicate the direction and the stack will not be checked." >fileLine
        fileCr
    s" The names and locations of the arrows between ports are designed to line up" >fileLine
    s" with each other (e.g. read from one will overlap write from the other)." >fileLine
    s" This should be noticeable as making the text bolder, but may be a blur if" >fileLine
    s" both names are not the same." >fileLine
        fileCr
    s" In the 'iocs, 'addr and 'data cases, the arrows are placed on the diagonal" >fileLine
    s" to prevent them from conflicting with the paths between nodes, and they are" >fileLine
    s" rotated around the node so they will point away from the other nodes." >fileLine
    s" The 'iocs port also has the option to specify the individual bits," >fileLine
    s" by preceding the description with a bit number.  There are 5 positions" >fileLine
    s" available, and the chip design uses 2 bits per I/O pin.  Therefore, you" >fileLine
    s" can specify the even or odd bit for the first 4 pins as 0 through 7" >fileLine
    s" and the 5th pin (the default) is specified as either bit 16 or 17." >fileLine
    s" This 5th pin is the diagonal one used if a bit number is not specified" >fileLine
    s" and the other pins use the 2 edges that face away from the other nodes." >fileLine
    s" Thus, specifying 'iocs bits on internal nodes will conflict with the" >fileLine
    s" normal communication paths between nodes." >fileLine
        fileCr
    s" There is, however, only minimal error checking on the use of port or bit" >fileLine
    s" numbers on any node.  Since the chip capabilities will change, it is left" >fileLine
    s" to the programmer to specify the capabilities that are appropriate for the" >fileLine
    s" hardware he is using." >fileLine
        fileCr
    s" Some additional commands:" >fileLine
    s" \begin{description}" >fileLine
    s" \item[\texttt{n to FpNode}] used if you are not setting the name." >fileLine
    s" \item[\texttt{FpRuntime}] used to add unlabeled arrows for runtime events." >fileLine
            s" (if the Events Plugin is also installed.)" >fileLine
    s" \item[\texttt{true to showUnusedNodes}] to show unused nodes (PDF only)." >fileLine
    s" \item[\texttt{true to ignoreFloorPlan}] to ignore these markers." >fileLine
    s" \end{description}" >fileLine
    s" All of the preceding words must appear in your source code before the following" >fileLine
    s" words that are used to generate the Floor Plan diagrams." >fileLine
    s" \begin{description}" >fileLine
    s" \item[\texttt{svgFloorPlan}] to generate an SVG Floor Plan." >fileLine
    s" \item[\texttt{pdfFloorPlan}] to generate a PDF Floor Plan." >fileLine
    s" \end{description}" >fileLine ;

: FloorPlanHistory ( -- )   s" Floor Plan Historical Background" subSection
    s" The story that started it all" subSection
    s" On 05 Feb 07, Les Snively wrote the following story in our XPlanner website" >fileLine
        fileCr
    s" \begin{quotation}" >fileLine
    s" In the SEAForth world, a floor plan has come" >fileLine
    s" to mean the location of specific chunks of code that handle particular" >fileLine
    s" processing tasks. It is a natural description of a data flow problem," >fileLine
    s" with pipelining of tasks in both serial and parallel fashion. Since" >fileLine
    s" I/O location is fixed relative to nodes on the chip, floor planning" >fileLine
    s" describes the location and data flow of the functional processing." >fileLine
    s" \end{quotation}" >fileLine
    s" The task that he assigned to me for accomplishing this was described" >fileLine
    s" as follows:" >fileLine
        fileCr
    s" \begin{quotation}" >fileLine
    s" An automatic graphical floor plan generator will be developed" >fileLine
    s" as a component of the Radio and RF IDE. The generator will take as" >fileLine
    s" it's input a standard VentureForth text file containing the design" >fileLine
    s" to be diagrammed. It will use the node definitions, and potentially" >fileLine
    s" special tags that will be defined, see below, to produce a graphical" >fileLine
    s" description of the floor plan for that file. It is recommended that" >fileLine
    s" the description be written in SVG format to make presentation via" >fileLine
    s" a server simple and easy to use with any standard browser." >fileLine
        fileCr
    s" A set of tags should be developed to ease in parsing out the important" >fileLine
    s" labels for the graphic. These labels should include, but may not be" >fileLine
    s" limited to:" >fileLine
        fileCr
    s" \begin{itemize}" >fileLine
    s" \item node name" >fileLine
    s" \item brief functional description" >fileLine
    s" \item active interfaces to other nodes including interface direction" >fileLine
    s" \item names for messages sent from node" >fileLine
    s" \item status indicator of node code, such as" >fileLine
    s" \begin{itemize}" >fileLine
    s" \item pending" >fileLine
    s" \item in-progress" >fileLine
    s" \item in-test" >fileLine
    s" \item released" >fileLine
    s" \end{itemize}" >fileLine
    s" \item probably some kind of indicator of the" >fileLine
    s" basic layout of the chip, such as" >fileLine
    s" \begin{itemize}" >fileLine
    s" \item 4x4" >fileLine
    s" \item 4x6" >fileLine
    s" \item etc." >fileLine
    s" \end{itemize}" >fileLine
    s" \end{itemize}" >fileLine
        fileCr
    s" The initial release should be done quickly, with no more than 3 or" >fileLine
    s" 4 days effort, and probably less, to get an feel for how the technique" >fileLine
    s" works. Additional features can be added later as the need arises." >fileLine
    s" \end{quotation}" >fileLine
    endSection endSection ;

: includeFloorPlan ( caption.len file.len label.len -- )
    s" \begin{figure}[b]" >fileLine 2>r
    s" \begin{picture}(200,100)(0,0)" >fileLine
    s" \put(-10,-50){\resizebox{14 cm}{!}{\includegraphics{" >fileStr
        >fileStr  s" }}}" >fileLine
    s" \end{picture}" >fileLine
    s" \caption{{\em " >fileStr  >fileStr  s" }}" >fileLine
    s" \label{" >fileStr 2r> >fileStr s" }" >fileLine
    s" \end{figure}" >fileLine
    s" \newpage" >fileLine ;

: FloorPlanExample ( -- )   s" Floor Plan Example" subSection
    s" \begin{tiny}" >fileLine
    s" \begin{verbatim}" >fileLine
    s" ( <title exterior> ) \ Repetitive lines removed" >fileLine
        fileCr
    s" \ Manual measurements (counts-watcher) taken on 30 Dec 08" >fileLine
    s" 00 to FpNode ( <function 12020-1> <function 11955-6>  )" >fileLine
    s\" : <tick> ( -- )   s\" ( <write 'iocs 1 1> <write 'iocs 2 2> )\" evaluate ;" >fileLine
    s\" : <corner> ( -- )   s\" ( <write 'iocs 17 17> )\" evaluate" >fileLine
    s\"   s\" ( <write 'iocs 1 1>   <write 'iocs 3 3> )\" evaluate" >fileLine
    s\"   s\" ( <write 'iocs 5 5>   <write 'iocs 7 7> )\" evaluate" >fileLine
    s\"   s\" ( <write 'addr addr>  <write 'data data> )\" evaluate ;" >fileLine
    s" 00 {node ( <name Node 00> <rgb 0 1 0>    <status corner> )  <corner>  node}" >fileLine
    s" 04 {node ( <name Node 04> <rgb 0 0.7 0>  <status bottom> )    <tick>  node}" >fileLine
    s" 16 {node ( <name Node 16> <rgb .92 0 0>  <status interior> )          node}" >fileLine
    s" 17 {node ( <name Node 17> <rgb 1.00 0 0> <status right> )     <tick>  node}" >fileLine
    s" 19 {node ( <name Node 19> <rgb 0 1 0>    <status uploader> )  <tick>  node}" >fileLine
    s" 22 {node ( <name Node 22> <rgb 0 1 1>    <status top> )       <tick>  node}" >fileLine
    s" 23 {node ( <name Node 23> <rgb 1 1 1>    <status corner> )  <corner>  node}" >fileLine
        fileCr
    s" ( exterior ) svgFloorPlan pdfFloorPlan" >fileLine
    s" \end{verbatim}" >fileLine
    s" \end{tiny}" >fileLine
    s" The example application's loader Floor Plan"
	s" ../../../projects/FloorPlan/exterior/FloorPlan"
	s" figPlan" includeFloorPlan
    endSection ;

: FloorPlan.tex ( -- )   v.VF pad place s" Plugins/doc/FloorPlan" pad append
    pad count 2dup texBook  s" Dennis Ruffer" s" Floor Plans" texTitle
    FloorPlanHistory fileCr
    FloorPlanFiles InstallingPlugins fileCr
    ProjectArtifacts fileCr
    s" Floor Plan User Interface" subSection
        FloorPlanHelp endSection fileCr
    FloorPlanExample fileCr
    endTex ;

HOST

0 value FpNode
0 value nodeArray
0 value |nodeEntry|
0 value arrowArray
0 value |arrowEntry|
0 value ignoreFloorPlan     \ set to true to ignore Floor Plan markers
0 value showUnusedNodes     \ set to true to show unused nodes

: FpTitle ( -- str len )   arrowArray 1 cells - @ dup if
        count  else  dup  then ;

: nodeField ( a n -- a+n )   create  over , +
    does> @  FpNode |nodeEntry| *  nodeArray + + ;

0
cell nodeField FpName
   3 nodeField FpColor  1+ \ throw away 1 byte
cell nodeField FpStatus
cell nodeField FpFunction
to |nodeEntry|

: /nodeArray ( a -- )   forth , here to nodeArray  #nodes 0 do
        0 , 100 c, 100 c, 100 c, 0 c, 0 , 0 ,
    loop ;
0 /nodeArray host  \ create a default array so applications don't have to

: doesNodes ( -- )   does> cell+ to nodeArray ;

: arrowField ( a n -- a+n )   create  over , +
    does> @  FpNode |arrowEntry| *  arrowArray + + ;

0
cell arrowField FpWrites
cell arrowField FpReads
to |arrowEntry|

: /arrowArray ( a -- )   forth , here to arrowArray  #nodes |arrowEntry| * /allot ;
0 /arrowArray host \ create a default array so applications don't have to

: doesArrows ( -- )   does> cell+ to arrowArray ;

: checkPort ( n -- )   case \ check that the port is valid at compile time.
        $171 of  endof \ 'addr
        $141 of  endof \ 'data

        $1a5 of  endof \ 'rdlu
        $1b5 of  endof \ 'rdl-
        $185 of  endof \ 'rd-u
        $195 of  endof \ 'rd--
        $1e5 of  endof \ 'r-lu
        $1f5 of  endof \ 'r-l-
        $1c5 of  endof \ 'r--u
        $1d5 of  endof \ 'r---
        $125 of  endof \ '-dlu
        $135 of  endof \ '-dl-
        $105 of  endof \ '-d-u
        $115 of  endof \ '-d--
        $165 of  endof \ '--lu
        $175 of  endof \ '--l-
        $145 of  endof \ '---u

        dup $1FF and $15d of
            9 rshift 4 > abort" undefined bit"
        endof \ 'iocs
        true abort" undefined port"                         \ we should not be here!
    endcase ;

create portAddrs \ valid port address strings for embedded references
    ," 'rdlu 'rdl- 'rd-u 'rd-- 'r-lu 'r-l- 'r--u 'r--- '-dlu '-dl- '-d-u '-d-- '--lu '--l- '---u 'iocs 'addr 'data "

: embeddedAddr ( str len -- false | addr )
    portAddrs count 2swap search if
        drop 5 evaluate
    else  2drop 0  then ;

: iocsBits ( addr -n- addr' )   dup $15d = if
        >in @  bl word number if
            nip 2/ 4 min
        else  >in !  4
        then  9 lshift +
    then ;

comments : <noname> ( -- )   node @ to FpNode ;

comments : <name ( -name>- )   node @ to FpNode  [char] > word count
    ignoreFloorPlan if  2drop exit  then
    ,string FpName ! ;

comments : <rgb ( -r*100 g*100 b*100>- )   ignoreFloorPlan if
        [char] > word count 2drop exit  then
    bl word count parseDecimal FpColor c!               \ red*100
    bl word count parseDecimal FpColor 1+ c!            \ green*100
    [char] > word count parseDecimal FpColor 2 + c! ;   \ blue*100

comments : <status ( -status>- )   [char] > word count
    ignoreFloorPlan if  2drop exit  then
    ,string FpStatus ! ;

comments : <function ( -text>- )   [char] > word count
    ignoreFloorPlan if  2drop exit  then
    ,string  FpFunction <link  forth , host ;

comments : <title ( -title>- )   [char] > word count
    ignoreFloorPlan if  2drop exit  then
    postpone comments  ,string dup count
    $create /arrowArray  doesArrows
    postpone host ;

comments : <read  ( n -name>- n )   ignoreFloorPlan if
        [char] > word count 2drop exit  then
    >in @  bl word count embeddedAddr dup >r
    ?dup if  nip  else  >in !  then
    iocsBits  [char] > word count ,string
    FpReads <link  forth ,  dup checkPort
    r> 0= if  dup  then  ,  host ;

comments : <write ( n -name>- n )   ignoreFloorPlan if
        [char] > word count 2drop exit  then
    >in @  bl word count embeddedAddr dup >r
    ?dup if  nip  else  >in !  then
    iocsBits  [char] > word count ,string
    FpWrites <link  forth ,  dup checkPort
    r> 0= if  dup  then  ,  host ;

: FpRun ( str len a n -- )   dup to FpNode + c@ 2/
    dup 1 and if  $1d5 ( 'r--- ) 2over evaluate drop  then  2/
    dup 1 and if  $115 ( '-d-- ) 2over evaluate drop  then  2/
    dup 1 and if  $175 ( '--l- ) 2over evaluate drop  then  2/
    dup 1 and if  $145 ( '---u ) 2over evaluate drop  then  2/
    dup 1 and if  $15d ( 'iocs ) 2over evaluate drop  then  2/
    drop 2drop ;

[defined] saveEvents [IF]
: FpRuntime ( -- )   #nodes 0 do    \ Add arrows for the runtime events
        s" ( <write  > )" files writeEvents host i FpRun
        s" ( <read  > )" files readEvents host i FpRun
    loop ;
[THEN]

0 value maxWidth
0 value maxLines
0 value maxSpace

: AdjustFloorPlanFrame ( -- )
    0  #nodes 0 do  i to FpNode
        FpName @ ?dup if  c@ max  then
        FpStatus @ ?dup if  c@ max  then  6 max
        FpFunction  begin  @link ?dup while
            dup >r cell+ @ c@ max r>
        repeat
    loop  2 + to maxWidth

    0  #nodes 0 do  i to FpNode  0
        FpFunction  begin  @link ?dup while
            >r 1+ r>
        repeat  max
    loop  5 + to maxLines

    0  #nodes 0 do  i to FpNode
        FpWrites  begin  @link ?dup while
            dup >r cell+ @ c@ max r>
        repeat
        FpReads  begin  @link ?dup while
            dup >r cell+ @ c@ max r>
        repeat
    loop  4 + to maxSpace ;

\ vectors for alternative graphical formats
[defined] textWidth 0= [IF] 0 value textWidth [THEN]
[defined] TextHeight 0= [IF] 0 value textHeight [THEN]

variable 'nodeCentered     : nodeCentered       'nodeCentered @ execute ;
variable 'nodeNumbered     : nodeNumbered       'nodeNumbered @ execute ;
variable 'nodeDirections   : nodeDirections   'nodeDirections @ execute ;
variable 'horizontalPath   : horizontalPath   'horizontalPath @ execute ;
variable 'verticalPath     : verticalPath       'verticalPath @ execute ;
variable 'diagonalPath     : diagonalPath       'diagonalPath @ execute ;

: nodeWide ( -- x*10 )   maxWidth 2 + textWidth * ;
: nodeHigh ( -- y*10 )   maxLines textHeight * 3 textWidth * + ;

: sizeX ( -- x*10 )   maxWidth              maxSpace 2 + + textWidth * ;
: sizeY ( -- y*10 )   maxLines textHeight * maxSpace 2 +   textWidth * + ;

: offsetX ( -- x*10 )   maxSpace 1+ textWidth * ;
: offsetY ( -- y*10 )   #rows 1- sizeY *  offsetX + ;

: >rectXY ( node -- x*10 y*10 ) \ Upper left corner
    #cols /mod  swap sizeX *  offsetX +
    swap sizeY *  offsetY swap - ;

create pathId   forth 10 allot host

: nodeId ( -- str len )   FpNode 0 <# # # #> ;

\ taken from the isqrt.mf translation of James Ulery's Computing Integer Square Roots
: isqrt ( n -- n' ) \ valid up to 3221225471 = $BFFFFFFF
    pad @ >r dup >r  0 ( nHat )  $8000 ( b )  15 ( bshft ) pad !
    begin  over ( nHat ) 2*  over ( b ) +
        pad @ ( bshft ) -1 + dup pad !
        dup 0< if  drop  else
            1 + 0 do  2*  loop
        then  r> dup >r over invert 1 + + dup 0<
        if  ( guess diff ) 2drop  else
            >r drop dup >r ( nHat b ) + r>
            r> r> drop dup
            if  >r  else  2drop
                >r drop r>
                r> pad ! exit 2 .?.
            then
        then
        ( b ) 2/ dup 0=
    until  r> 2drop
    >r drop r>
    r> pad ! ;

: diagonal ( x y -- x' y' )   offsetX dup * 2/ isqrt  rot over +  rot rot + ;

\ Make table of degree based offsets around node squares
create nodeDegrees   12 cells allot

: deg> ( deg -- adr )   30 / cells nodeDegrees + ;

: degreePath ( str1 len1 w|r str2 len2 deg -- )   FpNode >rectXY  rot deg> @ execute ;

\ abbreviations
: dP diagonalPath ;
: vP verticalPath ;
: hP horizontalPath ;
: nW swap nodeWide ;
: nH swap nodeHigh ;
: tW textWidth ;
: tH textHeight ;
: oX offsetX ;
: sq dup * 2/ isqrt ;
: ro rot over ;
: rr rot rot ;

\ diagonals
:noname   2swap >r >r rot >r                           2dup oX sq  ro - rr -  2swap r> 0= r> r> 0 dP ;   0 deg> !
:noname   2swap >r >r rot >r nW    +      swap         2dup oX sq  ro + rr -        r>    r> r> 1 dP ;  90 deg> !
:noname   2swap >r >r rot >r nW    +      nH    +      2dup oX sq  ro + rr +        r>    r> r> 2 dP ; 180 deg> !
:noname   2swap >r >r rot >r swap         nH    +      2dup oX sq  ro - rr +  2swap r> 0= r> r> 3 dP ; 270 deg> !

\ north
:noname   2swap >r >r rot >r nW 2/ + tH - swap         2dup oX - tW 2* +      2swap r> 0= r> r>   vP ;  30 deg> !
:noname   2swap >r >r rot >r nW 2/ + tH + swap         2dup oX - tW 2* +      2swap r> 0= r> r>   vP ;  60 deg> !

\ east
:noname   2swap >r >r rot >r nW    +      nH 2/ + tH - over oX + tW    - over       r>    r> r>   hP ; 120 deg> !
:noname   2swap >r >r rot >r nW    +      nH 2/ + tH + over oX + tW    - over       r>    r> r>   hP ; 150 deg> !

\ south
:noname   2swap >r >r rot >r nW 2/ + tH + nH    +      2dup oX + tW 2* -            r>    r> r>   vP ; 210 deg> !
:noname   2swap >r >r rot >r nW 2/ + tH - nH    +      2dup oX + tW 2* -            r>    r> r>   vP ; 240 deg> !

\ west
:noname   2swap >r >r rot >r swap         nH 2/ + tH - over oX - tW    + over 2swap r> 0= r> r>   hP ; 300 deg> !
:noname   2swap >r >r rot >r swap         nH 2/ + tH + over oX - tW    + over 2swap r> 0= r> r>   hP ; 330 deg> !

: connectWest  ( str len w|r -- str len w|r )   >r 2dup r@ s" west"  r@ if 300 else 330 then degreePath r> ;
: connectEast  ( str len w|r -- str len w|r )   >r 2dup r@ s" east"  r@ if 150 else 120 then degreePath r> ;
: connectNorth ( str len w|r -- str len w|r )   >r 2dup r@ s" north" r@ if  30 else  60 then degreePath r> ;
: connectSouth ( str len w|r -- str len w|r )   >r 2dup r@ s" south" r@ if 210 else 240 then degreePath r> ;

: connectRight ( str len w|r -- str len w|r )   FpNode #rows mod 1 and if connectWest  else connectEast  then ;
: connectLeft  ( str len w|r -- str len w|r )   FpNode #rows mod 1 and if connectEast  else connectWest  then ;
: connectDown  ( str len w|r -- str len w|r )   FpNode #cols /   1 and if connectSouth else connectNorth then ;
: connectUp    ( str len w|r -- str len w|r )   FpNode #cols /   1 and if connectNorth else connectSouth then ;

create iocsDirections \ Table of IOCS and special address directions
\ #   0-1   2-3   4-5   6-7   16-17   141   171
( 1 )  30 ,  60 , 330 , 300 ,     0 , 270 ,  90 ,   \ base orientation, upper left corner
( 2 )  60 ,  30 , 120 , 150 ,    90 , 180 ,   0 ,   \ flip horizontally, upper right (edge and corner)
( 3 ) 150 , 120 , 210 , 240 ,   180 , 270 ,  90 ,   \ flip diagonally, middle and right (edge and corner)
( 4 ) 300 , 330 , 240 , 210 ,   270 , 180 ,   0 ,   \ rotate left, lower left (edge and corner)
( 5 ) 240 , 210 , 300 , 330 ,   270 ,   0 , 180 ,   \ flip vertically, bottom edge

: iocsOrientation ( -- # )   FpNode #nodes #cols - 2dup = if  2drop 0 exit
    then  > if  1 exit  then  FpNode #cols mod 0= if  3 exit  then
    FpNode #cols 1- < if  4 exit  then  2 ;

: orientDirection ( n -- deg )   cells iocsOrientation 7 cells * iocsDirections + + @ ;

: connectIocs ( str len adr w|r -- str len w|r )   >r
    dup $1FF and $15d - abort" undefined port"          \ we should not be here!
    9 rshift >r  2dup  r> r@ swap s" iocs" pathId place
    dup 0 <# #s #> pathId append  pathId count
    rot orientDirection degreePath r> ;

: connectAddr ( str len w|r -- str len w|r )   >r 2dup r@ s" addr" 6 orientDirection degreePath r> ;
: connectData ( str len w|r -- str len w|r )   >r 2dup r@ s" data" 5 orientDirection degreePath r> ;

: connectPort ( adr str len w|r -- )   >r rot case
        $1a5 of r> connectRight connectDown connectLeft connectUp endof \ 'rdlu
        $1b5 of r> connectRight connectDown connectLeft           endof \ 'rdl-
        $185 of r> connectRight connectDown             connectUp endof \ 'rd-u
        $195 of r> connectRight connectDown                       endof \ 'rd--
        $1e5 of r> connectRight             connectLeft connectUp endof \ 'r-lu
        $1f5 of r> connectRight             connectLeft           endof \ 'r-l-
        $1c5 of r> connectRight                         connectUp endof \ 'r--u
        $1d5 of r> connectRight                                   endof \ 'r---
        $125 of r>              connectDown connectLeft connectUp endof \ '-dlu
        $135 of r>              connectDown connectLeft           endof \ '-dl-
        $105 of r>              connectDown             connectUp endof \ '-d-u
        $115 of r>              connectDown                       endof \ '-d--
        $165 of r>                          connectLeft connectUp endof \ '--lu
        $175 of r>                          connectLeft           endof \ '--l-
        $145 of r>                                      connectUp endof \ '---u
        $171 of r> connectAddr endof    \ 'addr
        $141 of r> connectData endof    \ 'data
                        r> connectIocs 0    \ 'iocs
    endcase  drop 2drop ;

: writeConnector ( adr str len -- )   0 connectPort ;
:  readConnector ( adr str len -- )   1 connectPort ;

[defined] svgWidth 0= [IF]
    v.VF +include" Plugins/Graphics/svg/svg.f"  svg.version 1 checkPlugin [THEN]
v.VF +include" Plugins/Graphics/svg/FloorPlan.f"  svgFloorPlan.version 1 checkPlugin

[defined] pdfWidth 0= [IF]
    v.VF +include" Plugins/Graphics/pdf/pdf.f"  pdf.version 3 checkPlugin [THEN]
v.VF +include" Plugins/Graphics/pdf/FloorPlan.f"  pdfFloorPlan.version 2 checkPlugin

[THEN]
