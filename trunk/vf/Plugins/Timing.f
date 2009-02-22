\ Timing.f - Create graphical output of timing events

FORTH
v.VF +include" Plugins/Plugins.f"  Plugins.version 7 checkPlugin
v.VF +include" Plugins/strings.f"  strings.version 4 checkPlugin
v.VF +include" Plugins/Events.f"  Events.version 3 checkPlugin
v.VF +include" Plugins/Projects.f"  Projects.version 12 checkPlugin

[defined] Timing.version 0= [IF]

4 constant Timing.version

fileList TimingFiles   addZip ," vf/Plugins/Timing.zip"
    addFile ," vf/Plugins/doc/pfDatabase.pdf"
    addFile ," vf/Plugins/doc/Timing.pdf"
    addFile ," vf/Plugins/Timing.f"
    addFile ," vf/Plugins/Graphics/pdf/Timing.f"
    addFile ," vf/Plugins/Graphics/pdf/pdf.f"
    addFile ," vf/Plugins/Graphics/svg/Timing.f"
    addFile ," vf/Plugins/Graphics/svg/svg.f"
    addFile ," vf/Plugins/File.fth"
    addFile ," vf/Plugins/File/csvParser.fth"
    addFile ," vf/Plugins/File/Index.fth"
    addFile ," vf/Plugins/File/Memory.fth"
    addFile ," vf/Plugins/File/Reports.fth"
    addFile ," vf/Plugins/File/Sort.fth"
    addFile ," vf/Plugins/File/Struct.fth"
    addFile ," vf/Plugins/File/Support.fth"
    addFile ," vf/Plugins/File/Examples/Accounts.dbf"
    addFile ," vf/Plugins/File/Examples/Accounts.fth"
    addFile ," vf/Plugins/File/Examples/Customers.dbf"
    addFile ," vf/Plugins/File/Examples/Customers.fth"
    addFile ," vf/Plugins/File/Examples/Glossary.dbf"
    addFile ," vf/Plugins/File/Examples/Glossary.fth"
    addFile ," vf/Plugins/File/Examples/People.dbf"
    addFile ," vf/Plugins/File/Examples/People.fth"
    addFile ," vf/Plugins/File/Examples/Personnel.dbf"
    addFile ," vf/Plugins/File/Examples/Personnel.fth"
    addFile ," vf/Plugins/File/Examples/Wines.dbf"
    addFile ," vf/Plugins/File/Examples/Wines.fth"
    addFile ," vf/Plugins/FileNames.f"
    addFile ," vf/Plugins/idForth.f"
    addFile ," vf/Plugins/Events.f"
    addFile ," vf/Plugins/LaTeX.f"
    addFile ," vf/Plugins/links.f"
    addFile ," vf/Plugins/Plugins.f"
    addFile ," vf/Plugins/Projects.f"
    addFile ," vf/Plugins/strings.f"
    addFile ," vf/Plugins/notail.f"
    addFile ," vf/Plugins/numbers.f"
    addFile ," vf/gforth.fs"
    addFile ," projects/FdCheck/FdCheck.vf"
    addFile ," projects/FdCheck/BlinkLED.vf"
    addFile ," projects/FdCheck/Echo.vf"
    addFile ," projects/FdCheck/USBCom.f"
    addFile ," projects/FdCheck/check-pass.vf"
    addFile ," projects/FdCheck/check-receive.vf"
    addFile ," projects/FdCheck/check-report.vf"
    addFile ," projects/FdCheck/checksum.vf"
    addFile ," projects/FdCheck/FloorPlan.htm"
    addFile ," projects/FdCheck/FloorPlan.pdf"
    addFile ," projects/FdCheck/FloorPlan.svg"
    addFile ," projects/FdCheck/project.bat"
    addFile ," projects/FdCheck/project.vfp"
    addFile ," projects/FdCheck/Timing.htm"
    addFile ," projects/FdCheck/Timing.pdf"
    addFile ," projects/FdCheck/Timing.svg"

: Timing.zip ( -- ) \ create archive of Timing plug in
    TimingFiles zipFiles ;

