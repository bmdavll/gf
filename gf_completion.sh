# bash completion for gf

! type gf &>/dev/null && return 1

_gf() {
    local cur="$2" choices
    if [[ "$cur" == - || "$cur" == --* ]]; then
        choices='--color=always'
    fi
    COMPREPLY=($(compgen -W "$choices" -- "$cur"))
}
complete -o bashdefault -o default -F _gf gf ef ff pf

# vim:set ts=4 sw=4 et:
