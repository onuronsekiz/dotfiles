# .bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls -h --group-directories-first --color=auto'
#PS1='[\u@\h \W]\$ '
PS1='\033[33m\][\[\033[32m\]\u@\h \033[34m\]\W\033[33m\]]\033[37m\]\$ '
PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;[%s@%s]$ %s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"'
