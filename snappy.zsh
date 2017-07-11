#!/usr/bin/env bash

SNAPPY_PROMPT_SYMBOL="${SNAPPY_PROMPT_SYMBOL:-❯}"
SNAPPY_PROMPT_EXECUTION_TIME_TRIGGER="${SNAPPY_PROMPT_EXECUTION_TIME_TRIGGER:-5}"

ZSH_THEME_GIT_PROMPT_PREFIX="%F{green}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%f"
ZSH_THEME_GIT_PROMPT_DIRTY=" %F{red}✗%f "
ZSH_THEME_GIT_PROMPT_CLEAN=" "
ZSH_THEME_GIT_PROMPT_SHA_BEFORE="%F{yellow}"
ZSH_THEME_GIT_PROMPT_SHA_AFTER="%f "

function snappy_format_time {
	local result
	local total_seconds=$1
	local days=$(( total_seconds / 60 / 60 / 24 ))
	local hours=$(( total_seconds / 60 / 60 % 24 ))
	local minutes=$(( total_seconds / 60 % 60 ))
	local seconds=$(( total_seconds % 60 ))

	(( days > 0 )) && result+="${days}d "
	(( hours > 0 )) && result+="${hours}h "
	(( minutes > 0 )) && result+="${minutes}m "
	result+="${seconds}s"

	echo -n "${result}"
}

function snappy_prompt_identity {
	if [[ -n $SSH_CONNECTION ]]; then
		echo -n "%n@%m:"
	elif [[ "$LOGNAME" != "$USER" ]]; then
		echo -n "%n:"
	fi
}

function snappy_prompt_virtualenv {
	if [[ "$VIRTUAL_ENV" != "" ]]; then
		echo -n "${VIRTUAL_ENV##*/} "
	fi
}

function snappy_prompt_cmd_execution_time {
	integer elapsed_time
	(( elapsed = EPOCHSECONDS - ${snappy_prompt_cmd_execution_timestamp:-$EPOCHSECONDS} ))
	(( elapsed > SNAPPY_PROMPT_EXECUTION_TIME_TRIGGER )) && {
		print -P "%F{yellow}Last command execution took $(snappy_format_time $elapsed)%f"
	}
}

function snappy_prompt_precmd {
	snappy_prompt_cmd_execution_time
	snappy_prompt_cmd_execution_timestamp=
}

function snappy_prompt_preexec {
	snappy_prompt_cmd_execution_timestamp=$EPOCHSECONDS
}

function snappy_prompt_setup {
	# Disable annoying/conflicting features
	export PROMPT_EOL_MARK=''
	export VIRTUAL_ENV_DISABLE_PROMPT=1

	# Load required modules
	zmodload zsh/datetime
	zmodload zsh/zle
	zmodload zsh/parameter

	autoload -U add-zsh-hook
	autoload -Uz async && async

	# Setup hooks
	add-zsh-hook precmd snappy_prompt_precmd
	add-zsh-hook preexec snappy_prompt_preexec

	# Configure prompt
	PROMPT='%F{cyan}$(snappy_prompt_identity)%f'				# User and Host
	PROMPT+='%F{blue}%~%f '										# Current Working Directory
	PROMPT+='%F{magenta}$(snappy_prompt_virtualenv)%f'			# Python Virtual Environment
	PROMPT+='$(git_prompt_info)$(git_prompt_short_sha)'			# Git Prompt Info
	PROMPT+='%(?.%F{blue}.%F{red})${SNAPPY_PROMPT_SYMBOL}%f '	# Prompt Symbol with Exit Status
}

snappy_prompt_setup "$@"
