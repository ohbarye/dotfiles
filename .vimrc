" Note: Skip initialization for vim-tiny or vim-small.
if 0 | endif

" Neobundle settings begin
if has('vim_starting')
  set runtimepath+=~/.vim/neobundle.vim/

  call neobundle#begin(expand('~/.vim/bundle'))
  source ~/.vim/.vimrc.bundle
  call neobundle#end()

endif
" Neobundle settings end

" Required:
filetype plugin indent on

source ~/.vim/.vimrc.indent

set modelines=0		" Configuration file for vim CVE-2007-2438
set backspace=2		" more powerful backspacing
set number  " display row number
set cursorline
set cursorcolumn
set expandtab
set mouse=a " enable tap scroll
set wildmode=longest:full,full

syntax on " enable syntax highlight

au BufNewFile,Bufread *.ru        set filetype=ruby
au BufNewFile,Bufread Gemfile     set filetype=ruby
au BufNewFile,Bufread Vagrantfile set filetype=ruby
au BufNewFile,BufRead *.jbuilder  set filetype=ruby
au BufNewFile,BufRead Guardfile   set filetype=ruby
au BufNewFile,BufRead .pryrc      set filetype=ruby

inoremap <silent> jj <ESC>

" Don't write backup file if vim is being called by "crontab -e"
au BufWrite /private/tmp/crontab.* set nowritebackup nobackup

" Don't write backup file if vim is being called by "chpass"
au BufWrite /private/etc/pw.* set nowritebackup nobackup

" after :set paste, return preference automaticallly
autocmd InsertLeave * set nopaste

set noswapfile

" set paste
if &term =~ "xterm"
    let &t_ti .= "\e[?2004h"
    let &t_te .= "\e[?2004l"
    let &pastetoggle = "\e[201~"

    function XTermPasteBegin(ret)
        set paste
        return a:ret
    endfunction

    noremap <special> <expr> <Esc>[200~ XTermPasteBegin("0i")
    inoremap <special> <expr> <Esc>[200~ XTermPasteBegin("")
    cnoremap <special> <Esc>[200~ <nop>
    cnoremap <special> <Esc>[201~ <nop>
endif
