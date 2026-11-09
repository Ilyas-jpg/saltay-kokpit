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
#   VAULT_LAYOUT="flat"    # flat (prefixed notes in one folder) | folders (v1.2)
#   BUDGET=9500            # bytes; keep below 10000
#   CORE="user_profile feedback_5_canonical_rules"    # optional override (flat)
#
# FOLDERS LAYOUT (v1.2) — an existing Obsidian vault organised in sub-folders
#   (e.g. Memory/Feedback, Memory/Projects, Journal ...). Notes are grouped by
#   folder, newest first; the frontmatter `summary:` (or `description:`) is the
#   description. Optional settings, ';'-separated, paths relative to VAULT_DIR:
#   CORE_NOTES="Home;Memory/Memory Rules"   # read-first notes (default: root notes)
#   BINDING_DIRS="Memory/Feedback"          # never trimmed (default: any folder named
#                                           #   feedback / geri bildirim / kural / rules)
#   EXCLUDE_DIRS="Templates"                # skipped entirely (added to the defaults:
#                                           #   .obsidian .trash .git Templates Şablonlar)
#   Folders named arsiv / arşiv / archive are counted, not listed.
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
VAULT_LAYOUT="flat"
BUDGET=9500
CORE=""
CORE_NOTES=""
BINDING_DIRS=""
EXCLUDE_DIRS=""
# shellcheck disable=SC1090
[ -f "$CONF" ] && . "$CONF"

[ -d "$VAULT_DIR" ] || exit 0
cd "$VAULT_DIR" || exit 0

# Path shown to the model: C:\... on Windows (what the Read tool expects), as-is elsewhere.
SHOW_DIR="$VAULT_DIR"
command -v cygpath >/dev/null 2>&1 && SHOW_DIR=$(cygpath -w "$VAULT_DIR")

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
    T_RULE2="RULE 2 (WRITE): when you learn something permanent (preference, decision, account pointer,"
    T_RULE2B="  project, correction) write it to the right file NOW + add one line to MEMORY.md. Never secrets."
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
    T_RULE2="KURAL 2 (YAZ): Yeni kalici bilgi (tercih, karar, hesap isaretcisi, proje, duzeltme) ogrenince"
    T_RULE2B="  hemen ilgili dosyaya YAZ + MEMORY.md'ye tek satir ekle. Sormadan yaz, kisaca bildir. Sir/parola ASLA."
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

