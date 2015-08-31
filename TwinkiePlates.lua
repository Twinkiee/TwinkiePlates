-----------------------------------------------------------------------------------------------
-- Client Lua Script for TwinkiePlates
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "ChallengesLib"
require "Unit"
require "GameLib"
require "Apollo"
require "PathMission"
require "Quest"
require "Episode"
require "math"
require "string"
require "DialogSys"
require "PublicEvent"
require "PublicEventObjective"
require "CommunicatorLib"
require "GroupLib"
require "PlayerPathLib"
require "bit32"


local TwinkiePlates = {}

local _ccWhiteList =
{
  [Unit.CodeEnumCCState.Blind] = "Blind",
  [Unit.CodeEnumCCState.Disarm] = "Disarm",
  [Unit.CodeEnumCCState.Disorient] = "Disorient",
  [Unit.CodeEnumCCState.Fear] = "Fear",
  [Unit.CodeEnumCCState.Knockdown] = "Knockdown",
  [Unit.CodeEnumCCState.Subdue] = "Subdue",
  [Unit.CodeEnumCCState.Stun] = "Stun",
  [Unit.CodeEnumCCState.Root] = "Root",
  [Unit.CodeEnumCCState.Tether] = "Tether",
  [Unit.CodeEnumCCState.Vulnerability] = "MoO",
}

local _exceptions =
{
  ["NyanPrime"] = false, -- Hidden
  ["Cactoid"] = true, -- Visible
  ["Spirit of the Darned"] = true,
  ["Wilderrun Trap"] = true,
}

local _color = ApolloColor.new

local _playerClass =
{
  [GameLib.CodeEnumClass.Esper] = "NPrimeNameplates_Sprites:IconEsper",
  [GameLib.CodeEnumClass.Medic] = "NPrimeNameplates_Sprites:IconMedic",
  [GameLib.CodeEnumClass.Stalker] = "NPrimeNameplates_Sprites:IconStalker",
  [GameLib.CodeEnumClass.Warrior] = "NPrimeNameplates_Sprites:IconWarrior",
  [GameLib.CodeEnumClass.Engineer] = "NPrimeNameplates_Sprites:IconEngineer",
  [GameLib.CodeEnumClass.Spellslinger] = "NPrimeNameplates_Sprites:IconSpellslinger",
}

local _npcRank =
{
  [Unit.CodeEnumRank.Elite] = "NPrimeNameplates_Sprites:icon_6_elite",
  [Unit.CodeEnumRank.Superior] = "NPrimeNameplates_Sprites:icon_5_superior",
  [Unit.CodeEnumRank.Champion] = "NPrimeNameplates_Sprites:icon_4_champion",
  [Unit.CodeEnumRank.Standard] = "NPrimeNameplates_Sprites:icon_3_standard",
  [Unit.CodeEnumRank.Minion] = "NPrimeNameplates_Sprites:icon_2_minion",
  [Unit.CodeEnumRank.Fodder] = "NPrimeNameplates_Sprites:icon_1_fodder",
}


local _dispColor =
{
  [Unit.CodeEnumDisposition.Neutral] = _color("FFFFBC55"),
  [Unit.CodeEnumDisposition.Hostile] = _color("FFFA394C"),
  [Unit.CodeEnumDisposition.Friendly] = _color("FF7DAF29"),
  [Unit.CodeEnumDisposition.Unknown] = _color("FFFFFFFF"),
}

local _typeColor =
{
  Self = _color("FF7DAF29"),
  FriendlyPc = _color("FF7DAF29"),
  FriendlyNpc = _color("xkcdKeyLime"),
  NeutralPc = _color("FFFFBC55"),
  NeutralNpc = _color("xkcdDandelion"),
  HostilePc = _color("xkcdLipstickRed"),
  HostileNpc = _color("FFFA394C"),
  Group = _color("FF7DAF29"), -- FF597CFF
  Harvest = _color("FFFFFFFF"),
  Other = _color("FFFFFFFF"),
  Hidden = _color("FFFFFFFF"),
  Special = _color("FF55FAFF"),
  Cleanse = _color("FFAF40E1"),
}

local _paths =
{
  [0] = "Soldier",
  [1] = "Settler",
  [2] = "Scientist",
  [3] = "Explorer",
}

local _matrixCategories =
{
  "Nameplates",
  "Health",
  "HealthText",
  "Class",
  "Level",
  "Title",
  "Guild",
  "CastingBar",
  "CCBar",
  "Armor",
  "TextBubbleFade",
}

local _matrixFilters =
{
  "Self",
  "Target",
  "Group",
  "FriendlyPc",
  "FriendlyNpc",
  "NeutralPc",
  "NeutralNpc",
  "HostilePc",
  "HostileNpc",

  -- "Other",
}

local _matrixButtonSprites =
{
  [0] = "MatrixOff",
  [1] = "MatrixInCombat",
  [2] = "MatrixOutOfCombat",
  [3] = "MatrixOn",
}

local _asbl =
{
  ["Chair"] = true,
  ["CityDirections"] = true,
  ["TradeskillNode"] = true,
}

local _flags =
{
  opacity = 1,
  contacts = 1,
}

local _fontPrimary =
{
  [1] = { font = "CRB_Header9_O", height = 20 },
  [2] = { font = "CRB_Header10_O", height = 21 },
  [3] = { font = "CRB_Header11_O", height = 22 },
  [4] = { font = "CRB_Header12_O", height = 24 },
  [5] = { font = "CRB_Header14_O", height = 28 },
  [6] = { font = "CRB_Header16_O", height = 34 },
}

local _fontSecondary =
{
  [1] = { font = "CRB_Interface9_O", height = 20 },
  [2] = { font = "CRB_Interface10_O", height = 21 },
  [3] = { font = "CRB_Interface11_O", height = 22 },
  [4] = { font = "CRB_Interface12_O", height = 24 },
  [5] = { font = "CRB_Interface14_O", height = 28 },
  [6] = { font = "CRB_Interface16_O", height = 34 },
}

local _dispStr =
{
  [Unit.CodeEnumDisposition.Hostile] = "Hostile",
  [Unit.CodeEnumDisposition.Neutral] = "Neutral",
  [Unit.CodeEnumDisposition.Friendly] = "Friendly",
  [Unit.CodeEnumDisposition.Unknown] = "Hidden",
}

local E_VULNERABILITY = Unit.CodeEnumCCState.Vulnerability

local F_PATH = 0
local F_QUEST = 1
local F_CHALLENGE = 2
local F_FRIEND = 3
local F_RIVAL = 4
local F_PVP = 4
local F_AGGRO = 5
local F_CLEANSE = 6
local F_LOW_HP = 7
local F_GROUP = 8

local F_NAMEPLATE = 0
local F_HEALTH = 1
local F_HEALTH_TEXT = 2
local F_CLASS = 3
local F_LEVEL = 4
local F_TITLE = 5
local F_GUILD = 6
local F_CASTING_BAR = 7
local F_CC_BAR = 8
local F_ARMOR = 9
local F_BUBBLE = 10


local _player = nil
local _playerPath = nil
local _playerPos = nil
local _blinded = nil

local _targetNP = nil

local _floor = math.floor
local _min = math.min
local _max = math.max
local _ipairs = ipairs
local _pairs = pairs
local _tableInsert = table.insert
local _tableRemove = table.remove
local _next = next
local _type = type
local _weaselStr = String_GetWeaselString
local _strLen = string.len
local _textWidth = Apollo.GetTextWidth

local _or = bit32.bor
local _lshift = bit32.lshift
local _and = bit32.band
local _not = bit32.bnot
local _xor = bit32.bxor

local _configUI = nil

local _matrix = {}
local _count = 0
local _cycleSize = 25

local _iconPixie =
{
  strSprite = "",
  cr = white,
  loc =
  {
    fPoints = { 0, 0, 1, 1 },
    nOffsets = { 0, 0, 0, 0 }
  },
}

local _targetPixie =
{
  strSprite = "BK3:sprHolo_Accent_Rounded",
  cr = white,
  loc =
  {
    fPoints = { 0.5, 0.5, 0.5, 0.5 },
    nOffsets = { 0, 0, 0, 0 }
  },
}

-------------------------------------------------------------------------------
function TwinkiePlates:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function TwinkiePlates:Init()
  Apollo.RegisterAddon(self, true)
end

function TwinkiePlates:OnLoad()
  self.nameplates = {}
  self.pool = {}
  self.buffer = {}
  self.challenges = ChallengesLib.GetActiveChallengeList()

  Apollo.RegisterSlashCommand("npnpdebug", "OnNPrimeNameplatesCommandDebug", self)
  Apollo.RegisterEventHandler("VarChange_FrameCount", "OnDebuggerUnit", self)

  Apollo.RegisterSlashCommand("npnp", "OnConfigure", self)
  Apollo.RegisterEventHandler("ShowTwinkiePlatesConfigurationWnd", "OnConfigure", self)

  Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
  Apollo.RegisterEventHandler("VarChange_FrameCount", "OnFrame", self)
  Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", self)

  Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
  Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
  Apollo.RegisterEventHandler("UnitTextBubbleCreate", "OnTextBubble", self)
  Apollo.RegisterEventHandler("UnitTextBubblesDestroyed", "OnTextBubble", self)
  Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)
  Apollo.RegisterEventHandler("UnitActivationTypeChanged", "OnUnitActivationTypeChanged", self)

  Apollo.RegisterEventHandler("UnitLevelChanged", "OnUnitLevelChanged", self)

  Apollo.RegisterEventHandler("PlayerTitleChange", "OnPlayerMainTextChanged", self)
  Apollo.RegisterEventHandler("UnitNameChanged", "OnUnitMainTextChanged", self)
  Apollo.RegisterEventHandler("UnitTitleChanged", "OnUnitMainTextChanged", self)
  Apollo.RegisterEventHandler("GuildChange", "OnPlayerMainTextChanged", self)
  Apollo.RegisterEventHandler("UnitGuildNameplateChanged", "OnUnitMainTextChanged", self)
  Apollo.RegisterEventHandler("UnitMemberOfGuildChange", "OnUnitMainTextChanged", self)

  Apollo.RegisterEventHandler("ApplyCCState", "OnCCStateApplied", self)
  Apollo.RegisterEventHandler("UnitGroupChanged", "OnGroupUpdated", self)
  Apollo.RegisterEventHandler("ChallengeUnlocked", "OnChallengeUnlocked", self)
  Apollo.RegisterEventHandler("UnitEnteredCombat", "OnUnitCombatStateChanged", self)
  Apollo.RegisterEventHandler("UnitPvpFlagsChanged", "OnUnitPvpFlagsChanged", self)

  Apollo.RegisterEventHandler("FriendshipAdd", "OnFriendshipChanged", self)
  Apollo.RegisterEventHandler("FriendshipRemove", "OnFriendshipChanged", self)

  self.nameplacer = Apollo.GetAddon("Nameplacer")
  if (self.nameplacer) then
    Apollo.RegisterEventHandler("Nameplacer_UnitNameplatePositionChanged", "OnNameplatePositionSettingChanged", self)
  end


  self.xmlDoc = XmlDoc.CreateFromFile("TwinkiePlates.xml")
  Apollo.LoadSprites("TwinkiePlates_Sprites.xml")
end

function TwinkiePlates:OnSave(p_type)
  if p_type ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
  return _matrix
end

function TwinkiePlates:OnRestore(p_type, p_savedData)
  if p_type ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
  _matrix = p_savedData
  self:CheckMatrixIntegrity()
end

function TwinkiePlates:OnFriendshipChanged()
  _flags.contacts = 1
