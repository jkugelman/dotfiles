" Enable syntax highlighting.
syntax on
hi Comment ctermfg=darkgray
hi LineNr ctermfg=darkblue
hi CursorColumn ctermbg=darkblue

" Show line numbers.
"set number

" Always show the current file name.
set laststatus=2

" Disable swap files.
set uc=0

" Jump to the last known cursor position.
if has("autocmd")
    au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
endif

" Automatically reload files that have changed.
set autoread

" Trigger `autoread` when files change on disk.
" <https://unix.stackexchange.com/questions/149209/refresh-changed-content-of-file-opened-in-vim/383044#383044>
" <https://vi.stackexchange.com/questions/13692/prevent-focusgained-autocmd-running-in-command-line-editing-mode>
autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * if mode() != 'c' | checktime | endif
" Notification after file change.
" <https://vi.stackexchange.com/questions/13091/autocmd-event-for-autoread>
autocmd FileChangedShellPost *
  \ echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None

" Store undo history across vim invocations.
if has('persistent_undo')
    set undofile
    set undodir=~/.vimundo//,/var/tmp//,/tmp//,.
endif

" Allow backspace and delete to delete line wraps, and allow cursor to move
" between lines with LEFT and RIGHT arrows.
set ww=b,s,<,>

" Move up and down across display lines, not physical lines.
nnoremap j gj
nnoremap k gk
vnoremap j gj
vnoremap k gk
nnoremap <Down> gj
nnoremap <Up> gk
vnoremap <Down> gj
vnoremap <Up> gk
inoremap <Down> <C-o>gj
inoremap <Up> <C-o>gk

" Incremental search. F7 to disable highlighting.
set incsearch
set hlsearch
nnoremap <F7> :nohl<Enter>

" Show ruler.
set ruler

" Try to keep 2 lines above/below the current line in view for context.
set scrolloff=2

" Other file types.
autocmd BufReadPre,BufNew *.xml    set filetype=xml
autocmd BufReadPre,BufNew *.fxml   set filetype=xml
autocmd BufReadPre,BufNew SCons*   set filetype=python
autocmd BufReadPre,BufNew ex*.log  set filetype=iislog
autocmd BufReadPre,BufNew *.gradle set filetype=groovy

" Flag problematic whitespace (trailing spaces, spaces before tabs).
let c_space_errors=1
let c_no_trail_space_error=1
let java_space_errors=1
let java_no_trail_space_error=1
let python_highlight_space_errors=1

highlight BadWhitespace term=standout ctermbg=red guibg=red
match BadWhitespace /[^* \t]\zs\s\+$\| \+\ze\t/

" If using ':set list' show things nicer.
execute 'set listchars=tab:' . nr2char(187) . '\ '
set list
highlight Tab ctermfg=lightgray guifg=lightgray
2match Tab /\t/

" Allow backspacing over auto-indent and line breaks.
set backspace=indent,eol,start

" Default indentation settings: 4 spaces, do not use tab character.
set tabstop=8 shiftwidth=4 autoindent shiftround
set expandtab softtabstop=4

" Use same indentation characters as previous lines.
set preserveindent
set copyindent

