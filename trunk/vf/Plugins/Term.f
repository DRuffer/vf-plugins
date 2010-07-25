#! /usr/bin/env gforth
\ 		File:	Term.f
\
\ 	Contains:	Serial terminal support for GForth
\				Original source written by Dennis Ruffer, last updated on 30 May 1994
\				Translated to GForth starting on 22 Apr 2004
\
\	   Usage:	gforth Term.f -e WATCHER

v.VF +include" Plugins/Plugins.f"  Plugins.version 7 checkPlugin
v.VF +include" Plugins/Serial/TestSerial.f"  TestSerial.version 1 checkPlugin

[defined] Term.version 0= [IF]

2 constant Term.version

: SerialSupport ( -- )   s" Serial Port Support" subSection
	s" The code that is being used for serial port support has been in" >fileLine
	s" my tool box for decades now.  I pull it out, from time to time," >fileLine
	s" brush off the cobwebs and make it work on whatever platform I" >fileLine
	s" happen to be working on at the time.  It has run on PCs using" >fileLine
	s" native polyForth, on Windows using SwiftForth, and now on Macs" >fileLine
	s" using gforth.  It has been a personal toy, so documentation and" >fileLine
	s" regression testing have not been high priorities, and it has" >fileLine
	s" plenty of 'undocumented features' (e.g. bugs).  However, it has" >fileLine
	s" also proven to be quite useful, from time to time, as a quick" >fileLine
	s" means to monitor a serial port." >fileLine
		fileCr
	s" This latest incarnation went unused for many years, as I tried" >fileLine
	s" to make it work in OSX.  It finally took converting the machine" >fileLine
	s" code to gforth's latest PowerPC assembler for me to see what I" >fileLine
	s" had been doing wrong.  Now, it can finally be used again, on" >fileLine
	s" my latest platform of choice." >fileLine
		fileCr
	s" I have learned quite a lot about platform independence since this" >fileLine
	s" code last saw the light of day, and someday, I will need to apply" >fileLine
	s" those principles to this code.  However, at the moment, it solves" >fileLine
	s" the immediate issues and using Apple's Rosetta technology, it works" >fileLine
	s" on both PowerPC and Intel machines.  Restoring the functionality" >fileLine
	s" in SwiftForth, or gforth on cygwin, might take a little work, but" >fileLine
	s" I don't anticipate any serious show stoppers." >fileLine
		fileCr
	s" This code attempts to implement a full terminal emulator, with ADM3A" >fileLine
	s" and VT100-300 interpreters.  Since that is not a requirement of the" >fileLine
	s" current applications, I will not attempt to document these features" >fileLine
	s" at this point in time.  Since it is sometimes useful to view the" >fileLine
	s" characters being received, I will say that WATCHER will show them" >fileLine
	s" to you, and the ESC key will get you out of that mode, but beyond" >fileLine
	s" that, the source code is the only documentation that exists." >fileLine
		fileCr
	s" All that does need to be documented is the portions of this code that" >fileLine
	s" are being used by these applications.  That would be the port control" >fileLine
	s" block structure, port initialization and buffer manipulation." >fileLine
;

FORTH DEFINITIONS

TRUE VALUE USE-AUX-THREADING