end

function TwinkiePlates:OnNameClick(wndHandler, wndCtrl, nClick)
  local l_unit = wndCtrl:GetData()
  if (l_unit ~= nil and nClick == 0) then
    GameLib.SetTargetUnit(l_unit)
    return true
  end
end

function TwinkiePlates:OnChangeWorld()
  _player = nil

  if (_targetNP ~= nil) then
    if (_targetNP.targetMark ~= nil) then
      _targetNP.targetMark:Destroy()
    end
    _targetNP.form:Destroy()
    _targetNP = nil
  end
end

function TwinkiePlates:OnUnitCombatStateChanged(p_unit, p_inCombat)
  if (p_unit == nil) then return end
  local l_nameplate = self.nameplates[p_unit:GetId()]
  self:SetCombatState(l_nameplate, p_inCombat)
  if (_player ~= nil and _player:GetTarget() == p_unit) then
    self:SetCombatState(_targetNP, p_inCombat)
  end
end

function TwinkiePlates:OnGroupUpdated(unitNameplateOwner)
  if (unitNameplateOwner == nil) then return end
  local tNameplate = self.nameplates[unitNameplateOwner:GetId()]
  if (tNameplate ~= nil) then
    local strPcOrNpc = tNameplate.isPlayer and "Pc" or "Npc"
    tNameplate.inGroup = unitNameplateOwner:IsInYourGroup()
    tNameplate.type = tNameplate.inGroup and "Group" or _dispStr[tNameplate.eDisposition] .. strPcOrNpc
  end
end

function TwinkiePlates:OnUnitPvpFlagsChanged(unit)
  if (not unit) then return end

  local bPvpFlagged = self:IsPvpFlagged(unit)
  local tNameplate = self.nameplates[unit:GetId()]

  -- Update unit nameplate
  if (tNameplate) then
    tNameplate.pvpFlagged = bPvpFlagged
  end

  -- Update target nameplate as well
  if (_targetNP and _player:GetTarget() == unit) then
    _targetNP.pvpFlagged = bPvpFlagged
  end
end



function TwinkiePlates:InitNameplate(unitNameplateOwner, tNameplate, strCategoryType, tTargetNameplate)
  tNameplate = tNameplate or {}
  tTargetNameplate = tTargetNameplate or false

  local bIsCharacter = unitNameplateOwner:IsACharacter()

  tNameplate.unit = unitNameplateOwner
  tNameplate.unitClassID = bIsCharacter and unitNameplateOwner:GetClassId() or unitNameplateOwner:GetRank()
  tNameplate.bPet = self:IsPet(unitNameplateOwner)
  tNameplate.eDisposition = self:GetDispositionTo(unitNameplateOwner, _player)
  tNameplate.isPlayer = bIsCharacter

  tNameplate.type = strCategoryType
  tNameplate.color = "FFFFFFFF"
  tNameplate.targetNP = tTargetNameplate
  tNameplate.hasHealth = self:HasHealth(unitNameplateOwner)

  if (tTargetNameplate) then
    local l_source = self.nameplates[unitNameplateOwner:GetId()]
    tNameplate.nCcActiveId = l_source and l_source.nCcActiveId or -1
    tNameplate.nCcNewId = l_source and l_source.nCcNewId or -1
    tNameplate.nCcDuration = l_source and l_source.nCcDuration or 0
    tNameplate.nCcDurationMax = l_source and l_source.nCcDurationMax or 0

  else
    tNameplate.nCcActiveId = -1
    tNameplate.nCcNewId = -1
    tNameplate.nCcDuration = 0
    tNameplate.nCcDurationMax = 0
  end

  tNameplate.lowHealth = false
  tNameplate.healthy = false
  tNameplate.prevHealth = 0
  tNameplate.prevShield = 0
  tNameplate.prevAbsorb = 0
  tNameplate.prevArmor = -2
  tNameplate.levelWidth = 1

  tNameplate.iconFlags = -1
  tNameplate.colorFlags = -1
  tNameplate.matrixFlags = -1
  tNameplate.rearrange = false

  tNameplate.outOfRange = true
  tNameplate.occluded = unitNameplateOwner:IsOccluded()
  tNameplate.inCombat = unitNameplateOwner:IsInCombat()
  tNameplate.inGroup = unitNameplateOwner:IsInYourGroup()
  tNameplate.isMounted = unitNameplateOwner:IsMounted()
  tNameplate.isObjective = false
  tNameplate.pvpFlagged = unitNameplateOwner:IsPvpFlagged()
  tNameplate.hasActivationState = self:HasActivationState(unitNameplateOwner)
  tNameplate.hasShield = unitNameplateOwner:GetShieldCapacityMax() ~= nil and unitNameplateOwner:GetShieldCapacityMax() ~= 0


  local l_zoomSliderW = _matrix["SliderBarScale"] / 2
  local l_zoomSliderH = _matrix["SliderBarScale"] / 10
  local l_fontSize = _matrix["SliderFontSize"]
  local l_font = _matrix["ConfigAlternativeFont"] and _fontSecondary or _fontPrimary

  if (tNameplate.form == nil) then
    -- Print("TwinkiePlates: InitNameplate; New form!")

    tNameplate.form = Apollo.LoadForm(self.xmlDoc, "Nameplate", "InWorldHudStratum", self)

    tNameplate.containerTop = tNameplate.form:FindChild("ContainerTop")
    tNameplate.containerMain = tNameplate.form:FindChild("ContainerMain")
    tNameplate.containerIcons = tNameplate.form:FindChild("ContainerIcons")

    tNameplate.textUnitName = tNameplate.form:FindChild("TextUnitName")
    tNameplate.textUnitGuild = tNameplate.form:FindChild("TextUnitGuild")
    tNameplate.textUnitLevel = tNameplate.form:FindChild("TextUnitLevel")

    tNameplate.wndContainerCc = tNameplate.form:FindChild("ContainerCC")
    tNameplate.containerCastBar = tNameplate.form:FindChild("ContainerCastBar")

    tNameplate.iconUnit = tNameplate.form:FindChild("IconUnit")
    tNameplate.iconArmor = tNameplate.form:FindChild("IconArmor")

    tNameplate.health = tNameplate.form:FindChild("BarHealth")
    tNameplate.wndHealthText = tNameplate.form:FindChild("TextHealth")
    tNameplate.shield = tNameplate.form:FindChild("BarShield")
    tNameplate.absorb = tNameplate.form:FindChild("BarAbsorb")
    tNameplate.casting = tNameplate.form:FindChild("BarCasting")
    tNameplate.cc = tNameplate.form:FindChild("BarCC")
    tNameplate.wndCleanseFrame = tNameplate.form:FindChild("CleanseFrame")

    if (not _matrix["ConfigBarIncrements"]) then
      tNameplate.health:SetFullSprite("Bar_02")
      tNameplate.health:SetFillSprite("Bar_02")
      tNameplate.absorb:SetFullSprite("Bar_02")
      tNameplate.absorb:SetFillSprite("Bar_02")
    end

    tNameplate.casting:SetMax(100)

    self:InitNameplateVerticalOffset(tNameplate)
    self:InitAnchoring(tNameplate)

    local l_fontH = l_font[l_fontSize].height
    local l_fontGuild = l_fontSize > 1 and l_fontSize - 1 or l_fontSize

    tNameplate.iconArmor:SetFont(l_font[l_fontSize].font)

    tNameplate.containerTop:SetAnchorOffsets(0, 0, 0, l_font[l_fontSize].height * 0.8)
    tNameplate.iconUnit:SetAnchorOffsets(-l_fontH * 0.9, 0, l_fontH * 0.1, 0)

    tNameplate.textUnitName:SetFont(l_font[l_fontSize].font)
    tNameplate.textUnitLevel:SetFont(l_font[l_fontSize].font)
    tNameplate.textUnitGuild:SetFont(l_font[l_fontGuild].font)
    tNameplate.wndHealthText:SetFont(l_font[l_fontGuild].font)
    -- tNameplate.textUnitGuild:SetAnchorOffsets(0, 0, 0, l_font[l_fontGuild].height * 0.9)

    tNameplate.containerCastBar:SetFont(l_font[l_fontSize].font)
    tNameplate.wndContainerCc:SetFont(l_font[l_fontSize].font)
    tNameplate.containerCastBar:SetAnchorOffsets(0, 0, 0, (l_font[l_fontSize].height * 0.75) + l_zoomSliderH)
    tNameplate.wndContainerCc:SetAnchorOffsets(0, 0, 0, (l_font[l_fontSize].height * 0.75) + l_zoomSliderH)

    tNameplate.containerMain:SetFont(l_font[l_fontSize].font)

    tNameplate.casting:SetAnchorOffsets(-l_zoomSliderW, (l_zoomSliderH * 0.25), l_zoomSliderW, l_zoomSliderH)
    tNameplate.cc:SetAnchorOffsets(-l_zoomSliderW, (l_zoomSliderH * 0.25), l_zoomSliderW, l_zoomSliderH)

    local l_armorWidth = tNameplate.iconArmor:GetHeight() / 2
    tNameplate.iconArmor:SetAnchorOffsets(-l_armorWidth, 0, l_armorWidth, 0)
  end

  tNameplate.matrixFlags = self:GetMatrixFlags(tNameplate)

  self:UpdateAnchoring(tNameplate)

  -- Print("tNameplate.bIsVerticalOffsetUpdated: " .. tostring(tNameplate.bIsVerticalOffsetUpdated))

  if (not tNameplate.bIsVerticalOffsetUpdated) then
    self:InitNameplateVerticalOffset(tNameplate)
  end

  tNameplate.textUnitName:SetData(unitNameplateOwner)
  tNameplate.health:SetData(unitNameplateOwner)
  tNameplate.onScreen = tNameplate.form:IsOnScreen()

  self:UpdateOpacity(tNameplate)
  tNameplate.wndContainerCc:Show(false)
  tNameplate.containerMain:Show(false)
  tNameplate.containerCastBar:Show(false)
  tNameplate.textUnitGuild:Show(false)
  tNameplate.iconArmor:Show(false)
  tNameplate.wndCleanseFrame:Show(false)

  -- tNameplate.containerMain:SetText("")
  local l_heightMod = (tNameplate.hasShield and 1.3 or 1)

  local l_shieldHeightMod = _matrix["ConfigLargeShield"] and 0.5 or 0.35
  local l_shieldHeight = tNameplate.health:GetHeight() * l_shieldHeightMod
  local l_shield = tNameplate.hasShield and l_zoomSliderH * 1.3 or l_zoomSliderH

  self:UpdateMainContainerHeight(tNameplate)

  tNameplate.shield:Show(tNameplate.hasShield)
  --tNameplate.health:SetAnchorOffsets(-l_zoomSliderW, 3, l_zoomSliderW, l_zoomSliderH * l_heightMod + 3)
  -- tNameplate.health:SetAnchorOffsets(0, 0, 0, --[[l_shieldHeight + l_healthTextHeight]] tNameplate.hasShield and 0 or -3)
  local mc_left, mc_top, mc_right, mc_bottom = tNameplate.containerMain:GetAnchorOffsets()
  tNameplate.containerMain:SetAnchorOffsets(mc_left, mc_top, mc_right, tNameplate.hasShield and mc_top + 14 or mc_top + 11)

  -- tNameplate.shield:SetAnchorOffsets(0, _min(-l_shieldHeight, -3), 0, 0)

  if (tNameplate.hasHealth) then
    self:UpdateMainContainer(tNameplate)
  else
    tNameplate.wndHealthText:Show(false)
  end

  tNameplate.colorFlags = self:GetColorFlags(tNameplate)
  self:UpdateNameplateColors(tNameplate)

  tNameplate.containerIcons:DestroyAllPixies()
  if (tNameplate.isPlayer) then
    self:UpdateIconsPC(tNameplate)
  else
    self:UpdateIconsNPC(tNameplate)
  end

  self:UpdateTextNameGuild(tNameplate)
  self:UpdateTextLevel(tNameplate)
  self:UpdateArmor(tNameplate)
  self:InitClassIcon(tNameplate)

  tNameplate.form:Show(self:GetNameplateVisibility(tNameplate), true)

  self:UpdateTopContainer(tNameplate)


  -- TEST CLEANSABLE FRAME
  --[[
  local nPixieId = tNameplate.containerMain:AddPixie({
    bLine = false,
    strSprite = "NPrimeNameplates_Sprites:FrameGlow",
    cr = _typeColor["Cleanse"],
    loc = {
      fPoints = { 0.5, 0, 0.5, 0 },
      nOffsets = { -62, -10, 62, 20 }
    },
    flagsText = {
      DT_CENTER = true,
      DT_VCENTER = true
    }
  })
  --]]

  tNameplate.form:ArrangeChildrenVert(1)

  return tNameplate
