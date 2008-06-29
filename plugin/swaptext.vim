" swaptext.vim: Mapping to exchange text with the previously deleted text. 
"
" DESCRIPTION:
" USAGE:
"   First, delete some text (using any normal VIM command, such as 'daw',
"   {Visual}x, or 'dt'). Then, visually select some other text, and press 
"   <Leader>x, or use the custom operator, e.g. <Leader>xw. The two pieces of
"   text should now be swapped. 
"
" INSTALLATION:
" DEPENDENCIES:
" CONFIGURATION:
" LIMITATIONS:
"   - Unless "set virtualedit=all", swapping the last characters in a line will
"     insert one character short of where the insert should be. This only
"     happens when you swap FROM the last characters in a line to somewhere
"     else. If you swap TO (in the natural left-to-right editing order) the last
"     characters in a line, everythings works fine. 
"
" ASSUMPTIONS:
" KNOWN PROBLEMS:
" TODO:
"
" Copyright: (C) 2007 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
" Source: Based on vimtip #470: Map to quickly swap/exchange arbitrary text by
"	  Piet Delport and an enhancement by ad_scriven@postmaster.co.uk. 
"
" REVISION	DATE		REMARKS 
"	002	07-Jun-2007	Changed offset algorithm from calculating
"				differences to set marks to differences in
"				pasted text. 
"				BF: Saving position of deleted text and adding
"				offset to that instead of jumping to mark and
"				adding offset then (which doesn't work when the
"				swap shortens the line and the mark now points
"				to after the end of the line. 
"				Added VIM7 custom operator. 
"				Refactored code so that both the visual mode
"				mapping and the operator use the same functions. 
"	001	06-Jun-2007	file creation

" Avoid installing twice or when in compatible mode
if exists("g:loaded_swaptext")
    finish
endif
let g:loaded_swaptext = 1

"- functions ------------------------------------------------------------------
function! s:SwapTextWithOffsetCorrection( overrideCmd )
    " When you change a line by inserting/deleting characters, any marks to
    " the right of the change don't get adjusted to correct for the change,
    " but stay pointing at the exact same column as before the change (which
    " is not the right place anymore). 
    let l:deletedCol = col("'.")
    let l:deletedTextLen = len(@@)
    execute 'normal! ' . a:overrideCmd
    let l:replacedTextLen = len(@@)
    let l:offset = l:deletedTextLen - l:replacedTextLen
"****D echomsg '**** corrected for ' . l:offset. ' characters.'
    call cursor( line('.'), l:deletedCol + l:offset )
    normal! P
endfunction

function! s:SwapTextCharacterwise( overrideCmd, multipleLineCmd )
    if line('.') == line("'.") && col('.') < col("'.")
	call s:SwapTextWithOffsetCorrection( a:overrideCmd )
    else
	execute 'normal! ' . a:multipleLineCmd
    endif
endfunction

function! s:SwapTextVisual()
    call s:SwapTextCharacterwise( 'gvP', '`.``gvP``P' )
endfunction

function! s:SwapTextOperator( type )
    " The 'selection' option is temporarily set to "inclusive" to be able to
    " yank exactly the right text by using Visual mode from the '[ to the ']
    " mark.
    let l:save_sel = &selection
    set selection=inclusive

    " Inside the operatorfunc, the jump mark (``) can somehow not be used to
    " save the position of the deleted text (as is done in the visual mode
    " swap). Instead, we use a normal register. 
    if a:type == 'char'
	call s:SwapTextCharacterwise( '`[v`]P', '`.mz`[v`]P`zP' )
    elseif a:type == 'line'
	normal! `.mz`[V`]P`zP
    else
	throw 'ASSERT: There is no blockwise visual motion, because we have a special vmap.'
    endif

    let &selection = l:save_sel
endfunction

" How it works:
" <ESC>	exits visual mode
" `.	returns to exact spot of last modification (the deleted text) 
" ``	jumps back to where you were (exactly) 
" gv	re-selects last visual text 
" P	put/paste last deleted text over visually selected text 
" ``	moves to where text was deleted 
" P	visually selected text is now in the default register, so just paste it. 
"
"vnoremap <Leader>x <Esc>`.``gvP``P

" The simple mapping doesn't work when the deleted text occurs on the right of
" the selected text (i.e. when you edit against the typical left-to-right
" direction) _and_ both text elements are on the same line. 
" The following mapping + function explicitly check for that condition and take
" corrective actions. 
vnoremap <script> <Plug>SwapTextVisual :<C-U>call <SID>SwapTextVisual()<CR>
if ! hasmapto('<Plug>SwapTextVisual')
    vmap <silent> <Leader>x <Plug>SwapTextVisual
endif

" Original enhancement from ad_scriven@postmaster.co.uk (didn't work for me): 
"vnoremap <silent> <Leader>x <Esc>`.``:exe line(".")==line("'.") && col(".") < col("'.") ? 'norm! :let c=col(".")<CR>gvp```]:let c=col(".")-c<CR>``:silent call cursor(line("."),col(".")+c)<CR>P' : "norm! gvp``P"<CR>

"------------------------------------------------------------------------------
if v:version >= 700
    " The custom "swap text" operator uses 'operatorfunc' and 'g@', which were
    " introduced in VIM 7.0. Cp. ':help :map-operator'. 
    nnoremap <script> <Plug>SwapTextOperator :set opfunc=<SID>SwapTextOperator<CR>g@
    if ! hasmapto('<Plug>SwapTextOperator')
	nmap <silent> <Leader>x <Plug>SwapTextOperator
    endif
endif

