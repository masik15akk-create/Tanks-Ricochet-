# tanks.rb
require 'io/console'
require 'timeout'

W = 40
H = 20

$pX = W/2
$pY = H/2
$pDX = 0
$pDY = -1
$pSym = '▲'
$enemies = []
$bullets = []
$score = 0
$lives = 3
$game_over = false
$running = true
$spawn_timer = 0
$enemy_spawn_interval = 40
$shoot_cooldown = 0
$shoot_delay = 15

Bullet = Struct.new(:x, :y, :dx, :dy, :bounces, :alive)

def draw_border
  (0...W).each { |x| print "\e[0;#{x}H#" }
  (0...W).each { |x| print "\e[#{H-1};#{x}H#" }
  (0...H).each { |y| print "\e[#{y};0H#" }
  (0...H).each { |y| print "\e[#{y};#{W-1}H#" }
end

def spawn_enemy
  side = rand(4)
  case side
  when 0 then x = rand(2...W-2); y = 2
  when 1 then x = rand(2...W-2); y = H-3
  when 2 then x = 2; y = rand(2...H-2)
  else x = W-3; y = rand(2...H-2)
  end
  return if (x - $pX).abs < 3 && (y - $pY).abs < 3
  dirs = [[0,1],[0,-1],[1,0],[-1,0]]
  d = dirs.sample
  $enemies << {x: x, y: y, dx: d[0], dy: d[1], sym: '▼', shoot_timer: rand(30..90)}
end

def shoot
  return if $shoot_cooldown > 0
  $bullets << Bullet.new($pX + $pDX, $pY + $pDY, $pDX, $pDY, 3, true)
  $shoot_cooldown = $shoot_delay
end

def enemy_shoot(e)
  $bullets << Bullet.new(e[:x] + e[:dx], e[:y] + e[:dy], e[:dx], e[:dy], 2, true)
end

def update
  return if $game_over
  $shoot_cooldown -= 1 if $shoot_cooldown > 0
  $spawn_timer += 1
  if $spawn_timer >= $enemy_spawn_interval && $enemies.size < 6
    spawn_enemy
    $spawn_timer = 0
  end
  $enemies.each do |e|
    dx = $pX - e[:x]
    dy = $pY - e[:y]
    if dx.abs > dy.abs
      e[:x] += dx > 0 ? 1 : -1
    else
      e[:y] += dy > 0 ? 1 : -1
    end
    e[:x] = [2, [W-3, e[:x]].min].max
    e[:y] = [2, [H-3, e[:y]].min].max
    if dx.abs > dy.abs
      e[:dx] = dx > 0 ? 1 : -1
      e[:dy] = 0
    else
      e[:dx] = 0
      e[:dy] = dy > 0 ? 1 : -1
    end
    e[:shoot_timer] -= 1
    if e[:shoot_timer] <= 0 && rand < 0.3
      enemy_shoot(e)
      e[:shoot_timer] = rand(40..120)
    end
    if e[:x] == $pX && e[:y] == $pY
      $lives -= 1
      if $lives <= 0
        $game_over = true
      else
        $pX = W/2; $pY = H/2; $pDX = 0; $pDY = -1; $pSym = '▲'
      end
      return
    end
  end
  $bullets.each_with_index do |b, i|
    next unless b.alive
    nx = b.x + b.dx
    ny = b.y + b.dy
    bounced = false
    if nx <= 1 || nx >= W-2
      b.dx *= -1
      b.bounces -= 1
      bounced = true
    end
    if ny <= 1 || ny >= H-2
      b.dy *= -1
      b.bounces -= 1
      bounced = true
    end
    if bounced
      b.x += b.dx
      b.y += b.dy
    else
      b.x = nx
      b.y = ny
    end
    if b.bounces <= 0 || b.x <= 0 || b.x >= W-1 || b.y <= 0 || b.y >= H-1
      b.alive = false
      $bullets.delete_at(i)
      next
    end
    hit = false
    $enemies.each_with_index do |e, j|
      if e[:x] == b.x && e[:y] == b.y
        $enemies.delete_at(j)
        $bullets.delete_at(i)
        $score += 10
        hit = true
        break
      end
    end
    next if hit
    if b.x == $pX && b.y == $pY
      $lives -= 1
      $bullets.delete_at(i)
      if $lives <= 0
        $game_over = true
      else
        $pX = W/2; $pY = H/2; $pDX = 0; $pDY = -1; $pSym = '▲'
      end
    end
  end
end

def move_player(dx, dy)
  return if $game_over
  nx = $pX + dx
  ny = $pY + dy
  if nx >= 2 && nx < W-2 && ny >= 2 && ny < H-2
    $pX = nx
    $pY = ny
    if dx != 0 || dy != 0
      $pDX = dx
      $pDY = dy
      $pSym = case
              when dx == 1 then '►'
              when dx == -1 then '◄'
              when dy == -1 then '▲'
              when dy == 1 then '▼'
              end
    end
  end
end

def render
  system('clear') || system('cls')
  draw_border
  print "\e[#{$pY};#{$pX}H#{$pSym}"
  $enemies.each { |e| print "\e[#{e[:y]};#{e[:x]}H#{e[:sym]}" }
  $bullets.each { |b| print "\e[#{b.y};#{b.x}H*" if b.alive }
  print "\e[0;#{W+2}HScore: #{$score}  Lives: #{$lives}"
  print "\e[1;#{W+2}HEnemies: #{$enemies.size}"
  print "\e[2;#{W+2}HWASD move, Space fire"
  print "\e[#{H/2};#{W/2-5}HGAME OVER! Press R" if $game_over
end

def restart
  $pX = W/2; $pY = H/2; $pDX = 0; $pDY = -1; $pSym = '▲'
  $enemies = []
  $bullets = []
  $score = 0
  $lives = 3
  $game_over = false
  $spawn_timer = 0
end

Thread.new do
  while $running
    char = STDIN.getch
    case char
    when 'q', 'Q' then $running = false
    when 'r', 'R'
      restart if $game_over
    when ' ' then shoot
    when 'w', 'W' then move_player(0, -1)
    when 's', 'S' then move_player(0, 1)
    when 'a', 'A' then move_player(-1, 0)
    when 'd', 'D' then move_player(1, 0)
    when "\e"
      c = STDIN.read_nonblock(2) rescue nil
      if c == '[A' then move_player(0, -1)
      elsif c == '[B' then move_player(0, 1)
      elsif c == '[C' then move_player(1, 0)
      elsif c == '[D' then move_player(-1, 0)
      end
    end
  end
end

while $running
  update
  render
  sleep 0.05
end
