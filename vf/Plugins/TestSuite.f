\ TestSuite.f  documentation for the TestSuite plugin

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

fileList TestSuiteFiles   addZip ," vf/Plugins/TestSuite.zip"
    addFile ," vf/Plugins/doc/TestSuite.pdf"
    addFile ," vf/Plugins/TestSuite.f"
    addFile ," vf/Plugins/LaTeX.f"
    addFile ," vf/Plugins/Plugins.f"
    addFile ," vf/Plugins/Projects.f"
    addFile ," vf/Plugins/comments.f"
    addFile ," vf/Plugins/idForth.f"
    addFile ," vf/Plugins/links.f"
    addFile ," vf/Plugins/numbers.f"
    addFile ," vf/Plugins/strings.f"
    addFile ," vf/Plugins/testSim.f"
    addFile ," vf/Plugins/xUnit.f"
    addFile ," vf/gforth.fs"
    addFile ," projects/FdCheck/FdCheck.vf"
    addFile ," projects/FdCheck/BlinkLED.vf"
    addFile ," projects/FdCheck/Echo.vf"
    addFile ," projects/FdCheck/USBCom.f"
    addFile ," projects/FdCheck/check-pass.vf"
    addFile ," projects/FdCheck/check-receive.vf"
    addFile ," projects/FdCheck/check-report.vf"
    addFile ," projects/FdCheck/checksum.vf"
    addFile ," projects/FdCheck/FloorPlan.pdf"
    addFile ," projects/FdCheck/project.bat"
    addFile ," projects/FdCheck/project.vfp"

: TestSuite.zip ( -- ) \ create archive of TestSuite plug in
    TestSuiteFiles zipFiles ;

: TestSuiteHelp ( -- )
    s" The following words are the user interface for the Test Suite.  The 1st two" >fileLine
    s" words are used within parenthesis, so they do not need to be removed if this" >fileLine
    s" plug-in is not loaded." >fileLine
    s" \begin{description}" >fileLine

	s" \item[\texttt{n .?.}]Puts a 'fence post' at this location in the target image" >fileLine
    s" that will display the data stack when the simulator steps over that location." >fileLine

    s" \item[\texttt{assert: ... ;}]Puts a test at this location in the target image that will be" >fileLine
    s" executed when the simulator steps over that location.  The words that are" >fileLine
    s" compiled within this definition use the host search order and must return a" >fileLine
    s" true or a false flag to indicate test success or failure.  Two entries are" >fileLine
    s" placed into the TestSuite.log file for each of these tests; one for the setup" >fileLine
    s" of the test and the other for the run of the test code.  There is no need for" >fileLine
    s" a tear down step with these tests." >fileLine

    s" Both of these words attempt to match the compile time address and slot number" >fileLine
    s" with the run time locations that the simulator will encounter.  This is not" >fileLine
    s" always possible and you may have to move it to a different location before the" >fileLine
    s" matching logic works properly." >fileLine

    s" \item[\texttt{TestAssertions}]is the word that attempts to match the compile time location of" >fileLine
    s" each of the above words with the current location in the simulator.  This" >fileLine
    s" works best when it is executed within the simulator's step logic.  However," >fileLine
    s" that requires a change to the definition of step that is described when" >fileLine
    s" testSim is loaded and the change is not found.  Someday, someone might be able" >fileLine
    s" to figure out why, but I have not been bothered by this modification.  I have" >fileLine
    s" made the code work without it, but you will likely only be able to trigger" >fileLine
    s" your tests at the beginning of slot 0." >fileLine

    s" \item[\texttt{simUnit: name-XX-XXX}]is not used in parenthesis, but is useful to give a name" >fileLine
    s" to the entries placed in the TestSuite.log file.  The test setup phase" >fileLine
    s" replaces the X's with the node number and the address/slot position.  The" >fileLine
    s" TestSuite.log file is not cleared automatically, but can be deleted manually" >fileLine
    s" to prevent it from becoming too large." >fileLine

    s" \item[\texttt{n goes}]runs the simulator until \begin{bf}FinishTests\end{bf} has been" >fileLine
    s" executed (within an assert test) n times or a key is pressed." >fileLine

    s" \item[\texttt{continue}]resumes running the simulator after a key has been pressed." >fileLine

    s" \item[\texttt{FinishTests}]decrements the test counter that was passed to goes." >fileLine

	s" \item[\texttt{autoTerminate}]aborts if the test \begin{bf}errorCount\end{bf} is" >fileLine
	s"  greater than 0.  Normally, \begin{bf}TestAssertions\end{bf} aborts as soon as if" >fileLine
	s" finds an error, but you can comment out that line and the error count will be" >fileLine
	s" accumulated until \begin{bf}FinishTests\end{bf} is executed.  Then you would need" >fileLine
    s" to abort so your compiler exits, like gforth normally does." >fileLine
	
    s" \item[\texttt{summary}]displays how many tests have run and how many failed." >fileLine
    s" \end{description}" >fileLine ;

