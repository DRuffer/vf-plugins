\ FileNames.f - Report dependent file locations

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

FORTH DEFINITIONS

v.VF +include" Plugins/File.fth"  File.version 3 checkPlugin
v.VF +include" Plugins/idForth.f"  idForth.version 5 checkPlugin
v.VF +include" Plugins/Projects.f"  Projects.version 11 checkPlugin

[defined] FileNames.version 0= [IF]

3 constant FileNames.version

[defined] ForGForth [IF] \ Only supports gforth at this point

	: FileNameLog ( -- str len )  s" FileNames.log" ;

FileNameLog R/W CREATE-FILE THROW  CLOSE-FILE THROW     \ clear the file

: logFileName ( str len -- )
    FileNameLog R/W OPEN-FILE if  drop
        FileNameLog R/W CREATE-FILE abort" Can't create FileNameLog file" >r
    else  dup >r FILE-SIZE abort" Can't get FileNameLog file size"
        r@ REPOSITION-FILE abort" Can't find end of FileNameLog file"
    then  r@ WRITE-LINE abort" Can't write to FileNameLog file"
    r> CLOSE-FILE abort" Can't close FileNameLog file" ;

[defined] 'logFileName [IF] ' logFileName 'logFileName ! [THEN]

0 [IF] \ These should be reloaded if they are actual requirements
    s" ./compatibility.f" logFileName
    s" ./FileNames.f" logFileName
    s" ./Projects.f" logFileName
    s" ./Plugins.f" logFileName
    s" ./idForth.f" logFileName
    s" ./numbers.f" logFileName
    s" ./strings.f" logFileName
    s" ./paths.f" logFileName
[THEN]

files  file FileNames.dbf

\ Define the FileNames index fields:
4 ( LINK )  252 BYTES FileNames  DROP

( Bytes  records  origin            name )
    256      200       0 BLOCK-DATA FileNamesData

\ Initialize the files if there is nothing in them.
: /FileNames ( -- )   files FileNames.dbf
    FILE-HANDLE @ 0= IF
        s" FileNames.dbf" >FILE
    THEN  FileNamesData INITIALIZE ;

[R                           Dependent File Names\File Name]
   CONSTANT FileNamesTitle

0 value CommonPath

: .FileName ( -- )   FileNames  swap CommonPath -  swap CommonPath +  ?B ;

: findCommonPath ( -- )   FileNames.dbf
    FileNamesData 1 READ  FileNames OVER TO CommonPath B@
    FileNamesData RECORDS ?DO
        I READ  FileNames ADDRESS FILE-PAD
        ROT DROP CommonPath 0 ?DO
            OVER I + C@  OVER I + C@ = IF
                I 1+ TO CommonPath
            ELSE  LEAVE  THEN
        LOOP  2DROP
    LOOP ;

: .FileNames ( -- )   FileNames.dbf
    FileNamesTitle LAYOUT  +L  findCommonPath
    FileNamesData RECORDS ?DO
        I READ  .FileName  +L
    LOOP ;

: belowPWD ( str len -- )                       \ below current path
    s" PWD" getenv DUP >R  FILE-PAD SWAP MOVE
    pathSeparator FILE-PAD R@ + C!
    FILE-PAD R> 1+ + SWAP MOVE ;

: abovePWD ( str len -- )                       \ above current path
    3 /STRING  s" PWD" getenv
    pathSeparator right-parse-string
    DUP >R  FILE-PAD SWAP MOVE  2DROP
    pathSeparator FILE-PAD R@ + C!
    FILE-PAD R> 1+ + SWAP MOVE ;

: inPlugins ( str len -- )                      \ in the Plugins folder
    2 /STRING  s" PWD" getenv
    pathSeparator right-parse-string
    DUP >R  FILE-PAD SWAP MOVE  2DROP
    pathSeparator FILE-PAD R@ + C!
    s" Plugins/" FILE-PAD R@ 1+ + SWAP MOVE
    FILE-PAD R> 9 + + SWAP MOVE ;

