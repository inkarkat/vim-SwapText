SWAP TEXT
===============================================================================
_by Ingo Karkat_

DESCRIPTION
------------------------------------------------------------------------------

Swapping text areas when there's other text in between (e.g. function
arguments separated by other arguments) is done frequently, yet cumbersome.
One way to do this is by deleting A, selecting B, pasting over it, then going
back to where A used to be and pasting the original B.

This plugin lets you exchange the current selection / line / text covered by a
motion with the previously deleted text, with a short and simple mapping. The
swap can be undone as a single action.

### SOURCE

Based on vimtip #470: Map to quickly swap/exchange arbitrary text by Piet
- [Delport and an enhancement by ad\_scriven@postmaster.co.uk.](http://vim.wikia.com/wiki/Swapping_characters,_words_and_lines)

### SEE ALSO

- The LineJuggler.vim plugin ([vimscript #4140](http://www.vim.org/scripts/script.php?script_id=4140)) provides [E / ]E mappings to
  swap lines / the selection with the same amount of visible lines located
  [count] above / below.
- The LineJugglerCommands.vim plugin ([vimscript #4465](http://www.vim.org/scripts/script.php?script_id=4465)) provides swapping of
  ranges as an Ex :Swap command.

### RELATED WORKS

- visswap.vim (http://www.drchip.org/astronaut/vim/vbafiles/visswap.vba.gz)
  uses a visual selection, &lt;C-y&gt;, another selection, &lt;C-x&gt; to swap the two.
- swapstrings.vim (http://www.drchip.org/astronaut/vim/#SWAPSTRINGS) can swap
  all instances of two strings in a range.
- swap.vim ([vimscript #3250](http://www.vim.org/scripts/script.php?script_id=3250)) can swap around a pivot (e.g. ==) or to WORDs to
  the left / right with &lt;Leader&gt;x / &lt;Leader&gt;X.
- exchange (https://github.com/tommcdo/vim-exchange) defines a cx{motion}
  operator that has to be used twice to exchange the first with the second
  one.

USAGE
------------------------------------------------------------------------------

    First, delete some text (using any normal Vim command, such as "daw",
    {Visual}x, or "dt"). Then, visually select some other text, and press
    <Leader>x, or use the custom operator <Leader>x{motion}. The two pieces of
    text should now be swapped.

    {Visual}<Leader>x       Swap the visual selection with the just deleted text.
    <Leader>x{motion}       Swap the characters covered by {motion} with the just
                            deleted text.
    [count]<Leader>xx       Swap the current [count] line(s) with the just deleted
                            text.
    [count]<Leader>X        Swap the characters under the cursor until the end of
                            the line and [count]-1 more lines with the just
                            deleted text.

INSTALLATION
------------------------------------------------------------------------------

The code is hosted in a Git repo at
    https://github.com/inkarkat/vim-SwapText
You can use your favorite plugin manager, or "git clone" into a directory used
for Vim packages. Releases are on the "stable" branch, the latest unstable
development snapshot on "master".

This script is also packaged as a vimball. If you have the "gunzip"
decompressor in your PATH, simply edit the \*.vmb.gz package in Vim; otherwise,
decompress the archive first, e.g. using WinZip. Inside Vim, install by
sourcing the vimball or via the :UseVimball command.

    vim SwapText*.vmb.gz
    :so %

To uninstall, use the :RmVimball command.

### DEPENDENCIES

- Requires Vim 7.0 or higher.
- Requires the ingo-library.vim plugin ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)), version 1.042 or
  higher.

LIMITATIONS
------------------------------------------------------------------------------

- Unless :set virtualedit=all, swapping the last characters in a line will
  insert one character short of where the insert should be. This only
  happens when you swap FROM the last characters in a line to somewhere else.
  If you swap TO (in the natural left-to-right editing order) the last
  characters in a line, everythings works fine.

### KNOWN PROBLEMS

- Offset correction only works when the entire swap-to text is inside one
  line.

### CONTRIBUTING

Report any bugs, send patches, or suggest features via the issue tracker at
https://github.com/inkarkat/vim-SwapText/issues or email (address below).

HISTORY
------------------------------------------------------------------------------

##### 1.03    13-Nov-2024
- Adapt: Plugin broken since Vim 8.2.4242 (put in Visual mode cannot be
  repeated); need to use v\_p instead of v\_P command now.
- Adapt: Detection of deletion at the end of the line broken since Vim
  8.2.0324; implement workaround to handle all Vim versions.

__You need to update to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.042!__

##### 1.02    19-Sep-2016
- "E790: undojoin is not allowed after undo" may also be raised in
  SwapText#Operator(); ignore it.
- BUG: When deleting at the end of a line, and swapping with a longer text
  before it, the swap location is off by one. The EOL position isn't properly
  detected, because the virtual line length after the paste is used in the
  condition. Save the deleted virtual line length in deletedVirtLen, and pass
  that on to s:WasDeletionAtEndOfLine(). Thanks to Marcelo Montu for the bug
  report.

##### 1.01    22-Jul-2014
- BUG: &lt;Leader&gt;X includes the newline unless :set selection=exclusive. Thanks
  to Enno Nagel for reporting this.

##### 1.00    24-Jun-2014
- First published version.

##### 0.01    06-Jun-2007
- Started development based on vimtip #470: Map to quickly swap/exchange
arbitrary text by Piet Delport and an enhancement by
ad\_scriven@postmaster.co.uk.

------------------------------------------------------------------------------
Copyright: (C) 2007-2024 Ingo Karkat -
The [VIM LICENSE](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) applies to this plugin.

Maintainer:     Ingo Karkat &lt;ingo@karkat.de&gt;
