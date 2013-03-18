" SwapText.vim: Mappings to exchange text with the previously deleted text.
"
" REVISION	DATE		REMARKS
"   	015	28-Aug-2012	For the operators, handle readonly and
"				nomodifiable buffers by printing just the
"				warning / error, without the multi-line function
"				error. (Unlikely as it may be, as the user must
"				have done a delete first, anyway.)
"	014	17-Nov-2011	ENH: Handle :undojoin failure when user did undo
"				between delete and swap. To avoid a potential
"				swap with wrong register contents, error in this
"				case.
"				FIX: Require Vim 7, necessary for :undojoin.
"				Rename to SwapText.vim.
"				Split off autoload script and documentation.
"	013	30-Sep-2011	Use <silent> for <Plug> mapping instead of
"				default mapping.
"	012	22-Jun-2011	BUG: Must adapt the deleted line location if
"				it's below the overridden range; the override
"				may have changed the number of lines.
"	011	16-Jun-2011	Remove general "P" command from pasteCmd
"				argument and rename it selectReplacementCmd.
"				Remove outdated comment.
"	010	12-Feb-2010	After further problems with the used marks, set
"				jumps, etc., replaced all used marks with a
"				variable, and was even able to simplify the code
"				through it.
"				ENH: The swap is now atomic, i.e. it can be
"				undone in a single action.
"	009	12-Feb-2010	BUG: Used mark ' instead of mark ", thereby
"				horribly breaking everything. (It's astounding
"				how long it took me to notice!)
"	008	11-Sep-2009	BUG: Cannot set mark " in Vim 7.0 and 7.1; using
"				mark z instead; abstracted mark via s:tempMark.
"	007	04-Jul-2009	Also replacing temporary mark ` with mark " and
"				using g` command for the visual mode swap.
"	006	18-Jun-2009	Replaced temporary mark z with mark " and using
"				g` command to avoid clobbering jumplist.
"	005	21-Mar-2009	Added \xx mapping for linewise swap.
"				Added \X mapping for swap until the end of line.
"	004	07-Aug-2008	hasmapto() now checks for normal mode.
"	003	30-Jun-2008	Removed unnecessary <script> from mappings.
"	002	07-Jun-2007	Changed offset algorithm from calculating
"				differences to set marks to differences in
"				pasted text.
"				BF: Saving position of deleted text and adding
"				offset to that instead of jumping to mark and
"				adding offset then (which doesn't work when the
"				swap shortens the line and the mark now points
"				to after the end of the line.
"				Added Vim 7 custom operator.
"				Refactored code so that both the visual mode
"				mapping and the operator use the same functions.
"	001	06-Jun-2007	file creation

function! s:SwapTextWithOffsetCorrection( selectReplacementCmd )
    " When you change a line by inserting/deleting characters, any marks to
    " the right of the change don't get adjusted to correct for the change,
    " but stay pointing at the exact same column as before the change (which
    " is not the right place anymore).
    let l:deletedCol = col("'.")
    let l:deletedTextLen = len(@")
    execute 'normal! ' . a:selectReplacementCmd . 'P'
    let l:replacedTextLen = len(@")
    let l:offset = l:deletedTextLen - l:replacedTextLen
"****D echomsg '**** corrected for ' . l:offset. ' characters.'
    call cursor(line('.'), l:deletedCol + l:offset)
    normal! P
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
	let l:deletedLine = line("'.")
	let l:deletedLineCnt = s:LineCnt(@")

	" Override with deleted contents.
	execute 'normal! ' . a:selectReplacementCmd . 'P'
"****D echomsg '****' l:deletedCol l:deletedLine l:deletedLineCnt
	" Must adapt the deleted line location if it's below the overridden
	" range; the override may have changed the number of lines.
	let l:overwrittenLineCnt = s:LineCnt(@")
	let l:offset = l:deletedLineCnt - l:overwrittenLineCnt
	if l:deletedLine > line('.')
	    let l:deletedLine += l:offset
	endif
"****D echomsg '****' l:overwrittenLineCnt l:offset
	" Put overridden contents at the formerly deleted location.
	call cursor(l:deletedLine, l:deletedCol)
	let l:isAtEndOfDeletedLine = (l:deletedVirtCol + 1 == virtcol('$'))
	" Because the '[,'] marks are already set to the current swap area, we
	" cannot use them any more to determine whether the previous deletion
	" was before or after the cursor position. Therefore we save that
	" position at the start of the mapping.
	let l:wasDeletionAtEndOfLine = (s:deletedStartPos[1] == line('.') && s:deletedStartPos[2] > l:deletedCol)
"****D echomsg '****' l:deletedLine l:deletedCol string(getpos('.')) l:isAtEndOfDeletedLine string(s:deletedStartPos) l:wasDeletionAtEndOfLine
	if l:isAtEndOfDeletedLine && l:wasDeletionAtEndOfLine
	    normal! p
	else
	    normal! P
	endif
    endif
endfunction

function! SwapText#Visual()
    let s:deletedStartPos = getpos("'[")
    call s:SwapText('gv')
endfunction

function! SwapText#Operator( type )
    " The operator needs another undojoin for the operator action itself.
    undojoin

    " The 'selection' option is temporarily set to "inclusive" to be able to
    " yank exactly the right text by using Visual mode from the '[ to the ']
    " mark.
    let l:save_sel = &selection
    set selection=inclusive

    if a:type ==# 'char'
	call s:SwapText('`[v`]')
    elseif a:type ==# 'line'
	call s:SwapText('`[V`]')
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
	let v:errmsg = 'Cannot swap after undo'
	echohl ErrorMsg
	echomsg v:errmsg
	echohl None
	return 0
    endtry
endfunction

function! SwapText#OperatorExpr()
    if ! SwapText#UndoJoin()
	return ''
    endif

    let s:deletedStartPos = getpos("'[")

    set opfunc=SwapText#Operator

    let l:keys = 'g@'

    if ! &l:modifiable || &l:readonly
	" Probe for "Cannot make changes" error and readonly warning via a no-op
	" dummy modification.
	" In the case of a nomodifiable buffer, Vim will abort the normal mode
	" command chain, discard the g@, and thus not invoke the operatorfunc.
	let l:keys = ":call setline('.', getline('.'))\<CR>" . l:keys
    endif

    return l:keys
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
