#!/bin/bash

###############################################################################
# Bermuda Cyber Family Theme - Update Script
# Updates the theme to the latest version
# Author: dinethnethsara
# GitHub: https://github.com/dinethnethsara/bermuda-cyber-theme
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Paths
PTERODACTYL_DIR="/var/www/pterodactyl"
THEME_DIR="$PTERODACTYL_DIR/public/themes/bermuda"
BACKUP_DIR="/var/backups/pterodactyl-theme-update-$(date +%Y%m%d_%H%M%S)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="/tmp/bermuda-theme-update"

# GitHub repository
GITHUB_REPO="dinethnethsara/bermuda-cyber-theme"
GITHUB_URL="https://github.com/$GITHUB_REPO"

# Print colored messages
print_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║   Bermuda Cyber Family Theme Updater           ║"
    echo "║   For Pterodactyl Panel                        ║"
    echo "╚════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Detect current installation
detect_installation() {
    print_info "Checking for existing theme installation..."
    
    if [ ! -d "$THEME_DIR" ]; then
        print_error "Theme is not installed at: $THEME_DIR"
        print_info "Please run install.sh first to install the theme"
        exit 1
    fi
    
    print_success "Found theme installation at: $THEME_DIR"
}

# Get current version
get_current_version() {
    if [ -f "$THEME_DIR/theme.css" ]; then
        CURRENT_VERSION=$(grep -oP "Theme v\K[0-9.]+" "$THEME_DIR/theme.css" | head -1)
        if [ -z "$CURRENT_VERSION" ]; then
            CURRENT_VERSION="unknown"
        fi
    else
        CURRENT_VERSION="unknown"
    fi
    
    print_info "Current version: $CURRENT_VERSION"
}

# Download latest version
download_latest() {
    print_info "Downloading latest version from GitHub..."
    
    # Create temp directory
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    # Download from GitHub
    cd "$TEMP_DIR"
    
    if command -v wget &> /dev/null; then
        wget -q --show-progress "$GITHUB_URL/archive/main.zip" -O theme.zip
    elif command -v curl &> /dev/null; then
        curl -L "$GITHUB_URL/archive/main.zip" -o theme.zip
    else
        print_error "Neither wget nor curl found. Please install one of them."
        exit 1
    fi
    
    if [ ! -f "theme.zip" ]; then
        print_error "Failed to download theme"
        exit 1
    fi
    
    # Extract
    unzip -q theme.zip
    
    if [ ! -d "bermuda-cyber-theme-main" ]; then
        print_error "Failed to extract theme"
        exit 1
    fi
    
    print_success "Downloaded latest version"
}

# Get new version
get_new_version() {
    NEW_VERSION=$(grep -oP "Theme v\K[0-9.]+" "$TEMP_DIR/bermuda-cyber-theme-main/public/css/theme.css" | head -1)
    if [ -z "$NEW_VERSION" ]; then
        NEW_VERSION="latest"
    fi
    
    print_info "New version: $NEW_VERSION"
}

# Compare versions
compare_versions() {
    if [ "$CURRENT_VERSION" = "$NEW_VERSION" ] && [ "$CURRENT_VERSION" != "unknown" ]; then
        print_warning "You already have the latest version ($CURRENT_VERSION)"
        read -p "Do you want to reinstall anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Update cancelled"
            rm -rf "$TEMP_DIR"
            exit 0
        fi
    fi
}

# Create backup
create_backup() {
    print_info "Creating backup of current theme..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup theme files
    cp -r "$THEME_DIR" "$BACKUP_DIR/"
    
    # Backup wrapper template
    if [ -f "$PTERODACTYL_DIR/resources/views/templates/wrapper.blade.php" ]; then
        cp "$PTERODACTYL_DIR/resources/views/templates/wrapper.blade.php" "$BACKUP_DIR/"
    fi
    
    print_success "Backup created at: $BACKUP_DIR"
}

# Update theme files
update_theme() {
    print_info "Updating theme files..."
    
    # Copy CSS
    cp "$TEMP_DIR/bermuda-cyber-theme-main/public/css/theme.css" "$THEME_DIR/"
    
    # Copy JavaScript
    cp "$TEMP_DIR/bermuda-cyber-theme-main/public/js/matrix.js" "$THEME_DIR/"
    
    # Update images if they exist
    if [ -d "$TEMP_DIR/bermuda-cyber-theme-main/public/images" ]; then
        cp -r "$TEMP_DIR/bermuda-cyber-theme-main/public/images"/* "$THEME_DIR/images/" 2>/dev/null || true
    fi
    
    print_success "Theme files updated"
}

# Set permissions
set_permissions() {
    print_info "Setting file permissions..."
    
    # Detect web server user
    WEBUSER="www-data"
    if id "nginx" &>/dev/null; then
        WEBUSER="nginx"
    fi
    
    chown -R "$WEBUSER:$WEBUSER" "$THEME_DIR"
    chmod -R 755 "$THEME_DIR"
    
    print_success "Permissions set for user: $WEBUSER"
}

# Clear caches
clear_cache() {
    print_info "Clearing Pterodactyl cache..."
    
    cd "$PTERODACTYL_DIR"
    
    php artisan cache:clear 2>/dev/null || print_warning "Could not clear application cache"
    php artisan view:clear 2>/dev/null || print_warning "Could not clear view cache"
    php artisan config:clear 2>/dev/null || print_warning "Could not clear config cache"
    
    print_success "Cache cleared"
}

# Restart services
restart_services() {
    print_info "Restarting services..."
    
    # Restart queue worker if exists
    if systemctl list-units --type=service | grep -q "pteroq"; then
        systemctl restart pteroq 2>/dev/null || print_warning "Could not restart pteroq"
    fi
    
    # Reload web server
    if systemctl is-active --quiet nginx; then
        systemctl reload nginx
        print_success "Nginx reloaded"
    elif systemctl is-active --quiet apache2; then
        systemctl reload apache2
        print_success "Apache reloaded"
    fi
}

# Cleanup
cleanup() {
    print_info "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
    print_success "Cleanup complete"
}

# Show completion message
show_completion() {
    echo ""
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║                                                ║"
    echo "║        Theme Updated Successfully!             ║"
    echo "║                                                ║"
    echo "╚════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo "Updated from: $CURRENT_VERSION"
    echo "Updated to: $NEW_VERSION"
    echo ""
    echo "Backup location: $BACKUP_DIR"
    echo ""
    echo "Next steps:"
    echo "  1. Clear your browser cache (Ctrl+F5 or Cmd+Shift+R)"
    echo "  2. Visit your Pterodactyl panel"
    echo "  3. Verify the update was successful"
    echo ""
    echo "If something went wrong:"
    echo "  - Restore from backup: cp -r $BACKUP_DIR/bermuda/* $THEME_DIR/"
    echo "  - Clear cache: cd $PTERODACTYL_DIR && php artisan cache:clear"
    echo ""
    echo "Check what's new: $GITHUB_URL/releases"
    echo ""
}

# Main update function
main() {
    print_banner
    
    check_root
    detect_installation
    get_current_version
    download_latest
    get_new_version
    compare_versions
    create_backup
    update_theme
    set_permissions
    clear_cache
    restart_services
    cleanup
    show_completion
}

# Run update
main "$@"
