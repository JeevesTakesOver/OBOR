
Plug 'davidhalter/jedi-vim'

let g:jedi#use_tabs_not_buffers = 0
let g:jedi#use_splits_not_buffers = "left"
let g:jedi#show_call_signatures = "1"
let g:jedi#popup_select_first = 1
let g:jedi#popup_on_dot = 1

" https://github.com/davidhalter/jedi-vim/issues/685#issuecomment-291632671
Plug 'jmcantrell/vim-virtualenv'
" in your plugin constants configuration section
let g:virtualenv_auto_activate = 1
let g:virtualenv_directory = 'venv'


if has("autocmd")
  augroup python
    au BufReadPre,FileReadPre set kp=ri sw=4 ts=4 expandtab
    au FileType python set omnifunc=jedi#completions
  augroup END
endif
