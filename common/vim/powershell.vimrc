Plug 'PProvost/vim-ps1'
if has("autocmd")
  augroup powershell
      au BufReadPre,FileReadPre *.ps1 set filetype=ps1
      au BufNewFile,BufRead *.ps1 set filetype=ps1
  augroup END
endif
