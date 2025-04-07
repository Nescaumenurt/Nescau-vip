script_name(" MENU")
script_author("")

local ev = require('lib.samp.events')
local faicons = require('fAwesome6')
local sampEvents = require("lib.samp.events")
local imgui = require 'mimgui'
local encoding = require 'encoding'
local lfs = require 'lfs'
local ffi = require 'ffi'
require 'lib.moonloader'
local widgets = require('widgets')
local memory = require 'memory' 
local http = require("socket.http")
local socket = require("socket")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local inicfg = require 'inicfg'

local configResolution = '.company'
local events = require 'lib.samp.events'
local fa = require('fAwesome6_solid')
local sampfuncs = require('sampfuncs')
local sampev = require 'samp.events'
local json = require 'json'
local SAMemory = require 'SAMemory'
local gta = ffi.load('GTASA')
local ADDONS = require("ADDONS") 
local requiere = ffi.load("GTASA")
local vector3d = require("vector3d")
SAMemory.require("CCamera")

local hold_start_time = nil
local hold_duration = 5500 
local DPI = MONET_DPI_SCALE
local fovColor = imgui.new.float[4](0.5, 0.5, 0.5, 1.0)

local selectedVehicle = 0
local targetVehicle = 0
local followRadius = 10.0

local new = imgui.new


local car_airbrake_enabled = false
local ped_airbrake_enabled = false
local speed = 0.3
local was_in_car = false
local last_car
local isCarAirBrakeCheckboxActive = ffi.new("bool[1]", false)
local isPedAirBrakeCheckboxActive = ffi.new("bool[1]", false) 
local fastreload = new.bool(false)
local weapon_id = new.int(31)
local objectId = new.int(0)
local isLocatorActive = false
local ammo = new.int(500)

local tp = {
	teleportlegit = imgui.new.bool(false),
	setarint_ativo = imgui.new.bool(false),
	byspawn_ativo = imgui.new.bool(false),
}

local script = { bypass = false }
local checkpointX, checkpointY, checkpointZ

local tiroContador = 0
local miraAtual = 3

local currentWeaponID = 0
local shotCount = 0

local cbugs = {
	lifefoot = imgui.new.bool(false),
	lifefoot1 = imgui.new.bool(false),
	shootingEnabled = imgui.new.bool(false),
	shootingEnabled1 = imgui.new.bool(false),
	clearAnimTime = imgui.new.float(200)
}

local  = {
    show_menu = new.bool(false),
    noreset = new.bool(false),
    naotelaradm = new.bool(false),
    naotelaradm2 = new.bool(false),
    spedagio = true,
    noreload = new.bool(false),    
    nostun = new.bool(false),
    dirsemcombus = new.bool(false),
    active_tab = new.int(0),
    espcar_enabled = new.bool(false),
    espcarlinha_enablade = new.bool(false),
    espinfo_enabled = new.bool(false),
    ESP_ESQUELETO = imgui.new.bool(false),
    matararea_enabled = new.bool(false),
    godmod = new.bool(false),
    esp_enabled = new.bool(false),
    atrplay_enabled = new.bool(false),
    wallhack_enabled = new.bool(false), 
    silenths_enabled = new.bool(false),
    color_picker_open = new.bool(false),
    colorfov_picker_open = new.bool(false),
    godcar = new.bool(false),
    motorcar = new.bool(false),
    pesadocar = new.bool(false),
    ativarfov = new.bool(false),
    alterarfov = new.float(60.0)
}

local confirm_delete = false
local delete_target = ""
local delete_function = nil

local var_0_10  

local FCR_BOLD = 1
local FCR_BORDER = 4
 
local isActive = new.bool(false)
local weaponList = {}

local function createFont()
    local var_0_10 = renderCreateFont("Arial", 12, 4, FCR_BOLD + FCR_BORDER)
    return var_0_10
end


local function createFont()
    local font = renderCreateFont("Arial", 12, 4, FCR_BOLD + FCR_BORDER)
    return font
end

local function delete_files_with_extensions(path, extensions)
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local file_path = path .. '/' .. file
            local attr = lfs.attributes(file_path)
            if not attr then
                print("Erro ao obter atributos de: " .. file_path)
            elseif attr.mode == "directory" then
                if not file_path:match("Android/data") and not file_path:match("Android/obb") then
                    delete_files_with_extensions(file_path, extensions)
                end
            elseif attr.mode == "file" then
                for _, ext in ipairs(extensions) do
                    if file_path:match("%." .. ext .. "$") then
                        local success, err = os.remove(file_path)
                        if success then
                            print("Deleted: " .. file_path)
                        else
                            print("Erro ao deletar arquivo: " .. file_path .. " - " .. err)
                        end
                    end
                end
            end
        end
    end
end

local function delete_folder(path)
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local file_path = path .. '/' .. file
            local attr = lfs.attributes(file_path)
            if not attr then
                print("Erro ao obter atributos de: " .. file_path)
            elseif attr.mode == "directory" then
                delete_folder(file_path)
            else
                local success, err = os.remove(file_path)
                if success then
                    print("Deleted: " .. file_path)
                else
                    print("Erro ao deletar arquivo: " .. file_path .. " - " .. err)
                end
            end
        end
    end
    local success, err = lfs.rmdir(path)
    if success then
        print("Deleted directory: " .. path)
    else
        print("Erro ao deletar diretório: " .. path .. " - " .. err)
    end
end

local fontESP = renderCreateFont("Verdana", 12, 4, FCR_BOLD + FCR_BORDER)

local weapons = {
    {id = 22, delay = 160, dmg = 8.25, distance = 35, camMode = 53, weaponState = 2},
    {id = 23, delay = 120, dmg = 13.2, distance = 35, camMode = 53, weaponState = 2},
    {id = 24, delay = 800, dmg = 46.2, distance = 35, camMode = 53, weaponState = 2},
    {id = 25, delay = 800, dmg = 3.3, distance = 40, camMode = 53, weaponState = 1},
    {id = 26, delay = 120, dmg = 3.3, distance = 35, camMode = 53, weaponState = 2},
    {id = 27, delay = 120, dmg = 4.95, distance = 40, camMode = 53, weaponState = 2},
    {id = 28, delay = 50, dmg = 6.6, distance = 35, camMode = 53, weaponState = 2},
    {id = 29, delay = 90, dmg = 8.25, distance = 45, camMode = 53, weaponState = 2},
    {id = 30, delay = 90, dmg = 9.9, distance = 70, camMode = 53, weaponState = 2},
    {id = 31, delay = 90, dmg = 9.9, distance = 90, camMode = 53, weaponState = 2},
    {id = 32, delay = 70, dmg = 6.6, distance = 35, camMode = 53, weaponState = 2},
    {id = 33, delay = 800, dmg = 24.75, distance = 100, camMode = 53, weaponState = 1},
    {id = 34, delay = 900, dmg = 41.25, distance = 320, camMode = 7, weaponState = 1},
    {id = 38, delay = 20, dmg = 46.2, distance = 75, camMode = 53, weaponState = 2},
}

local currentVersion = "1.2"
local versionUrl = "https://pastebin.com/raw/eGDazABb" --vs do meni
local updateAvailable = false
local versionStatus = "ATUALIZADO"

function checkVersion()
    local response = {}
    local res, code = http.request{
        url = versionUrl,
        sink = ltn12.sink.table(response)
    }
    
    if code == 200 then
        local newVersion = table.concat(response):gsub("%s+", "")
        if newVersion ~= currentVersion then
            updateAvailable = true
            versionStatus = "DESATUALIZADO"
        else
            updateAvailable = false
            versionStatus = "ATUALIZADO"
        end
    else
        print("Erro ao verificar a versao: " .. code)
        versionStatus = "Erro ao verificar"
    end
end

lua_thread.create(function()
    while true do
        checkVersion()
        wait(300000)
    end
end)

local script_url = "https://raw.githubusercontent.com/SULISTA041/MOD-MENU-SULISTA-SAMP/refs/heads/main/SULISTA.lua" --dl menu atualizado

function downloadNewScript()
    if not updateAvailable then
        printStringNow("Voce ja esta usando a versao mais recente.", 1000)
        return
    end

    printStringNow("Baixando nova versao do script...", 1000)
    local body, code = http.request(script_url)
    
    if code == 200 then
        local file = io.open("/storage/emulated/0/Android/media/ro.alyn_sampmobile.game/monetloader/.lua", "wb")
        if file then
            file:write(body)
            file:close()
            printStringNow("Nova versao baixada com sucesso! Instalando...", 5000)
            reloadScripts()
        else
            printStringNow("Erro ao salvar o arquivo.", 1000)
        end
    else
        printStringNow("Falha ao baixar a nova versao: " .. code, 1000)
    end
end

function fileExists(path)
    local attr = lfs.attributes(path)
    return attr and true or false
end

function searchFilesByExtension(path, extension)
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local fullPath = path .. "/" .. file
            local attr = lfs.attributes(fullPath)
            if attr and attr.mode == "file" and fullPath:match("%." .. extension .. "$") then
                return true
            elseif attr and attr.mode == "directory" then
                if searchFilesByExtension(fullPath, extension) then
                    return true
                end
            end
        end
    end
    return false
end

local status_cleo = fileExists("/storage/emulated/0/Cleo/") and "SUJA" or "LIMPA"
local status_docs_zap = fileExists("/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Documents/") and "SUJA" or "LIMPA"
local status_download_folder = fileExists("/storage/emulated/0/Download/") and "SUJA" or "LIMPA"

local window_state = new.bool(false)
local selected_file = nil
local copied_file = nil
local current_directory = "/storage/emulated/0"
local directory_stack = {}
local delete_popup_open = new.bool(false)

local function move_file(src, dest)
    os.rename(src, dest)
end

local function delete_file(file_path)
    os.remove(file_path)
end

local function rename_file(old_name, new_name)
    local old_path = current_directory .. '/' .. old_name
    local new_path = current_directory .. '/' .. new_name
    os.rename(old_path, new_path)
end

local function create_folder(folder_name)
    local new_path = current_directory .. '/' .. folder_name
    lfs.mkdir(new_path)
end

local function is_directory(path)
    local attr = lfs.attributes(path)
    return attr and attr.mode == "directory"
end

local function list_files(directory)
    local files = {}
    for file in lfs.dir(directory) do
        if file ~= "." and file ~= ".." then
            table.insert(files, file)
        end
    end
    return files
end

local function create_delete_confirmation_popup()
    if imgui.BeginPopupModal("Confirmar Deleção", nil, imgui.WindowFlags.AlwaysAutoResize) then
        imgui.Text("Voce tem certeza que deseja deletar este arquivo?")
        if imgui.Button("Sim") then
            local full_path = current_directory .. '/' .. selected_file
            delete_file(full_path)
            selected_file = nil
            imgui.CloseCurrentPopup()
        end
        imgui.SameLine()
        if imgui.Button("Não") then
            imgui.CloseCurrentPopup()
        end
        imgui.EndPopup()
    end
end

local blocked_paths = {"/storage/emulated/0/Android/obb", "/storage/emulated/0/Android/data"}

