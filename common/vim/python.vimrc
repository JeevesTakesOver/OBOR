
" _. Python {{{
Plug 'klen/python-mode'
Plug 'davidhalter/jedi-vim'
" Automatically sort python imports
Plug 'fisadev/vim-isort'

"Plug 'python.vim'
"Plug 'python_match.vim'
"Plug 'pythoncomplete'
"Plug 'ropevim'
" }}}

" Python and PHP Debugger
Plug 'fisadev/vim-debug.vim'

" disable default mappings, have a lot of conflicts with other plugins
let g:vim_debug_disable_mappings = 1
" add some useful mappings
map <F5> :Dbg over<CR>
map <F6> :Dbg into<CR>
map <F7> :Dbg out<CR>
map <F8> :Dbg here<CR>
map <F9> :Dbg break<CR>
map <F10> :Dbg watch<CR>
map <F11> :Dbg down<CR>
map <F12> :Dbg up<CR>

if has("autocmd")
  augroup python
    au BufReadPre,FileReadPre set kp=ri sw=4 ts=4 expandtab
    " Python-mode
    "" Activate rope
    " Keys:
    " K             Show python docs
    " <Ctrl-Space>  Rope autocomplete
    " <Ctrl-c>g     Rope goto definition
    " <Ctrl-c>d     Rope show documentation
    " <Ctrl-c>f     Rope find occurrences
    " <Leader>b     Set, unset breakpoint (g:pymode_breakpoint enabled)
    " [[            Jump on previous class or function (normal, visual, operator modes)
    " ]]            Jump on next class or function (normal, visual, operator modes)
    " [M            Jump on previous class or method (normal, visual, operator modes)
    " ]M            Jump on next class or method (normal, visual, operator modes)

    " enable all of python mode
    "let g:pymode = 1

    " don't load rope by default. Change to 1 to use rope
    let g:pymode_rope = 0
    " don't autoimport modules by default
    let g:pymode_rope_autoimport = 1
    let g:pymode_rope_autoimport_import_after_complete = 1

    " enable default options
    let g:pymode_options = 1

    " re-generate cache on every write
    let g:pymode_rope_regenerate_on_write = 0

    " http://unlogic.co.uk/2013/02/08/vim-as-a-python-ide/#comment-1703589179
    let g:pymode_rope_completion = 0
    let g:pymode_rope_vim_completion = 0

    " Documentation
    let g:pymode_doc = 1
    let g:pymode_doc_key = 'K'

    " change usages_command as it clashes with NerdTree
    let g:jedi#usages_command = "<leader>u"

    "Linting
    " don't use linter, we use syntastic for that
    let g:pymode_lint = 0
    let g:pymode_lint_checkers = ["pep8","pyflakes"]
    " Auto check on save
    let g:pymode_lint_write = 0

    " don't use linter, we use syntastic for that
    let g:pymode_lint_on_write = 0
    let g:pymode_lint_signs = 0

    " Support virtualenv
    let g:pymode_virtualenv = 1
    let g:pymode_virtualenv_path = 'venv'

    " Enable breakpoints plugin
    let g:pymode_breakpoint = 1
    let g:pymode_breakpoint_bind = '<leader>b'

    " syntax highlighting
    let g:pymode_syntax = 1
    let g:pymode_syntax_all = 1
    let g:pymode_syntax_indent_errors = g:pymode_syntax_all
    let g:pymode_syntax_space_errors = g:pymode_syntax_all

    " pep8-compatible python indent
    let g:pymode_indent = 1

    " autofold code on open
    let g:pymode_folding = 1


    " open definitions on same window, and custom mappings for definitions and
    " occurrences
    " Override go-to.definition key shortcut to Ctrl-]
    let g:pymode_rope_goto_definition_bind = "<C-]>"
    let g:pymode_rope_goto_definition_cmd = 'e'
    nmap ,D :tab split<CR>:PymodePython rope.goto()<CR>
    nmap ,o :RopeFindOccurrences<CR>

    " Override view python doc key shortcut to Ctrl-Shift-d
    let g:pymode_doc_bind = "<C-S-d>"


    " fix some issuews with python mode
    let g:pymode_rope_lookup_project = 1
    let g:pymode_rope = 1
    let g:pymode_rope_complete_on_dot = 1

    " autocmd FileType python setlocal omnifunc=RopeCompleteFunc


    "{{{{ python

    "Plugin 'davidhalter/jedi-vim'
    let g:jedi#use_tabs_not_buffers = 0
    let g:jedi#use_splits_not_buffers = "left"
    let g:jedi#show_call_signatures = "1"
    let g:jedi#popup_select_first = 1
    let g:jedi#popup_on_dot = 0
    ""end of python }}}}
  augroup END
endif