end

function TwinkiePlates:IsPet(unit)
  local strUnitType = unit:GetType()
  return strUnitType == "Pet" or strUnitType == "Scanner"
end

function TwinkiePlates:IsPvpFlagged(unit)
  if (self:IsPet(unit) and unit:GetUnitOwner()) then
    unit = unit:GetUnitOwner()
  end

  return unit:IsPvpFlagged()
end

function TwinkiePlates:UpdateAnchoring(tNameplate, nCodeEnumFloaterLocation)
  local tAnchorUnit = tNameplate.unit:IsMounted() and tNameplate.unit:GetUnitMount() or tNameplate.unit
  local bReposition = false
  local nCodeEnumFloaterLocation = nCodeEnumFloaterLocation



  if (self.nameplacer) then
    if (not nCodeEnumFloaterLocation) then
      local tNameplatePositionSetting = self.nameplacer:GetUnitNameplatePositionSetting(tNameplate.unit:GetName())

      if (tNameplatePositionSetting and tNameplatePositionSetting["nAnchorId"]) then
        nCodeEnumFloaterLocation = tNameplatePositionSetting["nAnchorId"]
        -- tNameplate.form:SetUnit(tAnchorUnit, nCodeEnumFloaterLocation)
      end
    end

    -- Print("\\\\\\\\\\\\\\\\\ unit name: " .. tAnchorUnit:GetName() .. "; nCodeEnumFloaterLocation: " .. tostring(nCodeEnumFloaterLocation) .. "; tNameplate.form:GetUnit(tAnchorUnit): " .. tostring(tNameplate.form:GetUnit(tAnchorUnit)))

    if (nCodeEnumFloaterLocation) then
      -- Print("\\\\\\\\\\\\\\\\\ unit name: " .. tAnchorUnit:GetName() .. "; nCodeEnumFloaterLocation: " .. tostring(nCodeEnumFloaterLocation) .. "; tNameplate.form:GetUnit(tAnchorUnit): " .. tostring(tNameplate.form:GetUnit(tAnchorUnit)))
      tNameplate.form:SetUnit(tAnchorUnit, nCodeEnumFloaterLocation)
      return
    end
  end

  if (_matrix["ConfigDynamicVPos"] and not tNameplate.isPlayer) then

    local tOverhead = tNameplate.unit:GetOverheadAnchor()
    if (tOverhead ~= nil) then
      bReposition = not tNameplate.occluded and tOverhead.y < 25
    end
  end

  if (bReposition) then
    tNameplate.form:SetUnit(tAnchorUnit, 0)
  else
    tNameplate.form:SetUnit(tAnchorUnit, 1)
  end
end

function TwinkiePlates:InitNameplateVerticalOffset(tNameplate, nInputNameplacerVerticalOffset)
  local nVerticalOffset = _matrix["SliderVerticalOffset"]
  local nNameplacerVerticalOffset = nInputNameplacerVerticalOffset

  -- Print("TwinkiePlates:InitNameplateVerticalOffset(tNameplate); " .. tostring(nInputNameplacerVerticalOffset))

  if (self.nameplacer or nNameplacerVerticalOffset) then

    -- Print("TwinkiePlates:InitNameplateVerticalOffset(tNameplate); tNameplate.unit:GetName(): " .. tostring(tNameplate.unit:GetName()) .. "; nNameplacerVerticalOffset: " .. tostring(nNameplacerVerticalOffset))

    if (not nNameplacerVerticalOffset) then
      local tNameplatePositionSetting = self.nameplacer:GetUnitNameplatePositionSetting(tNameplate.unit:GetName())

      if (tNameplatePositionSetting) then
        -- Print("TwinkiePlates:InitNameplateVerticalOffset(tNameplatePositionSetting[\"nVerticalOffset\"]); " .. tostring(tNameplatePositionSetting["nVerticalOffset"]))
        nNameplacerVerticalOffset = tNameplatePositionSetting["nVerticalOffset"]
      end
    end
  end

  if (not nNameplacerVerticalOffset) then

    -- Print("TwinkiePlates:InitNameplateVerticalOffset(tNameplate); nNameplacerVerticalOffset: " .. tostring(nNameplacerVerticalOffset))
    nNameplacerVerticalOffset = 0
  end

  self:SetNameplateVerticalOffset(tNameplate, nVerticalOffset, nNameplacerVerticalOffset)
  tNameplate.bIsVerticalOffsetUpdated = true
end

function TwinkiePlates:IsPet(unit)
  local strUnitType = unit:GetType()
  return strUnitType == "Pet" or strUnitType == "Scanner"
end

function TwinkiePlates:IsPvpFlagged(unit)
  if (self:IsPet(unit) and unit:GetUnitOwner()) then
    unit = unit:GetUnitOwner()
  end

  return unit:IsPvpFlagged()
end

function TwinkiePlates:OnUnitCreated(unitNameplateOwner)
  _tableInsert(self.buffer, unitNameplateOwner)
end

function TwinkiePlates:UpdateBuffer()
  for i = 1, #self.buffer do
    local l_unit = self.buffer[i]
    if (l_unit ~= nil and l_unit:IsValid()) then
      self:AllocateNameplate(l_unit)
    end
    self.buffer[i] = nil
  end
end

function TwinkiePlates:OnFrame()

  -- Player initialization. Should be done once after the addon loadin?
  if (_player == nil) then
    _player = GameLib.GetPlayerUnit()
    if (_player ~= nil) then
      _playerPath = _paths[PlayerPathLib.GetPlayerPathType()]
      if (_player:GetTarget() ~= nil) then
        self:OnTargetUnitChanged(_player:GetTarget())
      end
      self:CheckMatrixIntegrity()
    end
  end

  -- Addon configuration loading. Maybe can be used to reaload the configuration without reloading the whole UI.
  if (_configUI == nil and _next(_matrix) ~= nil) then
    self:InitConfiguration()
  end

  if (_player == nil) then return end

  ---------------------------------------------------------------------------

  _playerPos = _player:GetPosition()
  _blinded = _player:IsInCCState(Unit.CodeEnumCCState.Blind)

  for flag, flagValue in _pairs(_flags) do
    _flags[flag] = flagValue == 1 and 2 or flagValue
  end

  -- if (true) then return end

  local l_c = 0
  for id, nameplate in _pairs(self.nameplates) do
    l_c = l_c + 1
    local l_cyclic = (l_c > _count and l_c < _count + _cycleSize)
    self:UpdateNameplate(nameplate, l_cyclic)
  end

  _count = (_count + _cycleSize > l_c) and 0 or _count + _cycleSize


  if (_targetNP ~= nil) then
    self:UpdateNameplate(_targetNP, true)
  end


  if (_configUI ~= nil and _configUI:IsVisible()) then
    self:UpdateConfiguration()
  end

  self:UpdateBuffer()

  for flag, flagValue in _pairs(_flags) do
    _flags[flag] = flagValue == 2 and 0 or flagValue
  end
end



function TwinkiePlates:UpdateNameplate(tNameplate, bCyclicUpdate)
  -- local bShowCastingBar = GetFlag(tNameplate.matrixFlags, F_CASTING_BAR)
  local bShowCcBar = GetFlag(tNameplate.matrixFlags, F_CC_BAR)
  tNameplate.onScreen = tNameplate.form:IsOnScreen()
  tNameplate.occluded = tNameplate.form:IsOccluded()

  if (bCyclicUpdate) then
    local nDistanceToUnit = self:DistanceToUnit(tNameplate.unit)
    tNameplate.outOfRange = nDistanceToUnit > _matrix["SliderDrawDistance"]
  end

  if (tNameplate.onScreen) then
    local eDispositionToPlayer = self:GetDispositionTo(tNameplate.unit, _player)
    if (tNameplate.eDisposition ~= eDispositionToPlayer) then
      local strPcOrNpc = tNameplate.isPlayer and "Pc" or "Npc"
      tNameplate.eDisposition = eDispositionToPlayer
      tNameplate.type = _dispStr[eDispositionToPlayer] .. strPcOrNpc
    end
  end

  local bIsNameplateVisible = self:GetNameplateVisibility(tNameplate)
  if (tNameplate.form:IsVisible() ~= bIsNameplateVisible) then
    tNameplate.form:Show(bIsNameplateVisible, true)
  end

  if (bShowCcBar and (tNameplate.nCcActiveId ~= -1 or tNameplate.nCcNewId ~= -1) ) then
    self:UpdateCc(tNameplate)
  end

  if (_flags.opacity == 2) then
    self:UpdateOpacity(tNameplate)
  end

  if (_flags.contacts == 2 and tNameplate.isPlayer) then
    self:UpdateIconsPC(tNameplate)
  end

  if (not bIsNameplateVisible) then return end

  ---------------------------------------------------------------------------

  self:UpdateAnchoring(tNameplate)

  -- if (bShowCastingBar) then
    self:UpdateCasting(tNameplate)
  -- end

  self:UpdateArmor(tNameplate)

  if (tNameplate.hasHealth
      or (tNameplate.isPlayer and self:HasHealth(tNameplate.unit))) then
    tNameplate.hasHealth = true
    tNameplate.matrixFlags = self:GetMatrixFlags(tNameplate)
    self:UpdateMainContainer(tNameplate)
  end

  if (bCyclicUpdate) then
    local l_colorFlags = self:GetColorFlags(tNameplate)
    if (tNameplate.colorFlags ~= l_colorFlags) then
      tNameplate.colorFlags = l_colorFlags
      self:UpdateNameplateColors(tNameplate)
    end

    if (not tNameplate.isPlayer) then
      self:UpdateIconsNPC(tNameplate)
    end
  end

  if (tNameplate.rearrange) then
    tNameplate.form:ArrangeChildrenVert(1)
    tNameplate.rearrange = false
  end
end