: >< ( x -- x' )   65535 AND 16 /MOD SWAP 16 * + ;
: (.) ( n -- str len )   BASE @ >R DECIMAL 0 <# #S #> R> BASE ! ;
: @EXECUTE ( ... a -- ... )   @ ?DUP IF  EXECUTE  THEN ;
: 2C@ ( a -- {a+1} {a} )   COUNT SWAP C@ SWAP ;
: 2C! ( x1 x2 a -- )   SWAP OVER C! 1+ C! ;

\ System Flag Bit Operators

\ 2**  Raise the given number to the power of 2.  The maximum
\    input will be 1 less that the system cell size.
: 2** ( # -- n   P: Raise to the power of 2 )   1 SWAP LSHIFT ;

\ @B  Fetch a flag bit from the given array.  A valid truth flag
\    will be returned.
: @B ( a # -- f   P: Fetch flag )   8 /MOD ROT + C@
       SWAP 2** AND  0= 0= ;

\ !B  Store a flag bit into the given array.  The truth value will
\    be represented as a bit in the array.
: !B ( f a # --   P: Store flag )   8 /MOD ROT +  DUP >R C@
       SWAP 2**  ROT IF  OR  ELSE  -1 XOR AND  THEN  R> C! ;

\ Port control block creation

: PortControlBlock ( -- )   s" Port Control Block" subSection
	s" The port control block structure is defined here.  Input and output buffer" >fileLine
	s" pointers are defined for each control block.  The definition of the receive" >fileLine
	s" input pointer REAR-IN is defined as task specific." >fileLine
		fileCr
	s" \begin{description}" >fileLine
	s" \item[\texttt{AUX-PORT}]Port handle" >fileLine
	s" \item[\texttt{AUX-Task}]Port task address" >fileLine
	s" \item[\texttt{AUX-RCode}]Port read threaded code" >fileLine
	s" \item[\texttt{AUX-WCode}]Port write threaded code" >fileLine
	s" \item[\texttt{AUX-RThread}]Port read thread address" >fileLine
	s" \item[\texttt{AUX-WThread}]Port write thread address" >fileLine
	s" \item[\texttt{BUFFER-IN}]Address of input buffer" >fileLine
	s" \item[\texttt{SIZE-IN}]Size-1 of input buffer" >fileLine
	s" \item[\texttt{FRONT-IN}]Offset to head of input buffer" >fileLine
	s" \item[\texttt{BUFFER-OUT}]Address of output buffer" >fileLine
	s" \item[\texttt{SIZE-OUT}]Size-1 of output buffer" >fileLine
	s" \item[\texttt{FRONT-OUT}]Offset to head of output buffer" >fileLine
	s" \item[\texttt{REAR-OUT}]Transmit buffer pointer" >fileLine
	s" \end{description}" >fileLine
		fileCr
	s" Each of these words takes the address of a Port Control Block" >fileLine
	s" and returns the address of the respective field.  Each field is" >fileLine
	s" one cell wide.  The word AUX returns the address of the current" >fileLine
	s" Port Control Block, which is held in the variable 'AUX." >fileLine
	endSection ;

USER REAR-IN ( -- a   P: Receive buffer pointer )
USER 'AUX ( -- a   P: Port buffer structure )

: auxField ( a n -- a+n )   over create ,  +
   does> ( a -- a' )   @ + ;

0 \ aux-buf
	cell auxField AUX-PORT		( a -- a'   P: Port handle )
	cell auxField AUX-Task		( a -- a'   P: Port task address )
	cell auxField AUX-RCode		( a -- a'   P: Port read threaded code )
	cell auxField AUX-WCode		( a -- a'   P: Port write threaded code )
	cell auxField AUX-RThread	( a -- a'   P: Port read thread address )
	cell auxField AUX-WThread	( a -- a'   P: Port write thread address )
	cell auxField AUX-Termios	( a -- a'   P: Port setup structure )
	cell auxField BUFFER-IN		( a -- a'   P: Address of input buffer )
	cell auxField SIZE-IN		( a -- a'   P: Size-1 of input buffer )
	cell auxField FRONT-IN		( a -- a'   P: Offset to head of input buffer )
	cell auxField BUFFER-OUT	( a -- a'   P: Address of output buffer )
	cell auxField SIZE-OUT		( a -- a'   P: Size-1 of output buffer )
	cell auxField FRONT-OUT		( a -- a'   P: Offset to head of output buffer )
	cell auxField REAR-OUT		( a -- a'   P: Transmit buffer pointer )
constant |aux-buf|

\ System Flags

VARIABLE CURSOR ( -- a   P: Cursor mode )				\ Not really implemented yet.
VARIABLE PACE   ( -- a   P: Pacing delay )				\ Time to wait between output chrs.
VARIABLE ECHOED ( -- a   P: Local echo flag )			\ True if displaying local keys.
VARIABLE LOCK   ( -- a   P: Keyboard lock flag )		\ True if keyboard disabled.
VARIABLE XOFF   ( -- a   P: Remote is stopped )			\ True if XOFF sent to remote.
VARIABLE PEX    ( -- a   P: Print extent flag )			\ True if print past window.
VARIABLE PFF    ( -- a   P: Print Form Feed flag )		\ True if page after print.
VARIABLE PCM    ( -- a   P: Printer Controller Mode )	\ True if sending only to printer.
VARIABLE LNM    ( -- a   P: Line Feed/New Line Mode )	\ True if LF does a CR.

CREATE TOP		 0 C,  0 C,
CREATE BOTTOM	79 C, 24 C,

VARIABLE ATTRIBUTE
VARIABLE PAGE#

: !PAGE ( n -- )   PAGE# ! ;
: TAB ( l c -- )   SWAP AT-XY ;

\ VT100 display control

: KEYS>N ( c -- n )   >R 0
	BEGIN  KEY R@ - ?DUP
	WHILE  R@ + [CHAR] 0 - +
	REPEAT  R> DROP ;

: CPR ( -- l c )   ESC[ ." 6n"  KEY 27 =
	IF  KEY [CHAR] [ =
		IF  [CHAR] ; KEYS>N 1-
			[CHAR] R KEYS>N 1-  EXIT  THEN
	THEN  TRUE ABORT" Invalid DSR response" ;

WARNINGS OFF
: REVERSE ( -- )   ESC[ ." 7m" ;
: NORMAL  ( -- )   ESC[ ." 0m" ;
WARNINGS ON

\ State Machine

\ CHRS  Lookup state vector address for character processing.
VARIABLE CHRS ( -- a   P: Lookup state vector )

\ CHRED  Execute state vector for a character.
: CHRED ( ... b -- ...   P: Execute state )   CHRS @EXECUTE ;

\ UNCHR  Undo a key sequence by clearing the state vector and
\    dropping anything left on the stack.  Top item is saved.
: UNCHR ( ... n -- n   P: Undo a key sequence )   CHRS OFF
          DEPTH 1 > IF  >R  DEPTH 0 DO  DROP  LOOP  R>  THEN ;

\ Port Control Block Functions

: AUX ( -- a   P: Get port control block address )   'AUX @ ;

: help{PURGE}   s" \item[\texttt{PURGE}]" >fileLine
	s" Clear buffer pointers for both receive and transmit." >fileLine
	s" Be careful when using this word, since it will have very" >fileLine
	s" global effects.  However, other tasks receive pointers are" >fileLine
	s" not reset.  This may cause problems." >fileLine ;
: PURGE ( --   P: Clear buffer pointers )
          AUX FRONT-IN  OFF      REAR-IN  OFF
          AUX FRONT-OUT OFF  AUX REAR-OUT OFF
          AUX BUFFER-IN @ AUX SIZE-IN @ 1+ ERASE
          AUX BUFFER-OUT @ AUX SIZE-OUT @ 1+ ERASE ;

\ METOO  Establish task at same point that the main task is at.
\    This allows a task to pick up at the same point you are
\    displaying right now.  Note that this may not be at the
\    current front of the receive buffer.
: METOO ( --   P: Establish task at same point )
          main-task user' 'AUX + @  'AUX !
          main-task user' REAR-IN + @  REAR-IN ! ;

\ ?FREE  How many characters are unused in buffer?  There is only
\    one set of pointers here per PCB since all tasks will be
\    sending characters to the FRONT of the buffer.
: ?FREE ( -- n   P: How many characters are left in buffer )
          PAUSE  AUX SIZE-OUT @  AUX FRONT-OUT @
                 AUX REAR-OUT @ -  DUP 0<
                 IF  +  ELSE  -  THEN  1+ ;

\ !CHR  Store character in buffer as if we received it from the
\    remote system.  This allows me to implement local echo and to
\    test the receive routines.  The multi-tasker is always called
\    after inserting the character.
: !CHR ( b --   P: Store character in buffer )
         AUX BUFFER-IN @  AUX FRONT-IN DUP >R @ +
         R> DUP @ 1+  AUX SIZE-IN @ AND  SWAP ! C!
         PAUSE ;

\ Port input buffering

WARNINGS OFF

\ XKEY?  How many characters are in buffer for this task.  Other
\    tasks may be further ahead or behind.  The multi-tasker is
\    called first to give them a chance to catch up.
: XKEY? ( -- n   P: How many characters are in buffer )
          PAUSE  AUX FRONT-IN @  REAR-IN @  - DUP 0<
                 IF  AUX SIZE-IN @  1+ +  THEN ;

\ XKEY  Read character from buffer if any are there. If there
\    are no characters, then spin until one is available.
\    Otherwise, pull the character out and increment the REAR
\    pointer for this task.  In either case, the mult-tasker is
\    called first to give them a chance to catch up.
: XKEY ( -- b   P:  Read character from buffer )   BEGIN XKEY? UNTIL
         AUX BUFFER-IN @  REAR-IN DUP >R @ + C@
         R> DUP @ 1+  AUX SIZE-IN @ AND  SWAP ! ;

WARNINGS ON

: BUFFERED-READ ( --   P: Read characters into buffer )
	BEGIN  AUX AUX-PORT @ pollSerialPort DROP
	WHILE  AUX AUX-PORT @  AUX BUFFER-IN @  AUX FRONT-IN DUP >R @
		DUP >R +  AUX SIZE-IN @ 1+  R> - read DUP 0>
		IF  R@ @ +  AUX SIZE-IN @ AND  R> !
		ELSE  R> 2DROP  THEN
	REPEAT ;

ALSO ASSEMBLER

: READ-THREAD-CODE ( -- a   P: Compile code for threaded read )
	ALIGN HERE
	HERE HERE HERE \ begins
		2 0 AUX AUX-PORT hi16	addis
		2 2 AUX AUX-PORT lo16	ori
		3 0 2					lwz
		3 3 3					or.
		12 2 ROT				bc		\ 0<> until
			5 0 1					addi
			2 0 AUX BUFFER-IN hi16	addis
			2 2 AUX BUFFER-IN lo16	ori
			4 0 2					lwz
			2 0 AUX FRONT-IN hi16	addis
			2 2 AUX FRONT-IN lo16	ori
			2 0 2					lwz
			4 4 2					add
			2 0 AUX AUX-PORT hi16	addis
			2 2 AUX AUX-PORT lo16	ori
			3 0 2					lwz
			2 0 readCall hi16		addis
			2 2 readCall lo16		ori
			2 0 2					lwz
			9 2						mtspr
			20 0					bcctrl
			3 3 3					or.
			4 1 ROT					bc		\ 0> until
				2 0 AUX FRONT-IN hi16	addis
				2 2 AUX FRONT-IN lo16	ori
				4 0 2					lwz
				3 3 4					add
				5 0 AUX SIZE-IN hi16	addis
				5 5 AUX SIZE-IN lo16	ori
				4 0 5					lwz
				3 3 4					and
				3 0 2					stw
	20 0 ROT	bc		\ again
;

: WRITE-THREAD-CODE ( -- a   P: Compile code for threaded write )
	ALIGN HERE
	HERE HERE HERE HERE \ begins
		2 0 AUX AUX-PORT hi16	addis
		2 2 AUX AUX-PORT lo16	ori
		3 0 2					lwz
		3 3 3					or.
		12 2 ROT				bc		\ 0<> until
			4 0 AUX BUFFER-OUT hi16	addis
			4 4 AUX BUFFER-OUT lo16	ori
			4 0 4					lwz
			3 0 AUX FRONT-OUT hi16	addis
			3 3 AUX FRONT-OUT lo16	ori
			3 0 3					lwz
			2 0 AUX REAR-OUT hi16	addis
			2 2 AUX REAR-OUT lo16	ori
			2 0 2					lwz
			0 0 2 3					cmp
			4 1 HERE 5 CELLS +		bc		\ 0< if
				3 0 AUX SIZE-OUT hi16	addis
				3 3 AUX SIZE-OUT lo16	ori
				3 0 3					lwz
				3 3 1					addi
											\ then
			4 4 2					add
			5 2 3					subf
			12 2 ROT				bc		\ 0<> until
				5 2 3					subf
				2 0 AUX AUX-PORT hi16	addis
				2 2 AUX AUX-PORT lo16	ori
				3 0 2					lwz
				2 0 writeCall hi16		addis
				2 2 writeCall lo16		ori
				2 0 2					lwz
				9 2						mtspr
				20 0					bcctrl
				3 3 3					or.
				4 1 ROT					bc		\ 0> until
					2 0 AUX REAR-OUT hi16	addis
					2 2 AUX REAR-OUT lo16	ori
					4 0 2					lwz
					3 3 4					add
					5 0 AUX SIZE-OUT hi16	addis
					5 5 AUX SIZE-OUT lo16	ori
					4 0 5					lwz
					3 3 4					and
					3 0 2					stw
	20 0 ROT	bc		\ again
;

PREVIOUS

: BUFFERED-THREAD ( --   P: Start the thread executing )
	AUX AUX-RThread 0 AUX AUX-RCode @ 0 pthread_create drop
	AUX AUX-WThread 0 AUX AUX-WCode @ 0 pthread_create drop ;

WARNINGS OFF

\ Port output buffering
: help{XEMIT}   s" \item[\texttt{XEMIT}]" >fileLine
	s" Buffer the character if the buffer is not full, and increment" >fileLine
	s" the FRONT pointer.  Otherwise, we spin." >fileLine ;
: XEMIT ( b --   P: Buffer output character )
	AUX DUP 0= ABORT" Port has not been defined!"
	AUX-PORT @ 0= ABORT" Port has not been initialized!"
	BEGIN  ?FREE  UNTIL  ECHOED @ IF  DUP !CHR  THEN
	AUX FRONT-OUT TUCK @  AUX BUFFER-OUT @ + C!
	DUP @ 1+  AUX SIZE-OUT @ AND  SWAP ! ;

WARNINGS ON

2VARIABLE UPACED

: PACED-WRITE ( --   P: Output next character )
	?FREE  AUX SIZE-OUT @ 1+ <>
	IF  PACE @ ?DUP IF  >R utime UPACED 2@ R> M+ D<
			IF  EXIT  THEN  THEN
		AUX AUX-PORT @  AUX BUFFER-OUT @  AUX REAR-OUT DUP >R @ + 1 write
		R@ @ +  AUX SIZE-OUT @ AND  R> !
		UTIME UPACED 2!
	THEN ;

\ Port Output Primatives

: help{XTYPE}   s" \item[\texttt{XTYPE}]" >fileLine
	s" Send characters at the given address." >fileLine ;
: XTYPE ( a # -   P: Send characters at address )
	0 ?DO  COUNT XEMIT  LOOP  DROP ;

: BUFFER-MONITOR ( task --   P: Handle the port I/O )   activate
	BEGIN  PAUSE  USE-AUX-THREADING 0=
		IF  PACED-WRITE
			BUFFERED-READ
		THEN
	AGAIN ;

\ Modem port selection

: XRESET ( -- )   AUX AUX-PORT @ >R
	R@ GetTermios THROW
	R@ GetModem THROW
	SetupTermios
	R@ SetTermios THROW
	R> SetModem THROW ;

: help{!PORT}   s" \item[\texttt{PORT}]" >fileLine
	s" Set port to the given port vectors.  Only ports 1 and 2" >fileLine
	s" have been implemented, but !PORT can be used to deal with" >fileLine
	s" the customizations needed for other ports." >fileLine
	s" The Mac uses null-terminated /dev port names passed to \$PORT." >fileLine ;
: (PORT) ( handle ior -- )   THROW DUP fd ! AUX AUX-PORT !
         AUX AUX-Termios @ TO theTermios
         XRESET  USE-AUX-THREADING
         IF  fd @ blockSerialPort THROW
             BUFFERED-THREAD
         ELSE  AUX AUX-Task @ BUFFER-MONITOR
         THEN ;
: !PORT ( n --   P: Set port by index )
         AUX AUX-PORT @ ?DUP IF  close DROP  THEN
         openSerialPort (PORT) ;
: $PORT ( strz --   P: Set port by name )
         AUX AUX-PORT @ ?DUP IF  close DROP  THEN
         ?DUP IF  DUP $openSerialPort ['] (PORT) CATCH IF
	             2DROP CR ." Can't open " DUP >count TYPE SPACE
             ELSE  DROP
    	 THEN  THEN ;

\ Modem control block creation

HEX

\ BUF-MAKE  Check buffer size validity to be a power of 2.
\    If it is, the memory is reserved and the pointers
\    are compiled into the Port Control Block.
\    Otherwise, we abort the creation of the block.
: BUF-MAKE ( n --   P: Check buffer size validity )   ?DUP
             IF  DUP DUP 1- AND ABORT" Invalid buffer size"
                 10 / 1 MAX  10 *  ELSE  10000
             THEN  DUP ALLOCATE THROW  2DUP SWAP ERASE
             ( BUFFER ) ,  1- ( SIZE ) ,  0 ( FRONT ) , ;

DECIMAL

: help{AUX-MAKE}   s" \item[\texttt{AUX-MAKE}]" >fileLine
	s" Create communication buffers and lay down the Port" >fileLine
	s" Control Block.  The transmit and receive buffer sizes are" >fileLine
	s" checked and allocated." >fileLine ;
: AUX-MAKE ( t r --   P: Create communication buffers )
	ALIGN  HERE 'AUX !  0 ( PORT ) ,  0 ( Task ) ,
	0 ( RCode ) ,  0 ( WCode ) ,  0 ( RThread ) ,  0 ( WThread ) ,
	theTermios ,  BUF-MAKE  BUF-MAKE  0 ( REAR ) ,
	READ-THREAD-CODE AUX AUX-RCode !
	WRITE-THREAD-CODE AUX AUX-WCode !
	64 NewTask AUX AUX-Task ! ;

: FIND-PORT ( -- n   P: Find a serial port to use )   AUX 0=
	IF  2048 2048 AUX-MAKE
	THEN  AUX AUX-PORT @ 0=
	IF	findSerialPorts  countPorts @ 0
		?DO  I ['] !PORT CATCH IF  DROP
			ELSE  I  UNLOOP  EXIT  THEN
		LOOP  TRUE ABORT" Can't find a port"
	THEN  0 ;

\ Input translation table    RESERVE space for the table

\ IN-TABLE  Table segment address for space we reserved.
0 VALUE IN-TABLE ( -- va   P: Table vector address )

\ >CHRS  Index key returning a vector address.
: >CHRS ( n -- va   P: Index key )   IN-TABLE SWAP CELLS + ;

\ :<tty  Define key behaviour by placing its execution address into
\    table and compile the definition with no name.  Similar to :
: :<tty ( n -   P: Define key behaviour )   :NONAME ;

\ <CHRS  Finish keys input, terminating the state and exiting.
: <CHRS ( b -- 0   P: Finish keys )   0  UNCHR ;

\ tty>;  Finish key behaviour and exit the compile STATE.
\    This is very similar to what ; does.
: tty>; ( --   P: Finish key behaviour and exit )
       POSTPONE <CHRS  POSTPONE ;  SWAP >CHRS ! ; IMMEDIATE

\ >;  Finish key behaviour and exit the compile STATE.
\    This is very similar to what ; does.
: >; ( --   P: Finish key behaviour and exit )
       POSTPONE ;  SWAP >CHRS ! ; IMMEDIATE

\ LOOKUP-CHRS  Execute key behaviour if it has been defined.  A 0 in
\    vector will skip this, but this fact is never really used.
: LOOKUP-CHRS ( b -- b | 0   P: Execute key behaviour )   DUP >CHRS @EXECUTE ;

\ NOMAP  Reset lookup table by EMPTYing the dictionary, clearing
\   the stack, and putting the state machine into each vector.
: NOMAP ( --   P: Reset lookup table )   UNCHR
          256 0 DO  ['] CHRED I >CHRS !  LOOP ;

: NEWMAP ( -name- P: Create new translation table )
	CREATE  256 CELLS ALLOCATE THROW DUP ,  TO IN-TABLE  NOMAP
	DOES>  @ TO IN-TABLE ;

\ Keyboard Processing

\ OUT-TABLE  Table segment address for space we reserved.
0 VALUE OUT-TABLE ( -- va   P: Table segment)

\ >KEYS  Index key returning an extended address.
: >KEYS ( n -- va | 0   P: Index key )   OUT-TABLE
	BEGIN  ?DUP  WHILE  2DUP CELL+ @ <>
	WHILE  @  REPEAT  NIP 2 CELLS +  EXIT
	THEN  DROP 0 ;

\ :<key  Define key behaviour by placing its execution address into
\    table and compile the definition with no name.  Similar to :
: :<key ( n --   P: Define key behaviour )   :NONAME ;

\ key>;  Finish key behaviour and exit the compile STATE.
\    This is very similar to what ; does
: key>; ( --   P: Finish key behaviour and exit )   POSTPONE ;
	HERE OUT-TABLE , TO OUT-TABLE  SWAP , , ; IMMEDIATE

\ FUNCTION  Execute key behaviour if it has been defined.  A 0 in
\    vector will skip this, but this fact is never really used.
: FUNCTION ( n --   P: Execute key behaviour )   >KEYS ?DUP IF @EXECUTE THEN ;

\ KEYBOARD  Process local keyboard, by sending the characters to
\    the remote system.  EKEY>CHAR lets us know when a function
\    key has been pressed and send its key code to FUNCTION.
\    If the keyboard character is a CR and the LNM mode is on,
\    then a LF is also sent.
: KEYBOARD ( -- flag   P: Process local keyboard )   EKEY?
	IF  EKEY  LOCK @ IF  DROP 0 EXIT  THEN
		DUP 27 = IF  DROP 1 EXIT  THEN  EKEY>CHAR
		IF  DUP XEMIT DUP
			13 =  LNM @ AND IF  10 XEMIT  THEN
			10 =  LNM @ AND IF  13 XEMIT  THEN
		ELSE  FUNCTION  THEN
	THEN  0 ;

\ Terminal Emulation

\ SERIAL  Process serial port characters by sending them through
\    the lookup table.  After the lookup, if the character is non-
\    zero, and we are not in Printer Controller Mode, then it is
\    sent to the display screen.  The lookup table can then change
\    any character or make it part of an invisible sequence.
: SERIAL ( --   P: Process serial port )
           XKEY? IF  XKEY  LOOKUP-CHRS ?DUP
                           IF  PCM @ IF  DROP
                                     ELSE  EMIT
                 THEN      THEN      THEN ;

: RESUME ( -- )   BEGIN  SERIAL  KEYBOARD  UNTIL  CR ;

: help{WATCHER}   s" \item[\texttt{WATCHER}]" >fileLine
	s" Terminal emulator  that processes the keyboard and the" >fileLine
	s" serial port.  The only way out is to hit the Esc key." >fileLine ;
: WATCHER ( --   P: Terminal emulator )
	FIND-PORT DROP  CURSOR ON  PAGE  0 0 TAB  RESUME ;

\ MAPPED  checks to see if the character at the given row and column
\    has been mapped to do something special.
: MAPPED ( b -- )   SWAP 16 * + >CHRS @  ['] CHRED =
       IF  ." un"  THEN  ." mapped " ;

: TermGlossary ( -- )   s" Term Glossary" subSection
	s" \begin{description}" >fileLine
		help{AUX-MAKE}
		help{!PORT}
		help{PURGE}
		help{WATCHER}
		help{XEMIT}
		help{XTYPE}
	s" \end{description}" >fileLine
	endSection ;

include ./Serial/XModem.f  XModem.version 1 checkPlugin

: TermHelp ( -- )
	SerialSupport fileCr
		PortControlBlock fileCr
		TermGlossary fileCr
		XModemSection fileCr
		TestSerialSection
	endSection ;

WARNINGS OFF

: XTRANSMIT ( addr len -- ior ) \ Transmit packets
	flowControl C@ >R  BL flowControl C! XRESET
	ECHOED @ >R  ECHOED OFF  XTRANSMIT  R> ECHOED !
	R> flowControl C! XRESET ;

: XRECEIVE ( addr len -- ior ) \ Receive packets
	flowControl C@ >R  BL flowControl C! XRESET
	ECHOED @ >R  ECHOED OFF  XRECEIVE  R> ECHOED !
	R> flowControl C! XRESET ;

15 1024 * allocate throw constant xx
true to flg-debugging
true to flg-progress

: yy xx 15 1024 * xreceive ;

WARNINGS ON

( ADM-3A Emulation )    NEWMAP ADM3A

: ADM-ESC ( ... n -- n )   UNCHR ;
: ADM-COL ( l b -- 0 )   BL - TAB  0  UNCHR ;
: ADM-LINE ( b -- n 0 )   BL -  0  ['] ADM-COL CHRS ! ;

27 :<tty   0=  ['] ADM-ESC CHRS ! >;						\ Sets up the state machine to reset itself next time.

\ CHAR =  If we are in the ESC mode, then set up the state
\    to establish the line number and set up the state machine
\    again to establish the column and set the cursor position.
\    Otherwise, execute the current state vector.
CHAR = :<tty  CHRS @ ['] ADM-ESC =
            IF  0=  ['] ADM-LINE CHRS !
            ELSE  CHRED  THEN  >;

\ Thus we have defined 4 states:
\    1) Process characters normally.
\    2) Enter the ESC state.
\    3) Establish the line number.
\    4) Establish the column and set the cursor.

CTRL G :<tty  BELL  tty>;									\ Sounds terminal BELL
CTRL H :<tty  CPR  1-  0 MAX  TAB  tty>;					\ Moves the cursor left non-destructively.
CTRL L :<tty  CPR  1+ 79 MIN  TAB  tty>;					\ Move the cursor right non-destructively.
CTRL K :<tty  CPR  SWAP 1- 0 MAX  SWAP TAB  tty>;			\ Move the cursor up and stop at the top.
CTRL J :<tty  CPR  SWAP 24 - ?DUP							\ Move the cursor down, and scroll the screen if
           IF  25 + SWAP TAB								\   already at the bottom.
           ELSE  CR DUP SPACES
           THEN  tty>;
CTRL I :<tty  4  CPR  NIP OVER MOD -  DUP SPACES  tty>;		\ Move the cursor to the next tab stop.
CTRL A :<tty  0 0 TAB  tty>;								\ Move the cursor to the top of the screen.
CTRL M :<tty  CPR  DROP 0 TAB  tty>;						\ Move the cursor to the beginning of the line.
CTRL O :<tty  LOCK ON  tty>;								\ Lock the keyboard.
CTRL N :<tty  LOCK OFF  tty>;								\ Unlock the keyboard.
CTRL Z :<tty  PAGE  0 0 TAB  tty>;							\ Clear the display screen.

( ANSI Emulation including VT100, 200 and 300 support )       NEWMAP ANSI

\ TABS  Tab settings are initially defined every 4 characters.
CREATE TABS ( -- a   P: Tab settings ) HERE 10 DUP ALLOT 17 FILL

\ ANSWERBACK  Answer Back message but I have no idea what should
\    be in this string.  Here is something that might work.
CREATE ANSWERBACK ( -- a   P: Answer Back message )
                    ," GForth Terminal Software  $Revision: 1.6 $"

\ DECSC  Save terminal state including the screen attributes.
CREATE DECSC ( -- a   P: Save terminal state )   2 CELL+ ALLOT

\ -PCM  Not if in Printer Controller Mode then exit this word.
\    This is quicker than doing it within the definition.
: -PCM ( --   P: Not if in Printer Controller Mode )
         PCM @ IF  R> DROP  <CHRS  THEN ;

\ ANSI Control Characters

CTRL E :<tty  ANSWERBACK COUNT XTYPE  tty>;								\ ENQ  Sends answerback message.
CTRL G :<tty  -PCM  BELL  tty>;											\ BEL  Sounds the terminal bell.
CTRL H :<tty  -PCM  CPR  1- 0 MAX  2DUP TAB  SPACE  TAB  tty>;			\ BS   Moves the cursor one character position to the left.
CTRL I :<tty  -PCM  CPR  80 OVER DO  1+  TABS OVER @B					\ HT   Moves the cursor to the next tab stop.  If there are no
                 IF  LEAVE  THEN  LOOP  TAB  tty>;						\		more tap stops, the cursor moves to the right margin.
CTRL J :<tty  -PCM  CPR  LNM @ IF  DROP TOP C@  THEN  SWAP				\ LF   Causes a line feed or a new line operation, depending on
           BOTTOM 1+ C@ - ?DUP IF  BOTTOM 1+ C@ 1+ + SWAP TAB			\		the setting of line feed/new line mode.  The display will
              ELSE  CR DUP SPACES  THEN  tty>;							\		scroll if the cursor is at the bottom margin.
CTRL M :<tty  -PCM  CPR  DROP TOP C@ TAB  tty>;							\ CR   Moves the cursor to the left margin on the current line.
133 :<tty  -PCM  CPR  DROP BOTTOM 1+ C@ - ?DUP							\ NEL  Moves the cursor to the first position on the next line.
        IF  BOTTOM 1+ C@ 1+ + 0 TAB										\		If at the bottom margin, the page scrolls up.
        ELSE  CR  THEN  tty>;
136 :<tty  -PCM  1 TABS CPR NIP !B  tty>;								\ HTS  Sets a horizontal tab stop at the cursor position.
141 :<tty  -PCM  CPR  SWAP 1- TOP 1+ C@ MAX  SWAP TAB  tty>;			\ RI   Moves the cursor up one line, but stops at top margin.
CTRL Q :<tty ( Transmitter ENABLE ) tty>;								\ DC1  Causes the terminal to continue sending characters.
CTRL S :<tty ( Transmitter DISABLE ) tty>;								\ DC3  Causes the terminal to stop sending characters.

\ ANSI Escape Control    The STATE Machine

\ ANSI-CSI  Introduces a control sequence.  This is the 8 bit version
\    of the 7 bit ESC [.  When it occures, a 0 is placed on the
\    stack in preparation for numeric parameters, and the state
\    vector is changed so numbers add digits to the parameter and
\    characters less than @ leave themselves.  All others exit.
: ANSI-CSI ( b -- ?   P: Introduce control sequence )
            DUP [CHAR] 0  [CHAR] 9 1+ WITHIN
            IF  [CHAR] 0 -  SWAP 10 * +  0
            ELSE  DUP [CHAR] @ < IF  SWAP 0
                  ELSE  0 UNCHR  THEN  THEN ;

155 :<tty   0= DUP  ['] ANSI-CSI CHRS !  >;

\ CSI?  Check Control State returning true if we are in it.
: CSI? ( -- f   P: Check Control State )   CHRS @  ['] ANSI-CSI = ;

\ CSI  Exit if not in Control State after processing character
\    through the state table.  Otherwise, continue.
: CSI ( --   P: Exit if not in Control State )
        CSI? 0= IF  CHRED  R> DROP  THEN ;

\ ANSI-ESC  Introduces an escape sequence.  The state vector is changed
\    so that characters less than @ leave themselves.
: ANSI-ESC ( b -- ?   P: Introduce an escape sequence )   DUP [CHAR] @ <
            IF  DROP 0  ELSE  0 UNCHR  THEN ;

27 :<tty   0=  ['] ANSI-ESC CHRS !  >;

\ ESC?  Check Escape State returning true if we are in it.
: ESC? ( - f   P: Check Escape State )   CHRS @  ['] ANSI-ESC = ;

\ ESC  Exit if not in Escape State after processing character
\    through the state table.  Otherwise, continue.
: ESC ( -   P: Exit if not in Escape State )
        ESC? 0= IF  CHRED  R> DROP  THEN ;

\ ANSI Escape Sequences

CHAR ; :<tty  CSI  0= DUP  >;										\ ;  is a parameter seperator.

CHAR [ :<tty  ESC  155 >CHRS @EXECUTE  >;							\ CSI  7 bit equivalent.
CHAR E :<tty  ESC  133 >CHRS @EXECUTE  >;							\ NEL  7 bit equivalent.
CHAR M :<tty  ESC  141 >CHRS @EXECUTE  >;							\ RI   7 bit equivalent.

: IND   ESC? IF  132 >CHRS @EXECUTE  R> DROP  THEN ;				\ IND  7 bit equivalent, but also needed in a CSI sequence.
: HTS   ESC? IF  136 >CHRS @EXECUTE  R> DROP  THEN ;				\ HTS  7 bit equivalent, but also needed in a CSI sequence.

CHAR 7 :<tty  ESC  CPR DECSC 2C!  ATTRIBUTE @ DECSC 2 + !  tty>;	\ DECSC  Saves the cursor state in the terminal's memory.
CHAR 8 :<tty  ESC  DECSC 2C@ TAB    DECSC 2 + @ ATTRIBUTE !  tty>;	\ DECRC  Restores the cursor state from the terminal's memory.

\ ANSI Cursor Control

\ nPull  Pull parameter to top of stack.  If it does not exist,
\    a 0 will be substituted for it.
: nPull ( n ... # -- ... n | 0   P: Pull parameter to top )
          DEPTH OVER 1+ > IF  ROLL  ELSE  DROP 0  THEN ;

\ 2nPulls  Pull 2 parameters up to top of stack.  If there is only 1,
\    use it first, putting a 0 above it.
: 2nPulls ( n1 n2 x -- x n1 n2   P: Pull 2 parameters up )
            DEPTH 2 > IF  ROT ROT  ELSE  1 nPull 0  THEN ;

CHAR H :<tty  HTS  CSI  2nPulls SWAP 1- 0 MAX SWAP 1- 0 MAX TAB  tty>;	\ CUP  Set the cursor to the given cursor position.
CHAR D :<tty  IND  CSI  CPR  3 nPull 1 MAX -  0 MAX TAB  tty>;			\ CUB  Move the cursor left the given number of places.
CHAR C :<tty  CSI  CPR  3 nPull 1 MAX + 79 MIN TAB  tty>;				\ CUF  Move the cursor right the given number of places.
CHAR A :<tty  CSI  CPR  SWAP 2 nPull 1 MAX -  0 MAX SWAP TAB  tty>;		\ CUU  Move the cursor up the given number of lines.
CHAR B :<tty  CSI  CPR  SWAP 2 nPull 1 MAX + 24 MIN SWAP TAB  tty>;		\ CUD  Move the cursor down the given number of lines.
CHAR r :<tty  CSI  2nPulls ?DUP 0= IF  24  THEN  1- BOTTOM 1+ C!		\ DECSTBM  Set the top and bottom margins for the current page.
                 1 MAX 1- TOP 1+ C!  TOP 2C@ TAB  tty>;					\    In this implementation, the margins are global for all pages.

CHAR g :<tty  CSI  1 nPull  3 OVER = IF  TABS 10 ERASE  THEN			\ TBC  Clears tab stops.  If nPull = 3, clear them all.
                       0= IF  0 TABS CPR NIP !B  THEN  tty>;			\    If nPull = 0, only clear the one at the current cursor.

\ ANSI Page Control

3 CONSTANT #Ps ( -- n   P: Last possible page number )

CHAR U :<tty  CSI  PAGE# @ 2 nPull 1 MAX +  #Ps MIN !PAGE				\ NP  Move the cursor to the home position on one of the following
                 TOP 2C@ TAB  tty>;										\    pages in page memory.
CHAR V :<tty  CSI  PAGE# @ 2 nPull 1 MAX -  0 MAX !PAGE					\ PP  Move the cursor to the home position on one of the preceding
                 TOP 2C@ TAB  tty>;										\    pages in page memory.

CHAR P :<tty  CSI  2 nPull 32 OVER = IF  CPR 2>R  1 nPull #Ps MIN		\ PPA  Move the cursor to the corresponding row and column on any
                              !PAGE  2R> TAB  THEN  tty>;				\    page in page memory.

CHAR R :<tty  CSI  2 nPull 32 OVER = IF  CPR 2>R  [CHAR] V >CHRS @		\ PPB  Move the cursor to the corresponding row and column on one
                              EXECUTE  2R> TAB  THEN  tty>;				\    of the following pages in page memory.
CHAR Q :<tty  CSI  2 nPull 32 OVER = IF  CPR 2>R  [CHAR] U >CHRS @		\ PPR  Move the cursor to the corresponding row and column on one
                              EXECUTE  2R> TAB  THEN  tty>;				\    of the preceding pages in page memory.

\ ANSI Color Sequences

HEX

\ COLORS  Color translation table.  Substitute different colors
\    if you don't like the colors that are use.
CREATE COLORS ( - a   P: Color translation table )
       0 C,  1 C,  2 C,  3 C,  4 C,  5 C,  6 C,  7 C,  8 C,

\ 00COLORS  Parameters 0-8 are handled here.
\    0 - All attributes off
\    1 - Bold
\    4 - Underline
\    5 - Blinking
\    7 - Negative image
\    8 - Invisible
: 00COLORS ( x n -- x'   P: Parameters 0-8 )   >R
   R@ 0 = IF DROP 7 COLORS + C@ COLORS C@ 10 * + THEN
   R@ 1 = IF 8 COLORS + C@ OR THEN
   R@ 4 = IF 1 COLORS + C@ OR THEN  R@ 5 = IF 80 OR THEN
   R@ 7 = IF DUP 88 AND SWAP 10 /MOD 7 AND
            SWAP 7 AND 10 * + + THEN
   R> 8 = IF F8 AND DUP 10 / 7 AND + THEN ;

\ 20COLORS  Parameters 22-28 are handled here.
\    22 - Bold off                   24 - Underline off
\    25 - Blinking off               27 - Negative image off
\    28 - Invisible off
: 20COLORS ( x n -- x'   P: Parameters 22-28 )   >R
   R@ 22 = IF F7 AND THEN  R@ 24 = IF FE AND THEN
   R@ 25 = IF 7F AND THEN  R@ 27 = IF 7 00COLORS THEN
   R> 28 = IF F0 AND 7 COLORS + C@ OR THEN ;

\ 30COLORS  Parameters 30-37 are handled here.
\    Set foreground color.
: 30COLORS ( x n -- x'   P: Parameters 30-37 )
             7 AND COLORS + C@      SWAP F8 AND + ;

\ 40COLORS  Parameters 40-47 are handled here.
\    Set background color.
: 40COLORS ( x n -- x'   P: Parameters 40-47 )
             7 AND COLORS + C@ 10 * SWAP 8F AND + ;

\ !COLORS  Set video attributes by executing the routine that
\    fits the parameter range.  0-7 are standard ANSI settings.
\    8-30 are specific to the VT300.  30-50 are unique to the
\    MSDOS ANSI terminal driver.
: !COLORS ( x n -- x'   P: Set video attributes )
            DUP  0 10 WITHIN IF  00COLORS  ELSE
            DUP 20 30 WITHIN IF  20COLORS  ELSE
            DUP 30 40 WITHIN IF  30COLORS  ELSE
            DUP 40 50 WITHIN IF  40COLORS  THEN
                                 THEN THEN THEN ;

\ SGR  Selects one or more character attributes at the same time.
CHAR m :<tty  CSI  -PCM  ATTRIBUTE C@  DEPTH 2 - 0
               DO  I' I - 1+ nPull  !COLORS  LOOP
            DUP >< + ATTRIBUTE !  tty>;

DECIMAL

\ ANSI Erase Sequences

\ ED  Erase characters from part or all of the display.  This
\    implementation only works within the current margins.
\    If nPull = 0, Erase from the cursor to the end of the display
\            1, from the beginning of the display to the cursor
\            2, the complete display.
CHAR J :<tty  CSI  1 nPull ?DUP IF  CPR  TOP 2C@ TAB  ROT 1-
                    IF  BOTTOM 2C@  TOP 2C@ D-  1 1 D+ *
                    ELSE  OVER BOTTOM C@ 1+ * OVER +
                    THEN  SPACES  TAB
                 ELSE  BOTTOM 2C@ 1 1 D+  SWAP CPR >R - *
                    R> - SPACES  THEN  tty>;

\ EL  Erase characters on the line that has the cursor.  This
\    implementation only works within the current margins.
\    If nPull = 0, Erase from the cursor to the end of the line
\            1, from the beginning of the line to the cursor.
\            2, the complete line.
CHAR K :<tty  CSI  1 nPull ?DUP IF  CPR  OVER TOP C@ TAB  ROT 1-
                    IF  BOTTOM C@ 1+  TOP C@ -
                    ELSE  BOTTOM C@ 1+ OVER -
                    THEN  SPACES  TAB
                 ELSE  BOTTOM C@ 1+ CPR NIP - SPACES  THEN  tty>;

\ ECH  Erase one or more characters from the cursor position to
\    the right.
CHAR X :<tty  CSI  1 nPull 1 MAX SPACES  tty>;

\ ANSI Combined Sequences

\ The following sequences are terminated with h.
\    DECPFF  Printer issues a form feed when done.
\    DECPEX  Print page prints the complete page.
\    DECTCEM  Makes the cursor visible.
\    KAM  Locks the keyboard.
\    SRM  Turns local echo off.
\    LNM  LF moves cursor to beginning of next line.
CHAR h :<tty  CSI  1 nPull  2 nPull [CHAR] ? = IF
                 18 OVER = IF  PFF ON  THEN
                 19 OVER = IF  PEX ON  THEN
                 25 OVER = IF  CURSOR ON  THEN
           ELSE   2 OVER = IF  LOCK ON  THEN
                 12 OVER = IF  ECHOED OFF  THEN
                 20 OVER = IF  LNM ON  THEN THEN  tty>;

\ The following sequences are terminated with l.
\    DECPFF  Printer does not issue form feed when done.
\    DECPEX  Print page only prints scrolling region.
\    DECTCEM  Makes the cursor invisible.
\    KAM  Unlocks the keyboard.
\    SRM  Turns local echo on.
\    LNM  LF moves cursor to current column of next line.
CHAR l :<tty  CSI  1 nPull  2 nPull [CHAR] ? = IF
                 18 OVER = IF  PFF OFF  THEN
                 19 OVER = IF  PEX OFF  THEN
                 25 OVER = IF  CURSOR OFF  THEN
           ELSE   2 OVER = IF  LOCK OFF  THEN
                 12 OVER = IF  ECHOED ON  THEN
                 20 OVER = IF  LNM OFF  THEN THEN  tty>;

\ ANSI Printing Sequences

\ The following sequences are terminated with i.
\    Turns on autoprint mode.
\    Turns off autoprint mode.
\    Prints the current display page.
\    Prints all display pages from page memory.
\    Print the cursor line.
\    Turns on printer controller mode.
\    Turns off printer controller mode.
\    Prints the current display page.
CHAR i :<tty  CSI  1 nPull  2 nPull [CHAR] ? = IF
                  5 OVER = IF ( +TYPER ) THEN
                  4 OVER = IF ( -TYPER ) THEN
                 10 OVER = IF ( PAGE-PRINT ) THEN
                 11 OVER = IF ( PAGES-PRINT ) THEN
                  1 OVER = IF ( LINE-PRINT ) THEN
           ELSE   5 OVER = IF  PCM ON  ( +TYPER ) THEN
                  4 OVER = IF  PCM OFF ( -TYPER ) THEN
                  0= IF ( PAGE-PRINT ) THEN THEN  tty>;

\ ANSI Device Attribute Reports

\ "CSI"  send the 7 bit CSI sequence to the remote system.
\    All these quoted words are merely shorthand methods to
\    to send the quoted strings.
: "CSI"   27 XEMIT  [CHAR] [ XEMIT ;
: ";"     [CHAR] ; XEMIT ;     : "?"   [CHAR] ? XEMIT ;
: "."     (.) XTYPE ;          : ".;"   "." ";" ;
: "c"     [CHAR] c XEMIT ;     : "CSI?"   "CSI" "?" ;
: "R"     [CHAR] R XEMIT ;     : "n"   [CHAR] n XEMIT ;

\ DA  Send the Primary Device Attribute string.  Notice that I
\    claim to be a VT300 with a printer and windows.
: DA   "CSI"  "?"  63 ".;"  ( VT200 or VT300 )
       2 ".;"  ( Printer port )  18 "."  ( Windowing )  "c" ;

\ DA  triggers the sending of the primary Device Attributes.
CHAR c :<tty  CSI  1 nPull 0= IF  DA  THEN  tty>;

\ DECID  also send the primary DA.
CHAR Z :<tty  ESC  DA  tty>;

\ ANSI Device Status Reports

\ The following sequences are terminated with n.
\    DECXCPR  Requests an eXtended Cursor Position Report.
\                 Notice that the page number is added.
\    Request the current printer status.  Always ready.
\    Asks if UDKs are locked.  They are.
\    Asks about the keyboard.  It is North American and ready.
\    Asks about the locator device.  We don't have one.
\    Asks what kind of locator device.  Can't identify it.
\    Asks terminal operating state.  We are good.
\    CPR  Requests a Cursor Position Report.
CHAR n :<tty  CSI  1 nPull  2 nPull  [CHAR] ? = IF
                  6 OVER = IF  "CSI" CPR SWAP 1+ ".;" 1+ ".;"
                          PAGE# @ "."  "R"  THEN
                 15 OVER = IF  "CSI?" 10 "." "n"  THEN
                 25 OVER = IF  "CSI?" 21 "." "n"  THEN
                 26 OVER = IF  "CSI?" 27 ".;" 1 ".;" 0 "." "n"
           THEN  55 OVER = IF  "CSI?" 53 "." "n"  THEN
                 56 OVER = IF  "CSI?" 57 ".;" 0 "." "n"  THEN
           ELSE   5 OVER = IF  "CSI" 0 "." "n"  THEN
                  6 OVER = IF  "CSI" CPR SWAP 1+ ".;" 1+ "." "R"
           THEN  THEN  tty>;

\ ANSI Controls not needed

\ These control codes we do not support, but we do need to ignore
\    them.  Thus I need some nul definitions.
CTRL N :<tty  tty>;    CTRL O :<tty  tty>;    CTRL T :<tty  tty>;

\ The DEL character also need to be ignored, but in this case
\    I do not want to abort any control sequence already in
\    process.
127 :<tty 0= >;

134 :<tty  tty>;    135 :<tty  tty>;    142 :<tty  tty>;    143 :<tty  tty>;
144 :<tty  tty>;    147 :<tty  tty>;    150 :<tty  tty>;    151 :<tty  tty>;
156 :<tty  tty>;    157 :<tty  tty>;    158 :<tty  tty>;    159 :<tty  tty>;

( ANSI Keyboard Control )    ANSI

\ [CSI]  Create keyboard code for the arrow keys.
: (CSI) ( b --   P: Create keyboard code )
         27 XEMIT  [CHAR] [ XEMIT  XEMIT ;
: [CSI] ( _b --   P: Create keyboard code )
		CHAR POSTPONE LITERAL POSTPONE (CSI) ; IMMEDIATE

\ Define the up, down, right and left keys.
k-up	:<key [CSI] A key>;
k-down	:<key [CSI] B key>;
k-right	:<key [CSI] C key>;
k-left	:<key [CSI] D key>;

\ [SS3]  Create function code for the 1st 4 function keys.
: (SS3) ( b --   P: Create function code )
         27 XEMIT  [CHAR] O XEMIT  XEMIT ;
: [SS3] ( _b --   P: Create function code )
		CHAR POSTPONE LITERAL POSTPONE (SS3) ; IMMEDIATE

\ Define F1-4 as the VT terminals do.
k1 :<key [SS3] P key>;
k2 :<key [SS3] Q key>;
k3 :<key [SS3] R key>;
k4 :<key [SS3] S key>;

\ Define PgUp, PgDn, End and Home to send F1 sequence first.
k-prior :<key k1 FUNCTION k-up    FUNCTION key>;
k-next  :<key k1 FUNCTION k-down  FUNCTION key>;
k-end   :<key k1 FUNCTION k-right FUNCTION key>;
k-home  :<key k1 FUNCTION k-left  FUNCTION key>;

\ : K( ( altM)   27 XEMIT  [CHAR] ? XEMIT  [CHAR] p XEMIT ;

\ [CSI]~  Create function keys that send their function number.
: (CSI)~ ( n --   P: Create function keys )
          27 XEMIT  [CHAR] [ XEMIT  (.) XTYPE  [CHAR] ~ XEMIT ;
: [CSI]~ ( _n --   P: Create function keys )
          BL WORD NUMBER DROP POSTPONE LITERAL POSTPONE (CSI)~ ; IMMEDIATE

\ These Alt keys send the sequences for Find, Insert Here, Remove
\    Select, Prev Screen and Next Screen keys.
( altF) 0 :<key [CSI]~ 1 key>;
( altI) 0 :<key [CSI]~ 2 key>;
( altR) 0 :<key [CSI]~ 3 key>;
( altS) 0 :<key [CSI]~ 4 key>;
( altP) 0 :<key [CSI]~ 5 key>;
( altN) 0 :<key [CSI]~ 6 key>;

\ F5 should send a Break sequence, but doesn't yet.
k5 :<key ( BREAK ) key>;

\ F6-10 emulate F6-10 on the VT keyboard.
k6  :<key [CSI]~ 17 key>;
k7  :<key [CSI]~ 18 key>;
k8  :<key [CSI]~ 19 key>;
k9  :<key [CSI]~ 20 key>;
k10 :<key [CSI]~ 21 key>;

\ Shifted F1-10 emulate F11-20 on the VT Keyboard.
s-k1  :<key [CSI]~ 23 key>;
s-k2  :<key [CSI]~ 24 key>;
s-k3  :<key [CSI]~ 25 key>;
s-k4  :<key [CSI]~ 26 key>;
s-k5  :<key [CSI]~ 28 key>;
s-k6  :<key [CSI]~ 29 key>;
s-k7  :<key [CSI]~ 31 key>;
s-k8  :<key [CSI]~ 32 key>;
s-k9  :<key [CSI]~ 33 key>;
s-k10 :<key [CSI]~ 34 key>;

\ Make a bunch of other control sequences work like a LF.
CTRL J >CHRS @  DUP CTRL K >CHRS !  DUP CTRL L >CHRS !  132 >CHRS !
CHAR H >CHRS @  CHAR f >CHRS !

[THEN]
