" Vim plugin -- addon for AsNeeded
" File:         anplus.vim
" Created:      2009 May 22
" Last Change:  2009 Oct 19
" Rev Days:     11
" Author:	Andy Wokula <anwoku@yahoo.de>
" License:	Vim License, see :h license

" COMMANDS

" 
com! -bar -nargs=+ -complete=custom,s:FuncCompl ANfunc call s:Func(<q-args>)

" :edit a tag's scriptfile (command or function)
com! -bar -bang -nargs=1 -complete=custom,s:EditCompl ANedit call s:Edit(<q-bang>, <q-args>)

" :cd to one of the Asneeded directories
com! -bar -nargs=* -complete=custom,AN_PtagCompl ANcd call s:Cd(<q-args>)

" com! -nargs=+ ANselect call s:Select(<q-args>)

" stop checking certain ANtags file for changes all the time:
com! -bar -bang -nargs=* -complete=custom,AN_PtagCompl ANonce call s:Once(<bang>0, <f-args>)

com! -bar -nargs=1 -complete=custom,asneeded#ComplAN ANfeed call s:ComLoadFeed(<q-args>,expand("<lt>sfile>"))

" check out what :ANmakeTags would get from the current script file:
com! -bar ANscanCurFile echo asneeded#ScanFile(expand("%"), g:asneeded#scancfg)

" FUNCTIONS

func! s:FuncCompl(...) "{{{
    let funcnames = keys(asneeded#GetObj().jmp.func)
    call filter(funcnames, '!exists("*". v:val)')
    call sort(funcnames)
    call map(funcnames, 'v:val. "("')
    return join(funcnames, "\n")
endfunc "}}}
func! s:EditCompl(...) "{{{
    let ant = asneeded#GetObj()
    let cpllist = keys(ant.jmp.com)
	\ + map(keys(ant.jmp.func), 'v:val. "()"')
    return join(sort(cpllist), "\n")
endfunc "}}}
func! AN_PtagCompl(...) "{{{
    return join(asneeded#GetObj().ptags+["all"], "\n")
    " global function needed for input()
endfunc "}}}

func! s:Edit(bang, tagarg) "{{{
    let tagname = matchstr(a:tagarg, '^\u\w*')
    " XXX func jp:template()
    let ant = asneeded#GetObj()
    try
	if a:tagarg =~ '^\u\w*('
	    let [ptag, scriptname] = ant.jmp.func[tagname]
	else
	    let [ptag, scriptname] = ant.jmp.com[tagname]
	endif
	let tag_file = ant.sources[ptag].fname
    catch
	return
    endtry
    let script_file = simplify(fnamemodify(tag_file, ":h"). "/". scriptname)
    exec "edit".a:bang script_file
endfunc "}}}

func! s:Cd(ptagarg) "{{{
    let ant = asneeded#GetObj()
    if a:ptagarg == ""
	for ptag in ant.ptags
	    let dir = fnamemodify(ant.sources[ptag].fname, ":p:~:h")
	    echo printf("%10s : %s", ptag, dir)
	endfor
	let ptag = input(":ANcd ", "", "custom,AN_PtagCompl")
    else
	let ptag = a:ptagarg
    endif
    if ptag == ""
	return
    endif
    if has_key(ant.sources, ptag)
	let dir = fnamemodify(ant.sources[ptag].fname, ":h")
	exec "cd" dir
    else
	echo "\n"
	echoerr "ANcd: not a ptag:" ptag
    endif
endfunc "}}}

func! s:Once(bang, ...) "{{{
    let ant = asneeded#GetObj()
    if a:bang
	for ptag in a:0>=1 ? a:000 : ant.ptags
	    try
		let src = ant.sources[ptag]
		if src.tstamp == 0
		    let src.tstamp = 1
		endif
	    catch
		echoerr "ANonce: not a ptag:" ptag
	    endtry
	endfor
    elseif a:0 >= 1
	for ptag in a:1==?"all" ? ant.ptags : a:000
	    try
		let src = ant.sources[ptag]
		let src.tstamp = 0
	    catch
		echoerr "ANonce: not a ptag:" ptag
	    endtry
	endfor
    else
	echo "ANtags files that will not be checked again for changes:"
	let oex = 0
	for ptag in ant.ptags
	    let src = ant.sources[ptag]
	    if src.tstamp == 0
		let tag_file = fnamemodify(src.fname, ":p:~")
		echo printf("%10s : %s", ptag, tag_file)
		let oex = 1
	    endif
	endfor
	if !oex
	    echo "NONE"
	endif
    endif
endfunc "}}}

func! s:Func(tagarg) "{{{
    let funcname = matchstr(a:tagarg, '^[^()]*')
    call asneeded#FuncLoad(funcname)
    if !exists("*".funcname)
	echoerr "ANfunc: don't know a script defining" funcname."()"
    endif
endfunc "}}}

func! s:ComLoadFeed(cmdname, sfile) "{{{
    try
	call asneeded#ComLoad(a:cmdname)
	if a:sfile == ""
	    " :ANfeed was executed at the Cmdline (not from a script)
	    call feedkeys(":". a:cmdname, "n")
	endif
    endtry
endfunc "}}}

"" func! s:Select(tagarg) "{{{
""     let tagname = matchstr(a:tagarg, '^\u\w*')
""     let ant = asneeded#GetObj()
""     " 1 AN1 D:\home\vimfiles\asneeded\anplus.vim
""     "	    :ANcd :ANedit AN_CdCompl()
""     " 2 AN1 ...
""     " Choice number (<Enter> cancels):
"" endfunc "}}}

" vim:set fdm=marker:
