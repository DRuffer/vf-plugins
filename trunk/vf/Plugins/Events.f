\ Events.f - VentureForth Simulator Events database

v.VF +include" Plugins/Plugins.f"  Plugins.version 7 checkPlugin
v.VF +include" Plugins/File.fth"  File.version 4 checkPlugin  host

[defined] >opcode 0= [IF] : >opcode ( op -- a )   16 * instructions + ; [THEN]

[defined] Events.version 0= [IF]

3 constant Events.version

: EventsHook ( -- )
    s" This plugin requires a hook in VentureForth's port logic like this:" >fileLine
    s" variable 'Event   0 'Event !" >fileLine
    s" : !Event   'Event @ ?dup if  execute  then ;" >fileLine
        fileCr
    s" : !lcl   local !  !Event ;   ( don't ask, don't tell)" >fileLine
    s" ..." >fileLine
    s" : /iocs   /clk commit ( n - n')" >fileLine
    s"    adrs @ psel 2@ on? if  1+  !Event" >fileLine
    s" ..." >fileLine ;

[defined] 'Event 0= [IF]  EventsHook  'Event drop  [THEN]

decimal  files  FILE Events.dbf

\ Define the index fields:
4 ( LINK )  1BYTE nodeEvent  DROP

\ Define the data fields:
0 DOUBLE eventTime
   1BYTE eventNode
   1BYTE eventPort
   1BYTE eventR-W
   1BYTE eventLocal
   1BYTE eventOpcode
 NUMERIC eventAddress
    LONG eventS
    LONG eventT
    LONG eventR
    LONG eventB
    LONG eventA
CONSTANT |Event|

( Bytes  records  origin            name )
      5   300000       0 BLOCK-DATA NodeEvents
|Event|   300000 +ORIGIN BLOCK-DATA EventsData

host \ Initialize the files if there is anything in them.
: /Events ( -- )   files Events.dbf [defined] ForTimbre [IF]
        s" Events.dbf" >FILE  FILE-HANDLE @ IF
            -FILE  THEN  DESTROY-FILE DROP
    [ELSE]  0 0 >MEMORY  [THEN]
    NodeEvents RECORDS - IF  INITIALIZE
        EventsData INITIALIZE
    THEN ;

create readEvents    host #nodes /allot files
create writeEvents   host #nodes /allot files

: sumEvent ( -- )   \ summarize the events for each node
    1 eventPort 1@ 6 min lshift
    eventR-W 1@ case
        1 of  writeEvents  endof
        2 of  readEvents  endof
        >r drop 0 r>
    endcase  ?dup if
        eventNode 1@ + dup c@ rot or swap c!
    then ;

