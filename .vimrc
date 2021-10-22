let g:currentmode={
     \ 'n'  : 'Normal',
     \ 'no' : 'Normal·Operator Pending',
     \ 'v'  : 'Visual',
     \ 'V'  : 'V·Line',
     \ "\<C-V>" : 'V·Block',
     \ 's'  : 'Select',
     \ 'S'  : 'S·Line',
     \ "\<C-S>" : 'S·Block',
     \ 'i'  : 'Insert',
     \ 'R'  : 'Replace',
     \ 'Rv' : 'V·Replace',
     \ 'c'  : 'Command',
     \ 'cv' : 'Vim Ex',
     \ 'ce' : 'Ex',
     \ 'r'  : 'Prompt',
     \ 'rm' : 'More',
     \ 'r?' : 'Confirm',
     \ '!'  : 'Shell',
     \ 't'  : 'Terminal'
     \}

set title
syntax on
highlight LineNr term=bold cterm=NONE ctermfg=DarkGrey ctermbg=NONE gui=NONE guifg=DarkGrey guibg=NONE
set tabstop=4
set number
set hlsearch
set laststatus=2
set noshowmode
set statusline=
set statusline+=%0*\ %n\                                 " Buffer number
set statusline+=%1*\ %<%F%m%r%h%w\                       " File path, modified, readonly, helpfile, preview
set statusline+=%3*â                                     " Separator
set statusline+=%2*\ %Y\                                 " FileType
set statusline+=%3*â                                     " Separator
set statusline+=%2*\ %{''.(&fenc!=''?&fenc:&enc).''}     " Encoding
set statusline+=\ (%{&ff})                               " FileFormat (dos/unix..)
set statusline+=%=                                       " Right Side
set statusline+=%2*\ col:\ %02v\                         " Column number
set statusline+=%3*â                                     " Separator
set statusline+=%1*\ ln:\ %02l/%L\ (%3p%%)\              " Line number / total lines, percentage of document
set statusline+=%0*\ %{toupper(g:currentmode[mode()])}\  " The current mode

hi User1 ctermfg=007 ctermbg=239 guibg=#4e4e4e guifg=#adadad 
hi User2 ctermfg=007 ctermbg=236 guibg=#303030 guifg=#adadad
hi User3 ctermfg=236 ctermbg=236 guibg=#303030 guifg=#303030
hi User4 ctermfg=239 ctermbg=239 guibg=#4e4e4e guifg=#4e4e4e
