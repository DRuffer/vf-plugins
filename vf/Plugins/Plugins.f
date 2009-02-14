\ Plugins.f - VentureForth Plug in support

\ Every Plugin is assumed to define a constant that returns its version number.
\ The constant's name is assumed to be the name of the file, with its extension
\ replaced by "version".  This can be tested to be equal to or grater than the
\ version number that existed when the Plugin was written.  It is assumed that
\ they all are upward compatible.

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

[defined] Plugins.version 0= [IF]

6 constant Plugins.version

: checkPlugin ( plugin.version test.version -- )
    < abort" Tool is older than required.  Reinstall! " ;

v.VF +include" Plugins/Projects.f"  Projects.version 11 checkPlugin
v.VF +include" Plugins/LaTeX.f"  LaTeX.version 3 checkPlugin

: InstallingSection ( -- )   s" Installing VentureForth Tools" subSection
    s" \emph{Someday, we may have a plugin architecture like Eclipse.}" >fileLine
        fileCr
    s" http://www.eclipse.org" URL
        fileCr
    s" http://www.eclipse.org/articles/Article-Update/keeping-up-to-date.html" URL
        fileCr
    s" Until then, we can use Eclipse as a model" subSection
    s" \begin{itemize}" >fileLine
    s" \item They have many plugins, as we can hope to someday." >fileLine
    s" \item They originally used a zip model for updates" >fileLine
    s" \end{itemize}" >fileLine
    endSection fileCr
    s" Place the Plugins zip file" subSection
    s" Into the root of your VentureForth folder." >fileLine
    endSection fileCr
    s" Extract the contents" subSection
    s" If you double click the file in OS X" subSection
    s" You will get a directory containing the contents, which you will need" >fileLine
    s" to integrate into the T18 directories." >fileLine
    endSection fileCr
    s" Better to use unzip in the Terminal" subSection
    s" The \emph{unzip} command will integrate the files," >fileLine
    s" as needed, and create the necessary directories for you." >fileLine
    endSection endSection endSection ;

: ValidationSection ( -- )   s" Validating the Tools" subSection
    s" Each file in the Plugins directory contains a version number," >fileLine
    s" which has been modeled after the work done in The Forth Foundation" >fileLine
    s" Library by Dick van Oudheusden at:" >fileLine
    s" http://freshmeat.net/projects/ffl/" URL
        fileCr
    s" This gives each file the ability to make sure that it is only loaded" >fileLine
    s" once, and dependent applications the ability to check that their" >fileLine
    s" dependencies contain the features they require.  The version number" >fileLine
    s" is the file name, replacing the extension with 'version', and is" >fileLine
    s" incremented each time the file is changed." >fileLine
        fileCr
    s" The file can then load its dependencies, checking that they are," >fileLine
    s" at least, as new as when the Plugin was written.  The file can" >fileLine
    s" also skip loading itself if its version number already exists." >fileLine
    s" This creates a self-validating, reentrant load sequence." >fileLine
        fileCr
    s" If any file is older than required, the load process will abort," >fileLine
    s" with the following error message:" >fileLine
        fileCr
    s" \emph{Tool is older than required.  Reinstall!}" >fileLine
    endSection ;

variable allFiles   0 allFiles !
variable theFiles   allFiles theFiles !

: fileList ( -name- )   create  here theFiles !  0 ,
    does> ( -- addr )   dup theFiles ! ;

: addZip ( -- )   align theFiles @ <link  here 1 cells + ,link ;
: addFile ( -- )   align allFiles <link  here 3 cells + ,link  addZip ;

variable 'installedFiles   0 'installedFiles !

: FilesSection ( addr -- )   s" Installed Files" subSection
    'installedFiles @ ?dup if  execute
    else  s" \begin{itemize}" >fileLine
        begin  @link ?dup while  dup >r
            s" \item " >fileStr  1 cells + @link count >fileLine  r>
        repeat  s" \end{itemize}" >fileLine
    then  endSection ;

variable 'dependentFiles   0 'dependentFiles !

: InstallingPlugins ( addr -- )   s" Installing the " >command
    @link dup 1 cells + @link count +command
    s"  Package" +command  command> subSection
    InstallingSection fileCr
    FilesSection fileCr
    ValidationSection
    'dependentFiles @ ?dup if  fileCr
        s" File Dependencies" subSection
            execute  endSection
    then  endSection ;

: Installing.tex ( -- )   s" ../../vf/Plugins/doc/Installing" 2dup texArticle
    InstallingSection fileCr
    endTex ;

[THEN]
