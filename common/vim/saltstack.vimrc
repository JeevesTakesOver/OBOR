Plug 'saltstack/salt-vim'

" Force using the Jinja template syntax file
let g:sls_use_jinja_syntax = 1

if !filereadable(expand("~/.vim/snippets/vim-snippets-salt/.done"))
    silent !mkdir -p ~/.vim/snippets
    silent !git clone https://github.com/StephenPCG/vim-snippets-salt ~/.vim/snippets/vim-snippets-salt
    silent !git clone -b v0.17.5 https://github.com/saltstack/salt.git ~/.vim/snippets/vim-snippets-salt/salt-source-code
    silent !virtualenv ~/.vim/snippets/vim-snippets-salt/salt-venv
    silent !~/.vim/snippets/vim-snippets-salt/salt-venv/bin/pip install --index-url=http://pypi.python.org/simple/ --trusted-host pypi.python.org pyaml
    silent !~/.vim/snippets/vim-snippets-salt/salt-venv/bin/pip install --index-url=http://pypi.python.org/simple/ --trusted-host pypi.python.org msgpack-python
    silent !~/.vim/snippets/vim-snippets-salt/salt-venv/bin/pip install --index-url=http://pypi.python.org/simple/ --trusted-host pypi.python.org Jinja2
    silent !~/.vim/snippets/vim-snippets-salt/salt-venv/bin/pip install --index-url=http://pypi.python.org/simple/ --trusted-host pypi.python.org pycrypto
    silent !~/.vim/snippets/vim-snippets-salt/salt-venv/bin/pip install --index-url=http://pypi.python.org/simple/ --trusted-host pypi.python.org markupsafe
    "silent !~/.vim/snippets/vim-snippets-salt/salt-venv/bin/pip install --index-url=http://pypi.python.org/simple/ --trusted-host pypi.python.org  -r ~/.vim/snippets/vim-snippets-salt/salt-source-code/requirements.txt
    silent !~/.vim/snippets/vim-snippets-salt/salt-venv/bin/python2.7 ~/.vim/snippets/vim-snippets-salt/gen-snippets.py  -p ~/.vim/snippets/vim-snippets-salt/salt-source-code
    silent !touch ~/.vim/snippets/vim-snippets-salt/.done
endif

