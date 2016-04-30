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

local N_NEVER_ENABLED = 0
local N_ENABLED_IN_COMBAT = 1
local N_ALWAYS_OUT_OF_COMBAT = 2
local N_ALWAYS_ENABLED = 3

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

local _tDisplayHideExceptionUnitNames =
{
  ["NyanPrime"] = false, -- Hidden
  ["Cactoid"] = true, -- Visible
  ["Spirit of the Darned"] = true,
  ["Wilderrun Trap"] = true,
  ["Essence of Logic"] = true,
  ["Teleporter Generator"] = false,
  ["Firewall"] = false,
  ["Engineer2 - Hostile Invisible Unit for Fields (1.2m Radius)"] = false,
  ["Spiritmother Selene's Echo"] = true,
  ["Data Devourer Spawner"] = false,
  ["Spore Cloud"] = false,
}

local _color = ApolloColor.new

local _tFromPlayerClassToIcon =
{
  [GameLib.CodeEnumClass.Esper] = "NPrimeNameplates_Sprites:IconEsper",
  [GameLib.CodeEnumClass.Medic] = "NPrimeNameplates_Sprites:IconMedic",
  [GameLib.CodeEnumClass.Stalker] = "NPrimeNameplates_Sprites:IconStalker",
  [GameLib.CodeEnumClass.Warrior] = "NPrimeNameplates_Sprites:IconWarrior",
  [GameLib.CodeEnumClass.Engineer] = "NPrimeNameplates_Sprites:IconEngineer",
  [GameLib.CodeEnumClass.Spellslinger] = "NPrimeNameplates_Sprites:IconSpellslinger",
}

local _tFromNpcRankToIcon =
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

local _tFromSettingToColor =
{
  Self = _color("FF7DAF29"),
  Target = _color("xkcdLightMagenta"),
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
  NoAggro = _color("FF55FAFF"),
  Cleanse = _color("FFAF40E1"),
  LowHpFriendly = _color("FF0000FF"),
  LowHpNotFriendly = _color("FF55FAFF"),
}

local _paths =
{
  [0] = "Soldier",
  [1] = "Settler",
  [2] = "Scientist",
  [3] = "Explorer",
}

local _tUiElements =
{
  ["Nameplates"] = {
    ["Self"] = "NameplatesSelf",
    ["Target"] = "NameplatesTarget",
    ["Group"] = "NameplatesGroup",
    ["FriendlyPc"] = "NameplatesFriendlyPc",
    ["FriendlyNpc"] = "NameplatesFriendlyNpc",
    ["NeutralPc"] = "NameplatesNeutralPc",
    ["NeutralNpc"] = "NameplatesNeutralNpc",
    ["HostilePc"] = "NameplatesHostilePc",
    ["HostileNpc"] = "NameplatesHostileNpc",
    ["Other"] = "NameplatesOther"
  },
  ["Health"] = {
    ["Self"] = "HealthSelf",
    ["Target"] = "HealthTarget",
    ["Group"] = "HealthGroup",
    ["FriendlyPc"] = "HealthFriendlyPc",
    ["FriendlyNpc"] = "HealthFriendlyNpc",
    ["NeutralPc"] = "HealthNeutralPc",
    ["NeutralNpc"] = "HealthNeutralNpc",
    ["HostilePc"] = "HealthHostilePc",
    ["HostileNpc"] = "HealthHostileNpc",
    ["Other"] = "HealthOther"
  },
  ["HealthText"] = {
    ["Self"] = "HealthTextSelf",
    ["Target"] = "HealthTextTarget",
    ["Group"] = "HealthTextGroup",
    ["FriendlyPc"] = "HealthTextFriendlyPc",
    ["FriendlyNpc"] = "HealthTextFriendlyNpc",
    ["NeutralPc"] = "HealthTextNeutralPc",
    ["NeutralNpc"] = "HealthTextNeutralNpc",
    ["HostilePc"] = "HealthTextHostilePc",
    ["HostileNpc"] = "HealthTextHostileNpc",
    ["Other"] = "HealthTexOther"
  },
  ["Class"] = {
    ["Self"] = "ClassSelf",
    ["Target"] = "ClassTarget",
    ["Group"] = "ClassGroup",
    ["FriendlyPc"] = "ClassFriendlyPc",
    ["FriendlyNpc"] = "ClassFriendlyNpc",
    ["NeutralPc"] = "ClassNeutralPc",
    ["NeutralNpc"] = "ClassNeutralNpc",
    ["HostilePc"] = "ClassHostilePc",
    ["HostileNpc"] = "ClassHostileNpc",
    ["Other"] = "ClassOther"
  },
  ["Level"] = {
    ["Self"] = "LevelSelf",
    ["Target"] = "LevelTarget",
    ["Group"] = "LevelGroup",
    ["FriendlyPc"] = "LevelFriendlyPc",
    ["FriendlyNpc"] = "LevelFriendlyNpc",
    ["NeutralPc"] = "LevelNeutralPc",
    ["NeutralNpc"] = "LevelNeutralNpc",
    ["HostilePc"] = "LevelHostilePc",
    ["HostileNpc"] = "LevelHostileNpc",
    ["Other"] = "LevelOther"
  },
  ["Title"] = {
    ["Self"] = "TitleSelf",
    ["Target"] = "TitleTarget",
    ["Group"] = "TitleGroup",
    ["FriendlyPc"] = "TitleFriendlyPc",
    ["FriendlyNpc"] = "TitleFriendlyNpc",
    ["NeutralPc"] = "TitleNeutralPc",
    ["NeutralNpc"] = "TitleNeutralNpc",
    ["HostilePc"] = "TitleHostilePc",
    ["HostileNpc"] = "TitleHostileNpc",
    ["Other"] = "TitleOther"
  },
  ["Guild"] = {
    ["Self"] = "GuildSelf",
    ["Target"] = "GuildTarget",
    ["Group"] = "GuildGroup",
    ["FriendlyPc"] = "GuildFriendlyPc",
    ["FriendlyNpc"] = "GuildFriendlyNpc",
    ["NeutralPc"] = "GuildNeutralPc",
    ["NeutralNpc"] = "GuildNeutralNpc",
    ["HostilePc"] = "GuildHostilePc",
    ["HostileNpc"] = "GuildHostileNpc",
    ["Other"] = "GuildOther"
  },
  ["CastingBar"] = {
    ["Self"] = "CastingBarSelf",
    ["Target"] = "CastingBarTarget",
    ["Group"] = "CastingBarGroup",
    ["FriendlyPc"] = "CastingBarFriendlyPc",
    ["FriendlyNpc"] = "CastingBarFriendlyNpc",
    ["NeutralPc"] = "CastingBarNeutralPc",
    ["NeutralNpc"] = "CastingBarNeutralNpc",
    ["HostilePc"] = "CastingBarHostilePc",
    ["HostileNpc"] = "CastingBarHostileNpc",
    ["Other"] = "CastingBarOther"
  },
  ["CCBar"] = {
    ["Self"] = "CCBarSelf",
    ["Target"] = "CCBarTarget",
    ["Group"] = "CCBarGroup",
    ["FriendlyPc"] = "CCBarFriendlyPc",
    ["FriendlyNpc"] = "CCBarFriendlyNpc",
    ["NeutralPc"] = "CCBarNeutralPc",
    ["NeutralNpc"] = "CCBarNeutralNpc",
    ["HostilePc"] = "CCBarHostilePc",
    ["HostileNpc"] = "CCBarHostileNpc",
    ["Other"] = "CCBarOther"
  },
  ["Armor"] = {
    ["Self"] = "ArmorSelf",
    ["Target"] = "ArmorTarget",
    ["Group"] = "ArmorGroup",
    ["FriendlyPc"] = "ArmorFriendlyPc",
    ["FriendlyNpc"] = "ArmorFriendlyNpc",
    ["NeutralPc"] = "ArmorNeutralPc",
    ["NeutralNpc"] = "ArmorNeutralNpc",
    ["HostilePc"] = "ArmorHostilePc",
    ["HostileNpc"] = "ArmorHostileNpc",
    ["Other"] = "ArmorOther"
  },
  ["TextBubbleFade"] = {
    ["Self"] = "TextBubbleFadeSelf",
    ["Target"] = "TextBubbleFadeTarget",
    ["Group"] = "TextBubbleFadeGroup",
    ["FriendlyPc"] = "TextBubbleFadeFriendlyPc",
    ["FriendlyNpc"] = "TextBubbleFadeFriendlyNpc",
    ["NeutralPc"] = "TextBubbleFadeNeutralPc",
    ["NeutralNpc"] = "TextBubbleFadeNeutralNpc",
    ["HostilePc"] = "TextBubbleFadeHostilePc",
    ["HostileNpc"] = "TextBubbleFadeHostileNpc",
    ["Other"] = "TextBubbleOther"
  },
}

local _tUnitCategories =
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
  "Other",
}