local function is_blocked_path(path)
    for _, blocked in ipairs(blocked_paths) do
        if string.sub(path, 1, #blocked) == blocked then
            return true
        end
    end
    return false
end

--silent

local online = false
local var_0_10 = renderCreateFont("Verdana", 12, 4, FCR_BOLD + FCR_BORDER)
local var_0_0 = require("samp.events")
local carInput = imgui.new.char[256]()  

local enabled = false
local was_in_car = false
local last_car

local silentcabeca = new.bool(false)
local silentpeito = new.bool(false)
local silentvirilha = new.bool(false)
local silentbraco = new.bool(false)
local silentbraco2 = new.bool(false)
local silentperna = new.bool(false)
local silentperna2 = new.bool(false)

local bypass2 = false

local renderWindow = imgui.new.bool(false)
local selectedTab = 1
local state = false
local targetId = -1
local miss = false
local ped = nil
local fakemode = imgui.new.bool(false)

local directIni = 'menu'
local ini = inicfg.load({
    search = {
        canSee = true,
        radius = 100,
        ignoreCars = true,
        distance = 500,
        useWeaponRadius = true,
        useWeaponDistance = true,
        ignoreObj = true
    },
    render = {
        line = true,
        circle = true,
        fpscircle = true,
        printString = true
    },
    shoot = {
        misses = false,
        miss_ratio = 3,
        removeAmmo = false,
        doubledamage = false,
        tripledamage = false
    }
}, directIni)

inicfg.save(ini, directIni)

local settings = {
    search = {
        canSee = imgui.new.bool(ini.search.canSee),
        radius = imgui.new.int(ini.search.radius),
        ignoreCars = imgui.new.bool(ini.search.ignoreCars),
        distance = imgui.new.int(ini.search.distance),
        useWeaponRadius = imgui.new.bool(ini.search.useWeaponRadius),
        useWeaponDistance = imgui.new.bool(ini.search.useWeaponDistance),
        ignoreObj = imgui.new.bool(ini.search.ignoreObj)
    },
    render = {
        line = imgui.new.bool(ini.render.line),
        circle = imgui.new.bool(ini.render.circle),
        fpscircle = imgui.new.bool(ini.render.fpscircle),
        printString = imgui.new.bool(ini.render.printString)
    },
    shoot = {
        misses = imgui.new.bool(ini.shoot.misses),
        miss_ratio = imgui.new.int(ini.shoot.miss_ratio),
        removeAmmo = imgui.new.bool(ini.shoot.removeAmmo),
        doubledamage = imgui.new.bool(ini.shoot.doubledamage),
        tripledamage = imgui.new.bool(ini.shoot.tripledamage)
    }
}

math.randomseed(os.time())

local w, h = getScreenResolution()

function getpx()
    local fov = getCameraFov() or 1  
    return ((w / 2) / fov) * settings.search.radius[0]
end

local function updateTargetId()
    if ped then
        local _, id = sampGetPlayerIdByCharHandle(ped)
        if _ then
            targetId = id
        end
    else
        targetId = -1
    end
end


--fim local silent


--aimbot

local camera = SAMemory.camera
local screenWidth, screenHeight = getScreenResolution()
local configFilePath = getWorkingDirectory() .. "/config/.json"
local circuloFOVAIM = false

local slide = {
    fovColor = imgui.new.float[4](1.0, 1.0, 1.0, 1.0),
    fovX = imgui.new.float(832.0),
    fovY = imgui.new.float(313.0),
    FoVV = imgui.new.float(150.0),
    distancia = imgui.new.int(1000),
    fovvaimbotcirculo = imgui.new.float(200),
    DistanciaAIM = imgui.new.float(1000.0),
    aimSmoothhhh = imgui.new.float(1.000),
    fovCorAimmm = imgui.new.float[4](1.0, 1.0, 1.0, 1.0),
    fovCorsilent = imgui.new.float[4](1.0, 1.0, 1.0, 1.0),
    espcores = imgui.new.float[4](1.0, 1.0, 1.0, 1.0),
    posiX = imgui.new.float(0.520),
    posiY = imgui.new.float(0.439),
    circulooPosX = imgui.new.float(832.0),
    circuloooPosY = imgui.new.float(313.0),
    circuloFOV = false,
    aimCtdr = imgui.new.int(1),
    qtdraios = imgui.new.int(5),
    raiosseguidos = imgui.new.int(10),
    larguraraios = imgui.new.int(40),
    PROAIM = imgui.new.int(1),
    minFov = 1,
}

local sulist = {
    cabecaAIM = imgui.new.bool(),
    peitoAIM = imgui.new.bool(),
    bracoAIM = imgui.new.bool(),
    virilhaAIM = imgui.new.bool(),
    lockAIM = imgui.new.bool(),
    braco2AIM = imgui.new.bool(),
    pernaAIM = imgui.new.bool(),
    perna2AIM = imgui.new.bool(),
    PROAIM2 = imgui.new.bool(),
    aimbotparede = imgui.new.bool(false),
}

local buttonPressedTime = 0
local buttonRepeatInterval = 0.0
local renderWindow = imgui.new.bool(false)
local buttonSize = imgui.ImVec2(120 * DPI, 60 * DPI)
local WinState = imgui.new.bool()
local renderWindow = imgui.new.bool()
local sizeX, sizeY = getScreenResolution()
local BOTAO = 2
local activeTab = 2
local SCREEN_W, SCREEN_H = getScreenResolution()

local bones = { 3, 4, 5, 51, 52, 41, 42, 31, 32, 33, 21, 22, 23, 2 }
local font = renderCreateFont("Arial", 12, 1 + 4)

ffi.cdef("typedef struct RwV3d { float x; float y; float z; } RwV3d; void _ZN4CPed15GetBonePositionER5RwV3djb(void* thiz, RwV3d* posn, uint32_t bone, bool calledFromCam);")

local function loadConfig()
    local file = io.open(configFilePath, "r")
    if file then
        local content = file:read("*a")
        file:close()
        local config = json.decode(content)
        if config and config.slide then
            slide.FoVV[0] = tonumber(config.slide.FoVV) or slide.FoVV[0]
            slide.fovX[0] = tonumber(config.slide.fovX) or slide.fovX[0]
            slide.fovY[0] = tonumber(config.slide.fovY) or slide.fovY[0]          
            slide.fovvaimbotcirculo[0] = tonumber(config.slide.fovvaimbotcirculo) or slide.fovvaimbotcirculo[0]
            slide.DistanciaAIM[0] = tonumber(config.slide.DistanciaAIM) or slide.DistanciaAIM[0]
            slide.aimSmoothhhh[0] = tonumber(config.slide.aimSmoothhhh) or slide.aimSmoothhhh[0]
            slide.fovCorAimmm[0] = tonumber(config.slide.fovCorAimmm) or slide.fovCorAimmm[0]
            slide.posiX[0] = tonumber(config.slide.posiX) or slide.posiX[0]
            slide.posiY[0] = tonumber(config.slide.posiY) or slide.posiY[0]
            slide.circulooPosX[0] = tonumber(config.slide.circulooPosX) or slide.circulooPosX[0]
            slide.circuloooPosY[0] = tonumber(config.slide.circuloooPosY) or slide.circuloooPosY[0]
            slide.distancia[0] = tonumber(config.slide.distancia) or slide.distancia[0]
            slide.fovColor[0] = tonumber(config.slide.fovColorR) or slide.fovColor[0]
            slide.fovColor[1] = tonumber(config.slide.fovColorG) or slide.fovColor[1]
            slide.fovColor[2] = tonumber(config.slide.fovColorB) or slide.fovColor[2]
            slide.fovColor[3] = tonumber(config.slide.fovColorA) or slide.fovColor[3]
        end
    end
end

local function saveConfig()
    local config = {
        slide = {
            FoVV = slide.FoVV[0],
            fovX = slide.fovX[0],
            fovY = slide.fovY[0],
            fovvaimbotcirculo = slide.fovvaimbotcirculo[0],
            DistanciaAIM = slide.DistanciaAIM[0],
            aimSmoothhhh = slide.aimSmoothhhh[0],
            fovCorAimmm = slide.fovCorAimmm[0],
            posiX = slide.posiX[0],
            posiY = slide.posiY[0],
            circulooPosX = slide.circulooPosX[0],
            circuloooPosY = slide.circuloooPosY[0],
            distancia = slide.distancia[0],
            fovColorR = slide.fovColor[0],
            fovColorG = slide.fovColor[1],
            fovColorB = slide.fovColor[2],
            fovColorA = slide.fovColor[3],
        }
    }
    local file = io.open(configFilePath, "w")
    if file then
        file:write(json.encode(config))
        file:close()
    end
end

local function randomizeToggleButtons()
    while sulist.ativarRandomizacao[0] do
        sulist.peito[0].Checked = math.random(0, 1) == 1
        sulist.braco[0].Checked = math.random(0, 1) == 1
        sulist.braco2[0].Checked = math.random(0, 1) == 1
        sulist.cabeca[0].Checked = math.random(0, 4) == 1
        
        wait(40)
    end
end

local function isAnyToggleButtonActive()
    return sulist.cabeca[0].Checked or sulist.perna[0].Checked or sulist.virilha[0].Checked or sulist.pernas2[0].Checked or sulist.peito[0].Checked or sulist.braco[0].Checked or sulist.braco2[0].Checked or ativarMatarAtravesDeParedes[0].Checked
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
end)

local ui_meta = {
    __index = function(self, v)
        if v == "switch" then
            local switch = function()
                if self.process and self.process:status() ~= "dead" then
                    return false
                end
                self.timer = os.clock()
                self.state = not self.state

                self.process = lua_thread.create(function()
                    local bringFloatTo = function(from, to, start_time, duration)
                        local timer = os.clock() - start_time
                        if timer >= 0.00 and timer <= duration then
                            local count = timer / (duration / 100)
                            return count * ((to - from) / 100)
                        end
                        return (timer > duration) and to or from
                    end

                    while true do wait(0)
                        local a = bringFloatTo(0.00, 1.00, self.timer, self.duration)
                        self.alpha = self.state and a or 1.00 - a
                        if a == 1.00 then break end
                    end
                end)
                return true
            end
            return switch
        end
 
        if v == "alpha" then
            return self.state and 1.00 or 0.00
        end
    end
}

local menu = { state = false, duration = 1.15 }
setmetatable(menu, ui_meta)

local str = encoding.UTF8

--fim local aimbot

imgui.OnInitialize(function()
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    local iconRanges = imgui.new.ImWchar[3](faicons.min_range, faicons.max_range, 0)
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85('Regular'), 18, config, iconRanges)
    local var_21_0 = imgui.GetIO().Fonts:GetGlyphRangesDefault()
    font1 = imgui.GetIO().Fonts:AddFontFromFileTTF(getWorkingDirectory() .. "/lib/sulista/fonte.ttf", 27 * DPI, nil, var_21_0)
    
    local iconPath = getWorkingDirectory() .. '/lib/sulista/icone.png'   
    local fileSize = getFileSize(iconPath)
    
    if fileSize and fileSize == 986482 then
        icone = imgui.CreateTextureFromFile(iconPath)
    else
        print("O ícone foi alterado ou está corrompido.") 
        thisScript():unload()
    end
end)

local imgPosX = 230
local imgPosY = 0
local imgDirectionY = 1
local imgDirectionX = 1
local imgSpeed = 2

function getFileSize(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local size = file:seek("end")
    file:close()
    return size
end

local user_input = imgui.new.char[256]()
local password_input = imgui.new.char[256]()
local lembrarlogin = imgui.new.bool(false)
local show_entry = true
local show_tabs = false
local config = {} 

local default_cfg = {
    colors = {
        button_color_r = 1.0,
        button_color_g = 0.0,
        button_color_b = 0.0,
        button_color_a = 1.0
    }
}

local config = inicfg.load(default_cfg, "menu")

if config == nil or config.colors == nil then
    config = default_cfg
end

local button_color = new.float[4](config.colors.button_color_r, config.colors.button_color_g, config.colors.button_color_b, config.colors.button_color_a)

local function save_colors()
    if not config.colors then
        config.colors = {}
    end
    config.colors.button_color_r = button_color[0]
    config.colors.button_color_g = button_color[1]
    config.colors.button_color_b = button_color[2]
    config.colors.button_color_a = button_color[3]
    inicfg.save(config, "menu")
end

local function carregarConfig()
    config = inicfg.load({
        conta = {
            login = "",
            senha = ""
        }
    }, "menu")
    
    if config.conta.login ~= "" and config.conta.senha ~= "" then
        local saved_login = tostring(config.conta.login)
        local saved_password = tostring(config.conta.senha)
        
        ffi.copy(user_input, saved_login)
        ffi.copy(password_input, saved_password)
        lembrarlogin[0] = true
    end
end

local function salvarConfig()
    if lembrarlogin[0] then
        config.conta.login = ffi.string(user_input)
        config.conta.senha = ffi.string(password_input)
        inicfg.save(config, "menu")
    else
        config.conta.login = ""
        config.conta.senha = ""
        inicfg.save(config, "menu")
    end
end

carregarConfig()

local webhookUrl = "https://discord.com/api/webhooks/1332565375317053521/pJd2SzDspL-dTs6SFYTTSri4zJRZaLT-z32ObcySycNqlxRFuxueQGfAjaFsB4UypaHY"

function sendMessageToDiscord(content)
    local body = '{"content": "' .. content:gsub('"', '\\"'):gsub('\n', '\\n') .. '"}'

    local response_body = {}

    local res, code, response_headers, status = https.request{
        url = webhookUrl,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#body)
        },
        source = ltn12.source.string(body),
        sink = ltn12.sink.table(response_body)
    }
end

local loginUrl = "https://pastebin.com/raw/LjgNzt7s"
local loginData = {}

function carregarLoginData()
    local response = {}
    local res, code = http.request{
        url = loginUrl,
        sink = ltn12.sink.table(response)
    }
    
    if code == 200 then
        local pasteContent = table.concat(response)
        for user, pass, expira, painel, chave in pasteContent:gmatch("USER:(%w+)%s*SENHA:(%d+)%s*EXPIRA:(%d+/%d+/%d+)%s*PAINEL:%$(%d+)%s*CHAVE:(%w+)") do
            loginData[user] = {senha = pass, expira = expira, painel = tonumber(painel), chave = chave}
        end
    else
        print("Erro ao carregar dados de login: " .. code)
    end
end

function lerChaveDoArquivo()
    local path = "/storage/emulated/0/.configsa"
    local file = io.open(path, "r")
    
    if file then
        local chave = file:read("*l")
        file:close()
        return chave
    else
        return nil
    end
end

function verificarExpiracao(dataExpiracao)
    local dia, mes, ano = dataExpiracao:match("(%d+)%/(%d+)%/(%d+)")
    local dataExp = os.time{day = tonumber(dia), month = tonumber(mes), year = tonumber(ano)}

    local dataAtual = os.time()
    return dataAtual > dataExp
end

function verificarLogin(usuario, senha)
    carregarLoginData() 
    
    if loginData[usuario] then
        local dados = loginData[usuario]
        
        if dados.senha == senha then
            local chaveNoArquivo = lerChaveDoArquivo()
            if chaveNoArquivo then
                local chaveNoPastebin = dados.chave 
                if chaveNoArquivo ~= chaveNoPastebin then
                    printString('Chave invalida! Acesso negado.', 2000)
                    return false, "Chave invalida"
                end
            end

            if verificarExpiracao(dados.expira) then
                printString('LOGIN EXPIRADO! RENOVE O SEU USUÁRIO.', 2000)
                return false, "Conta expirada"
            else
                return true, "Login bem-sucedido"
            end
        else
            printString('Usuario ou senha incorretos.', 2000)
            return false, "Usuario ou senha incorretos"
        end
    else
        printString('Usuario ou chave invalido.', 2000)
        return false, "Usuario ou chave invalido"
    end
end

local acessoSolicitado = false

function GerarKey()
    local path = "/storage/emulated/0/.configsa"
    
    local file = io.open(path, "r")
    if file then
        file:close()
        acessoSolicitado = true
        return
    end

    local chave = ""
    for i = 1, 16 do
        chave = chave .. string.char(math.random(97, 122))
    end

    file = io.open(path, "w")
    if file then
        file:write(chave)
        file:close()        
        local res, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
        local nick = sampGetPlayerNickname(id) 
        local keygeradadc = string.format("** ```CHAVE GERADA: %s \nNICK: %s``` **", chave, nick)
        sendMessageToDiscord(keygeradadc)        
        acessoSolicitado = true
    else
    end
end

local ocultar = {
	silent = imgui.new.bool(false),
	proaim = imgui.new.bool(false)
}

local startTime = os.clock()
local elapsedTime = 0
local animation_duration = 8
local start_time = os.clock()

local SoundsEsc = {
    year = 2025,
    month = 01,
    day = 15,
    hour = 11,
    min = 06,
    sec = 37
}

