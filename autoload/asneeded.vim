" autoload script - main
" File:         asneeded.vim
" Created:      2009 Apr 19
" Last Change:  2009 Oct 19
" Rev Days:     37
" Author:	Andy Wokula <anwoku@yahoo.de>
" License:	Vim License, see :h license

" Customization:
" Variables: {{{
if !exists('g:asneeded_path')
    let g:asneeded_path = 'AsNeeded'
    " DrChip's default folder
endif

if !exists('g:asneeded_func_ignpat')
    let g:asneeded_func_ignpat = '^T\%[ag]list_'
endif

" Scan Config (Patterns)
"	separate passes to filter functions and commands
"	pre-filter lines once with '\|'-joined {fastpat}s
if !exists("g:asneeded#scancfg")
    let g:asneeded#scancfg = {}
endif
call extend(g:asneeded#scancfg, {"func": {}, "com": {}}, "keep")
call extend(g:asneeded#scancfg.func, {
    \ "flag": "f",
    \ "fastpat": '\<fu',
    \ "pat": '^[ \t:]*fu\%[nction]!\=\C\s\+\%(s:\)\@!\(\u\w*\|\h\+:\h\w*\)\s*(.*$',
    \ }, "keep")
call extend(g:asneeded#scancfg.com, {
    \ "flag": "c",
    \ "fastpat": '\<com',
    \ "pat": '^[ \t:]*\%(sil\%[ent][! :\t][ :\t]*\)\=com\%[mand][! \t]\s*\%(-\S\+\s\+\)*\(\u\w*\)\>.*',
    \ }, "keep")

" Old com.pat:
"   \ "pat": '^[ \t:]*com\%[mand]!\=\%(\s\+-\S\+\)*\s\+\(\u\w*\)\>.*'
    \ "pat": '^[ \t:]*\%(sil\%[ent][! :\t][ :\t]*\)\=com\%[mand]!\=\%(\s\+-\S\+\)*\s\+\(\u\w*\)\>.*',

" added 19-10-2009, see how it proves value
" should it be an object attribute?
let g:asneeded#sourcedepth = 0
" }}}

" create object instance:
func! asneeded#New(an_path, scancfg) "{{{
    let ant = copy(s:asneeded)
    let ant.path = a:an_path

    call ant.GetSources()

    let ant.alltags = {}
    for ptag in ant.ptags
	let tag_file = ant.sources[ptag].fname
	let ant.alltags[ptag] = asneeded#read_antags(tag_file)
    endfor

    let ant.scancfg = a:scancfg
    let ant.jmp = {}
    for tkind in keys(ant.scancfg)
	" let ant.jmp[tkind] = ant.GetTags(ant.scancfg[tkind].flag)
	call ant.MkJmpTags(tkind)
    endfor

    return ant
endfunc "}}}


" INTERNAL INSTANCE

" create/get the internal instance (check ANtags files for changes)
func! asneeded#GetObj() "{{{
    if !exists("s:ant")
	let s:ant = asneeded#New(g:asneeded_path, g:asneeded#scancfg)
    elseif g:asneeded#sourcedepth == 0
	call s:ant.Update()
    endif
    return s:ant
endfunc "}}}

" refresh the internal instance
func! asneeded#Refresh() "{{{
    let s:ant = asneeded#New(g:asneeded_path, g:asneeded#scancfg)
endfunc "}}}

" source script after a function name
func! asneeded#FuncLoad(funcname) "{{{
    " {funcname}	name of a (yet undefined) global function
    if a:funcname =~ '#'
	return
    endif
    if g:asneeded_func_ignpat != '' && a:funcname =~# g:asneeded_func_ignpat
	return
    endif
    let [sfile, inrtp] = asneeded#GetObj().ScriptFqname("func", a:funcname)
    if sfile != ""
	call s:SourceFile(sfile, inrtp)
    endif
endfunc "}}}

" source script for each given command name
func! asneeded#ComLoad(...) "{{{
    " a:1 ...	user command to load
    for cmdname in a:000
	if exists(":". cmdname) == 2
	    continue
	elseif matchstr(cmdname, '^\u\w*') == ""
	    echoerr "AN: not a valid command name:" cmdname
	    continue
	endif
	if !exists("ant")
	    let ant = asneeded#GetObj()
	endif
	let [sfile, inrtp] = ant.ScriptFqname("com", cmdname)
	if sfile != ""
	    call s:SourceFile(sfile, inrtp)
	else
	    echoerr "AN: no script known to define :".cmdname
	endif
    endfor