: TimingHelp ( -- )
    s" The only words that are needed to generate Timing diagrams are the" >fileLine
    s" words \begin{bf}svgTiming\end{bf} and \begin{bf}pdfTiming\end{bf}," >fileLine
    s" which create SVG or PDF diagrams, respectively.  However, you do" >fileLine
    s" have to set up the VentureForth simulator so that it will save the timing" >fileLine
    s" events that you want to see on the diagram.  See the Events Help" >fileLine
    s" section for those details." >fileLine
        fileCr
    s" You also may want to change the order of the nodes in the Timing" >fileLine
    s" diagram.  The value of \begin{bf}NodeOrder\end{bf} defaults to the" >fileLine
    s" the address of an array that containes a sequential list of node" >fileLine
    s" number bytes, terminated with a -1.  If you want a different order" >fileLine
    s" or to only display selected nodes, you can set \begin{bf}NodeOrder\end{bf}" >fileLine
    s" to your own array of node numbers.  Remember to always terminate the" >fileLine
    s" list with a -1." >fileLine
;

: includeTiming ( str1.len str2.len -- )
    s" \begin{figure}" >fileLine
    s" \begin{picture}(200,600)(0,0)" >fileLine
    s" \put(-10,-45){\resizebox{15 cm}{!}{\includegraphics{" >fileStr
        >fileStr  s" }}}" >fileLine
    s" \end{picture}" >fileLine
    s" \caption{{\em " >fileStr  >fileStr  s" }}" >fileLine
    s" \end{figure}" >fileLine ;

: TimingHistory ( -- )   s" Timing Diagrams Historical Background" subSection
    s" The problem it is designed to solve" subSection
    s" Normally, timing diagrams are documented as part of a design" >fileLine
    s" specification, which is then used as a guideline to meet the" >fileLine
    s" inter node communication timing requirements, while developing" >fileLine
    s" the multiprocessor program code.  The problem with that approach" >fileLine
    s" is the actual hardware timing is unknown, so the programmer has" >fileLine
    s" to use trial and error techniques to close in on the actual hardware" >fileLine
    s" timing that will execute the code correctly, which is a very time" >fileLine
    s" consuming process for debugging." >fileLine
    endSection fileCr
    s" What it is and how it does it" subSection
    s" The inventive method is that the application code itself includes" >fileLine
    s" functions that determine the inter node timing, as it executes." >fileLine
    s" The code does this by first capturing data from an event driven" >fileLine
    s" simulator that is expected to represent accurate timing information" >fileLine
    s" for the hardware.  Then the code generates timing diagrams from that" >fileLine
    s" data, which are used by an engineer to compare and analyze the code" >fileLine
    s" behavior as it executes in the target multiprocessor array hardware." >fileLine
    s" The engineer uses this method to determine if the actual hardware" >fileLine
    s" events for a given instruction sequence correlates to the expected" >fileLine
    s" events that were simulated.  This is a big advantage to reducing" >fileLine
    s" debug time, because this method allows the developer to have visibilty" >fileLine
    s" of actual timing internal to the chip, which is otherwise not accessible." >fileLine
    s" Also, it is anticipated that the developer will use a standard technique" >fileLine
    s" of placing 'dummy' code in nodes while doing design and analysis to see" >fileLine
    s" timing in advance, as a part of the design step.  That is a novel use of" >fileLine
    s" the simulator/chip combination to produce documentation, rather than just" >fileLine
    s" hand drawing these sorts of diagrams as is normally done." >fileLine
    s" \footnote{Invention Disclosure 07-0050 by Dave Dalglish 30 Aug 07}" >fileLine
    endSection endSection ;