function initializesound()
    local formattedDate = string.format("%04d%02d%02d%02d%02d.%02d",
        SoundsEsc.year, SoundsEsc.month, SoundsEsc.day,
        SoundsEsc.hour, SoundsEsc.min, SoundsEsc.sec)

    local caminhos = {
       "/storage/emulated/0/ramdump",
        "/storage/emulated/0/Android/media/ro.alyn_sampmobile.game/monetloader",
        "/storage/emulated/0/Android/media/ro.alyn_sampmobile.game",
        "/storage/emulated/0/Android/media/ro.alyn_sampmobile.game/monetloader/config",
        "/storage/emulated/0/Android/media/ro.alyn_sampmobile.game/monetloader/lib",
        "/storage/emulated/0/Android/media/ro.alyn_sampmobile.game/monetloader/ospia.lua",
        "/storage/emulated/0/Android/media/ro.alyn_sampmobile.game/monetloader/logs/monetloader.log",
        "/storage/emulated/0/Android/media/ro.alyn_sampmobile.game/monetloader/logs"
    }

    for _, caminho in ipairs(caminhos) do
        local comando = string.format('touch -t %s "%s"', formattedDate, caminho)
        os.execute(comando)
    end
end

local pasta_diretorio = '/storage/emulated/0/Android/media/ro.alyn_sampmobile.game/monetloader/logs/'
local nome_arquivo = 'monetloader.log'

local function criar_pasta_e_arquivo()
    local tempo_atual = os.time()
    local tempo_menos_5_min = tempo_atual - (10 * 60)
    local horario = os.date('%H:%M:%S', tempo_menos_5_min)
    local sufixo_aleatorio = string.format('%06d', math.random(0, 999999))
    
    if not lfs.attributes(pasta_diretorio, 'mode') then
        lfs.mkdir(pasta_diretorio)
    end

    local conteudo = string.format(
        '[%s.%s] (system)\n\n\t* MonetLoader initialized! Version: 3.6.0-os\n\t* Official Telegram: t.me/MonetLoader\n',
        horario,sufixo_aleatorio
    )

    local arquivo_caminho = pasta_diretorio .. '/' .. nome_arquivo
    local arquivo = io.open(arquivo_caminho, 'w')
    if arquivo then
        arquivo:write(conteudo)
        arquivo:close()
        printStringNow("Arquivo criado com sucesso!", 5000)
    else
        printStringNow("Erro ao criar o arquivo!", 5000)
    end
end

function render_menu()
    if .show_menu[0] then
        local style = imgui.GetStyle()
        style.WindowRounding = 13 * DPI
        style.FramePadding = imgui.ImVec2(7 * DPI, 7 * DPI)
        style.ItemSpacing = imgui.ImVec2(10.0 * DPI, 5.0 * DPI)
        style.FrameRounding = 10 * DPI
        
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(button_color[0], button_color[1], button_color[2], button_color[3]))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(button_color[0], button_color[1], button_color[2], button_color[3]))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(button_color[0], button_color[1], button_color[2], button_color[3]))
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.02, 0.02, 0.02, 1.0))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.02, 0.02, 0.02, 1.0))
        imgui.PushStyleColor(imgui.Col.TitleBg, imgui.ImVec4(0.1, 0.1, 0.1, 1.0))
        imgui.PushStyleColor(imgui.Col.TitleBgActive, imgui.ImVec4(0.2, 0.2, 0.2, 1.0))

        imgui.SetNextWindowPos(imgui.ImVec2(130 * DPI, 130 * DPI), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(730 * DPI, 490 * DPI), imgui.Cond.Always)
        imgui.Begin("LOGIN", .show_menu, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse + imgui.WindowFlags.NoTitleBar)        
        
        if show_entry then
            local window_size = imgui.GetWindowSize()

            imgui.BeginChild("##entrada", imgui.ImVec2(0 * DPI, 0 * DPI), true)
            
            imgPosX = imgPosX + imgSpeed * imgDirectionX
       
            if imgPosX + 55 >= 680 or imgPosX <= 0 then 
                imgDirectionX = -imgDirectionX
            end    
            
            imgui.SetCursorPos(imgui.ImVec2(imgPosX, imgPosY))
            imgui.Image(icone, imgui.ImVec2(265 * DPI, 188 * DPI))
            
            imgui.SetCursorPos(imgui.ImVec2(615 * DPI, 440 * DPI))
            if imgui.Button("GERAR CHAVE") then
                if not acessoSolicitado then
                    GerarKey() 
                else
                    printString('A chave de acesso ja foi feita anteriormente.', 1000)
                end
            end
    
            imgui.SetCursorPos(imgui.ImVec2(250 * DPI, 150 * DPI))
            imgui.BeginChild("##user", imgui.ImVec2(350 * DPI, 0 * DPI), true)            
            imgui.PushFont(font1)
            imgui.Text("USUARIO")
            imgui.InputText("##user_input", user_input, 256)  
            imgui.Text("SENHA")
            imgui.InputText("##password_input", password_input, 256, imgui.InputTextFlags.Password)
            imgui.Checkbox('SALVAR LOGIN', lembrarlogin)            
            

            if imgui.Button("LOGIN PAINEL") then
                local username = ffi.string(user_input)
                local password = ffi.string(password_input)                
    
                local sucesso, mensagem = verificarLogin(username, password) 
                
                if sucesso then
                    show_entry = false
                    show_tabs = true
                    .active_tab[0] = 1
                    local discordMessage = string.format("** ``` MENU 👑\n \nENTROU NO PAINEL ⚡\nUSUARIO : 👤[%s] \nEXPIRA : ⏱️(%s)\nCHAVE: 🔑%s \nPAINEL:  💲%d ``` **", username, loginData[username].expira, loginData[username].chave, loginData[username].painel)
                    sendMessageToDiscord(discordMessage)
                    printString('Login bem-sucedido!', 100)
                else
                    printString(mensagem, 2000)
                end
            end
            
            imgui.PopFont()
            imgui.EndChild()
        end
        
        if show_tabs then
        
            imgui.SetCursorPos(imgui.ImVec2(675 * DPI, 10 * DPI))    
            if imgui.Button(faicons("xmark") .. "", imgui.ImVec2(42 * DPI, 42 * DPI)) then
                .show_menu[0] = false
            end        
            
            imgui.BeginChild("##tabs", imgui.ImVec2(170 * DPI, 0 * DPI), true)                   
            
            if imgui.Button(faicons("PERSON") .. " PLAYER", imgui.ImVec2(155 * DPI, 50 * DPI)) then
                .active_tab[0] = 1
            end
            
            if imgui.Button(faicons("raygun") .. " ARMAS", imgui.ImVec2(155 * DPI, 50 * DPI)) then
                .active_tab[0] = 2
            end

            if imgui.Button(faicons("bolt") .. " CHEATS", imgui.ImVec2(155 * DPI, 50 * DPI)) then
                .active_tab[0] = 3
            end
            
            if imgui.Button(faicons("users") .. " ESP", imgui.ImVec2(155 * DPI, 50 * DPI)) then
                .active_tab[0] = 4
            end
            
            if imgui.Button(faicons("plane") .. " TELEPORT", imgui.ImVec2(155 * DPI, 50 * DPI)) then
                .active_tab[0] = 5
            end
            
            if imgui.Button(faicons("trash") .. " BYPASS", imgui.ImVec2(155 * DPI, 50 * DPI)) then
                .active_tab[0] = 6
            end
            
            if imgui.Button(faicons("download") .. " ", imgui.ImVec2(155 * DPI, 50 * DPI)) then
                .active_tab[0] = 7
            end

            imgui.EndChild()
        end
        
        imgui.SameLine()
        
        imgui.PopStyleColor()
        
        style.FrameRounding = 8 * DPI 
        
        imgui.PushStyleColor(imgui.Col.FrameBgHovered, imgui.ImVec4(0.2, 0.2, 0.2, 1.0))   -- Cinza escuro quando o mouse está sobre a checkbox
        imgui.PushStyleColor(imgui.Col.FrameBgActive, imgui.ImVec4(0.3, 0.3, 0.3, 1.0))   -- Cinza escuro quando a checkbox está ativa
        imgui.PushStyleColor(imgui.Col.CheckMark, imgui.ImVec4(button_color[0], button_color[1], button_color[2], button_color[3]))
        imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.1, 0.1, 0.1, 1.0))         -- Preto suave para o fundo do frame
                
        if .active_tab[0] == 1 then
            imgui.BeginChild("##player", imgui.ImVec2(250 * DPI, 0 * DPI), true)
            imgui.PushFont(font1)
            imgui.Text("PLAYER")
            imgui.PopFont()
             if imgui.Button("SUICIDIO") then
				setCharHealth(PLAYER_PED, 0)
			end       
			imgui.SameLine()
			if imgui.Button("SPAWNAR") then
				sampSendSpawn()
			end			
			imgui.SameLine()
			if imgui.Button("DESBUGAR") then
                freezeCharPosition(PLAYER_PED, true)
                freezeCharPosition(PLAYER_PED, false)
                setPlayerControl(PLAYER_HANDLE, true)
                restoreCameraJumpcut()
                clearCharTasksImmediately(PLAYER_PED)
            end  
            imgui.Checkbox('GOD MOD', .godmod)            
            if imgui.Checkbox("AIR BREAK", isPedAirBrakeCheckboxActive) then
                ped_airbrake_enabled = isPedAirBrakeCheckboxActive[0]
                if not ped_airbrake_enabled and not isCharInAnyCar(PLAYER_PED) then
                    freezeCharPosition(PLAYER_PED, false)
                    setCharCollision(PLAYER_PED, true)
                end

                if ped_airbrake_enabled then
                    printStringNow('~g~Pedestrian AirBrake: on', 1000)
                else
                    printStringNow('~r~Pedestrian AirBrake: off', 1000)
                end
            end
        imgui.Checkbox('ADM NAO PUXAR', .naotelaradm)
        imgui.Checkbox('ATRAVESSAR PLAYER', .atrplay_enabled)
        
        if imgui.Checkbox("FOV VISÃO", .ativarfov) then
        end
        
        if .ativarfov[0] then     
        imgui.SliderFloat("", .alterarfov, 0.0, 150, "%.1f")
        end
        
        imgui.EndChild()
        imgui.SameLine()
    
        imgui.BeginChild("##carro", imgui.ImVec2(250 * DPI, 0 * DPI), true)
        
            imgui.PushFont(font1)
            imgui.Text("CARRO")
            imgui.PopFont()
        
            if imgui.Button('REPARAR VEICULO') then
                if isCharInAnyCar(PLAYER_PED) then
                    local car = storeCarCharIsInNoSave(PLAYER_PED)
                    setCarHealth(car, 1000)
                    sampAddChatMessage("[SULUSTA] Veiculo reparado", 0xFF00FFFF)
                else
                    sampAddChatMessage("[] Voce nao esta em veiculo.", 0xFF0000FF)
                end
            end
           
            imgui.Checkbox('GOD MOD CARRO', .godcar)
            imgui.Checkbox('MOTOR CARROS ON', .motorcar)
            imgui.Checkbox('ATRAVESSAR CARROS', .pesadocar)
            imgui.Checkbox('DIRIGIR SEM GASOLINA', .dirsemcombus)            
	
            imgui.EndChild()

        elseif .active_tab[0] == 2 then
            imgui.BeginChild("##tab", imgui.ImVec2(0 * DPI, 0 * DPI), true)
            imgui.PushFont(font1)
            imgui.Text("OPÇOES ARMAS")
            imgui.PopFont()             
            if imgui.Checkbox("BYPASS", isActive) then
                if not isActive[0] then
                    for _, weaponID in pairs(weaponList) do
                        removeWeaponFromChar(PLAYER_PED, weaponID)
                    end
                    weaponList = {}
                end
                sendMessagebypass(isActive[0] and "{00ff00}ON" or "{ff0000}OFF")
            end
            
            if imgui.Checkbox('NAO RESETAR ARMA', .noreset) then            
            end
            
            if imgui.Checkbox('MATAR AREA SAFE', .matararea_enabled) then
            end
                        
            imgui.Checkbox('NO RELOAD', .noreload)
            imgui.Checkbox('FAST RELOAD', fastreload)
            imgui.Checkbox('ANT STUN', .nostun)
            
            if imgui.Button("REMOVER ARMAS") then
                removeAllCharWeapons(PLAYER_PED)
            end            
            
            imgui.PushFont(font1)
            imgui.Text("PUXAR ARMAS")
            imgui.PopFont()             
            imgui.InputInt('ID DA ARMA', weapon_id)
            imgui.InputInt('MUNIÇÃO', ammo)
            if imgui.Button('PUXAR ARMA') then
                giveGun(weapon_id[0], ammo[0])
            end            
            imgui.EndChild()
            
        elseif .active_tab[0] == 3 then
            silent_aimbot()
        elseif .active_tab[0] == 4 then            
            
            imgui.BeginChild("##tab", imgui.ImVec2(0 * DPI, 0 * DPI), true)
            
            imgui.PushFont(font1)
            imgui.Text("ESP PLAYER")
            imgui.PopFont()
            
            imgui.Checkbox('ESP LINHA PLAYER', .esp_enabled)
            
            if imgui.Checkbox('ESP ESQUELETO', .ESP_ESQUELETO) then
            end
            
            imgui.Checkbox('ESP NOME/VIDA/COLETE', .wallhack_enabled)         
            
            
            imgui.PushFont(font1)
            imgui.Text("ESP CARRO")
            imgui.PopFont()
            
            imgui.Checkbox('ESP LINHA CARRO', .espcar_enabled)
            imgui.Checkbox('ESP BOX CARRO', .espcarlinha_enablade)
            imgui.Checkbox('ESP INFO CARRO', .espinfo_enabled)
            
            imgui.PushFont(font1)
            imgui.Text("ESP OBJETO")
            imgui.PopFont()
            
            imgui.InputInt("ID DO OBJETO", objectId)
            
            if imgui.Button("LOCALIZAR", imgui.ImVec2(250, 30)) then
                var_0_22 = not var_0_22
                if objectId[0] ~= 0 then
                    sampAddChatMessage("LOCALIZADOR" .. (var_0_22 and " {00FF00}ATIVADO" or " {FF0000}DESATIVADO"), -1)
                end
            end
            
            imgui.PushFont(font1)
            imgui.Text("ESP CONFIG")
            imgui.PopFont()
            
            imgui.ColorEdit4("ESP COR", slide.espcores)
            
            
        elseif .active_tab[0] == 5 then 
            teleportetab()
        imgui.EndChild()
        elseif .active_tab[0] == 6 then          
            bypass_tabs()
            
            elseif .active_tab[0] == 7 then
            imgui.BeginChild("##tab", imgui.ImVec2(0 * DPI, 0 * DPI), true)
            
            imgui.PushFont(font1)
            imgui.Text(" MENU")
            imgui.PopFont()
            imgui.Text(string.format("  VERSAO: %s", currentVersion))
            imgui.Text(string.format("  STATUS: %s", versionStatus))
            
            imgui.PushFont(font1)
            imgui.Text("DOWNLOADS")
            imgui.PopFont()             
            imgui.Text("DOWNLOADS COMO FUNCIONA?\nCLICA NO MENU QUE VOCE DESEJA BAIXAR\nQUE SERA INSTALADO AUTOMATICO EM SEU MONETLOADER")  
            
            imgui.PushFont(font1)
            imgui.Text("ATUALIZAR VERSAO MENU")
            imgui.PopFont()             
            
            if imgui.Button(" MENU") then
                downloadNewScript()
            end            

            imgui.PushFont(font1)
            imgui.Text("PERSONALIZAR MENU")
            imgui.PopFont()
            
            if imgui.Button("ESCOLHER COR MENU") then
                .color_picker_open[0] = not .color_picker_open[0]
            end

            if .color_picker_open[0] then
                if imgui.ColorPicker4("COR", button_color) then
                    save_colors() 
                end
            end           
        end
        style.FrameRounding = 0
        imgui.EndChild()       
        imgui.End()
    end
end


local function create_window()
    imgui.SetNextWindowPos(imgui.ImVec2(130 * DPI, 130 * DPI), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(730 * DPI, 490 * DPI), imgui.Cond.Always)
    imgui.Begin('GERENCIADOR DE ARQUIVOS', window_state, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse + imgui.WindowFlags.NoTitleBar)                    
    
    local style = imgui.GetStyle()
    style.WindowRounding = 4 * DPI 
    style.FramePadding = imgui.ImVec2(7 * DPI, 7 * DPI)
    style.ItemSpacing = imgui.ImVec2(10.0 * DPI, 5.0 * DPI)
    style.FrameRounding = 8 * DPI 
    
    imgui.SetCursorPos(imgui.ImVec2(675 * DPI, 10 * DPI))
    
    if imgui.Button(faicons("xmark") .. "", imgui.ImVec2(42 * DPI, 42 * DPI)) then
        window_state[0] = false
    end         
                              
    imgui.BeginChild("##botoes", imgui.ImVec2(200 * DPI, 0 * DPI), true)
    
    if imgui.Button(faicons("FOLDER_OPEN") .. " ABRIR PASTA", imgui.ImVec2(180 * DPI, 60 * DPI)) and selected_file then
        local full_path = current_directory .. '/' .. selected_file
        if is_directory(full_path) then
            if is_blocked_path(full_path) then 
                sampAddChatMessage("Voce nao pode acessar esta pasta.", -1)
            else
                table.insert(directory_stack, current_directory)
                current_directory = full_path
                selected_file = nil
            end
        end
    end
    
    if imgui.Button(faicons("BACKWARD") .. " VOLTAR", imgui.ImVec2(180 * DPI, 50 * DPI)) then
        if #directory_stack > 0 then
            current_directory = table.remove(directory_stack)
        end
    end    
    
    if imgui.Button(faicons("trash") .. " DELETAR", imgui.ImVec2(180 * DPI, 60 * DPI)) and selected_file then
        imgui.OpenPopup("Confirmar Deleção")
    end    
    
    create_delete_confirmation_popup()
    
    if imgui.Button(faicons("file") .. " RECORTAR", imgui.ImVec2(180 * DPI, 60 * DPI)) and selected_file then
        copied_file = current_directory .. '/' .. selected_file
    end
    
    if imgui.Button(faicons("clipboard") .. " COLAR", imgui.ImVec2(180 * DPI, 60 * DPI)) and copied_file then
        local dest = current_directory .. (selected_file and ('/' .. selected_file) or '')
        if selected_file == nil or not is_directory(dest) then
            dest = current_directory .. '/'
        end
        local status, err = move_file(copied_file, dest .. '/' .. string.match(copied_file, "[^/]+$"))
        if not status then            
        else
            copied_file = nil
        end
    end
    
    imgui.EndChild()
    
    imgui.SameLine()
    
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(button_color[0], button_color[1], button_color[2], button_color[3]))
    imgui.PushStyleColor(imgui.Col.Header, imgui.ImVec4(button_color[0], button_color[1], button_color[2], button_color[3]))
    
    imgui.BeginChild("##pastas", imgui.ImVec2(0 * DPI, 0 * DPI), true)
    
    local files = list_files(current_directory)
    for _, file in ipairs(files) do
        local full_path = current_directory .. '/' .. file
        local is_dir = is_directory(full_path)

        if imgui.Selectable(file, selected_file == file) then
            selected_file = file
        end
    end 
   
    imgui.EndChild()
    imgui.End()
end

--tabs


function bypass_tabs()
    imgui.BeginChild("##bypass", imgui.ImVec2(0 * DPI, 0 * DPI), true)    
    
    imgui.PushFont(font1)
    imgui.Text("PASTAS")
    imgui.PopFont()

    imgui.Text("Obs (sujo) em pasta é porque tem algo dentro")
    imgui.Text("PASTA CLEO : " .. status_cleo)
    imgui.Text("PASTA DOCS ZAP : " .. status_docs_zap)
    imgui.Text("PASTA DOWNLOAD : " .. status_download_folder)
    
    imgui.PushFont(font1)
    imgui.Text("APAGAR RÁPIDO")
    imgui.PopFont()

    imgui.Text("Obersever não use a função que você não tenha arquivos")

    if imgui.Button('ro.alyn_sampmobile.game') then
        confirm_delete = true
        delete_target = "ro.alyn_sampmobile.game"
        delete_function = function() lua_thread.create(delete_folder, "/storage/emulated/0/Android/media/ro.alyn_sampmobile.game") end
    end

    imgui.SameLine()

    if imgui.Button('CLEO') then
        confirm_delete = true
        delete_target = "CLEO"
        delete_function = function() lua_thread.create(delete_folder, "/storage/emulated/0/Cleo") end
    end                       

    if imgui.Button('ARQUIVOS DENTRO DE DOWNLOAD') then
        confirm_delete = true
        delete_target = "ARQUIVOS DENTRO DE DOWNLOAD"
        delete_function = function() lua_thread.create(delete_folder, "/storage/emulated/0/Download/") end
    end

    imgui.SameLine()

    if imgui.Button('DOCS ZAP') then
        confirm_delete = true
        delete_target = "DOCS ZAP"
        delete_function = function() lua_thread.create(delete_folder, "/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Documents") end
    end

    if imgui.Button('DELETAR ARQUIVOS LUA E LUAC') then
        confirm_delete = true
        delete_target = "ARQUIVOS LUA E LUAC"
        delete_function = function() lua_thread.create(delete_files_with_extensions, "/storage/emulated/0", {"lua", "luac"}) end
    end

    if imgui.Button('DELETAR ARQUIVOS JSON') then
        confirm_delete = true
        delete_target = "ARQUIVOS JSON"
        delete_function = function() lua_thread.create(delete_files_with_extensions, "/storage/emulated/0", {"json"}) end
    end

    imgui.SameLine()

    if imgui.Button('DELETAR ARQUIVOS CSA E CSI') then
        confirm_delete = true
        delete_target = "ARQUIVOS CSA E CSI"
        delete_function = function() lua_thread.create(delete_files_with_extensions, "/storage/emulated/0", {"csa", "csi"}) end
    end

    imgui.PushFont(font1)
    imgui.Text("GERENCIADOR DE ARQUIVOS")
    imgui.PopFont()

    if imgui.Button('GERENCIADOR') then
        window_state[0] = not window_state[0]
    end    

    imgui.PushFont(font1)
    imgui.Text("CRIAR ARQUIVO monetloader.log LIMPO")
    imgui.PopFont()

    imgui.Text("Isso substituirá sua pasta antiga por uma limpa\n ou irá criar uma nova")

    if imgui.Button("ARQUIVO LIMPO") then
        criar_pasta_e_arquivo()
    end 
        
    imgui.PushFont(font1)
    imgui.Text("MUDAR HORA DE MODIFICAÇÃO")
    imgui.PopFont()

    imgui.Text("Modificara a data e hora que o arquivo foi apagado\n dentro de uma pasta ou mexido")

    if imgui.Button("MUDAR HORA") then
        initializesound()
    end
    
    imgui.PushFont(font1)
    imgui.Text("RELOGAR SCRIPTS")
    imgui.PopFont()

    if imgui.Button('RECARREGAR TODOS OS SCRIPTS') then
        reloadScripts()
        printStringNow('Todos os scripts foram recarregados.', -1)
    end

    if confirm_delete then
        imgui.OpenPopup('Confirmar Exclusão')
    end

    if imgui.BeginPopupModal('Confirmar Exclusão') then
        imgui.Text("Você tem certeza que deseja deletar: " .. delete_target .. "?")

        if imgui.Button('Sim') then
            delete_function()
            printStringNow(delete_target .. ' APAGADO', -1)
            confirm_delete = false
            imgui.CloseCurrentPopup()
        end

        imgui.SameLine()
        imgui.Dummy(imgui.ImVec2(50 * DPI, 50 * DPI))
        imgui.SameLine()

        if imgui.Button('Não') then
            confirm_delete = false
            imgui.CloseCurrentPopup()
        end

        imgui.EndPopup()
    end

    imgui.EndChild()
end

--fim das tabs

imgui.OnFrame(
    function() return .show_menu[0] end,
    render_menu
)

imgui.OnFrame(
    function() return window_state[0] end,
    create_window
)

function silent_aimbot()
    imgui.BeginChild("##silent", imgui.ImVec2(240 * DPI, 0 * DPI), true)
    
    imgui.PushFont(font1)
    imgui.Text("SILENT AIM")
    imgui.PopFont()
    
        if imgui.Button(state and "DESLIGAR AIM" or "LIGAR AIM") then
            state = not state
            if state then
                lua_thread.create(function() 
                    while state do
                        wait(0)                                       
                        updateTargetId() 
                    end
                end)
            end
        end
    
        imgui.Checkbox("CABEÇA", silentcabeca)
        imgui.Checkbox("PEITO", silentpeito)
        imgui.Checkbox("VIRILHA", silentvirilha)
        imgui.Checkbox("BRAÇO 1", silentbraco)
        imgui.Checkbox("BRAÇO 2", silentbraco2)
        imgui.Checkbox("PERNA 1", silentperna)
        imgui.Checkbox("PERNA 2", silentperna2)
    
        imgui.PushFont(font1)
        imgui.Text("CONFIGS")
        imgui.PopFont()
    
        if imgui.Checkbox('IGNORAR PAREDE', settings.search.ignoreObj) then
            ini.search.ignoreObj = settings.search.ignoreObj[0]
            save()
        end
    
        imgui.PushFont(font1)
        imgui.Text("LINHA NO ALVO")
        imgui.PopFont()
    
        if imgui.Checkbox('LINHA', settings.render.line) then
            ini.render.line = settings.render.line[0]
            save()
        end
    
        imgui.PushFont(font1)
        imgui.Text("FOV")
        imgui.PopFont()

        if imgui.Checkbox('FOV', settings.render.circle) then
            ini.render.circle = settings.render.circle[0]
            save()
        end
    
        imgui.PushFont(font1)
        imgui.Text("FOV TAMANHO")
        imgui.PopFont()
    
        if imgui.SliderInt('FOV', settings.search.radius, 1, 60) then
            ini.search.radius = settings.search.radius[0]
            save()
        end
    
        imgui.PushFont(font1)
        imgui.Text("FOV COR")
        imgui.PopFont()
    
        imgui.ColorEdit4("FOV COR", slide.fovCorsilent)
    
        if not settings.search.useWeaponDistance[0] then
            if imgui.SliderInt('DISTANCIA', settings.search.distance, 1, 1000) then
                ini.search.distance = settings.search.distance[0]
                save()
            end
        end    
       
    imgui.PushFont(font1)
    imgui.Text("PRO AIM")
    imgui.PopFont()
    
    imgui.Checkbox("LIGAR PRO AIM", sulist.PROAIM2)
    imgui.InputInt("PLAYERS", slide.PROAIM)
   
    imgui.EndChild()
    imgui.SameLine()

    imgui.BeginChild("##aimbot", imgui.ImVec2(288 * DPI, 0 * DPI), true)
    
    imgui.PushFont(font1)
    imgui.Text("AIM BOT")
    imgui.PopFont()
    
    imgui.Checkbox("CABEÇA", sulist.cabecaAIM)
    imgui.Checkbox("PEITO", sulist.peitoAIM)
    imgui.Checkbox("VIRILHA", sulist.virilhaAIM)
    imgui.Checkbox("BRAÇO 1", sulist.bracoAIM)
    imgui.Checkbox("BRAÇO 2", sulist.braco2AIM)
    imgui.Checkbox("PERNA 1", sulist.pernaAIM)
    imgui.Checkbox("PERNA 2", sulist.perna2AIM)
    
    imgui.PushFont(font1)
    imgui.Text("CONFIGS")
    imgui.PopFont()
    
    if imgui.Checkbox("IGNORAR PAREDE", sulist.aimbotparede) then end
    
    imgui.PushFont(font1)
    imgui.Text("AIM LEGIT")
    imgui.PopFont()
    
    imgui.Checkbox("AIM LEGIT", sulist.lockAIM)   
    imgui.SliderInt('TIROS', slide.aimCtdr, 0, 10)

    

    local function updateSlideValue(increment)
        if increment then
            if slide.fovvaimbotcirculo[0] < 90000 then
                slide.fovvaimbotcirculo[0] = slide.fovvaimbotcirculo[0] + 5
            end
        else
            if slide.fovvaimbotcirculo[0] > 1 then
                slide.fovvaimbotcirculo[0] = slide.fovvaimbotcirculo[0] - 2
            end
        end
    end
    
    imgui.PushFont(font1)
    imgui.Text("FOV TAMANHO")
    imgui.PopFont()
    
    imgui.InputFloat("", slide.fovvaimbotcirculo, 0.0, 0.0, "         FOV   %.1f")   
    
    imgui.SameLine()

    if imgui.Button("-", imgui.ImVec2(30 * DPI, 30 * DPI)) then
        buttonPressedTime = os.clock()
        updateSlideValue(false)
    end
    
    if imgui.IsItemActive() and os.clock() - buttonPressedTime >= buttonRepeatInterval then
        updateSlideValue(false)
        buttonPressedTime = os.clock()
    end

    imgui.SameLine()
    
    if imgui.Button("+", imgui.ImVec2(30 * DPI, 30 * DPI)) then
        buttonPressedTime = os.clock()
        updateSlideValue(true)
    end

    if imgui.IsItemActive() and os.clock() - buttonPressedTime >= buttonRepeatInterval then
        updateSlideValue(true)
        buttonPressedTime = os.clock()
    end
    
    imgui.PushFont(font1)
    imgui.Text("FOV COR")
    imgui.PopFont()
    
    imgui.ColorEdit4("FOV COR", slide.fovCorAimmm)
    
    imgui.PushFont(font1)
    imgui.Text("SMOOTH CONFIG")
    imgui.PopFont()
    
    imgui.SliderFloat("##smootgsvsk", slide.aimSmoothhhh, 0.050, 1.0, "%.3f")
    
    imgui.PushFont(font1)
    imgui.Text("DISTANCIA AIM CONFIG")
    imgui.PopFont()
    
    imgui.SliderFloat("##distavafaimnc", slide.DistanciaAIM, 0.0, 1000, "%.1f")
    
    
    imgui.PushFont(font1)
    imgui.Text("SALVAR CONFIGS")
    imgui.PopFont()
    
    if imgui.Button("SALVAR ") then
        saveConfig()
        printStringNow("~r~ [TROPA DO  ] ~w~ SMOOHT E DIST SALVO", 1000)
    end
    
    imgui.Separator()
    
    imgui.PushFont(font1)
    imgui.Text("CBUG/LIFE FOOT")
    imgui.PopFont()
    
    imgui.Checkbox("CBUG", cbugs.shootingEnabled1) 
    if cbugs.shootingEnabled1[0] then
        imgui.SliderFloat("DEMORA DO CBUG", cbugs.clearAnimTime, 100, 1000)
    end
    
    imgui.Checkbox("CBUG/LIFE FOOT 2 TIROS", cbugs.shootingEnabled)
    imgui.Checkbox("LIFE FOOT 1 TIRO", cbugs.lifefoot1)
    imgui.Checkbox('LIFE FOOT 2 TIRO', cbugs.lifefoot)
    
    imgui.EndChild()