function TwinkiePlates:UpdateMainContainer(tNameplate)
  local l_health = tNameplate.unit:GetHealth();
  local l_healthMax = tNameplate.unit:GetMaxHealth();
  local l_shield = tNameplate.unit:GetShieldCapacity();
  local l_shieldMax = tNameplate.unit:GetShieldCapacityMax();
  local l_absorb = tNameplate.unit:GetAbsorptionValue();
  local l_fullHealth = l_health == l_healthMax;
  local l_shieldFull = false;
  local l_hiddenBecauseFull = false;
  local l_isFriendly = tNameplate.eDisposition == Unit.CodeEnumDisposition.Friendly

  if (tNameplate.hasShield) then
    l_shieldFull = l_shield == l_shieldMax;
  end

  if (not tNameplate.targetNP) then
    l_hiddenBecauseFull = (_matrix["ConfigSimpleWhenHealthy"] and l_fullHealth) or
        (_matrix["ConfigSimpleWhenFullShield"] and l_shieldFull);
  end

  local l_matrixEnabled = GetFlag(tNameplate.matrixFlags, F_HEALTH)
  local l_visible = l_matrixEnabled and not l_hiddenBecauseFull

  if (tNameplate.containerMain:IsVisible() ~= l_visible) then
    tNameplate.containerMain:Show(l_visible)
    tNameplate.rearrange = true
  end

  if (l_visible) then
    if (l_health ~= tNameplate.prevHealth) then
      local l_temp = l_isFriendly and "SliderLowHealthFriendly" or "SliderLowHealth"
      if (_matrix[l_temp] ~= 0) then
        local l_cutoff = (_matrix[l_temp] / 100)
        local l_healthPct = l_health / l_healthMax
        tNameplate.lowHealth = l_healthPct <= l_cutoff
      end
      self:SetProgressBar(tNameplate.health, l_health, l_healthMax)
    end

    if (l_absorb > 0) then
      if (not tNameplate.absorb:IsVisible()) then
        tNameplate.absorb:Show(true)
      end

      if (l_absorb ~= tNameplate.prevAbsorb) then
        self:SetProgressBar(tNameplate.absorb, l_absorb, l_healthMax)
      end
    else
      tNameplate.absorb:Show(false)
    end

    if (tNameplate.hasShield and l_shield ~= tNameplate.prevShield) then
      self:SetProgressBar(tNameplate.shield, l_shield, l_shieldMax)
    end

    local l_healthTextEnabled = GetFlag(tNameplate.matrixFlags, F_HEALTH_TEXT)

    -- Print("l_healthTextEnabled: " .. tostring(l_healthTextEnabled))

    if (l_healthTextEnabled) then
      --if (_matrix["ConfigHealthText"] and not tNameplate.inCombat) then
      -- if (_matrix["ConfigHealthText"]) then
      local l_shieldText = ""
      local l_healthText = self:GetNumber(l_health, l_healthMax)

      if (tNameplate.hasShield and l_shield ~= 0) then
        l_shieldText = " (" .. self:GetNumber(l_shield, l_shieldMax) .. ")"
      end

      tNameplate.wndHealthText:SetText(l_healthText .. l_shieldText)
    end
  end

  tNameplate.prevHealth = l_health
  tNameplate.prevShield = l_shield
  tNameplate.prevAbsorb = l_absorb
end

function TwinkiePlates:UpdateTopContainer(p_nameplate)
  local l_levelVisible = GetFlag(p_nameplate.matrixFlags, F_LEVEL)
  local l_classVisible = GetFlag(p_nameplate.matrixFlags, F_CLASS)
  p_nameplate.iconUnit:SetBGColor(l_classVisible and "FFFFFFFF" or "00FFFFFF")
  local l_width = p_nameplate.levelWidth + p_nameplate.textUnitName:GetWidth()
  local l_ratio = p_nameplate.levelWidth / l_width
  local l_middle = (l_width * l_ratio) - (l_width / 2)

  if (not l_levelVisible) then
    local l_extents = p_nameplate.textUnitName:GetWidth() / 2
    p_nameplate.textUnitLevel:SetTextColor("00FFFFFF")
    p_nameplate.textUnitLevel:SetAnchorOffsets(-l_extents - 5, 0, -l_extents, 1)
    p_nameplate.textUnitName:SetAnchorOffsets(-l_extents, 0, l_extents, 1)
  else
    p_nameplate.textUnitLevel:SetTextColor("FFFFFFFF")
    p_nameplate.textUnitLevel:SetAnchorOffsets(-(l_width / 2), 0, l_middle, 1)
    p_nameplate.textUnitName:SetAnchorOffsets(l_middle, 0, (l_width / 2), 1)
  end
end

function TwinkiePlates:UpdateMainContainerHeight(tNameplate)
  local l_healthTextEnabled = GetFlag(tNameplate.matrixFlags, F_HEALTH_TEXT)

  -- Print("l_healthTextEnabled: " .. tostring(l_healthTextEnabled))

  if (l_healthTextEnabled) then
    self:UpdateMainContainerHeightWithHealthText(tNameplate)
  else
    self:UpdateMainContainerHeightWithoutHealthText(tNameplate)
  end

  tNameplate.rearrange = true
end

function TwinkiePlates:UpdateNameplateColors(tNameplate)
  local bPvpFlagged = _player:IsPvpFlagged() and GetFlag(tNameplate.colorFlags, F_PVP)
  local bLostAggro = GetFlag(tNameplate.colorFlags, F_AGGRO)
  local bIsCleansable = GetFlag(tNameplate.colorFlags, F_CLEANSE)
  local nLowHp = GetFlag(tNameplate.colorFlags, F_LOW_HP)


  local l_textColor = _typeColor[tNameplate.type]
  local l_barColor = _dispColor[tNameplate.eDisposition]

  local bHostile = tNameplate.eDisposition == Unit.CodeEnumDisposition.Hostile
  local bIsFriendly = tNameplate.eDisposition == Unit.CodeEnumDisposition.Friendly

  tNameplate.color = l_textColor

  if (tNameplate.isPlayer or tNameplate.bPet) then
    if (not bPvpFlagged and bHostile) then
      l_textColor = _dispColor[Unit.CodeEnumDisposition.Neutral]
      l_barColor = _dispColor[Unit.CodeEnumDisposition.Neutral]
      tNameplate.color = l_textColor
    end

    if (bIsCleansable and bIsFriendly and not tNameplate.wndCleanseFrame:IsVisible()) then
      tNameplate.wndCleanseFrame:Show(true)
      tNameplate.wndCleanseFrame:SetBGColor(_typeColor["Cleanse"])
    elseif (tNameplate.wndCleanseFrame:IsVisible()) then
      -- p_nameplate.containerMain:SetSprite("")
      tNameplate.wndCleanseFrame:Show(false)
    end
  else
    if (bLostAggro and bHostile) then
      l_textColor = _typeColor["Special"]
    end
    if (tNameplate.wndCleanseFrame:IsVisible()) then
      -- p_nameplate.containerMain:SetSprite("")
      tNameplate.wndCleanseFrame:Show(false)
    end
  end

  if (nLowHp) then
    l_barColor = bIsFriendly and _color("FF0000FF") or _typeColor["Special"]
  end

  tNameplate.textUnitName:SetTextColor(l_textColor)
  tNameplate.textUnitGuild:SetTextColor(l_textColor)
  tNameplate.health:SetBarColor(l_barColor)

  if (tNameplate.targetNP and tNameplate.targetMark ~= nil) then
    tNameplate.targetMark:SetBGColor(tNameplate.color)
  end
end

function TwinkiePlates:GetColorFlags(tNameplate)
  if (_player == nil) then return end

  local l_flags = SetFlag(0, tNameplate.eDisposition)
  local bIsFriendly = tNameplate.eDisposition == Unit.CodeEnumDisposition.Friendly

  if (tNameplate.inGroup) then l_flags = SetFlag(l_flags, F_GROUP) end
  if (tNameplate.pvpFlagged) then l_flags = SetFlag(l_flags, F_PVP) end
  if (tNameplate.lowHealth) then l_flags = SetFlag(l_flags, F_LOW_HP) end

  if (_matrix["ConfigAggroIndication"]) then
    if (tNameplate.inCombat and not tNameplate.isPlayer and tNameplate.unit:GetTarget() ~= _player) then
      l_flags = SetFlag(l_flags, F_AGGRO)
    end
  end

  if (_matrix["ConfigCleanseIndicator"] and bIsFriendly) then
    local l_debuffs = tNameplate.unit:GetBuffs()["arHarmful"]
    for i = 1, #l_debuffs do
      if (l_debuffs[i]["splEffect"]:GetClass() == Spell.CodeEnumSpellClass.DebuffDispellable) then
        l_flags = SetFlag(l_flags, F_CLEANSE)
      end
    end
  end

  return l_flags
end

function TwinkiePlates:GetDispositionTo(unitSubject, unitObject)

  if (not unitSubject or not unitObject) then return Unit.CodeEnumDisposition.Unknown end

  if (self:IsPet(unitSubject) and unitSubject:GetUnitOwner()) then
    unitSubject = unitSubject:GetUnitOwner()
  end

  return unitSubject:GetDispositionTo(unitObject)
end

function TwinkiePlates:GetMatrixFlags(tNameplate)
  local nFlags = 0
  local bInCombat = tNameplate.inCombat
  local strUnitCategoryType = tNameplate.targetNP and "Target" or tNameplate.type

  for i = 1, #_matrixCategories do
    local l_matrix = _matrix[_matrixCategories[i] .. strUnitCategoryType]
    if ((type(l_matrix) ~= "number") or (l_matrix == 3) or
        (l_matrix + (bInCombat and 1 or 0) == 2)) then
      nFlags = SetFlag(nFlags, i - 1)
    end
  end

  if (not tNameplate.hasHealth) then
    nFlags = ClearFlag(nFlags, F_HEALTH)
  end

  return nFlags
end

function SetFlag(p_flags, p_flag)
  return _or(p_flags, _lshift(1, p_flag))
end

function ClearFlag(p_flags, p_flag)
  return _and(p_flags, _xor(_lshift(1, p_flag), 65535))
end

function GetFlag(p_flags, p_flag)
  return _and(p_flags, _lshift(1, p_flag)) ~= 0
end

function TwinkiePlates:GetNumber(p_current, p_max)
  if (p_current == nil or p_max == nil) then return "" end
  if (_matrix["ConfigHealthPct"]) then
    return _floor((p_current / p_max) * 100) .. "%"
  else
    return self:FormatNumber(p_current)
  end
end

function TwinkiePlates:UpdateConfiguration()
  self:UpdateConfigSlider("SliderDrawDistance", 50, 155.0, "m")
  self:UpdateConfigSlider("SliderLowHealth", 0, 101.0, "%")
  self:UpdateConfigSlider("SliderLowHealthFriendly", 0, 101.0, "%")
  self:UpdateConfigSlider("SliderVerticalOffset", 0, 101.0, "px")
  self:UpdateConfigSlider("SliderBarScale", 50, 205.0, "%")
  self:UpdateConfigSlider("SliderFontSize", 1, 6.2)
end

function TwinkiePlates:UpdateConfigSlider(p_name, p_min, p_max, p_labelSuffix)
  local l_slider = _configUI:FindChild(p_name)
  if (l_slider ~= nil) then
    local l_sliderVal = l_slider:FindChild("SliderBar"):GetValue()
    l_slider:SetProgress((l_sliderVal - p_min) / (p_max - p_min))
    l_slider:FindChild("TextValue"):SetText(l_sliderVal .. (p_labelSuffix or ""))
  end
end