: TestSuiteHistory ( -- )   s" Test Suite Historical Background" subSection
    s" Why would you want to use this stuff?" subSection
    s" Over the past 30 years I have simplified my debugging tools down to one word" >fileLine
    s" that I call a 'fence post'.  For many years, it looked like this" >fileLine
	s" \verb|<?>|, which almost looks like the top of a fence post," >fileLine
	s" but since the \verb|<| and \verb|>| characters" >fileLine
    s" are not part of the colorForth character set, I changed it to \begin{bf}.?.\end{bf}" >fileLine
    s" The word itself has taken on many forms, but in the simplest form, it is defined as:" >fileLine
        fileCr
    s" \begin{verbatim}" >fileLine
	s\" : .?. ( n -- )   cr .s drop .\" .?. \" ;" >fileLine
    s" \end{verbatim}" >fileLine
        fileCr
    s" This allows me to sprinkle these words around the code that I am debugging to" >fileLine
    s" 'fence in' the problem.  The number that it takes allows me to distinguish" >fileLine
    s" between all of them, since I have had cases where quite a few (hundreds) are" >fileLine
    s" needed to isolate a problem.  This has served me well over the years and I" >fileLine
    s" have brought them into everything I work on in Forth." >fileLine
        fileCr
    s" However, bringing this tool into my work in VentureForth proved to be a little" >fileLine
    s" more difficult.  First, the lack of resources within the chip requires that" >fileLine
    s" the tool be implemented within the simulation environment.  Second, the tool" >fileLine
    s" must record the position within the target code without modifying the location" >fileLine
    s" or size of the target code itself.  This proved to be a very difficult task." >fileLine
        fileCr
    s" Additionally, it was desirable to bring in some of the Agile techniques into" >fileLine
    s" our development process.  Test Driven Development (TDD) allows you to define" >fileLine
    s" your development goals in terms of Unit Tests and to know when you have" >fileLine
    s" accomplished each goal.  Continuous Integration (CI) allows you to maintain" >fileLine
    s" those tests in a process that can be run whenever the code is changed." >fileLine
    s" Letting you know quickly that the goals you have accomplished can still be" >fileLine
    s" relied on.  The only difficulty was implementing these techniques within" >fileLine
    s" VentureForth." >fileLine
        fileCr
    s" I started by reading Kent Beck's 'Test-Driven Development by Example' and" >fileLine
    s" implementing his concepts in Forth.  It is recommended reading for anyone" >fileLine
    s" interested in how it works.  Then came the job of integrating this into the" >fileLine
    s" VentureForth simulator.  This has been a problem from the beginning, as I have" >fileLine
    s" already mentioned, and it is not perfect today, but it has proven to be good" >fileLine
    s" enough to work with.  We integrated simulations of our applications with" >fileLine
    s" Zutubi's Pulse and every check in to our source repository generated an email" >fileLine
    s" to let me know that our tests passed." >fileLine
        fileCr
    s" This got us reliable target code, but when we started putting it on actual" >fileLine
    s" target hardware, our efforts were still frustrated by problems.  First, the" >fileLine
    s" targets didn't always work right.  We started with FPGA simulations of the" >fileLine
    s" SEAforth chips, which failed unpredictably as we pushed them faster and added" >fileLine
    s" more nodes.  When we received the 1st prototype chips, this problem became even" >fileLine
    s" more extreme.  Second, the target delivery mechanisms were not always reliable" >fileLine
    s" as we developed various techniques." >fileLine
        fileCr
    s" To help us distinguish between target and algorithm problems, I developed a" >fileLine
    s" means for the target to tell us if the compiled code was delivered reliably" >fileLine
    s" and, in effect, to tell us if the target itself was working reliably.  I" >fileLine
    s" generated a checksum at compile time, checked it in the target and delivered" >fileLine
    s" the results to a feedback mechanism.  On the FPGA, we had the entire address" >fileLine
    s" space of each node to work with and an LED display to report the results on." >fileLine
    s" Now, as I ported this code onto the FORTHdrive, I came to appreciate what a" >fileLine
    s" luxury this was." >fileLine
        fileCr
    s" The example application that is included with this plug-in shows the cost of" >fileLine
    s" this code.  The basic checksum algorithm takes 30% of the address space and" >fileLine
    s" the result passing takes up to 12% more.  The reporting used to fit in 1 node," >fileLine
    s" but here it takes 4 nodes to get the detailed results back to the host and" >fileLine
    s" provide visual feedback on an LED.  That puts this technique way over the" >fileLine
    s" limit of acceptable overhead.  It gives me a 'warm and fuzzy' feeling that my" >fileLine
    s" chip is working, but I'm not sure if it has any other purpose." >fileLine
        fileCr
    s" The same can be said for all of the tools in this plug-in.  They are familiar" >fileLine
    s" to me, so I continue to use them.  However, modern TDD is not a common way of" >fileLine
    s" thinking for most Forth programmers, and CI doesn't make a lot of sense in the" >fileLine
    s" 'Lone Wolf' environment of many Forth shops.  Still, I am publishing these" >fileLine
    s" tools with the hope that others will find a way to use them.  When used" >fileLine
    s" appropriately, they can be very beneficial." >fileLine
    endSection endSection ;

