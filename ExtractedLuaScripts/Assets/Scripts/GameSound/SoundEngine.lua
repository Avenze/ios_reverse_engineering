---@class SoundEngine
local SoundEngine = GameTableDefine.SoundEngine
local EventManager = require("Framework.Event.Manager")

local AudioMgr = CS.Common.Utils.AudioManager.Instance

SoundEngine.m_bgMusicName = nil
SoundEngine.m_isBGMFixed = false
SoundEngine.m_lastSoundIds = {}


SoundEngine.m_isTimeLineMusic = false

SoundEngine.m_preSceneBGMLoop = false
SoundEngine.m_preSceneBGMName = nil

setmetatable(SoundEngine, {__index = SoundConst})
------------------------------BackGround-------------------------------
function SoundEngine:PlayBackgroundMusic(musicfile, isLoop, isFixed)

    --如果正在播放TimeLine的BGM，那就不要播放场景的BGM
    if SoundEngine.m_isTimeLineMusic then
        SoundEngine.m_preSceneBGMLoop = isLoop
        SoundEngine.m_preSceneBGMName = musicfile
        return
    end

    if isFixed or not SoundEngine.m_isBGMFixed then
        if SoundEngine.m_bgMusicName == musicfile then
            return
        end
        SoundEngine.m_bgMusicName = musicfile
        AudioMgr:PlayBGM(musicfile, isLoop)
        SoundEngine.m_preSceneBGMLoop = isLoop
    end

    if isFixed then
        SoundEngine:FixBGM()
    else
        SoundEngine:UnFixBGM()
    end
end

---缓存当前的的SceneBGM
function SoundEngine:CatchAndStopSceneBGM()
    SoundEngine.m_isTimeLineMusic = true
    SoundEngine.m_preSceneBGMName = SoundEngine.m_bgMusicName
    AudioMgr:PauseBGM()
end

---解除当前的的SceneBGM的缓存
function SoundEngine:UnCatchAndStopSceneBGM()
    if not SoundEngine.m_isTimeLineMusic then
        return
    end
    SoundEngine.m_isTimeLineMusic = false
    if SoundEngine.m_preSceneBGMName then
        if SoundEngine.m_preSceneBGMName == SoundEngine.m_bgMusicName then
            AudioMgr:UnPauseBGM()
        else
            SoundEngine:PlayBackgroundMusic(SoundEngine.m_preSceneBGMName,SoundEngine.m_preSceneBGMLoop)
        end
    end
end

---播放TimeLineBGM,缓存之前的SceneBGM
function SoundEngine:PlayTimeLineBGM(musicfile, isLoop)
    if not SoundEngine.m_isTimeLineMusic then
        self:CatchAndStopSceneBGM()
    end
    if SoundEngine.m_bgMusicName == musicfile then
        return
    end
    SoundEngine.m_bgMusicName = musicfile
    AudioMgr:PlayBGM(musicfile, isLoop)
end

function SoundEngine:CurrBackgroundMusic()
    return SoundEngine.m_bgMusicName
end

function SoundEngine:StopBackgroundMusic(forceStop)
    if forceStop or not self.m_isBGMFixed then
        AudioMgr:StopBGM()
    end
end

function SoundEngine:FixBGM()
    SoundEngine.m_isBGMFixed = true
end

function SoundEngine:UnFixBGM()
    SoundEngine.m_isBGMFixed = false
end

------------------------------SFx-------------------------------
function SoundEngine:PlaySFX(sfxfile, isLoop, cb)
    local isLoop = isLoop or false
    local cb = cb or nil
    local soundId = AudioMgr:PlaySound(sfxfile, isLoop, cb)
    self.m_lastSoundIds[sfxfile] = soundId
    return soundId
end

function SoundEngine:StopAllSFX()
    for k, v in pairs(self.m_lastSoundIds) do
        SoundEngine:StopSFX(v)
        self.m_lastSoundIds[k] = nil
    end
end

function SoundEngine:StopSFX(soundId)
    AudioMgr:StopSound(soundId)
end

function SoundEngine:StopLastSFX(sfxfile)
    if self.m_lastSoundIds[sfxfile] then
        SoundEngine:StopSFX(self.m_lastSoundIds[sfxfile])
        self.m_lastSoundIds[sfxfile] = nil
    end
end

function SoundEngine:OpenSFX()
    AudioMgr.SoundVolume = 1.0
end

function SoundEngine:OpenMusic()
    AudioMgr.MusicVolume = 1.0
end

function SoundEngine:CloseSFX()
    AudioMgr.SoundVolume = 0.0
end

function SoundEngine:StopMusic()
    AudioMgr.MusicVolume = 0.0
end

function SoundEngine:MusicOn()
    return AudioMgr.MusicVolume > 0
end

function SoundEngine:SFXOn()
    return AudioMgr.SoundVolume > 0
end

function SoundEngine:SetMusic(open)
    AudioMgr.MusicVolume = open == true and 1.0 or 0.0
end

function SoundEngine:SetSFX(open)
    AudioMgr.SoundVolume = open == true and 1.0 or 0.0
end

function SoundEngine:SetTimeLineVisible(visible)
    if nil == visible then
        return
    end
    AudioMgr.VisibleTimeLineSound = visible
end

EventManager:RegEvent(
    "FS_CMD_PLAY_SFX",
    function(sfx)
        SoundEngine:PlaySFX(sfx)
    end
)

EventManager:RegEvent("PLAY_BGM", function(go,args)
    if not args then
        return
    end
    local bgm = args and args[1] or nil
    if bgm then
        if string.find(bgm, "Assets") ~= 1 then
            bgm = "Assets/Res/Audio/"..bgm
        end
        SoundEngine:PlayTimeLineBGM(bgm,true)
    end
end)

EventManager:RegEvent("STOP_BGM", function()
    SoundEngine:UnCatchAndStopSceneBGM()
end)
