# Put Homebrew on PATH for login shells. It isn't there by default: Apple
# Silicon installs under /opt/homebrew, Intel under /usr/local, Linux under
# /home/linuxbrew/.linuxbrew. Activate whichever brew exists (shellenv sets
# PATH, MANPATH, INFOPATH, and the HOMEBREW_* vars); a no-op where none does.
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
	if [[ -x $_brew ]]; then
		eval "$("$_brew" shellenv)"
		break
	fi
done
unset _brew
