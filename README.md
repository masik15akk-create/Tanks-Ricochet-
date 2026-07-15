🎮 Tanks (Ricochet) – Multi‑Language Edition
A classic tank battle game where bullets ricochet off walls!
Control your tank, shoot bouncing bullets, and eliminate enemy tanks in an arena with ricocheting projectiles.
Built in 7 programming languages – each implementation features movement, shooting, ricochet physics, enemy AI, and scoring.

✨ Features
Player control – move with WASD (or arrow keys), shoot with Space.

Ricochet bullets – bullets bounce off walls at 45° angles, adding tactical depth.

Enemy tanks – spawn periodically, move towards the player, and shoot.

Collision detection – walls, enemies, and bullets interact realistically.

Score tracking – each enemy destroyed adds points.

Lives system – lose a life when hit by an enemy bullet.

Game over – when lives reach zero.

Restart – press R to restart.

Cross‑platform – runs in any terminal (Windows, macOS, Linux).

🗂 Languages & Files
Language	File
Python	tanks.py
Go	tanks.go
JavaScript (Node)	tanks.js
C#	Tanks.cs
Java	Tanks.java
Ruby	tanks.rb
Swift	tanks.swift
🚀 How to Run
Each file is standalone – run it with the appropriate interpreter/compiler.

Language	Command
Python	python tanks.py
Go	go run tanks.go
JavaScript	node tanks.js
C#	dotnet run (or csc Tanks.cs && Tanks.exe)
Java	javac Tanks.java && java Tanks
Ruby	ruby tanks.rb
Swift	swift tanks.swift
🎮 Controls
W / ↑ – move up

S / ↓ – move down

A / ← – move left

D / → – move right

Space – shoot

R – restart after game over

Q / Esc – quit

📦 Game Mechanics
Arena: 30×20 grid with walls on all sides.

Player tank: starts in the centre, moves 1 cell per frame.

Enemy tanks: spawn randomly, chase the player, shoot periodically.

Bullets: travel in 8 directions; ricochet off walls (reflect at 90°).

Ricochet: bullets bounce off walls up to 3 times before disappearing.

Score: +10 points per enemy destroyed.

Lives: start with 3; lose one when hit by enemy bullet.

Game over: when lives reach 0.

📜 License
MIT – use freely.