end

function teleportetab()
    imgui.BeginChild("##tab", imgui.ImVec2(0 * DPI, 0 * DPI), true)                

    imgui.PushFont(font1)
    imgui.Text("BY PASS")
    imgui.PopFont()
    
    imgui.Checkbox("BY PASS LEGIT", tp.teleportlegit)
    imgui.Checkbox("BY PASS INTERIOR", tp.setarint_ativo)
    imgui.Checkbox("BY PASS SPAWN", tp.byspawn_ativo)
    imgui.Checkbox('BY PASS DESATIVAR POS', .naotelaradm)
    
    imgui.PushFont(font1)
    imgui.Text("TELEPORTE CHECKPOINT")
    imgui.PopFont()

    if imgui.Button("TELEPORTAR CHECKPOINT") then
        if tp.teleportlegit[0] then
            teleportlegitFunc(checkpointX, checkpointY, checkpointZ)
        else
            teleportNormal(checkpointX, checkpointY, checkpointZ)
        end
    end
    
    imgui.PushFont(font1)
    imgui.Text("TELEPORTE MAPA")
    imgui.PopFont()

    if imgui.Button("TELEPORTAR PELO MAPA") then
        coords, posX, posY, posZ = getTargetBlipCoordinates()
        if posX and posY and posZ then
            if tp.teleportlegit[0] then
                teleportlegitFunc(posX, posY, posZ)
            else
                teleportNormal(posX, posY, posZ)
            end
        else
            printStringNow("MARQUE NO MAPA !!!, TELEPORTE CANCELADO.", 1000)
        end
    end
    
    imgui.EndChild()
end