local _matrixButtonSprites =
{
  [N_NEVER_ENABLED] = "MatrixOff",
  [N_ENABLED_IN_COMBAT] = "MatrixInCombat",
  [N_ALWAYS_OUT_OF_COMBAT] = "MatrixOutOfCombat",
  [N_ALWAYS_ENABLED] = "MatrixOn",
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

local _tDispositionToString = {
  [Unit.CodeEnumDisposition.Hostile] = { ["Pc"] = "HostilePc", ["Npc"] = "HostileNpc" },
  [Unit.CodeEnumDisposition.Neutral] = { ["Pc"] = "NeutralPc", ["Npc"] = "NeutralNpc" },
  [Unit.CodeEnumDisposition.Friendly] = { ["Pc"] = "FriendlyPc", ["Npc"] = "FriendlyNpc" },
  [Unit.CodeEnumDisposition.Unknown] = { ["Pc"] = "Hidden", ["Npc"] = "Hidden" },
}

local _tUiElementToFlag = {
  ["Nameplates"] = F_NAMEPLATE,
  ["Health"] = F_HEALTH,
  ["HealthText"] = F_HEALTH_TEXT,
  ["Class"] = F_CLASS,
  ["Level"] = F_LEVEL,
  ["Title"] = F_TITLE,
  ["Guild"] = F_GUILD,
  ["CastingBar"] = F_CASTING_BAR,
  ["CCBar"] = F_CC_BAR,
  ["Armor"] = F_ARMOR,
  ["TextBubbleFade"] = F_BUBBLE,
}

local _tPvpZones = {
  [4456] = true, -- The Slaughterdome
  [4457] = true, -- The Slaughterdome
  [4460] = true, -- The Slaughterdome
  [478] = true, -- The Cryoplex
  [4471] = true, -- Walatiki Temple
  [2176] = true, -- Walatiki Temple
  [2193] = false, -- Test
  [2177] = true, -- Halls of the Bloodsworn
  [4472] = true, -- Halls of the Bloodsworn
  [103] = true, -- Daggerstone Pass
}

local _unitPlayer
local _playerPath
local _playerPos
local _bIsPlayerBlinded

local _tTargetNameplate

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

local _wndConfigUi

local _tSettings = {}
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

local _tTargetPixie =
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
  self.tNameplates = {}
  self.pool = {}
  self.buffer = {}
  self.challenges = ChallengesLib.GetActiveChallengeList()

  Apollo.RegisterEventHandler("VarChange_FrameCount", "OnDebuggerUnit", self)

  Apollo.RegisterSlashCommand("tp", "OnConfigure", self)
  Apollo.RegisterEventHandler("ShowTwinkiePlatesConfigurationWnd", "OnConfigure", self)

  Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
  Apollo.RegisterEventHandler("VarChange_FrameCount", "OnFrame", self)
  Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", self)
  Apollo.RegisterEventHandler("SubZoneChanged", "OnSubZoneChanged", self)

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

  --  Apollo.RegisterEventHandler("UnitGibbed", "OnUnitGibbed", self)
  Apollo.RegisterEventHandler("CombatLogDeath", "OnCombatLogDeath", self)
  Apollo.RegisterEventHandler("CombatLogResurrect", "OnCombatLogResurrect", self)
  --  Apollo.RegisterEventHandler("CharacterFlagsUpdated", "OnCharacterFlagsUpdated", self)
  Apollo.RegisterEventHandler("ApplyCCState", "OnCCStateApplied", self)
  --  Apollo.RegisterEventHandler("UnitGroupChanged", "OnGroupUpdated", self)
  Apollo.RegisterEventHandler("ChallengeUnlocked", "OnChallengeUnlocked", self)

  -- Too unreliable
  -- Apollo.RegisterEventHandler("UnitEnteredCombat", "OnUnitCombatStateChanged", self)
  Apollo.RegisterEventHandler("UnitPvpFlagsChanged", "OnUnitPvpFlagsChanged", self)

  Apollo.RegisterEventHandler("FriendshipAdd", "OnFriendshipChanged", self)
  Apollo.RegisterEventHandler("FriendshipRemove", "OnFriendshipChanged", self)

  self.nameplacer = Apollo.GetAddon("Nameplacer")
  if (self.nameplacer) then
    Apollo.RegisterEventHandler("Nameplacer_UnitNameplatePositionChanged", "OnNameplatePositionSettingChanged", self)
  end

  self.perspectivePlates = Apollo.GetAddon("PerspectivePlates")

  self.xmlDoc = XmlDoc.CreateFromFile("TwinkiePlates.xml")
  Apollo.LoadSprites("TwinkiePlates_Sprites.xml")
end

function TwinkiePlates:OnSave(p_type)
  if p_type ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
  return _tSettings
end

function TwinkiePlates:OnRestore(p_type, p_savedData)
  if p_type ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
  _tSettings = p_savedData
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
  _unitPlayer = nil

  if (_tTargetNameplate ~= nil) then
    if (_tTargetNameplate.targetMark ~= nil) then
      _tTargetNameplate.targetMark:Destroy()
    end
    _tTargetNameplate.wndNameplate:Destroy()
    _tTargetNameplate = nil
  end
end

function TwinkiePlates:UpdateCurrentZoneInfo(nZoneId)
  --  local tCurrentZone = GameLib.GetCurrentZoneMap()

  self.nCurrentZoneId = nZoneId
end

function TwinkiePlates:OnUnitCombatStateChanged(unit, bIsInCombat)
  if (unit == nil) then return end
  local tNameplate = self.tNameplates[unit:GetId()]
  self:SetCombatState(tNameplate, bIsInCombat)
  if (_unitPlayer ~= nil and _unitPlayer:GetTarget() == unit) then
    self:SetCombatState(_tTargetNameplate, bIsInCombat)
  end
end

function TwinkiePlates:OnGroupUpdated(unitNameplateOwner)
  if (unitNameplateOwner == nil) then return end
  local tNameplate = self.tNameplates[unitNameplateOwner:GetId()]
  if (tNameplate ~= nil) then
    local strPcOrNpc = tNameplate.bIsPlayer and "Pc" or "Npc"
    tNameplate.bIsInGroup = unitNameplateOwner:IsInYourGroup()
    tNameplate.strUnitCategory = tNameplate.bIsInGroup and "Group" or _tDispositionToString[tNameplate.eDisposition][strPcOrNpc]
  end
end

function TwinkiePlates:OnUnitPvpFlagsChanged(unit)
  if (not unit) then return end

  local bPvpFlagged = self:IsPvpFlagged(unit)
  local tNameplate = self.tNameplates[unit:GetId()]

  -- Update unit nameplate
  if (tNameplate) then
    tNameplate.bIsPvpFlagged = bPvpFlagged
  end

  -- Update target nameplate as well
  if (_tTargetNameplate and _unitPlayer:GetTarget() == unit) then
    _tTargetNameplate.bIsPvpFlagged = bPvpFlagged
  end
end

function TwinkiePlates:OnSubZoneChanged(nZoneId, strSubZoneName)

  Print("TwinkiePlates:OnSubZoneChanged; Current zone: " .. tostring(nZoneId))

  self:UpdateCurrentZoneInfo(nZoneId)
end



function TwinkiePlates:InitNameplate(unitNameplateOwner, tNameplate, bIsTargetNameplate)
  tNameplate = tNameplate or {}
  bIsTargetNameplate = bIsTargetNameplate or false

  local bIsCharacter = unitNameplateOwner:IsACharacter()

  tNameplate.unitNameplateOwner = unitNameplateOwner
  tNameplate.unitClassID = bIsCharacter and unitNameplateOwner:GetClassId() or unitNameplateOwner:GetRank()
  tNameplate.bPet = self:IsPet(unitNameplateOwner)
  tNameplate.eDisposition = self:GetDispositionTo(unitNameplateOwner, _unitPlayer)
  tNameplate.bIsPlayer = bIsCharacter
  tNameplate.bForcedHideDisplayToggle = _tDisplayHideExceptionUnitNames[unitNameplateOwner:GetName()]

  tNameplate.strUnitCategory = self:GetUnitCategoryType(unitNameplateOwner)
  tNameplate.color = "FFFFFFFF"
  tNameplate.bIsTargetNameplate = bIsTargetNameplate
  tNameplate.bHasHealth = self:HasHealth(unitNameplateOwner)

  if (bIsTargetNameplate) then
    local l_source = self.tNameplates[unitNameplateOwner:GetId()]
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

  tNameplate.bRefreshHealthShieldBar = false
  tNameplate.bIsLowHealth = false
  tNameplate.nCurrHealth = tNameplate.bHasHealth and tNameplate.unitNameplateOwner:GetHealth() or nil
  tNameplate.healthy = false
  tNameplate.prevArmor = nil
  tNameplate.levelWidth = 1

  tNameplate.iconFlags = -1
  tNameplate.nNonCombatStateFlags = -1
  tNameplate.nMatrixFlags = -1
  tNameplate.bRearrange = false

  tNameplate.bIsUnitOutOfRange = true
  tNameplate.bIsOccluded = unitNameplateOwner:IsOccluded()
  tNameplate.bIsInCombat = self:IsInCombat(tNameplate)
  tNameplate.bIsInGroup = unitNameplateOwner:IsInYourGroup()
  tNameplate.isMounted = unitNameplateOwner:IsMounted()
  tNameplate.bIsObjective = false
  tNameplate.bIsPvpFlagged = unitNameplateOwner:IsPvpFlagged()
  tNameplate.bHasActivationState = self:HasActivationState(unitNameplateOwner)
  tNameplate.bHasShield = unitNameplateOwner:GetShieldCapacityMax() ~= nil and unitNameplateOwner:GetShieldCapacityMax() ~= 0

  local l_zoomSliderW = _tSettings["SliderBarScale"] / 2
  local l_zoomSliderH = _tSettings["SliderBarScale"] / 10
  local l_fontSize = _tSettings["SliderFontSize"]
  local l_font = _tSettings["ConfigAlternativeFont"] and _fontSecondary or _fontPrimary

  if (tNameplate.wndNameplate == nil) then
    -- Print("TwinkiePlates: InitNameplate; New form!")

    tNameplate.wndNameplate = Apollo.LoadForm(self.xmlDoc, "Nameplate", "InWorldHudStratum", self)

    tNameplate.containerTop = tNameplate.wndNameplate:FindChild("ContainerTop")
    tNameplate.wndContainerMain = tNameplate.wndNameplate:FindChild("ContainerMain")
    tNameplate.containerIcons = tNameplate.wndNameplate:FindChild("ContainerIcons")

    tNameplate.wndUnitNameText = tNameplate.wndNameplate:FindChild("TextUnitName")
    tNameplate.textUnitGuild = tNameplate.wndNameplate:FindChild("TextUnitGuild")
    tNameplate.textUnitLevel = tNameplate.wndNameplate:FindChild("TextUnitLevel")

    tNameplate.wndContainerCc = tNameplate.wndNameplate:FindChild("ContainerCC")
    tNameplate.containerCastBar = tNameplate.wndNameplate:FindChild("ContainerCastBar")
    tNameplate.wndCastBar = tNameplate.containerCastBar:FindChild("BarCasting")

    tNameplate.wndClassRankIcon = tNameplate.wndNameplate:FindChild("IconUnit")
    tNameplate.iconArmor = tNameplate.wndNameplate:FindChild("IconArmor")

    tNameplate.wndHealthProgressBar = tNameplate.wndNameplate:FindChild("BarHealth")
    tNameplate.wndHealthText = tNameplate.wndNameplate:FindChild("TextHealth")
    tNameplate.wndShieldBar = tNameplate.wndNameplate:FindChild("BarShield")
    tNameplate.wndAbsorbBar = tNameplate.wndNameplate:FindChild("BarAbsorb")
    tNameplate.wndCcBar = tNameplate.wndNameplate:FindChild("BarCC")
    tNameplate.wndCleanseFrame = tNameplate.wndNameplate:FindChild("CleanseFrame")
    tNameplate.wndCleanseFrame:SetBGColor(_tFromSettingToColor["Cleanse"])

    if (not _tSettings["ConfigBarIncrements"]) then
      tNameplate.wndHealthProgressBar:SetFullSprite("Bar_02")
      tNameplate.wndHealthProgressBar:SetFillSprite("Bar_02")
      tNameplate.wndAbsorbBar:SetFullSprite("Bar_02")
      tNameplate.wndAbsorbBar:SetFillSprite("Bar_02")
    end

    tNameplate.wndCastBar:SetMax(100)

    self:InitNameplateVerticalOffset(tNameplate)
    self:InitAnchoring(tNameplate)

    local l_fontH = l_font[l_fontSize].height
    local l_fontGuild = l_fontSize > 1 and l_fontSize - 1 or l_fontSize

    tNameplate.iconArmor:SetFont(l_font[l_fontSize].font)

    tNameplate.containerTop:SetAnchorOffsets(0, 0, 0, l_font[l_fontSize].height * 0.8)
    tNameplate.wndClassRankIcon:SetAnchorOffsets(-l_fontH * 0.9, 0, l_fontH * 0.1, 0)

    tNameplate.wndUnitNameText:SetFont(l_font[l_fontSize].font)
    tNameplate.textUnitLevel:SetFont(l_font[l_fontSize].font)
    tNameplate.textUnitGuild:SetFont(l_font[l_fontGuild].font)
    tNameplate.wndHealthText:SetFont(l_font[l_fontGuild].font)
    -- tNameplate.textUnitGuild:SetAnchorOffsets(0, 0, 0, l_font[l_fontGuild].height * 0.9)

    tNameplate.containerCastBar:SetFont(l_font[l_fontSize].font)
    tNameplate.wndContainerCc:SetFont(l_font[l_fontSize].font)
    tNameplate.containerCastBar:SetAnchorOffsets(0, 0, 0, (l_font[l_fontSize].height * 0.75) + l_zoomSliderH)
    tNameplate.wndContainerCc:SetAnchorOffsets(0, 0, 0, (l_font[l_fontSize].height * 0.75) + l_zoomSliderH)

    tNameplate.wndContainerMain:SetFont(l_font[l_fontSize].font)

    tNameplate.wndCastBar:SetAnchorOffsets(-l_zoomSliderW, (l_zoomSliderH * 0.25), l_zoomSliderW, l_zoomSliderH)
    tNameplate.wndCcBar:SetAnchorOffsets(-l_zoomSliderW, (l_zoomSliderH * 0.25), l_zoomSliderW, l_zoomSliderH)

    local l_armorWidth = tNameplate.iconArmor:GetHeight() / 2
    tNameplate.iconArmor:SetAnchorOffsets(-l_armorWidth, 0, l_armorWidth, 0)
  end

  tNameplate.nMatrixFlags = self:GetCombatStateDependentFlags(tNameplate)

  self:UpdateAnchoring(tNameplate)

  if (not tNameplate.bIsVerticalOffsetUpdated) then
    self:InitNameplateVerticalOffset(tNameplate)
  end

  tNameplate.wndUnitNameText:SetData(unitNameplateOwner)
  tNameplate.wndHealthProgressBar:SetData(unitNameplateOwner)
  tNameplate.bIsOnScreen = tNameplate.wndNameplate:IsOnScreen()

  self:UpdateOpacity(tNameplate)
  tNameplate.wndContainerCc:Show(false)
  tNameplate.wndContainerMain:Show(false)
  tNameplate.containerCastBar:Show(false)
  tNameplate.textUnitGuild:Show(false)
  tNameplate.iconArmor:Show(false)
  tNameplate.wndCleanseFrame:Show(false)

  --  self:UpdateHealthShieldText(tNameplate)

  tNameplate.wndShieldBar:Show(tNameplate.bHasShield)
  local mc_left, mc_top, mc_right, mc_bottom = tNameplate.wndContainerMain:GetAnchorOffsets()
  tNameplate.wndContainerMain:SetAnchorOffsets(mc_left, mc_top, mc_right, tNameplate.bHasShield and mc_top + 14 or mc_top + 11)

  if (_tSettings["ConfigLargeShield"]) then
    tNameplate.wndShieldBar:SetAnchorOffsets(0, 8, 0, 14)
  end

  -- Some NPCs do seem to spawn in combat while they don't have a valid HP value.
  -- We still want to show their health bars
  if (tNameplate.bHasHealth or tNameplate.bIsInCombat) then
    self:UpdateMainBars(tNameplate)
    self:UpdateHealthShieldText(tNameplate)
  else
    tNameplate.wndHealthText:Show(false)

    -- When a PC dyes we also hide the CC status container window
    tNameplate.wndContainerCc:Show(false)
  end

  tNameplate.nNonCombatStateFlags = self:GetNonCombatStateDependentFlags(tNameplate)
  self:UpdateNonCombatStateElements(tNameplate)

  tNameplate.containerIcons:DestroyAllPixies()
  if (tNameplate.bIsPlayer) then
    self:UpdateIconsPc(tNameplate)
  else
    self:UpdateIconsNpc(tNameplate)
  end

  self:UpdateTextNameGuild(tNameplate)
  self:UpdateTextLevel(tNameplate)
  self:UpdateInterruptArmor(tNameplate)
  self:InitClassRankIcon(tNameplate)

  tNameplate.wndNameplate:Show(self:GetNameplateVisibility(tNameplate), true)

  self:UpdateTopContainer(tNameplate)

  tNameplate.wndNameplate:ArrangeChildrenVert(1)

  return tNameplate
end

function TwinkiePlates:UpdateAnchoring(tNameplate, nCodeEnumFloaterLocation)

  local tAnchorUnit = tNameplate.unitNameplateOwner:IsMounted() and tNameplate.unitNameplateOwner:GetUnitMount() or tNameplate.unitNameplateOwner
  local bReposition = false
  local nCodeEnumFloaterLocation = nCodeEnumFloaterLocation

  if (self.nameplacer) then
    if (not nCodeEnumFloaterLocation) then
      local tNameplatePositionSetting = self.nameplacer:GetUnitNameplatePositionSetting(tNameplate.unitNameplateOwner:GetName())

      if (tNameplatePositionSetting and tNameplatePositionSetting["nAnchorId"]) then
        nCodeEnumFloaterLocation = tNameplatePositionSetting["nAnchorId"]
      end
    end


    if (nCodeEnumFloaterLocation) then
      -- Already updated
      if (nCodeEnumFloaterLocation == tNameplate.nAnchorId and tAnchorUnit == tNameplate.wndNameplate:GetUnit()) then
        return
      end

      tNameplate.nAnchorId = nCodeEnumFloaterLocation
      tNameplate.wndNameplate:SetUnit(tAnchorUnit, tNameplate.nAnchorId)
      return
    end
  end


  if (_tSettings["ConfigDynamicVPos"] and not tNameplate.bIsPlayer) then

    local tOverhead = tNameplate.unitNameplateOwner:GetOverheadAnchor()
    if (tOverhead ~= nil) then
      bReposition = not tNameplate.bIsOccluded and tOverhead.y < 25
    end
  end

  nCodeEnumFloaterLocation = bReposition and 0 or 1

  if (nCodeEnumFloaterLocation ~= tNameplate.nAnchorId or tAnchorUnit ~= tNameplate.wndNameplate:GetUnit()) then

    tNameplate.nAnchorId = nCodeEnumFloaterLocation
    tNameplate.wndNameplate:SetUnit(tAnchorUnit, tNameplate.nAnchorId)
  end
end

function TwinkiePlates:InitNameplateVerticalOffset(tNameplate, nInputNameplacerVerticalOffset)
  local nVerticalOffset = _tSettings["SliderVerticalOffset"]
  local nNameplacerVerticalOffset = nInputNameplacerVerticalOffset

  if (self.nameplacer or nNameplacerVerticalOffset) then

    if (not nNameplacerVerticalOffset) then
      local tNameplatePositionSetting = self.nameplacer:GetUnitNameplatePositionSetting(tNameplate.unitNameplateOwner:GetName())

      if (tNameplatePositionSetting) then
        nNameplacerVerticalOffset = tNameplatePositionSetting["nVerticalOffset"]
      end
    end
  end

  if (not nNameplacerVerticalOffset) then
    nNameplacerVerticalOffset = 0
  end

  self:SetNameplateVerticalOffset(tNameplate, nVerticalOffset, nNameplacerVerticalOffset)
  tNameplate.bIsVerticalOffsetUpdated = true
end

function TwinkiePlates:IsInCombat(tNameplate)

  --  Print("TwinkiePlates: _tPvpZones[self.nCurrentZoneId]: " .. tostring(_tPvpZones[self.nCurrentZoneId]))
  if (not self.nCurrentZoneId) then
    Print("TwinkiePlates:IsInCombat; Updating current zone!")
    self:UpdateCurrentZoneInfo(GameLib.GetCurrentZoneId())
  end

  -- PvP zones always on
  if (_tSettings["ConfigAlwaysPvPCombatDetection"] and _tPvpZones[self.nCurrentZoneId]) then
    --    Print("TwinkiePlates:IsInCombat; PvP Zone detected!")
    return true
  end

  -- Player based combat status
  if _tSettings["ConfigPlayerCombatDetection"] then
    -- Print("TwinkiePlates:IsInCombat; Player setting! " .. tostring(_unitPlayer:IsInCombat()))
    return _unitPlayer:IsInCombat()
  end

  return tNameplate.unitNameplateOwner:IsInCombat()
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

  -- Player initialization.
  if (_unitPlayer == nil) then
    _unitPlayer = GameLib.GetPlayerUnit()
    if (_unitPlayer ~= nil) then
      _playerPath = _paths[PlayerPathLib.GetPlayerPathType()]
      if (_unitPlayer:GetTarget() ~= nil) then
        self:OnTargetUnitChanged(_unitPlayer:GetTarget())
      end
      self:CheckMatrixIntegrity()
    end
  end

  -- Addon configuration loading. Maybe can be used to reaload the configuration without reloading the whole UI.
  if (_wndConfigUi == nil and _next(_tSettings) ~= nil) then
    self:InitConfiguration()
  end

  if (_unitPlayer == nil) then return
  end

  ---------------------------------------------------------------------------

  _playerPos = _unitPlayer:GetPosition()
  _bIsPlayerBlinded = _unitPlayer:IsInCCState(Unit.CodeEnumCCState.Blind)

  for flag, flagValue in _pairs(_flags) do
    _flags[flag] = flagValue == 1 and 2 or flagValue
  end

  local nCount = 0
  for id, tNameplate in _pairs(self.tNameplates) do
    nCount = nCount + 1
    local bIsCyclicUpdate = (nCount > _count and nCount < _count + _cycleSize)
    self:UpdateNameplate(tNameplate, bIsCyclicUpdate)
  end

  _count = (_count + _cycleSize > nCount) and 0 or _count + _cycleSize


  if (_tTargetNameplate ~= nil) then
    self:UpdateNameplate(_tTargetNameplate, true)
  end


  if (_wndConfigUi ~= nil and _wndConfigUi:IsVisible()) then
    self:UpdateConfiguration()
  end

  self:UpdateBuffer()

  for flag, flagValue in _pairs(_flags) do
    _flags[flag] = flagValue == 2 and 0 or flagValue
  end
end


function TwinkiePlates:UpdateNameplate(tNameplate, bCyclicUpdate)

  if (bCyclicUpdate) then
    local nDistanceToUnit = self:DistanceToUnit(tNameplate.unitNameplateOwner)
    tNameplate.bIsUnitOutOfRange = nDistanceToUnit > _tSettings["SliderDrawDistance"]
  end

  tNameplate.bIsOnScreen = tNameplate.wndNameplate:IsOnScreen()

  if (tNameplate.bIsOnScreen) then
    tNameplate.eDisposition = self:GetDispositionTo(tNameplate.unitNameplateOwner, _unitPlayer)

    if (tNameplate.bHasHealth
        or (tNameplate.bIsPlayer and self:HasHealth(tNameplate.unitNameplateOwner))
        --  Some units only start having HPs after some events (eg. Essence of Logic)
        or (tNameplate.bForcedHideDisplayToggle and self:HasHealth(tNameplate.unitNameplateOwner))) then
      tNameplate.bHasHealth = true
      tNameplate.nCurrHealth = tNameplate.unitNameplateOwner:GetHealth();
    end

    tNameplate.strUnitCategory = self:GetNameplateCategoryType(tNameplate)
  end

  tNameplate.bIsOccluded = tNameplate.wndNameplate:IsOccluded()
  local bIsNameplateVisible = self:GetNameplateVisibility(tNameplate)
  if (tNameplate.wndNameplate:IsVisible() ~= bIsNameplateVisible) then
    tNameplate.wndNameplate:Show(bIsNameplateVisible, true)
  end

  if (not bIsNameplateVisible) then return
  end

  ---------------------------------------------------------------------------

  -- local bIsInCombat = tNameplate.unitNameplateOwner:IsInCombat()
  local bIsInCombat = self:IsInCombat(tNameplate)

  if (tNameplate.bIsInCombat ~= bIsInCombat) then
    if (tNameplate.unitNameplateOwner == _unitPlayer) then
      Print("Updating combat state")
    end

    tNameplate.bIsInCombat = bIsInCombat

    if (tNameplate.unitNameplateOwner == _unitPlayer) then
      Print("tNameplate.bIsInCombat: " .. tostring(tNameplate.bIsInCombat))
    end

    if (tNameplate.unitNameplateOwner == _unitPlayer) then
      Print("Combat state flags: " .. tostring(tNameplate.nMatrixFlags))
    end
    tNameplate.nMatrixFlags = self:GetCombatStateDependentFlags(tNameplate)

    if (tNameplate.unitNameplateOwner == _unitPlayer) then
      Print("New combat state flags: " .. tostring(tNameplate.nMatrixFlags))
    end
    self:UpdateTextNameGuild(tNameplate)
    self:UpdateTopContainer(tNameplate)
  end

  local bShowCcBar = GetFlag(tNameplate.nMatrixFlags, F_CC_BAR)

  if ((bShowCcBar and (tNameplate.nCcActiveId ~= -1 or tNameplate.nCcNewId ~= -1))
      -- We need to hide the CC bar cause the combat state may have changed
      or (not bShowCcBar and tNameplate.wndContainerCc:IsVisible())) then
    self:UpdateCc(tNameplate)
  end

  if (_flags.opacity == 2) then
    self:UpdateOpacity(tNameplate)
  end

  if (_flags.contacts == 2 and tNameplate.bIsPlayer) then
    self:UpdateIconsPc(tNameplate)
  end

  self:UpdateAnchoring(tNameplate)

  self:UpdateCasting(tNameplate)

  self:UpdateInterruptArmor(tNameplate)

  if (tNameplate.bHasHealth) then
    self:UpdateMainBars(tNameplate)
    self:UpdateHealthShieldText(tNameplate)
  end

  if (bCyclicUpdate) then
    local nNonCombatStateFlags = self:GetNonCombatStateDependentFlags(tNameplate)
    if (tNameplate.nNonCombatStateFlags ~= nNonCombatStateFlags) then
      tNameplate.nNonCombatStateFlags = nNonCombatStateFlags
      self:UpdateNonCombatStateElements(tNameplate)
    end

    if (not tNameplate.bIsPlayer) then
      self:UpdateIconsNpc(tNameplate)
    end
  end

  if (tNameplate.bRearrange) then
    tNameplate.wndNameplate:ArrangeChildrenVert(1)
    tNameplate.bRearrange = false
  end

  if self.perspectivePlates then
    tNameplate.wndNameplate = tNameplate.wndNameplate
    tNameplate.unitOwner = tNameplate.unitNameplateOwner
    self.perspectivePlates:OnRequestedResize(tNameplate)
  end
end


function TwinkiePlates:UpdateMainBars(tNameplate)
  local nHealth = tNameplate.nCurrHealth;
  local nHealthMax = tNameplate.unitNameplateOwner:GetMaxHealth();
  local nShield = tNameplate.unitNameplateOwner:GetShieldCapacity();
  local nShieldMax = tNameplate.unitNameplateOwner:GetShieldCapacityMax();

  local bIsFullHealth = nHealth == nHealthMax;
  local bIsShieldFull = false;
  local bIsHiddenBecauseFull = false;
  local bIsFriendly = tNameplate.eDisposition == Unit.CodeEnumDisposition.Friendly

  if (tNameplate.bHasShield) then
    bIsShieldFull = nShield == nShieldMax;
  end

  if (not tNameplate.bIsTargetNameplate) then
    local bConfigHideWhenFullHealth = _tSettings["ConfigSimpleWhenHealthy"]
    local bConfigHideWhenFullShield = _tSettings["ConfigSimpleWhenFullShield"]

    bIsHiddenBecauseFull =
      -- Check only health
    (bConfigHideWhenFullHealth and bIsFullHealth) and (not bConfigHideWhenFullShield)
        -- Check only shield
        or (bConfigHideWhenFullShield and bIsShieldFull) and (not bConfigHideWhenFullHealth)
        -- Check health and shield
        or (bConfigHideWhenFullHealth and bIsFullHealth) and (bConfigHideWhenFullShield and bIsShieldFull);
  end

  local bConfigShowHealthBar = GetFlag(tNameplate.nMatrixFlags, F_HEALTH)
  local bIsHealthBarVisible = bConfigShowHealthBar and not bIsHiddenBecauseFull and nHealth

  if (tNameplate.wndContainerMain:IsVisible() ~= bIsHealthBarVisible) then
    tNameplate.wndContainerMain:Show(bIsHealthBarVisible)
    tNameplate.bRearrange = true
  end

  if (bIsHealthBarVisible) then

    if (tNameplate.bHasShield) then
      self:SetProgressBar(tNameplate.wndShieldBar, nShield, nShieldMax)
    end

    local strLowHealthCheck = bIsFriendly and "SliderLowHealthFriendly" or "SliderLowHealth"
    if (_tSettings[strLowHealthCheck] ~= 0) then
      local nLowHealthThresholdCutoff = (_tSettings[strLowHealthCheck] / 100)
      local nHealthPercentage = nHealth / nHealthMax
      tNameplate.bIsLowHealth = nHealthPercentage <= nLowHealthThresholdCutoff
    end
    self:SetProgressBar(tNameplate.wndHealthProgressBar, nHealth, nHealthMax)

    tNameplate.bRefreshHealthShieldBar = false

    local nAbsorb = tNameplate.unitNameplateOwner:GetAbsorptionValue();
    if (nAbsorb > 0) then
      if (not tNameplate.wndAbsorbBar:IsVisible()) then
        tNameplate.wndAbsorbBar:Show(true)
      end

      self:SetProgressBar(tNameplate.wndAbsorbBar, nAbsorb, nHealthMax)
    else
      tNameplate.wndAbsorbBar:Show(false)
    end
  end
end

function TwinkiePlates:UpdateTopContainer(tNameplate)
  local bIsLevelVisible = GetFlag(tNameplate.nMatrixFlags, F_LEVEL)
  local bIsClassIconVisible = GetFlag(tNameplate.nMatrixFlags, F_CLASS)
  tNameplate.wndClassRankIcon:SetBGColor(bIsClassIconVisible and "FFFFFFFF" or "00FFFFFF")
  local l_width = tNameplate.levelWidth + tNameplate.wndUnitNameText:GetWidth()
  local l_ratio = tNameplate.levelWidth / l_width
  local l_middle = (l_width * l_ratio) - (l_width / 2)

  if (not bIsLevelVisible) then
    local l_extents = tNameplate.wndUnitNameText:GetWidth() / 2
    tNameplate.textUnitLevel:SetTextColor("00FFFFFF")
    tNameplate.textUnitLevel:SetAnchorOffsets(-l_extents - 5, 0, -l_extents, 1)
    tNameplate.wndUnitNameText:SetAnchorOffsets(-l_extents, 0, l_extents, 1)
  else
    tNameplate.textUnitLevel:SetTextColor("FFFFFFFF")
    tNameplate.textUnitLevel:SetAnchorOffsets(-(l_width / 2), 0, l_middle, 1)
    tNameplate.wndUnitNameText:SetAnchorOffsets(l_middle, 0, (l_width / 2), 1)
  end
end

function TwinkiePlates:UpdateHealthShieldText(tNameplate)
  local bHealthTextEnabled = GetFlag(tNameplate.nMatrixFlags, F_HEALTH_TEXT) and tNameplate.bHasHealth

  if (tNameplate.wndHealthText:IsVisible() ~= bHealthTextEnabled) then
    tNameplate.wndHealthText:Show(bHealthTextEnabled)
    tNameplate.bRearrange = true
  end

  if (bHealthTextEnabled) then

    local nHealth = tNameplate.nCurrHealth;
    local nHealthMax = tNameplate.unitNameplateOwner:GetMaxHealth();
    local nShield = tNameplate.unitNameplateOwner:GetShieldCapacity();
    local nShieldMax = tNameplate.unitNameplateOwner:GetShieldCapacityMax();

    local strShieldText = ""
    local strHealthText = self:GetNumber(nHealth, nHealthMax)

    if (tNameplate.bHasShield and nShield ~= 0) then
      strShieldText = " (" .. self:GetNumber(nShield, nShieldMax) .. ")"
    end

    tNameplate.wndHealthText:SetText(strHealthText .. strShieldText)

    --    self:UpdateMainContainerHeightWithHealthText(tNameplate)
    --  else
    --    self:UpdateMainContainerHeightWithoutHealthText(tNameplate)
  end

  --  tNameplate.bRearrange = true
end

function TwinkiePlates:UpdateNonCombatStateElements(tNameplate)
  local bPvpFlaggedSettingEnabled = _unitPlayer:IsPvpFlagged() and GetFlag(tNameplate.nNonCombatStateFlags, F_PVP)
  local bNoAggroSettingEnabled = GetFlag(tNameplate.nNonCombatStateFlags, F_AGGRO)
  local bIsShowCleansableSettingEnabled = GetFlag(tNameplate.nNonCombatStateFlags, F_CLEANSE)
  local bIsLowHpSettingEnabled = GetFlag(tNameplate.nNonCombatStateFlags, F_LOW_HP)


  local colorNameplateText = _tFromSettingToColor[tNameplate.strUnitCategory]
  local colorNameplateBar = _dispColor[tNameplate.eDisposition]

  local bHostile = tNameplate.eDisposition == Unit.CodeEnumDisposition.Hostile
  local bIsFriendly = tNameplate.eDisposition == Unit.CodeEnumDisposition.Friendly

  tNameplate.color = colorNameplateText

  if (tNameplate.bIsPlayer or tNameplate.bPet) then
    if (not bPvpFlaggedSettingEnabled and bHostile) then
      colorNameplateText = _dispColor[Unit.CodeEnumDisposition.Neutral]
      colorNameplateBar = _dispColor[Unit.CodeEnumDisposition.Neutral]
      tNameplate.color = colorNameplateText
    end

    if (bIsShowCleansableSettingEnabled and bIsFriendly --[[ and not tNameplate.wndCleanseFrame:IsVisible()]]) then
      tNameplate.wndCleanseFrame:Show(true)
      tNameplate.wndCleanseFrame:SetBGColor(_tFromSettingToColor["Cleanse"])
      --    elseif (tNameplate.wndCleanseFrame:IsVisible()) then
    else
      tNameplate.wndCleanseFrame:Show(false)
    end
  else
    if (bNoAggroSettingEnabled and bHostile) then
      colorNameplateText = _tFromSettingToColor["NoAggro"]
    end
    if (tNameplate.wndCleanseFrame:IsVisible()) then
      tNameplate.wndCleanseFrame:Show(false)
    end
  end

  if (bIsLowHpSettingEnabled) then
    colorNameplateBar = bIsFriendly and _tFromSettingToColor["LowHpFriendly"] or _tFromSettingToColor["LowHpNotFriendly"]
  end

  tNameplate.wndUnitNameText:SetTextColor(colorNameplateText)
  tNameplate.textUnitGuild:SetTextColor(colorNameplateText)
  tNameplate.wndHealthProgressBar:SetBarColor(colorNameplateBar)

  if (tNameplate.bIsTargetNameplate and tNameplate.targetMark ~= nil) then
    tNameplate.targetMark:SetBGColor(tNameplate.color)
  end
end


function TwinkiePlates:GetCombatStateDependentFlags(tNameplate)
  local nFlags = 0
  local bIsInCombat = tNameplate.bIsInCombat
  local strUnitCategoryType = tNameplate.strUnitCategory

  if (tNameplate.unitNameplateOwner == _unitPlayer) then
    Print("GetCombatStateDependentFlags;  tNameplate.bIsIncombat:" .. tostring(tNameplate.bIsInCombat))
  end

  for strUiElement in _pairs(_tUiElements) do

    local nMatrixConfigurationCellValue = _tSettings[_tUiElements[strUiElement][strUnitCategoryType]]

    if ((_type(nMatrixConfigurationCellValue) ~= "number")
        or (nMatrixConfigurationCellValue == N_ALWAYS_ENABLED)
        or (nMatrixConfigurationCellValue == N_ENABLED_IN_COMBAT and bIsInCombat)
        or (nMatrixConfigurationCellValue == N_ALWAYS_OUT_OF_COMBAT and not bIsInCombat)) then

      nFlags = SetFlag(nFlags, _tUiElementToFlag[strUiElement])
    end
  end

  if (not tNameplate.bHasHealth) then
    nFlags = ClearFlag(nFlags, F_HEALTH)
  end

  return nFlags
end

function TwinkiePlates:GetNonCombatStateDependentFlags(tNameplate)
  if (_unitPlayer == nil) then return
  end

  local nFlags = SetFlag(0, tNameplate.eDisposition)
  local bIsFriendly = tNameplate.eDisposition == Unit.CodeEnumDisposition.Friendly

  if (tNameplate.bIsInGroup) then nFlags = SetFlag(nFlags, F_GROUP)
  end
  if (tNameplate.bIsPvpFlagged) then nFlags = SetFlag(nFlags, F_PVP)
  end
  if (tNameplate.bIsLowHealth) then nFlags = SetFlag(nFlags, F_LOW_HP)
  end

  if (_tSettings["ConfigAggroIndication"]) then
    if (tNameplate.bIsInCombat and not tNameplate.bIsPlayer and tNameplate.unitNameplateOwner:GetTarget() ~= _unitPlayer) then
      nFlags = SetFlag(nFlags, F_AGGRO)
    end
  end

  if (_tSettings["ConfigCleanseIndicator"] and bIsFriendly) then
    local tUnitDebuffs = tNameplate.unitNameplateOwner:GetBuffs()["arHarmful"]
    for i = 1, #tUnitDebuffs do
      if (tUnitDebuffs[i]["splEffect"]:GetClass() == Spell.CodeEnumSpellClass.DebuffDispellable) then
        nFlags = SetFlag(nFlags, F_CLEANSE)
      end
    end
  end

  return nFlags
end

function TwinkiePlates:GetDispositionTo(unitSubject, unitObject)

  if (not unitSubject or not unitObject) then return Unit.CodeEnumDisposition.Unknown
  end

  if (self:IsPet(unitSubject) and unitSubject:GetUnitOwner()) then
    unitSubject = unitSubject:GetUnitOwner()
  end

  return unitSubject:GetDispositionTo(unitObject)
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
  if (p_current == nil or p_max == nil) then return ""
  end
  if (_tSettings["ConfigHealthPct"]) then
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
  local l_slider = _wndConfigUi:FindChild(p_name)
  if (l_slider ~= nil) then
    local l_sliderVal = l_slider:FindChild("SliderBar"):GetValue()
    l_slider:SetProgress((l_sliderVal - p_min) / (p_max - p_min))
    l_slider:FindChild("TextValue"):SetText(l_sliderVal .. (p_labelSuffix or ""))
  end
end

function TwinkiePlates:OnTargetUnitChanged(unitTarget)
  if (not _unitPlayer) then return
  end

  if (unitTarget and self.tNameplates[unitTarget:GetId()]) then
    self.tNameplates[unitTarget:GetId()].wndNameplate:Show(false, true)
  end

  if (unitTarget ~= nil) then

    if (_tTargetNameplate == nil) then
      _tTargetNameplate = self:InitNameplate(unitTarget, nil, true)

      if (_tSettings["ConfigLegacyTargeting"]) then
        self:UpdateLegacyTargetPixie()
        _tTargetNameplate.wndNameplate:AddPixie(_tTargetPixie)
      else
        _tTargetNameplate.targetMark = Apollo.LoadForm(self.xmlDoc, "Target Indicator", _tTargetNameplate.containerTop, self)
        local nTargetMarkVerticalOffset = _tTargetNameplate.targetMark:GetHeight() / 2
        _tTargetNameplate.targetMark:SetAnchorOffsets(-nTargetMarkVerticalOffset, 0, nTargetMarkVerticalOffset, 0)
        _tTargetNameplate.targetMark:SetBGColor(_tTargetNameplate.color)
      end
    else
      -- Target nameplate is never reset because it's not attached to any specific unit thus is never affected by OnUnitDestroyed event
      _tTargetNameplate.bIsVerticalOffsetUpdated = false

      _tTargetNameplate = self:InitNameplate(unitTarget, _tTargetNameplate, true)

      if (_tSettings["ConfigLegacyTargeting"]) then
        self:UpdateLegacyTargetPixie()
        _tTargetNameplate.wndNameplate:UpdatePixie(1, _tTargetPixie)
      end
    end

    -- We need to call this otherwise hidden health text configuration may not update correctly
    --    self:UpdateHealthShieldText(_tTargetNameplate)
  end

  _flags.opacity = 1
  _tTargetNameplate.wndNameplate:Show(unitTarget ~= nil, true)
end

function TwinkiePlates:UpdateLegacyTargetPixie()
  local nWidth = _tTargetNameplate.wndUnitNameText:GetWidth()
  local nHeight = _tTargetNameplate.wndUnitNameText:GetHeight()

  if (_tTargetNameplate.textUnitLevel:IsVisible()) then nWidth = nWidth + _tTargetNameplate.textUnitLevel:GetWidth()
  end
  if (_tTargetNameplate.textUnitGuild:IsVisible()) then nHeight = nHeight + _tTargetNameplate.textUnitGuild:GetHeight()
  end
  if (_tTargetNameplate.wndContainerMain:IsVisible()) then nHeight = nHeight + _tTargetNameplate.wndContainerMain:GetHeight()
  end

  nHeight = (nHeight / 2) + 30
  nWidth = (nWidth / 2) + 50

  nWidth = nWidth < 45 and 45 or (nWidth > 200 and 200 or nWidth)
  nHeight = nHeight < 45 and 45 or (nHeight > 75 and 75 or nHeight)

  _tTargetPixie.loc.nOffsets[1] = -nWidth
  _tTargetPixie.loc.nOffsets[2] = -nHeight
  _tTargetPixie.loc.nOffsets[3] = nWidth
  _tTargetPixie.loc.nOffsets[4] = nHeight
end

function TwinkiePlates:OnTextBubble(unitNameplateOwner, p_text)
  if (_unitPlayer == nil) then return
  end

  local tNameplate = self.tNameplates[unitNameplateOwner:GetId()]
  if (tNameplate ~= nil) then
    self:ProcessTextBubble(tNameplate, p_text)
  end
end

function TwinkiePlates:ProcessTextBubble(p_nameplate, p_text)
  if (GetFlag(p_nameplate.nMatrixFlags, F_BUBBLE)) then
    self:UpdateOpacity(p_nameplate, (p_text ~= nil))
  end
end

function TwinkiePlates:OnPlayerMainTextChanged()
  if (_unitPlayer == nil) then return
  end
  self:OnUnitMainTextChanged(_unitPlayer)
end

function TwinkiePlates:OnNameplatePositionSettingChanged(strUnitName, tNameplatePositionSetting)
  --  Print("[TwinkiePlates] OnNameplatePositionSettingChanged; strUnitName: " .. strUnitName .. "; tNameplatePositionSetting: " .. table.tostring(tNameplatePositionSetting))

  if (not tNameplatePositionSetting or (not tNameplatePositionSetting["nAnchorId"] and not tNameplatePositionSetting["nVerticalOffset"])) then return
  end

  if (_tTargetNameplate and _tTargetNameplate.unitNameplateOwner and _tTargetNameplate.unitNameplateOwner:GetName() == strUnitName) then
    if (tNameplatePositionSetting["nAnchorId"]) then
      self:UpdateAnchoring(_tTargetNameplate, tNameplatePositionSetting["nAnchorId"])
    end
    if (tNameplatePositionSetting["nVerticalOffset"]) then
      self:InitNameplateVerticalOffset(_tTargetNameplate, tNameplatePositionSetting["nVerticalOffset"])
    end
  end

  for _, tNameplate in _pairs(self.tNameplates) do
    if (tNameplate.unitNameplateOwner:GetName() == strUnitName) then

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
  if (unitNameplateOwner == nil) then return
  end
  local tNameplate = self.tNameplates[unitNameplateOwner:GetId()]
  if (tNameplate ~= nil) then
    self:UpdateTextNameGuild(tNameplate)
    self:UpdateTopContainer(tNameplate)
  end
  if (_tTargetNameplate ~= nil and _unitPlayer:GetTarget() == unitNameplateOwner) then
    self:UpdateTextNameGuild(_tTargetNameplate)
    self:UpdateTopContainer(_tTargetNameplate)
  end
end

function TwinkiePlates:OnUnitLevelChanged(unitNameplateOwner)
  if (unitNameplateOwner == nil) then return
  end
  local l_nameplate = self.tNameplates[unitNameplateOwner:GetId()]
  if (l_nameplate ~= nil) then
    self:UpdateTextLevel(l_nameplate)
    self:UpdateTopContainer(l_nameplate)
  end
  if (_tTargetNameplate ~= nil and _unitPlayer:GetTarget() == unitNameplateOwner) then
    self:UpdateTextLevel(_tTargetNameplate)
    self:UpdateTopContainer(_tTargetNameplate)
  end
end

function TwinkiePlates:OnUnitActivationTypeChanged(unitNameplateOwner)
  if (_unitPlayer == nil) then return
  end

  local tNameplate = self.tNameplates[unitNameplateOwner:GetId()]
  local bHasActivationState = self:HasActivationState(unitNameplateOwner)

  if (tNameplate ~= nil) then
    tNameplate.bHasActivationState = bHasActivationState
  elseif (bHasActivationState) then
    self:AllocateNameplate(unitNameplateOwner)
  end
  if (_tTargetNameplate ~= nil and _unitPlayer:GetTarget() == unitNameplateOwner) then
    _tTargetNameplate.bHasActivationState = bHasActivationState
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
    _tSettings["ConfigOcclusionCulling"] = not _tSettings["ConfigOcclusionCulling"]
    local l_occlusionString = _tSettings["ConfigOcclusionCulling"] and "<Enabled>" or "<Disabled>"
    Print("[nPrimeNameplates] Occlusion culling " .. l_occlusionString)
  elseif ((strArg == nil or strArg == "") and _wndConfigUi ~= nil) then
    _wndConfigUi:Show(not _wndConfigUi:IsVisible(), true)
  end
end

function TwinkiePlates:OnCombatLogDeath(tLogInfo)
  Print("tLogInfo: " .. tLogInfo.unitCaster:GetName())
end

function TwinkiePlates:OnCombatLogResurrect(tLogInfo)
  Print("tLogInfo: " .. tLogInfo.unitCaster:GetName())
end

-- Called from form
function TwinkiePlates:OnConfigButton(wndHandler, wndControl, eMouseButton)
  local strHandlerName = wndHandler:GetName()

  if (strHandlerName == "ButtonClose") then
    _wndConfigUi:Show(false)
  elseif (strHandlerName == "ButtonApply") then
    RequestReloadUI()
  elseif (string.starts(strHandlerName, "Config")) then
    _tSettings[strHandlerName] = wndHandler:IsChecked()
  end
end

-- Called from form
function TwinkiePlates:OnSliderBarChanged(p1, wndHandler, nValue, nOldValue)
  local strParentHandlerName = wndHandler:GetParent():GetName()
  if (_tSettings[strParentHandlerName] ~= nil) then
    _tSettings[strParentHandlerName] = nValue
  end
end

-- Called from form
function TwinkiePlates:OnMatrixClick(p_wndHandler, wndCtrl, nClick)
  if (nClick ~= 0 and nClick ~= 1) then return
  end

  local l_parent = p_wndHandler:GetParent():GetParent():GetName()
  local l_key = l_parent .. p_wndHandler:GetName()
  local l_valueOld = _tSettings[l_key]
  local l_xor = bit32.bxor(bit32.extract(l_valueOld, nClick), 1)
  local l_valueNew = bit32.replace(l_valueOld, l_xor, nClick)

  p_wndHandler:SetTooltip(self:GetMatrixTooltip(l_valueNew))

  _tSettings[l_key] = l_valueNew
  p_wndHandler:SetSprite(_matrixButtonSprites[l_valueNew])
end

function TwinkiePlates:OnInterfaceMenuListHasLoaded()
  Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "TwinkiePlates", { "ShowTwinkiePlatesConfigurationWnd", "", "" })
end

function TwinkiePlates:CheckMatrixIntegrity()
  if (_type(_tSettings["ConfigBarIncrements"]) ~= "boolean") then _tSettings["ConfigBarIncrements"] = true
  end
  if (_type(_tSettings["ConfigHealthText"]) ~= "boolean") then _tSettings["ConfigHealthText"] = true
  end
  if (_type(_tSettings["ConfigShowHarvest"]) ~= "boolean") then _tSettings["ConfigShowHarvest"] = true
  end
  if (_type(_tSettings["ConfigOcclusionCulling"]) ~= "boolean") then _tSettings["ConfigOcclusionCulling"] = true
  end
  if (_type(_tSettings["ConfigFadeNonTargeted"]) ~= "boolean") then _tSettings["ConfigFadeNonTargeted"] = true
  end
  if (_type(_tSettings["ConfigDynamicVPos"]) ~= "boolean") then _tSettings["ConfigDynamicVPos"] = true
  end

  if (_type(_tSettings["ConfigLargeShield"]) ~= "boolean") then _tSettings["ConfigLargeShield"] = false
  end
  if (_type(_tSettings["ConfigHealthPct"]) ~= "boolean") then _tSettings["ConfigHealthPct"] = false
  end
  if (_type(_tSettings["ConfigSimpleWhenHealthy"]) ~= "boolean") then _tSettings["ConfigSimpleWhenHealthy"] = false
  end
  if (_type(_tSettings["ConfigSimpleWhenFullShield"]) ~= "boolean") then _tSettings["ConfigSimpleWhenFullShield"] = false
  end
  if (_type(_tSettings["ConfigAggroIndication"]) ~= "boolean") then _tSettings["ConfigAggroIndication"] = false
  end
  if (_type(_tSettings["ConfigHideAffiliations"]) ~= "boolean") then _tSettings["ConfigHideAffiliations"] = false
  end
  if (_type(_tSettings["ConfigAlternativeFont"]) ~= "boolean") then _tSettings["ConfigAlternativeFont"] = false
  end
  if (_type(_tSettings["ConfigLegacyTargeting"]) ~= "boolean") then _tSettings["ConfigLegacyTargeting"] = false
  end
  if (_type(_tSettings["ConfigCleanseIndicator"]) ~= "boolean") then _tSettings["ConfigCleanseIndicator"] = false
  end

  if (_type(_tSettings["SliderDrawDistance"]) ~= "number") then _tSettings["SliderDrawDistance"] = 100
  end
  if (_type(_tSettings["SliderLowHealth"]) ~= "number") then _tSettings["SliderLowHealth"] = 30
  end
  if (_type(_tSettings["SliderLowHealthFriendly"]) ~= "number") then _tSettings["SliderLowHealthFriendly"] = 0
  end
  if (_type(_tSettings["SliderVerticalOffset"]) ~= "number") then _tSettings["SliderVerticalOffset"] = 20
  end
  if (_type(_tSettings["SliderBarScale"]) ~= "number") then _tSettings["SliderBarScale"] = 100
  end
  if (_type(_tSettings["SliderFontSize"]) ~= "number") then _tSettings["SliderFontSize"] = 1
  end

  --[[  for i, category in _ipairs(_tUiElements) do
      for j, filter in _ipairs(_tUnitCategories) do
        local l_key = category .. filter
        if (type(_tSettings[l_key]) ~= "number") then
          _tSettings[l_key] = 3
        end
      end
    end]]

  for _, tUiElement in _pairs(_tUiElements) do
    for _, strUiElementCategory in _pairs(tUiElement) do

      if (_type(_tSettings[strUiElementCategory]) ~= "number") then
        _tSettings[strUiElementCategory] = 3
      end
    end
  end