# ============================================================ FOLDERS LAYOUT
if [ "$VAULT_LAYOUT" = "folders" ]; then
  if [ "$VAULT_LANG" = "en" ]; then
    F_TITLE="Vault — persistent memory (CANONICAL SOURCE, %s notes)"
    F_LOC="Location: %s — this is an INDEX, not content. Note path: <location>/<section>/<name>.md"
    F_R1="RULE 1 (READ): if a name here matches the topic, Read it. Never assume you remember."
    F_R1B="  Not listed? Grep the vault (archive included)."
    F_R2="RULE 2 (WRITE): when you learn something permanent (preference, decision, project, correction)"
    F_R2B="  write an atomic note in the right folder (frontmatter + summary) and link it from its MOC. Never secrets."
    F_CORE="## CORE — read these first"
    F_ROOT="(root)"; F_BIND="BINDING rules"; F_NEWEST="newest"; F_TOTAL="total"; F_REST="rest: Grep"
    F_COUNT="notes — names: Grep"; F_ARCH="Archive — outside the index, Grep still finds it"
    F_W1="> [index compression level %s — some sections list only their newest notes. FIX: move stale"
    F_W2=">  notes into an archive/ folder (stays out of the index, Grep still finds them)."
    F_W3=">  Output is guaranteed < 10K, no truncation risk.]"
  else
    F_TITLE="Vault — kalici hafiza (KANONIK KAYNAK, %s not)"
    F_LOC="Konum: %s — INDEX'tir, icerik degil. Not yolu: <konum>/<bolum>/<ad>.md"
    F_R1="KURAL 1 (OKU): Konuyla ilgili ad gorursen Read et. Hatirladigini varsayma, tahmin etme."
    F_R1B="  Listede yoksa vault'ta Grep (arsiv dahil)."
    F_R2="KURAL 2 (YAZ): Kalici bilgi (tercih, karar, proje, duzeltme) ogrenince ilgili klasore atomik"
    F_R2B="  not yaz (frontmatter + summary) ve ilgili MOC'a [[link]] ekle. Sir/parola ASLA yazilmaz."
    F_CORE="## CEKIRDEK — once bunlar"
    F_ROOT="(kok)"; F_BIND="BAGLAYICI kurallar"; F_NEWEST="en yeni"; F_TOTAL="toplam"; F_REST="kalanlar: Grep"
    F_COUNT="not — adlar icin: Grep"; F_ARCH="Arsiv — index disi, Grep bulur"
    F_W1="> [index sikisma seviyesi %s — bazi bolumlerde yalniz en yeni notlar var. CARE: bayat"
    F_W2=">  notlari bir arsiv/ klasorune tasi (index disi kalir, Grep yine bulur)."
    F_W3=">  Cikti garantili <10K, kesilme riski yok.]"
  fi

  TMP=$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/saltay-idx.$$")
  trap 'rm -f "$TMP" "$TMP.cat"' EXIT

  # 1) file list: one "dir<TAB>file" line per note, folders sorted, newest note first.
  find . \( -name .obsidian -o -name .trash -o -name .git -o -name node_modules \) -prune \
       -o -type d -print 2>/dev/null | LC_ALL=C sort | while IFS= read -r d; do
    ( cd "$d" 2>/dev/null && ls -t -- *.md 2>/dev/null ) | while IFS= read -r f; do
      printf '%s\t%s\n' "${d#./}" "$f"
    done
  done > "$TMP"
  [ -s "$TMP" ] || exit 0

  # 2) catalog: dir<TAB>name<TAB>summary — every file is read ONCE (frontmatter only).
  awk -F'\t' '{
    p = ($1 == "." ? "./" : $1 "/") $2; s = ""; n = 0; fm = 0
    while ((getline l < p) > 0) {
      sub(/\r$/, "", l); n++
      if (n == 1) { if (l ~ /^---[ \t]*$/) { fm = 1; continue } else break }
      if (l ~ /^---[ \t]*$/ || n > 40) break
      if (s == "" && l ~ /^(summary|description):/) {
        sub(/^(summary|description):[ \t]*/, "", l); gsub(/^["\047]|["\047]$/, "", l); gsub(/[ \t]+/, " ", l); s = l
      }
    }
    close(p); name = $2; sub(/\.md$/, "", name)
    print $1 "\t" name "\t" s
  }' "$TMP" > "$TMP.cat"

  build_folders() {
    awk -F'\t' -v lvl="$1" -v core="$CORE_NOTES" -v bind="$BINDING_DIRS" -v excl="$EXCLUDE_DIRS" \
        -v t_core="$F_CORE" -v t_root="$F_ROOT" -v t_bind="$F_BIND" -v t_new="$F_NEWEST" \
        -v t_tot="$F_TOTAL" -v t_rest="$F_REST" -v t_cnt="$F_COUNT" -v t_arch="$F_ARCH" '
    # cut at a word boundary (byte-safe even under a non-UTF-8 awk such as mawk)
    function cut(s, w,   t, i) {
      if (w <= 0) return ""
      if (length(s) <= w) return s
      t = substr(s, 1, w); i = w
      while (i > 1 && substr(t, i, 1) != " ") i--
      return (i > 1 ? substr(t, 1, i - 1) : t) "…"
    }
    function wrapped(d, k,   i, line, out, nm) {
      line = ""; out = ""
      for (i = 1; i <= k; i++) {
        nm = N[d, i]
        if (line != "" && length(line) + length(nm) + 2 > 100) { out = out line ",\n"; line = nm }
        else line = (line == "" ? nm : line ", " nm)
      }
      return out line
    }
    BEGIN {
      nc = split(core, a, ";"); for (i = 1; i <= nc; i++) if (a[i] != "") { iscore[a[i]] = 1; corder[++ncore] = a[i] }
      nb = split(bind, a, ";"); for (i = 1; i <= nb; i++) if (a[i] != "") isbind[a[i]] = 1
      ex["Templates"] = 1; ex["templates"] = 1; ex["Şablonlar"] = 1; ex["Sablonlar"] = 1; ex["_templates"] = 1
      ne = split(excl, a, ";"); for (i = 1; i <= ne; i++) if (a[i] != "") ex[a[i]] = 1
      if (lvl <= 0) { wc = 70; wb = 70; wo = 70 } else if (lvl == 1) { wc = 70; wb = 70; wo = 0 }
      else if (lvl == 2) { wc = 50; wb = 50; wo = 0 } else { wc = 0; wb = 0; wo = 0 }
    }
    {
      d = $1; nm = $2; s = $3; rel = (d == "." ? nm : d "/" nm)
      np = split(d, parts, "/"); skip = 0; arch = 0
      for (i = 1; i <= np; i++) {
        if (parts[i] in ex) skip = 1
        lb = tolower(parts[i]); if (lb ~ /^_?(arsiv|arşiv|archive)$/) arch = 1
      }
      if (skip) next
      if (arch) { if (!(d in AC)) AO[++na] = d; AC[d]++; next }
      total++
      if ((ncore > 0 && (rel in iscore)) || (ncore == 0 && d == ".")) { CS[rel] = s; if (ncore == 0) corder[++nauto] = rel; next }
      if (!(d in C)) {
        lbd = tolower(d)
        B[d] = (d in isbind) || (nb == 0 && lbd ~ /(feedback|geri ?bildirim|kural|rule)/)
        DO[++nd] = d
      }
      C[d]++; N[d, C[d]] = nm; S[d, C[d]] = s
    }
    END {
      print "TOTAL\t" total
      print t_core
      m = (ncore > 0 ? ncore : nauto)
      for (i = 1; i <= m; i++) {
        r = corder[i]; if (!(r in CS)) continue
        x = cut(CS[r], wc); print "- " r (x != "" ? " — " x : "")
      }
      for (pass = 1; pass <= 2; pass++) for (j = 1; j <= nd; j++) {
        d = DO[j]; if ((pass == 1) != (B[d] == 1)) continue
        print ""
        print "## " (d == "." ? t_root : d "/") " (" C[d] ")" (B[d] ? " — " t_bind : "")
        if (B[d]) {
          if (lvl >= 3) { print wrapped(d, C[d]); continue }
          for (i = 1; i <= C[d]; i++) { x = cut(S[d, i], wb); print "- " N[d, i] (x != "" ? " — " x : "") }
          continue
        }
        if (lvl >= 5) { print C[d] " " t_cnt; continue }
        if (lvl == 4 && C[d] > 10) { print t_new " 10 (" t_tot " " C[d] " — " t_rest "):"; print wrapped(d, 10); continue }
        if (lvl >= 2) { print wrapped(d, C[d]); continue }
        for (i = 1; i <= C[d]; i++) { x = cut(S[d, i], wo); print "- " N[d, i] (x != "" ? " — " x : "") }
      }
      if (na > 0) {
        line = ""; for (i = 1; i <= na; i++) line = line (line == "" ? "" : " · ") AO[i] " (" AC[AO[i]] ")"
        print ""; print t_arch ": " line
      }
    }' "$TMP.cat"
  }

  for lvl in 0 1 2 3 4 5; do
    BODY=$(build_folders "$lvl")
    TOTAL=$(printf '%s\n' "$BODY" | head -1 | cut -f2)
    OUT="$(printf "$F_TITLE" "${TOTAL:-0}")

$(printf "$F_LOC" "$SHOW_DIR")
$F_R1
$F_R1B
$F_R2
$F_R2B

$(printf '%s\n' "$BODY" | sed '1d')"
    if [ "$lvl" -ge 4 ]; then OUT="$OUT

$(printf "$F_W1" "$lvl")
$F_W2
$F_W3"; fi
    SZ=$(printf '%s' "$OUT" | wc -c | tr -d ' ')
    [ "$SZ" -le "$BUDGET" ] && break
  done
  if [ "$SZ" -gt "$BUDGET" ]; then
    OUT=$(printf '%s' "$OUT" | head -c $((BUDGET-160)) | sed '$d')
    OUT="$OUT
$(printf "$FS" "$SZ" "$BUDGET")"
  fi
  printf '%s\n' "$OUT"
  exit 0
fi

# =============================================================== FLAT LAYOUT
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
  echo "$T_LOC: $SHOW_DIR — $T_ISINDEX"
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