endfunc "}}}

" source a script (not specialized):
func! asneeded#Source(tkind, tagname) "{{{
    if a:tagname == ""
	return
    endif
    let ant = asneeded#GetObj()
    if a:tkind == ""
	echoerr 'asneeded#Source({tkind}, ...): {tkind} must be one of:'.
	    \ ' "'.join(keys(ant.jmp), '", "').'"'
	return
    endif
    let [sfile, inrtp] = ant.ScriptFqname(a:tkind, a:tagname)
    if sfile != ""
	call s:SourceFile(sfile, inrtp)
    else
	echoerr "asneeded#Source(): don't know a script defining" a:tagname
    endif
endfunc "}}}

func! asneeded#TaggedFiles() "{{{
    return asneeded#GetObj().TaggedFiles()
endfunc "}}}

func! asneeded#Exists(expr) "{{{
    return asneeded#GetObj().Exists(a:expr)
endfunc "}}}

" command completion:
func! asneeded#ComplAN(...) "{{{
    let ant = asneeded#GetObj()
    let cmdlist = keys(ant.jmp.com)
    call filter(cmdlist, 'exists(":".v:val) != 2')
    return join(sort(cmdlist), "\n")
endfunc "}}}


" ASNEEDED PROTOTYPE

let s:asneeded = {}

" check known ANtags files for changes
func! s:asneeded.Update() "{{{
    let antupd = 0
    for ptag in self.ptags
	let src = self.sources[ptag]
	if src.tstamp == 0
	    " not used yet
	    continue
	endif
	let ftime = getftime(src.fname)
	if ftime != src.tstamp
	    let src.tstamp = ftime
	    let self.alltags[ptag] = asneeded#read_antags(src.fname)
	    let antupd = 1
	endif
    endfor
    if antupd
	for tkind in keys(self.scancfg)
	    " let self.jmp[tkind] = self.GetTags(self.scancfg[tkind].flag)
	    call self.MkJmpTags(tkind)
	endfor
    endif
endfunc "}}}

