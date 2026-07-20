" ~/.vimrc — Vim is a secondary editor now (VS Code and Claude Code are the
" daily drivers), so this is kept deliberately lean. Companion files live under
" ~/.vim/: vim-plug in autoload/, installed plugins in plugged/.


"===[ Plugins ]===============================================================
" Managed with vim-plug. Run :PlugUpdate to update plugins.
" <https://github.com/junegunn/vim-plug>

" Bootstrap vim-plug itself on first run, mirroring how ~/.zshrc auto-clones
" antidote: fetched on demand rather than vendored into the repo.
let s:plug = expand('~/.vim/autoload/plug.vim')
if empty(glob(s:plug))
    silent execute '!curl -fLo ' . s:plug . ' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()

" Truecolor colorscheme (muted, dark; degrades to a 256-color palette).
Plug 'sainnhe/gruvbox-material'

" Auto-detects indentation (shiftwidth/expandtab) per file — makes manual
" indent tuning unnecessary.
Plug 'tpope/vim-sleuth'

" Add/change/delete surrounding pairs: cs"' , ds" , ysiw] , cst" , etc.
Plug 'tpope/vim-surround'

" Lets . repeat a whole plugin map (e.g. surround), not just its last step.
Plug 'tpope/vim-repeat'

" TOML syntax.
Plug 'cespare/vim-toml'

" nginx config syntax.
Plug 'chr4/nginx.vim'

call plug#end()

" `%` jumps between matching keyword pairs. Bundled with Vim; load it from Vim's
" own packages rather than vendoring.
packadd! matchit


"===[ Appearance ]============================================================
syntax on

" Use a real truecolor colorscheme rather than hand-tuning highlight groups.
" Enable 24-bit color only on a terminal that advertises it; inside tmux, teach
" vim the escape sequences it needs first.
if has('termguicolors') && ($COLORTERM ==# 'truecolor' || $COLORTERM ==# '24bit')
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
    set termguicolors
endif
set background=dark
" Swap this one word for any other installed scheme (e.g. sonokai, gruvbox).
" silent! keeps a fresh machine quiet until :PlugInstall fetches it.
silent! colorscheme gruvbox-material

" Always show the statusline, plus the ruler and a little scroll context.
set laststatus=2
set ruler
set scrolloff=2

" Flash the matching bracket.
set showmatch


"===[ Whitespace display ]====================================================
" Flag problematic whitespace (trailing spaces, spaces before tabs) in red.
let c_space_errors=1
let c_no_trail_space_error=1
let java_space_errors=1
let java_no_trail_space_error=1
let python_highlight_space_errors=1

highlight BadWhitespace term=standout ctermbg=red guibg=red
match BadWhitespace /[^* \t]\zs\s\+$\| \+\ze\t/

" Show tabs as » followed by spaces, tinted light gray.
execute 'set listchars=tab:' . nr2char(187) . '\ '
set list
highlight Tab ctermfg=lightgray guifg=lightgray
2match Tab /\t/


"===[ Search ]================================================================
set incsearch
set hlsearch
" F7 clears the search highlighting.
nnoremap <F7> :nohl<Enter>


"===[ Movement & editing ]====================================================
" Sane backspacing, and let backspace/space/arrows cross line boundaries.
set backspace=indent,eol,start
set ww=b,s,<,>

" Move by display line, not physical line.
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

" Make Y yank to end of line, matching D. (This is the default in nvim.)
map Y y$

" Keep the selection after shifting in visual mode.
vnoremap < <gv
vnoremap > >gv

" Square up visual-block selections.
set virtualedit=block

" Enable the mouse: click to position, drag to select, wheel to scroll.
set mouse=a


"===[ Indentation ]===========================================================
" Fallback defaults: 4-space indent, no literal tabs. vim-sleuth overrides
" these per file.
set tabstop=8 shiftwidth=4 autoindent shiftround
set expandtab softtabstop=4

" Don't let a leading `#` yank the line out to column 0.
" https://vim.fandom.com/wiki/Restoring_indent_after_typing_hash
set cinkeys-=0#
set indentkeys-=0#


"===[ Command line ]==========================================================
" Complete file names on <Tab> like bash does.
set wildmode=longest,list

" Show the current mode and the partially-typed command.
set showmode
set showcmd

" Confirm rather than fail when quitting with unsaved changes.
set confirm


"===[ Tabs ]==================================================================
nnoremap <C-N> :tabnext<Enter>
nnoremap <C-P> :tabprev<Enter>
nnoremap <C-T> :tabnew<Enter>
nnoremap <C-D> :tabclose<Enter>


"===[ Files & buffers ]=======================================================
" No swap files.
set noswapfile

" Auto-reload files changed on disk, and announce it when it happens.
set autoread
" <https://unix.stackexchange.com/questions/149209/refresh-changed-content-of-file-opened-in-vim/383044#383044>
" <https://vi.stackexchange.com/questions/13692/prevent-focusgained-autocmd-running-in-command-line-editing-mode>
autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * if mode() != 'c' | checktime | endif
" <https://vi.stackexchange.com/questions/13091/autocmd-event-for-autoread>
autocmd FileChangedShellPost *
  \ echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None

" Store undo history across vim invocations. Undo files are per-machine state
" rather than config, so prefer XDG's state dir, where Neovim keeps its own.
"
" Vim never creates these; it uses the first entry that already exists. Keep
" that a self-contained rule — $XDG_STATE_HOME if set, its spec default if not,
" temp dirs as a last resort. This repo guarantees the second entry by tracking
" a .gitkeep there, but the rule doesn't depend on knowing that; without such a
" guarantee the tail matters, since /var/tmp gets pruned and undo history
" silently vanishes.
if has('persistent_undo')
    set undofile
    set undodir=$XDG_STATE_HOME/vim/undo//,~/.local/state/vim/undo//,/var/tmp//,/tmp//,.
endif

" Honor vim: modelines, even as root.
set modeline

" Jump to the last known cursor position. Skip for git commit messages, where
" the file path is reused across unrelated commits.
if has("autocmd")
    au BufReadPost * if &ft !=# 'gitcommit' && line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
endif


"===[ Filetypes & syntax ]====================================================
" bats tests are shell scripts.
autocmd BufRead,BufNewFile *.bats set filetype=sh

" Don't count '.' as a keyword character in shell scripts.
let g:sh_noisk=1

" Fuller Python syntax highlighting.
let python_highlight_all=1
