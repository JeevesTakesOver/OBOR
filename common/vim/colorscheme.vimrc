
" download all color files
if !filereadable(expand("~/.vim/colors/elive.vim"))
    silent !mkdir -p ~/.vim/colors
    silent !curl -fLo ~/.vim/colors/elive.vim https://raw.githubusercontent.com/Elive/vim-colorscheme-elive/master/colors/elive.vim
endif

if !filereadable(expand("~/.vim/colors/hybrid.vim"))
    silent !mkdir -p ~/.vim/colors
    silent !curl -fLo ~/.vim/colors/hybrid.vim https://raw.githubusercontent.com/w0ng/vim-hybrid/master/colors/hybrid.vim
endif

if !filereadable(expand("~/.vim/colors/neverland-darker.vim"))
    silent !mkdir -p ~/.vim/colors
    silent !curl -fLo ~/.vim/colors/neverland-darker.vim https://raw.githubusercontent.com/trapd00r/neverland-vim-theme/master/colors/neverland-darker.vim
endif

if !filereadable(expand("~/.vim/colors/candycode.vim"))
    silent !mkdir -p ~/.vim/colors
    silent !curl -fLo ~/.vim/colors/candycode.vim http://www.vim.org/scripts/download_script.php?src_id=6066
endif

if !filereadable(expand("~/.vim/colors/onedark.vim"))
    silent !mkdir -p ~/.vim/colors
    silent !curl -fLo ~/.vim/colors/onedark.vim https://raw.githubusercontent.com/joshdick/onedark.vim/master/colors/onedark.vim
endif

if !filereadable(expand("~/.vim/colors/atom-dark-256.vim"))
    silent !mkdir -p ~/.vim/colors
    silent !curl -fLo ~/.vim/colors/atom-dark-256.vim https://raw.githubusercontent.com/gosukiwi/vim-atom-dark/master/colors/atom-dark-256.vim
endif

if !filereadable(expand("~/.vim/colors/calmar256-light.vim"))
    silent !mkdir -p ~/.vim/colors
    silent !curl -fLo ~/.vim/colors/calmar256-light.vim http://www.calmar.ws/dotfiles/dotfiledir/calmar256-light.vim
endif

if !filereadable(expand("~/.vim/colors/literal_tango.vim"))
    silent !mkdir -p ~/.vim/colors
    silent !curl -fLo ~/.vim/colors/literal_tango.vim http://www.vim.org/scripts/download_script.php?src_id=10374
endif

if !filereadable(expand("~/.vim/colors/mustang.vim"))
    silent !mkdir -p ~/.vim/colors
    silent !curl -fLo ~/.vim/colors/mustang.vim https://raw.githubusercontent.com/croaker/mustang-vim/master/colors/mustang.vim
endif


"this colorscheme uses a white on black background with the tango pallete
set background=dark
set t_Co=256
colorscheme hybrid


" set keyboard to change colorscheme
nnoremap <Leader>csd1 :set background=dark<Cr>:colorscheme default<Cr>:colorscheme elive<Cr>
nnoremap <Leader>csd2 :set background=dark<Cr>:colorscheme default<Cr>:colorscheme neverland-darker<Cr>
nnoremap <Leader>csd3 :set background=dark<Cr>:colorscheme default<Cr>:colorscheme hybrid<Cr>
nnoremap <Leader>csd4 :set background=dark<Cr>:colorscheme default<Cr>:colorscheme candycode<Cr>
nnoremap <Leader>csd5 :set background=dark<Cr>:colorscheme default<Cr>:colorscheme onedark<Cr>
nnoremap <Leader>csd6 :set background=dark<Cr>:colorscheme default<Cr>:colorscheme atom-dark-256<Cr>

nnoremap <Leader>csl1 :set background=light<Cr>:colorscheme default<Cr>:colorscheme hybrid-light<Cr>
nnoremap <Leader>csl2 :set background=light<Cr>:colorscheme default<Cr>:colorscheme calmar256-light<Cr>
nnoremap <Leader>csl3 :set background=light<Cr>:colorscheme default<Cr>:colorscheme literal_tango<Cr>
nnoremap <Leader>csl4 :set background=light<Cr>:colorscheme default<Cr>:colorscheme azul<Cr>
nnoremap <Leader>csl5 :set background=light<Cr>:colorscheme default<Cr>:colorscheme bw<Cr>
