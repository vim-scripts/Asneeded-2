" Vim plugin -- addon for AsNeeded
" File:         anmap.vim
" Created:      2009 Jun 14
" Last Change:  2009 Oct 18
" Rev Days:     4
" Author:	Andy Wokula <anwoku@yahoo.de>
" License:	Vim License, see :h license

" Description:
" - Sourcing this script lets :ANmakeTags recognize mappings starting with
"   <Leader> or <Plug>.
" - New command :ANmap to source a script by a mapname.

" Terms: (variable names)
"   "mapname": {lhs} of a mapping, especially when used as a tag
"   "ant": short for the asneeded instance = the return value of
"	   asneeded#GetObj()

" ID for the new kind of tag (next to "com" and "func"):
let s:tkind = "map"

com! -nargs=1 -complete=custom,s:MapCompl ANmap call asneeded#Source(s:tkind, <q-args>)
" like :AN, but with a mapname as argument; and :ANmap will unconditionally
" load a script!

" if g:asneeded#scancfg doesn't exist yet, the following command will try to
" load autoload/asneeded.vim to make it available:
call extend(g:asneeded#scancfg, {
    \ s:tkind : {
    \	"flag": "m",
    \	"fastpat": 'map\|[novx]n\|[il]no',
    \	"pat": '^\%("\@![ \t:]\)*\%(map\|[nvoilc]m\%[ap]\|[oic]\=no\%[remap]\|[nl]n\%[oremap]\)!\=\%(\s*<\%(silent\|unique\|buffer\|script\|expr\)>\)*\s*\(<\%([Ll]eader\|[Pp]lug\)>\S\+\)\s.*'
    \ }})

" "pat": '^[ \t:]*\%(^\s*".*\)\@<!\<\%(map\|[nvoilc]m\%[ap]\|[oic]\=no\%[remap]\|[nl]n\%[oremap]\)!\=\%(\s*<\%(silent\|unique\|buffer\|script\)>\)*\s*\(<\%([lL]eader\|[pP]lug\)>\S\+\)\s.*'
"
" DrChip's pattern (almost):
"   \<\%(map\|[nvoilc]m\%[ap]\|[oic]\=no\%[remap]\|[nl]n\%[oremap]\)!\=\%(\s*<\%(silent\|unique\|buffer\|script\)>\)*\s*\(\S\+\)\s

" {flag}	letter for first column in ANtags files
" {fastpat}	is for pre-filtering lines; it will be part of a
"		'\|'-branch; must match at least were {pat} matches
" {pat}		pattern for :map-definitions in script files, must match a
"		whole line; backref \1 must match the mapname
"
" the ant instance has a reference on g:asneeded#scancfg (not a copy).

" completion for :ANmap
func! s:MapCompl(...)
    let ant = asneeded#GetObj()
    let maplist = keys(ant.jmp[s:tkind])
    return join(sort(maplist), "\n")
endfunc

call asneeded#GetObj().MkJmpTags(s:tkind)
" Prepare the mapname->[ptag, scriptname] table (ant.jmp.map) from the
" cached raw tags (ant.alltags).  If this looks "too internal", :ANrefresh
" will include this command as well.

" Rant: Adding mappings as asneeded tags is a dirty thing to do ... imho
" this functionality deserves an extra script like this one to be easily
" removable.  Ok, my goal was to replace DrChip's AsNeeded script, which
" supports mappings, and AsNeeded's credits even emphasize this particular
" feature.  Now then, what's so bad about mappings:
" - The mapname must be short, so it's difficult to avoid name clashes.
" - Mappings are more difficult to support: There are dozens of :map
"   commands.
" - What I think that is actually wanted in most cases: A mapping is already
"   defined after startup, but its script is not loaded yet.  The script
"   will be sourced when the mapping is typed.  This is beyond the purpose
"   of Asneeded.
