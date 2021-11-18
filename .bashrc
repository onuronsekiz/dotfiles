# .bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls -h --group-directories-first --color=auto'
#PS1='[\u@\h \W]\$ '
PS1='\e[0m[\e[32m\u@\h \e[34m\W\e[0m]\$ '
PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;[%s@%s]$ %s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"'
