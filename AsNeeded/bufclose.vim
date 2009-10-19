" :bd - don't close my window . vim
" Date:		2007 Oct 10
" Last Change:	2009 Jun 14
" Rev Days:     1
" Dependencies:	autoload/bunused.vim
"
" http://www.vi-improved.org/wiki/index.php/DontCloseMyWindow?version=13
"
"   :Bd [{buffernum}] - by FallingCow
"
" Buffer to delete: Replace its first window with the next buffer.  Other
" windows and windows in other tab pages: replace with empty window.
" Then delete the buffer.

com! -bang -nargs=? BdKeepWin call s:BDel(<q-bang>, <args>)

func! s:BDel(bang, ...) abort "{{{
    let bd_bnr = a:0>=1 ? a:1 : bufnr("")

    if type(bd_bnr) != type(0)
	echoerr "Argument must be a number"
	return
    endif

    let next_bnr = s:NextBnr(bd_bnr)
    let first_win_do_bnext = next_bnr >= 1

    " current tab page:
    let sav_wnr = winnr()
    if winbufnr(sav_wnr) == bd_bnr
	let bwnr = sav_wnr
    else
	let bwnr = bufwinnr(bd_bnr)
    endif
    while bwnr >= 1
	exec "noa" bwnr."wincmd w"

	if first_win_do_bnext
	    exec "buf" next_bnr
	elseif !bunused#LoadUnused()
	    break
	endif
	let first_win_do_bnext = 0

	let bwnr = bufwinnr(bd_bnr)
    endwhile
    exec "noa" sav_wnr."wincmd w"

    " separate handling of the other tab pages:
    let cur_tabnr = tabpagenr()
    let tabpage_list = range(1, tabpagenr("$"))
    call filter(tabpage_list, 'v:val != cur_tabnr')
    call filter(tabpage_list, 'index(tabpagebuflist(v:val),bd_bnr)>=0')
    for tabnr in tabpage_list
	exec "noa tabnext" tabnr
	let sav_wnr = winnr()
	let bwnr = bufwinnr(bd_bnr)
	while bwnr >= 1
	    exec "noa" bwnr."wincmd w"

	    if !bunused#LoadUnused()
		break
	    endif

	    let bwnr = bufwinnr(bd_bnr)
	endwhile
	exec "noa" sav_wnr."wincmd w"
    endfor
    exec "noa tabnext" cur_tabnr

    " Finally: Delete the buffer!
    exec "bd".a:bang bd_bnr
endfunc "}}}

" like :bnext, but starting from an arbitrary buf number, and
" return the next buffer number (don't switch buffers)
func! s:NextBnr(bnr) "{{{
    let maxbnr = bufnr('$')
    let nextbnr = a:bnr
    while 1
	let nextbnr = 1 + nextbnr % maxbnr
	if s:UserBuf(nextbnr) || nextbnr == a:bnr
	    break
	endif
    endwhile
    if nextbnr == a:bnr
	return -1
    else
	return nextbnr
    endif
endfunc "}}}

func! s:UserBuf(bnr) "{{{
    return buflisted(a:bnr) && getbufvar(a:bnr, '&modifiable')
endfunc "}}}

" vim:set fdm=marker:
