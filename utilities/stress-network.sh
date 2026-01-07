#!/usr/bin/env bash
# Stress test - parallel HTTP requests (forces DNS through Pihole)
#
# Usage:
#   stress-network.sh              100 parallel for 60s
#   stress-network.sh --heavy      500 parallel
#   stress-network.sh -p 200 -d 120

set -euo pipefail

PARALLEL=100
DURATION=60

while [[ $# -gt 0 ]]; do
    case $1 in
        --insane) PARALLEL=1000; shift ;;
        --heavy) PARALLEL=500; shift ;;
        --light) PARALLEL=50; shift ;;
        --ratelimit-test) PARALLEL=25; DURATION=90; shift ;;
        -p|--parallel) PARALLEL="$2"; shift 2 ;;
        -d|--duration) DURATION="$2"; shift 2 ;;
        -h|--help)
            echo "Network stress test - parallel HTTP requests"
            echo "  --light           50 parallel"
            echo "  --heavy           500 parallel"
            echo "  --insane          1000 parallel"
            echo "  --ratelimit-test  ~2500 queries/min (over old 1000/60, under new 5000/60)"
            echo "  -p N              N parallel workers"
            echo "  -d N              Duration in seconds"
            exit 0
            ;;
        *) echo "Unknown: $1"; exit 1 ;;
    esac
done

URLS=(
    "https://www.google.com"
    "https://www.cloudflare.com"
    "https://www.amazon.com"
    "https://www.github.com"
    "https://www.microsoft.com"
    "https://www.apple.com"
    "https://www.wikipedia.org"
    "https://www.reddit.com"
)

echo "=== HTTP Stress Test ==="
echo "Parallel: $PARALLEL | Duration: ${DURATION}s"
echo "Each request = DNS lookup (via Pihole) + TCP + HTTP"
echo ""
echo "Run 'debug-dns.sh --watch' in another terminal"
echo "Starting in 3s..."
sleep 3

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"; pkill -P $$ 2>/dev/null || true' EXIT INT TERM

END=$(($(date +%s) + DURATION))

for i in $(seq 1 $PARALLEL); do
    bash -c '
        urls="https://www.google.com https://www.cloudflare.com https://www.amazon.com https://www.github.com https://www.microsoft.com https://www.apple.com https://www.wikipedia.org https://www.reddit.com"
        url_arr=($urls)
        total=0 failed=0
        while (( $(date +%s) < '"$END"' )); do
            url="${url_arr[$((RANDOM % ${#url_arr[@]}))]}"
            if ! curl -sf --max-time 3 -o /dev/null "$url" 2>/dev/null; then
                ((failed++))
                echo "$(date +%H:%M:%S) FAIL $url" >&2
            fi
            ((total++))
        done
        echo "$total:$failed"
    ' > "$TMPDIR/$i.out" 2> "$TMPDIR/$i.err" &
done

echo "Spawned $PARALLEL workers..."

while (( $(date +%s) < END )); do
    left=$((END - $(date +%s)))
    fails=$(cat "$TMPDIR"/*.err 2>/dev/null | wc -l || echo 0)
    printf "\r[%3ds] Failures: %d   " "$left" "$fails"
    sleep 1
done

echo -e "\nWaiting..."
wait 2>/dev/null || true

TOTAL=0 FAILED=0
for file in "$TMPDIR"/*.out; do
    [[ -f "$file" ]] || continue
    result=$(cat "$file" 2>/dev/null) || continue
    [[ "$result" =~ ^[0-9]+:[0-9]+$ ]] || continue
    t=${result%%:*}
    f=${result##*:}
    TOTAL=$((TOTAL + t))
    FAILED=$((FAILED + f))
done

echo ""
echo "=== Results ==="
echo "Requests: $TOTAL | Failed: $FAILED"
(( TOTAL > 0 )) && echo "Rate: $(awk "BEGIN {printf \"%.0f\", $TOTAL / $DURATION}") req/s"

if (( FAILED > 0 )); then
    echo -e "\n\033[31mSample failures:\033[0m"
    cat "$TMPDIR"/*.err 2>/dev/null | head -10
fi