" check g:asneeded_path -> ptags, sources
func! s:asneeded.GetSources() abort "{{{
    let self.sources = {}
    let self.ptags = []
    let autoid_num = 1
    let entrylist = split(self.path, ",")
    let entryidx = 0
    let guardidx = -1	" detect endless loops
    " not a for-loop: list can be modified when expanding relative paths
    while entryidx < len(entrylist)

	" inrtp - added to compare with autorc path
	if type(entrylist[entryidx]) == type([])
	    let [entry, inrtp] = entrylist[entryidx]
	else " string (former)
	    let entry = entrylist[entryidx]
	    let inrtp = "<|>"	" magic invalid path name
	endif

	if entry !~ '|'
	    while index(self.ptags, "AN". autoid_num) >= 0
		let autoid_num += 1
	    endwhile
	    let [ptag, path] = ["AN". autoid_num, entry]
	    let autoname = 1
	else
	    try
		let [ptag, path] = split(entry, "|")
		let autoname = 0
		if index(self.ptags, ptag) >= 0
		    echoerr printf('GetSources(): doubled ptag "%s", skipping path "%s"', ptag, path)
		    let entryidx += 1
		    continue
		endif
	    catch
		echoerr printf('GetSources(): bad path entry: "%s"', entry)
		let entryidx += 1
		continue
	    endtry
	endif
	if s:IsRelativePath(path)
	    if guardidx == entryidx
		echoerr printf('GetSources(): not a full path (bad ''rtp'' entry?): "%s"', path)
		let entryidx += 1
		continue
	    endif
	    let rellist = split(globpath(&rtp, path), "\n")
	    call filter(rellist, "filereadable(simplify(fnamemodify(v:val, ':p'). '/ANtags'))")
	    call remove(entrylist, entryidx)
	    if !empty(rellist)
		if !autoname
		    let lenrl = len(rellist)
		    if lenrl == 1
			let rellist[0] = ptag. "|". rellist[0]
		    else
			for ptagnum in range(lenrl)
			    let rellist[ptagnum] = ptag. (ptagnum+1). "|". rellist[ptagnum]
			endfor
		    endif
		endif

		" 10-07-2009 inrtp, autorc
		let path = tr(path, '\', '/')
		call map(rellist, '[v:val, path]')

		call extend(entrylist, rellist, entryidx)
		let guardidx = entryidx
	    else
		call s:Warning('GetSources(): no match for "%s" in the runtimepath', path)
	    endif
	    continue
	endif
	let path = fnamemodify(path, ":p")
	if !isdirectory(path)
	    call s:Warning('GetSources(): not a directory: "%s"', path)
	    let entryidx += 1
	    continue
	endif
	let antags_fqname = simplify(fnamemodify(path, ':p'). '/ANtags')
	let timestamp = getftime(antags_fqname)
	let self.sources[ptag] = {"fname": antags_fqname,
	    \ "tstamp": timestamp, "inrtp": inrtp}
	call add(self.ptags, ptag)
	if autoname
	    let autoid_num += 1
	endif
	let entryidx += 1
    endwhile
endfunc "}}}

func! s:asneeded.MkJmpTags(tkind) abort "{{{
    let flag = self.scancfg[a:tkind].flag
    " let flagpat = "^".flag."$"
    let jmptags = {}
    for ptag in self.ptags
	let taglist = copy(self.alltags[ptag])
	call filter(taglist, 'v:val[0] ==# flag')
	for [_, tagname, scriptname] in taglist
	    if !has_key(jmptags, tagname)
		let jmptags[tagname] = [ptag, scriptname]
	    endif
	endfor
    endfor
    let self.jmp[a:tkind] = jmptags
endfunc "}}}

" extract script names from the ANtags files
func! s:asneeded.TaggedFiles() "{{{
    let dirX = []
    for ptag in self.ptags
	let entry = {}
	let tag_file = self.sources[ptag].fname
	let entry.dir = simplify(fnamemodify(tag_file, ":h"). "/")
	let files = {}
	for antag in self.alltags[ptag]
	    let files[antag[2]] = 1
	endfor
	let entry.fnames = sort(keys(files))
	call add(dirX, entry)
    endfor
    return dirX
endfunc "}}}

" extended exists()
func! s:asneeded.Exists(expr) "{{{
    " {expr}	    ":comname" or "*funcname"
    let ex_val = exists(a:expr)
    if a:expr[0] == ":"
	if ex_val == 2
	    return 2
	endif
    elseif ex_val
	return ex_val
    endif
    if a:expr[0] == ":"
	return has_key(self.jmp.com, a:expr[1:]) ? 4 : ex_val
    elseif a:expr[0] == "*"
	return has_key(self.jmp.func, a:expr[1:]) ? 4 : 0
    else
	echoerr 'asneeded#Exists(): argument must start with ":" or "*"'
	return 0
    endif
endfunc "}}}

func! s:asneeded.ScriptFqname(tkind, tagname) "{{{
    if !has_key(self.jmp[a:tkind], a:tagname)
	return ['', '']
    endif
    let [ptag, scriptname] = self.jmp[a:tkind][a:tagname]
    let src = self.sources[ptag]
    let sfile = simplify(fnamemodify(src.fname, ":h"). "/". scriptname)
    return [sfile, src.inrtp]
endfunc "}}}

" READ/WRITE ANTAGS (NO OBJECT INVOLVED)

" read the ANtags file, return tag_lists
func! asneeded#read_antags(tag_file) "{{{
    try
	let lines = readfile(a:tag_file)
    catch
	return []
    endtry
    let tag_lists = []
    for line in lines
	let parts = split(line, "\t")
	call add(tag_lists, parts)
    endfor
    return tag_lists
endfunc "}}}

" opposite of asneeded#read_antags(); return lines, don't write yet
func! asneeded#make_taglines(tag_lists, ...) abort "{{{
    " a:1, a:2	    range of lines, zero based, default 1, "$"
    let nlines = len(a:tag_lists)
    let first = a:0>=1 ? a:1 : 0
    let last = a:0>=2 ? min([a:2, nlines-1]) : nlines-1
    if first > last
	return []
    endif
    let lines = []
    let idx = first
    while idx <= last
	call add(lines, join(a:tag_lists[idx], "\t"))
	let idx += 1
    endwhile
    return lines
endfunc "}}}

func! asneeded#MakeTags(bang, ...) "{{{
    " a:1, a:2, ...	fspec: file names or glob patterns

    if a:0 >= 1
	let spec_expanded = asneeded#Expand(a:000)
	if a:bang
	    call s:Warning("ANmakeTags: with arguments, [!] has no meaning")
	endif
    else
	call asneeded#CleanupTags()
	if a:bang
	    " now with dead files removed:
	    let spec_expanded = asneeded#TaggedFiles()
	else
	    return
	endif
    endif

    if empty(spec_expanded)
	call s:Warning("ANmakeTags: no script file found")
	return
    endif

    for xentry in spec_expanded
	" xentry: {'dir': '/foo/dir/', 'fnames': ['foo.vim',...]}

	let tag_file = xentry.dir . "ANtags"
	let tag_lists = asneeded#read_antags(tag_file)

	" file_tags: fname -> [[type, tagname], ...]
	let file_tags = {}
	for entry in tag_lists
	    if len(entry) < 3
		continue
	    endif
	    let fname = entry[2]
	    if has_key(file_tags, fname)
		call add(file_tags[fname], entry[0:1])
	    else
		let file_tags[fname] = [entry[0:1]]
	    endif
	endfor

	" add scanned tags to file_tags, or replace existing tags with
	" scanned tags (keep disabled tags):
	for fname in xentry.fnames
	    let scantags = asneeded#ScanFile(xentry.dir . fname, g:asneeded#scancfg)
	    if has_key(file_tags, fname)
		let olddisabled = file_tags[fname]
		" more general than v:val[0] =~# "^-[cf]":
		call filter(olddisabled, 'v:val[0] =~ "^-\\l"')
		if empty(olddisabled)
		    let file_tags[fname] = scantags
		else
		    let entries = []
		    for [type, tagname] in scantags
			if index(olddisabled, ["-".type, tagname]) >= 0
			    call add(entries, ["-".type, tagname])
			else
			    call add(entries, [type, tagname])
			endif
		    endfor
		    let file_tags[fname] = entries
		endif
	    else
		let file_tags[fname] = scantags
	    endif
	endfor

	" [[type, tagname, fname], ...], ordered after f[ile]names
	let tag_lists = []
	for fname in sort(keys(file_tags))
	    for entry in file_tags[fname]
		call add(tag_lists, entry + [fname])
	    endfor
	endfor

	if empty(tag_lists)
	    let antfwrp = fnamemodify(tag_file, ":.")
	    if glob(tag_file) != ""
		call delete(tag_file)
		call s:Warning('ANmakeTags: removed empty file "%s"', antfwrp)
	    else
		call s:Warning('ANmakeTags: nothing found, did not create "%s"', antfwrp)
	    endif
	    continue
	endif

	let taglines = asneeded#make_taglines(tag_lists)
	try
	    call writefile(taglines, tag_file)
	catch
	    echoerr "ANmakeTags: error writing to" tag_file
	endtry
    endfor
endfunc "}}}

func! asneeded#Expand(fspeclist) "{{{
    " fspeclist	    list of file names, glob patterns, ...
    "		    a relative path in {fspec} is relative to getcwd()

    " special chars %, #, ## etc. must be already expanded

    let dirL = []	" dir names matching fspec
    let filesL = []	" their files matching fspec
    for fspec in a:fspeclist
	let fqdir = simplify(fnamemodify(fspec, ':p:h:gs?\\?/?')."/")
	" let files = split(glob(fspec), "\n")
	let files = split(expand(fspec), "\n")
	if empty(files)
	    continue
	endif
	call map(files, 'fnamemodify(v:val, ":t")')
	let dix = index(dirL, fqdir)
	if dix >= 0
	    call extend(filesL[dix], files)
	    " dups in a filesL entry are not prevented
	else
	    call add(dirL, fqdir)
	    call add(filesL, files)
	endif
    endfor
    " dirL entries have a trailing "/"

    let dirX = []
    let idx = 0
    let len = len(dirL)
    while idx < len
	call add(dirX, {"dir": dirL[idx], "fnames": filesL[idx]})
	let idx += 1
    endwhile
    return dirX
endfunc "}}}

" gather command and function tags from a script file ()
func! asneeded#ScanFile(fqname, scancfg) "{{{
    " return [["c", {comname1}], ..., ["f": {funcname1}], ...]
    " function or command tags first? -- order is arbitrary
    let fqname = a:fqname
    try
	let lines = readfile(fqname)
    catch
	" echoerr "ANmakeTags: error reading" fqname
	return []
    endtry

    let scancfg = a:scancfg
    let fastpat = join(map(values(scancfg), 'v:val.fastpat'), '\|')
    call filter(lines, 'v:val =~ fastpat')

    let taglist = []
    for scandef in values(scancfg)
	let tagnames = asneeded#ScanLines(copy(lines), scandef)
	if !empty(tagnames)
	    call extend(taglist, map(tagnames, '[scandef.flag, v:val]'))
	endif
    endfor

    if empty(taglist)
	call s:Warning('ANmakeTags: no tags from "%s"', fnamemodify(fqname, ':.'))
    endif
    return taglist
endfunc
"}}}

func! asneeded#ScanLines(lines, scandef) "{{{
    let [tkind_lines, scandef] = [a:lines, a:scandef]
    call filter(tkind_lines, 'v:val =~ scandef.pat')
    if empty(tkind_lines)
	return []
    endif
    let pat_qesc = escape(scandef.pat, '\"')
    let scandef_expr = 'substitute(v:val, "'.pat_qesc.'", "\\1", "")'
    return map(tkind_lines, scandef_expr)
endfunc "}}}

" READ/WRITE ANTAGS (INTERNAL INSTANCE)

func! asneeded#CleanupTags() "{{{
    let tagged_spec = asneeded#TaggedFiles()

    for xentry in tagged_spec
	let rm_list = copy(xentry.fnames)
	call filter(rm_list, 'glob(xentry.dir. v:val) == ""')
	if empty(rm_list)
	    continue
	endif

	let tag_file = xentry.dir . "ANtags"
	let tag_lists = asneeded#read_antags(tag_file)

	let fexpr = 'len(v:val) >= 3 && index(rm_list, v:val[2]) < 0'
	call filter(tag_lists, fexpr)

	let taglines = asneeded#make_taglines(tag_lists)
	try
	    call writefile(taglines, tag_file)
	catch
	    echoerr "asneeded#CleanupTags(): error writing to" tag_file
	endtry
    endfor
endfunc "}}}


" LOCAL FUNCS

" replaces  :exec "source" sfile
" if possible, let autoload/autorc.vim load the script {sfile}
func! s:SourceFile(sfile, inrtp) "{{{
    let sname = fnamemodify(a:sfile, ':t:r')
    if !exists("g:autorc#loaded")
	let g:autorc#loaded = 0
	" ^ prevent checking all the time for the autorc script on disk if
	" it isn't there
    endif
    try
	let g:asneeded#sourcedepth += 1
	if g:autorc#loaded && autorc#CanLoad(sname, a:inrtp)
	    call autorc#L(sname)
	else
	    exec "source" a:sfile
	endif
    finally
	let g:asneeded#sourcedepth -= 1
    endtry
endfunc

" 23-09-2009 path comparison
" the same (relative) path can be written in many different ways; a
" successful check for equality (of the two paths a:inrtp and
" g:autorc#loadpath) requires normalization, either here (use of tr()
" reminds of that) or per convention
"	\ && tr(a:inrtp,'\','/') == tr(g:autorc#loadpath,'\','/')
"	\ && has_key(g:autorc#loadcmds, sname)

"}}}

func! s:IsRelativePath(dir) "{{{
    return !s:PathIsAbsolute(a:dir)
endfunc "}}}

func! s:Warning(fmt, ...) "{{{
    echohl WarningMsg
    echomsg call("printf", [a:fmt] + a:000)
    echohl None
endfunc "}}}


" FROM GENUTILS

function! s:OnMS() "{{{
    return has('win32') || has('dos32') || has('win16') || has('dos16')
endfunction "}}}
let s:AnyMSofty = s:OnMS()

function! s:PathIsAbsolute(path) "{{{
    if has('unix')
	return match(a:path, '^[~/]') == 0
    elseif s:AnyMSofty
	return match(a:path, '^\a:[\\/]\|^[\\/~]') == 0
    endif
endfunction "}}}

" vim:set fdm=marker ts=8 sw=4 sts=4 noet:
