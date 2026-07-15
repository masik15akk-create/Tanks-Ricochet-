// tanks.go
package main

import (
	"fmt"
	"math/rand"
	"os"
	"os/exec"
	"time"
)

const (
	width  = 40
	height = 20
)

type Bullet struct {
	x, y      int
	dx, dy    int
	bounces   int
	alive     bool
}

type Enemy struct {
	x, y      int
	dx, dy    int
	symbol    rune
	shootTimer int
}

var (
	playerX, playerY int
	playerDirX, playerDirY int
	playerSymbol      rune
	enemies           []Enemy
	bullets           []Bullet
	score             int
	lives             int
	gameOver          bool
	running           bool
	spawnTimer        int
	enemySpawnInterval int
	shootCooldown     int
	shootDelay        int
)

func clearScreen() {
	cmd := exec.Command("clear")
	cmd.Stdout = os.Stdout
	cmd.Run()
}

func drawBorder() {
	for x := 0; x < width; x++ {
		fmt.Printf("\033[%d;%dH#", 0, x)
		fmt.Printf("\033[%d;%dH#", height-1, x)
	}
	for y := 0; y < height; y++ {
		fmt.Printf("\033[%d;%dH#", y, 0)
		fmt.Printf("\033[%d;%dH#", y, width-1)
	}
}

func spawnEnemy() {
	side := rand.Intn(4)
	var x, y int
	switch side {
	case 0:
		x = rand.Intn(width-4) + 2
		y = 2
	case 1:
		x = rand.Intn(width-4) + 2
		y = height - 3
	case 2:
		x = 2
		y = rand.Intn(height-4) + 2
	default:
		x = width - 3
		y = rand.Intn(height-4) + 2
	}
	if abs(x-playerX) < 3 && abs(y-playerY) < 3 {
		return
	}
	e := Enemy{
		x:          x,
		y:          y,
		dx:         0,
		dy:         1,
		symbol:     '▼',
		shootTimer: rand.Intn(60) + 30,
	}
	dirs := [][2]int{{0, 1}, {0, -1}, {1, 0}, {-1, 0}}
	d := dirs[rand.Intn(4)]
	e.dx, e.dy = d[0], d[1]
	enemies = append(enemies, e)
}

func abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}

func shoot() {
	if shootCooldown > 0 {
		return
	}
	b := Bullet{
		x:       playerX + playerDirX,
		y:       playerY + playerDirY,
		dx:      playerDirX,
		dy:      playerDirY,
		bounces: 3,
		alive:   true,
	}
	bullets = append(bullets, b)
	shootCooldown = shootDelay
}

func enemyShoot(e *Enemy) {
	b := Bullet{
		x:       e.x + e.dx,
		y:       e.y + e.dy,
		dx:      e.dx,
		dy:      e.dy,
		bounces: 2,
		alive:   true,
	}
	bullets = append(bullets, b)
}

func update() {
	if gameOver {
		return
	}
	if shootCooldown > 0 {
		shootCooldown--
	}
	// Spawn enemies
	spawnTimer++
	if spawnTimer >= enemySpawnInterval && len(enemies) < 6 {
		spawnEnemy()
		spawnTimer = 0
	}
	// Move enemies
	for i := range enemies {
		e := &enemies[i]
		dx := playerX - e.x
		dy := playerY - e.y
		if abs(dx) > abs(dy) {
			if dx > 0 {
				e.x++
			} else {
				e.x--
			}
		} else {
			if dy > 0 {
				e.y++
			} else {
				e.y--
			}
		}
		if e.x < 2 {
			e.x = 2
		}
		if e.x > width-3 {
			e.x = width - 3
		}
		if e.y < 2 {
			e.y = 2
		}
		if e.y > height-3 {
			e.y = height - 3
		}
		// Update direction
		if abs(dx) > abs(dy) {
			if dx > 0 {
				e.dx, e.dy = 1, 0
			} else {
				e.dx, e.dy = -1, 0
			}
		} else {
			if dy > 0 {
				e.dx, e.dy = 0, 1
			} else {
				e.dx, e.dy = 0, -1
			}
		}
		// Enemy shoots
		e.shootTimer--
		if e.shootTimer <= 0 && rand.Float64() < 0.3 {
			enemyShoot(e)
			e.shootTimer = rand.Intn(80) + 40
		}
		// Collision with player
		if e.x == playerX && e.y == playerY {
			lives--
			if lives <= 0 {
				gameOver = true
			} else {
				resetPlayer()
			}
			return
		}
	}
	// Move bullets
	for i := 0; i < len(bullets); i++ {
		b := &bullets[i]
		if !b.alive {
			continue
		}
		newX := b.x + b.dx
		newY := b.y + b.dy
		bounced := false
		if newX <= 1 || newX >= width-2 {
			b.dx *= -1
			b.bounces--
			bounced = true
		}
		if newY <= 1 || newY >= height-2 {
			b.dy *= -1
			b.bounces--
			bounced = true
		}
		if bounced {
			b.x += b.dx
			b.y += b.dy
		} else {
			b.x = newX
			b.y = newY
		}
		if b.bounces <= 0 || b.x <= 0 || b.x >= width-1 || b.y <= 0 || b.y >= height-1 {
			b.alive = false
			bullets = append(bullets[:i], bullets[i+1:]...)
			i--
			continue
		}
		// Check hit enemy
		hit := false
		for j := 0; j < len(enemies); j++ {
			if enemies[j].x == b.x && enemies[j].y == b.y {
				enemies = append(enemies[:j], enemies[j+1:]...)
				score += 10
				bullets = append(bullets[:i], bullets[i+1:]...)
				hit = true
				i--
				break
			}
		}
		if hit {
			continue
		}
		// Check hit player
		if b.x == playerX && b.y == playerY {
			lives--
			bullets = append(bullets[:i], bullets[i+1:]...)
			i--
			if lives <= 0 {
				gameOver = true
			} else {
				resetPlayer()
			}
		}
	}
}

