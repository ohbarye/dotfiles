" Note: Skip initialization for vim-tiny or vim-small.
if 0 | endif

" neobundle settings
if has('vim_starting')
  if &compatible
    set nocompatible               " Be iMproved
  endif

  " Required:
  set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

" Required:
call neobundle#begin(expand('~/.vim/bundle'))

" Let NeoBundle manage NeoBundle
" Required:
NeoBundleFetch 'Shougo/neobundle.vim'

let g:neobundle#types#git#default_protocol = 'git'

" 連続で行うような操作をサブモジュールとして登録できるPlugin
NeoBundle 'kana/vim-submode'

" 様々なデータを共通のインタフェースを用いて操作できるPlugin
NeoBundle 'Shougo/unite.vim'
" unite {{{
let g:unite_enable_start_insert=1
nmap <silent> <C-u><C-b> :<C-u>Unite buffer<CR>
nmap <silent> <C-u><C-f> :<C-u>UniteWithBufferDir -buffer-name=files file<CR>
nmap <silent> <C-u><C-r> :<C-u>Unite -buffer-name=register register<CR>
nmap <silent> <C-u><C-m> :<C-u>Unite file_mru<CR>
nmap <silent> <C-u><C-u> :<C-u>Unite buffer file_mru<CR>
nmap <silent> <C-u><C-a> :<C-u>UniteWithBufferDir -buffer-name=files buffer file_mru bookmark file<CR>
au FileType unite nmap <silent> <buffer> <expr> <C-j> unite#do_action('split')
au FileType unite imap <silent> <buffer> <expr> <C-j> unite#do_action('split')
au FileType unite nmap <silent> <buffer> <expr> <C-l> unite#do_action('vsplit')
au FileType unite imap <silent> <buffer> <expr> <C-l> unite#do_action('vsplit')
au FileType unite nmap <silent> <buffer> <ESC><ESC> q
au FileType unite imap <silent> <buffer> <ESC><ESC> <ESC>q
" }}}

NeoBundle 'Shougo/neomru.vim', {
  \ 'depends' : 'Shougo/unite.vim'
  \ }

" colorscheme集
NeoBundle 'flazz/vim-colorschemes'

" 非同期処理を実施するために必要なvim用のplugin(環境ごとに自動build)
NeoBundle 'Shougo/vimproc', {
          \ 'build' : {
          \     'windows' : 'make -f make_mingw32.mak',
          \     'cygwin' : 'make -f make_cygwin.mak',
          \     'mac' : 'make -f make_mac.mak',
          \     'unix' : 'make -f make_unix.mak',
          \    },
          \ }
" ファイルを検索して開くためのplugin
NeoBundle 'kien/ctrlp.vim'

" vim内でshellを動作させるplugin
NeoBundle 'Shougo/vimshell'

" vim上でgit操作するplugin
NeoBundle 'tpope/vim-fugitive'
NeoBundle 'gregsexton/gitv.git'
if has("lua")
  " 入力補完plugin  
  NeoBundleLazy 'Shougo/neocomplete', { 'autoload' : {
       \ 'depends' : 'Shougo/vimproc',
       \   'insert' : 1,
       \ }}
endif

" 言語用のsnippet plugin
NeoBundle 'Shougo/neosnippet.vim'
NeoBundle 'Shougo/neosnippet-snippets'
NeoBundle 'honza/vim-snippets'
" Enable snipMate compatibility feature.
let g:neosnippet#enable_snipmate_compatibility = 1"  
"  " Tell Neosnippet about the other snippets
let g:neosnippet#snippets_directory='~/.vim/bundle/vim-snippets/snippets'

" uniteでtagsを読み込みます
NeoBundleLazy 'tsukkee/unite-tag', {
      \ 'depends' : ['Shougo/unite.vim'],
      \ 'autoload' : {
      \   'unite_sources' : ['tag', 'tag/file', 'tag/include']
      \ }}

" ファイルの構文エラーなどを表示するPlugin
" この場合はjs,rubyをsave時に動作させてます。
NeoBundle 'scrooloose/syntastic'
let g:syntastic_check_on_open=0 "ファイルを開いたときはチェックしない
let g:syntastic_check_on_save=1 "保存時にはチェック
let g:syntastic_check_on_wq = 0 " wqではチェックしない
let g:syntastic_auto_loc_list=1 "エラーがあったら自動でロケーションリストを開く
let g:syntastic_loc_list_height=6 "エラー表示ウィンドウの高さ
set statusline+=%#warningmsg# "エラーメッセージの書式
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_javascript_checkers = ['eslint'] "ESLintを使う
let g:syntastic_ruby_checkers = ['rubocop']
let g:syntastic_mode_map = {
      \ 'mode': 'active',
      \ 'active_filetypes': ['javascript', 'ruby'],
      \ 'passive_filetypes': []
      \ }

" html,css用
NeoBundle 'hail2u/vim-css3-syntax'
" NeoBundle 'taichouchou2/html5.vim'
NeoBundle 'othree/html5.vim'

" zencoding-vimの後継
NeoBundle 'mattn/emmet-vim'
" "html展開した時のlangをjaに
let g:user_emmet_settings = {
\ 'lang' : 'ja'
\}