function TwinkiePlates:OnTargetUnitChanged(unitTarget)
  if (not _player) then return end

  if (unitTarget and self.nameplates[unitTarget:GetId()]) then
    self.nameplates[unitTarget:GetId()].form:Show(false, true)
  end

  -- Print(unitTarget:GetType())

  if (unitTarget ~= nil) then
    local strUnitCategoryType = self:GetUnitType(unitTarget)
    if (_targetNP == nil) then
      -- Print(">>> OnTargetUnitChanged; initializing new nameplate")
      _targetNP = self:InitNameplate(unitTarget, nil, strUnitCategoryType, true)

      if (_matrix["ConfigLegacyTargeting"]) then
        self:UpdateLegacyTargetPixie()
        _targetNP.form:AddPixie(_targetPixie)
      else
        _targetNP.targetMark = Apollo.LoadForm(self.xmlDoc, "Target Indicator", _targetNP.containerTop, self)
        local l_offset = _targetNP.targetMark:GetHeight() / 2
        _targetNP.targetMark:SetAnchorOffsets(-l_offset, 0, l_offset, 0)
        _targetNP.targetMark:SetBGColor(_targetNP.color)
      end
    else

      -- Print("Updating _targetNP")

      -- Target Nameplacte is never reset because it's not attached to any specific unit thus is never affected by OnUnitDestroyed event
      _targetNP.bIsVerticalOffsetUpdated = false

      _targetNP = self:InitNameplate(unitTarget, _targetNP, strUnitCategoryType, true)

      if (_matrix["ConfigLegacyTargeting"]) then
        self:UpdateLegacyTargetPixie()
        _targetNP.form:UpdatePixie(1, _targetPixie)
      end
    end

    -- We need to call this otherwise hidden health text comfiguration may not update correctly
    self:UpdateMainContainerHeight(_targetNP)
  end

  _flags.opacity = 1
  _targetNP.form:Show(unitTarget ~= nil, true)
end

function TwinkiePlates:UpdateLegacyTargetPixie()
  local l_width = _targetNP.textUnitName:GetWidth()
  local l_height = _targetNP.textUnitName:GetHeight()

  if (_targetNP.textUnitLevel:IsVisible()) then l_width = l_width + _targetNP.textUnitLevel:GetWidth() end
  if (_targetNP.textUnitGuild:IsVisible()) then l_height = l_height + _targetNP.textUnitGuild:GetHeight() end
  if (_targetNP.containerMain:IsVisible()) then l_height = l_height + _targetNP.containerMain:GetHeight() end

  l_height = (l_height / 2) + 30
  l_width = (l_width / 2) + 50

  l_width = l_width < 45 and 45 or (l_width > 200 and 200 or l_width)
  l_height = l_height < 45 and 45 or (l_height > 75 and 75 or l_height)

  _targetPixie.loc.nOffsets[1] = -l_width
  _targetPixie.loc.nOffsets[2] = -l_height
  _targetPixie.loc.nOffsets[3] = l_width
  _targetPixie.loc.nOffsets[4] = l_height
end

function TwinkiePlates:OnTextBubble(unitNameplateOwner, p_text)
  if (_player == nil) then return end

  local tNameplate = self.nameplates[unitNameplateOwner:GetId()]
  if (tNameplate ~= nil) then
    self:ProcessTextBubble(tNameplate, p_text)
  end
end

function TwinkiePlates:ProcessTextBubble(p_nameplate, p_text)
  if (GetFlag(p_nameplate.matrixFlags, F_BUBBLE)) then
    self:UpdateOpacity(p_nameplate, (p_text ~= nil))
  end
end

function TwinkiePlates:OnPlayerMainTextChanged()
  if (_player == nil) then return end
  self:OnUnitMainTextChanged(_player)
end

function TwinkiePlates:OnNameplatePositionSettingChanged(strUnitName, tNameplatePositionSetting)
  -- Print("[nPrimeNameplates] OnNameplatePositionSettingChanged; strUnitName: " .. strUnitName .. "; tNameplatePositionSetting: " .. table.tostring(tNameplatePositionSetting))

  if (not tNameplatePositionSetting or (not tNameplatePositionSetting["nAnchorId"] and not tNameplatePositionSetting["nVerticalOffset"])) then return end

  if (_targetNP and _targetNP.unit and _targetNP.unit:GetName() == strUnitName) then
    if (tNameplatePositionSetting["nAnchorId"]) then
      self:UpdateAnchoring(_targetNP, tNameplatePositionSetting["nAnchorId"])
    end
    if (tNameplatePositionSetting["nVerticalOffset"]) then
      self:InitNameplateVerticalOffset(_targetNP, tNameplatePositionSetting["nVerticalOffset"])
    end
  end

  for _, tNameplate in _pairs(self.nameplates) do
    -- Print("[nPrimeNameplates] nameplate.unit:GetName():" .. tNameplate.unit:GetName())

    if (tNameplate.unit:GetName() == strUnitName) then

      -- Print("!!!!!!!!!!!!!!!!!! nameplate.unit:GetName():" .. tNameplate.unit:GetName())

      if (tNameplatePositionSetting["nAnchorId"]) then
        self:UpdateAnchoring(tNameplate, tNameplatePositionSetting["nAnchorId"])
      end
      if (tNameplatePositionSetting["nVerticalOffset"]) then
        self:InitNameplateVerticalOffset(tNameplate, tNameplatePositionSetting["nVerticalOffset"])
      end
    end
  end
end

function TwinkiePlates:OnUnitMainTextChanged(unitNameplateOwner)
  if (unitNameplateOwner == nil) then return end
  local l_nameplate = self.nameplates[unitNameplateOwner:GetId()]
  if (l_nameplate ~= nil) then
    self:UpdateTextNameGuild(l_nameplate)
    self:UpdateTopContainer(l_nameplate)
  end
  if (_targetNP ~= nil and _player:GetTarget() == unitNameplateOwner) then
    self:UpdateTextNameGuild(_targetNP)
    self:UpdateTopContainer(_targetNP)
  end
end

function TwinkiePlates:OnUnitLevelChanged(unitNameplateOwner)
  if (unitNameplateOwner == nil) then return end
  local l_nameplate = self.nameplates[unitNameplateOwner:GetId()]
  if (l_nameplate ~= nil) then
    self:UpdateTextLevel(l_nameplate)
    self:UpdateTopContainer(l_nameplate)
  end
  if (_targetNP ~= nil and _player:GetTarget() == unitNameplateOwner) then
    self:UpdateTextLevel(_targetNP)
    self:UpdateTopContainer(_targetNP)
  end
end

function TwinkiePlates:OnUnitActivationTypeChanged(unitNameplateOwner)
  if (_player == nil) then return end

  local l_nameplate = self.nameplates[unitNameplateOwner:GetId()]
  local l_hasActivationState = self:HasActivationState(unitNameplateOwner)

  if (l_nameplate ~= nil) then
    l_nameplate.hasActivationState = l_hasActivationState
  elseif (l_hasActivationState) then
    self:AllocateNameplate(unitNameplateOwner)
  end
  if (_targetNP ~= nil and _player:GetTarget() == unitNameplateOwner) then
    _targetNP.hasActivationState = l_hasActivationState
  end
end

function TwinkiePlates:OnChallengeUnlocked()
  self.challenges = ChallengesLib.GetActiveChallengeList()
end

-------------------------------------------------------------------------------
function string.starts(String, Start)
  return string.sub(String, 1, string.len(Start)) == Start
end

function TwinkiePlates:OnConfigure(strCmd, strArg)
  if (strArg == "occlusion") then
    _matrix["ConfigOcclusionCulling"] = not _matrix["ConfigOcclusionCulling"]
    local l_occlusionString = _matrix["ConfigOcclusionCulling"] and "<Enabled>" or "<Disabled>"
    Print("[nPrimeNameplates] Occlusion culling " .. l_occlusionString)
  elseif ((strArg == nil or strArg == "") and _configUI ~= nil) then
    _configUI:Show(not _configUI:IsVisible(), true)
  end
end

-- Called from form
function TwinkiePlates:OnConfigButton(p_wndHandler, p_wndControl, p_mouseButton)
  local l_name = p_wndHandler:GetName()

  if (l_name == "ButtonClose") then _configUI:Show(false)
  elseif (l_name == "ButtonApply") then RequestReloadUI()
  elseif (string.starts(l_name, "Config")) then
    _matrix[l_name] = p_wndHandler:IsChecked()
  end
end

-- Called from form
function TwinkiePlates:OnSliderBarChanged(p1, p_wndHandler, p_value, p_oldValue)
  local l_name = p_wndHandler:GetParent():GetName()
  if (_matrix[l_name] ~= nil) then
    _matrix[l_name] = p_value
  end
end

-- Called from form
function TwinkiePlates:OnMatrixClick(p_wndHandler, wndCtrl, nClick)
  if (nClick ~= 0 and nClick ~= 1) then return end

  local l_parent = p_wndHandler:GetParent():GetParent():GetName()
  local l_key = l_parent .. p_wndHandler:GetName()
  local l_valueOld = _matrix[l_key]
  local l_xor = bit32.bxor(bit32.extract(l_valueOld, nClick), 1)
  local l_valueNew = bit32.replace(l_valueOld, l_xor, nClick)

  p_wndHandler:SetTooltip(self:GetMatrixTooltip(l_valueNew))

  _matrix[l_key] = l_valueNew
  p_wndHandler:SetSprite(_matrixButtonSprites[l_valueNew])
end

function TwinkiePlates:OnInterfaceMenuListHasLoaded()
  Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "TwinkiePlates", { "ShowTwinkiePlatesConfigurationWnd", "", "" })
end

function TwinkiePlates:CheckMatrixIntegrity()
  if (_type(_matrix["ConfigBarIncrements"]) ~= "boolean") then _matrix["ConfigBarIncrements"] = true end
  if (_type(_matrix["ConfigHealthText"]) ~= "boolean") then _matrix["ConfigHealthText"] = true end
  if (_type(_matrix["ConfigShowHarvest"]) ~= "boolean") then _matrix["ConfigShowHarvest"] = true end
  if (_type(_matrix["ConfigOcclusionCulling"]) ~= "boolean") then _matrix["ConfigOcclusionCulling"] = true end
  if (_type(_matrix["ConfigFadeNonTargeted"]) ~= "boolean") then _matrix["ConfigFadeNonTargeted"] = true end
  if (_type(_matrix["ConfigDynamicVPos"]) ~= "boolean") then _matrix["ConfigDynamicVPos"] = true end

  if (_type(_matrix["ConfigLargeShield"]) ~= "boolean") then _matrix["ConfigLargeShield"] = false end
  if (_type(_matrix["ConfigHealthPct"]) ~= "boolean") then _matrix["ConfigHealthPct"] = false end
  if (_type(_matrix["ConfigSimpleWhenHealthy"]) ~= "boolean") then _matrix["ConfigSimpleWhenHealthy"] = false end
  if (_type(_matrix["ConfigSimpleWhenFullShield"]) ~= "boolean") then _matrix["ConfigSimpleWhenFullShield"] = false end
  if (_type(_matrix["ConfigAggroIndication"]) ~= "boolean") then _matrix["ConfigAggroIndication"] = false end
  if (_type(_matrix["ConfigHideAffiliations"]) ~= "boolean") then _matrix["ConfigHideAffiliations"] = false end
  if (_type(_matrix["ConfigAlternativeFont"]) ~= "boolean") then _matrix["ConfigAlternativeFont"] = false end
  if (_type(_matrix["ConfigLegacyTargeting"]) ~= "boolean") then _matrix["ConfigLegacyTargeting"] = false end
  if (_type(_matrix["ConfigCleanseIndicator"]) ~= "boolean") then _matrix["ConfigCleanseIndicator"] = false end

  if (_type(_matrix["SliderDrawDistance"]) ~= "number") then _matrix["SliderDrawDistance"] = 100 end
  if (_type(_matrix["SliderLowHealth"]) ~= "number") then _matrix["SliderLowHealth"] = 30 end
  if (_type(_matrix["SliderLowHealthFriendly"]) ~= "number") then _matrix["SliderLowHealthFriendly"] = 0 end
  if (_type(_matrix["SliderVerticalOffset"]) ~= "number") then _matrix["SliderVerticalOffset"] = 20 end
  if (_type(_matrix["SliderBarScale"]) ~= "number") then _matrix["SliderBarScale"] = 100 end
  if (_type(_matrix["SliderFontSize"]) ~= "number") then _matrix["SliderFontSize"] = 1 end

  for i, category in _ipairs(_matrixCategories) do
    for j, filter in _ipairs(_matrixFilters) do
      local l_key = category .. filter
      if (type(_matrix[l_key]) ~= "number") then
        _matrix[l_key] = 3
      end
    end
  end