end

function TwinkiePlates:InitConfiguration()
  _wndConfigUi = Apollo.LoadForm(self.xmlDoc, "Configuration", nil, self)
  _wndConfigUi:Show(false)

  local wndConfigurationMatrix = _wndConfigUi:FindChild("MatrixConfiguration")

  -- Matrix layout
  self:DistributeMatrixColumns(wndConfigurationMatrix:FindChild("RowNames"))
  for strUiElementName, tUiElement in _pairs(_tUiElements) do
    local wndCategoryContainer = wndConfigurationMatrix:FindChild(strUiElementName)
    self:DistributeMatrixColumns(wndCategoryContainer, strUiElementName)
  end

  for k, v in _pairs(_tSettings) do
    if (string.starts(k, "Config")) then
      local l_button = _wndConfigUi:FindChild(k)
      if (l_button ~= nil) then
        l_button:SetCheck(v)
      end
    elseif (string.starts(k, "Slider")) then
      local l_slider = _wndConfigUi:FindChild(k)
      if (l_slider ~= nil) then
        l_slider:FindChild("SliderBar"):SetValue(v)
      end
    end
  end
end

function TwinkiePlates:DistributeMatrixColumns(wndElementRow, p_categoryName)
  -- local l_columns = (1 / #_tUnitCategories)
  for i, filter in _ipairs(_tUnitCategories) do
    -- local l_left = l_columns * (i - 1)
    -- local l_right = l_columns * i
    local l_button = wndElementRow:FindChild(filter)

    -- l_button:SetAnchorPoints(l_left, 0, l_right, 1)
    -- l_button:SetAnchorOffsets(1, 1, -1, -1)

    if (p_categoryName ~= nil) then
      local l_value = _tSettings[p_categoryName .. filter] or 0
      l_button:SetSprite(_matrixButtonSprites[l_value])
      l_button:SetStyle("IgnoreTooltipDelay", true)
      l_button:SetTooltip(self:GetMatrixTooltip(l_value))
    end
  end
end

function TwinkiePlates:GetMatrixTooltip(nValue)
  if (nValue == 0) then return "Never enabled"
  end
  if (nValue == 1) then return "Enabled in combat"
  end
  if (nValue == 2) then return "Enabled out of combat"
  end
  if (nValue == 3) then return "Always enabled"
  end
  return "?"
end

function TwinkiePlates:DistanceToUnit(unitNameplateOwner)
  if (unitNameplateOwner == nil) then return 0
  end

  local l_pos = unitNameplateOwner:GetPosition()
  if (l_pos == nil) then return 0
  end
  if (l_pos.x == 0) then return 0
  end

  local deltaPos = Vector3.New(l_pos.x - _playerPos.x, l_pos.y - _playerPos.y, l_pos.z - _playerPos.z)
  return deltaPos:Length()
end

-------------------------------------------------------------------------------
function TwinkiePlates:FormatNumber(p_number)
  if (p_number == nil) then return ""
  end
  local l_result = p_number
  if p_number < 1000 then l_result = p_number
  elseif p_number < 1000000 then l_result = _weaselStr("$1f1k", p_number / 1000)
  elseif p_number < 1000000000 then l_result = _weaselStr("$1f1m", p_number / 1000000)
  elseif p_number < 1000000000000 then l_result = _weaselStr("$1f1b", p_number / 1000000)
  end
  return l_result
end

function TwinkiePlates:UpdateTextNameGuild(tNameplate)
  local bShowTitle = GetFlag(tNameplate.nMatrixFlags, F_TITLE)
  local bShowGuild = GetFlag(tNameplate.nMatrixFlags, F_GUILD)
  local bHideAffiliation = _tSettings["ConfigHideAffiliations"]
  local unitNameplateOwner = tNameplate.unitNameplateOwner
  local strUnitName = bShowTitle and unitNameplateOwner:GetTitleOrName() or unitNameplateOwner:GetName()
  local strGuildName
  local nFontSize = _tSettings["SliderFontSize"]
  local tFontSettings = _tSettings["ConfigAlternativeFont"] and _fontSecondary or _fontPrimary
  local nWidth = _textWidth(tFontSettings[nFontSize].font, strUnitName .. " ")

  --[[
    if (tNameplate.unitNameplateOwner == _unitPlayer) then
      Print("Updating title/guild text: " .. tostring(bShowTitle) .. " " .. tostring(bShowGuild))
    end
  ]]

  if (bShowGuild and tNameplate.bIsPlayer) then
    strGuildName = unitNameplateOwner:GetGuildName() and ("<" .. unitNameplateOwner:GetGuildName() .. ">") or nil
  elseif (bShowGuild and not bHideAffiliation and not tNameplate.bIsPlayer) then
    strGuildName = unitNameplateOwner:GetAffiliationName() or nil
  end

  tNameplate.wndUnitNameText:SetText(strUnitName)
  tNameplate.wndUnitNameText:SetAnchorOffsets(0, 0, nWidth, 0)


  local l_hasGuild = strGuildName ~= nil and (_strLen(strGuildName) > 0)
  if (tNameplate.textUnitGuild:IsVisible() ~= l_hasGuild) then
    tNameplate.textUnitGuild:Show(l_hasGuild)
    tNameplate.bRearrange = true
  end
  if (l_hasGuild) then
    tNameplate.textUnitGuild:SetTextRaw(strGuildName)
  end
end

function TwinkiePlates:UpdateTextLevel(p_nameplate)
  local l_level = p_nameplate.unitNameplateOwner:GetLevel()
  if (l_level ~= nil) then
    l_level = --[[ "Lv" .. --]] l_level .. "   "
    local l_fontSize = _tSettings["SliderFontSize"]
    local l_font = _tSettings["ConfigAlternativeFont"] and _fontSecondary or _fontPrimary
    local l_width = _textWidth(l_font[l_fontSize].font, l_level)
    p_nameplate.levelWidth = l_width
    p_nameplate.textUnitLevel:SetText(l_level)
  else
    p_nameplate.levelWidth = 1
    p_nameplate.textUnitLevel:SetText("")
  end
end

function TwinkiePlates:InitClassRankIcon(tNameplate)
  local tIconMappingTable = tNameplate.bIsPlayer and _tFromPlayerClassToIcon or _tFromNpcRankToIcon
  local strIconRef = tIconMappingTable[tNameplate.unitClassID]
  tNameplate.wndClassRankIcon:Show(strIconRef ~= nil)
  tNameplate.wndClassRankIcon:SetSprite(strIconRef ~= nil and strIconRef or "")
end

--[[
function TwinkiePlates:OnCharacterFlagsUpdated(strRandomVar)

  Print("OnCharacterFlagsUpdated; strRandomVar: " .. tostring(strRandomVar))
end
]]

function TwinkiePlates:OnCCStateApplied(nCcId, unitNameplateOwner)

  if (_ccWhiteList[nCcId] == nil) then
    return
  end

  local l_nameplate = self.tNameplates[unitNameplateOwner:GetId()]


  if (l_nameplate ~= nil) then
    if (GetFlag(l_nameplate.nMatrixFlags, F_CC_BAR)) then
      self:RegisterCc(l_nameplate, nCcId)
    end
  end

  if (_tTargetNameplate ~= nil and _tTargetNameplate.unitNameplateOwner == unitNameplateOwner) then
    if (GetFlag(_tTargetNameplate.nMatrixFlags, F_CC_BAR)) then
      self:RegisterCc(_tTargetNameplate, nCcId)
    end
  end
end

function TwinkiePlates:RegisterCc(tNameplate, nCcId)

  local strCcNewName = _ccWhiteList[nCcId]
  if (strCcNewName) then

    -- Register the new CC only if there no MoO already ongoning. The CC duration check is performed in the UpdateCc method
    if (tNameplate.nCcNewId == -1 or (tNameplate.nCcNewId ~= -1 and tNameplate.nCcActiveId ~= Unit.CodeEnumCCState.Vulnerability and tNameplate.nCcNewId ~= Unit.CodeEnumCCState.Vulnerability)) then
      tNameplate.nCcNewId = nCcId
    end
  end
end

function TwinkiePlates:UpdateCc(tNameplate)

  local nCcNewDuration = tNameplate.nCcNewId >= 0 and tNameplate.unitNameplateOwner:GetCCStateTimeRemaining(tNameplate.nCcNewId) or 0
  tNameplate.nCcDuration = tNameplate.nCcActiveId >= 0 and tNameplate.unitNameplateOwner:GetCCStateTimeRemaining(tNameplate.nCcActiveId) or 0

  if (nCcNewDuration <= 0 and tNameplate.nCcNewId ~= -1) then
    tNameplate.nCcNewId = -1
  end

  if (tNameplate.nCcDuration <= 0 and tNameplate.nCcActiveId ~= -1) then
    tNameplate.nCcActiveId = -1
  end

  local strCcActiveName = _ccWhiteList[tNameplate.nCcActiveId]
  local strCcNewName = _ccWhiteList[tNameplate.nCcNewId]

  local bShowCcBar = (strCcActiveName and tNameplate.nCcDuration > 0) or (strCcNewName and nCcNewDuration > 0)

  if (tNameplate.wndContainerCc:IsVisible() ~= bShowCcBar) then

    tNameplate.wndContainerCc:Show(bShowCcBar)
    tNameplate.bRearrange = true
  end

  if (bShowCcBar) then

    local bUpdateCc = not tNameplate.nCcDurationMax
        or tNameplate.nCcActiveId == -1
        or (tNameplate.nCcNewId == Unit.CodeEnumCCState.Vulnerability)
        or ((nCcNewDuration and nCcNewDuration > tNameplate.nCcDuration)
        and tNameplate.nCcActiveId ~= Unit.CodeEnumCCState.Vulnerability)

    -- New CC has a longer duration than the previous one (if any) and the current CC state is not a MoO
    if (bUpdateCc) then
      tNameplate.nCcDurationMax = nCcNewDuration
      tNameplate.nCcDuration = nCcNewDuration
      tNameplate.nCcActiveId = tNameplate.nCcNewId
      tNameplate.nCcNewId = -1

      tNameplate.wndContainerCc:SetText(strCcNewName)
      tNameplate.wndCcBar:SetMax(nCcNewDuration)
    end

    -- Update the CC progress bar
    tNameplate.wndCcBar:SetProgress(tNameplate.nCcDuration)
  end
end

function TwinkiePlates:UpdateCasting(tNameplate)
  local bCastingBarConfiguration = GetFlag(tNameplate.nMatrixFlags, F_CASTING_BAR)


  local bShowCastBar = tNameplate.unitNameplateOwner:ShouldShowCastBar() and bCastingBarConfiguration
  if (tNameplate.containerCastBar:IsVisible() ~= bShowCastBar) then

    tNameplate.containerCastBar:Show(bShowCastBar)

    tNameplate.bRearrange = true
  end
  if (bShowCastBar) then
    local bIsCcVulnerable = tNameplate.unitNameplateOwner:GetInterruptArmorMax() >= 0
    -- tNameplate.wndNameplate:ToFront()
    tNameplate.wndCastBar:SetBarColor(bIsCcVulnerable and "xkcdDustyOrange" or _color("ff990000"))
    tNameplate.wndCastBar:SetProgress(tNameplate.unitNameplateOwner:GetCastTotalPercent())
    tNameplate.containerCastBar:SetText(tNameplate.unitNameplateOwner:GetCastName())
  end
end

function TwinkiePlates:UpdateInterruptArmor(tNameplate)
  local nArmorMax = tNameplate.unitNameplateOwner:GetInterruptArmorMax()
  local nCurrentInterruptArmor = tNameplate.unitNameplateOwner:GetInterruptArmorValue()
  local bShowArmor = GetFlag(tNameplate.nMatrixFlags, F_ARMOR) and --[[nArmorMax]] (nCurrentInterruptArmor ~= 0 or nArmorMax == -1)

  if (tNameplate.iconArmor:IsVisible() ~= bShowArmor) then
    tNameplate.iconArmor:Show(bShowArmor)
  end

  if (not bShowArmor) then
    tNameplate.prevArmor = 0
    return
  end

  if (nCurrentInterruptArmor --[[nArmorMax]] > 0) then
    -- p_nameplate.iconArmor:SetText(p_nameplate.unitNameplateOwner:GetInterruptArmorValue())
    tNameplate.iconArmor:SetText(nCurrentInterruptArmor)
  end

  if (tNameplate.prevArmor ~= nArmorMax) then
    tNameplate.prevArmor = nArmorMax
    if (nArmorMax == -1) then
      tNameplate.iconArmor:SetText("")
      tNameplate.iconArmor:SetSprite("NPrimeNameplates_Sprites:IconArmor_02")
    elseif (nArmorMax > 0) then
      tNameplate.iconArmor:SetSprite("NPrimeNameplates_Sprites:IconArmor")
    end
  end
end

function TwinkiePlates:UpdateOpacity(tNameplate, bHasTextBubble)
  if (tNameplate.bIsTargetNameplate) then return
  end
  bHasTextBubble = bHasTextBubble or false

  if (bHasTextBubble) then
    tNameplate.wndNameplate:SetOpacity(0.25, 10)
  else
    local l_opacity = 1
    if (_tSettings["ConfigFadeNonTargeted"] and _unitPlayer:GetTarget() ~= nil) then
      l_opacity = 0.6
    end
    tNameplate.wndNameplate:SetOpacity(l_opacity, 10)
  end
end

function TwinkiePlates:UpdateIconsNpc(tNameplate)
  local nFlags = 0
  local nIcons = 0

  local tRewardInfo = tNameplate.unitNameplateOwner:GetRewardInfo()
  if (tRewardInfo ~= nil and _next(tRewardInfo) ~= nil) then
    for i = 1, #tRewardInfo do
      local strType = tRewardInfo[i].strType
      if (strType == _playerPath) then
        nIcons = nIcons + 1
        nFlags = SetFlag(nFlags, F_PATH)
      elseif (strType == "Quest") then
        nIcons = nIcons + 1
        nFlags = SetFlag(nFlags, F_QUEST)
      elseif (strType == "Challenge") then
        local l_ID = tRewardInfo[i].idChallenge
        local l_challenge = self.challenges[l_ID]
        if (l_challenge ~= nil and l_challenge:IsActivated()) then
          nIcons = nIcons + 1
          nFlags = SetFlag(nFlags, F_CHALLENGE)
        end
      end
    end
  end

  tNameplate.bIsObjective = nFlags > 0

  if (nFlags ~= tNameplate.iconFlags) then
    tNameplate.iconFlags = nFlags
    tNameplate.containerIcons:DestroyAllPixies()

    local l_height = tNameplate.containerIcons:GetHeight()
    local l_width = 1 / nIcons
    local l_iconN = 0

    tNameplate.containerIcons:SetAnchorOffsets(0, 0, nIcons * l_height, 0)

    if (GetFlag(nFlags, F_CHALLENGE)) then
      self:AddIcon(tNameplate, "IconChallenge", l_iconN, l_width)
      l_iconN = l_iconN + 1
    end

    if (GetFlag(nFlags, F_PATH)) then
      self:AddIcon(tNameplate, "IconPath", l_iconN, l_width)
      l_iconN = l_iconN + 1
    end

    if (GetFlag(nFlags, F_QUEST)) then
      self:AddIcon(tNameplate, "IconQuest", l_iconN, l_width)
      l_iconN = l_iconN + 1
    end
  end
end

function TwinkiePlates:UpdateIconsPc(tNameplate)
  local nConfigurationFlags = 0
  local nIconsCounter = 0

  if (tNameplate.unitNameplateOwner:IsFriend() or
      tNameplate.unitNameplateOwner:IsAccountFriend()) then
    nIconsCounter = nIconsCounter + 1
    nConfigurationFlags = SetFlag(nConfigurationFlags, F_FRIEND)
  end

  if (tNameplate.unitNameplateOwner:IsRival()) then
    nIconsCounter = nIconsCounter + 1
    nConfigurationFlags = SetFlag(nConfigurationFlags, F_RIVAL)
  end

  if (nConfigurationFlags ~= tNameplate.iconFlags) then
    tNameplate.iconFlags = nConfigurationFlags
    tNameplate.containerIcons:DestroyAllPixies()

    local nIconsContainerHeight = tNameplate.containerIcons:GetHeight()
    local nIconsContainerWidth = 1 / nIconsCounter
    local nIconPos = 0

    tNameplate.containerIcons:SetAnchorOffsets(0, 0, nIconsCounter * nIconsContainerHeight, 0)

    if (GetFlag(nConfigurationFlags, F_FRIEND)) then
      self:AddIcon(tNameplate, "IconFriend", nIconPos, nIconsContainerWidth)
      nIconPos = nIconPos + 1
    end

    if (GetFlag(nConfigurationFlags, F_RIVAL)) then
      self:AddIcon(tNameplate, "IconRival", nIconPos, nIconsContainerWidth)
      nIconPos = nIconPos + 1
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

  if (unitNameplateOwner == nil or not unitNameplateOwner:IsValid()) then
    return false
  end

  if (unitNameplateOwner:GetMouseOverType() == "Simple" or unitNameplateOwner:GetMouseOverType() == "SimpleCollidable") then
    return false
  end

  if (unitNameplateOwner:IsDead()) then
    return false
  end

  local nUnitMaxHealth = unitNameplateOwner:GetMaxHealth()
  if (nUnitMaxHealth == nil or nUnitMaxHealth == 0) then
    return false
  end

  return true
end

function TwinkiePlates:GetNameplateVisibility(tNameplate)
  if (_bIsPlayerBlinded) then return false
  end

  local unitTarget = _unitPlayer:GetTarget()

  -- return false if the nameplate is targeted by the player. Targeted nameplate is handled by _TargetNP
  if (unitTarget == tNameplate.unitNameplateOwner and not tNameplate.bIsTargetNameplate) then return false
  end

  if (not tNameplate.bIsOnScreen) then return false
  end

  if (_tSettings["ConfigOcclusionCulling"] and tNameplate.bIsOccluded) then return false
  end

  if (tNameplate.bIsUnitOutOfRange) then return false
  end

  -- if this is the target nameplate
  if (tNameplate.bIsTargetNameplate) then
    -- return true if this still is the player's target nameplate
    return unitTarget == tNameplate.unitNameplateOwner
  end

  if (not GetFlag(tNameplate.nMatrixFlags, F_NAMEPLATE)) then
    return tNameplate.bHasActivationState or tNameplate.bIsObjective
  end

  if (tNameplate.unitNameplateOwner:IsDead() or (tNameplate.nCurrHealth and tNameplate.nCurrHealth <= 0)) then return false
  end

  if (tNameplate.bForcedHideDisplayToggle ~= nil) then
    return tNameplate.bForcedHideDisplayToggle
  end

  -- Uninportant NPCs handling
  local bIsFriendly = tNameplate.eDisposition == Unit.CodeEnumDisposition.Friendly
  if (not tNameplate.bIsPlayer and bIsFriendly) then
    return tNameplate.bHasActivationState or tNameplate.bIsObjective
  end

  return true
end

function TwinkiePlates:InitAnchoring(tNameplate, nCodeEnumFloaterLocation)
  local tAnchorUnit = tNameplate.unitNameplateOwner:IsMounted() and tNameplate.unitNameplateOwner:GetUnitMount() or tNameplate.unitNameplateOwner

  if (self.nameplacer or nCodeEnumFloaterLocation) then
    if (not nCodeEnumFloaterLocation) then
      local tNameplatePositionSetting = self.nameplacer:GetUnitNameplatePositionSetting(tNameplate.unitNameplateOwner:GetName())

      if (tNameplatePositionSetting and tNameplatePositionSetting["nAnchorId"]) then
        nCodeEnumFloaterLocation = tNameplatePositionSetting["nAnchorId"]
      end
    end

    if (nCodeEnumFloaterLocation and (nCodeEnumFloaterLocation ~= tNameplate.nAnchorId or tAnchorUnit ~= tNameplate.unitNameplateOwner)) then

      tNameplate.nAnchorId = nCodeEnumFloaterLocation
      tNameplate.wndNameplate:SetUnit(tAnchorUnit, tNameplate.nAnchorId)
      return
    end
  end

  tNameplate.nAnchorId = 1
  tNameplate.wndNameplate:SetUnit(tAnchorUnit, tNameplate.nAnchorId)
end


function TwinkiePlates:GetUnitCategoryType(unitNameplateOwner)

  if (unitNameplateOwner == nil or not unitNameplateOwner:IsValid()) then return "Hidden"
  end

  if (unitNameplateOwner:CanBeHarvestedBy(_unitPlayer)) then
    return _tSettings["ConfigShowHarvest"] and "Other" or "Hidden"
  end

  if (unitNameplateOwner:IsThePlayer()) then return "Self"
  end

  -- Not using GameLib.GetTarget() cause it seems to return a copy of the original unit and that can be more resource intensive - untested
  if (_unitPlayer and _unitPlayer:GetTarget() == unitNameplateOwner) then return "Target"
  end

  if (unitNameplateOwner:IsInYourGroup()) then return "Group" end


  local strUnitType = unitNameplateOwner:GetType()
  if (strUnitType == "BindPoint") then return "Other"
  end
  if (strUnitType == "PinataLoot") then return "Other"
  end
  if (strUnitType == "Ghost") then return "Hidden"
  end
  if (strUnitType == "Mount") then return "Hidden"
  end

  -- Some interactable objects are identified as NonPlayer
  -- This hack is done to prevent display the nameplate for this kind of units
  if (strUnitType == "NonPlayer" and not unitNameplateOwner:GetUnitRaceId() and not unitNameplateOwner:GetLevel()) then
    return "Hidden"
  end

  local eDisposition = unitNameplateOwner:GetDispositionTo(_unitPlayer)
  local bIsCharacter = unitNameplateOwner:IsACharacter()
  local strPcOrNpc = (bIsCharacter) and "Pc" or "Npc"

  if (_tDisplayHideExceptionUnitNames[unitNameplateOwner:GetName()] ~= nil) then
    return _tDisplayHideExceptionUnitNames[unitNameplateOwner:GetName()] and _tDispositionToString[eDisposition][strPcOrNpc] or "Hidden"
  end

  local tRewardInfo = unitNameplateOwner:GetRewardInfo()

  if (tRewardInfo ~= nil and _next(tRewardInfo) ~= nil) then
    for i = 1, #tRewardInfo do
      if (tRewardInfo[i].strType ~= "Challenge") then
        return _tDispositionToString[eDisposition][strPcOrNpc]
      end
    end
  end

  if (bIsCharacter or self:HasActivationState(unitNameplateOwner)) then
    return _tDispositionToString[eDisposition][strPcOrNpc]
  end

  if (unitNameplateOwner:GetHealth() == nil) then return "Hidden"
  end

  local l_archetype = unitNameplateOwner:GetArchetype()

  -- Returning Friendly/Neutral/Hostile .. Pc/Npc
  if (l_archetype ~= nil) then
    return _tDispositionToString[eDisposition][strPcOrNpc]
  end

  return "Hidden"
end

function TwinkiePlates:GetNameplateCategoryType(tNameplate)

  local unitNameplateOwner = tNameplate.unitNameplateOwner

  if (unitNameplateOwner == nil or not unitNameplateOwner:IsValid()) then return "Hidden"
  end

  -- Top priority checks:
  -- 1) Self (Player)
  -- 2) Player's target
  -- 3) Group
  if (tNameplate.strUnitCategory == "Self") then return tNameplate.strUnitCategory end

  -- TODO Replace this check with a more consistent one
  if (_unitPlayer and _unitPlayer:GetTarget() == tNameplate) then return "Target" end

  if (tNameplate.bIsInGroup) then return "Group" end

  -- Harvesting nodes
  if (unitNameplateOwner:CanBeHarvestedBy(_unitPlayer)) then
    return _tSettings["ConfigShowHarvest"] and "Other" or "Hidden"
  end

  local eDisposition = tNameplate.eDisposition
  local bIsCharacter = tNameplate.bIsPlayer
  local strPcOrNpc = (bIsCharacter) and "Pc" or "Npc"
  local strUnitCategory = _tDispositionToString[eDisposition][strPcOrNpc]

  -- Forced exceptions (hide/show)
  if (tNameplate.bForcedHideDisplayToggle ~= nil) then
    return tNameplate.bForcedHideDisplayToggle and strUnitCategory or "Hidden"
  end

  -- Objectives
  --[[  local tRewardInfo = unitNameplateOwner:GetRewardInfo()

    if (tRewardInfo ~= nil and _next(tRewardInfo) ~= nil) then
      for i = 1, #tRewardInfo do
        if (tRewardInfo[i].strType ~= "Challenge") then
          return strUnitCategory
        end
      end
    end]]

  -- Interactables
  if (bIsCharacter or tNameplate.bHasActivationState) then
    return strUnitCategory
  end

  -- Dead creatures
  if (tNameplate.nCurrHealth == nil) then return "Hidden" end

  return strUnitCategory
