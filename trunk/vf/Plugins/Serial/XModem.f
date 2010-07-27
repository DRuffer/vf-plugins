\   File:		XModem.f
\
\	Contains:	Binary transfer with XModem with optional CRC-16
\
\ This system was translated and heavily modified from source
\    code originally written for FORTH-83, by:
\            Wilson M. Federici
\            1208 NW Grant
\            Corvallis OR 97330  (503) 753-6744
\            Version 1.01  9/85
\
\ It is now in compliance with the recommendations made in the document
\    entitled: XMODEM/YMODEM PROTOCOL REFERENCE, edited by Chuck Forsberg
\    that was formatted on 10-14-88.  The YMODEM extensions have not been
\    applied since they use file features which are not available.  The
\    XMODEM-1K transmit also will not drop down to 128 byte packets.
\
\ The protocol options must be established before these words
\    are used.  The protocol options are:
\
\ XMODEM  is the original protocol developed by Ward Christenson.
\ XMODEM-CRC  is the variant that uses a CRC-16 instead of a
\    simple byte sum.  It is the default.
\ XMODEM-1K  is the CRC variant that uses 1K transfer buffers.  It
\    is the default for transmit, but will be handled automatically
\    for receive.

\ Copyright (c) 2010 Dennis Ruffer

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

[defined] XModem.version 0= [IF]

1 constant XModem.version

: XModemSection ( -- )   s" XModem Support" subSection
	s" The XModem support is loaded by the Terminal emulator," >fileLine
	s" but otherwise, it is not used at this point." >fileLine
	endSection ;

\ ----------------------------------------------------------------------------
\          Constants and Variables
\ ----------------------------------------------------------------------------

    1 CONSTANT <SOH> \ Character used to start each record packet.
    2 CONSTANT <STX> \ Character used to start each 1K record packet.
    4 CONSTANT <EOT> \ Character used to conclude the transmission of the file.
   21 CONSTANT <NAK> \ Character used to signal a bad transmission.
    6 CONSTANT <ACK> \ Character used to signal a good transmission.
   26 CONSTANT <EOF> \ CP/M End Of File marker
   24 CONSTANT <CAN> \ Used to cancel transfer from "other" end

    2 VALUE STIME 	\ Short delay for receiving characters
   10 VALUE LTIME 	\ Long delay for receiving headers

VARIABLE CANCELS	\ Holds number of consecutive cancels; 0, 1 or 2
VARIABLE REC#		\ Holds the sequence number of the current packet

VARIABLE RETRIES	\ Holds number of retries for the current record
VARIABLE TOTAL		\ Holds the number of bytes transferred
VARIABLE SERDEV		\ Holds serial device port number

\ Dynamic arrays allocated at run time.
128 VALUE REC-SIZE	\ Size of receive buffer; 128 or 1024
  0 VALUE REC-BUF	\ Points to the record buffer

  0 VALUE MEM-ADDR	\ Memory address to transfer
  0 VALUE MEM-SIZE	\ Memory size to transfer

\ Protocol vectors
VARIABLE 'CHECK-PACKET	\ Holds packet checking function
VARIABLE 'SEND-CHECK	\ Holds check sending function
VARIABLE 'GET-CHECK		\ Holds check receiving function
VARIABLE 'WRITE-BUF		\ Holds buffer write function
VARIABLE 'READ-BUF		\ Hold buffer read function
VARIABLE 'XVECTORED		\ Holds routine to vector the I/O
VARIABLE 'XUNVECTORED	\ Holds routine to unvector the I/O

FALSE VALUE FLG-PROGRESS	\ True if displaying progress
FALSE VALUE FLG-DEBUGGING   \ True if debugging
FALSE VALUE FLG-SERDEV-IO	\ True if displaying i/o
FALSE VALUE FLG-TRACING     \ Tranfer point to start tracing
 TRUE VALUE FLG-SERPORT		\ Use direct port i/o
FALSE VALUE FLG-OVERLAP		\ Overlap receive i/o

VARIABLE TRACING-LEVEL  \ Record number of trace levels

: STOP-TRIGGER ( c-addr len -- ) \ Stop triggered trace
	TOTAL @ FLG-TRACING >
	IF	TRACING-LEVEL @  DUP 1+
		TRACING-LEVEL !  0=
		IF	CR TYPE ( STOP-TRACE ??? )  EXIT
		THEN
	THEN  2DROP
;

