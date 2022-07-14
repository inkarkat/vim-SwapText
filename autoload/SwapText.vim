" SwapText.vim: Mappings to exchange text with the previously deleted text.
"
" DEPENDENCIES:
"   - ingo-library.vim plugin
"
" Copyright: (C) 2007-2022 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

" Since Vim 8.2.0324, the last change position can be one beyond the last
" [screen] column (col('$') == col("'.")); previously its value was reset to
" point at the character before the deletion if that happened at the end of the
" line (col('$') == col("'.") + 1). The patch isn't about that, so it's not
" clear whether that change was intentional; as 2.5 years have passed already,
" let's take it at face value and implement a workaround here.
let s:atEndColOffset = (v:version < 802 || v:version == 802 && ! has('patch324') ? 1 : 0)

function! s:WasDeletionAtEndOfLine( deletedCol, deletedVirtCol, deletedVirtLen )
    let l:isAtEndOfDeletedLine = (a:deletedVirtCol + s:atEndColOffset == a:deletedVirtLen)
    if ! l:isAtEndOfDeletedLine
	return 0
    endif

    " Because the '[,'] marks are already set to the current swap area, we
    " cannot use them any more to determine whether the previous deletion
    " was before or after the cursor position. Therefore we save that
    " position at the start of the mapping.
    let l:wasDeletionAtEndOfLine = (s:deletedStartPos[1] == line('.') && s:deletedStartPos[2] >= (a:deletedCol + s:atEndColOffset))
"****D echomsg '****' string(getpos('.')) l:isAtEndOfDeletedLine string(s:deletedStartPos) l:wasDeletionAtEndOfLine
    return l:wasDeletionAtEndOfLine
endfunction
function! s:Replace( deletedCol, deletedVirtCol, deletedVirtLen )
    execute 'normal!' (s:WasDeletionAtEndOfLine(a:deletedCol, a:deletedVirtCol, a:deletedVirtLen) ? 'p' : 'P')
endfunction

function! s:SwapTextWithOffsetCorrection( selectReplacementCmd )
    " When you change a line by inserting/deleting characters, any marks to
    " the right of the change don't get adjusted to correct for the change,
    " but stay pointing at the exact same column as before the change (which
    " is not the right place anymore).
    let l:deletedCol = col("'.")
    let l:deletedVirtCol = virtcol("'.")
    let l:deletedVirtLen = virtcol('$')
    let l:deletedTextLen = len(@")
    execute 'normal! ' . a:selectReplacementCmd . 'p'
    let l:replacedTextLen = len(@")
    let l:offset = l:deletedTextLen - l:replacedTextLen
"****D echomsg '**** corrected for ' . l:offset. ' characters.'
    call cursor(line('.'), l:deletedCol + l:offset)
    call s:Replace(l:deletedCol, l:deletedVirtCol, l:deletedVirtLen)
endfunction

function! s:LineCnt( text )
    return strlen(substitute(a:text, '\n\@!.', '', 'g'))
endfunction
function! s:SwapText( selectReplacementCmd )
    if line('.') == line("'.") && col('.') < col("'.")
	call s:SwapTextWithOffsetCorrection(a:selectReplacementCmd)
    else
	let l:deletedCol = col("'.")
	let l:deletedVirtCol = virtcol("'.")
	let l:deletedVirtLen = (line('.') == line("'.") ? virtcol('$') : ingo#compat#strdisplaywidth(getline("'.")) + 1)
	let l:deletedLine = line("'.")
	let l:deletedLineCnt = s:LineCnt(@")

	" Overwrite with deleted contents.
	execute 'normal!' a:selectReplacementCmd . 'p'
"****D echomsg '****' l:deletedCol l:deletedLine l:deletedLineCnt
	" Must adapt the deleted line location if it's below the overwritten
	" range; the overwriting may have changed the number of lines.
	let l:overwrittenLineCnt = s:LineCnt(@")
	let l:offset = l:deletedLineCnt - l:overwrittenLineCnt
	if l:deletedLine > line('.')
	    let l:deletedLine += l:offset
	endif
"****D echomsg '****' l:overwrittenLineCnt l:offset
	" Put overwritten contents at the formerly deleted location.
	call cursor(l:deletedLine, l:deletedCol)
	call s:Replace(l:deletedCol, l:deletedVirtCol, l:deletedVirtLen)
    endif
endfunction

function! SwapText#Visual()
    let s:deletedStartPos = getpos("'[")
    call s:SwapText('gv')
endfunction

function! SwapText#Operator( type )
    " The operator needs another undojoin for the operator action itself.
    " Ignore any E790 in here; I hope that's fine.
    call SwapText#UndoJoin()

    " The 'selection' option is temporarily set to "inclusive" to be able to
    " yank exactly the right text by using Visual mode from the '[ to the ']
    " mark.
    let l:save_sel = &selection
    set selection=inclusive

    if a:type ==# 'char'
	call s:SwapText('g`[vg`]')
    elseif a:type ==# 'line'
	call s:SwapText('g`[Vg`]')
    else
	throw 'ASSERT: There is no blockwise visual motion, because we have a special vmap.'
    endif

    let &selection = l:save_sel
endfunction

function! SwapText#UndoJoin()
    " :undojoin may fail with "E790: undojoin is not allowed after undo" when
    " there was an undo immediately before the SwapText mapping. SwapText's
    " problem with undo is that register modifications of the undone command are
    " _not_ undone, so the replacement may be wrong. (We cannot know for sure,
    " the undone command may have specified another target register, or not
    " affected the registers at all.) Better be safe than doing unexpected
    " things.
    try
	undojoin
	return 1
    catch /^Vim\%((\a\+)\)\=:E790/	" E790: undojoin is not allowed after undo
	call ingo#err#Set('Cannot swap after undo')
	return 0
    endtry
endfunction

function! SwapText#OperatorExpr()
    if ! SwapText#UndoJoin()
	return ''
    endif

    let s:deletedStartPos = getpos("'[")

    return ingo#mapmaker#OpfuncExpression('SwapText#Operator')
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