func resetPlayer() {
	playerX = width / 2
	playerY = height / 2
	playerDirX, playerDirY = 0, -1
	playerSymbol = '▲'
}

func movePlayer(dx, dy int) {
	if gameOver {
		return
	}
	newX := playerX + dx
	newY := playerY + dy
	if newX >= 2 && newX < width-2 && newY >= 2 && newY < height-2 {
		playerX = newX
		playerY = newY
		if dx != 0 || dy != 0 {
			playerDirX, playerDirY = dx, dy
			if dx == 1 {
				playerSymbol = '►'
			} else if dx == -1 {
				playerSymbol = '◄'
			} else if dy == -1 {
				playerSymbol = '▲'
			} else if dy == 1 {
				playerSymbol = '▼'
			}
		}
	}
}

func render() {
	clearScreen()
	drawBorder()
	// Player
	fmt.Printf("\033[%d;%dH%c", playerY, playerX, playerSymbol)
	// Enemies
	for _, e := range enemies {
		fmt.Printf("\033[%d;%dH%c", e.y, e.x, e.symbol)
	}
	// Bullets
	for _, b := range bullets {
		if b.alive {
			fmt.Printf("\033[%d;%dH*", b.y, b.x)
		}
	}
	// Info
	fmt.Printf("\033[%d;%dHScore: %d  Lives: %d", 0, width+2, score, lives)
	fmt.Printf("\033[%d;%dHEnemies: %d", 1, width+2, len(enemies))
	fmt.Printf("\033[%d;%dHWASD move, Space fire", 2, width+2)
	if gameOver {
		fmt.Printf("\033[%d;%dHGAME OVER! Press R", height/2, width/2-5)
	}
}

func readInput() {
	go func() {
		for running {
			var b [1]byte
			os.Stdin.Read(b[:])
			switch b[0] {
			case 'q', 'Q':
				running = false
				os.Exit(0)
			case 'r', 'R':
				if gameOver {
					// Restart
					playerX = width / 2
					playerY = height / 2
					playerDirX, playerDirY = 0, -1
					playerSymbol = '▲'
					enemies = nil
					bullets = nil
					score = 0
					lives = 3
					gameOver = false
					spawnTimer = 0
				}
			case ' ':
				shoot()
			case 'w', 'W':
				movePlayer(0, -1)
			case 's', 'S':
				movePlayer(0, 1)
			case 'a', 'A':
				movePlayer(-1, 0)
			case 'd', 'D':
				movePlayer(1, 0)
			}
		}
	}()
}

func main() {
	rand.Seed(time.Now().UnixNano())
	fmt.Print("\033[?25l")
	// Init
	playerX = width / 2
	playerY = height / 2
	playerDirX, playerDirY = 0, -1
	playerSymbol = '▲'
	lives = 3
	score = 0
	gameOver = false
	running = true
	spawnTimer = 0
	enemySpawnInterval = 40
	shootDelay = 15
	shootCooldown = 0
	readInput()
	for running {
		update()
		render()
		time.Sleep(50 * time.Millisecond)
	}
}
