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
" ## added by OPAM user-setup for vim / base ## 93ee63e278bdfc07d1139a748ed3fff2 ## you can edit, but keep this line
let s:opam_share_dir = system("opam config var share")
let s:opam_share_dir = substitute(s:opam_share_dir, '[\r\n]*$', '', '')

let s:opam_configuration = {}

function! OpamConfOcpIndent()
  execute "set rtp^=" . s:opam_share_dir . "/ocp-indent/vim"
endfunction
let s:opam_configuration['ocp-indent'] = function('OpamConfOcpIndent')

function! OpamConfOcpIndex()
  execute "set rtp+=" . s:opam_share_dir . "/ocp-index/vim"
endfunction
let s:opam_configuration['ocp-index'] = function('OpamConfOcpIndex')

function! OpamConfMerlin()
  let l:dir = s:opam_share_dir . "/merlin/vim"
  execute "set rtp+=" . l:dir
endfunction
let s:opam_configuration['merlin'] = function('OpamConfMerlin')

let s:opam_packages = ["ocp-indent", "ocp-index", "merlin"]
let s:opam_check_cmdline = ["opam list --installed --short --safe --color=never"] + s:opam_packages
let s:opam_available_tools = split(system(join(s:opam_check_cmdline)))
for tool in s:opam_packages
  " Respect package order (merlin should be after ocp-index)
  if count(s:opam_available_tools, tool) > 0
    call s:opam_configuration[tool]()
  endif
endfor
let g:opamshare = substitute(system('opam config var share'),'\n$','','''')
execute "set rtp+=" . g:opamshare . "/merlin/vim"
" ## end of OPAM user-setup addition for vim / base ## keep this line
