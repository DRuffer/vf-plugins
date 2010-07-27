#! /usr/bin/env gforth
\ 		File:	TestSerial.f
\				Translated to GForth by Dennis Ruffer

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

: TestSerialSection ( -- )   s" TestSerial sample code" subSection
	s" The basic serial port support was taken from KeySpan's" >fileLine
	s" testserial.c -- test/sample code for MacOS X serial ports." >fileLine
	s" A command line driven test program allows exercise of various serial port functions by hand." >fileLine
		fileCr
	s" With additions described in Serial Programming Guide for POSIX Operating Systems" >fileLine
	s" 5th Edition, Michael R. Sweet, Copyright 1994-1999, All Rights Reserved." >fileLine
		fileCr
	s" Usage: gforth TestSerial.f (type TestSerial h to display a list of commands)" >fileLine
		fileCr
	s" \begin{description}" >fileLine
	s" \item[\texttt{h}]display a list of commands" >fileLine
	s" \item[\texttt{q}]quit" >fileLine
	s" \item[\texttt{o n}]open port \#n" >fileLine
	s" \item[\texttt{c}]close" >fileLine
	s" \item[\texttt{s}]test read select" >fileLine
	s" \item[\texttt{sw n}]test write select" >fileLine
	s" \item[\texttt{r n}]read n bytes" >fileLine
	s" \item[\texttt{w data}]write" >fileLine
	s" \item[\texttt{w/ n m}]write n lines of m characters each, beginning with 'A'" >fileLine
	s" \item[\texttt{b baud p d s f}]set baudRate, Parity, dataBits, stopBits, flowControl" >fileLine
	s" \item[\texttt{bs}]set port variables, without doing actual I/O" >fileLine
	s" \item[\texttt{g}]get all modem bits" >fileLine
	s" \item[\texttt{gs x}]set modem bits" >fileLine
	s" \item[\texttt{l}]list serial ports" >fileLine
	s" \item[\texttt{m}]poll port" >fileLine
	s" \item[\texttt{t}]toggle read thread" >fileLine
	s" \end{description}" >fileLine
	endSection ;

\ In the public beta, MacOS X serial ports are provided by device specific device drivers publishing the
\ ports through a kernel extension known as Port Server.  In future versions this mechanism will be
\ replaced by IOSerialFamily.
\
\ c build with:     cc -o testserial -framework CoreFoundation -framework IOKit testserial.c

\ c includes:
\	<stdio.h>							/usr/include/stdio.h
\	<fcntl.h>							/usr/include/fcntl.h
\	<sys/errno.h>						/System/Library/Frameworks/Kernel.framework/Versions/A/Headers/sys/errno.h
\	<sys/termios.h> 					/System/Library/Frameworks/Kernel.framework/Versions/A/Headers/sys/termios.h
\	<sys/types.h>						/System/Library/Frameworks/Kernel.framework/Versions/A/Headers/sys/types.h
\	<sys/time.h>						/System/Library/Frameworks/Kernel.framework/Versions/A/Headers/sys/time.h
\	<unistd.h>							/usr/include/unistd.h

\	<sys/filio.h>						/System/Library/Frameworks/Kernel.framework/Versions/A/Headers/sys/filio.h
\	<sys/ioctl.h>						/System/Library/Frameworks/Kernel.framework/Versions/A/Headers/sys/ioctl.h
\	<CoreFoundation/CoreFoundation.h>	/System/Library/Frameworks/CoreFoundation.framework/Versions/A/Headers/CoreFoundation.h

\	<IOKit/IOKitLib.h>					/System/Library/Frameworks/IOKit.framework/Versions/A/Headers/IOKitLib.h
\	<IOKit/serial/IOSerialKeys.h>		/System/Library/Frameworks/IOKit.framework/Versions/A/Headers/serial/IOSerialKeys.h
\	<IOKit/IOBSD.h>						/System/Library/Frameworks/IOKit.framework/Versions/A/Headers/IOBSD.h

\	<pthread.h>							/usr/include/pthread.h

\ sample to show reading the MacOS X registry to find IOSerialFamily serial ports

[defined] TestSerial.version 0= [IF]

1 constant TestSerial.version

FORTH DEFINITIONS

[defined] NewTask 0= [IF] include tasker.fs [THEN]
[defined] library 0= [IF] include lib.fs [THEN]