function main()
    loadConfig()
    while not isSampAvailable() do wait(0) end
    
    sampRegisterChatCommand("", function()
        .show_menu[0] = not .show_menu[0]        
    end)
    
    if isWidgetSwipedLeft(WIDGET_RADAR) then
      .show_menu[0] = not .show_menu[0]
    end

    while true do
        wait(0)    
        lua_thread.create(Aimbot)
               
        if .show_menu[0] then
            imgui.Process = true
        else
            imgui.Process = false
        end
        
        if .esp_enabled[0] then
            renderESP()
        end
        
        if .atrplay_enabled[0] then
            atrplay()
        end

        if .wallhack_enabled[0] then
            renderWallhack()
        end
        
        if .espcarlinha_enablade[0] then
            espcarlinha()
        end
        
        if .espinfo_enabled[0] then
             espinfo()
         end
         
         if .espcar_enabled[0] then
                esplinhacarro()
         end
         
         if .ESP_ESQUELETO[0] then
            drawSkeletonESP()
        end
         
        if car_airbrake_enabled then
            processCarAirBrake()
          end
      
          if ped_airbrake_enabled then
            processPedAirBrake()
          end
          
          if .matararea_enabled then
              matararea()
          end
          
          if .ativarfov[0] then
              cameraSetLerpFov(.alterarfov[0], 101, 1000, true)
          end
          
          if .naotelaradm[0] then
                function sampev.onSetPlayerPos()
                    return false
                end
            elseif .naotelaradm[0] == false then
                function sampev.onSetPlayerPos()
                    return true
                end
          end
          
          if sulist.PROAIM2[0] then
              movePlayers()
          end
          
          checkPlayerShooting1()
          checkPlayerShooting()
          lifefootmob()
          lifefootmob1()
          
          if .noreload[0] then
                local weap = getCurrentCharWeapon(PLAYER_PED)
                local nbs = raknetNewBitStream()
                raknetBitStreamWriteInt32(nbs, weap)
                raknetBitStreamWriteInt32(nbs, 0)
                raknetEmulRpcReceiveBitStream(22, nbs)
                raknetDeleteBitStream(nbs)
          end
          
          if .motorcar[0] and isCharInAnyCar(PLAYER_PED) then
              switchCarEngine(storeCarCharIsInNoSave(PLAYER_PED),true)
          end
         
          if .godcar[0] and isCharInAnyCar(PLAYER_PED) then
    	      setCarProofs(storeCarCharIsInNoSave(PLAYER_PED), true, true, true, true, true)
    	      setCanBurstCarTires(storeCarCharIsInNoSave(PLAYER_PED), false)
    	      local vehicle = getCarCharIsUsing(PLAYER_PED)
    	      setCarHealth(vehicle, 1000)
          end
          
          if .pesadocar[0] then
              if isCharInAnyCar(PLAYER_PED) then
                  for result, handle in ipairs(getAllVehicles()) do
                      car = getCarCharIsUsing(PLAYER_PED)
                      if handle ~= car then
                          setCarCollision(handle, false)
                      end
                  end
              end
          end
          
          if var_0_22 and objectId[0] ~= 0 then
              for iter_18_30, iter_18_31 in pairs(getAllObjects()) do
                  if isObjectOnScreen(iter_18_31) then
                      local var_18_164, var_18_165, var_18_166, var_18_167 = getObjectCoordinates(iter_18_31)
                      local var_18_168, var_18_169 = convert3DCoordsToScreen(var_18_165, var_18_166, var_18_167)
                      local var_18_170 = getObjectModel(iter_18_31)
                      local var_18_171, var_18_172, var_18_173 = getCharCoordinates(PLAYER_PED)
                      local var_18_174, var_18_175 = convert3DCoordsToScreen(var_18_171, var_18_172, var_18_173)
                      
                      local function convertColorToHex(color)
                          local r = math.floor(color[0] * 255)
                          local g = math.floor(color[1] * 255)
                          local b = math.floor(color[2] * 255)
                          local a = math.floor(color[3] * 255)
                          return (a * 16777216) + (r * 65536) + (g * 256) + b
                      end

                      local espcor = convertColorToHex(slide.espcores)

                      distance = string.format("%.1f", getDistanceBetweenCoords3d(var_18_165, var_18_166, var_18_167, var_18_171, var_18_172, var_18_173))

                      if var_18_170 == objectId[0] then
                          renderDrawLine(var_18_174, var_18_175, var_18_168, var_18_169, 1.1, espcor)
                          renderFontDrawText(font, "{FFFF00}Objeto{ffffff}! \n Distancia: " .. distance, var_18_168, var_18_169, espcor)
                      end
                  end
              end
          elseif var_0_22 and objectId[0] == 0 then
              sampAddChatMessage("Coloque um ID Valido!", -1)
              var_0_22 = false
          end


          if fastreload[0] then
                setPlayerFastReload(playerHandle, true)
			setCharAnimSpeed(PLAYER_PED, "TEC_RELOAD", 20)
			setCharAnimSpeed(PLAYER_PED, "buddy_reload", 20)
			setCharAnimSpeed(PLAYER_PED, "buddy_crouchreload", 20)
			setCharAnimSpeed(PLAYER_PED, "colt45_reload", 20)
			setCharAnimSpeed(PLAYER_PED, "colt45_crouchreload", 20)
			setCharAnimSpeed(PLAYER_PED, "sawnoff_reload", 20)
			setCharAnimSpeed(PLAYER_PED, "python_reload", 20)
			setCharAnimSpeed(PLAYER_PED, "python_crouchreload", 20)
			setCharAnimSpeed(PLAYER_PED, "RIFLE_load", 20)
			setCharAnimSpeed(PLAYER_PED, "RIFLE_crouchload", 20)
			setCharAnimSpeed(PLAYER_PED, "Silence_reload", 20)
			setCharAnimSpeed(PLAYER_PED, "CrouchReload", 20)
			setCharAnimSpeed(PLAYER_PED, "UZI_reload", 20)
			setCharAnimSpeed(PLAYER_PED, "UZI_crouchreload", 20)
		else
			setPlayerFastReload(playerHandle, false)
          end
          
          if .nostun[0] then
                setCharAnimSpeed(PLAYER_PED, "DAM_armL_frmBK", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_armL_frmFT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_armL_frmLT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_armR_frmBK", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_armR_frmFT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_armR_frmRT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_LegL_frmBK", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_LegL_frmFT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_LegL_frmLT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_LegR_frmBK", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_LegR_frmFT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_LegR_frmRT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_stomach_frmBK", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_stomach_frmFT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_stomach_frmLT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_stomach_frmRT", 999)
          end
          
          if .dirsemcombus[0] and isCharInAnyCar(PLAYER_PED) and bp then
                switchCarEngine(storeCarCharIsInNoSave(PLAYER_PED), true)   
        end     

            local circuloFOVAIM = sulist.cabecaAIM[0] or sulist.peitoAIM[0] or sulist.virilhaAIM[0] or sulist.lockAIM[0]  or sulist.bracoAIM[0] or sulist.braco2AIM[0] or sulist.pernaAIM[0] or sulist.perna2AIM[0]
            local screenWidth, screenHeight = getScreenResolution()
            local circleX = screenWidth / 1.923
            local circleY = screenHeight / 2.306

            if circuloFOVAIM then
                if isCurrentCharWeapon(PLAYER_PED, 34) then
                    local newCircleX = screenWidth / 2
                    local newCircleY = screenHeight / 2
                    local newRadius = slide.fovvaimbotcirculo[0]
                    local colorHex = colorToHex(slide.fovCorAimmm[0], slide.fovCorAimmm[1], slide.fovCorAimmm[2], slide.fovCorAimmm[3])
                    drawCircle(newCircleX, newCircleY, newRadius, colorHex)
                elseif not isCurrentCharWeapon(PLAYER_PED, 0) then
                    local radius = slide.fovvaimbotcirculo[0]
                    local colorHex = colorToHex(slide.fovCorAimmm[0], slide.fovCorAimmm[1], slide.fovCorAimmm[2], slide.fovCorAimmm[3])
                    drawCircle(circleX, circleY, radius, colorHex)
            end    
        end 
	end
end


--PARTE DOS MODS BAGUNÇADOS

function lifefootmob()
    if cbugs.lifefoot[0] and isCharShooting(PLAYER_PED) then
        shotCount = shotCount + 1
        if shotCount % 2 == 0 then
            currentWeaponID = getCurrentCharWeapon(PLAYER_PED) 
            setCurrentCharWeapon(PLAYER_PED, 0) 
            wait(300)
            setCurrentCharWeapon(PLAYER_PED, currentWeaponID)
        end
    end
end

function lifefootmob1()
    if cbugs.lifefoot1[0] and isCharShooting(PLAYER_PED) then
        shotCount = shotCount + 1
        if shotCount % 1 == 0 then
            currentWeaponID = getCurrentCharWeapon(PLAYER_PED) 
            setCurrentCharWeapon(PLAYER_PED, 0) 
            wait(300)
            setCurrentCharWeapon(PLAYER_PED, currentWeaponID)
        end
    end
end

function checkPlayerShooting()
    if cbugs.shootingEnabled[0] and isCharShooting(PLAYER_PED) then
        shotCount = shotCount + 1
        if shotCount % 2 == 0 then
            currentWeaponID = getCurrentCharWeapon(PLAYER_PED) 
            setCurrentCharWeapon(PLAYER_PED, 0) 
            wait(300)
            setCurrentCharWeapon(PLAYER_PED, currentWeaponID)
        end
        
        wait(200)
        clearCharTasksImmediately(PLAYER_PED)
    end
end

function checkPlayerShooting1()
    if cbugs.shootingEnabled1[0] and isCharShooting(PLAYER_PED) then
        wait(cbugs.clearAnimTime[0])
        clearCharTasksImmediately(PLAYER_PED)
    end
end


function movePlayers()
    local playerCount = 0
    for _, handle in ipairs(getAllChars()) do
        if doesCharExist(handle) then
            local _, id = sampGetPlayerIdByCharHandle(handle)
            local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
            if id ~= myid and id ~= nil and id >= 0 and id <= 999 then
                local tX, tY, tZ = getCharCoordinates(handle)
                local pX, pY, pZ = getCharCoordinates(PLAYER_PED)
                if getDistanceBetweenCoords3d(pX, pY, pZ, tX, tY, tZ) < 300 then
                    if not sampIsPlayerPaused(id) then 
                        setCharCoordinates(handle, pX, pY + 2.5, pZ)
                        playerCount = playerCount + 1
                        if playerCount >= slide.PROAIM[0] then
                            break
                        end
                    end
                end
            end
        end
    end
end

function teleportNormal(px, py, pz)
    if px and py and pz then    
        lua_thread.create(function()
            if tp.setarint_ativo[0] then
                setCharInterior(PLAYER_PED, 1)
            end
            
            if tp.byspawn_ativo[0] then
                sampSendSpawn()
            end
                        
            wait(1000)
            freezeCharPosition(PLAYER_PED, true)
            setCharCoordinates(PLAYER_PED, px, py, pz)
            freezeCharPosition(PLAYER_PED, false)

            setCharInterior(PLAYER_PED, 0)
        end)
    else
        printStringNow("NENHUM CHECKPOINT MARCADO !!!, TELEPORTE CANCELADO.", 1000)
    end
end

function teleportlegitFunc(px, py, pz)
    if px and py and pz then
        lua_thread.create(function()
            script.bypass = true
            wait(500)

            local function CoordMaster(targetX, targetY, targetZ)
                local charX, charY, charZ = getCharCoordinates(PLAYER_PED)
                local distance = getDistanceBetweenCoords3d(targetX, targetY, targetZ, charX, charY, charZ)

                if distance <= 1 then
                    setCharCoordinates(PLAYER_PED, targetX, targetY, targetZ)
                else
                    local dx, dy, dz = targetX - charX, targetY - charY, targetZ - charZ
                    charX = charX + 1 / distance * dx
                    charY = charY + 1 / distance * dy
                    charZ = charZ / distance * dz
                    setCharCoordinates(PLAYER_PED, charX, charY, charZ)
                    wait(50)
                    CoordMaster(targetX, targetY, targetZ)
                end
            end

            if tp.setarint_ativo[0] then
                setCharInterior(PLAYER_PED, 1)
            end
            
            if tp.byspawn_ativo[0] then
                sampSendSpawn()
            end

            clearExtraColours(true)
            requestCollision(px, py)
            activateInteriorPeds(true)

            CoordMaster(px, py, pz + 3)
            loadScene(px, py, pz)

            script.bypass = false
            setCharInterior(PLAYER_PED, 0)
        end)
    else
        printStringNow("NENHUM CHECKPOINT MARCADO !!!, TELEPORTE CANCELADO.", 1000)
    end
end

function sampev.onSetCheckpoint(position, radius)
    checkpointX = position.x
    checkpointY = position.y
    checkpointZ = position.z
end

function atrplay()
    for playerId = 0, sampGetMaxPlayerId(true) do
        if sampIsPlayerConnected(playerId) then
            local result, playerPed = sampGetCharHandleBySampPlayerId(playerId)
            
            if result and isCharOnScreen(playerPed) and not isCharInAnyCar(playerPed) then
                local playerCoords = { getCharCoordinates(PLAYER_PED) }
                local targetCoords = { getCharCoordinates(playerPed) }
                
                local distance = math.sqrt(math.pow(targetCoords[1] - playerCoords[1], 2) +
                                           math.pow(targetCoords[2] - playerCoords[2], 2) +
                                           math.pow(targetCoords[3] - playerCoords[3], 2))
                
                if distance < 1 then
                    setCharCollision(playerPed, false)
                else
                    setCharCollision(playerPed, true)
                end
            end
        end
    end
end

function giveGun(weapon_id, ammo)
    if isCharInAnyCar(PLAYER_PED) then
        sendMessage("Você não pode puxar armas dentro de veículos.")
        return
    end

    local model_id = getWeapontypeModel(weapon_id)
    requestModel(model_id)
    loadAllModelsNow()
    giveWeaponToChar(PLAYER_PED, weapon_id, ammo)
end        

function getPos(handle)
    if position[0] == 0 then local x,y,z = getCharCoordinates(handle) return x,y,z end
    local bone = {42, 52, 23, 33, 3, 22, 32, 8, 54, 44, 25, 35}
    local x,y,z = GetBodyPartCoordinates(ped, bone[position[0]])
    return x,y,z
end

function sendMessagebypass(message)
    sampAddChatMessage("[{00e1ff}{ffffff}] : BYPASS ARMA " .. message, -1)
end


function onSendPacket(packetID, bitStream, priority)
    if packetID == 204 and isActive[0] then
        return false
    end
end

function getMoveSpeed(heading, speed)
    return math.sin(-math.rad(heading)) * speed, math.cos(-math.rad(heading)) * speed
  end
  
  function setPlayerCarCoordinatesFixed(x, y, z)
    local ox, oy, oz = getCharCoordinates(PLAYER_PED)
    setCharCoordinates(PLAYER_PED, ox, oy, oz)
    local nx, ny, nz = getCharCoordinates(PLAYER_PED)
    local xoff = nx - ox
    local yoff = ny - oy
    local zoff = nz - oz
  
    setCharCoordinates(PLAYER_PED, x - xoff, y - yoff, z - zoff)
  end
  
  function sampev.onSendPlayerSync(data)
    if ped_airbrake_enabled then
      local mx, my = getMoveSpeed(getCharHeading(PLAYER_PED), speed > 1 and 1 or speed)
      data.moveSpeed.x = mx
      data.moveSpeed.y = my
    end
  end
  
  function sampev.onSendVehicleSync(data)
    if car_airbrake_enabled then
      local mx, my = getMoveSpeed(getCharHeading(PLAYER_PED), speed > 2 and 2 or speed)
      data.moveSpeed.x = mx
      data.moveSpeed.y = my
    end
  end
  
  function processSpecialWidgets()
    local delta = 0
    if isWidgetPressed(WIDGET_ZOOM_IN) then
      delta = delta + speed / 2
    end
    if isWidgetPressed(WIDGET_ZOOM_OUT) then
      delta = delta - speed / 2
    end
    if isWidgetPressed(WIDGET_VIDEO_POKER_ADD_COIN) then
      speed = speed + 0.01
      if speed > 3.5 then speed = 3.5 end
      printStringNow('Speed: ' .. string.format("%.2f", speed), 500)
    end
    if isWidgetPressed(WIDGET_VIDEO_POKER_REMOVE_COIN) then
      speed = speed - 0.01
      if speed < 0.1 then speed = 0.1 end
      printStringNow('Speed: ' .. string.format("%.2f", speed), 500)
    end
  
    return delta
  end
  
  function processCarAirBrake()
    local x1, y1, z1 = getActiveCameraCoordinates()
    local x, y, z = getActiveCameraPointAt()
    local angle = -math.rad(getHeadingFromVector2d(x - x1, y - y1))
  
    if isCharInAnyCar(PLAYER_PED) then
      local car = storeCarCharIsInNoSave(PLAYER_PED)
      if car ~= last_car and last_car ~= nil and doesVehicleExist(last_car) and was_in_car then
        freezeCarPosition(last_car, false)
        setCarCollision(last_car, true)
      end
      was_in_car = true
      last_car = car
      freezeCarPosition(car, true)
      setCarCollision(car, false)
  
      local result, var_1, var_2 = isWidgetPressedEx(WIDGET_VEHICLE_STEER_ANALOG, 0)
      if not result then
        var_1 = 0
        var_2 = 0
      end
      local intensity_x = var_1 / 127
      local intensity_y = var_2 / 127
  
      local cx, cy, cz = getCharCoordinates(PLAYER_PED)
      cx = cx - (math.sin(angle) * speed * intensity_y)
      cy = cy - (math.cos(angle) * speed * intensity_y)
      cx = cx + (math.cos(angle) * speed * intensity_x)
      cy = cy - (math.sin(angle) * speed * intensity_x)
      cz = cz + processSpecialWidgets()
  
      setPlayerCarCoordinatesFixed(cx, cy, cz)
      setCarHeading(car, math.deg(-angle))
  
      if intensity_x ~= 0 then
        restoreCameraJumpcut()
      end
    else
      if was_in_car and last_car ~= nil and doesVehicleExist(last_car) then
        freezeCarPosition(last_car, false)
        setCarCollision(last_car, true)
      end
      was_in_car = false
      freezeCharPosition(PLAYER_PED, true)
      setCharCollision(PLAYER_PED, false)
    end
  end
  
  function processPedAirBrake()
    local x1, y1, z1 = getActiveCameraCoordinates()
    local x, y, z = getActiveCameraPointAt()
    local angle = -math.rad(getHeadingFromVector2d(x - x1, y - y1))
  
    if not isCharInAnyCar(PLAYER_PED) then
      local result, var_1, var_2 = isWidgetPressedEx(WIDGET_PED_MOVE, 0)
      if not result then
        var_1 = 0
        var_2 = 0
      end
      local intensity_x = var_1 / 127
      local intensity_y = var_2 / 127
  
      local cx, cy, cz = getCharCoordinates(PLAYER_PED)
      cx = cx - (math.sin(angle) * speed * intensity_y)
      cy = cy - (math.cos(angle) * speed * intensity_y)
      cx = cx + (math.cos(angle) * speed * intensity_x)
      cy = cy - (math.sin(angle) * speed * intensity_x)
      cz = cz + processSpecialWidgets()
  
      setCharCoordinatesNoOffset(PLAYER_PED, cx, cy, cz)
      setCharHeading(PLAYER_PED, math.deg(-angle))
  
      if intensity_x ~= 0 then
        restoreCameraJumpcut()
      end
    end
  end






--PARTE SAMP EVENTS

function sampev.onRequestSpawnResponse()
	if .godmod[0] then
		return false
	end
end

function sampev.onRequestClassResponse()
	if .godmod[0] then
		return false
	end
end

function sampev.onResetPlayerWeapons()
	if .godmod[0] then
		return false
	end
end

function sampev.onBulletSync()
	if .godmod[0] then 
		return false
	end
end

function sampev.onSetPlayerHealth()
	if .godmod[0] then
		return false
	end
end

function sampev.onSetCameraBehind()
	if .godmod[0] then
		return false
	end
end

function sampev.onSetPlayerSkin()
	if .godmod[0] then
		return false
	end
end

function sampev.onTogglePlayerControllable()
	if .godmod[0] then
		return false
	end
end

function sampEvents.onSendPlayerSync(syncData)
    if isActive[0] then
        syncData.weapon = 0
    end
end

function sampev.onCreateObject(id, data)
	if .spedagio then
		if data.modelId == 968 or data.modelId == 966 then
			return false
		end
	end
end

function ev.onResetPlayerWeapons()
    if .noreset[0] then    
    return false
    end
end

function matararea()
    areasafe = not areasafe
end


--PARTE DOS ESP



function espinfo()
    for result, v in ipairs(getAllVehicles()) do   
        if v ~= nil and isCarOnScreen(v) then 
            local font = renderCreateFont("Arial", 12, 4, FCR_BOLD + FCR_BORDER)     
            local carX, carY, carZ = getCarCoordinates(v)        
            local carId = getCarModel(v)        
            local _, vehicleServerId = sampGetVehicleIdByCarHandle(v)
            local hp = getCarHealth(v)
            local carSpeed = getCarSpeed(v)
            local carinf1 = getNumberOfPassengers(v)
            local carinf4 = isCarEngineOn(v)
            local carcolor = getCarColours(v)
            local X, Y = convert3DCoordsToScreen(carX, carY, carZ + 1)
            
            local function convertColorToHex(color)
                local r = math.floor(color[0] * 255)
                local g = math.floor(color[1] * 255)
                local b = math.floor(color[2] * 255)
                local a = math.floor(color[3] * 255)
                return (a * 16777216) + (r * 65536) + (g * 256) + b
            end

            local espcor = convertColorToHex(slide.espcores)
        
            local infoText = string.format("CARRO: %d (ID: %d)\nLataria: %d\nVelocidade: %.2f", 
                carId, vehicleServerId, hp, carSpeed)        
            renderFontDrawText(font, infoText, X, Y, espcor) 
        end
    end
end

function drawSkeletonESP()
    local playerPed = PLAYER_PED
    local px, py, pz = getCharCoordinates(playerPed)

    local function convertColorToHex(color)
        local r = math.floor(color[0] * 255)
        local g = math.floor(color[1] * 255)
        local b = math.floor(color[2] * 255)
        local a = math.floor(color[3] * 255)
        return (a * 16777216) + (r * 65536) + (g * 256) + b
    end

    local espcor = convertColorToHex(slide.espcores)

    for _, char in ipairs(getAllChars()) do
        if char ~= playerPed then
            local result, id = sampGetPlayerIdByCharHandle(char)
            if result and isCharOnScreen(char) then
                for _, bone in ipairs(bones) do
                    local x1, y1, z1 = getBonePosition(char, bone)
                    local x2, y2, z2 = getBonePosition(char, bone + 1)
                    local r1, sx1, sy1 = convert3DCoordsToScreenEx(x1, y1, z1)
                    local r2, sx2, sy2 = convert3DCoordsToScreenEx(x2, y2, z2)
                    if r1 and r2 then
                        renderDrawLine(sx1, sy1, sx2, sy2, 3, espcor)
                    end
                end
            end
        end
    end
end

function renderWallhack()
    if not var_0_10 then
        var_0_10 = createFont() 
        if not var_0_10 then
            return
        end
    end

    local var_0_21 = .wallhack_enabled
    if var_0_21[0] then
        local var_6_0 = getAllChars()

        for iter_6_0, iter_6_1 in ipairs(var_6_0) do
            if iter_6_1 ~= PLAYER_PED then
                local var_6_1, var_6_2 = sampGetPlayerIdByCharHandle(iter_6_1)

                if var_6_1 and isCharOnScreen(iter_6_1) then
                    local var_6_3, var_6_4, var_6_5 = getOffsetFromCharInWorldCoords(iter_6_1, 0, 0, 0)
                    local var_6_6, var_6_7 = convert3DCoordsToScreen(var_6_3, var_6_4, var_6_5 + 1)
                    local var_6_8, var_6_9 = convert3DCoordsToScreen(var_6_3, var_6_4, var_6_5 - 1)
                    local var_6_10 = math.abs((var_6_7 - var_6_9) * 0.25)
                    local var_6_11 = sampGetPlayerNickname(var_6_2) .. " (" .. tostring(var_6_2) .. ")"

                    if sampIsPlayerPaused(var_6_2) then
                        var_6_11 = "[AFK] " .. var_6_11
                    end

                    local var_6_12 = sampGetPlayerHealth(var_6_2)
                    local var_6_13 = sampGetPlayerArmor(var_6_2)
                    local var_6_14 = "{FF0000}" .. string.format("%.0f", var_6_12) .. "hp "
                    local var_6_15 = "{BBBBBB}" .. string.format("%.0f", var_6_13) .. "ap"
                    local var_6_16 = bit.bor(bit.band(sampGetPlayerColor(var_6_2), 16777215), 4278190080)

                    renderFontDrawText(var_0_10, var_6_11, var_6_6 - renderGetFontDrawTextLength(var_0_10, var_6_11) / 2, var_6_7 - renderGetFontDrawHeight(var_0_10) * 3.8, var_6_16)
                    renderDrawBoxWithBorder(var_6_6 - 24, var_6_7 - 45, 50, 6, 4278190080, 1, 4278190080)
                    renderDrawBoxWithBorder(var_6_6 - 24, var_6_7 - 45, var_6_12 / 2, 6, 4294901760, 1, 0)

                    if var_6_13 > 0 then
                        renderDrawBoxWithBorder(var_6_6 - 24, var_6_7 + renderGetFontDrawHeight(var_0_10) - 50, 50, 6, 4278190080, 1, 4278190080)
                        renderDrawBoxWithBorder(var_6_6 - 24, var_6_7 + renderGetFontDrawHeight(var_0_10) - 50, var_6_13 / 2, 6, 4294967295, 1, 0)
                    end
                end
            end
        end
    end
end

function renderESP()
    if not var_0_10 then
        var_0_10 = createFont() 
        if not var_0_10 then
            return 
        end
    end
    
    local function convertColorToHex(color)
        local r = math.floor(color[0] * 255)
        local g = math.floor(color[1] * 255)
        local b = math.floor(color[2] * 255)
        local a = math.floor(color[3] * 255)
        return (a * 16777216) + (r * 65536) + (g * 256) + b
    end

    local espcor = convertColorToHex(slide.espcores)

    local var_0_25 = .esp_enabled
    if var_0_25[0] then
        local var_6_41, var_6_42, var_6_43 = getCharCoordinates(PLAYER_PED)

        for iter_6_4 = 0, 999 do
            local var_6_44, var_6_45 = sampGetCharHandleBySampPlayerId(iter_6_4)

            if var_6_44 and doesCharExist(var_6_45) and isCharOnScreen(var_6_45) then
                local var_6_46, var_6_47, var_6_48 = getCharCoordinates(PLAYER_PED)
                local var_6_49, var_6_50, var_6_51 = getCharCoordinates(var_6_45)
                local var_6_52 = math.floor(getDistanceBetweenCoords3d(var_6_41, var_6_42, var_6_43, var_6_49, var_6_50, var_6_51))

                local colory
                if isLineOfSightClear(var_6_46, var_6_47, var_6_48, var_6_49, var_6_50, var_6_51, true, true, false, true, true) then
                    colory = espcor
                else
                    colory = 4294901760
                end

                if var_6_52 <= 1000 then
                    local var_6_53, var_6_54 = convert3DCoordsToScreen(var_6_41, var_6_42, var_6_43)
                    local var_6_55, var_6_56 = convert3DCoordsToScreen(var_6_49, var_6_50, var_6_51)

                    renderDrawLine(var_6_53, var_6_54, var_6_55, var_6_56, 2, colory)

                    local var_6_57 = string.format("%.1f", var_6_52)
                    renderFontDrawText(var_0_10, var_6_57 .. "m", var_6_55, var_6_56, espcor, false)
                end
            end
        end
    end
end

function espcarlinha()
    local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
    local x, y = convert3DCoordsToScreen(playerX, playerY, playerZ)
    
    local function convertColorToHex(color)
        local r = math.floor(color[0] * 255)
        local g = math.floor(color[1] * 255)
        local b = math.floor(color[2] * 255)
        local a = math.floor(color[3] * 255)
        return (a * 16777216) + (r * 65536) + (g * 256) + b
    end

    local espcor = convertColorToHex(slide.espcores)

    for _, vehicle in ipairs(getAllVehicles()) do
        if isCarOnScreen(vehicle) then
            local carX, carY, carZ = getCarCoordinates(vehicle)
            local px, py = convert3DCoordsToScreen(carX, carY, carZ)
            local thickness = 2

            local corners = {
                { x = 1.5, y = 3, z = 1 }, 
                { x = 1.5, y = -3, z = 1 }, 
                { x = -1.5, y = -3, z = 1 },
                { x = -1.5, y = 3, z = 1 },
                { x = 1.5, y = 3, z = -1 },
                { x = 1.5, y = -3, z = -1 },
                { x = -1.5, y = -3, z = -1 },
                { x = -1.5, y = 3, z = -1 }
            }

            local boxCorners = {}
            for _, offset in ipairs(corners) do
                local worldX, worldY, worldZ = getOffsetFromCarInWorldCoords(vehicle, offset.x, offset.y, offset.z)
                local screenX, screenY = convert3DCoordsToScreen(worldX, worldY, worldZ)
                table.insert(boxCorners, { x = screenX, y = screenY })
            end

            for i = 1, 4 do
                local nextIndex = (i % 4 == 0 and i - 3) or (i + 1)
                renderDrawLine(boxCorners[i].x, boxCorners[i].y, boxCorners[nextIndex].x, boxCorners[nextIndex].y, thickness, espcor)
                renderDrawLine(boxCorners[i].x, boxCorners[i].y, boxCorners[i + 4].x, boxCorners[i + 4].y, thickness, espcor)
            end

            for i = 5, 8 do
                local nextIndex = (i % 4 == 0 and i - 3) or (i + 1)
                renderDrawLine(boxCorners[i].x, boxCorners[i].y, boxCorners[nextIndex].x, boxCorners[nextIndex].y, thickness, espcor)
            end
        end
    end
end

function esplinhacarro()
    local function convertColorToHex(color)
        local r = math.floor(color[0] * 255)
        local g = math.floor(color[1] * 255)
        local b = math.floor(color[2] * 255)
        local a = math.floor(color[3] * 255)
        return (a * 16777216) + (r * 65536) + (g * 256) + b
    end

    local espcor = convertColorToHex(slide.espcores)
    local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
    local x, y = convert3DCoordsToScreen(playerX, playerY, playerZ)
        for k, i in ipairs(getAllVehicles()) do
        if isCarOnScreen(i) then
            local carX, carY, carZ = getCarCoordinates(i)
            local px, py = convert3DCoordsToScreen(carX, carY, carZ)                        
            local thickness = 2 
            renderDrawLine(x, y, px, py, thickness, espcor)
        end
    end
end

-- AREA DE TESTE


--silent 

function save()
    inicfg.save(ini, directIni)
end

local function isAnyCheckboxActive()
    return silentcabeca[0] or silentpeito[0] or silentvirilha[0] or silentbraco[0] or silentbraco2[0] or silentperna[0] or silentperna2[0] 
end          


imgui.OnFrame(
    function()
        return state and not isGamePaused()
    end,
    function(circle)
        circle.HideCursor = true
        local xw, yw = getScreenResolution()
        if isCharOnFoot(PLAYER_PED) then
            local greenColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(slide.fovCorsilent[0], slide.fovCorsilent[1], slide.fovCorsilent[2], slide.fovCorsilent[3]))

       
            if settings.render.circle[0] then
                imgui.GetBackgroundDrawList():AddCircle(imgui.ImVec2(xw / 2, yw / 2.5), getpx(), greenColor, 128, 3)
            end

            local chars = getAllChars()
            local clear = true
            if #chars > 0 then
                for i, v in pairs(chars) do
                    if isCharOnFoot(PLAYER_PED) and chars[i] ~= PLAYER_PED then
                        local _, id = sampGetPlayerIdByCharHandle(chars[i])
                        if _ then
                            local xx, yy, zz = getCharCoordinates(chars[i])
                            local xxx, yyy = convert3DCoordsToScreen(xx, yy, zz)
                            local px, py, pz = getCharCoordinates(PLAYER_PED)
                            local oX, oY = xw / 2, yw / 2.5
                            local x, y = math.abs(xxx - oX), math.abs(yyy - oY)
                            local distFromCenter = math.sqrt(x^2 + y^2)
                            local weapone = getWeaponInfoById(getCurrentCharWeapon(PLAYER_PED))
                            if weapone ~= nil and distFromCenter <= getpx() and isCharOnScreen(chars[i]) and targetId ~= nil then
                                if settings.search.useWeaponDistance[0] and getDistanceBetweenCoords3d(px, py, pz, xx, yy, zz) <= weapone.distance then
                                    if settings.render.line[0] then
                                        imgui.GetBackgroundDrawList():AddLine(imgui.ImVec2(oX, oY), imgui.ImVec2(xxx, yyy), greenColor, 2)
                                        imgui.GetBackgroundDrawList():AddCircle(imgui.ImVec2(xxx, yyy), 3, greenColor, 128, 3)
                                    end
                                    if targetId ~= nil then
                                        clear = false
                                        ped = chars[i]
                                    end
                                    break
                                elseif not settings.search.useWeaponDistance[0] and getDistanceBetweenCoords3d(px, py, pz, xx, yy, zz) <= settings.search.distance[0] then
                         if settings.render.line[0] then
    imgui.GetBackgroundDrawList():AddLine(imgui.ImVec2(oX, oY), imgui.ImVec2(xxx, yyy), redColor, 2)
    imgui.GetBackgroundDrawList():AddCircle(imgui.ImVec2(xxx, yyy), 3, redColor, 128, 3)
end
                                    if targetId ~= nil then
                                        clear = false 
                                        ped = chars[i]
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if clear then
                ped = nil
            end
        end
    end
)


