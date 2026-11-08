#!/usr/bin/env bash
# saltay-kokpit · scripts/lib.sh — helpers shared by new-project.sh and archive-project.sh.

# slugify "Şirket Sitesi" -> sirket-sitesi
# v1.1 lower-cased with tr A-Z a-z and replaced every other byte with "-", so
# Turkish letters were lost ("Şirket" -> "irket"). Transliterate first.
slugify() {
  printf '%s' "$1" \
    | sed 's/ç/c/g; s/Ç/c/g; s/ğ/g/g; s/Ğ/g/g; s/ı/i/g; s/İ/i/g; s/ö/o/g; s/Ö/o/g; s/ş/s/g; s/Ş/s/g; s/ü/u/g; s/Ü/u/g;
           s/â/a/g; s/Â/a/g; s/î/i/g; s/Î/i/g; s/û/u/g; s/Û/u/g;
           s/ä/a/g; s/Ä/a/g; s/é/e/g; s/É/e/g; s/è/e/g; s/à/a/g; s/ñ/n/g; s/ß/ss/g' \
    | tr 'A-Z' 'a-z' \
    | LC_ALL=C sed 's/[^a-z0-9._-]/-/g; s/--*/-/g; s/^-//; s/-$//'
}

# double-quote a value for a sourced shell config file (vault.conf): "C:/My \"Vault\""
dq() { printf '"%s"' "$(printf '%s' "$1" | sed 's/[\\"$`]/\\&/g')"; }

# escape a value for the replacement side of sed "s|...|VALUE|"
sed_escape() { printf '%s' "$1" | sed 's/[\\&|]/\\&/g'; }
