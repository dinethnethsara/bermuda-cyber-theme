# Quick Start Guide

## Installation in 3 Steps

### 1. Download & Extract
```bash
cd /tmp
# Upload your theme zip or download from GitHub
unzip bermuda-cyber-theme.zip
cd bermuda-cyber-theme
```

### 2. Run Installer
```bash
sudo chmod +x install.sh
sudo ./install.sh
```

### 3. Clear Browser Cache
- **Windows/Linux:** `Ctrl + F5`
- **Mac:** `Cmd + Shift + R`

Done! Your Pterodactyl panel now has the Bermuda Cyber theme.

---

## Manual Install (if automatic fails)

```bash
# Copy files
mkdir -p /var/www/pterodactyl/public/themes/bermuda
cp public/css/theme.css /var/www/pterodactyl/public/themes/bermuda/
cp public/js/matrix.js /var/www/pterodactyl/public/themes/bermuda/

# Set permissions
chown -R www-data:www-data /var/www/pterodactyl/public/themes/bermuda
chmod -R 755 /var/www/pterodactyl/public/themes/bermuda
```

Edit `/var/www/pterodactyl/resources/views/templates/wrapper.blade.php`:

**Before `</head>` add:**
```html
<link rel="stylesheet" href="{{ asset('themes/bermuda/theme.css') }}">
```

**Before `</body>` add:**
```html
<script src="{{ asset('themes/bermuda/matrix.js') }}"></script>
```

**Clear cache:**
```bash
cd /var/www/pterodactyl
php artisan cache:clear
php artisan view:clear
systemctl reload nginx
```

---

## Quick Customization

### Change Colors
Edit `public/css/theme.css` - find `:root` section:
```css
:root {
    --bcf-primary: #00d4ff;  /* Change to your color */
}
```

### Disable Matrix Rain
Remove this line from wrapper.blade.php:
```html
<script src="{{ asset('themes/bermuda/matrix.js') }}"></script>
```

---

## Troubleshooting

**Theme not showing?**
1. Clear cache: `php artisan cache:clear; php artisan view:clear`
2. Hard refresh browser: `Ctrl+Shift+F5`
3. Check file permissions: `ls -la /var/www/pterodactyl/public/themes/bermuda`

**Matrix not working?**
- Open browser console (F12) and check for errors
- Verify matrix.js is loading in Network tab

---

For full documentation, see [README.md](README.md)

**Author:** dinethnethsara  
**GitHub:** https://github.com/dinethnethsara
