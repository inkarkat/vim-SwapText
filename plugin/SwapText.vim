" SwapText.vim: Mappings to exchange text with the previously deleted text. 
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher. 
"   - SwapText.vim autoload script. 
"
" Copyright: (C) 2007-2011 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
" Source: Based on vimtip #470: Map to quickly swap/exchange arbitrary text by
"	  Piet Delport and an enhancement by ad_scriven@postmaster.co.uk. 
"
" REVISION	DATE		REMARKS 
"	014	17-Nov-2011	Split off separate autoload script and
"				documentation. 
"	001	06-Jun-2007	file creation

" Avoid installing twice or when in unsupported Vim version. 
if exists('g:loaded_SwapText') || (v:version < 700)
    finish
endif
let g:loaded_SwapText = 1

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