[defined] libc 0= [IF] library libc /usr/lib/libc.dylib [THEN]

4 (int) libc pthread_create pthread_create
1 (int) libc pthread_cancel pthread_cancel
0 (int) libc pthread_self pthread_self
2 (int) libc cfsetspeed cfsetspeed
1 (int) libc cfmakeraw cfmakeraw
2 (int) libc tcgetattr tcgetattr
3 (int) libc tcsetattr tcsetattr
2 (int) libc tcflush tcflush
5 (int) libc select select
3 (int) libc memset memset
0 (int) libc errno __error
2 (int) libc bzero bzero
3 (int) libc bcopy bcopy
3 (int) libc ioctl ioctl
3 (int) libc fcntl fcntl
1 (int) libc close close
3 (int) libc write write
3 (int) libc read read
2 (int) libc open open

library CoreFoundation /System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation

1 (int) CoreFoundation CFStringMakeConstantString __CFStringMakeConstantString
3 (int) CoreFoundation CFStringCreateWithCString CFStringCreateWithCString
3 (int) CoreFoundation CFDictionarySetValue CFDictionarySetValue
4 (int) CoreFoundation CFStringGetCString CFStringGetCString
1 (int) CoreFoundation CFRelease CFRelease

: CFMutableDictionaryRef ( _ -- )   variable ;
: CFTypeRef ( _ -- )   variable ;

0 constant kCFAllocatorDefault

\ in creating CFString, values greater than 0x7F are treated as corresponding Unicode value
hex 0600 decimal constant kCFStringEncodingASCII		\ 0..127

library IOKit /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit

4 (int) IOKit IORegistryEntryCreateCFProperty IORegistryEntryCreateCFProperty
3 (int) IOKit IOServiceGetMatchingServices IOServiceGetMatchingServices
1 (int) IOKit IOServiceMatching IOServiceMatching
1 (int) IOKit IOIteratorNext IOIteratorNext
2 (int) IOKit IOMasterPort IOMasterPort

:           natural_t ( _ -- )   variable ;
:         port_name_t ( _ -- )   natural_t ;
:              port_t ( _ -- )   port_name_t ;
:         mach_port_t ( _ -- )   port_t ;
:         io_object_t ( _ -- )   mach_port_t ;
:           pthread_t ( _ -- )   mach_port_t ;
: io_registry_entry_t ( _ -- )   io_object_t ;
:       io_iterator_t ( _ -- )   io_object_t ;

variable readArmed  0 readArmed !
variable writeArmed  0 writeArmed !
variable fd  0 fd !

create line 100 allot

warnings off
4096 constant BUFSIZE
create theBuff BUFSIZE allot
create theBuff2 BUFSIZE allot
warnings on

variable countPorts  -1 countPorts !
10 constant	kMaxPorts
40 constant kMaxPortLen