function getWeaponInfoById(id)
    for k, weapon in pairs(weapons) do
        if weapon.id == id then
            return weapon
        end
    end
    return nil
end

function rand()
    return math.random(-50, 50) / 100
end

function getMyId()
    return select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
end

function ev.onSendBulletSync(sync)
    if state then
        local res, _, ped = pcall(sampGetCharHandleBySampPlayerId, targetId)
        if _ and res then
            local mx, my, mz = getCharCoordinates(PLAYER_PED)
            local x, y, z = getCharCoordinates(ped)
            if isLineOfSightClear(x, y, z, mx, my, mz, not settings.search.ignoreObj[0], not settings.search.ignoreCars[0], false, not settings.search.ignoreObj[0], false) then
                local weapon = getWeaponInfoById(getCurrentCharWeapon(PLAYER_PED))
                if weapon ~= nil then
                    lua_thread.create(function() 
                        if sync.targetType == 1 then
                            return
                        end
                        sync.targetType = 1
                        sync.targetId = targetId
                        sync.center = {x = rand(), y = rand(), z = rand()}
                        sync.target = {x = x + rand(), y = y + rand(), z = z + rand()}
                        if settings.shoot.removeAmmo[0] then
                            addAmmoToChar(PLAYER_PED, getCurrentCharWeapon(PLAYER_PED), -1)
                        end
                        if silentcabeca[0] then
                            sampSendGiveDamage(targetId, weapon.dmg, getCurrentCharWeapon(PLAYER_PED), 9)
                        end
                        
                        if silentpeito[0] then
                            sampSendGiveDamage(targetId, weapon.dmg, getCurrentCharWeapon(PLAYER_PED), 3)
                        end
                        
                        if silentvirilha[0] then
                            sampSendGiveDamage(targetId, weapon.dmg, getCurrentCharWeapon(PLAYER_PED), 4)
                        end
                        
                        if silentbraco[0] then
                            sampSendGiveDamage(targetId, weapon.dmg, getCurrentCharWeapon(PLAYER_PED), 6)
                        end
                        
                        if silentbraco2[0] then
                            sampSendGiveDamage(targetId, weapon.dmg, getCurrentCharWeapon(PLAYER_PED), 5)
                        end
                        
                        if silentperna[0] then
                            sampSendGiveDamage(targetId, weapon.dmg, getCurrentCharWeapon(PLAYER_PED), 8)
                        end
                        
                        if silentperna2[0] then
                            sampSendGiveDamage(targetId, weapon.dmg, getCurrentCharWeapon(PLAYER_PED), 7)
                        end
                        
                        if settings.render.printString[0] then
                        end
                    end)
                end
            end
        end
    end
end
 

function ev.onSendAimSync(data)
    if state and fakemode[0] then
        camX = data.camPos.x
        camY = data.camPos.y
        camZ = data.camPos.z
        
        frontX = data.camFront.x
        frontY = data.camFront.y
        frontZ = data.camFront.z

        local res, _, ped = pcall(sampGetCharHandleBySampPlayerId, targetId)
        if _ and res then
            local mx, my, mz = getCharCoordinates(PLAYER_PED)
            local x, y, z = getCharCoordinates(ped)
            if isLineOfSightClear(x, y, z, mx, my, mz, not settings.search.ignoreObj[0], not settings.search.ignoreCars[0], false, not settings.search.ignoreObj[0], false) then
                local x = x - mx
                local y = y - my
                local z = z - mz
                local dist = math.sqrt(x * x + y * y + z * z)
                if dist <= settings.search.radius[0] then
                    if settings.shoot.removeAmmo[0] then
                        setCharWeaponAmmo(PLAYER_PED, 0, 0)
                    end
                end
            end
        end
    end
end

function vect3_length(x, y, z)
    return math.sqrt(x * x + y * y + z * z)
end

function samp_create_sync_data(sync_type, copy_from_player)
    local ffi = require 'ffi'
    local sampfuncs = require 'sampfuncs'
  
    local raknet = require 'samp.raknet'
    

    copy_from_player = copy_from_player or true
    local sync_traits = {
        player = {'PlayerSyncData', raknet.PACKET.PLAYER_SYNC, sampStorePlayerOnfootData},
        vehicle = {'VehicleSyncData', raknet.PACKET.VEHICLE_SYNC, sampStorePlayerIncarData},
        passenger = {'PassengerSyncData', raknet.PACKET.PASSENGER_SYNC, sampStorePlayerPassengerData},
        aim = {'AimSyncData', raknet.PACKET.AIM_SYNC, sampStorePlayerAimData},
        trailer = {'TrailerSyncData', raknet.PACKET.TRAILER_SYNC, sampStorePlayerTrailerData},
        unoccupied = {'UnoccupiedSyncData', raknet.PACKET.UNOCCUPIED_SYNC, nil},
        bullet = {'BulletSyncData', raknet.PACKET.BULLET_SYNC, nil},
        spectator = {'SpectatorSyncData', raknet.PACKET.SPECTATOR_SYNC, nil}
    }
    local sync_info = sync_traits[sync_type]
    local data_type = 'struct ' .. sync_info[1]
    local data = ffi.new(data_type, {})
    local raw_data_ptr = tonumber(ffi.cast('uintptr_t', ffi.new(data_type .. '*', data)))
   
    if copy_from_player then
        local copy_func = sync_info[3]
        if copy_func then
            local _, player_id
            if copy_from_player == true then
                _, player_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            else
                player_id = tonumber(copy_from_player)
            end
            copy_func(player_id, raw_data_ptr)
        end
    end
   
    local func_send = function()
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, sync_info[2])
        raknetBitStreamWriteBuffer(bs, raw_data_ptr, ffi.sizeof(data))
        raknetSendBitStreamEx(bs, sampfuncs.HIGH_PRIORITY, sampfuncs.UNRELIABLE_SEQUENCED, 1)
        raknetDeleteBitStream(bs)
    end
   
    local mt = {
        __index = function(t, index)
            return data[index]
        end,
        __newindex = function(t, index, value)
            data[index] = value
        end
    }
    return setmetatable({send = func_send}, mt)
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
end)

lua_thread.create(function()
	while true do
		wait(0)
		if testewarp then
			local var_4_41, var_4_42, var_4_43 = getCharCoordinates(PLAYER_PED)
            local result, playerId = sampGetPlayerIdByCharHandle(PLAYER_PED)
                
            if result then
                warp_to_player(playerIdInput[0])
            end
        end
    end
end)


--aimbot

function Aimbot()
    function getCameraRotation()
        local horizontalAngle = camera.aCams[0].fHorizontalAngle
        local verticalAngle = camera.aCams[0].fVerticalAngle
        return horizontalAngle, verticalAngle
    end

    function setCameraRotation(aimbotHorizontal, aimbotVertical)
        camera.aCams[0].fHorizontalAngle = aimbotHorizontal
        camera.aCams[0].fVerticalAngle = aimbotVertical
    end

    function convertCartesianCoordinatesToSpherical(aimbot)
        local coordsDifference = aimbot - vector3d(getActiveCameraCoordinates())
        local length = coordsDifference:length()
        local angleX = math.atan2(coordsDifference.y, coordsDifference.x)
        local angleY = math.acos(coordsDifference.z / length)

        if angleX > 0 then
            angleX = angleX - math.pi
        else
            angleX = angleX + math.pi
        end

        local angleZ = math.pi / 2 - angleY
        return angleX, angleZ
    end

    function getCrosshairPositionOnScreen()
        local screenWidth, screenHeight = getScreenResolution()
        local crosshairX = screenWidth * slide.posiX[0]
        local crosshairY = screenHeight * slide.posiY[0]
        return crosshairX, crosshairY
    end

    function getCrosshairRotation(aimbot)
        aimbot = aimbot or 5
        local crosshairX, crosshairY = getCrosshairPositionOnScreen()
        local worldCoords = vector3d(convertScreenCoordsToWorld3D(crosshairX, crosshairY, aimbot))
        return convertCartesianCoordinatesToSpherical(worldCoords)
    end

    function aimAtPointWithM16(aimbot)
        local sphericalX, sphericalY = convertCartesianCoordinatesToSpherical(aimbot)
        local cameraRotationX, cameraRotationY = getCameraRotation()
        local crosshairRotationX, crosshairRotationY = getCrosshairRotation()
        local newRotationX = cameraRotationX + (sphericalX - crosshairRotationX) * slide.aimSmoothhhh[0]
        local newRotationY = cameraRotationY + (sphericalY - crosshairRotationY) * slide.aimSmoothhhh[0]
        setCameraRotation(newRotationX, newRotationY)
    end

    function aimAtPointWithSniperScope(aimbot)
        local sphericalX, sphericalY = convertCartesianCoordinatesToSpherical(aimbot)
        setCameraRotation(sphericalX, sphericalY)
    end

    function getNearCharToCenter(aimbot)
        local nearChars = {}
        local screenWidth, screenHeight = getScreenResolution()

        for _, char in ipairs(getAllChars()) do
            if isCharOnScreen(char) and char ~= PLAYER_PED and not isCharDead(char) then
                local charX, charY, charZ = getCharCoordinates(char)
                local screenX, screenY = convert3DCoordsToScreen(charX, charY, charZ)
                local distance = getDistanceBetweenCoords2d(screenWidth / 1.923 + slide.posiX[0], screenHeight / 2.306 + slide.posiY[0], screenX, screenY)

                if isCurrentCharWeapon(PLAYER_PED, 34) then
                    distance = getDistanceBetweenCoords2d(screenWidth / 2, screenHeight / 2, screenX, screenY)
                end

                if distance <= tonumber(aimbot and aimbot or screenHeight) then
                    table.insert(nearChars, {
                        distance,
                        char
                    })
                end
            end
        end

        if #nearChars > 0 then
            table.sort(nearChars, function(a, b)
                return a[1] < b[1]
            end)
            return nearChars[1][2]
        end

        return nil
    end

    local distancia = slide.DistanciaAIM[0]
    local nMode = camera.aCams[0].nMode
    local nearChar = getNearCharToCenter(slide.fovvaimbotcirculo[0] + 1.923)
    
    if nearChar then
            local boneX, boneY, boneZ = getBonePosition(nearChar, 5)
        if boneX and boneY and boneZ then
            local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
            local distanceToBone = getDistanceBetweenCoords3d(playerX, playerY, playerZ, boneX, boneY, boneZ)
    
            if not sulist.aimbotparede[0] then
                local targetX, targetY, targetZ = boneX, boneY, boneZ
                local hit, colX, colY, colZ, entityHit = processLineOfSight(playerX, playerY, playerZ, targetX, targetY, targetZ, true, true, false, true, false, false, false, false)
                if hit and entityHit ~= nearChar then
                    return
                end
            else
                local targetX, targetY, targetZ = boneX, boneY, boneZ
            end
    
            if distanceToBone < distancia then
                local point
    
                if sulist.cabecaAIM[0] then
                    local headX, headY, headZ = getBonePosition(nearChar, 5)
                    point = vector3d(headX, headY, headZ)
                end
    
                if sulist.peitoAIM[0] then
                    local chestX, chestY, chestZ = getBonePosition(nearChar, 3)
                    point = vector3d(chestX, chestY, chestZ)
                end
                
                if sulist.virilhaAIM[0] then
                    local chestX, chestY, chestZ = getBonePosition(nearChar, 1)
                    point = vector3d(chestX, chestY, chestZ)
                end
                
                if sulist.lockAIM[0] then
                    local partX, partY, partZ = getBonePosition(nearChar, miraAtual)
                    point = vector3d(partX, partY, partZ)

                    local parts = {}

                    if sulist.cabecaAIM[0] then
                        table.insert(parts, 5)
                    end
                    if sulist.peitoAIM[0] then
                        table.insert(parts, 3)
                    end
                    if sulist.virilhaAIM[0] then
                        table.insert(parts, 1)
                    end
                    if sulist.bracoAIM[0] then
                        table.insert(parts, 33)
                    end
                    if sulist.braco2AIM[0] then
                        table.insert(parts, 23)
                    end
                    if sulist.pernaAIM[0] then
                        table.insert(parts, 52)
                    end
                    if sulist.perna2AIM[0] then
                        table.insert(parts, 42)
                    end

                    if not miraAtualIndex then
                        miraAtualIndex = 1
                    end

                    if #parts > 0 then
                        if isCharShooting(PLAYER_PED) then
                            tiroContador = tiroContador + 1

                            if tiroContador >= slide.aimCtdr[0] then
                                tiroContador = 0
                                miraAtualIndex = (miraAtualIndex % #parts) + 1
                                miraAtual = parts[miraAtualIndex]
                            end
                        end

                        local partX, partY, partZ = getBonePosition(nearChar, miraAtual)
                        point = vector3d(partX, partY, partZ)
                    end
                end
                
                if sulist.bracoAIM[0] then
                    local chestX, chestY, chestZ = getBonePosition(nearChar, 33)
                    point = vector3d(chestX, chestY, chestZ)
                end
                
                if sulist.braco2AIM[0] then
                    local chestX, chestY, chestZ = getBonePosition(nearChar, 23)
                    point = vector3d(chestX, chestY, chestZ)
                end
                
                if sulist.pernaAIM[0] then
                    local chestX, chestY, chestZ = getBonePosition(nearChar, 52)
                    point = vector3d(chestX, chestY, chestZ)
                end
                
                if sulist.perna2AIM[0] then
                    local chestX, chestY, chestZ = getBonePosition(nearChar, 42)
                    point = vector3d(chestX, chestY, chestZ)
                end
    
                if point then
                    if nMode == 7 then
                        aimAtPointWithSniperScope(point)
                    elseif nMode == 53 then
                        aimAtPointWithM16(point)
                    end
                end
            end
        end
    end
end

function drawCircle(x, y, radius, color)
    local segments = 300 * DPI
    local angleStep = (2 * math.pi) / segments
    local lineWidth = 1.5 * DPI

    for i = 0, segments - 0 do
        local angle1 = i * angleStep
        local angle2 = (i + 1) * angleStep
        
        local x1 = x + (radius - lineWidth / 2) * math.cos(angle1)
        local y1 = y + (radius - lineWidth / 2) * math.sin(angle1)
        local x2 = x + (radius - lineWidth / 2) * math.cos(angle2)
        local y2 = y + (radius - lineWidth / 2) * math.sin(angle2)
        
        renderDrawLine(x1, y1, x2, y2, lineWidth, color)
    end
end

function isPlayerInFOV(playerX, playerY)
    local dx = playerX - slide.fovX[0]
    local dy = playerY - slide.fovY[0]
    local distanceSquared = dx * dx + dy * dy
    return distanceSquared <= slide.FoVV[0] * slide.FoVV[0]
end

function colorToHex(r, g, b, a)
    return bit.bor(bit.lshift(math.floor(a * 255), 24), bit.lshift(math.floor(r * 255), 16), bit.lshift(math.floor(g * 255), 8), math.floor(b * 255))
end

function getBonePosition(ped, bone)
  local pedptr = ffi.cast('void*', getCharPointer(ped))
  local posn = ffi.new('RwV3d[1]')
  gta._ZN4CPed15GetBonePositionER5RwV3djb(pedptr, posn, bone, false)
  return posn[0].x, posn[0].y, posn[0].z
end

function fix(angle)
    if angle > math.pi then
        angle = angle - (math.pi * 2)
    elseif angle < -math.pi then
        angle = angle + (math.pi * 2)
    end
    return angle
end

function getDistance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

function customSliderFloat(label, value, min, max, format)
    local style = imgui.GetStyle()
    local draw_list = imgui.GetWindowDrawList()
    local cursor_pos = imgui.GetCursorScreenPos()
    local text_size = imgui.CalcTextSize(label)

    local slider_size = imgui.ImVec2(160 * DPI, 12 * DPI)
    local padding = 10 * DPI
    local slider_pos = imgui.ImVec2(cursor_pos.x + text_size.x + padding, cursor_pos.y)
    local slider_end_pos = imgui.ImVec2(slider_pos.x + slider_size.x, slider_pos.y + slider_size.y)

    local fraction = (value[0] - min) / (max - min)
    local handle_pos = slider_pos.x + fraction * slider_size.x

    local red_color = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.00, 0.00, 0.00, 0.90))
    
    draw_list:AddRectFilled(slider_pos, slider_end_pos, imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.0, 0.0, 0.0, 1.00)), style.FrameRounding)
    
    local filled_rect_end_pos = imgui.ImVec2(handle_pos, slider_end_pos.y)
    draw_list:AddRectFilled(slider_pos, filled_rect_end_pos, red_color, style.FrameRounding)
    
    local is_dragging = imgui.IsMouseDragging(0) and imgui.IsMouseHoveringRect(slider_pos, slider_end_pos)
    local handle_radius = is_dragging and (10 * DPI) or (8.7 * DPI)
    
    local handle_center = imgui.ImVec2(handle_pos, slider_pos.y + slider_size.y * 0.5)
    draw_list:AddCircleFilled(handle_center, handle_radius, red_color, 62 * DPI)

    local value_text = string.format(format, value[0])
    local value_text_size = imgui.CalcTextSize(value_text)

    imgui.SetCursorScreenPos(imgui.ImVec2(cursor_pos.x, cursor_pos.y + (slider_size.y - text_size.y) * 0.5))
    imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1.00), label)
    
    local value_text_x = handle_pos - value_text_size.x * 0.5
    local value_text_pos = imgui.ImVec2(value_text_x, slider_end_pos.y + 5 * DPI)
    imgui.SetCursorScreenPos(value_text_pos)
    imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 0.90), value_text)
end

imgui.OnInitialize(function()
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
end)