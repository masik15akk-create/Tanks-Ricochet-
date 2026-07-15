// Tanks.java
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import java.util.*;

class Bullet {
    int x, y, dx, dy, bounces;
    boolean alive;
    Bullet(int x, int y, int dx, int dy, int bounces) {
        this.x=x; this.y=y; this.dx=dx; this.dy=dy; this.bounces=bounces; alive=true;
    }
}

public class Tanks extends JPanel implements ActionListener, KeyListener {
    static final int W = 40, H = 20, CELL = 20;
    int pX = W/2, pY = H/2, pDX = 0, pDY = -1;
    char pSym = '▲';
    java.util.List<int[]> enemies = new ArrayList<>();
    java.util.List<Bullet> bullets = new ArrayList<>();
    int score = 0, lives = 3;
    boolean gameOver = false;
    Timer timer;
    Random rand = new Random();
    int spawnTimer = 0, enemySpawnInterval = 40;
    int shootCooldown = 0, shootDelay = 15;

    public Tanks() {
        setPreferredSize(new Dimension(W*CELL + 150, H*CELL));
        setBackground(Color.BLACK);
        setFocusable(true);
        addKeyListener(this);
        timer = new Timer(50, this);
        timer.start();
    }

    void spawnEnemy() {
        int side = rand.nextInt(4);
        int x=0, y=0;
        switch(side) {
            case 0: x = rand.nextInt(W-4)+2; y = 2; break;
            case 1: x = rand.nextInt(W-4)+2; y = H-3; break;
            case 2: x = 2; y = rand.nextInt(H-4)+2; break;
            default: x = W-3; y = rand.nextInt(H-4)+2;
        }
        if (Math.abs(x-pX) < 3 && Math.abs(y-pY) < 3) return;
        int[] dirs = {0,1,0,-1,1,0,-1,0};
        int d = rand.nextInt(4)*2;
        enemies.add(new int[]{x, y, dirs[d], dirs[d+1], '▼', rand.nextInt(60)+30});
    }

    void shoot() {
        if (shootCooldown > 0) return;
        bullets.add(new Bullet(pX+pDX, pY+pDY, pDX, pDY, 3));
        shootCooldown = shootDelay;
    }

    void enemyShoot(int[] e) {
        bullets.add(new Bullet(e[0]+e[2], e[1]+e[3], e[2], e[3], 2));
    }

    void update() {
        if (gameOver) return;
        if (shootCooldown > 0) shootCooldown--;
        spawnTimer++;
        if (spawnTimer >= enemySpawnInterval && enemies.size() < 6) {
            spawnEnemy();
            spawnTimer = 0;
        }
        for (int i = 0; i < enemies.size(); i++) {
            int[] e = enemies.get(i);
            int dx = pX - e[0], dy = pY - e[1];
            if (Math.abs(dx) > Math.abs(dy)) e[0] += dx > 0 ? 1 : -1;
            else e[1] += dy > 0 ? 1 : -1;
            e[0] = Math.max(2, Math.min(W-3, e[0]));
            e[1] = Math.max(2, Math.min(H-3, e[1]));
            if (Math.abs(dx) > Math.abs(dy)) { e[2] = dx > 0 ? 1 : -1; e[3] = 0; }
            else { e[2] = 0; e[3] = dy > 0 ? 1 : -1; }
            e[5]--;
            if (e[5] <= 0 && rand.nextDouble() < 0.3) {
                enemyShoot(e);
                e[5] = rand.nextInt(80)+40;
            }
            if (e[0] == pX && e[1] == pY) {
                lives--;
                if (lives <= 0) gameOver = true;
                else { pX = W/2; pY = H/2; pDX = 0; pDY = -1; pSym = '▲'; }
                enemies.set(i, e);
                return;
            }
            enemies.set(i, e);
        }
        for (int i = 0; i < bullets.size(); i++) {
            Bullet b = bullets.get(i);
            if (!b.alive) { bullets.remove(i); i--; continue; }
            int nx = b.x + b.dx, ny = b.y + b.dy;
            boolean bounced = false;
            if (nx <= 1 || nx >= W-2) { b.dx *= -1; b.bounces--; bounced = true; }
            if (ny <= 1 || ny >= H-2) { b.dy *= -1; b.bounces--; bounced = true; }
            if (bounced) { b.x += b.dx; b.y += b.dy; }
            else { b.x = nx; b.y = ny; }
            if (b.bounces <= 0 || b.x <= 0 || b.x >= W-1 || b.y <= 0 || b.y >= H-1) {
                b.alive = false;
                bullets.remove(i); i--;
                continue;
            }
            boolean hit = false;
            for (int j = 0; j < enemies.size(); j++) {
                int[] e = enemies.get(j);
                if (e[0] == b.x && e[1] == b.y) {
                    enemies.remove(j);
                    bullets.remove(i);
                    score += 10;
                    hit = true;
                    i--;
                    break;
                }
            }
            if (hit) continue;
            if (b.x == pX && b.y == pY) {
                lives--;
                bullets.remove(i);
                i--;
                if (lives <= 0) gameOver = true;
                else { pX = W/2; pY = H/2; pDX = 0; pDY = -1; pSym = '▲'; }
            }
        }
    }

