#!/usr/bin/env bash
# =============================================================================
# saltay-kokpit · hooks/vault-index.sh
# SessionStart hook: injects the vault INDEX (note names, not content) into
# every Claude Code session — whatever the working directory is.
#
# WHY UNCONDITIONAL
#   A "read the vault if the task is related to the past" instruction leaves
#   memory to the model's momentary judgement: it opens the vault when you say
#   "remember?" and skips it when you say "add this to the site". Injecting the
#   index on every session start removes that judgement call entirely.
#
# THE 10K RULE (root cause of a silent memory loss — see docs/10-dersler.md)
#   Claude Code (>= 2.1.88) persists any hook output larger than ~10.000
#   characters to a file and shows the model only a ~2 KB preview. An index that
#   grows past that limit disappears silently — the model "forgets" without
#   anybody noticing. This script therefore MEASURES ITSELF against BUDGET and
#   compresses in levels (0..5). If even level 5 does not fit, it cuts at BUDGET
#   with a visible marker. Output can never reach the limit.
#
#   Level 0  everything, one line per note, descriptions on core notes
#   Level 1  reference section wrapped (comma-joined lines)
#   Level 2  all sections wrapped, shorter core descriptions
#   Level 3  no descriptions at all
#   Level 4  project/note sections = newest K names + total count
#   Level 5  project/note sections = count only
#   feedback_ names are NEVER trimmed — they are binding behaviour rules.
#
# CONFIG  ~/.claude/vault.conf  (shell syntax; written by scripts/install.sh)
#   VAULT_DIR="/c/Users/you/Documents/ClaudeVault"   # Git Bash path on Windows
#   VAULT_LANG="tr"        # tr | en — selects prefix set + labels
#   BUDGET=9500            # bytes; keep below 10000
#   CORE="user_profile feedback_5_canonical_rules"    # optional override
#
# TEST
#   bash vault-index.sh | wc -c      -> must be <= BUDGET
#   bash vault-index.sh | tail -3    -> compression warning present?
# =============================================================================

# UTF-8 locale is mandatory: Git Bash ships with an empty LANG and then cut/sed/
# awk count BYTES, splitting Turkish (or any non-ASCII) characters in half.
export LC_ALL=C.UTF-8
if command -v locale >/dev/null 2>&1 && ! locale -a 2>/dev/null | grep -qi '^C\.UTF-8$'; then
  export LC_ALL=en_US.UTF-8
fi

CONF="${SALTAY_CONF:-$HOME/.claude/vault.conf}"
VAULT_DIR="$HOME/Documents/ClaudeVault"
VAULT_LANG="tr"
BUDGET=9500
CORE=""
# shellcheck disable=SC1090
[ -f "$CONF" ] && . "$CONF"

[ -d "$VAULT_DIR" ] || exit 0
cd "$VAULT_DIR" || exit 0

# ---------------------------------------------------------------- prefix sets
case "$VAULT_LANG" in
  en)
    P_USER="user_"; P_PERSONAL="personal_"; P_FEEDBACK="feedback_"
    P_REFERENCE="reference_"; P_PROJECT="project_"; P_HANDOFF="HANDOFF_"; P_NOTE="note_"
    [ -n "$CORE" ] || CORE="user_profile feedback_5_canonical_rules reference_skill_routing"
    T_TITLE="Vault — persistent memory (CANONICAL SOURCE"
    T_LOC="Location"; T_ISINDEX="this is an INDEX, not content."
    T_RULE1="RULE 1 (READ): if a name here matches the topic, Read it. Never assume you remember."
    T_RULE1B="  Topic not listed? Grep the vault. Fully described index: MEMORY.md."
    T_RULE2="RULE 2 (WRITE): when you learn something permanent (preference, decision, credential,"
    T_RULE2B="  project, correction) write it to the right file NOW + add one line to MEMORY.md."
    T_PREFIX="Names are listed WITHOUT their section prefix: 'wordpress_ban' -> feedback_wordpress_ban.md"
    T_CORE="## CORE — read these first"
    T_FEEDBACK="## feedback_<name>.md — behaviour rules and corrections (BINDING)"
    T_PERSONAL="## personal_<name>.md + user_<name>.md — who the user is, context, people"
    T_REFERENCE="## reference_<name>.md — servers, accounts, panels, standards, brand"
    T_PROJECT="## project_<name>.md — projects (HANDOFF_<name>.md listed separately)"
    T_NOTE="## note_<name>.md — decisions, insights, incidents, audits"
    T_OTHER="## Files without a prefix (Read by full name)"
    T_ARCHIVE="Archive — outside the index, Grep still finds it"
    T_NEWEST="newest"; T_TOTAL="total"; T_REST="rest: Grep / MEMORY.md"; T_NAMES="entries — names: Grep / MEMORY.md"
    W1="> [index compression level %s — project/note names shortened. FIX: move stale"
    W2=">  note/project files into the vault's archive/ folder (stays out of the index,"
    W3=">  Grep still finds them). Output is guaranteed < 10K, no truncation risk.]"
    FS="> [INDEX FORCE-CUT (%s B > %s B) — vault-index.sh needs maintenance NOW: archive/shorten.]"
    ;;
  *)
    P_USER="kullanici_"; P_PERSONAL="kisisel_"; P_FEEDBACK="feedback_"
    P_REFERENCE="reference_"; P_PROJECT="proje_"; P_HANDOFF="HANDOFF_"; P_NOTE="not_"
    [ -n "$CORE" ] || CORE="kullanici_profil feedback_5_kanonik_davranis_kurali reference_skill_routing"
    T_TITLE="Vault — kalici hafiza (KANONIK KAYNAK"
    T_LOC="Konum"; T_ISINDEX="INDEX'tir, icerik degil."
    T_RULE1="KURAL 1 (OKU): Konuyla ilgili ad gorursen Read et. Hatirladigini varsayma, tahmin etme."
    T_RULE1B="  Adini bilmedigin konu icin vault'ta Grep. Tam aciklamali index: MEMORY.md."
    T_RULE2="KURAL 2 (YAZ): Yeni kalici bilgi (tercih, karar, credential, proje, duzeltme) ogrenince"
    T_RULE2B="  hemen ilgili dosyaya YAZ + MEMORY.md'ye tek satir ekle. Sormadan yaz, kisaca bildir."
    T_PREFIX="Adlar bolum prefix'i ATILARAK listelenir: 'wordpress_yasak' -> feedback_wordpress_yasak.md"
    T_CORE="## CEKIRDEK — once bunlar"
    T_FEEDBACK="## feedback_<ad>.md — davranis kurallari ve duzeltmeler (BAGLAYICI)"
    T_PERSONAL="## kisisel_<ad>.md + kullanici_<ad>.md — kullanici, cevre, kisisel baglam"
    T_REFERENCE="## reference_<ad>.md — sunucu, hesap, panel, standart, marka"
    T_PROJECT="## proje_<ad>.md — projeler (HANDOFF_<ad>.md ayri isaretli)"
    T_NOTE="## not_<ad>.md — karar, insight, olay, denetim"
    T_OTHER="## Prefixsiz dosyalar (tam ad ile Read)"
    T_ARCHIVE="Arsiv — index disi, Grep bulur"
    T_NEWEST="en yeni"; T_TOTAL="toplam"; T_REST="kalanlar icin: Grep / MEMORY.md"; T_NAMES="adet — adlar icin: Grep / MEMORY.md"
    W1="> [index sikisma seviyesi %s — proje_/not_ adlari kisaltildi. CARE: bayat not/proje"
    W2=">  dosyalarini vault'un arsiv/ klasorune tasi (index disi kalir, Grep yine bulur);"
    W3=">  Cikti garantili <10K, kesilme riski yok.]"
    FS="> [INDEX ZORLA KESILDI (%s B > %s B) — vault-index.sh bakimi ACIL: arsivle/kisalt.]"
    ;;
esac

N=$(ls *.md 2>/dev/null | wc -l | tr -d ' ')
[ "$N" -eq 0 ] && exit 0

