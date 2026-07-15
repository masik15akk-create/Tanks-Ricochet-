// tanks.swift
import Foundation

let W = 40
let H = 20

struct Bullet {
    var x, y, dx, dy, bounces: Int
    var alive: Bool
}

var pX = W/2, pY = H/2, pDX = 0, pDY = -1
var pSym: Character = "▲"
var enemies: [(x: Int, y: Int, dx: Int, dy: Int, sym: Character, shootTimer: Int)] = []
var bullets: [Bullet] = []
var score = 0, lives = 3
var gameOver = false, running = true
var spawnTimer = 0, enemySpawnInterval = 40
var shootCooldown = 0, shootDelay = 15

func drawBorder() {
    for x in 0..<W {
        print("\u{001B}[0;\(x)H#", terminator: "")
        print("\u{001B}[\(H-1);\(x)H#", terminator: "")
    }
    for y in 0..<H {
        print("\u{001B}[\(y);0H#", terminator: "")
        print("\u{001B}[\(y);\(W-1)H#", terminator: "")
    }
}

func spawnEnemy() {
    let side = Int.random(in: 0..<4)
    var x = 0, y = 0
    switch side {
    case 0: x = Int.random(in: 2..<W-2); y = 2
    case 1: x = Int.random(in: 2..<W-2); y = H-3
    case 2: x = 2; y = Int.random(in: 2..<H-2)
    default: x = W-3; y = Int.random(in: 2..<H-2)
    }
    if abs(x - pX) < 3 && abs(y - pY) < 3 { return }
    let dirs = [(0,1), (0,-1), (1,0), (-1,0)]
    let d = dirs.randomElement()!
    enemies.append((x: x, y: y, dx: d.0, dy: d.1, sym: "▼", shootTimer: Int.random(in: 30...90)))
}

func shoot() {
    if shootCooldown > 0 { return }
    bullets.append(Bullet(
        x: pX + pDX, y: pY + pDY,
        dx: pDX, dy: pDY,
        bounces: 3, alive: true
    ))
    shootCooldown = shootDelay
}

func enemyShoot(_ e: (x: Int, y: Int, dx: Int, dy: Int, sym: Character, shootTimer: Int)) {
    bullets.append(Bullet(
        x: e.x + e.dx, y: e.y + e.dy,
        dx: e.dx, dy: e.dy,
        bounces: 2, alive: true
    ))
}

func update() {
    if gameOver { return }
    if shootCooldown > 0 { shootCooldown -= 1 }
    spawnTimer += 1
    if spawnTimer >= enemySpawnInterval && enemies.count < 6 {
        spawnEnemy()
        spawnTimer = 0
    }
    for i in 0..<enemies.count {
        var e = enemies[i]
        let dx = pX - e.x, dy = pY - e.y
        if abs(dx) > abs(dy) {
            e.x += dx > 0 ? 1 : -1
        } else {
            e.y += dy > 0 ? 1 : -1
        }
        e.x = max(2, min(W-3, e.x))
        e.y = max(2, min(H-3, e.y))
        if abs(dx) > abs(dy) {
            e.dx = dx > 0 ? 1 : -1
            e.dy = 0
        } else {
            e.dx = 0
            e.dy = dy > 0 ? 1 : -1
        }
        e.shootTimer -= 1
        if e.shootTimer <= 0 && Double.random(in: 0...1) < 0.3 {
            enemyShoot(e)
            e.shootTimer = Int.random(in: 40...120)
        }
        if e.x == pX && e.y == pY {
            lives -= 1
            if lives <= 0 {
                gameOver = true
            } else {
                pX = W/2; pY = H/2; pDX = 0; pDY = -1; pSym = "▲"
            }
            enemies[i] = e
            return
        }
        enemies[i] = e
    }
    var i = 0
    while i < bullets.count {
        if !bullets[i].alive {
            bullets.remove(at: i)
            continue
        }
        var b = bullets[i]
        let nx = b.x + b.dx, ny = b.y + b.dy
        var bounced = false
        if nx <= 1 || nx >= W-2 {
            b.dx *= -1; b.bounces -= 1; bounced = true
        }
        if ny <= 1 || ny >= H-2 {
            b.dy *= -1; b.bounces -= 1; bounced = true
        }
        if bounced {
            b.x += b.dx; b.y += b.dy
        } else {
            b.x = nx; b.y = ny
        }
        if b.bounces <= 0 || b.x <= 0 || b.x >= W-1 || b.y <= 0 || b.y >= H-1 {
            b.alive = false
            bullets.remove(at: i)
            continue
        }
        var hit = false
        for j in 0..<enemies.count {
            if enemies[j].x == b.x && enemies[j].y == b.y {
                enemies.remove(at: j)
                bullets.remove(at: i)
                score += 10
                hit = true
                break
            }
        }
        if hit { continue }
        if b.x == pX && b.y == pY {
            lives -= 1
            bullets.remove(at: i)
            if lives <= 0 {
                gameOver = true
            } else {
                pX = W/2; pY = H/2; pDX = 0; pDY = -1; pSym = "▲"
            }
            continue
        }
        bullets[i] = b
        i += 1
    }
}

func movePlayer(dx: Int, dy: Int) {
    if gameOver { return }
    let nx = pX + dx, ny = pY + dy
    if nx >= 2 && nx < W-2 && ny >= 2 && ny < H-2 {
        pX = nx; pY = ny
        if dx != 0 || dy != 0 {
            pDX = dx; pDY = dy
            if dx == 1 { pSym = "►" }
            else if dx == -1 { pSym = "◄" }
            else if dy == -1 { pSym = "▲" }
            else if dy == 1 { pSym = "▼" }
        }
    }
}

func render() {
    print("\u{001B}[2J", terminator: "")
    drawBorder()
    print("\u{001B}[\(pY);\(pX)H\(pSym)", terminator: "")
    for e in enemies {
        print("\u{001B}[\(e.y);\(e.x)H\(e.sym)", terminator: "")
    }
    for b in bullets {
        if b.alive {
            print("\u{001B}[\(b.y);\(b.x)H*", terminator: "")
        }
    }
    print("\u{001B}[0;\(W+2)HScore: \(score)  Lives: \(lives)", terminator: "")
    print("\u{001B}[1;\(W+2)HEnemies: \(enemies.count)", terminator: "")
    print("\u{001B}[2;\(W+2)HWASD move, Space fire", terminator: "")
    if gameOver {
        print("\u{001B}[\(H/2);\(W/2-5)HGAME OVER! Press R", terminator: "")
    }
}

func restart() {
    pX = W/2; pY = H/2; pDX = 0; pDY = -1; pSym = "▲"
    enemies.removeAll()
    bullets.removeAll()
    score = 0; lives = 3; gameOver = false; spawnTimer = 0
}

func inputLoop() {
    while running {
        let input = readLine(strippingNewline: false) ?? ""
        let chars = Array(input)
        if chars.isEmpty { continue }
        let ch = chars[0]
        switch ch {
        case "q", "Q": running = false
        case "r", "R":
            if gameOver { restart() }
        case " ":
            shoot()
        case "w", "W": movePlayer(dx: 0, dy: -1)
        case "s", "S": movePlayer(dx: 0, dy: 1)
        case "a", "A": movePlayer(dx: -1, dy: 0)
        case "d", "D": movePlayer(dx: 1, dy: 0)
        default: break
        }
    }
}

DispatchQueue.global().async {
    inputLoop()
}

while running {
    update()
    render()
    Thread.sleep(forTimeInterval: 0.05)
}
