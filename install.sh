#!/bin/bash
#
# This script installs the rekki cli on your unix machine. You can find
# instructions to run the latest version of the installer directly from the web
# by visiting: https://cli.rekki.team

# Make sure we only use binaries from known places.
PATH='/usr/bin:/bin'

# Make sure we don't have aliases polluting the script.
unalias -a

main() {
	install
	[[ "$1" != '--no-init' ]] && init
}

install() {
	# infer/check os
	local _os
	case "$(uname -s)" in
	Darwin)
		_os='darwin'
		;;
	Linux)
		_os='linux'
		;;
	*)
		err "Unsupported operating system: $(uname -a)"
		exit 1
		;;
	esac

	# infer/check arch
	local _arch
	case "$(uname -m)" in
	aarch64 | arm64)
		_arch='arm64'
		;;
	x86_64 | x86-64 | x64 | amd64)
		_arch='amd64'
		;;
	*)
		err "Unsupported machine hardware: $(uname -a)"
		exit 2
		;;
	esac

	info "Target: os=$_os arch=$_arch"

	# Make sure the required directories have been properly created
	for dir in "$HOME/.rekki" "$HOME/.rekki/bin"; do
		if ! [[ -d "$dir" ]]; then
			rm -rf "$dir"
		fi
		mkdir -p "$dir"
	done

	# If a local rekki exists, check if a new version is available
	info "Checking for a local rekki-cli..."
	if [[ -x "$HOME/.rekki/bin/rekki" ]]; then
		local _local_version
		_local_version=$("$HOME/.rekki/bin/rekki" version)

		# Find out about the latest remote version
		local _remote_version
		_remote_version=$(
			curl \
				--proto '=https' \
				--tlsv1.2 \
				--silent \
				"https://cli.rekki.team/version.txt"
		)

		# Early return if the local version is up-to-date
		if [[ "$_local_version" == "$_remote_version" ]]; then
			info 'Local rekki-cli is already up-to-date.'
			return 0
		fi

		info "Local rekki-cli is outdated."
	else
		info "Cannot find a local rekki-cli."
	fi

	# Download the latest release
	local _url
	_url="https://cli.rekki.team/rekki-$_os-$_arch"
	info "Downloading release $_url..."
	local _code
	_code=$(
		curl \
			--proto '=https' \
			--tlsv1.2 \
			--progress-bar \
			-w "%{http_code}" \
			-o "$HOME/.rekki/bin/rekki-$_os-$_arch" \
			"$_url"
	)
	if [[ "$_code" -ne 200 ]]; then
		err "Expected status code 200 for $_url, but got $_code"
		exit 3
	fi

	# Download the latest release signature
	local _url
	_url="https://cli.rekki.team/rekki-$_os-$_arch.sha256"
	info "Downloading signature $_url..."
	local _code
	_code=$(
		curl \
			--proto '=https' \
			--tlsv1.2 \
			--silent \
			-w "%{http_code}" \
			-o "$HOME/.rekki/bin/rekki-$_os-$_arch.sha256" \
			"$_url"
	)
	if [[ "$_code" -ne 200 ]]; then
		err "Expected status code 200 for $_url, but got $_code"
		exit 3
	fi

	# Check signature
	info "Checking signature..."
	local _sha256
	_sha256=$(cd "$HOME/.rekki/bin" && shasum -a 256 "rekki-$_os-$_arch")
	if echo -n "$_sha256" | diff "$HOME/.rekki/bin/rekki-$_os-$_arch.sha256" - &>/dev/null; then
		info "Signature does not match for: $HOME/.rekki/bin/rekki-$_os-$_arch"
		exit 4
	fi

	# Make sure it is executable
	chmod 0755 "$HOME/.rekki/bin/rekki-$_os-$_arch"

	# Overwrite the current binary
	info "Installing binary in: $HOME/.rekki/bin/rekki"
	rm -rf "$HOME/.rekki/bin/rekki"
	mv -f "$HOME/.rekki/bin/rekki-$_os-$_arch" "$HOME/.rekki/bin/rekki"
}

init() {
	# shellcheck disable=SC2016
	info 'Running `rekki init`'
	# we don't need to check for updates as we've just installed the latest version
	"$HOME/.rekki/bin/rekki" init --no-self-update
}

info() {
	echo "INFO [$(date -u +'%Y-%m-%d %H:%M:%S')] $*"
}

err() {
	echo "ERR [$(date -u +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

main "$@"
exit 0
