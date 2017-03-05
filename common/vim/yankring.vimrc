
Plug 'vim-scripts/YankRing.vim'
Plug 'jaredly/vim-debug'

if !isdirectory($HOME.'/.vim/tmp')
  call mkdir($HOME.'/.vim/tmp', 'p')
endif

let g:yankring_replace_n_pkey = '<leader>['
let g:yankring_replace_n_nkey = '<leader>]'
let g:yankring_history_dir = '~/.vim/tmp/'

"map leader,yrs to yankring show
nmap <leader>yrs :YRShow<cr>
