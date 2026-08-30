#!/bin/bash

# Script to force specific port traffic to use Cloudflare DNS
# Useful for Minecraft Bedrock servers and other applications

set -e

# Configuration
# Add or remove ports as needed
PORTS=(19132 25565)  # 19132=Minecraft Bedrock, 25565=Minecraft Java
CLOUDFLARE_DNS="1.1.1.1"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

setup_rules() {
    print_status "Setting up DNS routing for ports ${PORTS[*]} to Cloudflare..."

    for PORT in "${PORTS[@]}"; do
        local MARK_VALUE=$PORT
        
        # Mark packets TO port (for clients connecting to servers)
        print_status "Creating packet marking rules for port $PORT..."
        iptables -t mangle -A OUTPUT -p udp --dport $PORT -j MARK --set-mark $MARK_VALUE
        iptables -t mangle -A OUTPUT -p tcp --dport $PORT -j MARK --set-mark $MARK_VALUE

        # Route marked packets' DNS queries to Cloudflare
        print_status "Routing DNS queries to Cloudflare ($CLOUDFLARE_DNS) for port $PORT..."
        iptables -t nat -A OUTPUT -p udp --dport 53 -m mark --mark $MARK_VALUE -j DNAT --to-destination $CLOUDFLARE_DNS:53
        iptables -t nat -A OUTPUT -p tcp --dport 53 -m mark --mark $MARK_VALUE -j DNAT --to-destination $CLOUDFLARE_DNS:53

        print_success "Port $PORT is now configured to use Cloudflare DNS ($CLOUDFLARE_DNS)"
    done
}

save_rules() {
    print_status "Saving iptables rules..."

    # Create iptables directory if it doesn't exist
    mkdir -p /etc/iptables

    if command -v iptables-save &> /dev/null; then
        iptables-save > /etc/iptables/iptables.rules
        print_success "Rules saved to /etc/iptables/iptables.rules"
        
        # Enable iptables service if available
        if command -v systemctl &> /dev/null; then
            if systemctl list-unit-files | grep -q iptables.service; then
                systemctl enable iptables.service 2>/dev/null || true
                print_success "iptables service enabled"
            else
                print_warning "iptables.service not found. Rules may not persist after reboot."
                print_status "Install iptables and enable iptables.service to persist rules"
            fi
        fi
    else
        print_error "iptables-save not found. Rules will be lost on reboot."
        print_status "Install iptables package to persist rules"
    fi
}

show_rules() {
    echo ""
    print_status "Current iptables rules for ports ${PORTS[*]}:"
    echo "========================================"
    echo "Mangle table (packet marking):"
    for PORT in "${PORTS[@]}"; do
        iptables -t mangle -L OUTPUT -v -n | grep -E "(Chain OUTPUT|$PORT)" || echo "  No rules found for port $PORT"
    done
    echo ""
    echo "NAT table (DNS redirection):"
    iptables -t nat -L OUTPUT -v -n | grep -E "(Chain OUTPUT|mark match|$CLOUDFLARE_DNS)" || echo "  No rules found"
    echo "========================================"
}

remove_rules() {
    print_status "Removing DNS routing rules for ports ${PORTS[*]}..."

    for PORT in "${PORTS[@]}"; do
        local MARK_VALUE=$PORT
        
        # Remove mangle rules
        iptables -t mangle -D OUTPUT -p udp --dport $PORT -j MARK --set-mark $MARK_VALUE 2>/dev/null || true
        iptables -t mangle -D OUTPUT -p tcp --dport $PORT -j MARK --set-mark $MARK_VALUE 2>/dev/null || true

        # Remove NAT rules
        iptables -t nat -D OUTPUT -p udp --dport 53 -m mark --mark $MARK_VALUE -j DNAT --to-destination $CLOUDFLARE_DNS:53 2>/dev/null || true
        iptables -t nat -D OUTPUT -p tcp --dport 53 -m mark --mark $MARK_VALUE -j DNAT --to-destination $CLOUDFLARE_DNS:53 2>/dev/null || true

        print_success "Rules removed for port $PORT"
    done
    
    # Save the updated rules
    save_rules
}

reset_rules() {
    print_status "Resetting all iptables rules..."
    
    iptables -t mangle -F
    iptables -t nat -F
    iptables -t filter -F
    
    print_success "All iptables rules have been flushed"
    
    # Save the reset state
    save_rules
}

show_help() {
    echo "Port-Specific Cloudflare DNS Setup Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup    Setup DNS routing for ports ${PORTS[*]} to Cloudflare (default)"
    echo "  remove   Remove DNS routing rules for ports ${PORTS[*]}"
    echo "  reset    Reset all iptables rules"
    echo "  status   Show current iptables rules"
    echo "  help     Show this help message"
    echo ""
    echo "Examples:"
    echo "  sudo $0              # Setup rules"
    echo "  sudo $0 setup        # Setup rules"
    echo "  sudo $0 remove       # Remove rules"
    echo "  sudo $0 reset        # Reset all iptables"
    echo "  sudo $0 status       # Show current rules"
    echo ""
    echo "Configuration:"
    echo "  Ports: ${PORTS[*]}"
    echo "  DNS Server: $CLOUDFLARE_DNS"
}

main() {
    local action="${1:-setup}"
    
    case "$action" in
        "setup")
            check_root
            setup_rules
            save_rules
            show_rules
            print_success "Setup complete!"
            echo ""
            print_status "Traffic from ports ${PORTS[*]} will now use Cloudflare DNS for name resolution."
            ;;
        "remove")
            check_root
            remove_rules
            show_rules
            ;;
        "reset")
            check_root
            reset_rules
            ;;
        "status")
            check_root
            show_rules
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $action"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
