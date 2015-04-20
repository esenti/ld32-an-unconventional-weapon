c = document.getElementById('draw')
ctx = c.getContext('2d')

delta = 0
now = 0
before = Date.now()


# c.width = window.innerWidth
# c.height = window.innerHeight

c.width = 800
c.height = 600

keysDown = {}
mouse =
    pos:
        x: 0
        y: 0

window.addEventListener("keydown", (e) ->
    keysDown[e.keyCode] = true
, false)

window.addEventListener("keyup", (e) ->
    delete keysDown[e.keyCode]
, false)


window.addEventListener("mousemove", (e) ->
    rect = c.getBoundingClientRect();
    mouse.pos =
        x: e.clientX - rect.left
        y: e.clientY - rect.top
)

window.addEventListener("mousedown", (e) ->
    mouse.down = true
    mouse.noclick = false
)

window.addEventListener("mouseup", (e) ->
    mouse.down = false
    if not mouse.noclick
        mouse.click = true
)

setDelta = ->
    now = Date.now()
    delta = (now - before) / 1000
    before = now;

player =
    x: 400
    y: 300
    speed: 70
    color: '#ffffff'
    toShoot: 0
    fireRate: 6
    health: 100

playerBullets = []

enemies = []

ammo = []

toEnemy = 2
toToEnemy = 2
toToToEnemy = 10

ogre = false

clamp = (v, min, max) ->
    if v < min then min else if v > max then max else v

collides = (a, b, as, bs) ->
    a.x + as > b.x and a.x < b.x + bs and a.y + as > b.y and a.y < b.y + bs

enemyInside = (e, i) ->
    e.x >= players[i].minX and e.x <= players[i].maxX and e.y >= players[i].minY and e.y <= players[i].maxY

getCoordinates = ->
    
    q = Math.floor(Math.random() * 4)

    if q == 0
        x = -10
        y = Math.floor(Math.random() * 600)
    else if q == 1
        x = Math.floor(Math.random() * 800)
        y = -10
    else if q == 3
        x = 810
        y = Math.floor(Math.random() * 600)
    else
        x = Math.floor(Math.random() * 800)
        y = 610

    x: x
    y: y

spawn = ->
    pos = getCoordinates()

    x: pos.x
    y: pos.y
    dx: 1
    dy: 1
    speed: speedMod / 2
    toShoot: 0
    fireRate: 4
    color: '#eeaa66'
    toSeek: 0
    seekRate: 0.8
    health: 10

speedMod = 80
elapsed = 0

update = ->
    setDelta()

    elapsed += delta
    newPlayer = {x: player.x, y: player.y}

    if keysDown[65]
        newPlayer.x = player.x - delta * player.speed
    if keysDown[68]
        newPlayer.x = player.x + delta * player.speed
    if keysDown[87]
        newPlayer.y = player.y - delta * player.speed
    if keysDown[83]
        newPlayer.y = player.y + delta * player.speed

    player.x = clamp(newPlayer.x, 0, 800)
    player.y = clamp(newPlayer.y, 0, 600)

    speedMod += delta * 0.6
    player.toShoot -= delta

    if (mouse.down or keysDown[32]) and player.toShoot <= 0
        player.toShoot = 1 / player.fireRate
        player.health -= 1

        v = 
            x: mouse.pos.x - player.x
            y: mouse.pos.y - player.y

        bullet = 
            x: player.x + player.health * 0.2 * 0.5 - 2
            y: player.y + player.health * 0.2 * 0.5 - 2
            dx: v.x / Math.sqrt(v.x * v.x + v.y * v.y)
            dy: v.y / Math.sqrt(v.x * v.x + v.y * v.y)
            speed: 130

        playerBullets.push(bullet)


    for bullet in playerBullets
        bullet.x += bullet.dx * delta * bullet.speed
        bullet.y += bullet.dy * delta * bullet.speed


    for enemy, i in enemies
        for bullet, j in playerBullets
            if collides(enemy, bullet, 10, 4)
                enemy.health -= 5
                playerBullets.splice(j, 1)
                break

        if enemy.health <= 0
            enemies.splice(i, 1)
            ammo.push(
                x: enemy.x
                y: enemy.y
            )

            if Math.random() < 0.5
                ammo.push(
                    x: enemy.x + 4
                    y: enemy.y + 10
                )

            if Math.random() < 0.5
                ammo.push(
                    x: enemy.x - 6
                    y: enemy.y + 8
                )

            break

        enemy.toSeek -= delta

        if enemy.toSeek <= 0
            enemy.toSeek = 1 / enemy.seekRate
            enemy.dx = player.x - enemy.x
            enemy.dy = player.y - enemy.y

        enemy.x += enemy.dx / Math.sqrt(enemy.dx * enemy.dx + enemy.dy * enemy.dy) * delta * enemy.speed
        enemy.y += enemy.dy / Math.sqrt(enemy.dx * enemy.dx + enemy.dy * enemy.dy) * delta * enemy.speed

        if collides(player, enemy, player.health * 0.2, 8)
            console.log 'VOOOB'
            ogre = true

    toEnemy -= delta
    if toEnemy <= 0
        toEnemy = toToEnemy

        enemies.push spawn()

    toToToEnemy -= delta
    if toToToEnemy <= 0 and toToEnemy >= 0.2
        toToToEnemy = 10
        toToEnemy -= 0.2

    i = ammo.length
    while(i--)
        if collides(ammo[i], player, 2, player.health * 0.2)
            ammo.splice(i, 1)
            player.health += 5

    player.speed = 40 + 150 / player.health

    if player.health <= 0
        ogre = true

    draw(delta)

    if not ogre

        window.requestAnimationFrame(update)


draw = (delta) ->
    ctx.fillStyle = '#000000';
    ctx.clearRect(0, 0, c.width, c.height)

    ctx.fillStyle = if ogre then 'rgba(0, 0, 0, 0.5)' else player.color
    ctx.fillRect(player.x, player.y, player.health * 0.2, player.health * 0.2)

    for a in ammo
        ctx.fillStyle = '#ffffff'
        ctx.fillRect(a.x, a.y, 3, 3)

    for enemy in enemies
        ctx.fillStyle = enemy.color
        ctx.fillRect(enemy.x, enemy.y, 8, 8)


    ctx.fillStyle = '#ffffff'
    for bullet in playerBullets
        ctx.fillRect(bullet.x, bullet.y, 5, 5)

    ctx.font = '24px Visitor'
    ctx.fillStyle = '#ffffff'
    ctx.fillText(player.health, 20, 20)

    ctx.font = '24px Visitor'
    ctx.fillStyle = '#ffffff'
    ctx.fillText(elapsed.toFixed(2), 720, 20)

    if ogre
        ctx.font = '120px Visitor'
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillStyle = '#ffffff'
        ctx.fillText('GAME OVER', 400, 300)


do ->
    w = window
    for vendor in ['ms', 'moz', 'webkit', 'o']
        break if w.requestAnimationFrame
        w.requestAnimationFrame = w["#{vendor}RequestAnimationFrame"]

    if not w.requestAnimationFrame
        targetTime = 0
        w.requestAnimationFrame = (callback) ->
            targetTime = Math.max targetTime + 16, currentTime = +new Date
            w.setTimeout (-> callback +new Date), targetTime - currentTime


update()
