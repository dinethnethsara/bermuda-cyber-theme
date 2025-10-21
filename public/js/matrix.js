/*!
 * Bermuda Cyber Family Theme - Matrix Rain Effect
 * Author: dinethnethsara
 * GitHub: https://github.com/dinethnethsara
 */

(function() {
    'use strict';
    
    const config = {
        enabled: true,
        fontSize: 14,
        speed: 33,
        opacity: 0.3
    };
    
    class MatrixRain {
        constructor() {
            this.canvas = null;
            this.ctx = null;
            this.columns = 0;
            this.drops = [];
            this.characters = '01アイウエオカキクケコABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*';
            
            if (config.enabled) {
                this.init();
            }
        }
        
        init() {
            this.createCanvas();
            this.setupCanvas();
            this.start();
            window.addEventListener('resize', () => this.setupCanvas());
        }
        
        createCanvas() {
            this.canvas = document.createElement('canvas');
            this.canvas.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;z-index:-1;pointer-events:none;opacity:' + config.opacity;
            document.body.insertBefore(this.canvas, document.body.firstChild);
            this.ctx = this.canvas.getContext('2d');
        }
        
        setupCanvas() {
            this.canvas.width = window.innerWidth;
            this.canvas.height = window.innerHeight;
            this.columns = Math.floor(this.canvas.width / config.fontSize);
            this.drops = Array(this.columns).fill(0).map(() => ({
                y: Math.random() * -100,
                speed: 0.5 + Math.random() * 1.5
            }));
        }
        
        draw() {
            this.ctx.fillStyle = 'rgba(10, 14, 39, 0.05)';
            this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
            this.ctx.font = config.fontSize + 'px monospace';
            
            for (let i = 0; i < this.drops.length; i++) {
                const drop = this.drops[i];
                const char = this.characters[Math.floor(Math.random() * this.characters.length)];
                const x = i * config.fontSize;
                const y = drop.y * config.fontSize;
                
                if (drop.y < 2) {
                    this.ctx.fillStyle = '#00ffff';
                } else if (drop.y < 5) {
                    this.ctx.fillStyle = '#22d3ee';
                } else {
                    this.ctx.fillStyle = 'rgba(0, 212, 255, 0.8)';
                }
                
                this.ctx.fillText(char, x, y);
                drop.y += drop.speed;
                
                if (drop.y * config.fontSize > this.canvas.height && Math.random() > 0.975) {
                    drop.y = 0;
                    drop.speed = 0.5 + Math.random() * 1.5;
                }
            }
        }
        
        start() {
            const animate = () => {
                this.draw();
                setTimeout(() => requestAnimationFrame(animate), config.speed);
            };
            animate();
        }
    }
    
    // Initialize on page load
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => new MatrixRain());
    } else {
        new MatrixRain();
    }
})();
