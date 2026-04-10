#!/usr/bin/env bash
# codecount.sh — full codebase analysis
# Usage: bash codecount.sh [directory] [--no-color]

set -uo pipefail

TARGET="${1:-.}"
NO_COLOR=false
[[ "${2:-}" == "--no-color" ]] && NO_COLOR=true

if $NO_COLOR || ! [ -t 1 ]; then
  G="" Y="" M="" C="" DIM="" BOLD="" RESET=""
else
  G="\033[0;32m" Y="\033[0;33m" M="\033[0;35m" C="\033[0;36m"
  DIM="\033[2m" BOLD="\033[1m" RESET="\033[0m"
fi

declare -A LANG_MAP=(
  [py]="Python"        [pyw]="Python"
  [js]="JavaScript"    [mjs]="JavaScript"   [cjs]="JavaScript"
  [ts]="TypeScript"    [tsx]="TypeScript"
  [jsx]="React/JSX"
  [c]="C"              [h]="C/C++ Header"
  [cpp]="C++"          [cxx]="C++"          [cc]="C++"    [hpp]="C/C++ Header"
  [rs]="Rust"
  [go]="Go"
  [java]="Java"        [class]="Java Bytecode"
  [kt]="Kotlin"        [kts]="Kotlin"
  [swift]="Swift"
  [rb]="Ruby"          [erb]="Ruby/ERB"
  [php]="PHP"
  [cs]="C#"            [fs]="F#"            [fsx]="F#"
  [scala]="Scala"      [lua]="Lua"
  [r]="R"
  [m]="Objective-C"    [mm]="Objective-C++"
  [ex]="Elixir"        [exs]="Elixir"
  [erl]="Erlang"       [hrl]="Erlang"
  [hs]="Haskell"       [lhs]="Haskell"
  [clj]="Clojure"      [cljs]="ClojureScript"
  [dart]="Dart"        [nim]="Nim"          [zig]="Zig"
  [jl]="Julia"         [ml]="OCaml"         [mli]="OCaml"
  [pl]="Perl"          [pm]="Perl"
  [sh]="Shell"         [bash]="Shell"       [zsh]="Shell" [fish]="Shell"
  [ps1]="PowerShell"   [psm1]="PowerShell"
  [bat]="Batch"        [cmd]="Batch"
  [sql]="SQL"
  [html]="HTML"        [htm]="HTML"
  [css]="CSS"          [scss]="SCSS"        [sass]="SASS" [less]="LESS"
  [xml]="XML"          [xsl]="XML"
  [json]="JSON"        [jsonc]="JSON"
  [yaml]="YAML"        [yml]="YAML"
  [toml]="TOML"
  [ini]="INI/Config"   [cfg]="INI/Config"   [conf]="INI/Config"
  [env]="ENV"
  [md]="Markdown"      [mdx]="Markdown"
  [rst]="reStructuredText"
  [tex]="LaTeX"        [sty]="LaTeX"
  [txt]="Text"         [csv]="CSV"
  [tf]="Terraform"     [tfvars]="Terraform"
  [proto]="Protobuf"
  [graphql]="GraphQL"  [gql]="GraphQL"
  [vue]="Vue"          [svelte]="Svelte"    [astro]="Astro"
)

get_lang() {
  local file="$1" base lower_base ext
  base="$(basename "$file")"
  lower_base="${base,,}"
  case "$lower_base" in
    dockerfile)                echo "Dockerfile";  return ;;
    makefile|gnumakefile)      echo "Makefile";    return ;;
    rakefile|gemfile)          echo "Ruby";        return ;;
    cmakelists.txt)            echo "CMake";       return ;;
    .env|.env.*)               echo "ENV";         return ;;
    .gitignore|.gitattributes) echo "Git Config";  return ;;
    .editorconfig|.prettierrc|.eslintrc|.babelrc)  echo "Config"; return ;;
  esac
  [[ "$base" != *"."* ]] && { echo "Other"; return; }
  ext="${base##*.}"
  ext="${ext,,}"
  echo "${LANG_MAP[$ext]:-Other}"
}

