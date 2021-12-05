# .bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls -h --group-directories-first --color=auto'
#PS1='[\u@\h \W]\$ '
PS1='\[\e[0m\][\[\e[32m\]\u@\h \[\e[34m\]\W\[\e[0m\]]\$ '
PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;[%s@%s]$ %s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"'
export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;31m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;34m'
export EDITOR=vim
