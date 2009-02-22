\ LaTeX.f - LaTeX documentation support

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

v.VF +include" Plugins/links.f"  links.version 3 checkPlugin
v.VF +include" Plugins/Plugins.f"  Plugins.version 7 checkPlugin
v.VF +include" Plugins/Projects.f"  Projects.version 12 checkPlugin

[defined] LaTeX.version 0= [IF]

4 constant LaTeX.version

create command   256 allot

: >command ( str len -- )   command dup 256 erase place ;
: +command ( str len -- )   command append ;
: command> ( -- str len )   command count ;

: notYet ( -- )   [defined] ForGForth [IF]  exit  [ELSE]
        true abort" Not implemented yet!"
    [THEN] ;

 : sys ( str len -- )   notYet
         [defined] ForGForth [IF] system $? [THEN]
         abort" system failure" ;

: zipFiles ( addr -- )   notYet \ create archive of given list of files
    s" cd ../.. && zip " dup >r >command
    @link dup 1 cells + @link count +command        \ 1st string is archive name
    s"  " +command  command c@ >r
    begin  r@ command c!  @link ?dup while  dup >r  \ linked list of strings
            1 cells + @link count +command
            command> sys  r>
    repeat  r> r> 2drop ;

variable section   1 section !

: subSection ( str len -- )   section @ case \ variable nested sectioning control
        0 of  s" \part"  endof
        1 of  s" \chapter"  endof
        2 of  s" \section"  endof
        3 of  s" \subsection"  endof
        4 of  s" \subsubsection"  endof
        5 of  s" \paragraph"  endof
        6 of  s" \subparagraph"  endof
        abort" section nesting too deep!"
    endcase  >fileStr {file} fileCr fileCr
    1 section +! ;

: endSection ( -- )   -1 section +! ;

\ create UseURLs

: URL ( str len -- )   fileCr  [defined] UseURLs [if]
		s" \protect\url" >fileStr
	[then]  {file}  fileCr ;

: removeTex ( str len -- )   notYet
    s" rm -f " >command  ( str len ) +command
        command c@  s" .aux" +command  command> sys
    dup command c!  s" .log" +command  command> sys
    dup command c!  s" .tex" +command  command> sys
    dup command c!  s" .toc" +command  command> sys
    dup command c!  s" .dvi" +command  command> sys
        command c!  s" .pdf" +command  command> sys ;

: createTex ( str len -- )   2dup removeTex
    ( str len ) >command  s" .tex" +command  command> fileCreate ;

: beginTex ( -- )
    s" \usepackage{graphics}" >fileLine
[defined] UseURLs [if]
    s" \usepackage{url}" >fileLine
[then]
    s" \begin{document}" >fileLine
    fileCr ;

: texArticle ( str len -- )   createTex  2 section !
    s" \documentclass[english]{article}" >fileLine
    beginTex ;

: texBook ( str len -- )   createTex  1 section !
    s" \documentclass[openany]{book}" >fileLine
    beginTex ;

: endTex ( str len -- )   s" \end{document}" >fileLine  fileClose
    pathSeparator right-parse-string  s" cd " >command  +command
    s"  && pdflatex " +command  +command
    2 0 do  command> sys  loop ;

: texTitle ( str1 len1 str2 len2 -- )   s" \title" >fileStr {file} fileCr
    s" \author" >fileStr 2dup {file} fileCr fileCr  s" \maketitle" >fileLine fileCr
    s" Copyright (c) " >fileStr
        time&date nip nip nip nip nip 0 <# #S #> {file}
        fileSpace {file} fileCr fileCr
    s" \begin{itemize}" >fileLine
    s" \item Permission is hereby granted, free of charge, to any person obtaining a copy" >fileLine
    s" of this software and associated documentation files (the 'Software'), to deal" >fileLine
    s" in the Software without restriction, including without limitation the rights" >fileLine
    s" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell" >fileLine
    s" copies of the Software, and to permit persons to whom the Software is" >fileLine
    s" furnished to do so, subject to the following conditions:" >fileLine
        fileCr fileCr
    s" \item The above copyright notice and this permission notice shall be included in" >fileLine
    s" all copies or substantial portions of the Software." >fileLine
        fileCr fileCr
    s" \item THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR" >fileLine
    s" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY," >fileLine
    s" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE" >fileLine
    s" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER" >fileLine
    s" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM," >fileLine
    s" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN" >fileLine
    s" THE SOFTWARE." >fileLine
    s" \end{itemize}" >fileLine
    s" \tableofcontents{}" >fileLine fileCr ;
[THEN]