human() {
  local n=$1
  if   (( n >= 1000000 )); then awk "BEGIN{printf \"%.1fM\", $n/1000000}"
  elif (( n >= 1000 ));    then awk "BEGIN{printf \"%.1fK\", $n/1000}"
  else echo "$n"
  fi
}

bar() {
  local pct=$1 width=30 f="" e=""
  local filled=$(( pct * width / 100 ))
  local empty=$(( width - filled ))
  (( filled > 0 )) && f="$(printf '█%.0s' $(seq 1 $filled))"
  (( empty  > 0 )) && e="$(printf '░%.0s' $(seq 1 $empty))"
  printf "%s%s" "$f" "$e"
}

[[ ! -d "$TARGET" ]] && { echo "Error: '$TARGET' is not a directory." >&2; exit 1; }
TARGET="$(realpath "$TARGET")"

echo -e "\n${BOLD}${C}Scanning${RESET} ${BOLD}$TARGET${RESET}${DIM} ...${RESET}\n"

ALL_TMP="$(mktemp)"
TEXT_TMP="$(mktemp)"
trap 'rm -f "$ALL_TMP" "$TEXT_TMP"' EXIT

# Collect all candidate files
find "$TARGET" \
  \( -path "*/.git"            -o -path "*/node_modules"   \
     -o -path "*/__pycache__"   -o -path "*/.cache"        \
     -o -path "*/vendor"        -o -path "*/.venv"         \
     -o -path "*/venv"          -o -path "*/.mypy_cache"   \
     -o -path "*/.pytest_cache" -o -path "*/dist"          \
     -o -path "*/build"         -o -path "*/.next"         \
     -o -path "*/.nuxt"         -o -path "*/target"        \
     -o -path "*/.cargo"        \) \
  -prune -o -type f -print 2>/dev/null > "$ALL_TMP"

# Filter out binary files using `file` MIME encoding
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  enc=$(file -b --mime-encoding "$f" 2>/dev/null)
  [[ "$enc" == "binary" ]] && continue
  printf '%s\n' "$f"
done < "$ALL_TMP" > "$TEXT_TMP"

TOTAL_FILES=$(wc -l < "$TEXT_TMP" | tr -d ' ')

if [[ "$TOTAL_FILES" -eq 0 ]]; then
  echo "No text files found in $TARGET"
  exit 0
fi

declare -A FILE_LINES LANG_FILES LANG_LINES EXT_COUNT
TOTAL_LINES=0 BLANK_LINES=0

while IFS= read -r filepath; do
  [[ -z "$filepath" ]] && continue
  lines=$(wc -l < "$filepath" 2>/dev/null | tr -d ' ') || lines=0
  blank=$(grep -c '^[[:space:]]*$' "$filepath" 2>/dev/null) || blank=0
  lang=$(get_lang "$filepath")
  base="$(basename "$filepath")"
  if [[ "$base" == *"."* ]]; then
    ext="${base##*.}"; ext="${ext,,}"
  else
    ext="(none)"
  fi

  FILE_LINES["$filepath"]=$lines
  LANG_FILES["$lang"]=$(( ${LANG_FILES[$lang]:-0} + 1 ))
  LANG_LINES["$lang"]=$(( ${LANG_LINES[$lang]:-0} + lines ))
  EXT_COUNT["$ext"]=$(( ${EXT_COUNT[$ext]:-0} + 1 ))
  TOTAL_LINES=$(( TOTAL_LINES + lines ))
  BLANK_LINES=$(( BLANK_LINES + blank ))
done < "$TEXT_TMP"

CODE_LINES=$(( TOTAL_LINES - BLANK_LINES ))