: includeTestSuite ( caption.len file.len label.len -- )
    s" \begin{figure}[b]" >fileLine 2>r
    s" \begin{picture}(200,100)(0,0)" >fileLine
    s" \put(-10,-50){\resizebox{14 cm}{!}{\includegraphics{" >fileStr
        >fileStr  s" }}}" >fileLine
    s" \end{picture}" >fileLine
    s" \caption{{\em " >fileStr  >fileStr  s" }}" >fileLine
    s" \label{" >fileStr 2r> >fileStr s" }" >fileLine
    s" \end{figure}" >fileLine
    s" \newpage" >fileLine ;

: TestSuiteExample ( -- )   s" Test Suite Example" subSection
    s" \begin{tiny}" >fileLine
    s" \begin{verbatim}" >fileLine
    s\" v.VF +include\" Plugins/testSim.f\"  testSim.version 2 checkPlugin" >fileLine
        fileCr
    s" -warning" >fileLine
    s" [defined] TestCase [IF] [ simUnit: checksum-XX-XXX ( -- method ) ] [THEN]" >fileLine
    s" +warning" >fileLine
        fileCr
    s"     checksum ( 1 .?. )" >fileLine
        fileCr
    s"     ( assert: t @ 0= ; )" >fileLine
        fileCr
    s"    | ( assert: FinishTests ; )" >fileLine
        fileCr
    s" cr .( Running simulation testing... ) cr" >fileLine
    s" 1 goes decimal cr summary cr" >fileLine
    s" \end{verbatim}" >fileLine
    s" \end{tiny}" >fileLine
    s" The example application's Floor Plan"
	s" ../../../projects/FdCheck/FloorPlan"
	s" figPlan" includeTestSuite
    endSection ;