: TimingExample ( -- )   s" Timing Diagrams Example" subSection
    s" The following lines are the portions of the FdCheck application" >fileLine
    s" that are required to use these features." >fileLine
        fileCr
    s" \begin{tiny}" >fileLine
    s" \begin{verbatim}" >fileLine
    s\" v.VF +include\" Plugins/Timing.f\"  Timing.version 4 checkPlugin" >fileLine
        fileCr
    s" : checksum ( -- sum id )     \ assumes it can trash the a pointer" >fileLine
    s"     [defined] saveEvents [if] ( assert: saveEvents ; ) [then]" >fileLine
    s"     dup dup xor dup" >fileLine
        fileCr
    s" [defined] FloorPlan.version [IF]  svgFloorPlan pdfFloorPlan" >fileLine
    s" [THEN] [defined] Events.version [IF]" >fileLine
    s"     /Events \ saveEvents drop \ uncomment to see load" >fileLine
    s" [THEN]  power" >fileLine
        fileCr
    s" cr .( Running simulation testing... ) cr" >fileLine
    s" 1 goes decimal cr summary cr" >fileLine
        fileCr
    s" [defined] Timing.version [IF]" >fileLine
    s"     svgTiming pdfTiming cr" >fileLine
    s" [THEN]" >fileLine
    s" \end{verbatim}" >fileLine
    s" \end{tiny}" >fileLine
        fileCr
    s" The FdCheck's Timing Diagram"
    s" ../../../projects/FdCheck/Timing"
    includeTiming
        fileCr
    s" The figure that follows shows the resulting Timing diagram.  Note" >fileLine
    s" that transfers that are written to the right are colored green" >fileLine
    s" with the left half of an X appearing at both ends of the line." >fileLine
    s" Transfers to the left use blue and the right half of the X." >fileLine
    s" If you look closely, you will see a double X where node 19" >fileLine
    s" writes to IOCS (actually twice).  Using the zoom capability" >fileLine
    s" of your viewer is essential with these diagrams." >fileLine
    endSection ;

: Timing.tex ( -- )   v.VF pad place s" Plugins/doc/Timing" pad append
    pad count 2dup texBook  s" Dennis Ruffer" s" Timing Diagrams" texTitle
    TimingHistory fileCr
    TimingFiles InstallingPlugins fileCr
    ProjectArtifacts fileCr
    s" Timing Diagrams User Interface" subSection
        TimingHelp fileCr
        EventsSection fileCr
        pFDatabaseSection fileCr
    endSection
    TimingExample fileCr
    endTex ;

HOST

[defined] MHz 0= [IF] 1000 value MHz [THEN]

0 value 1stTime
0 value lastTime

0 value baseLine
0 value lastLine

25 value nodeSize
 5 value nodeSpace
15 value nodeScale
10 value nodeMargin
 0 value numberMargin

6 value xchgSize

: /nodeOrder ( -- )   #nodes 0 do  i c,  loop  -1 c, ;

0 value nodeOrder   forth here host to nodeOrder  /nodeOrder

: numberNodes ( -- n )   nodeOrder 0 begin
        swap count 255 - while  swap 1+
    repeat  drop ;

