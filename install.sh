#!/bin/bash

###############################################################################
# Bermuda Cyber Family Theme - Installer for Pterodactyl Panel
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

# Default Pterodactyl path
PTERODACTYL_DIR="/var/www/pterodactyl"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="/var/backups/pterodactyl-theme-$(date +%Y%m%d_%H%M%S)"

# Print colored messages
print_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║   Bermuda Cyber Family Theme Installer        ║"
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

# Detect Pterodactyl installation
detect_pterodactyl() {
    print_info "Detecting Pterodactyl installation..."
    
    # Check default path
    if [ ! -d "$PTERODACTYL_DIR" ]; then
        print_warning "Pterodactyl not found at default path: $PTERODACTYL_DIR"
        read -p "Enter your Pterodactyl installation path: " PTERODACTYL_DIR
        
        if [ ! -d "$PTERODACTYL_DIR" ]; then
            print_error "Directory not found: $PTERODACTYL_DIR"
            exit 1
        fi
    fi
    
    # Verify it's a Pterodactyl installation
    if [ ! -f "$PTERODACTYL_DIR/artisan" ]; then
        print_error "Not a valid Pterodactyl installation (artisan not found)"
        exit 1
    fi
    
    print_success "Found Pterodactyl at: $PTERODACTYL_DIR"
}

# Create backup
create_backup() {
    print_info "Creating backup..."
    mkdir -p "$BACKUP_DIR"
    
    # Backup wrapper template if it exists
    if [ -f "$PTERODACTYL_DIR/resources/views/templates/wrapper.blade.php" ]; then
        cp "$PTERODACTYL_DIR/resources/views/templates/wrapper.blade.php" "$BACKUP_DIR/"
        print_success "Backed up wrapper.blade.php"
    fi
    
    # Backup existing theme if it exists
    if [ -d "$PTERODACTYL_DIR/public/themes/bermuda" ]; then
        cp -r "$PTERODACTYL_DIR/public/themes/bermuda" "$BACKUP_DIR/theme-old"
        print_success "Backed up existing theme"
    fi
    
    print_success "Backup created at: $BACKUP_DIR"
}

# Install theme files
install_theme() {
    print_info "Installing theme files..."
    
    # Create theme directory
    mkdir -p "$PTERODACTYL_DIR/public/themes/bermuda"
    
    # Copy CSS
    cp "$SCRIPT_DIR/public/css/theme.css" "$PTERODACTYL_DIR/public/themes/bermuda/"
    print_success "Installed CSS files"
    
    # Copy JavaScript
    cp "$SCRIPT_DIR/public/js/matrix.js" "$PTERODACTYL_DIR/public/themes/bermuda/"
    print_success "Installed JavaScript files"
    
    # Copy images if they exist
    if [ -d "$SCRIPT_DIR/public/images" ]; then
        cp -r "$SCRIPT_DIR/public/images" "$PTERODACTYL_DIR/public/themes/bermuda/"
        print_success "Installed image assets"
    fi
}

# Inject theme into wrapper template
inject_theme() {
    print_info "Injecting theme into Pterodactyl..."
    
    WRAPPER_FILE="$PTERODACTYL_DIR/resources/views/templates/wrapper.blade.php"
    
    if [ ! -f "$WRAPPER_FILE" ]; then
        print_error "Could not find wrapper.blade.php"
        print_info "Please manually add the following to your template:"
        print_manual_instructions
        return
    fi
    
    # Check if already injected
    if grep -q "bermuda" "$WRAPPER_FILE"; then
        print_warning "Theme already injected, skipping..."
        return
    fi
    
    # Inject CSS before </head>
    sed -i 's|</head>|    <link rel="stylesheet" href="{{ asset('\''themes/bermuda/theme.css'\'') }}">\n</head>|g' "$WRAPPER_FILE"
    
    # Inject JS before </body>
    sed -i 's|</body>|    <script src="{{ asset('\''themes/bermuda/matrix.js'\'') }}"></script>\n</body>|g' "$WRAPPER_FILE"
    
    print_success "Theme injected successfully"
}

# Print manual installation instructions
print_manual_instructions() {
    echo ""
    echo "Add this line before </head> in your wrapper.blade.php:"
    echo '    <link rel="stylesheet" href="{{ asset('\''themes/bermuda/theme.css'\'') }}">'
    echo ""
    echo "Add this line before </body>:"
    echo '    <script src="{{ asset('\''themes/bermuda/matrix.js'\'') }}"></script>'
    echo ""
}

# Set permissions
set_permissions() {
    print_info "Setting file permissions..."
    
    # Detect web server user
    WEBUSER="www-data"
    if id "nginx" &>/dev/null; then
        WEBUSER="nginx"
    fi
    
    chown -R "$WEBUSER:$WEBUSER" "$PTERODACTYL_DIR/public/themes/bermuda"
    chmod -R 755 "$PTERODACTYL_DIR/public/themes/bermuda"
    
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

# Show completion message
show_completion() {
    echo ""
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║                                                ║"
    echo "║        Installation Completed Successfully!    ║"
    echo "║                                                ║"
    echo "╚════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo "Theme installed at: $PTERODACTYL_DIR/public/themes/bermuda"
    echo "Backup created at: $BACKUP_DIR"
    echo ""
    echo "Next steps:"
    echo "  1. Clear your browser cache (Ctrl+F5 or Cmd+Shift+R)"
    echo "  2. Visit your Pterodactyl panel"
    echo "  3. Enjoy the Bermuda Cyber theme!"
    echo ""
    echo "To customize:"
    echo "  - Edit colors: public/themes/bermuda/theme.css (modify :root variables)"
    echo "  - Disable matrix: Remove or comment matrix.js script tag"
    echo ""
    echo "To uninstall:"
    echo "  - Remove theme references from wrapper.blade.php"
    echo "  - Delete: public/themes/bermuda/"
    echo "  - Or restore from backup: $BACKUP_DIR"
    echo ""
    echo "Created by: dinethnethsara"
    echo "GitHub: https://github.com/dinethnethsara"
    echo ""
}

# Main installation function
main() {
    print_banner
    
    check_root
    detect_pterodactyl
    create_backup
    install_theme
    inject_theme
    set_permissions
    clear_cache
    restart_services
    show_completion
}

# Run installation
main "$@"