end

function TwinkiePlates:InitConfiguration()
  _configUI = Apollo.LoadForm(self.xmlDoc, "Configuration", nil, self)
  _configUI:Show(false)

  local l_matrix = _configUI:FindChild("MatrixConfiguration")
  -- local l_rowHeight = (1 / #_matrixCategories)

  -- Matrix layout
  self:DistributeMatrixColumns(l_matrix:FindChild("RowNames"))
  for i, category in _ipairs(_matrixCategories) do
    local containerCategory = l_matrix:FindChild(category)
    -- containerCategory:SetAnchorPoints(0, l_rowHeight * (i - 1), 1, l_rowHeight * i)
    self:DistributeMatrixColumns(containerCategory, category)
  end

  for k, v in _pairs(_matrix) do
    if (string.starts(k, "Config")) then
      local l_button = _configUI:FindChild(k)
      if (l_button ~= nil) then
        l_button:SetCheck(v)
      end
    elseif (string.starts(k, "Slider")) then
      local l_slider = _configUI:FindChild(k)
      if (l_slider ~= nil) then
        l_slider:FindChild("SliderBar"):SetValue(v)
      end
    end
  end
end

function TwinkiePlates:DistributeMatrixColumns(wndElementRow, p_categoryName)
  -- local l_columns = (1 / #_matrixFilters)
  for i, filter in _ipairs(_matrixFilters) do
    -- local l_left = l_columns * (i - 1)
    -- local l_right = l_columns * i
    local l_button = wndElementRow:FindChild(filter)

    -- l_button:SetAnchorPoints(l_left, 0, l_right, 1)
    -- l_button:SetAnchorOffsets(1, 1, -1, -1)

    if (p_categoryName ~= nil) then
      local l_value = _matrix[p_categoryName .. filter] or 0
      l_button:SetSprite(_matrixButtonSprites[l_value])
      l_button:SetStyle("IgnoreTooltipDelay", true)
      l_button:SetTooltip(self:GetMatrixTooltip(l_value))
    end
  end
end

function TwinkiePlates:GetMatrixTooltip(p_value)
  if (p_value == 0) then return "Never enabled" end
  if (p_value == 1) then return "Enabled in combat" end
  if (p_value == 2) then return "Enabled out of combat" end
  if (p_value == 3) then return "Always enabled" end
  return "?"
end

function TwinkiePlates:DistanceToUnit(unitNameplateOwner)
  if (unitNameplateOwner == nil) then return 0 end

  local l_pos = unitNameplateOwner:GetPosition()
  if (l_pos == nil) then return 0 end
  if (l_pos.x == 0) then return 0 end

  local deltaPos = Vector3.New(l_pos.x - _playerPos.x, l_pos.y - _playerPos.y, l_pos.z - _playerPos.z)
  return deltaPos:Length()
end

-------------------------------------------------------------------------------
function TwinkiePlates:FormatNumber(p_number)
  if (p_number == nil) then return "" end
  local l_result = p_number
  if p_number < 1000 then l_result = p_number
  elseif p_number < 1000000 then l_result = _weaselStr("$1f1k", p_number / 1000)
  elseif p_number < 1000000000 then l_result = _weaselStr("$1f1m", p_number / 1000000)
  elseif p_number < 1000000000000 then l_result = _weaselStr("$1f1b", p_number / 1000000)
  end
  return l_result
end

function TwinkiePlates:UpdateTextNameGuild(p_nameplate)
  local l_showTitle = GetFlag(p_nameplate.matrixFlags, F_TITLE)
  local l_showGuild = GetFlag(p_nameplate.matrixFlags, F_GUILD)
  local l_hideAffiliation = _matrix["ConfigHideAffiliations"]
  local l_unit = p_nameplate.unit
  local l_name = l_showTitle and l_unit:GetTitleOrName() or l_unit:GetName()
  local l_guild = nil
  local l_fontSize = _matrix["SliderFontSize"]
  local l_font = _matrix["ConfigAlternativeFont"] and _fontSecondary or _fontPrimary
  local l_width = _textWidth(l_font[l_fontSize].font, l_name .. " ")

  if (l_showGuild and p_nameplate.isPlayer) then
    l_guild = l_unit:GetGuildName() and ("<" .. l_unit:GetGuildName() .. ">") or nil
  elseif (l_showGuild and not l_hideAffiliation and not p_nameplate.isPlayer) then
    l_guild = l_unit:GetAffiliationName() or nil
  end

  p_nameplate.textUnitName:SetText(l_name)
  p_nameplate.textUnitName:SetAnchorOffsets(0, 0, l_width, 0)


  local l_hasGuild = l_guild ~= nil and (_strLen(l_guild) > 0)
  if (p_nameplate.textUnitGuild:IsVisible() ~= l_hasGuild) then
    p_nameplate.textUnitGuild:Show(l_hasGuild)
    p_nameplate.rearrange = true
  end
  if (l_hasGuild) then
    p_nameplate.textUnitGuild:SetTextRaw(l_guild)
  end
end

function TwinkiePlates:UpdateTextLevel(p_nameplate)
  local l_level = p_nameplate.unit:GetLevel()
  if (l_level ~= nil) then
    l_level = --[[ "Lv" .. --]] l_level .. "   "
    local l_fontSize = _matrix["SliderFontSize"]
    local l_font = _matrix["ConfigAlternativeFont"] and _fontSecondary or _fontPrimary
    local l_width = _textWidth(l_font[l_fontSize].font, l_level)
    p_nameplate.levelWidth = l_width
    p_nameplate.textUnitLevel:SetText(l_level)
  else
    p_nameplate.levelWidth = 1
    p_nameplate.textUnitLevel:SetText("")
  end
end

function TwinkiePlates:InitClassIcon(p_nameplate)
  local l_table = p_nameplate.isPlayer and _playerClass or _npcRank
  local l_icon = l_table[p_nameplate.unitClassID]
  p_nameplate.iconUnit:Show(l_icon ~= nil)
  p_nameplate.iconUnit:SetSprite(l_icon ~= nil and l_icon or "")
end

function TwinkiePlates:OnCCStateApplied(nCcId, unitNameplateOwner)

  -- Print("Applied CC ID: " .. tostring(nCcId))

  if (_ccWhiteList[nCcId] == nil) then
    return
  end

  local l_nameplate = self.nameplates[unitNameplateOwner:GetId()]


  if (l_nameplate ~= nil) then
    if (GetFlag(l_nameplate.matrixFlags, F_CC_BAR)) then
      self:RegisterCc(l_nameplate, nCcId)
    end
  end

  -- Print("l_nameplate ~= _targetNP: " .. tostring(l_nameplate ~= _targetNP))

  if (_targetNP ~= nil and _targetNP.unit == unitNameplateOwner) then
    if (GetFlag(_targetNP.matrixFlags, F_CC_BAR)) then
      self:RegisterCc(_targetNP, nCcId)
    end
  end
end

function TwinkiePlates:RegisterCc(tNameplate, nCcId)
  -- GetCCStateTimeRemaining(nCcId) doesn't return any duration as soon as the CC is applied
  --local l_duration = tNameplate.unit:GetCCStateTimeRemaining(nCcId)

  -- Print("nCcId: " .. nCcId .. "; tNameplate.nCcNewId: " .. tNameplate.nCcNewId .. "; tNameplate.nCcActiveId: " .. tNameplate.nCcActiveId)

  local strCcNewName = _ccWhiteList[nCcId]
  -- if (nCcId == 9 or l_duration > tNameplate.nCcDuration) then
  if (strCcNewName) then
    -- tNameplate.nCcDurationMax = _max(l_duration, 0.1)

    -- Register the new CC only if there no MoO already ongoning. The CC duration check is performed in the UpdateCc method
    if (tNameplate.nCcNewId == -1 or (tNameplate.nCcNewId ~= -1 and tNameplate.nCcActiveId ~= Unit.CodeEnumCCState.Vulnerability and tNameplate.nCcNewId ~= Unit.CodeEnumCCState.Vulnerability)) then
      tNameplate.nCcNewId = nCcId

      -- Print("Registered CC: " .. tNameplate.nCcNewId)
    end

    --[[
    if (tNameplate.nCcActiveId == -1) then
      tNameplate.nCcActiveId = nCcId
    end
    ]]

    -- tNameplate.wndContainerCc:SetText(_ccWhiteList[nCcId])
    -- tNameplate.wndContainerCc:Show(true)
    -- tNameplate.rearrange = true
  end
end

function TwinkiePlates:UpdateCc(tNameplate)

  -- Print("tNameplate.nCcActiveId: " .. tNameplate.nCcActiveId ..  "; tNameplate.nCcNewId: " .. tNameplate.nCcNewId )
  -- tNameplate.nCcDuration = tNameplate.unit:GetCCStateTimeRemaining(tNameplate.nCcActiveId) or 0


  local nCcNewDuration = tNameplate.nCcNewId >= 0 and tNameplate.unit:GetCCStateTimeRemaining(tNameplate.nCcNewId) or 0
  tNameplate.nCcDuration = tNameplate.nCcActiveId >=0 and tNameplate.unit:GetCCStateTimeRemaining(tNameplate.nCcActiveId) or 0

  -- Print("tNameplate.nCcActiveId: " .. tNameplate.nCcActiveId .. "; tNameplate.nCcDuration: " .. tNameplate.nCcDuration .. "; tNameplate.nCcNewId: " .. tNameplate.nCcNewId .. "; nCcNewDuration: " .. nCcNewDuration)

  if (nCcNewDuration <= 0 and tNameplate.nCcNewId ~= -1) then
    tNameplate.nCcNewId = -1
  end

  if (tNameplate.nCcDuration <= 0 and tNameplate.nCcActiveId ~= -1) then
    tNameplate.nCcActiveId = -1
  end

  local strCcActiveName = _ccWhiteList[tNameplate.nCcActiveId]
  local strCcNewName = _ccWhiteList[tNameplate.nCcNewId]

  -- Print("tNameplate.nCcActiveId: " .. tNameplate.nCcActiveId .. "; tNameplate.nCcDuration: " .. tNameplate.nCcDuration .. "; tNameplate.nCcNewId: " .. tNameplate.nCcNewId .. "; nCcNewDuration: " .. nCcNewDuration)

  local bShowCcBar = (strCcActiveName and tNameplate.nCcDuration > 0) or (strCcNewName and nCcNewDuration > 0)

  -- Print("bShowCcBar: " .. tostring(bShowCcBar))

  if (tNameplate.wndContainerCc:IsVisible() ~= bShowCcBar) then

    tNameplate.wndContainerCc:Show(bShowCcBar)
    tNameplate.rearrange = true
  end

  -- Print("tNameplate.nCcDurationMax: " .. tNameplate.nCcDurationMax .. "; tNameplate.nCcDuration: " .. tNameplate.nCcDuration)

  if (bShowCcBar) then

    local bUpdateCc = not tNameplate.nCcDurationMax
                      or tNameplate.nCcActiveId == -1
                      or (tNameplate.nCcNewId == Unit.CodeEnumCCState.Vulnerability)
                      or ((nCcNewDuration and nCcNewDuration > tNameplate.nCcDuration)
                          and tNameplate.nCcActiveId ~= Unit.CodeEnumCCState.Vulnerability)

    -- Print("bUpdateCc: " .. tostring(bUpdateCc))

    -- New CC has a longer duration than the previous one (if any) and the current CC state is not a MoO
    if (bUpdateCc) then
    -- if (false) then

      -- Print("tNameplate.nCcActiveId: " .. tNameplate.nCcActiveId .. "; tNameplate.nCcDuration: " .. tNameplate.nCcDuration .. "; strCcNewName: " .. strCcNewName .. "; nCcNewDuration: " .. nCcNewDuration)
      -- Print("tNameplate.nCcDurationMax: " .. tNameplate.nCcDurationMax .. "; tNameplate.nCcDuration: " .. tNameplate.nCcDuration)

      tNameplate.nCcDurationMax = nCcNewDuration
      tNameplate.nCcDuration = nCcNewDuration
      tNameplate.nCcActiveId = tNameplate.nCcNewId
      tNameplate.nCcNewId = -1

      tNameplate.wndContainerCc:SetText(strCcNewName)
      tNameplate.cc:SetMax(nCcNewDuration)
    end

    -- Update the CC progress bar
    tNameplate.cc:SetProgress(tNameplate.nCcDuration)
    -- self:SetProgressBar(tNameplate.cc, tNameplate.nCcDuration, tNameplate.nCcDurationMax)
  end
end

function TwinkiePlates:UpdateCasting(tNameplate)
  local bShowCastBar = tNameplate.unit:ShouldShowCastBar() and GetFlag(tNameplate.matrixFlags, F_CASTING_BAR)
  if (tNameplate.containerCastBar:IsVisible() ~= bShowCastBar) then

    tNameplate.containerCastBar:Show(bShowCastBar)

    tNameplate.rearrange = true
  end
  if (bShowCastBar) then
    local bIsCcVulnerable = tNameplate.unit:GetInterruptArmorMax() >= 0
    tNameplate.form:ToFront()
    tNameplate.containerCastBar:FindChild("BarCasting"):SetBarColor(bIsCcVulnerable and "xkcdDustyOrange" or _color("ff990000"))
    tNameplate.casting:SetProgress(tNameplate.unit:GetCastTotalPercent())
    tNameplate.containerCastBar:SetText(tNameplate.unit:GetCastName())
  end
end

function TwinkiePlates:UpdateArmor(p_nameplate)
  local l_armorMax = p_nameplate.unit:GetInterruptArmorMax()
  local l_showArmor = GetFlag(p_nameplate.matrixFlags, F_ARMOR) and l_armorMax ~= 0

  if (p_nameplate.iconArmor:IsVisible() ~= l_showArmor) then
    p_nameplate.iconArmor:Show(l_showArmor)
  end

  if (not l_showArmor) then return end

  if (l_armorMax > 0) then
    p_nameplate.iconArmor:SetText(p_nameplate.unit:GetInterruptArmorValue())
  end

  if (p_nameplate.prevArmor ~= l_armorMax) then
    p_nameplate.prevArmor = l_armorMax
    if (l_armorMax == -1) then
      p_nameplate.iconArmor:SetText("")
      p_nameplate.iconArmor:SetSprite("NPrimeNameplates_Sprites:IconArmor_02")
    elseif (l_armorMax > 0) then
      p_nameplate.iconArmor:SetSprite("NPrimeNameplates_Sprites:IconArmor")
    end
  end
end

function TwinkiePlates:UpdateOpacity(p_nameplate, p_textBubble)
  if (p_nameplate.targetNP) then return end
  p_textBubble = p_textBubble or false

  if (p_textBubble) then
    p_nameplate.form:SetOpacity(0.25, 10)
  else
    local l_opacity = 1
    if (_matrix["ConfigFadeNonTargeted"] and _player:GetTarget() ~= nil) then
      l_opacity = 0.6
    end
    p_nameplate.form:SetOpacity(l_opacity, 10)
  end
end

function TwinkiePlates:UpdateIconsNPC(p_nameplate)
  local l_flags = 0
  local l_icons = 0

  local l_rewardInfo = p_nameplate.unit:GetRewardInfo()
  if (l_rewardInfo ~= nil and _next(l_rewardInfo) ~= nil) then
    for i = 1, #l_rewardInfo do
      local l_type = l_rewardInfo[i].strType
      if (l_type == _playerPath) then
        l_icons = l_icons + 1
        l_flags = SetFlag(l_flags, F_PATH)
      elseif (l_type == "Quest") then
        l_icons = l_icons + 1
        l_flags = SetFlag(l_flags, F_QUEST)
      elseif (l_type == "Challenge") then
        local l_ID = l_rewardInfo[i].idChallenge
        local l_challenge = self.challenges[l_ID]
        if (l_challenge ~= nil and l_challenge:IsActivated()) then
          l_icons = l_icons + 1
          l_flags = SetFlag(l_flags, F_CHALLENGE)
        end
      end
    end
  end

  p_nameplate.isObjective = l_flags > 0

  if (l_flags ~= p_nameplate.iconFlags) then
    p_nameplate.iconFlags = l_flags
    p_nameplate.containerIcons:DestroyAllPixies()

    local l_height = p_nameplate.containerIcons:GetHeight()
    local l_width = 1 / l_icons
    local l_iconN = 0

    p_nameplate.containerIcons:SetAnchorOffsets(0, 0, l_icons * l_height, 0)

    if (GetFlag(l_flags, F_CHALLENGE)) then
      self:AddIcon(p_nameplate, "IconChallenge", l_iconN, l_width)
      l_iconN = l_iconN + 1
    end

    if (GetFlag(l_flags, F_PATH)) then
      self:AddIcon(p_nameplate, "IconPath", l_iconN, l_width)
      l_iconN = l_iconN + 1
    end

    if (GetFlag(l_flags, F_QUEST)) then
      self:AddIcon(p_nameplate, "IconQuest", l_iconN, l_width)
      l_iconN = l_iconN + 1
    end
  end
end

function TwinkiePlates:UpdateIconsPC(p_nameplate)
  local l_flags = 0
  local l_icons = 0

  if (p_nameplate.unit:IsFriend() or
      p_nameplate.unit:IsAccountFriend()) then
    l_icons = l_icons + 1
    l_flags = SetFlag(l_flags, F_FRIEND)
  end

  if (p_nameplate.unit:IsRival()) then
    l_icons = l_icons + 1
    l_flags = SetFlag(l_flags, F_RIVAL)
  end

  if (l_flags ~= p_nameplate.iconFlags) then
    p_nameplate.iconFlags = l_flags
    p_nameplate.containerIcons:DestroyAllPixies()

    local l_height = p_nameplate.containerIcons:GetHeight()
    local l_width = 1 / l_icons
    local l_iconN = 0

    p_nameplate.containerIcons:SetAnchorOffsets(0, 0, l_icons * l_height, 0)

    if (GetFlag(l_flags, F_FRIEND)) then
      self:AddIcon(p_nameplate, "IconFriend", l_iconN, l_width)
      l_iconN = l_iconN + 1
    end

    if (GetFlag(l_flags, F_RIVAL)) then
      self:AddIcon(p_nameplate, "IconRival", l_iconN, l_width)
      l_iconN = l_iconN + 1
    end
  end
end

function TwinkiePlates:AddIcon(p_nameplate, p_sprite, p_iconN, p_width)
  _iconPixie.strSprite = p_sprite
  _iconPixie.loc.fPoints[1] = p_iconN * p_width
  _iconPixie.loc.fPoints[3] = (p_iconN + 1) * p_width
  p_nameplate.containerIcons:AddPixie(_iconPixie)
end

function TwinkiePlates:HasHealth(unitNameplateOwner)

  if (unitNameplateOwner == nil)
  then return false
  end

  if (unitNameplateOwner:GetMouseOverType() == "Simple" or unitNameplateOwner:GetMouseOverType() == "SimpleCollidable")
  then return false
  end

  if (unitNameplateOwner:IsDead())
  then return false
  end

  if (unitNameplateOwner:GetMaxHealth() == nil)
  then return false
  end

  if (unitNameplateOwner:GetMaxHealth() == 0)
  then return false
  end

  return true
end

function TwinkiePlates:GetNameplateVisibility(p_nameplate)
  if (_blinded) then return false end

  if (not p_nameplate.onScreen) then return false end

  -- if the nameplate has a target set (which probably means it's a player's nameplate)
  if (p_nameplate.targetNP) then
    -- return true if the nameplate's unit is targeted by the player, false otherwise
    return _player:GetTarget() == p_nameplate.unit
  end

  -- return false if the nameplate is targeted by the player. Targeted nameplate is handled by _TargetNP
  if (_player:GetTarget() == p_nameplate.unit) then return false end

  if (_matrix["ConfigOcclusionCulling"] and p_nameplate.occluded) then return false
  end

  if (not GetFlag(p_nameplate.matrixFlags, F_NAMEPLATE)) then
    return p_nameplate.hasActivationState or p_nameplate.isObjective
  end

  if (p_nameplate.unit:IsDead()) then return false end
  if (p_nameplate.outOfRange) then return false end

  local l_isFriendly = p_nameplate.eDisposition == Unit.CodeEnumDisposition.Friendly
  if (not p_nameplate.isPlayer and l_isFriendly) then
    return p_nameplate.hasActivationState or p_nameplate.isObjective
  end

  return true
end

function TwinkiePlates:InitAnchoring(tNameplate, nCodeEnumFloaterLocation)
  local tAnchorUnit = tNameplate.unit:IsMounted() and tNameplate.unit:GetUnitMount() or tNameplate.unit
  local bReposition = false
  -- local nCodeEnumFloaterLocation = nCodeEnumFloaterLocation

  if (self.nameplacer or nCodeEnumFloaterLocation) then
    if (not nCodeEnumFloaterLocation) then
      local tNameplatePositionSetting = self.nameplacer:GetUnitNameplatePositionSetting(tNameplate.unit:GetName())

      if (tNameplatePositionSetting and tNameplatePositionSetting["nAnchorId"]) then
        nCodeEnumFloaterLocation = tNameplatePositionSetting["nAnchorId"]
        -- tNameplate.form:SetUnit(tAnchorUnit, nCodeEnumFloaterLocation)
      end
    end

    -- Print("\\\\\\\\\\\\\\\\\ unit name: " .. tAnchorUnit:GetName() .. "; nCodeEnumFloaterLocation: " .. tostring(nCodeEnumFloaterLocation) .. "; tNameplate.form:GetUnit(tAnchorUnit): " .. tostring(tNameplate.form:GetUnit(tAnchorUnit)))

    if (nCodeEnumFloaterLocation) then
      -- Print("\\\\\\\\\\\\\\\\\ unit name: " .. tAnchorUnit:GetName() .. "; nCodeEnumFloaterLocation: " .. tostring(nCodeEnumFloaterLocation) .. "; tNameplate.form:GetUnit(tAnchorUnit): " .. tostring(tNameplate.form:GetUnit(tAnchorUnit)))
      tNameplate.form:SetUnit(tAnchorUnit, nCodeEnumFloaterLocation)
      return
    end
  end

  tNameplate.form:SetUnit(tAnchorUnit, 1)
end



--[[
-- See if a nameplate should be displayed
function OptiPlates:HelperVerifyVisibilityOptions(tNameplate)
  if tNameplate == nil then return false end
  local unitPlayer = self.playerUnit
  local unitOwner = tNameplate.unitOwner
  local eDisposition = unitOwner:GetDispositionTo(unitPlayer)
  local isImportant = tNameplate.bIsImportantNPC
  local isVendor = tNameplate.bIsVendorNPC
  if unitOwner == nil or not unitOwner:IsValid() then
    return false
  end


  -- Always show target nameplate, regardless of what it is
  if unitPlayer ~= nil then
    local unitPlayerTarget = unitPlayer:GetTarget()
    if unitPlayerTarget ~= nil and unitPlayerTarget == unitOwner then
      return true
    end
  end
  -- PET PLATES

  if tNameplate.bGibbed then
    return false
  end

  local bShowNameplate = false
  tNameplate.eDisposition = eDisposition
  if tNameplate.bIsPet then
    if not unitOwner:GetUnitOwner() or unitOwner:GetUnitOwner() == nil then
      if eDisposition == 2 then
        bShowNameplate = self.setShowFriendlyPets
      else
        bShowNameplate = self.setShowHostilePets
      end
    elseif unitOwner:GetUnitOwner():IsThePlayer() == true then
      bShowNameplate = self.setShowMyPets
    else
      if eDisposition == 2 then
        bShowNameplate = self.setShowFriendlyPets
      else
        bShowNameplate = self.setShowHostilePets
      end
    end
  elseif eDisposition == 2 and unitOwner:GetHealth() ~= nil then
    bShowNameplate = true
  elseif eDisposition == 0 then
    bShowNameplate = true
  elseif eDisposition == 1 and unitOwner:GetHealth() ~= nil then
    bShowNameplate = true
  end

  if self.setIconQuest and tNameplate.bIsObjective then
    bShowNameplate = true
  end

  if self.bShowMainGroupOnly and unitOwner:IsInYourGroup() then
    bShowNameplate = true
  end

  if tNameplate.bIsWeapon then
    bShowNameplate = true
  end
  if tNameplate.bIsHarvest then
    bShowNameplate = true
  end

  local tActivation = unitOwner:GetActivationState()
  if tActivation.FlightPathSettler ~= nil or tActivation.FlightPath ~= nil or tActivation.FlightPathNew then
    bShowNameplate = true

    --Vendors
  elseif self.setF_Vendor and isVendor then
    bShowNameplate = true
  elseif self.setF_Important and isImportant then
    bShowNameplate = true
    --QuestGivers too
  elseif tActivation.QuestReward ~= nil then
    bShowNameplate = true
  elseif tActivation.QuestNew ~= nil or tActivation.QuestNewMain ~= nil then
    bShowNameplate = true
  elseif tActivation.QuestReceiving ~= nil then
    bShowNameplate = true
  elseif tActivation.TalkTo ~= nil then
    bShowNameplate = true
  end

  if bShowNameplate == true then
    bShowNameplate = not (self.bPlayerInCombat and self.bHideInCombat)
  end

  if unitOwner:IsThePlayer() then
    if not unitOwner:IsDead() then
      bShowNameplate = true
    else
      bShowNameplate = false
    end
  end


  --if unitPlayer ~= nil and unitPlayer:IsMounted() and unitPlayer:GetUnitMount() == unitOwner then
  --	bShowNameplate = false
  --end


  return bShowNameplate
end
]]

function TwinkiePlates:GetUnitType(unitNameplateOwner)
  if (unitNameplateOwner == nil) then return "Hidden" end
  if (not unitNameplateOwner:IsValid()) then return "Hidden" end

  if (unitNameplateOwner:CanBeHarvestedBy(_player)) then
    return _matrix["ConfigShowHarvest"] and "Other" or "Hidden"
  end

  if (unitNameplateOwner:IsThePlayer()) then return "Self" end
  if (unitNameplateOwner:IsInYourGroup()) then return "Group" end

  local l_type = unitNameplateOwner:GetType()
  if (l_type == "BindPoint") then return "Other" end
  if (l_type == "PinataLoot") then return "Other" end
  if (l_type == "Ghost") then return "Hidden" end
  if (l_type == "Mount") then return "Hidden" end
  -- if (l_type == "Collectible")  then return "Hidden" end

  --[[ 
	if (unitNameplateOwner:GetName() == "Derelict Silo Egg") then
		     local Rover = Apollo.GetAddon("Rover")
    			Rover:AddWatch("WatchName", unitNameplateOwner, Rover.ADD_ONCE )
	end
	--]]

  -- Some interactable objects are identified as NonPlayer
  -- This hack is done to prevent display the nameplate for this kind of units
  if (l_type == "NonPlayer" and not unitNameplateOwner:GetUnitRaceId() and not unitNameplateOwner:GetLevel()) then
    return "Hidden"
  end

  local eDisposition = unitNameplateOwner:GetDispositionTo(_player)
  local bIsCharacter = unitNameplateOwner:IsACharacter()
  local strPcOrNpc = (bIsCharacter) and "Pc" or "Npc"

  if (_exceptions[unitNameplateOwner:GetName()] ~= nil) then
    return _exceptions[unitNameplateOwner:GetName()] and _dispStr[eDisposition] .. strPcOrNpc or "Hidden"
  end

  local tRewardInfo = unitNameplateOwner:GetRewardInfo()

  if (tRewardInfo ~= nil and _next(tRewardInfo) ~= nil) then
    for i = 1, #tRewardInfo do
      if (tRewardInfo[i].strType ~= "Challenge") then
        return _dispStr[eDisposition] .. strPcOrNpc
      end
    end
  end

  if (bIsCharacter or self:HasActivationState(unitNameplateOwner)) then
    return _dispStr[eDisposition] .. strPcOrNpc
  end

  if (unitNameplateOwner:GetHealth() == nil) then return "Hidden" end

  local l_archetype = unitNameplateOwner:GetArchetype()

  -- Returning Friendly/Neutral/Hostile .. Pc/Npc
  if (l_archetype ~= nil) then
    return _dispStr[eDisposition] .. strPcOrNpc
  end

  return "Hidden"
end

function TwinkiePlates:SetCombatState(p_nameplate, p_inCombat)
  if (p_nameplate == nil) then return end

  -- If combat state changed
  if (p_nameplate.inCombat ~= p_inCombat) then
    p_nameplate.inCombat = p_inCombat
    p_nameplate.matrixFlags = self:GetMatrixFlags(p_nameplate)
    self:UpdateTextNameGuild(p_nameplate)
    self:UpdateTopContainer(p_nameplate)
  end

  self:UpdateMainContainerHeight(p_nameplate)

  -- p_nameplate.rearrange = true
end

function TwinkiePlates:HasActivationState(unitNameplateOwner)
  local l_activationStates = unitNameplateOwner:GetActivationState()
  if (_next(l_activationStates) == nil) then return false end
  local l_show = false
  for state, a in _pairs(l_activationStates) do
    if (state == "Busy") then return false end
    if (not _asbl[state]) then l_show = true end
  end
  return l_show
end

function TwinkiePlates:SetProgressBar(p_bar, p_current, p_max)
  p_bar:SetMax(p_max)
  p_bar:SetProgress(p_current)
end

function TwinkiePlates:SetNameplateVerticalOffset(tNameplate, nVerticalOffset, nNameplacerVerticalOffset)

  -- Print("SetNameplateVerticalOffset; nNameplacerVerticalOffset: " .. tostring(nNameplacerVerticalOffset))
  tNameplate.form:SetAnchorOffsets(-200, -75 - nVerticalOffset - nNameplacerVerticalOffset, 200, 75 - nVerticalOffset - nNameplacerVerticalOffset)
end

function TwinkiePlates:AllocateNameplate(unitNameplateOwner)
  if (self.nameplates[unitNameplateOwner:GetId()] == nil) then
    local l_type = self:GetUnitType(unitNameplateOwner)
    if (l_type ~= "Hidden") then
      local l_nameplate = self:InitNameplate(unitNameplateOwner, _tableRemove(self.pool) or nil, l_type)
      self.nameplates[unitNameplateOwner:GetId()] = l_nameplate
    end
  end
end

function TwinkiePlates:OnUnitDestroyed(unitNameplateOwner)
  local l_nameplate = self.nameplates[unitNameplateOwner:GetId()]
  if (l_nameplate == nil) then return end

  if (#self.pool < 50) then
    l_nameplate.form:Show(false, true)
    l_nameplate.form:SetUnit(nil)
    l_nameplate.textUnitName:SetData(nil)
    l_nameplate.health:SetData(nil)
    l_nameplate.bIsVerticalOffsetUpdated = nil
    _tableInsert(self.pool, l_nameplate)
  else
    l_nameplate.form:Destroy()
  end
  self.nameplates[unitNameplateOwner:GetId()] = nil
end

function TwinkiePlates:UpdateMainContainerHeightWithHealthText(p_nameplate)
  local l_fontSize = _matrix["SliderFontSize"]
  local l_zoomSliderH = _matrix["SliderBarScale"] / 10
  local l_shieldHeight = p_nameplate.hasShield and l_zoomSliderH * 1.3 or l_zoomSliderH
  local l_healthTextFont = _matrix["ConfigAlternativeFont"] and _fontSecondary or _fontPrimary
  local l_healthTextHeight = _matrix["ConfigHealthText"] and (l_healthTextFont[l_fontSize].height * 0.75) or 0

  -- p_nameplate.health:SetAnchorOffsets(0, 0, 0, --[[l_shieldHeight + l_healthTextHeight]] p_nameplate.hasShield and 0 or -4)
  p_nameplate.wndHealthText:Show(true)
end

function TwinkiePlates:UpdateMainContainerHeightWithoutHealthText(p_nameplate)
  -- Reset text
  -- p_nameplate.containerMain:SetText("")

  -- Set container height without text
  local l_zoomSliderH = _matrix["SliderBarScale"] / 10
  local l_shieldHeight = p_nameplate.hasShield and l_zoomSliderH * 1.3 or l_zoomSliderH
  -- p_nameplate.containerMain:SetAnchorOffsets(144, -5, -144, --[[l_shieldHeight]] 16)
  p_nameplate.wndHealthText:Show(false)
end

-------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- Configuration Functions
---------------------------------------------------------------------------------------------------
function TwinkiePlates:OnButtonSignalShowInfoPanel(wndHandler, wndControl, eMouseButton)
end

local TwinkiePlatesInst = TwinkiePlates:new()
TwinkiePlatesInst:Init()

function table.val_to_str(v)
  if "string" == type(v) then
    v = string.gsub(v, "\n", "\\n")
    if string.match(string.gsub(v, "[^'\"]", ""), '^"+$') then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v, '"', '\\"') .. '"'
  else
    return "table" == type(v) and table.tostring(v) or
        tostring(v)
  end
end

function table.key_to_str(k)
  if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
    return k
  else
    return "[" .. table.val_to_str(k) .. "]"
  end
end

function table.tostring(tbl)
  if (not tbl) then return "nil" end

  local result, done = {}, {}
  for k, v in ipairs(tbl) do
    table.insert(result, table.val_to_str(v))
    done[k] = true
  end
  for k, v in pairs(tbl) do
    if not done[k] then
      table.insert(result,
        table.key_to_str(k) .. "=" .. table.val_to_str(v))
    end
  end
  return "{" .. table.concat(result, ",") .. "}"
end