" wordを決まったwordに変換するPlugin
NeoBundle 'AndrewRadev/switch.vim'

" vimからagを利用できるようにするPlugin
NeoBundle 'rking/ag.vim'

" ディレクトリ構造をtree表示するPlugin
NeoBundle 'scrooloose/nerdtree'
" autocmd VimEnter * execute 'NERDTree'
" F2でtree表示/非表示にする
nnoremap <f2> :NERDTreeToggle<CR>
""tree表示だけの場合は一緒に閉じる
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif
" 不可視ファイルをデファルトで表示
let NERDTreeShowHidden = 1
" タグリストを表示するPlugin
NeoBundleLazy "majutsushi/tagbar", {
      \ "autoload": { "commands": ["TagbarToggle"] }}
let g:tlist_js_settings = 'javascript;f:function;v:variable'
if ! empty(neobundle#get("tagbar"))
  nmap <F8> :TagbarToggle<CR>
endif

" 日付をインクリメントしたら、数値をまとめてインクリメントしたりするPlugin
NeoBundle 'tpope/vim-speeddating'

" vimからDBを扱うPlugin
NeoBundle 'vim-scripts/dbext.vim'

" JSDocを生成(<C-l>) 
NeoBundleLazy 'heavenshell/vim-jsdoc' , {'autoload': {'filetypes': ['javascript']}}

" Ruby 用

" refを参照できるようにするPlugin
NeoBundleLazy 'yuku-t/vim-ref-ri', {
      \ 'depends': ['Shougo/unite.vim', 'thinca/vim-ref'],
      \ 'autoload': { 'filetypes': ['ruby', 'eruby', 'haml'] } }

" endを自動補完するplugin
NeoBundleLazy 'alpaca-tc/vim-endwise.git', {
      \ 'autoload' : {
      \   'insert' : 1,
      \ }}

" ファイルの構文エラーなどを表示するPlugin
" この場合はRubyをsave時にrubocopを動作させてます。
"NeoBundle 'scrooloose/syntastic'
"let g:syntastic_mode_map = { 'mode': 'passive',
"            \ 'active_filetypes': ['ruby'] }
"let g:syntastic_ruby_checkers = ['rubocop']

" railsのファイル移動をコマンド移動するplugin
NeoBundle 'tpope/vim-rails', { 'autoload' : {
      \ 'filetypes' : ['haml', 'ruby', 'eruby'] }}
      
" railsのファイル種類ごとに一覧を表示する
NeoBundleLazy 'basyura/unite-rails', {
      \ 'depends' : 'Shougo/unite.vim',
      \ 'autoload' : {
      \   'unite_sources' : [
      \     'rails/bundle', 'rails/bundled_gem', 'rails/config',
      \     'rails/controller', 'rails/db', 'rails/destroy', 'rails/features',
      \     'rails/gem', 'rails/gemfile', 'rails/generate', 'rails/git', 'rails/helper',
      \     'rails/heroku', 'rails/initializer', 'rails/javascript', 'rails/lib', 'rails/log',
      \     'rails/mailer', 'rails/model', 'rails/rake', 'rails/route', 'rails/schema', 'rails/spec',
      \     'rails/stylesheet', 'rails/view'
      \   ]
      \ }}

NeoBundle 'kchmck/vim-coffee-script'
au BufRead,BufNewFile,BufReadPre *.coffee   set filetype=coffee
" インデント設定
autocmd FileType coffee    setlocal sw=2 sts=2 ts=2 et

"NeoBundleLazy 'alpaca-tc/neorspec.vim', {
"      \ 'depends' : ['alpaca-tc/vim-rails', 'tpope/vim-dispatch'],
"      \ 'autoload' : {
"      \   'commands' : ['RSpec', 'RSpecAll', 'RSpecCurrent', 'RSpecNearest', 'RSpecRetry']
"      \ }}
"
"NeoBundleLazy 'alpaca-tc/alpaca_tags', {
"      \ 'depends': 'Shougo/vimproc',
"      \ 'autoload' : {
"      \   'commands': ['TagsUpdate', 'TagsSet', 'TagsBundle']
"      \ }}

call neobundle#end()

" Required:
filetype plugin indent on

" If there are uninstalled bundles found on startup,
" this will conveniently prompt you to install them.
NeoBundleCheck

" Configuration file for vim
set modelines=0		" CVE-2007-2438

" Normally we use vim-extensions. If you want true vi-compatibility
" remove change the following statements
set nocompatible	" Use Vim defaults instead of 100% vi compatibility
set backspace=2		" more powerful backspacing
" 行番号を表示する
set number
" 構文ハイライト
syntax on
inoremap <silent> jj <ESC>

" Don't write backup file if vim is being called by "crontab -e"
au BufWrite /private/tmp/crontab.* set nowritebackup nobackup
" Don't write backup file if vim is being called by "chpass"
au BufWrite /private/etc/pw.* set nowritebackup nobackup

colorscheme jellybeans

set cursorline
set cursorcolumn

set tabstop=2
set expandtab
set shiftwidth=2
