#!/usr/bin/env bash
# DNS Stress Test - attempt to reproduce intermittent DNS failures
#
# Usage:
#   stress-dns.sh              Run with default settings (50 req/s for 60s)
#   stress-dns.sh --heavy      Heavy load (200 req/s)
#   stress-dns.sh --light      Light load (10 req/s)
#   stress-dns.sh -r 100 -d 120  Custom: 100 req/s for 120 seconds
#
# Run debug-dns.sh --watch in another terminal to monitor for failures

set -euo pipefail

# Defaults
REQUESTS_PER_SEC=50
DURATION=60
PARALLEL_WORKERS=10

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --heavy|-H)
            REQUESTS_PER_SEC=200
            PARALLEL_WORKERS=20
            shift
            ;;
        --light|-l)
            REQUESTS_PER_SEC=10
            PARALLEL_WORKERS=5
            shift
            ;;
        -r|--rate)
            REQUESTS_PER_SEC="$2"
            shift 2
            ;;
        -d|--duration)
            DURATION="$2"
            shift 2
            ;;
        -w|--workers)
            PARALLEL_WORKERS="$2"
            shift 2
            ;;
        -h|--help)
            echo "DNS Stress Test - reproduce intermittent DNS failures"
            echo ""
            echo "Usage: stress-dns.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --light, -l       Light load (10 req/s)"
            echo "  --heavy, -H       Heavy load (200 req/s)"
            echo "  -r, --rate N      Requests per second (default: 50)"
            echo "  -d, --duration N  Duration in seconds (default: 60)"
            echo "  -w, --workers N   Parallel workers (default: 10)"
            echo "  -h, --help        Show this help"
            echo ""
            echo "Run 'debug-dns.sh --watch' in another terminal to monitor"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# Calculate delay
RATE_PER_WORKER=$((REQUESTS_PER_SEC / PARALLEL_WORKERS))
if (( RATE_PER_WORKER < 1 )); then RATE_PER_WORKER=1; fi
DELAY_MS=$((1000 / RATE_PER_WORKER))

echo -e "${BOLD}DNS Stress Test${NC}"
echo "Rate: ${REQUESTS_PER_SEC} req/s | Duration: ${DURATION}s | Workers: ${PARALLEL_WORKERS}"
echo "Delay per worker: ${DELAY_MS}ms"
echo ""
echo -e "${YELLOW}Tip: Run 'debug-dns.sh --watch' in another terminal${NC}"
echo ""
echo "Starting in 3 seconds... (Ctrl+C to stop)"
sleep 3

echo -e "${GREEN}Running...${NC}"

# Create temp dir for results
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"; kill $(jobs -p) 2>/dev/null || true' EXIT INT TERM

START_TIME=$(date +%s)
END_TIME=$((START_TIME + DURATION))

# Spawn workers - each is a self-contained bash script
for i in $(seq 1 $PARALLEL_WORKERS); do
    bash -c '
        set +e  # Disable errexit for entire worker
        domains="google.com github.com amazon.com cloudflare.com microsoft.com apple.com reddit.com stackoverflow.com wikipedia.org nixos.org"
        domain_arr=($domains)
        total=0
        failed=0
        delay_sec=$(awk "BEGIN {printf \"%.3f\", '"$DELAY_MS"'/1000}")

        while (( $(date +%s) < '"$END_TIME"' )); do
            domain="${domain_arr[$((RANDOM % ${#domain_arr[@]}))]}"
            # Random subdomain 1/3 of time to defeat cache
            if (( RANDOM % 3 == 0 )); then
                rand=$(head -c 4 /dev/urandom | od -An -tx1 | tr -d " \n")
                domain="t${rand}.${domain}"
            fi

            # Run query - exit 124 = timeout (real failure), others OK
            timeout 2 host "$domain" > /dev/null 2>&1
            exit_code=$?

            if (( exit_code == 124 )); then
                ((failed++))
                echo "$(date +%H:%M:%S) TIMEOUT $domain" >&2
            fi

            ((total++))
            sleep "$delay_sec"
        done
        echo "${total}:${failed}"
    ' > "$TMPDIR/worker_$i.out" 2> "$TMPDIR/worker_$i.err" &
done

# Progress display
while true; do
    now=$(date +%s)
    remaining=$((END_TIME - now))
    if (( remaining <= 0 )); then
        break
    fi

    # Count failures so far
    fails=$(cat "$TMPDIR"/*.err 2>/dev/null | wc -l || echo 0)
    printf "\r[%3ds remaining] Failures so far: %d   " "$remaining" "$fails"
    sleep 1
done

echo ""
echo -e "${YELLOW}Waiting for workers to finish...${NC}"
wait

# Collect results
TOTAL=0
FAILED=0
for f in "$TMPDIR"/worker_*.out; do
    if [[ -f "$f" ]]; then
        result=$(cat "$f")
        t=$(echo "$result" | cut -d: -f1)
        f_count=$(echo "$result" | cut -d: -f2)
        TOTAL=$((TOTAL + t))
        FAILED=$((FAILED + f_count))
    fi
done

# Show any failures
if [[ -s "$TMPDIR/worker_1.err" ]]; then
    echo ""
    echo -e "${RED}Sample failures:${NC}"
    cat "$TMPDIR"/*.err | head -20
fi

# Summary
ELAPSED=$(($(date +%s) - START_TIME))
echo ""
echo -e "${BOLD}=== Stress Test Complete ===${NC}"
echo "Duration: ${ELAPSED}s"
echo "Total requests: $TOTAL"
echo "Failed requests: $FAILED"

if (( TOTAL > 0 )); then
    FAIL_RATE=$(awk "BEGIN {printf \"%.2f\", $FAILED * 100 / $TOTAL}")
    RPS=$(awk "BEGIN {printf \"%.1f\", $TOTAL / $ELAPSED}")
    echo "Failure rate: ${FAIL_RATE}%"
    echo "Actual rate: ${RPS} req/s"
fi

if (( FAILED > 0 )); then
    echo -e "${RED}DNS failures detected during test!${NC}"
    echo "Check debug-dns.sh --watch output for details"
else
    echo -e "${GREEN}No DNS failures during test${NC}"
    echo "Try --heavy for more load, or increase -d duration"
fi
