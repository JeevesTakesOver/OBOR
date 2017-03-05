
" _. Haskell {{{
Plug 'Twinside/vim-syntax-haskell-cabal'
Plug 'lukerandall/haskellmode-vim'

au BufEnter *.hs compiler ghc

let g:ghc = "/usr/local/bin/ghc"
let g:haddock_browser = "open"
" }}}