: portField ( a n -- a+n )   over create ,  +
   does> ( a -- a' )   @ + ;

0 \ portList
	kMaxPortLen portField portName
	kMaxPortLen portField dialIn
	kMaxPortLen portField callOut
constant |portList|

create portList   |portList| kMaxPorts * allot

\ these bits are defined in /usr/include/sys/types.h
    8 constant NBBY				\ number of bits in a byte
 1024 constant FD_SETSIZE
4 8 * constant NFDBITS			\ bits per mask

: howmany ( x y -- )   dup >r 1 - + r> / ;		\ (((x) + ((y) - 1)) / (y))

1 cells constant int32_t
1 cells constant fd_mask

FD_SETSIZE NFDBITS howmany constant |fds_bits|
fd_mask |fds_bits| * constant |fd_set|

: FD_SET ( n p -- )   over NFDBITS / + dup @ rot NFDBITS mod 1 swap lshift or swap ! ;
: FD_CLR ( n p -- )   over NFDBITS / + dup @ rot NFDBITS mod 1 swap lshift invert and swap ! ;
: FD_ISSET ( n p -- )   over NFDBITS / + @ swap NFDBITS mod 1 swap lshift and ;
: FD_COPY ( f t -- )   |fds_bits| bcopy drop ;
: FD_ZERO ( p -- )   |fds_bits| bzero drop ;

\ name changed to prevent conflicts with FD_SET
: fd-set ( -name- )   create |fd_set| allot ;

fd-set		theRd
fd-set		theWr
fd-set		theEx

variable theTime \ time in seconds

\ these bits are defined in /usr/include/sys/termios.h
20 constant NCCS
1 cells constant tcflag_t
1 cells constant speed_t
1 chars constant cc_t

: termField ( a n -- a+n )   over create ,  +
   does> ( a -- a' )   @ + ;

0 \ termios
	tcflag_t		termField	c_iflag		\ input flags
	tcflag_t		termField	c_oflag		\ output flags
	tcflag_t		termField	c_cflag		\ control flags
	tcflag_t		termField	c_lflag		\ local flags
	1 chars NCCS *	termField	c_cc		\ control chars
	speed_t			termField	c_ispeed	\ input speed
	speed_t			termField	c_ospeed	\ output speed
constant |termios|

\ Index into c_cc[] character array.
12 constant VSTART		\ IXON, IXOFF
13 constant VSTOP		\ IXON, IXOFF

\ constants used with tcflush
1 constant TCIFLUSH
2 constant TCOFLUSH
3 constant TCIOFLUSH

hex

\ c_iflag - Input flags - software input processing

00000001 constant IGNBRK			\ ignore BREAK condition
00000002 constant BRKINT			\ map BREAK to SIGINTR
00000004 constant IGNPAR			\ ignore (discard) parity errors
00000008 constant PARMRK			\ mark parity and framing errors
00000010 constant INPCK				\ enable checking of parity errors
00000020 constant ISTRIP			\ strip 8th bit off chars
00000040 constant INLCR				\ map NL into CR
00000080 constant IGNCR				\ ignore CR
00000100 constant ICRNL				\ map CR to NL (ala CRMOD)
00000200 constant IXON				\ enable output flow control
00000400 constant IXOFF				\ enable input flow control
00000800 constant IXANY				\ any char will restart after stop
00002000 constant IMAXBEL			\ ring bell on input queue full

\ c_oflag - Output flags - software output processing

00000001 constant OPOST				\ enable following output processing
00000002 constant ONLCR				\ map NL to CR-NL (ala CRMOD)
00000004 constant OXTABS			\ expand tabs to spaces
00000008 constant ONOEOT			\ discard EOT's (^D) on output)

\ c_cflag - Control flags - hardware control of terminal

00000001 constant CIGNORE			\ ignore control flags
00000300 constant CSIZE				\ character size mask
00000000 constant CS5				\ 5 bits (pseudo)
00000100 constant CS6				\ 6 bits
00000200 constant CS7				\ 7 bits
00000300 constant CS8				\ 8 bits
00000400 constant CSTOPB			\ send 2 stop bits
00000800 constant CREAD				\ enable receiver
00001000 constant PARENB			\ parity enable
00002000 constant PARODD			\ odd parity, else even
00004000 constant HUPCL				\ hang up on last close
00008000 constant CLOCAL			\ ignore modem status lines
00010000 constant CCTS_OFLOW		\ CTS flow control of output
00020000 constant CRTS_IFLOW		\ RTS flow control of input
00040000 constant CDTR_IFLOW		\ DTR flow control of input
00080000 constant CDSR_OFLOW		\ DSR flow control of output
00100000 constant CCAR_OFLOW		\ DCD flow control of output

' CCAR_OFLOW Alias MDMBUF			\ old name for CCAR_OFLOW

CCTS_OFLOW CRTS_IFLOW or constant CRTSCTS

\ c_lflag - "Local" flags - dumping ground for other state

00000001 constant ECHOKE			\ visual erase for line kill
00000002 constant ECHOE				\ visually erase chars
00000004 constant ECHOK				\ echo NL after line kill
00000008 constant ECHO				\ enable echoing
00000010 constant ECHONL			\ echo NL even if ECHO is off
00000020 constant ECHOPRT			\ visual erase mode for hardcopy
00000040 constant ECHOCTL  			\ echo control chars as ^(Char)
00000080 constant ISIG				\ enable signals INTR, QUIT, [D]SUSP
00000100 constant ICANON			\ canonicalize input lines
00000200 constant ALTWERASE			\ use alternate WERASE algorithm
00000400 constant IEXTEN			\ enable DISCARD and LNEXT
00000800 constant EXTPROC			\ external processing
00400000 constant TOSTOP			\ stop background jobs from output
00800000 constant FLUSHO			\ output being flushed (state)
02000000 constant NOKERNINFO		\ no kernel output from VSTATUS
20000000 constant PENDIN			\ XXX retype pending input (state)
80000000 constant NOFLSH			\ don't flush after interrupt

\ Commands passed to tcsetattr() for setting the termios structure.

00 constant TCSANOW					\ make change immediate
01 constant TCSADRAIN				\ drain output, then change
02 constant TCSAFLUSH				\ drain output, flush input
10 constant TCSASOFT				\ flag - don't alter h.w. state

\ modem control state

0001 constant TIOCM_LE				\ line enable
0002 constant TIOCM_DTR				\ data terminal ready
0004 constant TIOCM_RTS				\ request to send
0010 constant TIOCM_ST				\ secondary transmit
0020 constant TIOCM_SR				\ secondary receive
0040 constant TIOCM_CTS				\ clear to send
0100 constant TIOCM_CAR				\ carrier detect
0200 constant TIOCM_RNG				\ ring
0400 constant TIOCM_DSR				\ data set ready

TIOCM_CAR constant TIOCM_CD
TIOCM_RNG constant TIOCM_RI

decimal

: termios ( -name- )   here |termios| allot  value ;

termios theTermios

: .termios ( a -- )
	base @ >r hex
	>r ." termios: iFlag " r@ c_iflag @ u.
				." oFlag " r@ c_oflag @ u.
				." cFlag " r@ c_cflag @ u.
				." lFlag " r@ c_lflag @ u.
				." speed " r@ c_ispeed decimal ?
	r> drop
	r> base !
;

\ several names used for IOSerialFamily ports

: DEVICENAME ( -- zstr )    s" /dev/tty.KeyUSA28XP1" >asciz ;
: DEVICENAME2 ( -- zstr )   s" /dev/tty.KeyUSA28XP2" >asciz ;

\ name of Port #1 on the USA-28X with the PortServer driver in the public beta

: DEVICENAME3 ( -- zstr )   s" /dev/ttyd.KeyUSA28XP1" >asciz ;

\ non-blocked "call out" port for IOSerialFamily

: DEVICENAME4 ( -- zstr )   s" /dev/cu.KeyUSA28XP1" >asciz ;

\ sample to show reading the MacOS X registry to find IOSerialFamily serial ports

: kIOSerialBSDServiceValue ( -- zstr )   s" IOSerialBSDClient" >asciz ;

: kIOSerialBSDTypeKey ( -- cfstr )   s" IOSerialBSDClientType" >asciz CFStringMakeConstantString ;
: kIOSerialBSDRS232Type ( -- cfstr )   s" IORS232SerialStream" >asciz CFStringMakeConstantString ;

mach_port_t				masterPort
CFMutableDictionaryRef	classesToMatch

: createSerialIterator ( serialIterator -- )
	>r 0 masterPort IOMasterPort abort" IOMasterPort returned error"
	kIOSerialBSDServiceValue IOServiceMatching dup classesToMatch !
	0= abort" IOServiceMatching returned NULL"
	classesToMatch @ kIOSerialBSDTypeKey kIOSerialBSDRS232Type CFDictionarySetValue drop
	masterPort @ classesToMatch @ r> IOServiceGetMatchingServices
	abort" IOServiceGetMatchingServices returned error"
;

create resultStr 256 allot
CFTypeRef nameCFstring

: getRegistryString ( io_object_t propName -- zstr )
	resultStr 256 erase
	swap @ kCFAllocatorDefault rot kCFStringEncodingASCII CFStringCreateWithCString
	kCFAllocatorDefault 0 IORegistryEntryCreateCFProperty
	dup nameCFstring ! if
		nameCFstring @ resultStr 256 kCFStringEncodingASCII CFStringGetCString drop
		nameCFstring @ CFRelease drop
	then
	resultStr
;

: kIOTTYDeviceKey ( -- zstr )   s" IOTTYDevice" >asciz ;
: kIODialinDeviceKey ( -- zstr )   s" IODialinDevice" >asciz ;
: kIOCalloutDeviceKey ( -- zstr )   s" IOCalloutDevice" >asciz ;

io_iterator_t	theSerialIterator
io_object_t		theObject
create			ttyDevice 256 allot
create			dialInDevice 256 allot
create			callOutDevice 256 allot

: >SerialPort ( n -- a )
	dup countPorts @ < 0= abort" Port out of range"
	|portList| * portList +
;

: findSerialPorts ( -- )
    0 countPorts !
    theSerialIterator createSerialIterator
	begin  theSerialIterator @ IOIteratorNext  ?dup
	while  theObject !

		theObject kIOTTYDeviceKey getRegistryString ttyDevice 256 move
		theObject kIODialinDeviceKey getRegistryString dialInDevice 256 move
        theObject kIOCalloutDeviceKey getRegistryString callOutDevice 256 move

		countPorts @ kMaxPorts <
		if	countPorts @ dup >r  1+ countPorts !

			ttyDevice >count kMaxPortLen > abort" ttyDevice too long"
			ttyDevice r@ >SerialPort portName kMaxPortLen move

			dialInDevice >count kMaxPortLen > abort" dialInDevice too long"
			dialInDevice r@ >SerialPort dialIn kMaxPortLen move

			callOutDevice >count kMaxPortLen > abort" callOutDevice too long"
			callOutDevice r> >SerialPort callOut kMaxPortLen move

		then
    repeat
;

: listSerialPorts ( -- )
	findSerialPorts  countPorts @ 0
	?do	cr i . i >SerialPort dup portName dup >count type 2 spaces
		." dialin " dup dialIn dup >count type 2 spaces
		." callout " callOut dup >count type
	loop
;

wordlist constant TestSerial-wordlist

: TestSerial   forth-wordlist
   TestSerial-wordlist
      2 set-order  definitions ;  immediate

TestSerial
: l ( -- )					\ list IOSerialFamily (only) serial ports
	listSerialPorts
;

: h ( -- )					\ 'help' -- display a list of commands
	cr	." q               quit"
	cr	." o n             open port #n"
	cr	." c               close"
	cr	." s               test read select"
	cr	." sw n            test write select"
	cr	." r n             read n bytes"
	cr	." w data          write"
	cr	." w/ n m          write n lines of m characters each, beginning with 'A'"
	cr	." b baud p d s f  set baudRate, Parity, dataBits, stopBits, flowControl"
	cr  ." bs              set port variables, without doing actual I/O"
	cr	." g               get all modem bits"
	cr	." gs x            set modem bits"
	cr	." l               list serial ports"
	cr	." m               poll port"
	cr	." t               toggle read thread"
;

forth definitions hex

: IO ( n _char _name -- )   char 8 lshift or 2000 10 lshift or constant ;
: IOR ( n _char _name -- )   char 8 lshift or 4004 10 lshift or constant ;
: IOW ( n _char _name -- )   char 8 lshift or 8004 10 lshift or constant ;

decimal

\ these bits are defined in /usr/include/sys/ttycom.h
 13 IO  t TIOCEXCL		\ set exclusive use of tty
 97 IO  t TIOCSCTTY		\ become controlling tty
 16 IOW t TIOCFLUSH		\ flush buffers
109 IOW t TIOCMSET		\ set all modem bits
106 IOR t TIOCMGET		\ get all modem bits

\ defined in /usr/include/sys/fcntl.h
0 constant O_NOCTTY		\ don't assign controlling terminal, BSD default
2 constant O_RDWR		\ open for reading and writing
4 constant O_NONBLOCK	\ no delay

4 constant F_SETFL		\ set file status flags

: $openSerialPort ( zstr -- handle ior )
	O_RDWR  O_NOCTTY or  O_NONBLOCK or open
	dup TIOCEXCL 0 ioctl ;
: openSerialPort ( n -- handle ior )   >SerialPort dialIn $openSerialPort ;

: flushSerialPort ( handle -- ior )   tcioflush tcflush ;
: blockSerialPort ( handle -- ior )   F_SETFL 0 fcntl ;

TestSerial
: o ( "n" -- )				\ open port, note that O_NONBLOCK is required to keep open() from
	fd @ 0> if				\ waiting for CD to go high
		." already open"
	else
		bl word count 0 0 2swap >number abort" invalid port number"
		2drop dup openSerialPort abort" can't get exclusive access" dup fd !
		swap >SerialPort portName dup >count type ."  open returned " .
	then
;

: c ( -- )					\ close port
	fd @ ?dup if
		close drop
		0 fd !
	then
;
forth definitions

WARNINGS OFF

: bye TestSerial c forth bye ;				\ make sure we close the port

WARNINGS ON

TestSerial
: q ( -- )					\ quit test program
	bye
;
forth definitions

variable count-chars

\ defined in /usr/include/sys/filio.h
127 IOR f FIONREAD		\ get # bytes to read

: pollSerialPort ( handle -- n ior )
	FIONREAD count-chars ioctl
	count-chars @ swap
;

TestSerial
: m ( -- )					\ poll port
	fd @ 0> if
		fd @ pollSerialPort errno @
		." ioctl - FIONREAD returned "
		." count " rot .
		." ret " swap .
		." errno " .
	then
;
forth definitions

variable modem

TestSerial
: gs ( "n" -- )				\ set modem control bits
	0 0 bl word count >number abort" invalid modem control bits" 2drop modem !
	\ the only one defined here is TIOCM_DTR (0x02) for DTR on/off
	fd @ TIOCMSET modem ioctl if
		." ioctl - TIOCMSET returned error " errno ?
	then
;

: g ( -- )					\ get modem control bits
	\ CTS (GPI) is TIOCM_CTS (0x20) and DCD is TIOCM_CD (0x40)
	fd @ TIOCMGET modem ioctl if
		." ioctl - TIOCMGET returned error " errno ?
	else
		." TIOCMGET modem bits " modem ?
	then
;
forth definitions

variable baudRate				57600 baudRate !
variable dataBits				8 dataBits !
variable stopBits				1 stopBits !
create Parity 1 allot			char N Parity c!
create flowControl 1 allot		char x flowControl c!

: GetTermios ( handle -- ior )   theTermios tcgetattr ;
: SetTermios ( handle -- ior )   TCSANOW theTermios tcsetattr ;
: GetModem ( handle -- ior )   TIOCMGET modem ioctl ;
: SetModem ( handle -- ior )   TIOCMSET modem ioctl ;

TestSerial
: Baud ( n -- )   theTermios swap cfsetspeed throw ;

: Bits ( n -- )		\ Set data bits between 5 and 8
	theTermios c_cflag dup @ CSIZE invert and rot
	case	5 of CS5 or endof
			6 of CS6 or endof
			7 of CS7 or endof
			8 of CS8 or endof
		true abort" Invalid data bits"
	endcase  swap ! ;

: Stps ( n -- )		\ Set stop bits between 1 and 2
	theTermios c_cflag dup @ rot
	case	1 of CSTOPB invert and endof
			2 of CSTOPB or endof
		true abort" Invalid stop bits"
	endcase  swap ! ;

: Penable ( flag -- )	\ Parity Enable, true or false
	if  theTermios c_iflag dup @ INPCK or ISTRIP or swap !
		theTermios c_cflag dup @ PARENB or swap !
	else
		theTermios c_iflag dup @ INPCK invert and swap !
		theTermios c_cflag dup @ PARENB invert and swap !
	then ;

: Eparity ( flag -- )	\ Even Parity
	theTermios c_cflag dup @ rot
	if  PARODD invert and swap !
	else  PARODD or
	then  swap ! ;
forth definitions

: SetupTermios ( -- )   TestSerial
	theTermios 0 |termios| memset drop
	theTermios cfmakeraw drop
	baudRate @ Baud
	dataBits @ Bits
	stopBits @ Stps
	Parity c@ case
		[char] N of false Penable endof
		[char] E of true Penable true Eparity endof
		[char] O of true Penable false Eparity endof
	endcase
	theTermios c_cflag @
	( CREAD or) CLOCAL or							\ turn on READ and ignore modem control lines
\	CCTS_OFLOW CRTS_IFLOW CDTR_IFLOW CDSR_OFLOW CCAR_OFLOW
\	or or or or invert and
\	theTermios c_lflag dup @ ICANON ECHO or ECHOE or ECHONL or ECHOK or
\		ECHOPRT or ECHOCTL or ECHOKE or ISIG or IEXTEN or invert and swap !
	theTermios c_lflag 0 swap !		\ http://lists.ntp.isc.org/pipermail/hackers/2006-March/002061.html
\	theTermios c_iflag dup @ IXON IXOFF IXANY or or invert and swap !
	theTermios c_iflag 0 swap !		\ http://lists.ntp.isc.org/pipermail/hackers/2006-March/002061.html
	flowControl c@ case
		[char] c of CCTS_OFLOW or endof
		[char] d of CDTR_IFLOW or endof
		[char] x of theTermios c_iflag dup @ IXON or IXOFF or swap !
					$11 theTermios c_cc VSTART + c!
					$13 theTermios c_cc VSTOP + c!
		endof
	endcase
	theTermios c_cflag !
\	theTermios c_oflag dup @ OPOST invert and swap !
	theTermios c_oflag 0 swap !		\ http://lists.ntp.isc.org/pipermail/hackers/2006-March/002061.html
	modem @ TIOCM_DTR or modem !
;

TestSerial
: bs ( -baud p d s f- )
	bl word count ?dup if
		0 0 2swap >number abort" invalid baudRate" 2drop baudRate !
		bl word count if
			c@ Parity c!
			bl word count ?dup if
				0 0 2swap >number abort" invalid dataBits" 2drop dataBits !
				bl word count ?dup if
					0 0 2swap >number abort" invalid stopBits" 2drop stopBits !
					bl word count if c@
					else drop bl then
					flowControl c!
				else drop then
			else drop then
		else drop then
	else drop then
;

: b ( -baud p d s f- )					\ configure port
	\ get current termios structure (sys/termios.h)
	fd @ GetTermios ?dup if
		cr ." tcgetattr returned " .
	else  cr ." GET " theTermios .termios
		baudRate @ -1 = if exit then
		cr	." baudRate " baudRate ?
			." Parity " Parity c@ emit space
			." dataBits " dataBits ?
			." stopBits " stopBits ?
			." flow " flowControl c@ emit space
		fd @ GetModem ?dup if
			cr ." TIOCMGET returned " .
		else
			SetupTermios
			fd @ SetTermios ?dup if
				cr ." tcsetattr returned " . ." (errno " errno ? ." )"
			else
				cr ." SET " theTermios .termios
				fd @ SetModem ?dup if
					cr ." TIOCMSET returned " .
				then
			then
		then
	then
;

: r ( "n" -- )				\ given that open() was issued with O_NOBLOCK
	fd @ 0> if				\ read() here will not block
		bl word count ?dup if
			0 0 2swap >number abort" invalid read size" 2drop BUFSIZE min
		else 1 then
		fd @ theBuff rot read
		dup -1 = if
			drop ." read returned errno " errno ?
		else dup 0= if
			drop ." read returned 0"
		else
			." read " dup . ." bytes"
			cr theBuff swap type
		then then
	then
;

: w ( _ -- )				\ write data
	fd @ 0> if
 		fd @ 0 word count write
 		dup -1 = if
			drop ." write returned errno " errno ?
		else
			." write returned " .
		then
	then
;

: w/ ( "n" "m" -- )			\ write n lines of m characters each, beginning with 'A'
	fd @ 0> if
		bl word count ?dup if
			0 0 2swap >number abort" invalid number of lines" 2drop
		else 1 then
		bl word count ?dup if
			0 0 2swap >number abort" invalid number of characters" 2drop
		else 1 then
		2dup 2 + * BUFSIZE > abort" theBuff is not large enough"
		over 0 ?do
			theBuff over 2 + i * +
			over 0 ?do
				[char] A i + over i + c!
			loop
			2dup + 13 swap c!
			over + 10 swap 1+ c!
		loop
		fd @ theBuff 2swap 2 + * write
 		dup -1 = if
			drop ." write returned errno " errno ?
		else
			." write returned " .
		then
		theWr FD_ZERO
		fd @ theWr FD_SET
		5 theTime !
		fd @ 1+ 0 theWr 0 theTime select
		." select (w) returned " .
		." wr " fd @ theWr FD_ISSET .
	then
;

: sw ( "n" -- )				\ test write select
	fd @ 0> if
		theWr FD_ZERO
		fd @ theWr FD_SET
		bl word count ?dup if
			0 0 2swap >number abort" invalid number of seconds" 2drop
		else 0 then
		theTime !
		fd @ 1+ 0 theWr 0 theTime select
		." select (w) returned " .
		." wr " fd @ theWr FD_ISSET .
	then
;

: s ( -- )					\ test read select
	fd @ 0> if
		theRd FD_ZERO
		fd @ theRd FD_SET
		theWr FD_ZERO
		fd @ theWr FD_SET
		theEx FD_ZERO
		fd @ theEx FD_SET
		0 theTime !
		fd @ 1+ theRd theWr theEx theTime select
		." select returned " .
		." rd " fd @ theRd FD_ISSET .
		." wr " fd @ theWr FD_ISSET .
		." ex " fd @ theEx FD_ISSET .
	then
;
forth definitions

pthread_t theReadThread
pthread_t theWriteThread

variable readCall				\ don't rely on either version of lib.fs
variable writeCall				\ don't rely on either version of lib.fs

: /readCall ( -- )
	s" read" s" /usr/lib/libc.dylib"
	open-lib lib-sym readCall ! ;
/readCall

: /writeCall ( -- )
	s" write" s" /usr/lib/libc.dylib"
	open-lib lib-sym writeCall ! ;
/writeCall

: init-rwCall ( -- )   defers 'cold  /readCall  /writeCall ;

' init-rwCall IS 'cold

: hi16 ( x -- x' )   $10 rshift ;
: lo16 ( x -- x' )   $FFFF and ;

0 [if]
: readThread \ high level equivalent of code in readThread
	begin  readArmed @
		if  fd @ theBuff2 1+ 1 read theBuff2 c!
			cr ." read returned " theBuff2 count .
			." data " c@ .
		then
	again ;
[else]
code readThread
	here here here \ begins
		1 0 readArmed hi16		addis
		1 1 readArmed lo16		ori
		0 0 1					lwz
		0 0 0					or.
		12 2 rot				bc		\ 0<> until
			5 0 1					addi
			4 0 theBuff2 1+ hi16	addis
			4 4 theBuff2 1+ lo16	ori
			1 0 fd hi16				addis
			1 1 fd lo16				ori
			3 0 1					lwz
			1 0 readCall hi16		addis
			1 1 readCall lo16		ori
			2 0 1					lwz
			9 2						mtspr
			20 0					bcctrl
			3 3 3					or.
			4 1 rot					bc		\ 0> until
				4 0 theBuff2 hi16		addis
				4 4 theBuff2 lo16		ori
				3 0 4					stb
	20 0 rot	bc		\ again
end-code
[then]

0 [if]
: writeThread \ high level equivalent of code in writeThread
	begin  writeArmed @
		if  fd @ theBuff2 1+ 1 write theBuff2 c!
			cr ." write returned " theBuff2 count .
			." data " c@ .
		then
	again ;
[else]
code writeThread
	here here here \ begins
		1 0 writeArmed hi16		addis
		1 1 writeArmed lo16		ori
		0 0 1					lwz
		0 0 0					or.
		12 2 rot				bc		\ 0<> until
			5 0 10 ( * )			addi
			4 0 theBuff2 1+ hi16	addis
			4 4 theBuff2 1+ lo16	ori
			1 0 fd hi16				addis
			1 1 fd lo16				ori
			3 0 1					lwz
			1 0 writeCall hi16		addis
			1 1 writeCall lo16		ori
			2 0 1					lwz
			9 2						mtspr
			20 0					bcctrl
			3 3 3					or.
			4 1 rot					bc		\ 0> until
				4 0 theBuff2 hi16		addis
				4 4 theBuff2 lo16		ori
				3 0 4					stb
	20 0 rot	bc		\ again
end-code
[then]

: fillBuff2 ( -- )   BASE @ >R DECIMAL
	10 ( * ) 0 do  i s>d <# #S #> drop c@ theBuff2 1+ i + c!
	loop  R> BASE ! ;
  fillBuff2

: startRead ( -- )
	fd @ readArmed @ 0= and if
		theReadThread 0 ['] readThread >code-address 0 pthread_create .
		1 readArmed !
	then
;

: startWrite ( -- )
	fd @ writeArmed @ 0= and if
		theWriteThread 0 ['] writeThread >code-address 0 pthread_create .
		1 writeArmed !
	then
;

: stopRead ( -- )   readArmed @ if  0 readArmed !
		theReadThread @ pthread_cancel
	else -1 then  .
;

: stopWrite ( -- )   writeArmed @ if  0 writeArmed !
		theWriteThread @ pthread_cancel
	else -1 then  .
;

TestSerial
: t ( -- )					\ toggle read thread
	readArmed @ if
		stopRead
	else
		startRead
	then
;

: ts ( -- )					\ toggle write thread
	writeArmed @ if
		stopWrite
	else
		startWrite
	then
;
forth definitions

[THEN]