: START-TRIGGER ( c-addr len -- ) \ Start triggered trace
	TOTAL @ FLG-TRACING >
	IF	TRACING-LEVEL @  1- 0 MAX DUP
		TRACING-LEVEL !  0=
		IF	CR TYPE ( START-TRACE ??? )  EXIT
		THEN
	THEN  2DROP
;

: XVECTORED ( -- ) \ Vector the I/O
	'XVECTORED @EXECUTE
;

: XUNVECTORED ( -- ) \ Unvector the I/O
	'XUNVECTORED @EXECUTE
;

: WRITE-BUF ( c-addr len total -- ior ) \ Write bytes from buffer.
\ Return a non-zero ior if the transfer should be aborted.  The total
\ is the number of bytes which have been received prior to this packet.
	FLG-TRACING IF  S" Start trace" START-TRIGGER  THEN
	'WRITE-BUF @EXECUTE
;

: WRITE-MEM ( c-addr len total -- ior ) \ Write memory from buffer.
	DUP MEM-SIZE < DUP >R
	IF	SWAP OVER + MEM-SIZE MIN OVER -
		SWAP MEM-ADDR + SWAP MOVE
	ELSE  DROP 2DROP
	THEN  R> 0=
;

: READ-BUF ( c-addr len total -- num ) \ Read bytes into buffer.
\ Returns the number of characters actually read.  This number is
\ zero if the end of the transfer has been reached or negative if
\ the transfer should be aborted.  The total is the number of bytes
\ which have been transmitted prior to this packet.
	FLG-TRACING IF  S" Start trace" START-TRIGGER  THEN
	>R 2DUP <EOF> FILL R>							\ Use EOF as filler
	'READ-BUF @EXECUTE
;

: READ-MEM ( c-addr len total -- num ) \ Read memory into buffer.
	DUP MEM-SIZE <
	IF	SWAP OVER + MEM-SIZE MIN OVER - DUP >R
		SWAP MEM-ADDR + -ROT MOVE R>
	ELSE  DROP 2DROP 0
	THEN
;

: SEND-CHECK ( num -- ) \ Send check bytes
   'SEND-CHECK @EXECUTE
;

: GET-CHECK ( -- num ) \ Receive check bytes
   'GET-CHECK @EXECUTE
;

: CHECK-PACKET ( -- num ) \ Check the packet
	FLG-TRACING IF  S" Skip packet check" STOP-TRIGGER  THEN
	REC-BUF REC-SIZE 'CHECK-PACKET @EXECUTE
	FLG-TRACING IF  S" Resume after packet check" START-TRIGGER  THEN
;

: XALLOCATE ( -- ) \ Allocate & setup transfer buffer
	1 REC# !  0 RETRIES !  0 CANCELS !  0 TOTAL !
	REC-SIZE ALLOCATE THROW TO REC-BUF
;

: XRELEASE ( -- ) \ Release transfer buffers
	REC-BUF FREE THROW  0 TO REC-BUF
;

: CANCEL ( -- )   \ Send abort sequence.
\ The standard XMODEM abort sequence of 8 CAN's
\ followed by 8 backspaces to cover them up.
	8 0 DO  <CAN> XEMIT  LOOP
	8 0 DO  8 XEMIT  LOOP
;

: XABORT ( u -- ) \ Abort current transfer
	CANCEL  THROW
;

: XSECS ( -- secs )   UTIME 1000000 UM/MOD NIP ;

: USER-CANCELED ( -- ) \ Check if cancel key pressed
	KEY?						\ If user hit a key
	IF	KEY 27 =				\ If it's the Esc key
		IF	CANCEL 1 ABORT" Cancelled by user "
		THEN
	THEN
;

: ?TIMER ( secs -- flag ) \ True if time has expired
	XSECS -  -86400 1 WITHIN   \ within the last 24 hours
;

: ?CANCELED ( char -- char ) \ Abort on 2nd <CAN>
	DUP <CAN> =
	IF	1 CANCELS +!  CANCELS @ 1 >
		IF	CANCEL 1 ABORT" Cancelled by remote "
		THEN
	ELSE  0 CANCELS !
	THEN
;

: ?RETRY ( -- ) \ Abort after 10 tries
	1 RETRIES +!  RETRIES @ 9 >
	IF	CANCEL 1 ABORT" Transfer error "
	THEN
;

