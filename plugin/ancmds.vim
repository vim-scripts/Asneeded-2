" Vim plugin -- setup for Asneeded
" File:         ANcmds.vim
" Created:      2009 Apr 20
" Last Change:  2009 Oct 19
" Rev Days:     17
" Author:       Andy Wokula <anwoku@yahoo.de>
" License:      Vim License, see :h license

if exists("loaded_ancmds")
    finish
endif
let loaded_ancmds = 1

if v:version < 700 || &compatible
    echomsg "ANcmds: you need at least Vim 7.0 and 'nocp' set"
    finish
endif

augroup Asneeded
    au!
    au FuncUndefined * call s:FuncLoad(expand("<afile>"))
augroup End

func! s:FuncLoad(funcname)
    if a:funcname !~ '#'
        call asneeded#FuncLoad(a:funcname)
    endif
endfunc

" pattern to find the cmd name after a range: at least skip an upper case
" mark:
let s:Uw_star = '\%(['']\)\@<!\u\w*'

com! -bar -nargs=+ -complete=custom,asneeded#ComplAN  AN   call asneeded#ComLoad(<f-args>)
com!      -nargs=1 -complete=custom,asneeded#ComplAN  ANX  call asneeded#ComLoad(matchstr(<q-args>,s:Uw_star))|<args>
com! -bar -bang -nargs=* -complete=file        ANmakeTags  call asneeded#MakeTags(<bang>0, <f-args>)
com! -bar                                      ANrefresh   call asneeded#Refresh()

" vim:set fdm=marker et:
