import SpriteKit
import UIKit

final class SkylineRushScene: SKScene {
    private enum RunState {
        case menu
        case playing
        case levelClear
        case gameOver
    }

    private struct Level {
        let title: String
        let subtitle: String
        let targetKills: Int
        let spawnDelay: TimeInterval
        let enemySpeed: CGFloat
        let enemyHealth: CGFloat
    }

    private final class Enemy {
        let node: SKShapeNode
        var health: CGFloat
        var speed: CGFloat

        init(node: SKShapeNode, health: CGFloat, speed: CGFloat) {
            self.node = node
            self.health = health
            self.speed = speed
        }
    }

    private final class Shot {
        let node: SKShapeNode
        let velocity: CGVector
        var life: TimeInterval = 1.2

        init(node: SKShapeNode, velocity: CGVector) {
            self.node = node
            self.velocity = velocity
        }
    }

    private let levels: [Level] = [
        Level(title: "LEVEL 1", subtitle: "Warm-up breach", targetKills: 8, spawnDelay: 1.08, enemySpeed: 88, enemyHealth: 1),
        Level(title: "LEVEL 2", subtitle: "Rooftop storm", targetKills: 14, spawnDelay: 0.88, enemySpeed: 104, enemyHealth: 1.45),
        Level(title: "LEVEL 3", subtitle: "Final wall rush", targetKills: 22, spawnDelay: 0.68, enemySpeed: 122, enemyHealth: 2.1)
    ]

    private var runState: RunState = .menu
    private var currentLevelIndex = 0
    private var score = 0
    private var kills = 0
    private var lives = 5
    private var combo = 1
    private var lastUpdate: TimeInterval = 0
    private var spawnTimer: TimeInterval = 0
    private var fireCooldown: TimeInterval = 0

    private let worldNode = SKNode()
    private let hudNode = SKNode()
    private let overlayNode = SKNode()
    private let player = SKShapeNode(circleOfRadius: 24)
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let levelLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let livesLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let hintLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let subtitleLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let actionLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")

