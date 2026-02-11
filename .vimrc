" Note: Skip initialization for vim-tiny or vim-small.
if 0 | endif

" dein settings begin
if &compatible
  set nocompatible " Be iMproved
endif

" プラグインが実際にインストールされるディレクトリ
let s:dein_dir = expand('~/.vim/dein')
" dein.vim 本体
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

" dein.vim がなければ GitHub から落としてくる
if &runtimepath !~# '/dein.vim'
  if !isdirectory(s:dein_repo_dir)
    execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
  endif
  execute 'set runtimepath^=' . fnamemodify(s:dein_repo_dir, ':p')
endif

if dein#load_state(s:dein_dir)
  call dein#begin(s:dein_dir)
  source ~/.vim/.vimrc.dein
  call dein#end()
  call dein#save_state()
endif

if dein#check_install()
  call dein#install()
endif
" dein settings end

filetype plugin indent on

source ~/.vim/.vimrc.indent

set t_Co=256
set modelines=0		" Configuration file for vim CVE-2007-2438
set backspace=2		" more powerful backspacing
set number  " display row number
set cursorline
set cursorcolumn
set expandtab
set mouse=a " enable tap scroll
set wildmode=longest:full,full
set clipboard=unnamed,autoselect
set hlsearch
set autowrite
set updatetime=100
set encoding=utf-8

" Use English
if has("multi_lang")
  language C
endif

syntax on " enable syntax highlight

au BufNewFile,Bufread *.ru        set filetype=ruby
au BufNewFile,Bufread Gemfile     set filetype=ruby
au BufNewFile,Bufread Vagrantfile set filetype=ruby
au BufNewFile,BufRead *.jbuilder  set filetype=ruby
au BufNewFile,BufRead Guardfile   set filetype=ruby
au BufNewFile,BufRead .pryrc      set filetype=ruby

inoremap <silent> jj <ESC>
map <leader>r :QuickRun<CR>

" Don't write backup file if vim is being called by "crontab -e"
au BufWrite /private/tmp/crontab.* set nowritebackup nobackup

" Don't write backup file if vim is being called by "chpass"
au BufWrite /private/etc/pw.* set nowritebackup nobackup

" after :set paste, return preference automaticallly
autocmd InsertLeave * set nopaste
autocmd BufWritePre * :%s/\s\+$//ge

augroup HighlightTrailingSpaces
  autocmd!
  autocmd VimEnter,WinEnter,ColorScheme * highlight TrailingSpaces term=underline guibg=Red ctermbg=Red
  autocmd VimEnter,WinEnter * match TrailingSpaces /\s\+$/
augroup END

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

syntax enable
set background=dark
colorscheme solarized

