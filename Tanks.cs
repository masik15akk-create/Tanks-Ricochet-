// Tanks.cs
using System;
using System.Collections.Generic;
using System.Threading;

class Bullet
{
    public int X, Y, DX, DY, Bounces;
    public bool Alive;
    public Bullet(int x, int y, int dx, int dy, int bounces = 3)
    {
        X = x; Y = y; DX = dx; DY = dy; Bounces = bounces; Alive = true;
    }
    public void Move(int w, int h)
    {
        int nx = X + DX, ny = Y + DY;
        bool bounced = false;
        if (nx <= 1 || nx >= w-2) { DX *= -1; Bounces--; bounced = true; }
        if (ny <= 1 || ny >= h-2) { DY *= -1; Bounces--; bounced = true; }
        if (bounced) { X += DX; Y += DY; }
        else { X = nx; Y = ny; }
        if (Bounces <= 0 || X <= 0 || X >= w-1 || Y <= 0 || Y >= h-1)
            Alive = false;
    }
}

class Tanks
{
    const int W = 40, H = 20;
    static Random rand = new Random();
    static int pX, pY, pDX, pDY;
    static char pSym;
    static List<(int x, int y, int dx, int dy, char sym, int shootTimer)> enemies =
        new List<(int, int, int, int, char, int)>();
    static List<Bullet> bullets = new List<Bullet>();
    static int score = 0, lives = 3;
    static bool gameOver = false, running = true;
    static int spawnTimer = 0, enemySpawnInterval = 40;
    static int shootCooldown = 0, shootDelay = 15;

    static void DrawBorder()
    {
        for (int x = 0; x < W; x++)
        {
            Console.SetCursorPosition(x, 0); Console.Write('#');
            Console.SetCursorPosition(x, H-1); Console.Write('#');
        }
        for (int y = 0; y < H; y++)
        {
            Console.SetCursorPosition(0, y); Console.Write('#');
            Console.SetCursorPosition(W-1, y); Console.Write('#');
        }
    }

    static void SpawnEnemy()
    {
        int side = rand.Next(4);
        int x=0, y=0;
        switch(side)
        {
            case 0: x = rand.Next(2, W-2); y = 2; break;
            case 1: x = rand.Next(2, W-2); y = H-3; break;
            case 2: x = 2; y = rand.Next(2, H-2); break;
            default: x = W-3; y = rand.Next(2, H-2); break;
        }
        if (Math.Abs(x-pX) < 3 && Math.Abs(y-pY) < 3) return;
        int[] dirs = {0,1,0,-1,1,0,-1,0};
        int d = rand.Next(4)*2;
        enemies.Add((x, y, dirs[d], dirs[d+1], '▼', rand.Next(30, 90)));
    }

    static void Shoot()
    {
        if (shootCooldown > 0) return;
        bullets.Add(new Bullet(pX + pDX, pY + pDY, pDX, pDY, 3));
        shootCooldown = shootDelay;
    }

    static void EnemyShoot(ref (int x, int y, int dx, int dy, char sym, int shootTimer) e)
    {
        bullets.Add(new Bullet(e.x + e.dx, e.y + e.dy, e.dx, e.dy, 2));
    }

