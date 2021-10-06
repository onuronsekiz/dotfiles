# .bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls -h --group-directories-first --color=auto'
PS1='[\u@\h \W]\$ '
PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;[%s@%s]$ %s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"'