    private var enemies: [Enemy] = []
    private var shots: [Shot] = []

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        backgroundColor = SKColor(red: 0.04, green: 0.06, blue: 0.10, alpha: 1)
        addChild(worldNode)
        addChild(hudNode)
        addChild(overlayNode)
        configurePlayer()
        configureLabels()
        showMenu()
    }

    func relayout() {
        guard view != nil else { return }
        buildBackground()
        positionPlayer()
        layoutHUD()
        layoutOverlay()
    }

    private func configurePlayer() {
        player.fillColor = SKColor(red: 0.96, green: 0.86, blue: 0.54, alpha: 1)
        player.strokeColor = SKColor.white.withAlphaComponent(0.7)
        player.lineWidth = 4
        player.zPosition = 20
        worldNode.addChild(player)
    }

    private func configureLabels() {
        [scoreLabel, levelLabel, livesLabel, hintLabel].forEach {
            $0.zPosition = 100
            $0.horizontalAlignmentMode = .center
            hudNode.addChild($0)
        }

        scoreLabel.fontSize = 22
        levelLabel.fontSize = 18
        livesLabel.fontSize = 16
        hintLabel.fontSize = 13
        hintLabel.fontColor = SKColor.white.withAlphaComponent(0.62)
        hintLabel.text = "Tap anywhere to fire. Stop the breach."

        [titleLabel, subtitleLabel, actionLabel].forEach {
            $0.zPosition = 200
            $0.horizontalAlignmentMode = .center
            overlayNode.addChild($0)
        }

        titleLabel.fontSize = 44
        subtitleLabel.fontSize = 17
        subtitleLabel.fontColor = SKColor.white.withAlphaComponent(0.76)
        actionLabel.fontSize = 18
        actionLabel.fontColor = SKColor(red: 0.96, green: 0.72, blue: 0.30, alpha: 1)
    }

    private func buildBackground() {
        worldNode.childNode(withName: "background")?.removeFromParent()
        let bg = SKNode()
        bg.name = "background"
        bg.zPosition = -100

        let base = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        base.fillColor = SKColor(red: 0.04, green: 0.06, blue: 0.10, alpha: 1)
        base.strokeColor = .clear
        bg.addChild(base)

        for i in 0..<11 {
            let width = CGFloat.random(in: 26...58)
            let height = CGFloat.random(in: size.height * 0.18...size.height * 0.46)
            let x = CGFloat(i) / 10 * size.width
            let building = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 8)
            building.position = CGPoint(x: x, y: height / 2)
            building.fillColor = SKColor(red: 0.08, green: 0.12, blue: 0.18, alpha: 1)
            building.strokeColor = SKColor.white.withAlphaComponent(0.05)
            bg.addChild(building)
        }

        let gate = SKShapeNode(rectOf: CGSize(width: size.width * 0.82, height: 18), cornerRadius: 9)
        gate.position = CGPoint(x: size.width / 2, y: 62)
        gate.fillColor = SKColor(red: 0.52, green: 0.38, blue: 0.24, alpha: 1)
        gate.strokeColor = SKColor(red: 0.96, green: 0.72, blue: 0.30, alpha: 0.55)
        bg.addChild(gate)

        worldNode.insertChild(bg, at: 0)
    }

    private func positionPlayer() {
        player.position = CGPoint(x: size.width / 2, y: 104)
    }

    private func layoutHUD() {
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 58)
        levelLabel.position = CGPoint(x: size.width / 2, y: size.height - 92)
        livesLabel.position = CGPoint(x: size.width / 2, y: size.height - 120)
        hintLabel.position = CGPoint(x: size.width / 2, y: 26)
        updateHUD()
    }

    private func layoutOverlay() {
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.62)
        subtitleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.62 - 50)
        actionLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.62 - 96)
    }

    private func showMenu() {
        runState = .menu
        overlayNode.isHidden = false
        titleLabel.text = "SKYLINE RUSH"
        subtitleLabel.text = "Premium arcade defense"
        actionLabel.text = "TAP TO START"
        relayout()
    }

    private func startRun() {
        runState = .playing
        currentLevelIndex = 0
        score = 0
        kills = 0
        lives = 5
        combo = 1
        spawnTimer = 0
        fireCooldown = 0
        overlayNode.isHidden = true
        clearActors()
        relayout()
    }

    private func startNextLevel() {
        currentLevelIndex += 1
        if currentLevelIndex >= levels.count {
            runState = .gameOver
            overlayNode.isHidden = false
            titleLabel.text = "CITY SAVED"
            subtitleLabel.text = "Score \(score). Clean run."
            actionLabel.text = "TAP TO PLAY AGAIN"
            clearActors()
            return
        }

        runState = .playing
        kills = 0
        combo = 1
        spawnTimer = 0
        overlayNode.isHidden = true
        clearActors()
        updateHUD()
    }

    private func clearActors() {
        enemies.forEach { $0.node.removeFromParent() }
        shots.forEach { $0.node.removeFromParent() }
        enemies.removeAll()
        shots.removeAll()
    }

    private func updateHUD() {
        scoreLabel.text = "SCORE \(score)"
        let level = levels[min(currentLevelIndex, levels.count - 1)]
        levelLabel.text = "\(level.title)  •  \(kills)/\(level.targetKills)"
        livesLabel.text = "WALL INTEGRITY \(lives)  •  COMBO x\(combo)"
    }

    private func spawnEnemy() {
        let level = levels[currentLevelIndex]
        let radius = CGFloat.random(in: 20...34)
        let node = SKShapeNode(circleOfRadius: radius)
        node.position = CGPoint(x: CGFloat.random(in: 34...(size.width - 34)), y: size.height + radius + 20)
        node.fillColor = SKColor(red: 0.88, green: 0.39, blue: 0.30, alpha: 1)
        node.strokeColor = SKColor(red: 1.0, green: 0.76, blue: 0.46, alpha: 0.75)
        node.lineWidth = 3
        node.zPosition = 10

        let core = SKShapeNode(circleOfRadius: radius * 0.34)
        core.position = CGPoint(x: -radius * 0.24, y: radius * 0.18)
        core.fillColor = SKColor(red: 0.10, green: 0.05, blue: 0.05, alpha: 0.82)
        core.strokeColor = .clear
        node.addChild(core)

        worldNode.addChild(node)
        enemies.append(Enemy(node: node, health: level.enemyHealth, speed: level.enemySpeed + CGFloat.random(in: -10...24)))
    }

    private func fireShot(toward point: CGPoint) {
        guard fireCooldown <= 0 else { return }
        fireCooldown = 0.18

        let start = player.position
        let dx = point.x - start.x
        let dy = point.y - start.y
        let length = max(1, hypot(dx, dy))
        let velocity = CGVector(dx: dx / length * 760, dy: dy / length * 760)

        let shotNode = SKShapeNode(circleOfRadius: 7)
        shotNode.position = start
        shotNode.fillColor = SKColor(red: 0.96, green: 0.72, blue: 0.30, alpha: 1)
        shotNode.strokeColor = SKColor.white
        shotNode.lineWidth = 2
        shotNode.zPosition = 30
        worldNode.addChild(shotNode)
        shots.append(Shot(node: shotNode, velocity: velocity))

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.18, duration: 0.05),
            SKAction.scale(to: 1.0, duration: 0.08)
        ])
        player.run(pulse)
    }

    private func hit(enemy: Enemy, with shot: Shot) {
        shot.node.removeFromParent()
        enemy.health -= 1

        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.75, duration: 0.04),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.08)
        ])
        enemy.node.run(flash)

        if enemy.health <= 0 {
            enemy.node.removeFromParent()
            enemies.removeAll { $0 === enemy }
            score += 100 * combo
            kills += 1
            combo = min(combo + 1, 9)
            updateHUD()

            if kills >= levels[currentLevelIndex].targetKills {
                clearLevel()
            }
        }
    }

    private func clearLevel() {
        runState = .levelClear
        overlayNode.isHidden = false
        titleLabel.text = "LEVEL CLEAR"
        subtitleLabel.text = levels[currentLevelIndex].subtitle
        actionLabel.text = currentLevelIndex == levels.count - 1 ? "TAP FOR RESULT" : "TAP NEXT LEVEL"
        clearActors()
    }

    private func loseLife() {
        lives -= 1
        combo = 1
        updateHUD()

        if lives <= 0 {
            runState = .gameOver
            overlayNode.isHidden = false
            titleLabel.text = "BREACH"
            subtitleLabel.text = "Score \(score). Try a cleaner defense."
            actionLabel.text = "TAP TO RESTART"
            clearActors()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate == 0 ? 0 : min(currentTime - lastUpdate, 1.0 / 30.0)
        lastUpdate = currentTime
        guard runState == .playing else { return }

        fireCooldown = max(0, fireCooldown - dt)
        spawnTimer -= dt
        if spawnTimer <= 0 {
            spawnEnemy()
            spawnTimer = levels[currentLevelIndex].spawnDelay
        }

        for enemy in enemies {
            enemy.node.position.y -= enemy.speed * CGFloat(dt)
            if enemy.node.position.y < 74 {
                enemy.node.removeFromParent()
                enemies.removeAll { $0 === enemy }
                loseLife()
            }
        }

        for shot in shots {
            shot.life -= dt
            shot.node.position.x += shot.velocity.dx * CGFloat(dt)
            shot.node.position.y += shot.velocity.dy * CGFloat(dt)
        }

        for shot in shots where shot.life > 0 {
            if let enemy = enemies.first(where: { $0.node.frame.insetBy(dx: -8, dy: -8).contains(shot.node.position) }) {
                hit(enemy: enemy, with: shot)
                shot.life = 0
            }
        }

        shots.removeAll {
            let out = $0.life <= 0 || !$0.node.frame.intersects(CGRect(origin: .zero, size: size).insetBy(dx: -80, dy: -80))
            if out { $0.node.removeFromParent() }
            return out
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        switch runState {
        case .menu, .gameOver:
            startRun()
        case .levelClear:
            startNextLevel()
        case .playing:
            fireShot(toward: point)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard runState == .playing, let touch = touches.first else { return }
        fireShot(toward: touch.location(in: self))
    }
}
