#! /usr/bin/env bash

BASEDIR=$(dirname "$(readlink -f -- "$0")")
readonly BASEDIR

# For internal use via the logging functions below.
#
# $1    String added between the program name and the message,
#       typically to specify the log level.
# $2    Printf-style format string.
# $3…n  Arguments for printf.
_f_log() {
    local prog
    prog=$(basename "$0"):
    printf "%s %s${2}\n" "$prog" "$1" "${@:3}"
}

# $1    Printf-style format string.
# $2…n  Arguments for printf.
log() {
    _f_log '   INFO  ' "$@"
}

# $1    Printf-style format string.
# $2…n  Arguments for printf.
warn() {
    _f_log 'WARNING  ' "$@" >&2
}

# $1    Printf-style format string.
# $2…n  Arguments for printf.
err() {
    _f_log '  ERROR  ' "$@" >&2
}

# Print a command before running it.
# (This function takes care of running it).
#
# $@    The words making up the command to run.
log_and_run() {
    log 'Running: %s' "${*@Q}"
    "$@"
}

# ================================

unset -v keywords
keywords=(
    photographie
    photo
    rawtherapee
    raw
    tutoriel
    tuto
    documentation
    alice
    alicem
)

keywords_as_comma_separated_string=$(
    IFS=','
    printf '%s' "${keywords[*]}"
)

unset -v attributes
attributes=(
    -a lang=fr
    -a author='Alice M. – alicem.net'
    -a keywords="$keywords_as_comma_separated_string"

    # Load “docinfo.html” in <head>, mostly for CSS.
    -a docinfo='shared'

    -a imagesdir='images'
    -a icons='images'
    -a iconsdir='icons'
    -a icontype='png'

    -a toc='left'
    -a toc-title='Table des matières'
    -a toclevels=3
    -a sectanchors

    -a figure-caption='Image'
    -a table-caption='Tableau'

    -a experimental

    # Custom
    -a max_media_height=480
    -a max_media_width='85%'
)

unset -v opts
opts=(
    --failure-level=warn
)

if
    log_and_run asciidoctor "${attributes[@]}" "${opts[@]}" ./*.adoc &&
    log_and_run sed -ri '
        # Translate tooltip on footnote marks.
        s/title="View footnote\."/title="Voir la note de pied de page."/g

        # Translate and fill up the footer text.
        s@(id="footer-text">|^\s*)Last updated (.*) \+[0-9]{4}(<|\s*$)@\1<a href="https://creativecommons.org/licenses/by-nc-sa/4.0/" target="_blank"><img src="images/cc.png"></a>\&emsp;<a href="https://www.alicem.net/" target="_blank">alicem.net</a>\&emsp;·\&emsp;Écrit en <a href="https://asciidoctor.org/" target="_blank">AsciiDoc</a>\&emsp;·\&emsp;Dernière édition de cette page : \2@
    ' ./*.html
then
    log 'All good.'
    exit 0
else
    declare -i status=$?
    err 'Exit status: %d' "$status"
    exit "$status"
fi
