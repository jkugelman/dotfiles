# If a command is not recognized in the $PATH, this will use Ubuntu's
# command-not-found package to find it or suggest spelling mistakes.
#
# The oh-my-zsh command-not-found plugin isn't used: it doesn't print an error
# when there's no suggestion.
if [[ -x /usr/lib/command-not-found ]] ; then
    if (( ! ${+functions[command_not_found_handler]} )) ; then
        function command_not_found_handler {
            [[ -x /usr/lib/command-not-found ]] || return 1
            /usr/lib/command-not-found -- ${1+"$1"} && :
        }
    fi
fi
