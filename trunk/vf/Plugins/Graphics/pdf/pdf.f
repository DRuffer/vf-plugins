\ pdf.f - Support for Portable Document Format (PDF)

\ Documentation can be found in the PDF Reference, sixth edition,
\									Version 1.7, November 2006

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

[defined] pdf.version 0= [IF]

3 constant pdf.version

612 value pdfWidth
792 value pdfHeight

0 value viewWidth
0 value viewHeight

1 value pdfObject		\ number of next pdfObject to be allocated
variable pdfObjects		\ linked list of pdfObject locations

2variable pdfStream		\ holds size of stream
2variable pdfLastXref	\ holds location of last cross-reference section

create pdfXratio   forth 2 cells allot host    1 1 pdfXratio 2!
create pdfYratio   forth 2 cells allot host   20 1 pdfYratio 2!

: pdfXscale ( n -- n' )   pdfXratio 2@ */ ;
: pdfYscale ( n -- n' )   pdfYratio 2@ */ ;

: pdfHeader ( -- )   s" %PDF-1.4" >fileLine ;

: pdf*1000. ( n*1000 -- )   dup abs s>d <# # # # [char] . hold #s rot sign #> >fileStr ;
: pdf*100. ( n*100 -- )   dup abs s>d <# # # [char] . hold #s rot sign #> >fileStr ;
: pdf*10. ( n*10 -- )   dup abs s>d <# # [char] . hold #s rot sign #> >fileStr ;
: pdfD.10 ( d -- )   <# 10 0 do # loop #> >fileStr ;
: pdfD. ( d -- )   dup -rot dabs <# #s rot sign #> >fileStr ;
: pdfN.5 ( n -- )   s>d <# 5 0 do # loop #> >fileStr ;
: pdfN. ( n -- )   s>d pdfD. ;

: <<pdfDict ( str len -- )   s" << " >fileStr >fileStr ;
: pdfDict>> ( -- )   s" >>" >fileStr ;

: <pdfObj ( -- )   pdfObjects <link  filePosition , ,
	pdfObject dup 1+ to pdfObject  pdfN. fileSpace 0 pdfN. s"  obj" >fileLine ;

: endObj> ( -- )   fileCr  s" endobj" >fileLine  fileCr ;

: pdfCatalog ( -- )   <pdfObj
	fileIndent  s" /Type /Catalog"  <<pdfDict  fileCr
		2 fileIndents  s" /Outlines 2 0 R" >fileLine
		2 fileIndents  s" /Pages 3 0 R" >fileLine
	fileIndent  pdfDict>>
	endObj> ;

: pdfOutlines ( -- )   <pdfObj
	fileIndent  s" /Type /Outlines" <<pdfDict  fileCr
		2 fileIndents  s" /Count 0" >fileLine
	fileIndent  pdfDict>>
	endObj> ;

: pdfPages ( -- )   <pdfObj
	fileIndent  s" /Type /Pages"  <<pdfDict  fileCr
		2 fileIndents  s" /Kids [ 4 0 R ]" >fileLine
		2 fileIndents  s" /Count 1" >fileLine
	fileIndent  pdfDict>>
	endObj> ;

: pdfMediaBox ( -- )   s" /MediaBox [ " >fileStr
	0 pdfN. fileSpace  0 pdfN. fileSpace
	pdfWidth pdfN. fileSpace
	pdfHeight pdfN.
	s"  ]" >fileLine ;

: pdfPage ( rot -- )   <pdfObj
	fileIndent  s" /Type /Page"  <<pdfDict  fileCr
		2 fileIndents  s" /Parent 3 0 R" >fileLine
		2 fileIndents  pdfMediaBox
		2 fileIndents  s" /Contents 5 0 R" >fileLine
		2 fileIndents  s" /Rotate " >fileStr pdfN. fileCr
		2 fileIndents  s" /Resources " >fileLine
			3 fileIndents  s" /ProcSet 7 0 R " <<pdfDict fileCr
			4 fileIndents  s" /Font " >fileStr
				s" /F1 8 0 R " <<pdfDict
				pdfDict>> fileCr
			3 fileIndents  pdfDict>> fileCr
	fileIndent  pdfDict>> 
	endObj> ;

: <pdfStream ( -- )   <pdfObj
	fileIndent  s" /Length 6 0 R" <<pdfDict fileSpace pdfDict>>
	fileCr  s" stream" >fileLine
	filePosition pdfStream 2! ;

: pdfStream> ( -- )   filePosition pdfStream 2@ d- pdfStream 2!
	fileCr  s" endstream" >fileStr  endObj> ;

: pdfLength ( -- )   <pdfObj
	fileIndent  pdfStream 2@ pdfD.
	endObj> ;

: pdfProcSet ( -- )   <pdfObj
	fileIndent  s" [/PDF /Text]" >fileStr
	endObj> ;

: pdfFont ( -- )   <pdfObj
	fileIndent  s" /Type /Font" <<pdfDict fileCr
		2 fileIndents  s" /Subtype /Type1" >fileLine
		2 fileIndents  s" /BaseFont /Courier" >fileLine
	fileIndent  pdfDict>>
	endObj> ;

: pdfXref ( -- )   filePosition pdfLastXref 2!
	s" xref" >fileLine  0 pdfN.  fileSpace  pdfObject pdfN. fileCr
	0.0 pdfD.10 fileSpace 65535 pdfN.5 s"  f" >fileLine
	pdfObjects  begin  @link ?dup while
		dup cell+ 2@ pdfD.10 fileSpace 0 pdfN.5 s"  n" >fileLine
	repeat  fileCr ;

: pdfTrailer ( -- )   s" trailer" >fileLine
	fileIndent  s" /Size " <<pdfDict  pdfObject pdfN. fileCr
		2 fileIndents  s" /Root 1 0 R" >fileLine
	fileIndent  pdfDict>>
	fileCr  s" startxref" >fileLine
	pdfLastXref 2@ pdfD. fileCr
	s" %%EOF" >fileLine ;

: <cm*10> ( a b c d e f -- )   fileIndent
	2rot swap pdf*10. fileSpace  pdf*10. fileSpace
	2swap swap pdf*10. fileSpace  pdf*10. fileSpace
	swap pdf*10. fileSpace  pdf*10. fileSpace
	s" cm" >fileLine ;

: <cm*1000> ( a b c d e f -- )   fileIndent
	2rot swap pdf*1000. fileSpace  pdf*1000. fileSpace
	2swap swap pdf*1000. fileSpace  pdf*1000. fileSpace
	swap pdf*1000. fileSpace  pdf*1000. fileSpace
	s" cm" >fileLine ;

: rot90  ( -- )   0 -10 10 0 0 0 <cm*10> ;		\ rotate 90 degrees
: rot45  ( -- )   7  -7  7 7 0 0 <cm*10> ;		\ rotate 45 degrees
: rot-45 ( -- )   7   7 -7 7 0 0 <cm*10> ;		\ rotate -45 degrees

: <q ( -- )   fileIndent  s" q" >fileLine ;
: Q> ( -- )   fileIndent  s" Q" >fileLine ;
: <S> ( -- )   s" S" >fileLine ;
: <b> ( -- )   s" b" >fileLine ;

: <re> ( x*10 y*10 width*10 height*10 -- )   fileIndent
	2swap swap pdf*10. fileSpace  viewHeight swap - pdf*10. fileSpace
	swap pdf*10. fileSpace  negate pdf*10.
	s"  re " >fileStr ;

: <rgf> ( r*100 g*100 b*100 -- )   fileIndent
	rot pdf*100. fileSpace  swap pdf*100. fileSpace
	pdf*100.  s"  rg" >fileLine ;

: <RGS> ( r*100 g*100 b*100 -- )   fileIndent
	rot pdf*100. fileSpace  swap pdf*100. fileSpace
	pdf*100. s"  RG" >fileLine ;

: <BT> ( -- )   fileIndent  s" BT " >fileStr ;
: <ET> ( -- )   s" ET" >fileLine ;

: <Tf> ( -- )   s" /F1 12 Tf " >fileStr ;
: <Td> ( x*10 y*10 -- )   swap pdf*10. fileSpace
	viewHeight swap - pdf*10.  s"  Td " >fileStr ;
: <Tj> ( str len -- )   s" (" >fileStr  >fileStr  s" ) Tj " >fileStr ;

: <m> ( x*10 y*10 -- )   fileIndent  swap pdf*10. fileSpace
	viewHeight swap - pdf*10. fileSpace  s" m " >fileStr ;
: <l> ( x*10 y*10 -- )   swap pdf*10. fileSpace
	viewHeight swap - pdf*10. fileSpace  s" l " >fileStr  <S> ;

: <w> ( line_width*10 -- )   fileIndent  pdf*10. s"  w" >fileLine ;

: <d> ( dashes -- )   fileIndent  s" [ " >fileStr
	pdf*10.  s"  ] 0 d" >fileLine ;

[THEN]
