#!/usr/bin/env bash
# DNS Debugging Script
# Run this when DNS is failing to capture diagnostic information
#
# Usage:
#   debug-dns.sh              Run full diagnostics once
#   debug-dns.sh --watch      Monitor DNS continuously (Ctrl+C to stop)
#   debug-dns.sh --quick      Quick check - just test if DNS is working
#   debug-dns.sh -o FILE      Save output to specific file

set -euo pipefail

# Defaults
MODE="full"
OUTPUT_FILE="/tmp/dns-debug-$(date +%Y%m%d-%H%M%S).log"
WATCH_INTERVAL=5

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --watch|-w)
            MODE="watch"
            shift
            ;;
        --quick|-q)
            MODE="quick"
            shift
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -i|--interval)
            WATCH_INTERVAL="$2"
            shift 2
            ;;
        -h|--help)
            echo "DNS Debugging Script"
            echo ""
            echo "Usage: debug-dns.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --quick, -q       Quick check - just test if DNS works"
            echo "  --watch, -w       Monitor continuously (Ctrl+C to stop)"
            echo "  -i, --interval N  Watch interval in seconds (default: 5)"
            echo "  -o, --output FILE Save output to FILE"
            echo "  -h, --help        Show this help"
            exit 0
            ;;
        *)
            OUTPUT_FILE="$1"
            shift
            ;;
    esac
done

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

log() {
    echo -e "$@" | tee -a "$OUTPUT_FILE"
}

section() {
    log "\n${GREEN}=== $1 ===${NC}"
}

error() {
    log "${RED}✗ $1${NC}"
}

success() {
    log "${GREEN}✓ $1${NC}"
}

warning() {
    log "${YELLOW}⚠ $1${NC}"
}

info() {
    log "${BLUE}→ $1${NC}"
}

# Get nameservers from resolv.conf
get_nameservers() {
    grep -E '^nameserver' /etc/resolv.conf 2>/dev/null | awk '{print $2}' || true
}

# DNS query using available tools (prefers host since dig/nslookup may not be installed)
dns_query() {
    local domain="$1"
    local server="${2:-}"

    if [[ -n "$server" ]]; then
        if command -v host &> /dev/null; then
            timeout 3 host "$domain" "$server" 2>/dev/null | head -1
        elif command -v dig &> /dev/null; then
            timeout 3 dig @"$server" +short "$domain" 2>/dev/null | head -1
        else
            return 1
        fi
    else
        if command -v host &> /dev/null; then
            timeout 3 host "$domain" 2>/dev/null | head -1
        elif command -v getent &> /dev/null; then
            timeout 3 getent hosts "$domain" 2>/dev/null | head -1
        else
            return 1
        fi
    fi
}

# Timed DNS query - returns time in ms
timed_dns_query() {
    local domain="$1"
    local server="${2:-}"
    local start end elapsed

    start=$(date +%s%3N)
    if dns_query "$domain" "$server" > /dev/null 2>&1; then
        end=$(date +%s%3N)
        elapsed=$((end - start))
        echo "$elapsed"
        return 0
    else
        return 1
    fi
}