: TestSuiteOutput ( -- )   s" Test Suite Output" subSection
    s" \begin{small}" >fileLine
    s" \begin{verbatim}" >fileLine
    s" FdCheck" >fileLine
    s" Using gforth version 0.7.0-20081226" >fileLine
	    fileCr
    s" Compiling ROM 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23" >fileLine
    s" Compiling RAM 18 19 20 21 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 22 23" >fileLine
    s" Creating library file: /.gforth/libcc-tmp/.libs/gforth_c_7FCD340C.dll.a" >fileLine
	    fileCr
    s" Using FORTHdrive PhysicalDrive1" >fileLine
    s" 000 LAL8 3FFFF" >fileLine
    s" 001 ALD8 0003F" >fileLine
    s" 002 ALAK 00000" >fileLine
    s" 003 ALAK 00000" >fileLine
    s" Running simulation testing..." >fileLine
        fileCr
    s"      0 15555 15555 15555 15555 15555 15555 15555     0    17 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0    11 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0     B 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0     5 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0     D 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0     7 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0     E 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0     1 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0     8 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0     F 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0    16 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0     0 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0     2 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0     9 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0    10 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0     3 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0     A 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0     4 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0     C 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0     6 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0    15 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0    12 1 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555 15555 15555     0    14 1 .?." >fileLine
    s"      0     0 15555 15555 15555 15555 15555 1F9FF     0    13 1 .?." >fileLine
    s"  15555 15555 15555 15555 15555 15555     0    12     C     C 2 .?." >fileLine
    s"      C 15555 15555 15555 15555 15555     0    12     D     C 2 .?." >fileLine
    s"      D 15555 15555 15555 15555 15555     0    12     E     C 2 .?." >fileLine
    s"      E 15555 15555 15555 15555 15555     0    12     F     C 2 .?." >fileLine
    s"      F 15555 15555 15555 15555 15555     0    12    10     C 2 .?." >fileLine
    s"     10 15555 15555 15555 15555 15555     0    12    11     C 2 .?." >fileLine
    s"     11 15555 15555 15555 15555 15555     0    12     6     C 2 .?." >fileLine
    s"      6 15555 15555 15555 15555 15555     0    12     7     C 2 .?." >fileLine
    s"      7 15555 15555 15555 15555 15555     0    12     8     C 2 .?." >fileLine
    s"      8 15555 15555 15555 15555 15555     0    12     9     C 2 .?." >fileLine
    s"      9 15555 15555 15555 15555 15555     0    12     A     C 2 .?." >fileLine
    s"      A 15555 15555 15555 15555 15555     0    12     B     C 2 .?." >fileLine
    s"      B 15555 15555 15555 15555 15555     0    12     0     C 2 .?." >fileLine
    s"      0 15555 15555 15555 15555 15555     0    12     1     C 2 .?." >fileLine
    s"      1 15555 15555 15555 15555 15555     0    12     2     C 2 .?." >fileLine
    s"      2 15555 15555 15555 15555 15555     0    12     3     C 2 .?." >fileLine
    s"      3 15555 15555 15555 15555 15555     0    12     4     C 2 .?." >fileLine
    s"      4 15555 15555 15555 15555 15555     0    12     5     C 2 .?." >fileLine
    s"      5 15555 15555 15555 15555 15555     0    12    13     C 2 .?." >fileLine
    s"      1 15555 15555 15555 15555 15555     0    12    14     C 2 .?." >fileLine
    s"      2 15555 15555 15555 15555 15555     0    12    15     C 2 .?." >fileLine
    s"      3 15555 15555 15555 15555 15555     0    12    16     C 2 .?." >fileLine
    s"      4 15555 15555 15555 15555 15555     0    12    17     C 2 .?." >fileLine
    s"     12     5 15555 15555 15555 15555 15555     0    12     C 2 .?." >fileLine
    s"      0     0     5 15555 15555 15555 15555 15555     0     0 3 .?." >fileLine
    s"      0     0     5 15555 15555 15555 15555 15555     0     0 3 .?." >fileLine
    s"      0     0     5 15555 15555 15555 15555 15555     0    3F 3 .?." >fileLine
    s"      0     0     5 15555 15555 15555 15555 15555     0 3FFFF 3 .?." >fileLine
    s" 25 run, 0 failed" >fileLine
    s" \end{verbatim}" >fileLine
    s" \end{small}" >fileLine
    endSection ;


: TestSuite.tex ( -- )   v.VF pad place s" Plugins/doc/TestSuite" pad append
    pad count 2dup texBook  s" Dennis Ruffer" s" Test Suite" texTitle
    TestSuiteHistory fileCr
    TestSuiteFiles InstallingPlugins fileCr
    ProjectArtifacts fileCr
    s" Test Suite User Interface" subSection
        TestSuiteHelp endSection fileCr
    TestSuiteExample fileCr
    TestSuiteOutput fileCr
    endTex ;