: removeDots ( -- )
    FILE-PAD #TB S" .." SEARCH IF
        3 - >R DUP 3 + SWAP R> MOVE             \ 1st ones can just be removed
    ELSE  2DROP  THEN
    FILE-PAD #TB S" .." SEARCH IF
        3 - >R DUP 3 + SWAP  BEGIN              \ 2nd needs to remove a folder
            1- DUP 1- C@ pathSeparator =
        UNTIL  R> MOVE
    ELSE  2DROP  THEN
    BEGIN  FILE-PAD #TB S" ./" SEARCH WHILE
        2 - >R DUP 2 + SWAP R> MOVE             \ these can also just be removed
    REPEAT  2DROP ;

: addFileName ( str len -- )   FileNames.dbf
    FILE-PAD #TB BLANK  OVER C@ [CHAR] / = IF   \ contains full path
        FILE-PAD SWAP MOVE
    ELSE  OVER S" .." ROT OVER COMPARE IF
            OVER S" ./" ROT OVER COMPARE IF
                belowPWD  ELSE  inPlugins
            THEN  ELSE  abovePWD
        THEN  removeDots
    THEN  FileNames 2DUP S! -BINARY IF  +ORDERED
    ELSE  ORDERED RELEASE
    THEN ;

: addFileNames ( -- )   /FileNames
    FileNameLog R/W OPEN-FILE THROW >R
    BEGIN  HERE 256 R@ READ-LINE THROW  WHILE
        HERE SWAP addFileName
    REPEAT  DROP  R> CLOSE-FILE THROW ;

variable endPath      0 endPath !
variable nestedPath   0 nestedPath !
variable unnestPath   0 unnestPath !
variable indentPath   0 indentPath !

: @FileName ( -- str len )   FileNames B@
    FILE-PAD #TB -TRAILING  CommonPath /STRING ;

: newPath ( src len a -- src len flag )   2 CELLS + COUNT 2OVER COMPARE ;

: unnestPaths ( parent -- )   DUP @ ?DUP IF
        RECURSE  FREE THROW  1 unnestPath +!
    ELSE  FREE THROW  THEN ;

: nestPaths ( src len -- a )   DUP 2 CELLS + 1+ DUP ALLOCATE THROW
    DUP >R  SWAP ERASE  R@ 2 CELLS + place  R> ;

: doublyLinked ( child parent -- )   2DUP !  SWAP CELL+ ! ;

: closePath ( -- )   unnestPath @ 0 ?DO
        [ forth ] s" \-" >fileStr files
    LOOP  s" \\" >fileLine ;

: typePath ( len1 str2 len2 -- len1 )   endPath @ if
          closePath  indentPath @ fileSpaces
    then  false endPath !  [ forth ] >fileStr dup if
        s" \=\+\\" >fileStr files
    then ;

: texFileName ( str len -- )                        \ S: remaining path
    0 unnestPath !  0 indentPath !  nestedPath >R   \ R: address of parent
    BEGIN  pathSeparator left-parse-string
        ?DUP WHILE  R@ @ ?DUP IF
            newPath IF
                R@ @ unnestPaths  2DUP nestPaths  R@ doublyLinked  typePath
            ELSE  6 + indentPath +!  DROP  THEN
        ELSE  2DUP nestPaths  R@ doublyLinked  typePath
        THEN  R> @ >R                               \ nest into path
    REPEAT  R> 2DROP 2DROP ;

: texFileNames ( -- )   FileNames.dbf  findCommonPath
    s" \begin{tabbing}" >fileLine
    false endPath !  FileNamesData RECORDS ?DO
        I READ  @FileName texFileName  true endPath !
    LOOP  s"  " texFileName
    s" \end{tabbing}" >fileLine ;

: installedFiles ( -- )   /FileNames
    begin  @link ?dup while
        dup >r  1 cells + @link count addFileName  r>
    repeat  texFileNames ;
' installedFiles 'installedFiles !

: dependentFiles ( -- )   addFileNames texFileNames ;
' dependentFiles 'dependentFiles !

FORTH DEFINITIONS

[THEN] [THEN]