# Check Pihole API status
check_pihole_status() {
    local pihole_ip="$1"
    local api_url="http://${pihole_ip}/admin/api.php?summary"

    if response=$(timeout 3 curl -s "$api_url" 2>/dev/null); then
        if echo "$response" | grep -q "dns_queries_today"; then
            local queries=$(echo "$response" | grep -o '"dns_queries_today":[0-9]*' | cut -d: -f2)
            local blocked=$(echo "$response" | grep -o '"ads_blocked_today":[0-9]*' | cut -d: -f2)
            local status=$(echo "$response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
            echo "status=$status queries=$queries blocked=$blocked"
            return 0
        fi
    fi
    return 1
}

# Quick check mode
quick_check() {
    local ns pihole_ip
    ns=$(get_nameservers | head -1)

    echo -e "${BOLD}Quick DNS Check - $(date)${NC}"

    # Test basic DNS resolution
    if time_ms=$(timed_dns_query "google.com"); then
        success "DNS working (${time_ms}ms via system resolver)"
    else
        error "DNS FAILED - cannot resolve google.com"

        # Can we ping the nameserver?
        if [[ -n "$ns" ]]; then
            if ping -c 1 -W 1 "$ns" &> /dev/null; then
                warning "Can ping nameserver $ns but DNS queries fail"
                info "Pihole may be overloaded or crashed"
            else
                error "Cannot ping nameserver $ns"
                info "Network path to Pihole may be down"
            fi
        fi

        # Test dig directly to Pihole (bypasses system resolver)
        if [[ -n "$ns" ]] && command -v dig &> /dev/null; then
            if timeout 2 dig @"$ns" +short google.com &> /dev/null; then
                success "dig @$ns works (direct UDP works, system resolver issue)"
            else
                error "dig @$ns also fails (network path to Pihole broken)"
            fi
        fi

        # Can we use public DNS?
        if time_ms=$(timed_dns_query "google.com" "8.8.8.8"); then
            success "Public DNS (8.8.8.8) works (${time_ms}ms)"
            info "Workaround: echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf"
        else
            error "Public DNS also failing - network issue"
        fi
        return 1
    fi

    # Check Pihole status if we can
    if [[ -n "$ns" ]]; then
        if pihole_status=$(check_pihole_status "$ns"); then
            success "Pihole API: $pihole_status"
        fi
    fi

    return 0
}

# Watch mode - continuous monitoring
watch_mode() {
    local ns fail_count=0 last_status="unknown"
    ns=$(get_nameservers | head -1)

    echo -e "${BOLD}DNS Monitor - watching every ${WATCH_INTERVAL}s (Ctrl+C to stop)${NC}"
    echo "Logging to: $OUTPUT_FILE"
    echo ""

    while true; do
        local timestamp now_status time_ms
        timestamp=$(date '+%H:%M:%S')

        if time_ms=$(timed_dns_query "google.com"); then
            now_status="ok"
            if [[ "$last_status" != "ok" ]]; then
                log "${timestamp} ${GREEN}✓ DNS RECOVERED${NC} (${time_ms}ms)"
                fail_count=0
            else
                # Only log every 12th successful check (1 minute at 5s interval)
                if (( SECONDS % 60 < WATCH_INTERVAL )); then
                    log "${timestamp} ✓ ok (${time_ms}ms)"
                fi
            fi
        else
            now_status="fail"
            ((fail_count++))

            # Detailed failure info
            local detail=""
            if [[ -n "$ns" ]]; then
                if ! ping -c 1 -W 1 "$ns" &> /dev/null; then
                    detail="cannot ping $ns"
                elif ! dns_query "google.com" "$ns" &> /dev/null; then
                    detail="ping ok but DNS query fails"
                else
                    detail="unknown"
                fi
            fi

            log "${timestamp} ${RED}✗ DNS FAILED${NC} ($detail) [fail #$fail_count]"

            # Check if public DNS works
            if dns_query "google.com" "8.8.8.8" &> /dev/null; then
                log "         ${YELLOW}→ Public DNS (8.8.8.8) works - Pihole issue${NC}"
            else
                log "         ${YELLOW}→ Public DNS also fails - network issue${NC}"
            fi

            # Check Pihole status
            if [[ -n "$ns" ]] && pihole_status=$(check_pihole_status "$ns"); then
                log "         → Pihole API: $pihole_status"
            fi

            # Check ARP
            if arp_entry=$(ip neigh show "$ns" 2>/dev/null | head -1); then
                if echo "$arp_entry" | grep -q "STALE\|FAILED"; then
                    log "         ${YELLOW}→ ARP entry is STALE/FAILED - may need: sudo ip neigh flush dev enp2s0${NC}"
                else
                    log "         → ARP: $arp_entry"
                fi
            fi

            # Compare dig (direct UDP) vs host (system resolver)
            if command -v dig &> /dev/null; then
                if timeout 2 dig @"$ns" +short google.com &> /dev/null; then
                    log "         ${GREEN}→ dig @$ns works${NC} (direct UDP to Pihole works)"
                else
                    log "         ${RED}→ dig @$ns FAILED${NC} (can't reach Pihole DNS port)"
                fi
            fi

            # Check conntrack count
            if [[ -f /proc/sys/net/netfilter/nf_conntrack_count ]]; then
                local ct_count ct_max ct_pct
                ct_count=$(cat /proc/sys/net/netfilter/nf_conntrack_count)
                ct_max=$(cat /proc/sys/net/netfilter/nf_conntrack_max)
                ct_pct=$((ct_count * 100 / ct_max))
                if (( ct_pct > 50 )); then
                    log "         ${YELLOW}→ conntrack: $ct_count/$ct_max ($ct_pct%)${NC}"
                fi
            fi
        fi

        last_status="$now_status"
        sleep "$WATCH_INTERVAL"
    done
}

# Full diagnostic mode
full_diagnostic() {
    # Clear/create output file
    > "$OUTPUT_FILE"

    log "DNS Debug Report - $(date)"
    log "Output saved to: $OUTPUT_FILE"

    local NAMESERVERS
    NAMESERVERS=$(get_nameservers)

    # ============================================================================
    section "1. System DNS Configuration"
    # ============================================================================

    if [[ -f /etc/resolv.conf ]]; then
        log "\n/etc/resolv.conf:"
        cat /etc/resolv.conf | tee -a "$OUTPUT_FILE"

        if [[ -n "$NAMESERVERS" ]]; then
            success "Nameservers configured: $(echo $NAMESERVERS | tr '\n' ' ')"
        else
            error "No nameservers found in /etc/resolv.conf"
        fi
    else
        error "/etc/resolv.conf not found"
    fi

    # ============================================================================
    section "2. NetworkManager DNS Settings"
    # ============================================================================

    if command -v nmcli &> /dev/null; then
        log "\nNetworkManager status:"
        nmcli general status 2>&1 | tee -a "$OUTPUT_FILE" || error "Failed to get NetworkManager status"

        log "\nActive connections:"
        nmcli connection show --active 2>&1 | tee -a "$OUTPUT_FILE" || error "Failed to get active connections"

        log "\nDNS configuration from NetworkManager:"
        nmcli dev show | grep -E 'IP4.DNS|IP6.DNS|GENERAL.CONNECTION' 2>&1 | tee -a "$OUTPUT_FILE" || warning "Failed to get DNS from NetworkManager"
    else
        warning "nmcli not available"
    fi

    # ============================================================================
    section "3. Basic Network Connectivity"
    # ============================================================================

    log "\nTesting connectivity to 8.8.8.8 (Google DNS):"
    if ping -c 3 -W 2 8.8.8.8 &>> "$OUTPUT_FILE"; then
        success "Can reach 8.8.8.8"
    else
        error "Cannot reach 8.8.8.8 - network may be down"
    fi

    log "\nTesting connectivity to 1.1.1.1 (Cloudflare DNS):"
    if ping -c 3 -W 2 1.1.1.1 &>> "$OUTPUT_FILE"; then
        success "Can reach 1.1.1.1"
    else
        error "Cannot reach 1.1.1.1"
    fi

    # ============================================================================
    section "4. DNS Resolution Tests (with timing)"
    # ============================================================================

    local TEST_DOMAINS=("google.com" "github.com" "nixos.org")

    for domain in "${TEST_DOMAINS[@]}"; do
        log "\n--- Testing: $domain ---"

        # Test with host (most commonly available)
        if command -v host &> /dev/null; then
            log "host test:"
            if time_ms=$(timed_dns_query "$domain"); then
                success "host resolved $domain (${time_ms}ms)"
            else
                error "host failed to resolve $domain"
            fi
        fi

        # Test with getent (uses system resolver)
        if command -v getent &> /dev/null; then
            log "getent test (system resolver):"
            local start end
            start=$(date +%s%3N)
            if timeout 5 getent hosts "$domain" &>> "$OUTPUT_FILE"; then
                end=$(date +%s%3N)
                success "getent resolved $domain ($((end - start))ms)"
            else
                error "getent failed to resolve $domain"
            fi
        fi

        # Test with dig if available
        if command -v dig &> /dev/null; then
            log "dig test:"
            if timeout 5 dig +short "$domain" &>> "$OUTPUT_FILE"; then
                success "dig resolved $domain"
            else
                error "dig failed to resolve $domain"
            fi
        fi
    done

    # ============================================================================
    section "5. Direct DNS Server Tests"
    # ============================================================================

    if [[ -n "${NAMESERVERS:-}" ]]; then
        for ns in $NAMESERVERS; do
            log "\nTesting nameserver $ns directly:"

            # Ping test with timing
            local ping_time
            if ping_time=$(ping -c 2 -W 2 "$ns" 2>/dev/null | grep 'avg' | cut -d'/' -f5); then
                success "Can ping $ns (avg ${ping_time}ms)"
            else
                error "Cannot ping $ns"
            fi

            # DNS query test
            if time_ms=$(timed_dns_query "google.com" "$ns"); then
                success "DNS query to $ns successful (${time_ms}ms)"
            else
                error "DNS query to $ns failed"
            fi

            # ARP entry check
            log "ARP entry for $ns:"
            if arp_entry=$(ip neigh show "$ns" 2>/dev/null); then
                echo "$arp_entry" | tee -a "$OUTPUT_FILE"
                if echo "$arp_entry" | grep -q "STALE"; then
                    warning "ARP entry is STALE"
                elif echo "$arp_entry" | grep -q "FAILED"; then
                    error "ARP entry is FAILED"
                elif echo "$arp_entry" | grep -q "REACHABLE"; then
                    success "ARP entry is REACHABLE"
                fi
            else
                warning "No ARP entry found"
            fi
        done
    fi

    # Test common public DNS servers
    log "\nTesting public DNS servers:"
    for dns in "8.8.8.8" "1.1.1.1"; do
        log "Testing $dns:"
        if time_ms=$(timed_dns_query "google.com" "$dns"); then
            success "Query to $dns worked (${time_ms}ms)"
        else
            error "Query to $dns failed"
        fi
    done

    # ============================================================================
    section "6. Resolver Comparison (dig vs host vs getent)"
    # ============================================================================

    log "\nComparing different resolver methods to Pihole:"
    if [[ -n "${NAMESERVERS:-}" ]]; then
        local ns
        ns=$(echo "$NAMESERVERS" | head -1)

        log "Testing google.com via different methods to $ns:"

        # dig directly to server (bypasses system resolver)
        if command -v dig &> /dev/null; then
            local start end
            start=$(date +%s%3N)
            if timeout 3 dig @"$ns" +short google.com &>> "$OUTPUT_FILE"; then
                end=$(date +%s%3N)
                success "dig @$ns: worked ($((end - start))ms)"
            else
                error "dig @$ns: FAILED"
            fi
        fi

        # host to server
        if command -v host &> /dev/null; then
            start=$(date +%s%3N)
            if timeout 3 host google.com "$ns" &>> "$OUTPUT_FILE"; then
                end=$(date +%s%3N)
                success "host (to $ns): worked ($((end - start))ms)"
            else
                error "host (to $ns): FAILED"
            fi
        fi

        # getent (uses nsswitch.conf, full system resolver path)
        start=$(date +%s%3N)
        if timeout 3 getent hosts google.com &>> "$OUTPUT_FILE"; then
            end=$(date +%s%3N)
            success "getent: worked ($((end - start))ms)"
        else
            error "getent: FAILED (system resolver issue)"
        fi

        log "\nIf dig works but getent fails: problem is in system resolver stack"
        log "If both fail to Pihole but work to 8.8.8.8: problem is path to Pihole"
    fi

    # ============================================================================
    section "7. Network Interface & Routing"
    # ============================================================================

    log "\nNetwork interfaces (summary):"
    ip -br addr show 2>&1 | tee -a "$OUTPUT_FILE" || error "Failed to get network interfaces"

    log "\nRouting table:"
    ip route show 2>&1 | tee -a "$OUTPUT_FILE" || error "Failed to get routing table"

    # ============================================================================
    section "8. Docker & iptables (potential interference)"
    # ============================================================================

    log "\nDocker status:"
    if systemctl is-active docker &> /dev/null; then
        warning "Docker is running - may interfere with DNS routing"
        log "Docker networks:"
        docker network ls 2>&1 | tee -a "$OUTPUT_FILE" || true
    else
        success "Docker is not running"
    fi

    log "\niptables DNS-related rules (filter table):"
    if command -v iptables &> /dev/null; then
        # Check for any rules that might affect DNS (port 53)
        local dns_rules
        dns_rules=$(sudo iptables -L -n -v 2>/dev/null | grep -E ':53|dpt:53|spt:53' || true)
        if [[ -n "$dns_rules" ]]; then
            warning "Found iptables rules mentioning port 53:"
            echo "$dns_rules" | tee -a "$OUTPUT_FILE"
        else
            success "No specific DNS port rules in filter table"
        fi

        # Check for DROP rules
        local drop_rules
        drop_rules=$(sudo iptables -L -n -v 2>/dev/null | grep -i drop | head -10 || true)
        if [[ -n "$drop_rules" ]]; then
            log "\nDROP rules (first 10):"
            echo "$drop_rules" | tee -a "$OUTPUT_FILE"
        fi

        # Check NAT table for DOCKER chains
        log "\nNAT table DOCKER chains:"
        sudo iptables -t nat -L -n 2>/dev/null | grep -A5 DOCKER | head -20 | tee -a "$OUTPUT_FILE" || true
    else
        warning "iptables command not available"
    fi

    # ============================================================================
    section "9. Connection Tracking"
    # ============================================================================

    log "\nConnection tracking table status:"
    if [[ -f /proc/sys/net/netfilter/nf_conntrack_count ]]; then
        local ct_count ct_max ct_pct
        ct_count=$(cat /proc/sys/net/netfilter/nf_conntrack_count)
        ct_max=$(cat /proc/sys/net/netfilter/nf_conntrack_max)
        ct_pct=$((ct_count * 100 / ct_max))

        log "Connections: $ct_count / $ct_max ($ct_pct%)"
        if (( ct_pct > 80 )); then
            error "Connection tracking table is >80% full!"
            log "  → This can cause packet drops"
            log "  → Increase with: sudo sysctl net.netfilter.nf_conntrack_max=262144"
        elif (( ct_pct > 50 )); then
            warning "Connection tracking table is >50% full"
        else
            success "Connection tracking table has room ($ct_pct% used)"
        fi

        # Show connections to Pihole specifically
        if [[ -n "${NAMESERVERS:-}" ]] && command -v conntrack &> /dev/null; then
            local ns
            ns=$(echo "$NAMESERVERS" | head -1)
            log "\nConnections to Pihole ($ns):"
            sudo conntrack -L -d "$ns" 2>/dev/null | head -10 | tee -a "$OUTPUT_FILE" || true
        fi
    else
        warning "Connection tracking not available (nf_conntrack module not loaded)"
    fi

    # ============================================================================
    section "10. DNS-related Services Status"
    # ============================================================================

    log "\nsystemd-resolved status:"
    if systemctl is-active systemd-resolved &> /dev/null; then
        success "systemd-resolved is running"
        systemctl status systemd-resolved --no-pager 2>&1 | tee -a "$OUTPUT_FILE" || true
    else
        warning "systemd-resolved is not running (normal for NetworkManager-only setups)"
    fi

    log "\nNetworkManager service status:"
    if systemctl is-active NetworkManager &> /dev/null; then
        success "NetworkManager is running"
        systemctl status NetworkManager --no-pager 2>&1 | tee -a "$OUTPUT_FILE" || true
    else
        error "NetworkManager is not running!"
    fi

    # ============================================================================
    section "11. Pihole Status"
    # ============================================================================

    log "\nChecking Pihole:"
    if [[ -n "${NAMESERVERS:-}" ]]; then
        for ns in $NAMESERVERS; do
            log "Checking $ns:"

            # Admin page
            if timeout 3 curl -s "http://$ns/admin/" &> /dev/null; then
                success "$ns Pihole admin page accessible"
            else
                warning "$ns does not respond to Pihole admin page"
            fi

            # API status
            if pihole_status=$(check_pihole_status "$ns"); then
                success "Pihole API: $pihole_status"
            else
                warning "Could not query Pihole API"
            fi
        done
    fi

    # ============================================================================
    section "12. DNS Cache/NSS Configuration"
    # ============================================================================

    log "\nNSS configuration (/etc/nsswitch.conf hosts line):"
    grep -E '^hosts:' /etc/nsswitch.conf 2>&1 | tee -a "$OUTPUT_FILE" || warning "Could not read nsswitch.conf"

    # ============================================================================
    section "13. Kernel Network Errors (dmesg)"
    # ============================================================================

    log "\nRecent network-related kernel messages:"
    dmesg_output=$(dmesg --time-format=reltime 2>/dev/null | grep -iE 'enp|eth|net|drop|arp|link|carrier' | tail -20 || dmesg | grep -iE 'enp|eth|net|drop|arp|link|carrier' | tail -20 || true)
    if [[ -n "$dmesg_output" ]]; then
        echo "$dmesg_output" | tee -a "$OUTPUT_FILE"
    else
        success "No recent network errors in dmesg"
    fi

    # Check for link flapping
    log "\nChecking for link state changes:"
    link_changes=$(dmesg 2>/dev/null | grep -iE 'link.*(up|down)|carrier' | tail -10 || true)
    if [[ -n "$link_changes" ]]; then
        warning "Link state changes detected:"
        echo "$link_changes" | tee -a "$OUTPUT_FILE"
    else
        success "No link flapping detected"
    fi

    # ============================================================================
    section "14. Recent DNS-related Logs"
    # ============================================================================

    log "\nRecent NetworkManager logs (last 20 lines):"
    journalctl -u NetworkManager -n 20 --no-pager 2>&1 | tee -a "$OUTPUT_FILE" || warning "Could not fetch NetworkManager logs"

    # ============================================================================
    section "Summary & Recommendations"
    # ============================================================================

    log "\nTimestamp: $(date)"
    log "Full diagnostic log saved to: $OUTPUT_FILE"

    log "\n${BOLD}Quick analysis:${NC}"

    local dns_works=false
    if dns_query "google.com" &> /dev/null; then
        dns_works=true
    fi

    if ! ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
        error "Basic network connectivity is down (cannot ping 8.8.8.8)"
        log "  → Check network cable/WiFi connection"
        log "  → Check router status"
    elif ! $dns_works; then
        error "DNS resolution is failing"
        if [[ -n "${NAMESERVERS:-}" ]]; then
            for ns in $NAMESERVERS; do
                if ! ping -c 1 -W 2 "$ns" &> /dev/null; then
                    error "  → Cannot reach nameserver $ns"
                    log "  → This could be your Pihole - check if it's running"
                    log "  → Check router DHCP DNS settings"
                else
                    warning "  → Can reach nameserver $ns but DNS queries fail"
                    log "  → Pihole may be overloaded or crashed"
                    log "  → Check Pihole web UI: http://$ns/admin/"
                    log "  → Try: pihole restartdns (on Pihole host)"
                fi
            done
        fi
        log "\n${BOLD}Workarounds:${NC}"
        log "  → Temporary: echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf"
        log "  → Restart NM: sudo systemctl restart NetworkManager"
    else
        success "DNS appears to be working now"
        local time_ms
        if time_ms=$(timed_dns_query "google.com"); then
            log "  → Resolution time: ${time_ms}ms"
        fi
    fi

    log "\n${BOLD}For intermittent issues:${NC}"
    log "  → Run: debug-dns.sh --watch"
    log "  → This will monitor DNS and log failures with timestamps"

    log "\n${GREEN}Debug complete!${NC}"
}

# Main
case "$MODE" in
    quick)
        quick_check
        ;;
    watch)
        watch_mode
        ;;
    full)
        full_diagnostic
        ;;
esac
