" SwapText.vim: Mapping to exchange text with the previously deleted text. 
"
" DESCRIPTION:
" USAGE:
"   First, delete some text (using any normal Vim command, such as 'daw',
"   {Visual}x, or 'dt'). Then, visually select some other text, and press 
"   <Leader>x, or use the custom operator <Leader>x{motion}. The two pieces of
"   text should now be swapped. 
"
" {Visual}<Leader>x	Swap the visual selection with the text from the unnamed
"			register. 
" <Leader>x{motion}	Swap the characters covered by {motion} with the text
"			from the unnamed register. 
" [count]<Leader>xx	Swap the current [count] line(s) with the text from the
"			unnamed register. 
" [count]<Leader>X	Swap the characters under the cursor until the end of
"			the line and [count]-1 more lines with the text from the
"			unnamed register. 
"
" INSTALLATION:
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher. 
"
" CONFIGURATION:
"
" LIMITATIONS:
"   - Unless "set virtualedit=all", swapping the last characters in a line will
"     insert one character short of where the insert should be. This only
"     happens when you swap FROM the last characters in a line to somewhere
"     else. If you swap TO (in the natural left-to-right editing order) the last
"     characters in a line, everythings works fine. 
"
" ASSUMPTIONS:
" KNOWN PROBLEMS:
"   - Offset correction only works when the entire swap-to text is inside one
"     line. 
"
" TODO:
"
" Copyright: (C) 2007-2011 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
" Source: Based on vimtip #470: Map to quickly swap/exchange arbitrary text by
"	  Piet Delport and an enhancement by ad_scriven@postmaster.co.uk. 
"
" REVISION	DATE		REMARKS 
"	014	17-Nov-2011	ENH: Handle :undojoin failure when user did undo
"				between delete and swap. To avoid a potential
"				swap with wrong register contents, error in this
"				case. 
"				FIX: Require Vim 7, necessary for :undojoin. 
"				Rename to SwapText.vim. 
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

" Avoid installing twice or when in unsupported Vim version. 
if exists('g:loaded_SwapText') || (v:version < 700)
    finish
endif
let g:loaded_SwapText = 1

"- functions ------------------------------------------------------------------
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
	normal! P
    endif
endfunction

function! SwapText#Visual()
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

    set opfunc=SwapText#Operator
    return 'g@'
endfunction

" How it works:
" <ESC>	exits visual mode
" `.	returns to exact spot of last modification (the deleted text) 
" m`	put the `. mark into ``, as it'll be overridden by the first paste
" gv	re-selects last visual text 
" P	put/paste last deleted text over visually selected text 
" ``	moves to where text was deleted 
" P	visually selected text is now in the default register, so just paste it. 
"
"vnoremap <Leader>x <Esc>`.m`gvP``P
"
" Original enhancement from ad_scriven@postmaster.co.uk (didn't work for me): 
"vnoremap <silent> <Leader>x <Esc>`.``:exe line(".")==line("'.") && col(".") < col("'.") ? 'norm! :let c=col(".")<CR>gvp```]:let c=col(".")-c<CR>``:silent call cursor(line("."),col(".")+c)<CR>P' : "norm! gvp``P"<CR>

" The simple mapping doesn't work when the deleted text occurs on the right of
" the selected text (i.e. when you edit against the typical left-to-right
" direction) _and_ both text elements are on the same line. 
" The following mapping + function explicitly check for that condition and take
" corrective actions. 
vnoremap <silent> <Plug>SwapTextVisual :<C-U>if SwapText#UndoJoin()<Bar>call SwapText#Visual()<Bar>endif<CR>
if ! hasmapto('<Plug>SwapTextVisual', 'v')
    xmap <Leader>x <Plug>SwapTextVisual
endif

nnoremap <silent> <Plug>SwapTextLines :<C-U>if SwapText#UndoJoin()<Bar>execute 'normal! V' . v:count1 . '_'<CR>:<C-U>call SwapText#Visual()<Bar>endif<CR>
if ! hasmapto('<Plug>SwapTextLines', 'n')
    nmap <Leader>xx <Plug>SwapTextLines
endif

nnoremap <silent> <Plug>SwapTextUntilEnd :<C-U>execute 'normal! v$' . (v:count > 1 ? (v:count - 1) . 'j' : '')<CR>:<C-U>if SwapText#UndoJoin()<Bar>call SwapText#Visual()<Bar>endif<CR>
if ! hasmapto('<Plug>SwapTextUntilEnd', 'n')
    nmap <Leader>X <Plug>SwapTextUntilEnd
endif

nnoremap <silent> <expr> <Plug>SwapTextOperator SwapText#OperatorExpr()
if ! hasmapto('<Plug>SwapTextOperator', 'n')
    nmap <Leader>x <Plug>SwapTextOperator
endif

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
