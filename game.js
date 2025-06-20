// Space Defender Game - JavaScript Logic
class SpaceDefenderGame {
    constructor() {
        this.canvas = document.getElementById('gameCanvas');
        this.ctx = this.canvas.getContext('2d');
        this.gameState = 'start'; // start, playing, paused, gameOver
        
        // Game variables
        this.score = 0;
        this.lives = 3;
        this.level = 1;
        this.gameSpeed = 1;
        
        // Game objects
        this.player = null;
        this.bullets = [];
        this.enemies = [];
        this.particles = [];
        this.powerUps = [];
        
        // Input handling
        this.keys = {};
        this.lastShot = 0;
        this.shootCooldown = 200; // milliseconds
        
        // Game settings
        this.difficulty = 'normal';
        this.muted = false;
        
        // Animation
        this.lastTime = 0;
        this.animationId = null;
        
        this.init();
    }
    
    init() {
        this.setupEventListeners();
        this.createPlayer();
        this.updateUI();
        this.showScreen('startScreen');
    }
    
    setupEventListeners() {
        // Keyboard events
        document.addEventListener('keydown', (e) => {
            this.keys[e.code] = true;
            
            if (e.code === 'Space') {
                e.preventDefault();
                if (this.gameState === 'playing') {
                    this.shoot();
                }
            }
            
            if (e.code === 'KeyP') {
                this.togglePause();
            }
        });
        
        document.addEventListener('keyup', (e) => {
            this.keys[e.code] = false;
        });
        
        // Button events
        document.getElementById('startBtn').addEventListener('click', () => {
            this.startGame();
        });
        
        document.getElementById('restartBtn').addEventListener('click', () => {
            this.restartGame();
        });
        
        document.getElementById('pauseBtn').addEventListener('click', () => {
            this.togglePause();
        });
        
        document.getElementById('muteBtn').addEventListener('click', () => {
            this.toggleMute();
        });
        
        document.getElementById('difficulty').addEventListener('change', (e) => {
            this.difficulty = e.target.value;
            this.updateDifficulty();
        });
    }
    
    createPlayer() {
        this.player = {
            x: this.canvas.width / 2 - 25,
            y: this.canvas.height - 80,
            width: 50,
            height: 40,
            speed: 5,
            color: '#00ffff'
        };
    }
    
    startGame() {
        this.gameState = 'playing';
        this.score = 0;
        this.lives = 3;
        this.level = 1;
        this.bullets = [];
        this.enemies = [];
        this.particles = [];
        this.powerUps = [];
        
        this.createPlayer();
        this.updateUI();
        this.hideAllScreens();
        this.gameLoop();
        this.spawnEnemies();
    }
    
    restartGame() {
        this.startGame();
    }
    
    togglePause() {
        if (this.gameState === 'playing') {
            this.gameState = 'paused';
            this.showScreen('pauseScreen');
            if (this.animationId) {
                cancelAnimationFrame(this.animationId);
            }
        } else if (this.gameState === 'paused') {
            this.gameState = 'playing';
            this.hideAllScreens();
            this.gameLoop();
        }
    }
    
    toggleMute() {
        this.muted = !this.muted;
        document.getElementById('muteBtn').textContent = this.muted ? 'UNMUTE' : 'MUTE';
    }
    
    updateDifficulty() {
        const difficultySettings = {
            easy: { gameSpeed: 0.7, shootCooldown: 150 },
            normal: { gameSpeed: 1, shootCooldown: 200 },
            hard: { gameSpeed: 1.5, shootCooldown: 300 }
        };
        
        const settings = difficultySettings[this.difficulty];
        this.gameSpeed = settings.gameSpeed;
        this.shootCooldown = settings.shootCooldown;
    }
    
    gameLoop(currentTime = 0) {
        if (this.gameState !== 'playing') return;
        
        const deltaTime = currentTime - this.lastTime;
        this.lastTime = currentTime;
        
        this.update(deltaTime);
        this.render();
        
        this.animationId = requestAnimationFrame((time) => this.gameLoop(time));
    }
    
    update(deltaTime) {
        this.updatePlayer();
        this.updateBullets();
        this.updateEnemies();
        this.updateParticles();
        this.updatePowerUps();
        this.checkCollisions();
        this.checkLevelProgression();
    }
    
    updatePlayer() {
        if (this.keys['ArrowLeft'] && this.player.x > 0) {
            this.player.x -= this.player.speed;
        }
        if (this.keys['ArrowRight'] && this.player.x < this.canvas.width - this.player.width) {
            this.player.x += this.player.speed;
        }
    }
    
    shoot() {
        const now = Date.now();
        if (now - this.lastShot > this.shootCooldown) {
            this.bullets.push({
                x: this.player.x + this.player.width / 2 - 2,
                y: this.player.y,
                width: 4,
                height: 10,
                speed: 8,
                color: '#00ff00'
            });
            this.lastShot = now;
        }
    }
    
    updateBullets() {
        this.bullets = this.bullets.filter(bullet => {
            bullet.y -= bullet.speed;
            return bullet.y > -bullet.height;
        });
    }
    
    spawnEnemies() {
        if (this.gameState !== 'playing') return;
        
        const spawnRate = Math.max(500 - (this.level * 50), 200);
        
        setTimeout(() => {
            if (this.gameState === 'playing') {
                this.enemies.push({
                    x: Math.random() * (this.canvas.width - 40),
                    y: -40,
                    width: 40,
                    height: 30,
                    speed: (1 + Math.random() * 2) * this.gameSpeed,
                    color: `hsl(${Math.random() * 360}, 70%, 50%)`,
                    health: 1
                });
                this.spawnEnemies();
            }
        }, spawnRate);
    }
    
    updateEnemies() {
        this.enemies = this.enemies.filter(enemy => {
            enemy.y += enemy.speed;
            
            // Remove enemies that are off screen
            if (enemy.y > this.canvas.height) {
                this.lives--;
                this.updateUI();
                if (this.lives <= 0) {
                    this.gameOver();
                }
                return false;
            }
            return true;
        });
    }
    
    updateParticles() {
        this.particles = this.particles.filter(particle => {
            particle.x += particle.vx;
            particle.y += particle.vy;
            particle.life--;
            particle.alpha = particle.life / particle.maxLife;
            return particle.life > 0;
        });
    }
    
    updatePowerUps() {
        this.powerUps = this.powerUps.filter(powerUp => {
            powerUp.y += powerUp.speed;
            return powerUp.y < this.canvas.height;
        });
    }
    
    checkCollisions() {
        // Bullet-Enemy collisions
        for (let i = this.bullets.length - 1; i >= 0; i--) {
            for (let j = this.enemies.length - 1; j >= 0; j--) {
                if (this.isColliding(this.bullets[i], this.enemies[j])) {
                    this.createExplosion(this.enemies[j].x + this.enemies[j].width / 2, 
                                       this.enemies[j].y + this.enemies[j].height / 2);
                    
                    this.bullets.splice(i, 1);
                    this.enemies.splice(j, 1);
                    this.score += 10;
                    this.updateUI();
                    break;
                }
            }
        }
        
        // Player-Enemy collisions
        for (let i = this.enemies.length - 1; i >= 0; i--) {
            if (this.isColliding(this.player, this.enemies[i])) {
                this.createExplosion(this.enemies[i].x + this.enemies[i].width / 2, 
                                   this.enemies[i].y + this.enemies[i].height / 2);
                
                this.enemies.splice(i, 1);
                this.lives--;
                this.updateUI();
                
                if (this.lives <= 0) {
                    this.gameOver();
                }
                break;
            }
        }
    }
    
    isColliding(rect1, rect2) {
        return rect1.x < rect2.x + rect2.width &&
               rect1.x + rect1.width > rect2.x &&
               rect1.y < rect2.y + rect2.height &&
               rect1.y + rect1.height > rect2.y;
    }
    
    createExplosion(x, y) {
        for (let i = 0; i < 8; i++) {
            this.particles.push({
                x: x,
                y: y,
                vx: (Math.random() - 0.5) * 6,
                vy: (Math.random() - 0.5) * 6,
                life: 30,
                maxLife: 30,
                alpha: 1,
                color: `hsl(${Math.random() * 60 + 15}, 100%, 50%)`
            });
        }
    }
    
    checkLevelProgression() {
        const scoreThreshold = this.level * 100;
        if (this.score >= scoreThreshold) {
            this.level++;
            this.updateUI();
        }
    }
    
    gameOver() {
        this.gameState = 'gameOver';
        document.getElementById('finalScore').textContent = this.score;
        this.showScreen('gameOverScreen');
        if (this.animationId) {
            cancelAnimationFrame(this.animationId);
        }
    }
    
    render() {
        // Clear canvas
        this.ctx.fillStyle = 'rgba(0, 4, 40, 0.1)';
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
        
        // Draw player
        this.drawPlayer();
        
        // Draw bullets
        this.bullets.forEach(bullet => this.drawBullet(bullet));
        
        // Draw enemies
        this.enemies.forEach(enemy => this.drawEnemy(enemy));
        
        // Draw particles
        this.particles.forEach(particle => this.drawParticle(particle));
        
        // Draw power-ups
        this.powerUps.forEach(powerUp => this.drawPowerUp(powerUp));
    }
    
    drawPlayer() {
        const player = this.player;
        
        // Player body
        this.ctx.fillStyle = player.color;
        this.ctx.fillRect(player.x, player.y, player.width, player.height);
        
        // Player glow effect
        this.ctx.shadowColor = player.color;
        this.ctx.shadowBlur = 10;
        this.ctx.fillRect(player.x, player.y, player.width, player.height);
        this.ctx.shadowBlur = 0;
        
        // Player details
        this.ctx.fillStyle = '#ffffff';
        this.ctx.fillRect(player.x + 20, player.y + 5, 10, 5);
        this.ctx.fillRect(player.x + 15, player.y + 15, 20, 3);
    }
    
    drawBullet(bullet) {
        this.ctx.fillStyle = bullet.color;
        this.ctx.shadowColor = bullet.color;
        this.ctx.shadowBlur = 5;
        this.ctx.fillRect(bullet.x, bullet.y, bullet.width, bullet.height);
        this.ctx.shadowBlur = 0;
    }
    
    drawEnemy(enemy) {
        this.ctx.fillStyle = enemy.color;
        this.ctx.shadowColor = enemy.color;
        this.ctx.shadowBlur = 8;
        this.ctx.fillRect(enemy.x, enemy.y, enemy.width, enemy.height);
        this.ctx.shadowBlur = 0;
        
        // Enemy details
        this.ctx.fillStyle = '#ff0000';
        this.ctx.fillRect(enemy.x + 5, enemy.y + 5, 5, 5);
        this.ctx.fillRect(enemy.x + 30, enemy.y + 5, 5, 5);
    }
    
    drawParticle(particle) {
        this.ctx.save();
        this.ctx.globalAlpha = particle.alpha;
        this.ctx.fillStyle = particle.color;
        this.ctx.fillRect(particle.x - 2, particle.y - 2, 4, 4);
        this.ctx.restore();
    }
    
    drawPowerUp(powerUp) {
        this.ctx.fillStyle = powerUp.color;
        this.ctx.shadowColor = powerUp.color;
        this.ctx.shadowBlur = 10;
        this.ctx.fillRect(powerUp.x, powerUp.y, powerUp.width, powerUp.height);
        this.ctx.shadowBlur = 0;
    }
    
    updateUI() {
        document.getElementById('score').textContent = this.score;
        document.getElementById('lives').textContent = this.lives;
        document.getElementById('level').textContent = this.level;
    }
    
    showScreen(screenId) {
        this.hideAllScreens();
        document.getElementById(screenId).classList.add('active');
    }
    
    hideAllScreens() {
        const screens = document.querySelectorAll('.screen');
        screens.forEach(screen => screen.classList.remove('active'));
    }
}

// Initialize game when page loads
document.addEventListener('DOMContentLoaded', () => {
    const game = new SpaceDefenderGame();
    
    // Add some visual feedback for DevOps panel
    setInterval(() => {
        const statusItems = document.querySelectorAll('.status-value.success');
        statusItems.forEach(item => {
            item.classList.add('pulsing');
            setTimeout(() => item.classList.remove('pulsing'), 1000);
        });
    }, 5000);
});
