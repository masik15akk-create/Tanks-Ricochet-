# tanks.py
import curses
import random
import time
import math

class Bullet:
    def __init__(self, x, y, dx, dy, bounces=3):
        self.x = x
        self.y = y
        self.dx = dx
        self.dy = dy
        self.bounces_left = bounces
        self.alive = True

    def move(self, width, height):
        new_x = self.x + self.dx
        new_y = self.y + self.dy
        # Ricochet off walls
        bounced = False
        if new_x <= 1 or new_x >= width - 2:
            self.dx *= -1
            self.bounces_left -= 1
            bounced = True
        if new_y <= 1 or new_y >= height - 2:
            self.dy *= -1
            self.bounces_left -= 1
            bounced = True
        if bounced:
            self.x += self.dx
            self.y += self.dy
        else:
            self.x = new_x
            self.y = new_y
        if self.bounces_left <= 0:
            self.alive = False
        # Check out of bounds
        if self.x <= 0 or self.x >= width - 1 or self.y <= 0 or self.y >= height - 1:
            self.alive = False

class TankGame:
    def __init__(self, stdscr):
        self.stdscr = stdscr
        curses.curs_set(0)
        self.stdscr.nodelay(1)
        self.stdscr.timeout(50)
        self.height, self.width = self.stdscr.getmaxyx()
        self.height = min(self.height, 24)
        self.width = min(self.width, 60)
        self.player = {'x': self.width // 2, 'y': self.height // 2, 'dir': (0, -1), 'symbol': '▲'}
        self.enemies = []
        self.bullets = []
        self.score = 0
        self.lives = 3
        self.game_over = False
        self.running = True
        self.spawn_timer = 0
        self.enemy_spawn_interval = 80
        self.shoot_cooldown = 0
        self.shoot_delay = 15
        self.enemy_shoot_timer = 0

    def draw_border(self):
        for x in range(self.width):
            self.stdscr.addch(0, x, '#')
            self.stdscr.addch(self.height - 1, x, '#')
        for y in range(self.height):
            self.stdscr.addch(y, 0, '#')
            self.stdscr.addch(y, self.width - 1, '#')

    def spawn_enemy(self):
        side = random.choice(['top', 'bottom', 'left', 'right'])
        if side == 'top':
            x = random.randint(2, self.width - 3)
            y = 2
        elif side == 'bottom':
            x = random.randint(2, self.width - 3)
            y = self.height - 3
        elif side == 'left':
            x = 2
            y = random.randint(2, self.height - 3)
        else:
            x = self.width - 3
            y = random.randint(2, self.height - 3)
        # Avoid spawning on player
        if abs(x - self.player['x']) < 3 and abs(y - self.player['y']) < 3:
            return
        self.enemies.append({
            'x': x, 'y': y,
            'dir': random.choice([(0, 1), (0, -1), (1, 0), (-1, 0)]),
            'symbol': '▼',
            'shoot_timer': random.randint(30, 90)
        })

    def shoot(self):
        if self.shoot_cooldown > 0:
            return
        dx, dy = self.player['dir']
        self.bullets.append(Bullet(
            self.player['x'] + dx,
            self.player['y'] + dy,
            dx, dy, 3
        ))
        self.shoot_cooldown = self.shoot_delay

    def enemy_shoot(self, enemy):
        dx, dy = enemy['dir']
        self.bullets.append(Bullet(
            enemy['x'] + dx,
            enemy['y'] + dy,
            dx, dy, 2
        ))

    def update(self):
        if self.game_over:
            return
        # Player shoot cooldown
        if self.shoot_cooldown > 0:
            self.shoot_cooldown -= 1
        # Spawn enemies
        self.spawn_timer += 1
        if self.spawn_timer >= self.enemy_spawn_interval and len(self.enemies) < 6:
            self.spawn_enemy()
            self.spawn_timer = 0
        # Move enemies
        for e in self.enemies:
            dx = self.player['x'] - e['x']
            dy = self.player['y'] - e['y']
            if abs(dx) > abs(dy):
                e['x'] += 1 if dx > 0 else -1
            else:
                e['y'] += 1 if dy > 0 else -1
            e['x'] = max(2, min(self.width - 3, e['x']))
            e['y'] = max(2, min(self.height - 3, e['y']))
            # Update direction for shooting
            if abs(dx) > abs(dy):
                e['dir'] = (1 if dx > 0 else -1, 0)
            else:
                e['dir'] = (0, 1 if dy > 0 else -1)
            # Enemy shoots
            e['shoot_timer'] -= 1
            if e['shoot_timer'] <= 0 and random.random() < 0.3:
                self.enemy_shoot(e)
                e['shoot_timer'] = random.randint(40, 120)
            # Collision with player
            if e['x'] == self.player['x'] and e['y'] == self.player['y']:
                self.lives -= 1
                if self.lives <= 0:
                    self.game_over = True
                else:
                    self.reset_player()
                return
        # Move bullets
        for b in self.bullets[:]:
            b.move(self.width, self.height)
            if not b.alive:
                self.bullets.remove(b)
                continue
            # Check bullet vs enemy
            hit = False
            for e in self.enemies[:]:
                if e['x'] == b.x and e['y'] == b.y:
                    self.enemies.remove(e)
                    self.bullets.remove(b)
                    self.score += 10
                    hit = True
                    break
            if hit:
                continue
            # Check bullet vs player
            if b.x == self.player['x'] and b.y == self.player['y']:
                self.lives -= 1
                self.bullets.remove(b)
                if self.lives <= 0:
                    self.game_over = True
                else:
                    self.reset_player()

    def reset_player(self):
        self.player['x'] = self.width // 2
        self.player['y'] = self.height // 2
        self.player['dir'] = (0, -1)
        self.player['symbol'] = '▲'

    def move_player(self, dx, dy):
        if self.game_over:
            return
        new_x = self.player['x'] + dx
        new_y = self.player['y'] + dy
        if 2 <= new_x < self.width - 2 and 2 <= new_y < self.height - 2:
            self.player['x'] = new_x
            self.player['y'] = new_y
            if dx != 0 or dy != 0:
                self.player['dir'] = (dx, dy)
                if dx == 1:
                    self.player['symbol'] = '►'
                elif dx == -1:
                    self.player['symbol'] = '◄'
                elif dy == -1:
                    self.player['symbol'] = '▲'
                elif dy == 1:
                    self.player['symbol'] = '▼'

    def render(self):
        self.stdscr.clear()
        self.draw_border()
        # Draw player
        self.stdscr.addch(self.player['y'], self.player['x'], self.player['symbol'])
        # Draw enemies
        for e in self.enemies:
            self.stdscr.addch(e['y'], e['x'], e['symbol'])
        # Draw bullets
        for b in self.bullets:
            self.stdscr.addch(b['y'], b['x'], '*')
        # Info
        self.stdscr.addstr(0, self.width + 2, f"Score: {self.score}  Lives: {self.lives}")
        self.stdscr.addstr(1, self.width + 2, f"Enemies: {len(self.enemies)}")
        self.stdscr.addstr(2, self.width + 2, "WASD move, Space fire")
        if self.game_over:
            self.stdscr.addstr(self.height // 2, self.width // 2 - 5, "GAME OVER! Press R")
        self.stdscr.refresh()

    def restart(self):
        self.__init__(self.stdscr)

    def run(self):
        while self.running:
            key = self.stdscr.getch()
            if key == ord('q') or key == ord('Q'):
                break
            if key == ord('r') or key == ord('R') and self.game_over:
                self.restart()
            if key == ord(' '):
                self.shoot()
            if key == ord('w') or key == ord('W') or key == curses.KEY_UP:
                self.move_player(0, -1)
            elif key == ord('s') or key == ord('S') or key == curses.KEY_DOWN:
                self.move_player(0, 1)
            elif key == ord('a') or key == ord('A') or key == curses.KEY_LEFT:
                self.move_player(-1, 0)
            elif key == ord('d') or key == ord('D') or key == curses.KEY_RIGHT:
                self.move_player(1, 0)
            self.update()
            self.render()
            time.sleep(0.05)

def main(stdscr):
    game = TankGame(stdscr)
    game.run()

if __name__ == "__main__":
    curses.wrapper(main)