: WAITCAN ( secs -- char ) \ Wait for the input number of seconds
\ for a character.  If one is not received in that amount of time,
\ abort with a timeout.  If a byte is received, check it for <CAN>.
	FLG-TRACING IF  S" Skip wait for cancel" STOP-TRIGGER  THEN
	XSECS +										\ Get expiration time
	BEGIN  XKEY? 0=
	WHILE  DUP ?TIMER  USER-CANCELED
		IF
	FLG-TRACING IF  S" Resume after wait for cancel" START-TRIGGER  THEN
			CANCEL 1 ABORT" Transfer timeout "
		THEN
	REPEAT  DROP  XKEY  ?CANCELED
	FLG-TRACING IF  S" Resume after wait for cancel" START-TRIGGER  THEN
;

: XWAIT ( secs -- char | -1 ) \ Wait for given time.
\  If a character is not received in this time, a -1 is returned.
	FLG-TRACING IF  S" Skip wait for key" STOP-TRIGGER  THEN
	XKEY? 0=									\ If character not waiting
	IF	XSECS +									\ Get expiration time
		BEGIN  XKEY? 0=							\ While character not waiting
		WHILE  DUP ?TIMER  USER-CANCELED
			IF									\ If timer is expired
	FLG-TRACING IF  S" Resume after wait for key" START-TRIGGER  THEN
				DROP  -1  EXIT					\ Get out of here
			THEN
		REPEAT
	THEN  DROP  XKEY							\ Get waiting character
	FLG-TRACING IF  S" Resume after wait for key" START-TRIGGER  THEN
;

: LWAIT ( -- char | -1 ) \ Wait for long interval
	LTIME XWAIT
;

: SWAIT ( -- char | -1 ) \ Wait for short interval
	STIME XWAIT
;

: SEND-REC ( c-addr len -- ) \ Send string of characters
	FLG-TRACING IF  S" Skip sending keys" STOP-TRIGGER  THEN
	BOUNDS
	DO	I C@ XEMIT
	LOOP
	FLG-TRACING IF  S" Resume after sending keys" START-TRIGGER  THEN
;

: WAIT-REC ( c-addr len -- flag ) \ Wait for string
	FLG-TRACING IF  S" Skip waiting for keys" STOP-TRIGGER  THEN
	2DUP <EOF> FILL
	TRUE -ROT BOUNDS			\ For the address range
	DO	SWAIT DUP -1 =			\ If we timed out
		IF	DROP 0= LEAVE		\ Get out of here
		THEN  I C!				\ Store the character
	LOOP
	FLG-TRACING IF  S" Resume after getting keys" START-TRIGGER  THEN
;

: CLEAN-LINE ( -- ) \ Clear the receive queue
	FLG-TRACING IF  S" Skip clean line" STOP-TRIGGER  THEN
	BEGIN
		SWAIT -1 = \ Get character until timed out
	UNTIL
	FLG-TRACING IF  S" Resume after clean line" START-TRIGGER  THEN
;

: DISPLAY-HEADER ( S: c-addr len -- ) ( G: Display protocol header )
	XVECTORED  FLG-PROGRESS IF  CR 2DUP TYPE SPACE  THEN
	2DROP
;

: DISPLAY-STATUS ( S: c-addr len -- ) ( G: Display status information )
	FLG-TRACING IF  S" Skip display status" STOP-TRIGGER  THEN
	FLG-PROGRESS IF  CR 2DUP TYPE SPACE  THEN
	2DROP
	FLG-TRACING IF  S" Resume after status" START-TRIGGER  THEN
;

: DISPLAY-PROGRESS ( S: c-addr len -- ) ( G: Display progress message )
	FLG-TRACING IF  S" Skip display progress" STOP-TRIGGER  THEN
	<#  TOTAL @ 0 #S  BL HOLD  2SWAP BOUNDS SWAP 1-
		DO	I C@ HOLD -1
		+LOOP
	#>  FLG-PROGRESS IF  CR 2DUP TYPE SPACE  THEN
	2DROP
	FLG-TRACING IF  S" Resume after progress" START-TRIGGER  THEN
;

: CHECK-SUM ( c-addr len -- char ) \ Sum characters, modulo 255
	0 -ROT BOUNDS
	DO	I C@ +
	LOOP  255 AND
;

: SEND-SUM ( char -- ) \ Send one byte check
	XEMIT
;

: GET-SUM ( -- char ) \ Receive one byte check
	LWAIT
;

