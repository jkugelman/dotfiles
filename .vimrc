" Always show the current file name.
set laststatus=2

" Enable syntax highlighting.
syntax on

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

" Enable smarter indentation support.
filetype plugin indent on

" Customize code formatting.
set cinoptions=l1,g0,(0,W4,j1

" Use same indentation style as previous lines.
set preserveindent
set copyindent

" Indent settings for code: 4 spaces, do not use tab character.
set tabstop=8 shiftwidth=2 autoindent cindent shiftround
set expandtab softtabstop=2

autocmd BufRead,BufNewFile *.css  set shiftwidth=2 softtabstop=2
autocmd BufRead,BufNewFile *.html set shiftwidth=2 softtabstop=2
autocmd BufRead,BufNewFile *.scss set shiftwidth=2 softtabstop=2
autocmd BufRead,BufNewFile *.toml set shiftwidth=2 softtabstop=2
autocmd BufRead,BufNewFile *.yaml set shiftwidth=2 softtabstop=2
autocmd BufRead,BufNewFile *.yml  set shiftwidth=2 softtabstop=2

autocmd BufRead,BufNewFile *.go   set tabstop=4 shiftwidth=0 noexpandtab nolist softtabstop=0 nocopyindent

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

autocmd BufRead,BufNewFile Dockerfile* set syntax=dockerfile
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
