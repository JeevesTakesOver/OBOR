Plug 'LnL7/vim-nix'

" this will define the correct maintainers line in meta tags:
let g:nix_maintainer="Azulinho"

if has("autocmd")
  augroup nix
    au BufReadPre,FileReadPre *.nix setl ft=nix
    au BufNewFile,BufReadPost *.nix setl ft=nix
    "set background=dark
    "colorscheme default
    "colorscheme elive
  augroup END
endif