: XMODEM ( -- ) \ Vector routines for check sum
	S" XMODEM" DISPLAY-HEADER
	['] CHECK-SUM 'CHECK-PACKET !
	['] SEND-SUM 'SEND-CHECK !
	['] GET-SUM 'GET-CHECK !
	128 TO REC-SIZE
;

HEX

: CRC ( c-addr len -- u ) \ Calculate Xmodem CRC
	0 -ROT BOUNDS
	DO	I C@  8 LSHIFT XOR  8 0
		DO	2*  DUP 10000 AND
			IF	1021 XOR
			THEN
		LOOP
	LOOP  0FFFF AND
;

DECIMAL

: SEND-CRC ( num -- ) \ Send 16 bit CRC, MSB first
	DUP 8 RSHIFT XEMIT XEMIT
;

: GET-CRC ( -- num ) \ Receive 16 bit CRC, MSB first
	LWAIT 8 LSHIFT  SWAIT OR
;

: XMODEM-CRC ( -- ) \ Vector routines for CRC-16
	S" XMODEM-CRC" DISPLAY-HEADER
	['] CRC 'CHECK-PACKET !
	['] SEND-CRC 'SEND-CHECK !
	['] GET-CRC 'GET-CHECK !
	128 TO REC-SIZE
;

: XMODEM-1K ( -- ) \ Vector routines for 1024 byte CRC-16
	S" XMODEM-1K" DISPLAY-HEADER
	['] CRC 'CHECK-PACKET !
	['] SEND-CRC 'SEND-CHECK !
	['] GET-CRC 'GET-CHECK !
	1024 TO REC-SIZE
;

: TXREC ( -- ) \ Transmit each record to the receiver.
\ Each record is preceeded by a <SOH> and the record number,
\ straight and inverted.  They are followed by the CHECK-PACKET bytes.
\ Once sent, we wait for a response byte.  If the response is not
\ an <ACK> we attempt to send the record again.
	S" Checking packet" DISPLAY-STATUS  CHECK-PACKET ( * )
	S" Transmit" DISPLAY-PROGRESS
	0 RETRIES !  0 CANCELS !
	BEGIN  REC-SIZE 128 =
		IF	<SOH> XEMIT				\ 128 byte packet
		ELSE  <STX> XEMIT			\ 1024 byte packet
		THEN  REC# @ 255 AND  DUP XEMIT  -1 XOR XEMIT  REC-BUF REC-SIZE SEND-REC
		FLG-DEBUGGING IF  BASE @ >R HEX .S ." is check " R> BASE !  THEN
		DUP ( * ) SEND-CHECK  15 WAITCAN  <ACK> -
	WHILE  S" Transmit error" DISPLAY-STATUS
		?RETRY  CLEAN-LINE
	REPEAT  DROP ( * )
;

: (XTRANSMIT) ( -- ) \ Send the open file by waiting for
\ the <NAK> or a "C" and then sending the records until the entire
\ file has been sent.  The <NAK> will trigger XMODEM and the "C"
\ will trigger XMODEM-CRC protocols.  An <EOT> is sent and must be
\ acknowledged before we return.
	S" Synch receiver" DISPLAY-STATUS  XALLOCATE  CLEAN-LINE
	BEGIN  60 WAITCAN  DUP <NAK> =
		IF	0= XMODEM
		THEN  DUP [CHAR] C =
		IF	0= XMODEM-CRC
		THEN  0=
	UNTIL
	BEGIN  REC-BUF REC-SIZE TOTAL @
		READ-BUF DUP 0<
		IF	CANCEL 1 ABORT" Data read error "
		THEN
	WHILE  TXREC  1 REC# +!  REC-SIZE TOTAL +!
	REPEAT  S" Transmit <EOT>" DISPLAY-STATUS
	BEGIN  <EOT> XEMIT  60 WAITCAN  <ACK> =
	UNTIL  S" Trans complete" DISPLAY-STATUS
;

: CNAK ( -- char ) \ Initialization code.  The code is
\ a <NAK> for XMODEM or a "C" for XMODEM-CRC or XMODEM-1K.
	'CHECK-PACKET @  DUP ['] CHECK-SUM =
	SWAP 0= OR IF
		<NAK>  XMODEM
	  ELSE
		[CHAR] C
	  THEN
;

: RXREC ( -- num <ACK> | num <NAK> ) \ Waits for a record
\ packet, verifying that the check bytes and record number
\ are received correctly.
	SWAIT  SWAIT  REC-BUF REC-SIZE WAIT-REC
	IF	S" Checking packet" DISPLAY-STATUS  GET-CHECK  CHECK-PACKET
		FLG-DEBUGGING IF  BASE @ >R HEX .S ." check " R> BASE !  THEN
		<> IF  S" Packet chk error" DISPLAY-STATUS  DROP <NAK>
		ELSE  OVER -1 XOR XOR 255 AND
			IF	S" Complement error" DISPLAY-STATUS  <NAK>
			ELSE  <ACK>
				FLG-OVERLAP IF  DUP XEMIT  THEN		\ Overlap packet handling
			THEN
		THEN
	ELSE  DROP <NAK>
	THEN
;

: WAITREC ( char -- num <ACK> | <NAK> | <EOT> ) \ Syncs with
\ the transmitter's <SOH> or <STX> before receiving the record packet.
\ A <SOH> will indicate a 128 byte packet and a <STX> will indicate a
\ 1024 byte packet.  A <NAK> is sent if it is not received in time.
	DUP <NAK> =								\ If last packet bad
	IF	CLEAN-LINE							\ Clean up the line
	THEN
	BEGIN
		FLG-DEBUGGING IF  BASE @ >R HEX .S ." sync " R> BASE !  THEN
		FLG-OVERLAP
		IF	DUP <ACK> <>					\ If not already acked
			IF	DUP XEMIT					\ Output sync character
			THEN
		ELSE  DUP XEMIT
		THEN  LWAIT DUP <SOH> = DUP			\ If 128 byte packets
		IF	128 TO REC-SIZE
		ELSE  OVER <STX> = DUP				\ If 1024 byte packets
			IF	XMODEM-1K
			THEN  OR
		THEN  0=
	WHILE  DUP <EOT> =
		IF	NIP EXIT
		THEN  DUP <CAN> =
		IF	?CANCELED DROP
			SWAIT ?CANCELED
		THEN  -1 =
		IF	S" Can't sync trans" DISPLAY-STATUS
		THEN  CLEAN-LINE  DUP <ACK> =
		IF	DROP <NAK>
		THEN  ?RETRY
	REPEAT  2DROP  RXREC
	FLG-DEBUGGING IF  BASE @ >R HEX .S ." received " R> BASE !
					  REC-BUF REC-SIZE DUMP CR  THEN
;

: SEQ-CHECK ( rec# -- ) \ Checks the input record number
\ against the current record number, aborting if they are not the same.
\ Writes the buffer to disk if they are the same.
	DUP REC# @ 255 AND =						\ If packet number is correct
	IF	DROP  REC-BUF REC-SIZE TOTAL @
		WRITE-BUF ?DUP							\ If an error is detected
		IF	CANCEL 1 ABORT" Data write error "	\ Abort the transfer
		THEN  1 REC# +!  0 RETRIES !  0 CANCELS !  REC-SIZE TOTAL +!
	ELSE  REC# @ 1- 255 AND -					\ If not previous packet
		IF	CANCEL 1 ABORT" Sequence error "
		THEN
	THEN
;

: (XRECEIVE) ( -- ) \ Receive packets
	XMODEM-1K  XALLOCATE  CLEAN-LINE  CNAK
	S" Awaiting packet" DISPLAY-STATUS
	BEGIN  DUP <ACK> =
		IF	S" Receive" DISPLAY-PROGRESS
		THEN  WAITREC  DUP <EOT> -
	WHILE  DUP <ACK> =
		IF	SWAP SEQ-CHECK
		ELSE  NIP  ?RETRY
		THEN
	REPEAT  DROP  <ACK> XEMIT
	S" Receive complete" DISPLAY-STATUS
;

: XTRANSMIT ( addr len -- ior ) \ Transmit packets
	TO MEM-SIZE  TO MEM-ADDR  XVECTORED
	['] (XTRANSMIT) CATCH  XRELEASE
	XUNVECTORED
;

: XRECEIVE ( addr len -- ior ) \ Receive packets
	TO MEM-SIZE  TO MEM-ADDR  XVECTORED
	['] (XRECEIVE) CATCH  XRELEASE
	XUNVECTORED
;

: XDEFAULTS ( -- ) \ Default to XMODEM-1K Vectors for 1024 byte CRC-16
	['] WRITE-MEM 'WRITE-BUF !
	['] READ-MEM 'READ-BUF !
	['] CRC 'CHECK-PACKET !
	['] SEND-CRC 'SEND-CHECK !
	['] GET-CRC 'GET-CHECK !
	1024 TO REC-SIZE
;

XDEFAULTS

[THEN]