: findNode ( i -- i' flag )   -1  begin
    1+ 2dup nodeOrder + c@ dup 255 = if
        drop 2drop true exit
    then  = if  nip false exit
    then  again ;

\ vectors for alternative graphical formats
[defined] textWidth 0= [IF] 0 value textWidth [THEN]
[defined] TextHeight 0= [IF] 0 value textHeight [THEN]

variable 'AdjustTimingFrame   : AdjustTimingFrame   'AdjustTimingFrame @ execute ;
variable 'nodeCenter          : nodeCenter                 'nodeCenter @ execute ;
variable 'nodeBox             : nodeBox                       'nodeBox @ execute ;
variable 'drawXchg            : drawXchg                     'drawXchg @ execute ;
variable 'drawSleep           : drawSleep                   'drawSleep @ execute ;
variable 'drawScale           : drawScale                   'drawScale @ execute ;
variable 'startPath           : startPath                   'startPath @ execute ;
variable 'finishPath          : finishPath                 'finishPath @ execute ;
variable 'workPath            : workPath                     'workPath @ execute ;
variable 'drawPath            : drawPath                     'drawPath @ execute ;

: nodeColumn ( i -- px )   dup findNode if
        drop  cr ." Node " . ." is not in nodeOrder table"  abort
    else  nip  then  nodeSize nodeSpace + * ;

create numberBuffer   s" 4.999.999.999 s " ,string c@ to numberMargin

: bufferNumber ( n -- str len )   0 <# #s #> numberBuffer place  numberBuffer count ;
: bufferTime ( n -- str len )
    1000 MHz */  0 0 numberBuffer place  0 >r
    0 1000 um/mod ?dup if
        0 1000 um/mod ?dup if
            0 1000 um/mod ?dup if
                0 <# #s #> numberBuffer append  r> drop 3 >r
            then  ?dup if
                r> dup if  [char] . numberBuffer cappend
                else  drop 2  then  >r  0 <# #s #> numberBuffer append
            then
        then  ?dup if
            r> dup if  [char] . numberBuffer cappend
            else  drop 1  then  >r  0 <# #s #> numberBuffer append
        then
    then  ?dup if
        r> dup if  [char] . numberBuffer cappend
        else  drop 0  then  >r  0 <# #s #> numberBuffer append
    then  numberBuffer c@ 0= if  r> drop 3 >r
\       s" 4.999.999.999" numberBuffer append
        0 0 <# #s #> numberBuffer append
    then  r> case
        0 of s"  ns" endof
        1 of s"  us" endof
        2 of s"  ms" endof
        3 of s"  s" endof
    endcase  numberBuffer append  numberBuffer count ;

0 value iocsEvent

: otherNode ( i port -- x )   0 to iocsEvent  over >r  case \ the invalid port case is used for iocs
        1 of      1 2dup     and if - else + then  endof    \ right
        2 of  #cols 2dup / 1 and if - else + then  endof    \ down
        3 of      1 2dup     and if + else - then  endof    \ left
        4 of  #cols 2dup / 1 and if + else - then  endof    \ up
        dup of  true to iocsEvent  endof                    \ iocs
    endcase  dup 0 #nodes within  r> swap if
        over findNode nip if  swap
    then  else  swap  then
    drop  nodeCenter ;

0 value scaleIncrement

: calculateIncrement ( -- h l )   lastTime 1stTime
    2dup - 1  begin  2dup / 20 > while  10 *  repeat
    2dup / 5 < if  2/  then  to scaleIncrement drop ;

0 value nodeX           \ node center if working
0 value nodeY           \ time + baseline if working
0 value saveY           \ y position of previous event
0 value writeFlag       \ true = write events get drawn
0 value pathDirection   \ true = left, false = right

: pathLeft ( x y -- x y nx ny x y flag )   nodeX nodeY 2over
    2over 2over drop nip > dup to pathDirection ;

: drawPaths ( -- )   files sortNodes host  -1
    0 to nodeX  0 to nodeY  false to writeFlag  0 to saveY
    files NodeEvents RECORDS ?DO
        NodeEvents I READ  LINK L@
        EventsData READ  eventNode 1@
        dup host findNode if  2drop  else           \ ignore node if not in list
            drop swap 2dup - if                     \ node change
                finishPath                          \ finish previous node's tail
                dup startPath                       \ Start path at top
                false to writeFlag  0 to saveY      \ Make sure we start events
            else  drop
            then  files eventLocal 1@ ?dup if       \ Start of event

                host 1 = to writeFlag               \ Write events will be drawn
                saveY ?dup if
                    to nodeY                        \ save y of previous event
                then  0 to saveY
                files eventTime D@ d>s host
                1stTime - workPath                  \ Path from previous event

            else  iocsEvent if
                    files eventR-W 1@ host          \ iocs needs to also check for writes
                    1 = to writeFlag  then
                dup files eventPort 1@ host otherNode       \ End of event, calculate x
                files eventTime D@ d>s host 1stTime - baseLine +    \ fill in y vector
                writeFlag if  drawPath              \ Only draw write events
                    2dup drawXchg
                then  to saveY drop
            then
        then
    LOOP  finishPath ;                              \ finish last node's tail

[defined] svgWidth 0= [IF] v.VF +include" Plugins/Graphics/svg/svg.f" [THEN]
v.VF +include" Plugins/Graphics/svg/Timing.f"

[defined] pdfWidth 0= [IF] v.VF +include" Plugins/Graphics/pdf/pdf.f" [THEN]
v.VF +include" Plugins/Graphics/pdf/Timing.f"
[THEN]