" Customize C/C++/Java/JS formatting.
set cinoptions=l1,g0,(s,L0,U1,Ws,j1,J1,#1

" Indent <script> and <style> blocks in HTML.
let html_indent_script1 = "inc"
let html_indent_style1 = "inc"

" Automatically show matching brackets.
set showmatch

" Auto-complete file names after <TAB> like bash does.
set wildmode=longest,list
set wildignore=.svn,CVS,*.swp

" Show current mode and currently-typed command.
set showmode
set showcmd

" Use mouse if possible.
" set mouse=a

" Confirm saving and quitting.
set confirm

" Fix Ctrl-Left and Ctrl-Right in screen.
set <C-Left>=[1;5D
set <C-Right>=[1;5C

" So yank behaves like delete, i.e. Y = D.
map Y y$

" Toggle paste mode with F5.
set pastetoggle=<F5>

" Don't exit visual mode when shifting.
vnoremap < <gv
vnoremap > >gv

" Move up and down by visual lines not buffer lines.
nnoremap <Up>   gk
vnoremap <Up>   gk
nnoremap <Down> gj
vnoremap <Down> gj

" Customize syntax highlighting.
let java_highlight_functions="style"
let java_allow_cpp_keywords=1

let python_highlight_all=1

let sql_type_default="mysql"

autocmd BufRead,BufNewFile *.m4 hi link m4Custom   Special
autocmd BufRead,BufNewFile *.m4 hi link m4Constant Special
autocmd BufRead,BufNewFile *.m4 syn region m4Command  matchgroup=m4Type start="\<m4_\(\w*\)("he=e-1 end=")" contains=@m4Top
autocmd BufRead,BufNewFile *.m4 syn match  m4Constant "\<M4_\([a-zA-Z0-9_]*\)"

" Tab navigation.
nnoremap <C-N> :tabnext<Enter>
nnoremap <C-P> :tabprev<Enter>
nnoremap <C-T> :tabnew<Enter>
nnoremap <C-D> :tabclose<Enter>

" Enable modelines even for root.
set modeline

" Don't add '.' to the 'iskeyword' list of characters that w, e, etc., use.
let g:sh_noisk=1


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Load plugins with vim-plug. See ~/.vim/autoload/plug.vim and
" <https://github.com/junegunn/vim-plug>.
"
" Run :PlugUpdate to install and/or update plugins.

call plug#begin()

" This plugin automatically adjusts 'shiftwidth' and 'expandtab' heuristically
" based on the current file, or, in the case the current file is new, blank, or
" otherwise insufficient, by looking at other files of the same type in the
" current and parent directories. In lieu of adjusting 'softtabstop', 'smarttab'
" is enabled.
"
" Compare to DetectIndent. I wrote this because I wanted something fully
" automatic. My goal is that by installing this plugin, you can remove all
" indenting related configuration from your vimrc.
Plug 'tpope/vim-sleuth'

" Surround.vim is all about 'surroundings': parentheses, brackets, quotes, XML
" tags, and more. The plugin provides mappings to easily delete, change and add
" such surroundings in pairs.
"
"     cs"'       Change surrounding " to '
"     cs'<q>     Change surrounding ' to <q></q>
"     cst"       Change surrounding <q> to '
"
"     ysiw]      Surround word with [brackets]
"     cs]{       Change [word] to { word } (use `}` instead of `{` for no
"                    spaces)
Plug 'tpope/vim-surround'

" If you've ever tried using the `.` command after a plugin map, you were likely
" disappointed to discover it only repeated the last native command inside that
" map, rather than the map as a whole. That disappointment ends today.
" Repeat.vim remaps `.` in a way that plugins can tap into it.
Plug 'tpope/vim-repeat'

" Intellisense engine for Vim8 & Neovim, full language server protocol support
" as VSCode.
"
" Run `:CocInstall coc-rust-analyzer` to add Rust support.
"
" COC requires Vim >= 8.1.1719.
if has('nvim-0.4.0') || has('patch-8.1.1719')
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
    source ~/.vimrc-coc
endif

" This is a Vim plugin that provides Rust file detection, syntax highlighting,
" formatting, Syntastic integration, and more.
Plug 'rust-lang/rust.vim'

" Vim syntax for TOML.
Plug 'cespare/vim-toml'

" Vim plugin for Nginx, including syntax highlighting.
Plug 'chr4/nginx.vim'

call plug#end()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


autocmd BufRead,BufNewFile Dockerfile* set syntax=dockerfile
autocmd BufRead,BufNewFile *.bats      set syntax=sh


"=======[ Fix smartindent stupidities ]============

inoremap # X<C-H>#|                         "No magic outdent for comments

"=====[ Make Visual modes work better ]==================

"Square up visual selections...
set virtualedit=block

"=====[ Show help files in a new tab ]==============

"Only apply to .txt files...
augroup HelpInTabs
    autocmd!
    autocmd BufEnter  *.txt   call HelpInNewTab()
augroup END

"Only apply to help files...
function! HelpInNewTab ()
    if &buftype == 'help'
        "Convert the help window to a tab...
        execute "normal \<C-W>T"
    endif
endfunction

"=====[ Use Ctrl-UP/LEFT/DOWN/RIGHT to drag blocks in visual mode. ]==============

" runtime plugin/dragvisuals.vim
vmap  <expr>  <C-LEFT>   DVB_Drag('left')
vmap  <expr>  <C-RIGHT>  DVB_Drag('right')
vmap  <expr>  <C-DOWN>   DVB_Drag('down')
vmap  <expr>  <C-UP>     DVB_Drag('up')
vmap  <expr>  D          DVB_Duplicate()

" Disable gray column on left.
set signcolumn=auto