# ────────────────────────────────────────────────────────────────────────────
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  CODEBASE ANALYSIS REPORT${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo
printf "  ${BOLD}%-22s${RESET} %s\n"               "Directory:"       "$TARGET"
printf "  ${BOLD}%-22s${RESET} ${G}%s${RESET}\n"   "Total files:"     "$TOTAL_FILES"
printf "  ${BOLD}%-22s${RESET} ${G}%s${RESET}\n"   "Total lines:"     "$(human $TOTAL_LINES)  ($TOTAL_LINES)"
printf "  ${BOLD}%-22s${RESET} ${C}%s${RESET}\n"   "Code lines:"      "$(human $CODE_LINES)  ($CODE_LINES)"
printf "  ${BOLD}%-22s${RESET} ${DIM}%s${RESET}\n" "Blank lines:"     "$(human $BLANK_LINES)  ($BLANK_LINES)"
printf "  ${BOLD}%-22s${RESET} %s\n"               "Languages found:" "${#LANG_FILES[@]}"
echo

# ── Top 15 largest files ─────────────────────────────────────────────────────
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  TOP 15 LARGEST FILES${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo
printf "  ${BOLD}%-8s  %-16s  %s${RESET}\n" "Lines" "Language" "Path"
printf "  %s\n" "$(printf '─%.0s' {1..72})"

{
  for f in "${!FILE_LINES[@]}"; do
    printf '%d\t%s\n' "${FILE_LINES[$f]}" "$f"
  done
} | sort -t$'\t' -k1 -rn | head -15 | \
while IFS=$'\t' read -r lines filepath; do
  lang=$(get_lang "$filepath")
  relpath="${filepath#$TARGET/}"
  printf "  ${Y}%-8s${RESET}  ${M}%-16s${RESET}  %s\n" \
    "$(human $lines)" "${lang:0:16}" "$relpath"
done
echo

# ── Language breakdown ────────────────────────────────────────────────────────
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  LANGUAGE BREAKDOWN${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo
printf "  ${BOLD}%-18s  %6s  %8s  %6s  %-30s${RESET}\n" \
  "Language" "Files" "Lines" "   %" "Distribution"
printf "  %s\n" "$(printf '─%.0s' {1..76})"

{
  for lang in "${!LANG_LINES[@]}"; do
    printf '%d\t%s\n' "${LANG_LINES[$lang]}" "$lang"
  done
} | sort -t$'\t' -k1 -rn | \
while IFS=$'\t' read -r llines lang; do
  lfiles="${LANG_FILES[$lang]:-0}"
  if (( TOTAL_LINES > 0 )); then
    pct=$(( llines * 100 / TOTAL_LINES ))
    pct_exact=$(awk "BEGIN{printf \"%.1f\", $llines/$TOTAL_LINES*100}")
  else
    pct=0; pct_exact="0.0"
  fi
  printf "  %-18s  %6s  %8s  %5s%%  ${G}%s${RESET}\n" \
    "${lang:0:18}" "$lfiles" "$(human $llines)" "$pct_exact" "$(bar $pct)"
done
echo

# ── Extension counts ──────────────────────────────────────────────────────────
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  FILE TYPE COUNTS${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo
{
  for ext in "${!EXT_COUNT[@]}"; do
    printf '%d\t%s\n' "${EXT_COUNT[$ext]}" "$ext"
  done
} | sort -t$'\t' -k1 -rn | head -20 | \
while IFS=$'\t' read -r cnt ext; do
  suffix="s"; (( cnt == 1 )) && suffix=""
  printf "  ${C}.%-14s${RESET}  ${Y}%5s${RESET} file%s\n" "$ext" "$cnt" "$suffix"
done
echo
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${DIM}  Skipped: .git  node_modules  __pycache__  vendor  venv  dist  build  target${RESET}"
echo -e "${DIM}  Generated at $(date '+%Y-%m-%d %H:%M:%S')${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo