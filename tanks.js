// tanks.js
const readline = require('readline');
const { stdin, stdout } = process;

const W = 40;
const H = 20;

let player = { x: Math.floor(W/2), y: Math.floor(H/2), dx: 0, dy: -1, symbol: '▲' };
let enemies = [];
let bullets = [];
let score = 0;
let lives = 3;
let gameOver = false;
let running = true;
let spawnTimer = 0;
const enemySpawnInterval = 40;
let shootCooldown = 0;
const shootDelay = 15;

class Bullet {
    constructor(x, y, dx, dy, bounces = 3) {
        this.x = x;
        this.y = y;
        this.dx = dx;
        this.dy = dy;
        this.bounces = bounces;
        this.alive = true;
    }

    move() {
        let newX = this.x + this.dx;
        let newY = this.y + this.dy;
        let bounced = false;
        if (newX <= 1 || newX >= W-2) {
            this.dx *= -1;
            this.bounces--;
            bounced = true;
        }
        if (newY <= 1 || newY >= H-2) {
            this.dy *= -1;
            this.bounces--;
            bounced = true;
        }
        if (bounced) {
            this.x += this.dx;
            this.y += this.dy;
        } else {
            this.x = newX;
            this.y = newY;
        }
        if (this.bounces <= 0 || this.x <= 0 || this.x >= W-1 || this.y <= 0 || this.y >= H-1) {
            this.alive = false;
        }
    }
}

function drawBorder() {
    for (let x = 0; x < W; x++) {
        process.stdout.write(`\x1b[0;${x}H#`);
        process.stdout.write(`\x1b[${H-1};${x}H#`);
    }
    for (let y = 0; y < H; y++) {
        process.stdout.write(`\x1b[${y};0H#`);
        process.stdout.write(`\x1b[${y};${W-1}H#`);
    }
}

function spawnEnemy() {
    const sides = ['top', 'bottom', 'left', 'right'];
    const side = sides[Math.floor(Math.random() * 4)];
    let x, y;
    switch(side) {
        case 'top': x = Math.floor(Math.random() * (W-4)) + 2; y = 2; break;
        case 'bottom': x = Math.floor(Math.random() * (W-4)) + 2; y = H-3; break;
        case 'left': x = 2; y = Math.floor(Math.random() * (H-4)) + 2; break;
        default: x = W-3; y = Math.floor(Math.random() * (H-4)) + 2;
    }
    if (Math.abs(x - player.x) < 3 && Math.abs(y - player.y) < 3) return;
    const dirs = [[0,1],[0,-1],[1,0],[-1,0]];
    const d = dirs[Math.floor(Math.random() * 4)];
    enemies.push({
        x, y, dx: d[0], dy: d[1],
        symbol: '▼',
        shootTimer: Math.floor(Math.random() * 60) + 30
    });
}

function shoot() {
    if (shootCooldown > 0) return;
    bullets.push(new Bullet(
        player.x + player.dx,
        player.y + player.dy,
        player.dx, player.dy, 3
    ));
    shootCooldown = shootDelay;
}

function enemyShoot(e) {
    bullets.push(new Bullet(
        e.x + e.dx,
        e.y + e.dy,
        e.dx, e.dy, 2
    ));
}

function update() {
    if (gameOver) return;
    if (shootCooldown > 0) shootCooldown--;
    spawnTimer++;
    if (spawnTimer >= enemySpawnInterval && enemies.length < 6) {
        spawnEnemy();
        spawnTimer = 0;
    }
    // Move enemies
    for (const e of enemies) {
        const dx = player.x - e.x;
        const dy = player.y - e.y;
        if (Math.abs(dx) > Math.abs(dy)) {
            e.x += dx > 0 ? 1 : -1;
        } else {
            e.y += dy > 0 ? 1 : -1;
        }
        e.x = Math.max(2, Math.min(W-3, e.x));
        e.y = Math.max(2, Math.min(H-3, e.y));
        if (Math.abs(dx) > Math.abs(dy)) {
            e.dx = dx > 0 ? 1 : -1;
            e.dy = 0;
        } else {
            e.dx = 0;
            e.dy = dy > 0 ? 1 : -1;
        }
        e.shootTimer--;
        if (e.shootTimer <= 0 && Math.random() < 0.3) {
            enemyShoot(e);
            e.shootTimer = Math.floor(Math.random() * 80) + 40;
        }
        if (e.x === player.x && e.y === player.y) {
            lives--;
            if (lives <= 0) gameOver = true;
            else { player.x = Math.floor(W/2); player.y = Math.floor(H/2); player.dx = 0; player.dy = -1; player.symbol = '▲'; }
            return;
        }
    }
    // Bullets
    for (let i = 0; i < bullets.length; i++) {
        const b = bullets[i];
        if (!b.alive) { bullets.splice(i, 1); i--; continue; }
        b.move();
        if (!b.alive) { bullets.splice(i, 1); i--; continue; }
        // Hit enemy
        let hit = false;
        for (let j = 0; j < enemies.length; j++) {
            if (enemies[j].x === b.x && enemies[j].y === b.y) {
                enemies.splice(j, 1);
                bullets.splice(i, 1);
                score += 10;
                hit = true;
                i--;
                break;
            }
        }
        if (hit) continue;
        // Hit player
        if (b.x === player.x && b.y === player.y) {
            lives--;
            bullets.splice(i, 1);
            i--;
            if (lives <= 0) gameOver = true;
            else { player.x = Math.floor(W/2); player.y = Math.floor(H/2); player.dx = 0; player.dy = -1; player.symbol = '▲'; }
        }
    }
}

function movePlayer(dx, dy) {
    if (gameOver) return;
    const nx = player.x + dx;
    const ny = player.y + dy;
    if (nx >= 2 && nx < W-2 && ny >= 2 && ny < H-2) {
        player.x = nx;
        player.y = ny;
        if (dx !== 0 || dy !== 0) {
            player.dx = dx;
            player.dy = dy;
            if (dx === 1) player.symbol = '►';
            else if (dx === -1) player.symbol = '◄';
            else if (dy === -1) player.symbol = '▲';
            else if (dy === 1) player.symbol = '▼';
        }
    }
}

function render() {
    console.clear();
    drawBorder();
    // Player
    process.stdout.write(`\x1b[${player.y};${player.x}H${player.symbol}`);
    // Enemies
    for (const e of enemies) {
        process.stdout.write(`\x1b[${e.y};${e.x}H${e.symbol}`);
    }
    // Bullets
    for (const b of bullets) {
        if (b.alive) process.stdout.write(`\x1b[${b.y};${b.x}H*`);
    }
    process.stdout.write(`\x1b[0;${W+2}HScore: ${score}  Lives: ${lives}`);
    process.stdout.write(`\x1b[1;${W+2}HEnemies: ${enemies.length}`);
    process.stdout.write(`\x1b[2;${W+2}HWASD move, Space fire`);
    if (gameOver) process.stdout.write(`\x1b[${Math.floor(H/2)};${Math.floor(W/2)-5}HGAME OVER! Press R`);
}

function setupInput() {
    readline.emitKeypressEvents(process.stdin);
    process.stdin.setRawMode(true);
    process.stdin.on('keypress', (str, key) => {
        if (key.ctrl && key.name === 'c') process.exit();
        if (key.name === 'q') process.exit();
        if (key.name === 'r' && gameOver) {
            player = { x: Math.floor(W/2), y: Math.floor(H/2), dx: 0, dy: -1, symbol: '▲' };
            enemies = [];
            bullets = [];
            score = 0;
            lives = 3;
            gameOver = false;
            spawnTimer = 0;
            return;
        }
        if (key.name === 'space') shoot();
        if (key.name === 'w' || key.name === 'up') movePlayer(0, -1);
        else if (key.name === 's' || key.name === 'down') movePlayer(0, 1);
        else if (key.name === 'a' || key.name === 'left') movePlayer(-1, 0);
        else if (key.name === 'd' || key.name === 'right') movePlayer(1, 0);
    });
}

setupInput();
setInterval(() => {
    update();
    render();
}, 50);