    static void Update()
    {
        if (gameOver) return;
        if (shootCooldown > 0) shootCooldown--;
        spawnTimer++;
        if (spawnTimer >= enemySpawnInterval && enemies.Count < 6)
        {
            SpawnEnemy();
            spawnTimer = 0;
        }
        for (int i = 0; i < enemies.Count; i++)
        {
            var e = enemies[i];
            int dx = pX - e.x, dy = pY - e.y;
            if (Math.Abs(dx) > Math.Abs(dy))
                e.x += dx > 0 ? 1 : -1;
            else
                e.y += dy > 0 ? 1 : -1;
            e.x = Math.Max(2, Math.Min(W-3, e.x));
            e.y = Math.Max(2, Math.Min(H-3, e.y));
            if (Math.Abs(dx) > Math.Abs(dy))
                { e.dx = dx > 0 ? 1 : -1; e.dy = 0; }
            else
                { e.dx = 0; e.dy = dy > 0 ? 1 : -1; }
            e.shootTimer--;
            if (e.shootTimer <= 0 && rand.NextDouble() < 0.3)
            {
                EnemyShoot(ref e);
                e.shootTimer = rand.Next(40, 120);
            }
            if (e.x == pX && e.y == pY)
            {
                lives--;
                if (lives <= 0) gameOver = true;
                else { pX = W/2; pY = H/2; pDX = 0; pDY = -1; pSym = '▲'; }
                enemies[i] = e;
                return;
            }
            enemies[i] = e;
        }
        for (int i = 0; i < bullets.Count; i++)
        {
            var b = bullets[i];
            if (!b.Alive) { bullets.RemoveAt(i); i--; continue; }
            b.Move(W, H);
            if (!b.Alive) { bullets.RemoveAt(i); i--; continue; }
            bool hit = false;
            for (int j = 0; j < enemies.Count; j++)
            {
                if (enemies[j].x == b.X && enemies[j].y == b.Y)
                {
                    enemies.RemoveAt(j);
                    bullets.RemoveAt(i);
                    score += 10;
                    hit = true;
                    i--;
                    break;
                }
            }
            if (hit) continue;
            if (b.X == pX && b.Y == pY)
            {
                lives--;
                bullets.RemoveAt(i);
                i--;
                if (lives <= 0) gameOver = true;
                else { pX = W/2; pY = H/2; pDX = 0; pDY = -1; pSym = '▲'; }
            }
        }
    }

    static void MovePlayer(int dx, int dy)
    {
        if (gameOver) return;
        int nx = pX + dx, ny = pY + dy;
        if (nx >= 2 && nx < W-2 && ny >= 2 && ny < H-2)
        {
            pX = nx; pY = ny;
            if (dx != 0 || dy != 0)
            {
                pDX = dx; pDY = dy;
                if (dx == 1) pSym = '►';
                else if (dx == -1) pSym = '◄';
                else if (dy == -1) pSym = '▲';
                else if (dy == 1) pSym = '▼';
            }
        }
    }

    static void Render()
    {
        Console.Clear();
        DrawBorder();
        Console.SetCursorPosition(pX, pY); Console.Write(pSym);
        foreach (var e in enemies)
        {
            Console.SetCursorPosition(e.x, e.y);
            Console.Write(e.sym);
        }
        foreach (var b in bullets)
            if (b.Alive)
            {
                Console.SetCursorPosition(b.X, b.Y);
                Console.Write('*');
            }
        Console.SetCursorPosition(W+2, 0);
        Console.Write($"Score: {score}  Lives: {lives}");
        Console.SetCursorPosition(W+2, 1);
        Console.Write($"Enemies: {enemies.Count}");
        Console.SetCursorPosition(W+2, 2);
        Console.Write("WASD move, Space fire");
        if (gameOver)
        {
            Console.SetCursorPosition(W/2-5, H/2);
            Console.Write("GAME OVER! Press R");
        }
    }

    static void Restart()
    {
        pX = W/2; pY = H/2; pDX = 0; pDY = -1; pSym = '▲';
        enemies.Clear();
        bullets.Clear();
        score = 0; lives = 3; gameOver = false; spawnTimer = 0;
    }

    static void InputLoop()
    {
        while (running)
        {
            var key = Console.ReadKey(true);
            switch (key.Key)
            {
                case ConsoleKey.R:
                    if (gameOver) Restart();
                    break;
                case ConsoleKey.Spacebar:
                    Shoot();
                    break;
                case ConsoleKey.W:
                case ConsoleKey.UpArrow:
                    MovePlayer(0, -1);
                    break;
                case ConsoleKey.S:
                case ConsoleKey.DownArrow:
                    MovePlayer(0, 1);
                    break;
                case ConsoleKey.A:
                case ConsoleKey.LeftArrow:
                    MovePlayer(-1, 0);
                    break;
                case ConsoleKey.D:
                case ConsoleKey.RightArrow:
                    MovePlayer(1, 0);
                    break;
                case ConsoleKey.Q:
                    running = false;
                    return;
            }
        }
    }

    static void Main()
    {
        Console.CursorVisible = false;
        pX = W/2; pY = H/2; pDX = 0; pDY = -1; pSym = '▲';
        Thread inputThread = new Thread(InputLoop);
        inputThread.IsBackground = true;
        inputThread.Start();
        while (running)
        {
            Update();
            Render();
            Thread.Sleep(50);
        }
    }
}
