#!/usr/bin/env bash
# monswitch inputs against a fake ddcutil that replays tests/fixtures-ddc/ and fails loudly on any write.
# Run by tests/lint.sh or by hand: tests/monswitch-inputs.sh
# shellcheck disable=SC2016  # check takes its condition as a single-quoted string on purpose (eval runs it later)
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
bin=$PWD/config/scripts/.local/bin
export HYPRISM_LIB=$PWD/config/scripts/.local/lib/hyprism
fx=$PWD/tests/fixtures-ddc
t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
fail=0
check() { if eval "$2"; then echo "ok: $1"; else
    echo "xx $1"
    fail=1
fi; }

mkdir -p "$t/fake" "$t/empty"
cat >"$t/fake/ddcutil" <<EOF
#!/usr/bin/env bash
case "\$1 \$2" in
    "detect --brief") cat "$fx/detect.txt" ;;
    "capabilities --bus") cat "$fx/capabilities.txt" ;;
    "getvcp 60") cat "$fx/getvcp60.txt" ;;
    *) touch "$t/WROTE"; echo "fake ddcutil: unexpected call \$*" >&2; exit 99 ;;
esac
EOF
chmod +x "$t/fake/ddcutil"
# a PATH with the tools monswitch needs but no ddcutil
for c in bash env jq awk sed cat timeout; do ln -s "$(command -v "$c")" "$t/empty/$c"; done

run() { PATH="$t/fake:$PATH" bash "$bin/monswitch" "$@" 2>/dev/null; }
json=$(run inputs)
check "inputs prints valid JSON" 'jq -e . <<<"$json" >/dev/null'
check "inputs names the output" '[[ $(jq -r ".[0].output" <<<"$json") == HDMI-A-1 ]]'
check "inputs reads the current input" '[[ $(jq -r ".[0].current" <<<"$json") == 0x11 ]]'
check "inputs lists named inputs" '(($(jq ".[0].inputs | length" <<<"$json") >= 2)) && [[ $(jq -r ".[0].inputs[] | select(.code == \"0x11\") | .name" <<<"$json") == HDMI-1 ]]'
check "inputs skips the screen that has no DDC" '[[ $(jq length <<<"$json") == 1 ]]'
check "inputs with the right output name works" '[[ $(run inputs HDMI-A-1 | jq length) == 1 ]]'
check "inputs for an unknown output is []" '[[ $(run inputs NOSUCH) == "[]" ]]'
check "inputs without ddcutil is []" '[[ $(PATH="$t/empty" bash "$bin/monswitch" inputs 2>/dev/null) == "[]" ]]'
check "inputs never wrote to the monitor" '[[ ! -e $t/WROTE ]]'

exit $fail
