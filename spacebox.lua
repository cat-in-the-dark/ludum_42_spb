-- title:  game title
-- author: game developer
      -- desc:   short description
-- script: lua

T=8
W=240
H=136
EMPTY_TILE_ID=1
DEBUG_TILES=true

ST={
  SL=1,
  SR=2,
  RL=3,
  RR=4,
  JL=5,
  JR=6
}

ANIM_TICK=0
ANIM_SPEED=0.1
PL_ANIM={
  [ST.SL]={{{259},{275}}},
  [ST.SR]={{{256},{272}}},
  [ST.RL]={{{260},{276}},{{261},{277}}},
  [ST.RR]={{{257},{273}},{{258},{274}}},
  [ST.JL]={{{263},{279}}},
  [ST.JR]={{{262},{278}}}
}

function faceRight(state)
  return state == ST.SR or state == ST.JR or state == ST.RR
end

Player = {
  x=0,
  y=0,
  cr={x=0,y=0,w=8,h=16},
  vx=0,
  vy=0,
  rigid=true,
  mass=true,
  state=ST.SR,
  sp=PL_ANIM[ST.SR][1]
}

cam={x=W//2,y=H//2}

SpikeTex = {
  C=304,
  L=305,
  U=306,
  D=307,
  R=308
}

function deepcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[deepcopy(orig_key)] = deepcopy(orig_value)
    end
    setmetatable(copy, deepcopy(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

local function has_value (tab, val)
  for index, value in ipairs(tab) do
    if value == val then
      return true
    end
  end
  return false
end

LSpikes = {
  x=0,
  y=0,
  vx=0,
  vy=0,
  cr={x=0,y=0,w=240,h=136},
  rigid=false,
  mass=false,
  sp={}
}

RSpikes = deepcopy(LSpikes)
USpikes = deepcopy(LSpikes)
DSpikes = deepcopy(LSpikes)

Flag = {
  x=16,
  y=192,
  cr={x=0,y=0,w=8,h=48},
  sp={{6,1},{22,23},{38,39},{54,1},{54,1},{54,1}}
}

function drawEnt(e,cam)
  local i=1
  for i,t in ipairs(e.sp) do
    for j,v in ipairs(t) do
      spr(v, e.x+(j-1)*T+cam.x, e.y+(i-1)*T+cam.y, 0)
    end
  end
end

function vec2(xV, yV)
  return {x=xV,y=yV}
end

function v2mul(v, s)
  return vec2(v.x*s, v.y*s)
end

function v2div(v,s)
  return vec2(v.x/s, v.y/s)
end

function v2add(v1, v2)
  return vec2(v1.x+v2.x,v1.y+v2.y)
end

function v2len(v)
  return math.ceil(math.sqrt(v.x*v.x + v.y*v.y))
end

function sign(x) return x>0 and 1 or x<0 and -1 or 0 end
function lerp(a,b,t) return (1-t)*a + t*b end

BTN_UP = 0
BTN_LEFT = 2
BTN_RIGHT = 3

JMP_IMP = 3
ACCEL = 0.2

transparent_sprites_index = 0
solid_sprites_index = 80
bonus_index = 112
bonusExpired=116
spikeFirst=48
spikeLast=51

tileSky=1
tileBonusCommon=117

-- tile direction
TD={
  U=1,
  D=2,
  L=3,
  R=4
}

SPIKE_WALL_DIRS={
  [2]=TD.D,
  [3]=TD.L,
  [4]=TD.U,
  [5]=TD.R
}
SP_WALL_DIR_TILE_OFFSET = vec2(2,2)

function isTileSpikeDirFlag(tileId)
  return tileId >= 2 and tileId <= 5
end

function getCurrentRoom(x,y)
  return x//W*30,y//H*17
end

function getEntRoom(e)
  return getCurrentRoom(e.x,e.y)
end

function getSpWallDirInRoom(cx,cy)
  local off=SP_WALL_DIR_TILE_OFFSET
  local tile = mget(cx+off.x,cy+off.y)
  return isTileSpikeDirFlag(tile) and SPIKE_WALL_DIRS[tile] or 0
end

SPIKES={
  [TD.U]={e=DSpikes,x=0,y=H,vx=0,vy=-1},
  [TD.D]={e=USpikes,x=0,y=-H,vx=0,vy=1},
  [TD.L]={e=RSpikes,x=W+16,y=0,vx=-1,vy=0},
  [TD.R]={e=LSpikes,x=-W-16,y=0,vx=1,vy=0}
}

speedMulX=0.5
speedMulY=0.3
RoomCount=0

function resetSP(sp,x,y)
  sp.e.x=sp.x+x*8
  sp.e.y=sp.y+y*8
  sp.e.vx=sp.vx * speedMulX
  sp.e.vy=sp.vy * speedMulY
end

function onChangeRoom(e,x,y)
  bonusDir=0
  local dir=getSpWallDirInRoom(getEntRoom(e))
  if dir == 0 then return end
  resetSP(SPIKES[TD.U],x,y)
  resetSP(SPIKES[TD.D],x,y)
  resetSP(SPIKES[TD.L],x,y)
  resetSP(SPIKES[TD.R],x,y)
  RoomCount=RoomCount+1
end

function diffRoom(x,y)
  return x ~= crx or y ~= cry
end

crx,cry=-1,-1
function checkChangeRoom(e)
  local x1,y1=getCurrentRoom(e.x,e.y)
  local x2,y2=getCurrentRoom(e.x+e.cr.w,e.y)
  local x3,y3=getCurrentRoom(e.x,e.y+e.cr.h)
  local x4,y4=getCurrentRoom(e.x+e.cr.w,e.y+e.cr.h)
  if diffRoom(x1,y1) and diffRoom(x2,y2) and diffRoom(x3,y3) and diffRoom(x4,y4) then
    onChangeRoom(e,x1,y1)
    crx,cry=x1,y1
  end
end

BONUS_DIRS={
  [112]=TD.D,
  [113]=TD.L,
  [114]=TD.U,
  [115]=TD.R
}

bonusDir=0

function getBonusDir(c,r)
  return BONUS_DIRS[mget(c,r)]
end

REM_TILE_DIRS={
  [TD.D]={82,83},
  [TD.L]={84,85},
  [TD.U]={86,87},
  [TD.R]={88,89}
}

function isTileRemovable(tileId)
  for i,v in ipairs(REM_TILE_DIRS) do
    for j,w in ipairs(REM_TILE_DIRS[i]) do
      if w == tileId then return true end
    end
  end
  return false
end

function isTileRemoved(tileId)
  return bonusDir ~= 0 and has_value(REM_TILE_DIRS[bonusDir], tileId)
end

function isTileBonus(x,y)
  return bonus_index <= mget(x,y) and mget(x,y) < bonusExpired
end

function isTileSpike(c,r)
  id=mget(c,r)
  return id>=spikeFirst and id <=spikeLast
end

function IsTileSolid(x, y)
  tileId = mget(x, y)
  if isTileRemoved(tileId) then
    return false
  end
  return (tileId >= solid_sprites_index)
end

function collide(e1,e2)
  return (e1.x < e2.x+e2.cr.w and e2.x < e1.x + e1.cr.w) and
    (e1.y < e2.y+e2.cr.h and e2.y < e1.y+e1.cr.h)
end

function handleInput()
  local iv={pos=vec2(0,0), jump=false}
  if btn(BTN_LEFT) then
    iv.pos.x = -1
  elseif btn(BTN_RIGHT) then
    iv.pos.x = 1
  end
  if btn(BTN_UP) then
    iv.jump=true
  end
  return iv
end

--callback(c,r)
function collideTile(dp,cr,callback)
  local x1 = dp.x + cr.x
  local y1 = dp.y + cr.y
  local x2 = x1 + cr.w - 1
  local y2 = y1 + cr.h - 1
  -- check all tiles touched by the rect
  local startC = x1 // T
  local endC = x2 // T
  local startR = y1 // T
  local endR = y2 // T
  for c = startC, endC do
    for r = startR, endR do
      callback(c,r)
    end
  end
end

function CanMove(dp,cr)
  local cm=true
  collideTile(dp,cr, function(c,r)
    if IsTileSolid(c, r) then
      cm=false
      return
    end
  end)
  return cm
end

function checkHitBonus(e)
  collideTile(vec2(e.x,e.y-1),e.cr,function(c,r)
    if isTileBonus(c,r) and bonusDir == 0 then
      bonusDir = getBonusDir(c,r)
    end
  end)
end

function isOnFloor(e)
  return not CanMove(vec2(e.x,e.y+1),e.cr)
end

function isUnderCeiling(e)
  return not CanMove(vec2(e.x,e.y-1),e.cr)
end

function isTouchSpikeTiles(e)
  ts=false
  collideTile(vec2(e.x,e.y),e.cr,function(c,r)
    if isTileSpike(c,r) then
      ts=true
    end
  end)
  return ts
end

function TryMoveBy(e,dp)
  local pos=vec2(e.x, e.y)
  CM = ""
  if (e.rigid) then
    if dp.x ~= 0 then
      for i=dp.x,sign(dp.x),-1*sign(dp.x) do
        if CanMove(vec2(e.x+i,e.y),e.cr) then
          e.x=e.x+i
          break
        end
      end
    end
    if dp.y ~= 0 then
      if CanMove(vec2(e.x,e.y+dp.y),e.cr) then
        e.y=e.y+dp.y
      else
        moveby=0
        for i=0,math.ceil(dp.y),sign(dp.y) do
          if CanMove(vec2(e.x,e.y+i),e.cr) then
            moveby=i
          else
            break
          end
        end
        e.y=e.y+moveby
      end
    end
  else
    e.x=e.x+dp.x
    e.y=e.y+dp.y
  end
end

function update(e)
  local iv=handleInput()
  if (e.mass) then
    if isOnFloor(e) then
      if iv.jump then
        e.vy=-1*JMP_IMP
      else
        e.vy=0
      end
    elseif isUnderCeiling(e) and e.vy < 0 then
      e.vy=0
    else
      e.vy = e.vy + ACCEL
    end
  end
  e.vx=iv.pos.x
  local dp=vec2(e.vx, e.vy)
  checkHitBonus(e)
  TryMoveBy(e,dp)
end

function fillRect(e,x0,y0,w,h,tex)
  if e.sp == nil then e.sp = {} end
  for i=y0,h do
    if e.sp[i] == nil then e.sp[i]={} end
    for j=x0,w do
      e.sp[i][j]=tex
    end
  end
end

function updateCam(cam,e)
  cam.x=math.min(W//2,W//2-e.x)
  cam.y=math.min(H//2,H//2-e.y)
end

function updSpikeWall(dir,cam)
  if dir ~= 0 then
    local s=SPIKES[dir].e
    if math.abs(s.x)-0.2 >= 0 then s.x=s.x+s.vx end
    if math.abs(s.y)-0.2 >= 0 then s.y=s.y+s.vy end
    drawEnt(s,cam)
    return s
  end
end

-- FFFUUUUU
function updateState(e)
  if e.vx > 0 then
    if isOnFloor(e) then
      e.state=ST.RR
    else
      e.state=ST.JR
    end
  elseif e.vx < 0 then
    if isOnFloor(e) then
      e.state=ST.RL
    else
      e.state=ST.JL
    end
  elseif faceRight(e.state) then
    if isOnFloor(e) then
      e.state=ST.SR
    else
      e.state=ST.JR
    end
  else
    if isOnFloor(e) then
      e.state=ST.SL
    else
      e.state=ST.JL
    end
  end
end

function init()
  local cw = W//T
  local ch = H//T
  fillRect(LSpikes,1,1,cw,ch,SpikeTex.C)
  fillRect(RSpikes,1,1,cw,ch,SpikeTex.C)
  fillRect(USpikes,1,1,cw,ch,SpikeTex.C)
  fillRect(DSpikes,1,1,cw,ch,SpikeTex.C)
  fillRect(LSpikes,cw,1,cw,ch,SpikeTex.L)
  fillRect(RSpikes,1,1,1,ch,SpikeTex.R)
  fillRect(USpikes,1,ch,cw,ch,SpikeTex.U)
  fillRect(DSpikes,1,1,cw,1,SpikeTex.D)
  Player.x=8*8
  Player.y=4*8
  spikeDir=0
  mode=MOD_GAME
end

function TICFail()
  cls()
  print("Game over!", W/2-40, H/2, 4)
  print("-Press Z to restart!-", W/2-64, H/2+16, 4)
  if btn(4) then reset() end
end

function TICWin()
  cls()
  print("You win!", W/2-32,H/2,4)
  print("-Press Z to restart-", W/2-64, H/2+16, 4)
  if btn(4) then reset() end
end

function drawMap(e,cam)
  local cx,cy=getCurrentRoom(e.x,e.y)
  map(cx,cy,30,17,cx*8+cam.x,cy*8+cam.y,-1,1, function(tile, x, y)
    -- trace(string.format("%d %d", x, y))
    if isTileRemoved(tile) then
      return EMPTY_TILE_ID
    end
    if (bonusDir ~= 0) and isTileBonus(x,y) then
      return bonusExpired
    end
    if not DEBUG_TILES then
      if isTileSpikeDirFlag(tile) then
        return tileSky
      end
      if isTileBonus(x,y) then
        return tileBonusCommon
      end
      if isTileRemovable(tile) then
        -- EXTREMELY WTF!!!
        return 80 + (tile % 2)
      end
    end
    return tile
  end)
end

function animate(e,tex)
  local anim=tex[e.state]
  e.sp=anim[(math.floor(ANIM_TICK)%#anim)+1]
  ANIM_TICK = ANIM_TICK + ANIM_SPEED
end

function TICGame()
  cls()
  updateCam(cam,Player)
  update(Player)
  updateState(Player)
  drawMap(Player,cam)
  animate(Player,PL_ANIM)
  checkChangeRoom(Player)
  local dir=getSpWallDirInRoom(getEntRoom(Player))
  local spWall=updSpikeWall(dir,cam)
  drawEnt(Player,cam)
  -- print(string.format("%g %g %g %g, %g %g| %g", cam.x, cam.y, Player.x, Player.y, Player.x+cam.x, Player.y+cam.y, getSpWallDirInRoom(Player)), 0, 0, 4)
  if isTouchSpikeTiles(Player) then mode=MOD_FAIL end
  if collide(Player, Flag) then mode=MOD_WIN end
  if spWall ~= nil and collide(Player, spWall) then mode=MOD_FAIL end
end

MOD_GAME = 0
MOD_FAIL = 1
MOD_WIN=2

TICMode={
  [MOD_GAME]=TICGame,
  [MOD_FAIL]=TICFail,
  [MOD_WIN]=TICWin
}

init()
function TIC()
  TICMode[mode]()
end