    void movePlayer(int dx, int dy) {
        if (gameOver) return;
        int nx = pX + dx, ny = pY + dy;
        if (nx >= 2 && nx < W-2 && ny >= 2 && ny < H-2) {
            pX = nx; pY = ny;
            if (dx != 0 || dy != 0) {
                pDX = dx; pDY = dy;
                if (dx == 1) pSym = '►';
                else if (dx == -1) pSym = '◄';
                else if (dy == -1) pSym = '▲';
                else if (dy == 1) pSym = '▼';
            }
        }
    }

    void restart() {
        pX = W/2; pY = H/2; pDX = 0; pDY = -1; pSym = '▲';
        enemies.clear(); bullets.clear();
        score = 0; lives = 3; gameOver = false; spawnTimer = 0;
    }

    @Override
    public void actionPerformed(ActionEvent e) {
        update();
        repaint();
    }

    @Override
    public void paintComponent(Graphics g) {
        super.paintComponent(g);
        g.setColor(Color.WHITE);
        // border
        for (int x = 0; x < W; x++) {
            g.drawRect(x*CELL, 0, CELL, CELL);
            g.drawRect(x*CELL, (H-1)*CELL, CELL, CELL);
        }
        for (int y = 0; y < H; y++) {
            g.drawRect(0, y*CELL, CELL, CELL);
            g.drawRect((W-1)*CELL, y*CELL, CELL, CELL);
        }
        // player
        g.setColor(Color.GREEN);
        g.fillRect(pX*CELL, pY*CELL, CELL, CELL);
        g.setColor(Color.BLACK);
        g.drawString(String.valueOf(pSym), pX*CELL+5, pY*CELL+15);
        // enemies
        g.setColor(Color.RED);
        for (int[] e : enemies) {
            g.fillRect(e[0]*CELL, e[1]*CELL, CELL, CELL);
            g.setColor(Color.BLACK);
            g.drawString("E", e[0]*CELL+5, e[1]*CELL+15);
            g.setColor(Color.RED);
        }
        // bullets
        g.setColor(Color.YELLOW);
        for (Bullet b : bullets) {
            if (b.alive) g.fillOval(b.x*CELL+5, b.y*CELL+5, 10, 10);
        }
        // info
        g.setColor(Color.WHITE);
        g.drawString("Score: "+score, W*CELL+10, 20);
        g.drawString("Lives: "+lives, W*CELL+10, 40);
        g.drawString("Enemies: "+enemies.size(), W*CELL+10, 60);
        g.drawString("WASD move, Space fire", W*CELL+10, 80);
        if (gameOver) {
            g.setColor(Color.RED);
            g.setFont(new Font("Arial", Font.BOLD, 24));
            g.drawString("GAME OVER", W*CELL/2-50, H*CELL/2);
            g.setFont(new Font("Arial", Font.PLAIN, 14));
            g.drawString("Press R to restart", W*CELL/2-60, H*CELL/2+30);
        }
    }

    @Override
    public void keyPressed(KeyEvent e) {
        int key = e.getKeyCode();
        if (key == KeyEvent.VK_R && gameOver) restart();
        if (key == KeyEvent.VK_SPACE) shoot();
        if (key == KeyEvent.VK_W || key == KeyEvent.VK_UP) movePlayer(0, -1);
        if (key == KeyEvent.VK_S || key == KeyEvent.VK_DOWN) movePlayer(0, 1);
        if (key == KeyEvent.VK_A || key == KeyEvent.VK_LEFT) movePlayer(-1, 0);
        if (key == KeyEvent.VK_D || key == KeyEvent.VK_RIGHT) movePlayer(1, 0);
        if (key == KeyEvent.VK_Q) System.exit(0);
    }
    @Override public void keyReleased(KeyEvent e) {}
    @Override public void keyTyped(KeyEvent e) {}

    public static void main(String[] args) {
        JFrame frame = new JFrame("Tanks (Ricochet)");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setResizable(false);
        frame.add(new Tanks());
        frame.pack();
        frame.setLocationRelativeTo(null);
        frame.setVisible(true);
    }
}