end

function TwinkiePlates:SetCombatState(tNameplate, bIsInCombat)
  -- Do nothing because combat state change event is too unreliable for PCs
  -- Combat state change detection is performed on frame

  --[[
    if (tNameplate == nil) then return
    end

    -- If combat state changed
  if (tNameplate.bIsInCombat ~= bIsInCombat) then
      tNameplate.bIsInCombat = bIsInCombat
      tNameplate.nMatrixFlags = self:GetCombatStateDependentFlags(tNameplate)
      self:UpdateTextNameGuild(tNameplate)
      self:UpdateTopContainer(tNameplate)
    end

    self:UpdateHealthShieldText(tNameplate)
    ]]
end

function TwinkiePlates:HasActivationState(unitNameplateOwner)

  local tActivationStates = unitNameplateOwner:GetActivationState()
  if (_next(tActivationStates) == nil) then return false
  end
  local bShow = false
  for strState, a in _pairs(tActivationStates) do
    if (strState == "Busy") then return false
    end
    if (not _asbl[strState]) then bShow = true
    end
  end

  return bShow
end

function TwinkiePlates:SetProgressBar(p_bar, p_current, p_max)
  p_bar:SetMax(p_max)
  p_bar:SetProgress(p_current)
end

function TwinkiePlates:SetNameplateVerticalOffset(tNameplate, nVerticalOffset, nNameplacerVerticalOffset)

  tNameplate.wndNameplate:SetAnchorOffsets(-200, -75 - nVerticalOffset - nNameplacerVerticalOffset, 200, 75 - nVerticalOffset - nNameplacerVerticalOffset)

  if self.perspectivePlates then

    local bounds = {}
    bounds.left = -200
    bounds.top = -75 - nVerticalOffset - nNameplacerVerticalOffset
    bounds.right = 200
    bounds.bottom = 75 - nVerticalOffset - nNameplacerVerticalOffset

    tNameplate.unitOwner = tNameplate.unitNameplateOwner
    self.perspectivePlates:OnRequestedResize(tNameplate, 1, bounds)
  end
end

function TwinkiePlates:AllocateNameplate(unitNameplateOwner)
  if (self.tNameplates[unitNameplateOwner:GetId()] == nil) then
    local strUnitCategoryType = self:GetUnitCategoryType(unitNameplateOwner)
    if (strUnitCategoryType ~= "Hidden") then
      local l_nameplate = self:InitNameplate(unitNameplateOwner, _tableRemove(self.pool) or nil)
      self.tNameplates[unitNameplateOwner:GetId()] = l_nameplate
    end
  end
end

function TwinkiePlates:OnUnitDestroyed(unitNameplateOwner)
  local tNameplate = self.tNameplates[unitNameplateOwner:GetId()]
  if (tNameplate == nil) then return
  end

  if (#self.pool < 50) then
    tNameplate.wndNameplate:Show(false, true)
    tNameplate.wndNameplate:SetUnit(nil)
    tNameplate.wndUnitNameText:SetData(nil)
    tNameplate.wndHealthProgressBar:SetData(nil)
    tNameplate.bIsVerticalOffsetUpdated = nil
    _tableInsert(self.pool, tNameplate)
  else
    tNameplate.wndNameplate:Destroy()
  end
  self.tNameplates[unitNameplateOwner:GetId()] = nil
end

function TwinkiePlates:UpdateMainContainerHeightWithHealthText(p_nameplate)
  --  local l_fontSize = _tSettings["SliderFontSize"]
  --  local l_zoomSliderH = _tSettings["SliderBarScale"] / 10
  --  local l_shieldHeight = p_nameplate.bHasShield and l_zoomSliderH * 1.3 or l_zoomSliderH
  --  local l_healthTextFont = _tSettings["ConfigAlternativeFont"] and _fontSecondary or _fontPrimary
  --  local l_healthTextHeight = _tSettings["ConfigHealthText"] and (l_healthTextFont[l_fontSize].height * 0.75) or 0

  -- p_nameplate.wndHealthProgressBar:SetAnchorOffsets(0, 0, 0, --[[l_shieldHeight + l_healthTextHeight]] p_nameplate.bHasShield and 0 or -4)
  p_nameplate.wndHealthText:Show(true)
end

function TwinkiePlates:UpdateMainContainerHeightWithoutHealthText(p_nameplate)
  -- Reset text

  -- Set container height without text
  --  local l_zoomSliderH = _tSettings["SliderBarScale"] / 10
  --  local l_shieldHeight = p_nameplate.bHasShield and l_zoomSliderH * 1.3 or l_zoomSliderH
  -- p_nameplate.wndContainerMain:SetAnchorOffsets(144, -5, -144, --[[l_shieldHeight]] 16)
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
  if (not tbl) then return "nil"
  end

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
