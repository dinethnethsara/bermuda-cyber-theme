# Image Assets

This directory contains optional image assets for the Bermuda Cyber Family theme.

## Files

- **logo.png** - Bermuda Cyber Family logo with transparent background
- **bg-optional.png** - Optional cyberpunk circuit board background

## Usage

### Logo

To use the logo in your Pterodactyl panel navigation, edit your navigation template and add:

```html
<img src="{{ asset('themes/bermuda/images/logo.png') }}" alt="Bermuda Cyber Family" style="height: 40px;">
```

### Background Image

To use the circuit board background instead of the gradient, edit `theme.css`:

Find the `body::before` section and change:
```css
body::before {
    content: '';
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: url('../images/bg-optional.png') center/cover no-repeat fixed;
    opacity: 0.3; /* Adjust opacity as needed */
    z-index: -1;
    pointer-events: none;
}
```

## Custom Images

You can replace these files with your own:

1. **For Logo:**
   - Replace `logo.png` with your logo (PNG format with transparency recommended)
   - Recommended size: 200x50px or similar ratio

2. **For Background:**
   - Replace `bg-optional.png` with your custom background
   - Dark images work best with this theme
   - Recommended size: 1920x1080 or higher

## Notes

- Images are optional - the theme works without them
- The default theme uses CSS gradients for backgrounds
- Keep file sizes reasonable for faster loading
