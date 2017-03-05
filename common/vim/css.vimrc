
" _. CSS {{{
Plug 'wavded/vim-stylus'
Plug 'lunaru/vim-less'
nnoremap ,m :w <BAR> !lessc % > %:t:r.css<CR><space>
" }}}
