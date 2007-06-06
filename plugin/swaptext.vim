" swaptext.vim: Mapping to exchange text with the previously deleted text. 
"
" DESCRIPTION:
" USAGE:
"   First, delete some text (using any normal VIM command, such as 'daw',
"   {Visual}x, or 'dt'). Then, visually select some other text, and press the
"   mapped key.  The two pieces of text should now be swapped. 
"
" INSTALLATION:
" DEPENDENCIES:
" CONFIGURATION:
" LIMITATIONS:
" ASSUMPTIONS:
" KNOWN PROBLEMS:
" TODO:
"
" Copyright: (C) 2007 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
" Source:	vimtip #470: Map to quickly swap/exchange arbitrary text
"
" REVISION	DATE		REMARKS 
"	001	06-Jun-2007	file creation

" Avoid installing twice or when in compatible mode
if exists("g:loaded_swaptext")
    finish
endif
let g:loaded_swaptext = 1

function! s:SwapText()
    if line('.') == line("'.") && col('.') < col("'.")
	" When you change a line by inserting/deleting characters, any marks to
	" the right of the change don't get adjusted to correct for the change,
	" but stay pointing at the exact same column as before the change (which
	" is not the right place anymore). 
	let l:c = col('.')
	normal! gvp```]
	let l:c = col('.') - c
	normal! ``
	call cursor( line('.'), col('.') + l:c )
    else
	normal! gvp``
    endif
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
vnoremap <silent> <Leader>x `.``:<C-U>call <SID>SwapText()<CR>P

" Original enhancement from ad_scriven@postmaster.co.uk (didn't work for me): 
"vnoremap <silent> <Leader>x <Esc>`.``:exe line(".")==line("'.") && col(".") < col("'.") ? 'norm! :let c=col(".")<CR>gvp```]:let c=col(".")-c<CR>``:silent call cursor(line("."),col(".")+c)<CR>P' : "norm! gvp``P"<CR>