is_core() { case " $CORE " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

# First 'description:' line of the frontmatter, squeezed, cut to $2 characters.
# awk substr is character-based under a UTF-8 locale; cut -c is not (Git Bash).
desc() {
  grep -m1 '^description:' "$1" 2>/dev/null \
    | sed 's/^description: *//; s/^"//; s/"$//; s/[[:space:]]\+/ /g' \
    | awk -v w="$2" '{print substr($0,1,w)}'
}

# One name per line, prefix stripped, core notes skipped.
list_lines() {
  for f in "$1"*.md; do
    [ -e "$f" ] || continue
    n="${f%.md}"; is_core "$n" && continue
    echo "- ${n#$1}"
  done
}

# Comma-joined block wrapped at ~100 characters (UTF-8 safe under the locale above).
wrap() {
  awk '{ if (length(line)+length($0)+2 > 100) { print line ","; line=$0 } else { line = (line=="" ? $0 : line ", " $0) } } END { if (line!="") print line }'
}

list_wrapped() {
  for p in "$@"; do
    for f in "$p"*.md; do
      [ -e "$f" ] || continue
      n="${f%.md}"; is_core "$n" && continue
      echo "${n#$p}"
    done
  done | wrap
}

# Level 4-5: newest K names (by mtime) + total count. K=0 -> count only.
list_newest() {
  p=$1; k=$2
  total=$(ls "$p"*.md 2>/dev/null | wc -l | tr -d ' ')
  if [ "$k" -gt 0 ] && [ "$total" -gt 0 ]; then
    echo "$T_NEWEST $k ($T_TOTAL $total — $T_REST):"
    ls -t "$p"*.md 2>/dev/null | head -n "$k" | while read -r f; do
      n="${f%.md}"; is_core "$n" && continue
      echo "${n#$p}"
    done | wrap
  else
    echo "$total $T_NAMES"
  fi
}

build() {
  lvl=$1
  case $lvl in 0|1) dw=56 ;; 2) dw=40 ;; *) dw=0 ;; esac

  echo "# $T_TITLE, $N)"
  echo
  echo "$T_LOC: $VAULT_DIR — $T_ISINDEX"
  echo "$T_RULE1"; echo "$T_RULE1B"; echo "$T_RULE2"; echo "$T_RULE2B"
  echo "$T_PREFIX"
  echo
  echo "$T_CORE"
  for n in $CORE; do
    [ -e "$n.md" ] || continue
    d=""; [ "$dw" -gt 0 ] && d=$(desc "$n.md" "$dw")
    if [ -n "$d" ]; then echo "- $n — $d"; else echo "- $n"; fi
  done
  echo
  echo "$T_FEEDBACK"
  if [ "$lvl" -ge 2 ]; then list_wrapped "$P_FEEDBACK"; else list_lines "$P_FEEDBACK"; fi
  echo
  echo "$T_PERSONAL"
  if [ "$lvl" -ge 2 ]; then list_wrapped "$P_PERSONAL" "$P_USER"; else list_lines "$P_PERSONAL"; list_lines "$P_USER"; fi
  echo
  echo "$T_REFERENCE"
  if [ "$lvl" -ge 1 ]; then list_wrapped "$P_REFERENCE"; else list_lines "$P_REFERENCE"; fi
  echo
  echo "$T_PROJECT"
  if   [ "$lvl" -ge 5 ]; then list_newest "$P_PROJECT" 0
  elif [ "$lvl" -ge 4 ]; then list_newest "$P_PROJECT" 25
  else list_wrapped "$P_PROJECT"; fi
  echo
  echo "${P_HANDOFF}<name>.md:"
  list_wrapped "$P_HANDOFF"
  echo
  echo "$T_NOTE"
  if   [ "$lvl" -ge 5 ]; then list_newest "$P_NOTE" 0
  elif [ "$lvl" -ge 4 ]; then list_newest "$P_NOTE" 15
  else list_wrapped "$P_NOTE"; fi
  echo
  echo "$T_OTHER"
  for f in *.md; do
    case "$f" in
      ${P_FEEDBACK}*|${P_PERSONAL}*|${P_USER}*|${P_PROJECT}*|${P_HANDOFF}*|${P_REFERENCE}*|${P_NOTE}*|MEMORY.md|README.md) continue ;;
    esac
    echo "- $f"
  done

  # Sub-folders (archive layers) are outside the index; Grep still reads them.
  ARC=""
  for d in */; do
    [ -d "$d" ] || continue
    c=$(ls "$d"*.md 2>/dev/null | grep -vc 'README\.md$')
    [ "$c" -gt 0 ] && ARC="$ARC${ARC:+ · }${d%/} ($c)"
  done
  [ -n "$ARC" ] && { echo; echo "$T_ARCHIVE: $ARC"; }
  return 0
}

warn_text() {
  echo
  printf "$W1\n" "$1"; echo "$W2"; echo "$W3"
}

# Pick the most readable level that fits the budget.
for lvl in 0 1 2 3 4 5; do
  OUT=$(build $lvl)
  [ "$lvl" -ge 4 ] && OUT="$OUT$(warn_text "$lvl")"
  SZ=$(printf '%s' "$OUT" | wc -c | tr -d ' ')
  [ "$SZ" -le "$BUDGET" ] && break
done

# ABSOLUTE FAILSAFE: cut at BUDGET (drop the half line, keep UTF-8 intact) + marker.
if [ "$SZ" -gt "$BUDGET" ]; then
  OUT=$(printf '%s' "$OUT" | head -c $((BUDGET-160)) | sed '$d')
  OUT="$OUT
$(printf "$FS" "$SZ" "$BUDGET")"
fi

printf '%s\n' "$OUT"
exit 0