\ Add an event record
: +Event ( rw local port a b r t s pc opcode node dns -- )
    SAVE  Events.dbf  EventsData ['] SLOT CATCH ?DUP IF  RESTORE THROW
    THEN  DUP >R READ
    eventTime D!
    DUP >R eventNode 1!
    eventOpcode 1!
    eventAddress N!
    eventS L!
    eventT L!
    eventR L!
    eventB L!
    eventA L!
    eventPort 1!
    eventLocal 1!
    eventR-W 1!  sumEvent
    NodeEvents SLOT READ
    R> nodeEvent 1!
    R> LINK L!
    RESTORE ;

: TimeFrame ( -- last 1st )   Events.dbf  EventsData
    AVAILABLE 4 nC@ READ  eventTime D@ d>s
    1 READ  eventTime D@ d>s ;

\ Generate report

: .Event ( -- )   BASE @ DECIMAL
    eventTime ?D  eventNode ?1  HEX
    eventOpcode 1@ host >opcode files 8 + 8 -trailing RIGHT
    eventR-W ?1
    eventLocal 1@ case
        0 of s" idle" endof
        1 of s" write" endof
        2 of s" read" endof
        dup >r dup abs 0 <# #s rot sign #> r>
    endcase  LEFT
    eventPort 1@ case
        1 of s" right" endof
        2 of s" down" endof
        3 of s" left" endof
        4 of s" up" endof
        5 of s" iocs" endof
        dup >r dup abs 0 <# #s rot sign #> r>
    endcase  LEFT
    eventAddress ?N
    eventS ?L
    eventT ?L
    eventR ?L
    eventB ?L
    eventA ?L
    BASE ! ;

[R                     Events\    Time\Node\  Opcode\rw\Local\Port\Address\     S\     T\     R\     B\     A]
   CONSTANT eventTitle

: .Events ( -- )   eventTitle LAYOUT  +L
    EventsData RECORDS ?DO
        I READ  .Event  +L
    LOOP ;

false value nodesSorted
: sortNodes ( -- )   nodesSorted 0= if
        Events.dbf  NodeEvents  nodeEvent 1SORT
    then  true to nodesSorted ;

: .SortedEvents ( -- )   eventTitle LAYOUT  +L
    NodeEvents RECORDS ?DO
        NodeEvents I READ  LINK L@
        EventsData READ .Event  +L
    LOOP ;

host

: EventsHelp ( -- )
    s" The Events plug in extends the VentureForth simulator to record timing" >fileLine
    s" events in a memory resident database.  The database details" >fileLine
    s" are not required to use this plug in, but you can see the" >fileLine
    s" pfDatabase Help section for documentation." >fileLine
        fileCr
    s" The commands that you do need to know involve routines that" >fileLine
    s" control when data is stored into the Events database and" >fileLine
    s" running the VentureForth simulator until some condition is met." >fileLine
    s" Both the storing of event data and the display of simulator" >fileLine
    s" information are time consuming, which you may want to avoid" >fileLine
    s" when running the simulator.  The following commands give you" >fileLine
    s" control over those features:" >fileLine
        fileCr
    s" \begin{description}" >fileLine
    s" \item[\texttt{/Events}] initializes the Events database." >fileLine
    s" \item[\texttt{n goes}] runs the simulator until n 'finishes' or a key is pressed." >fileLine
    s" \item[\texttt{continue}] continues running the simulator after a key is pressed." >fileLine
    s" \item[\texttt{FinishTests drop}] an assertion to decrement 'finishes'." >fileLine
    s" \item[\texttt{saveEvents drop}] an assertion to store events." >fileLine
    s" \item[\texttt{ignoreEvents drop}] an assertion to ignore events." >fileLine
    s" \item[\texttt{lo hi timedEvents}] start storing events when the" >fileLine
        s" simluation clock is greater than or equal to lo and stop the" >fileLine
        s" simulation when the clock is greater than or equal to hi." >fileLine
    s" \end{description}" >fileLine
        fileCr
    s" The 'assertion' commands are designed to work with the Test Suite" >fileLine
    s" plug in, but can be used independently by dropping the flag that" >fileLine
    s" they return.  Assertions provide more options for controling the" >fileLine
    s" simulator, but it is typically sufficient to just do the following:" >fileLine
        fileCr
    s" \begin{verbatim}" >fileLine
    s" 0 10000 timedEvents  1 goes" >fileLine
    s" \end{verbatim}" >fileLine
        fileCr ;

: EventsSection ( -- )   s" Events Help" subSection
    s" \begin{verbatim}" >fileLine
    EventsHook
    s" \end{verbatim}" >fileLine
        fileCr
    EventsHelp
    endSection ;

[defined] xFinished 0= [IF] variable xFinished

: continue ( -- )   begin
      step  xFinished @ 0> 0=  key? or
   until  key? if  key abort"  type: continue"  then ;
: goes ( n -- )   xFinished !  continue ;

: FinishTests ( -- true )   -1 xFinished +!  true ;
[THEN]

0 value saveEvents?
: saveEvents ( -- true )   true to saveEvents?  true ;
: ignoreEvents ( -- true )   false to saveEvents?  true ;

0 value startEvents
0 value stopEvents
: timedEvents ( start stop -- )   to stopEvents  to startEvents ;
: timeEvents ( -- )  stopEvents ?dup if
        @ns startEvents rot within if
            saveEvents? 0= if
                saveEvents drop
            then
        else  saveEvents? if
                ignoreEvents drop
                FinishTests drop
            then
        then
    then ;

: !Event? ( -- )   timeEvents  saveEvents? if
        r-w @ local @ port @ a @ b @ r @ t @ s @
        pc @ slot @ cells slots + @ node @ @ns
        files +Event host
    then ;

' !Event? 'Event !
[THEN]
