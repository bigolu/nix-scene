#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
shopt -s nullglob
shopt -s inherit_errexit

DIRECTIVE_PREFIX='#nix '
GC_ROOT_DIRECTORY="${XDG_CACHE_HOME:-$HOME/.cache}/nix-scene"

function main {
	local script="$1"
	local -a script_args=("${@:2}")

	local interpreter=''
	local -a packages=()
	local -a script_lines
	readarray -t script_lines <"$script"
	for line in "${script_lines[@]}"; do
		if ! [[ $line == "$DIRECTIVE_PREFIX"* ]]; then
			continue
		fi

		local arg_string="${line#"$DIRECTIVE_PREFIX"}"
		local -a args
		read -ra args <<<"$arg_string"

		local seen_packages_flag=''
		local seen_interpreter_flag=''
		for arg in "${args[@]}"; do
			if [[ $seen_interpreter_flag == 'true' ]]; then
				seen_interpreter_flag=''
				interpreter="$arg"
				continue
			elif [[ $seen_packages_flag == 'true' ]]; then
				packages+=("$arg")
				continue
			fi

			case "$arg" in
				'-i' | '--interpreter')
					seen_interpreter_flag='true'
					;;
				'-p' | '--packages')
					seen_packages_flag='true'
					;;
				*)
					echo "Unexpected argument: $arg" >&2
					return 1
					;;
			esac
		done
	done

	local env=''

	if [[ -n ${NIX_SCENE_CACHE:-} ]]; then
		local -a cache_items
		readarray -t cache_items <"$NIX_SCENE_CACHE"

		local target="${packages[*]}"

		local found_match=''
		for item in "${cache_items[@]}"; do
			if [[ $found_match == 'true' ]]; then
				if [[ -e "$item" ]]; then
					env="$item"
					break
				else
					found_match=''
				fi
			fi

			if [[ $target == "$item" ]]; then
				found_match='true'
			fi
		done
	fi

	if [[ -z $env ]]; then
		if [[ -z ${NIX_SCENE_CONFIG:-} ]]; then
			# shellcheck disable=2016
			log 'Error: Configuration file not found. Set the environment variable `NIX_SCENE_CONFIG` to the path of your configuration file'
			return 1
		fi

		env="$(
			nix \
				build \
				--no-link \
				--impure \
				--print-out-paths \
				--file "${NIX_SCENE_ENV:-src/env.nix}" \
				--arg packages "[ $(printf '"%s" ' "${packages[@]}") ]" \
				--argstr config "$NIX_SCENE_CONFIG"
		)"

		if [[ ${NIX_SCENE_MAKE_GC_ROOT:-} == 'true' ]]; then
			local env_basename="${env##*/}"
			local gc_root="$GC_ROOT_DIRECTORY/$env_basename"
			if [[ ! -e $gc_root ]]; then
				nix build --out-link "$gc_root" "$env"
			fi
		fi
	fi

	local -a command=()
	if [[ ${NIX_SCENE_DEBUG:-} == 'true' ]]; then
		log "Runnning your shell ($SHELL) to debug"
		log "Script environment: $env"
		log "Interpreter: $interpreter"
		log "Script: $script"
		log "Arguments: ${script_args[*]}"
		command=("$SHELL")
	else
		command=("$interpreter" "$script" "${script_args[@]}")
	fi

	exec -- "$env/entrypoint" "${command[@]}"
}

function nix {
	command nix --extra-experimental-features nix-command "$@"
}

function log {
	echo "[nix-scene] $1" >&2
}

main "$@"
