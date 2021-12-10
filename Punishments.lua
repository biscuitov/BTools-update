script_name("[B] Recon Menu")
script_author("biscuit")

local imgui = require 'imgui'
local inicfg = require 'inicfg'
local sampev = require 'lib.samp.events'
local bNotf, notf = pcall(import, "imgui_notf.lua")
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8


local navigation = {
    current = 1,
    list = { "HOME", "SETTINGS", "ABOUT" }
}



local tag = '{d49a2f}Recon Menu: {ffffff}'

-- Автообновление
local dlstatus = require('moonloader').download_status
update_state = false -- Если переменная == true, значит начнётся обновление.
update_found = false -- Если будет true, будет доступна команда /update.

local script_vers = 6.0
local script_vers_text = "Beta 6.0" -- Название нашей версии. В будущем будем её выводить ползователю.

local update_url = 'https://raw.githubusercontent.com/Decadans1001/BTools-update/main/update.ini' -- Путь к ini файлу. Позже нам понадобиться.
local update_path = getWorkingDirectory() .. "/update.ini"

local script_url = '' -- Путь скрипту.
local script_path = thisScript().path
-- Окно настроек
local settingsw = imgui.ImBool(false)
-- Окно наказаний
local pns = imgui.ImBool(false)
-- Окно информации об игроке
local plinfo = imgui.ImBool(false)
cursorstate = imgui.ImBool(false)
local vehinfo = imgui.ImBool(false)
-- Нижнее меню рекона
local recmenu = imgui.ImBool(false)


local ex, ey = getScreenResolution()
local ToScreen = convertGameScreenCoordsToWindowScreenCoords
local font = nil


function sampev.onTogglePlayerSpectating(state)
            pns.v = state
            recmenu.v = state
            plinfo.v = state
end


-- Главная функция (main)
function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(0) end
    check_update()
    notf.addNotification(string.format('ReconMenu загружен!\nМеню настроек: /rset\n\nВерсия: Beta 3.0'), 7, 2)
    if update_found then 
        sampRegisterChatCommand('update', function()  
            update_state = true 
        end)
    else
        notf.addNotification(string.format('Обновления не найдены!'), 7, 3)
    end
    while true do
        wait(0)
        if update_state then
            downloadUrlToFile(script_url, script_path, function(id, status)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    notf.addNotification(string.format('Скрипт успешно обновлён'), 7, 2)
                end
            end)
            break
        end
    end 
    sampRegisterChatCommand('rset', function() settingsw.v = not settingsw.v end)
    sampRegisterChatCommand('frep', function() sampAddChatMessage('[Жалоба] от Frenk_Bonkers[29]:{FFFFFF} С 686886 раза почиму захожу?. Уже 1 жалоб!!!', -10) end)
    sampRegisterChatCommand('tdi', get_textdraws)
    if cursorstate.v then 
        imgui.ShowCursor = true
      else 
        imgui.ShowCursor = false
    end
    while true do
        wait(0)
        imgui.Process = settingsw.v
        if pns.v then imgui.Process = true end
    end
end

function sampev.onServerMessage(color, text)
    if text:find('%[Жалоба] от (%w+_%w+)%[%d*]:{FFFFFF}%s(.+). Уже.+') then
        repnick, reptext = text:match('%[Жалоба] от (%w+_%w+)%[%d*]:{FFFFFF}%s(.+). Уже.+')
        notf.addNotification(repnick..":\n"..reptext, 4, 1)
    end 
end

-- Удаление текстдравов рекона
function sampev.onShowTextDraw(id,data)
    lua_thread.create(function() 
      for i = 430,458 do  
        sampTextdrawDelete(i)
        sampTextdrawDelete(431)
      end
      for ii = 2063, 2065 do
        sampTextdrawDelete(ii)
        end
    end) 
end
-- Хук информации из текстдравов рекона
function sampev.onTextDrawSetString(id,text)
    if id == 2063 or id == 2084 then
        plname = text
    end
    if id == 2064 or id == 2085 then
        plID = text:match('ID:%s+(%d+)')
    end
    if id == 2064 or id == 2085 then
        plHP = text:match('n~HP:%s+(%d*.%d*)')
    end
    if id == 2064 or id == 2085 then
        plARM = text:match('.+Arm:%s+(%d*.%d*)') or text:match('.+Armour:%s+(%d*.%d*)')
    end
    if id == 2065 or id == 2086 then
        plLVL = text:match('LVL:%s+(%d+)')
    end
    if id == 2065 or id == 2086 then
        plWRNS = text:match('Warn:%s+(%d*)')
    end
    if id == 2065 or id == 2086 then
        plMON = text:match('Money:%s+(%d*)')
    end
    if id == 2065 or id == 2086 then
        plDEP = text:match('Deposit:%s+(%d*)')
    end
    if id == 2065 or id == 2086 then
        plBMON = text:match('Bank:%s+(%d*)')
    end
    if id == 2064 or id == 2085 then
        vehHP = text:match('n~vHP:%s+(%d+)')
    end
    if id == 2064 or id == 2085 then
        vehENG = text:match('~g~eng (.+)~w~') or text:match('~r~eng (.+)~w~')
    end
    if id == 2064 or id == 2085 then
        vehSP = text:match('n~vSpeed:%s+(%d*)')
    end
    if id == 2064 or id == 2085 then
        vehFUEL = text:match('Fuel:%s+(%d*.%d*)')
    end
    if id == 2064 or id == 2085 then
        gunID = text:match('n~Gun:%s+id%s+(%d*)')
    end
    if id == 2064 or id == 2085 then
        gunAMMO = text:match('ammo:%s+(%d+)')
    end
end
-- Тестовый вывод инфы из текстдрава
function get_textdraws()
    for id = 2064, 2065 do
        if sampTextdrawIsExists(id) then
            sampAddChatMessage(id.." "..sampTextdrawGetString(id), -1)
        end
    end
    sampAddChatMessage(tostring(plname), -1)
end

-- Шрифты
function imgui.BeforeDrawFrame()
    if font == nil then
        font = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 18.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic()) -- вместо 30 любой нужный размер
    end
    if font2 == nil then
        font2 = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 14.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic()) -- вместо 30 любой нужный размер
    end
    if font3 == nil then
        font3 = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 25.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic()) -- вместо 30 любой нужный размер
    end
end

function imgui.OnDrawFrame()
     if imgui.IsMouseClicked(1) then
            imgui.ShowCursor = not imgui.ShowCursor
        end 
    -- Меню настроек    
	if settingsw.v then
        local x,y = getScreenResolution()
		imgui.SetNextWindowPos(imgui.ImVec2(x / 2, y / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(250.0, 250.0), imgui.Cond.FirstUseEver)
        imgui.Begin('RECON MENU | BY BISCUIT', settingsw, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.AlwaysAutoResize)
        imgui.LockPlayer = true
        for i, title in ipairs(navigation.list) do
            if HeaderButton(navigation.current == i, title) then
                navigation.current = i
            end
            if i ~= #navigation.list then
                imgui.SameLine(nil, 30)
            end
        end
        if navigation.current == 1 then
            imgui.TextColoredRGB('еще не придумал')
        end
        if navigation.current == 2 then
            imgui.TextColoredRGB('еще не придумал')
        end
        if navigation.current == 3 then
            imgui.PushFont(font3)
            imgui.TextColoredRGB('{d49a2f}RECON {ffffff}MENU')
            imgui.PopFont()
            imgui.Text('')
            imgui.PushFont(font2)
            imgui.TextColoredRGB('{d49a2f}АВТОР СКРИПТА: {ffffff}BISCUIT')
            imgui.TextColoredRGB('{d49a2f}НАЗВАНИЕ: {ffffff}RECON MENU')
            imgui.TextColoredRGB('{d49a2f}ВЕРСИЯ: {ffffff}BETA 4.0')
            imgui.Text('')
            imgui.TextColoredRGB('{d49a2f}VK: {ffffff}')
            imgui.SameLine()
            imgui.Link("https://vk.com/biscuitt", 'B.Code')
            imgui.TextColoredRGB('{d49a2f}DISCORD: {ffffff}')
            imgui.SameLine()
            imgui.Link("#", 'B.Discord')
            imgui.TextColoredRGB('{d49a2f}VK: ')
            imgui.SameLine()
            imgui.Link('#', 'Biscuitt')
            imgui.PopFont()
        end
        imgui.End()
	end
    -- Информация об игроке
    if plinfo.v then
        local x, y = ToScreen(552, 230)
        if tostring(vehENG) == 'on' then 
            vehENG = 'ON'
        elseif tostring(vehENG) == 'off' then
            vehENG = 'OFF'
        end
        imgui.SetNextWindowPos(imgui.ImVec2(x+120, y+110), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(230.0, 320.0), imgui.Cond.FirstUseEver)
        imgui.Begin(u8'PLAYER INFO', plinfo, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoMove )
        imgui.LockPlayer = false
        imgui.PushFont(font)
        imgui.CenterText(tostring(plname).." | ID: "..tostring(plID))
        imgui.PopFont()
        imgui.Separator()
        imgui.PushFont(font2)
        imgui.Columns(2, '##plinfocol', true)
        imgui.CenterColumnText('HP:')
        imgui.CenterColumnText('ARMOUR:')
        imgui.CenterColumnText('LVL:')
        imgui.CenterColumnText('WARNS:')
        imgui.CenterColumnText('MONEY:')
        imgui.CenterColumnText('BANK:')
        imgui.CenterColumnText('DEPOSIT:')
        imgui.NextColumn()
        imgui.CenterColumnText(tostring(plHP))
        imgui.CenterColumnText(tostring(plARM))
        imgui.CenterColumnText(tostring(plLVL))
        imgui.CenterColumnText(tostring(plWRNS))
        imgui.CenterColumnText(tostring(plMON).."$")
        imgui.CenterColumnText(tostring(plBMON).."$")
        imgui.CenterColumnText(tostring(plDEP).."$")
        imgui.Columns(1)
        imgui.Separator()
        imgui.PopFont()
        imgui.PushFont(font)
        imgui.CenterText('GUN INFO')
        imgui.PopFont()
        imgui.Separator()
        imgui.PushFont(font2)
        imgui.Columns(2)
        imgui.CenterColumnText('GUN ID:')
        imgui.CenterColumnText('AMMO:')
        imgui.NextColumn()
        imgui.CenterColumnText(tostring(gunID))
        imgui.CenterColumnText(tostring(gunAMMO))
        imgui.PopFont()
        imgui.Columns(1)
        imgui.Separator()
        imgui.CenterText("Recon Control")
        if imgui.AnimatedButton('<< BACK', imgui.ImVec2(105, 30)) then
           sampSendChat('/re_prev')
        end imgui.SameLine()
        if imgui.AnimatedButton('NEXT >>', imgui.ImVec2(105, 30)) then
           sampSendChat('/re_next')
        end
        if imgui.AnimatedButton('REOFF', imgui.ImVec2(215, 30)) then
           sampSendChat('/reoff')
        end
        imgui.End()
    end
    -- Меню наказаний
	if pns.v then
        local x, y = ToScreen(552, 230)
        local w, h = ToScreen(638, 330)
        imgui.SetNextWindowPos(imgui.ImVec2(x - 40, y + 126), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(200.0, 350.0), imgui.Cond.FirstUseEver)
        imgui.Begin(u8'PUNISHMENT', pns, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoMove)
        imgui.LockPlayer = false
        if imgui.AnimatedButton(u8'IC MUTE', imgui.ImVec2(120, 30)) then
            imgui.OpenPopup(u8'MUTE IC')
        end 
        if imgui.AnimatedButton(u8'OOC MUTE', imgui.ImVec2(120, 30)) then
            imgui.OpenPopup(u8'MUTE OOC')
        end         
        if imgui.AnimatedButton(u8'KPZ', imgui.ImVec2(120, 30)) then
            imgui.OpenPopup(u8'KPZ')
        end     
        if imgui.AnimatedButton(u8'JAIL', imgui.ImVec2(120, 30)) then
            imgui.OpenPopup(u8'JAIL')
        end
        if imgui.AnimatedButton(u8'WARN', imgui.ImVec2(120, 30)) then
            imgui.OpenPopup(u8'WARN')
        end
        if imgui.AnimatedButton(u8'BAN', imgui.ImVec2(120, 30)) then
            imgui.OpenPopup(u8'BAN')
        end
        if imgui.AnimatedButton(u8'GIVEBIKE', imgui.ImVec2(120, 30)) then
            sampSendChat('/givebike '..tostring(plID))
        end
        if imgui.BeginPopupModal(u8"MUTE IC", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
            bsize = imgui.ImVec2(130, 30)
            if imgui.AnimatedButton(u8'СВОЯ ПРИЧИНА', bsize) then
                sampSetChatInputEnabled(true)
                sampSetChatInputText('/muteic '..tostring(plID)..' ')
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'METAGAMING ', bsize) then
                sampAddChatMessage('/muteic '..tostring(plID)..' 80 мг', -1)
                notf.addNotification(string.format('Вы выдали IC мут игроку '..plname..'['..plID..'].\nПричина: МГ.'), 4, 3)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'NONRP GAME', bsize) then
                sampSendChat('/muteic '..tostring(plID)..' 60 нрп')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали IC мут игроку '..plname..'['..plID..'] по причине: НРП.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'FLOOD', bsize) then
                sampSendChat('/muteic '..tostring(plID)..' 60 флуд')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали IC мут игроку '..plname..'['..plID..'] по причине: Флуд.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'BINDER', bsize) then
                sampSendChat('/muteic '..tostring(plID)..' 60 биндер')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали IC мут игроку '..plname..'['..plID..'] по причине: Биндер.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'FAKE ADMIN', bsize) then
                sampSendChat('/muteic '..tostring(plID)..' 120 выдача себя за адм')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали IC мут игроку '..plname..'['..plID..'] по причине: Выдача себя за адм.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'ЗАКРЫТЬ', bsize) then
                imgui.CloseCurrentPopup()
            end
            imgui.EndPopup()
        end 
        if imgui.BeginPopupModal(u8"MUTE OOC", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
            bsize = imgui.ImVec2(130, 30)
            if imgui.AnimatedButton(u8'СВОЯ ПРИЧИНА', bsize) then
                sampSetChatInputEnabled(true)
                sampSetChatInputText('/muteooc '..tostring(plID)..' ')
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'OFFTOP REPORT', bsize) then
                sampSendChat('/muteooc '..tostring(plID)..' 30 оффтоп в репорт')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали OOC мут игроку '..plname..'['..plID..'] по причине: Оффтоп в репорт.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'VIP CHAT ADS', bsize) then
                sampSendChat('/muteooc '..tostring(plID)..' 40 реклама в /вр')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали OOC мут игроку '..plname..'['..plID..'] по причине: Реклама в VIP чат.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'CAPS OOC', bsize) then
                sampSendChat('/muteooc '..tostring(plID)..' 60 капс оос')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали OOC мут игроку '..plname..'['..plID..'] по причине: Caps в ООС.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'МАТ OOC', bsize) then
                sampSendChat('/muteiooc '..tostring(plID)..' 60 мат оос')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали OOC мут игроку '..plname..'['..plID..'] по причине: Мат в ООС.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'ЗАКРЫТЬ', bsize) then
                imgui.CloseCurrentPopup()
            end
            imgui.EndPopup()
        end 
        if imgui.BeginPopupModal(u8"KPZ", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
            bsize = imgui.ImVec2(130, 30)
            if imgui.AnimatedButton(u8'СВОЯ ПРИЧИНА', bsize) then
                sampSetChatInputEnabled(true)
                sampSetChatInputText('/kpz '..tostring(reID)..' ')
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'DEATHMATCH', bsize) then
                sampSendChat('/kpz '..tostring(plID)..' 180 дм')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали КПЗ игроку '..plname..'['..plID..'] по причине: ДМ.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'DRIVEBY', bsize) then
                sampSendChat('/kpz '..tostring(plID)..' 180 дб')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали КПЗ игроку '..plname..'['..plID..'] по причине: ДМ.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'+C', bsize) then
                sampSendChat('/kpz '..tostring(plID)..' 120 плюс це')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали КПЗ игроку '..plname..'['..plID..'] по причине: +С.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'POWER GAMING', bsize) then
                sampSendChat('/kpz '..tostring(plID)..' 180 пг')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали КПЗ игроку '..plname..'['..plID..'] по причине: ПГ.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'TEAMKILL', bsize) then
                sampSendChat('/kpz '..tostring(plID)..' 180 тк')
                sampAddChatMessage('{d49a2f}[IC MUTE]{ffffff} Вы выдали КПЗ игроку '..plname..'['..plID..'] по причине: ТК.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'ЗАКРЫТЬ', bsize) then
                imgui.CloseCurrentPopup()
            end
            imgui.EndPopup()
        end 
        if imgui.BeginPopupModal(u8"JAIL", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
            bsize = imgui.ImVec2(130, 30)
            if imgui.AnimatedButton(u8'СВОЯ ПРИЧИНА', bsize) then
                sampSetChatInputEnabled(true)
                sampSetChatInputText('/jail '..tostring(plID)..' ')
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'BUGS', bsize) then
                sampSendChat('/jail '..tostring(plID)..' 120 багоюз')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали Джаил игроку '..plname..'['..plID..'] по причине: Багоюз.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'NONRP GAME', bsize) then
                sampSendChat('/jail '..tostring(plID)..' 30 нонрп')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали Джаил игроку '..plname..'['..plID..'] по причине: Багоюз.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'NONRP /DESC', bsize) then
                sampSendChat('/jail '..tostring(plID)..' 30 нонрп /деск')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали Джаил игроку '..plname..'['..plID..'] по причине: НонРП /desc.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'NONRP /ACTION', bsize) then
                sampSendChat('/jail '..tostring(plID)..' 30 нонрп /экшн')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали Джаил игроку '..plname..'['..plID..'] по причине: НонРП /action.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'NONRP DRIVE', bsize) then
                sampSendChat('/jail '..tostring(plID)..' 40 нрп драйв')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали Джаил игроку '..plname..'['..plID..'] по причине: НонРП езда.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'NONRP NICK', bsize) then
                sampSendChat('/jail '..tostring(plID)..' 3000 до смены ника (/мм - 1 - 12)')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали Джаил игроку '..plname..'['..plID..'] по причине: НонРП ник.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'ЗАКРЫТЬ', bsize) then
                imgui.CloseCurrentPopup()
            end
             imgui.EndPopup()
        end 
        if imgui.BeginPopupModal(u8"BAN", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
            bsize = imgui.ImVec2(130, 30)
            if imgui.AnimatedButton(u8'СВОЯ ПРИЧИНА', bsize) then
                sampSetChatInputEnabled(true)
                sampSetChatInputText('/ban '..tostring(plID)..' ')
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'DM НА СЛЕТЕ', bsize) then
                sampSendChat('/ban '..tostring(plID)..' 3 дм слет')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали Бан игроку '..plname..'['..plID..'] по причине: ДМ на Слете.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'CHEAT', bsize) then
                sampSendChat('/ban '..tostring(plID)..' 15 чит')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали Бан игроку '..plname..'['..plID..'] по причине: Читы.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'ОСК ПРОЕКТА', bsize) then
                sampSendChat('/ban '..tostring(plID)..' 30 оск проекта')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали Бан игроку '..plname..'['..plID..'] по причине: Оскорбление проекта.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'ОСК РОДНЫХ', bsize) then
                sampSendChat('/ban'..tostring(plID)..'5 упом родных')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали Бан игроку '..plname..'['..plID..'] по причине: Упоминание родных.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'ЗАКРЫТЬ', bsize) then
                imgui.CloseCurrentPopup()
            end
             imgui.EndPopup()
        end 
        imgui.End()
    end
    if tostring(vehHP) ~= 'nil' and tostring(vehENG) ~= 'nil' and tostring(vehSP) ~= 'nil' then
            local x, y = ToScreen(552, 230)
            imgui.SetNextWindowPos(imgui.ImVec2(x + 120, y + 353), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.SetNextWindowSize(imgui.ImVec2(230.0, 150.0), imgui.Cond.FirstUseEver)
            imgui.Begin(u8'VEHICLE INFO', vehinfo, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoMove )
            imgui.LockPlayer = false
            imgui.PushFont(font)
            imgui.CenterText('VEHICLE INFO')
            imgui.PopFont()
            imgui.PushFont(font2)
            imgui.Columns(2, '##vehinfocol', true)
            imgui.Separator()
            imgui.CenterColumnText('VEHICLE HP:')
            imgui.CenterColumnText('ENGINE:')
            imgui.CenterColumnText('SPEED:')
            imgui.CenterColumnText('FUEL:')
            imgui.NextColumn()
            imgui.CenterColumnText(tostring(vehHP))
            imgui.CenterColumnText(tostring(vehENG))
            imgui.CenterColumnText(tostring(vehSP).." KM/H")
            imgui.CenterColumnText(tostring(vehFUEL).." L")
            imgui.Columns(1)
            imgui.Separator()
            if imgui.AnimatedButton('GOTOCAR', imgui.ImVec2(105, 30)) then
                sampSendChat('/re_prev')
            end imgui.SameLine()
            if imgui.AnimatedButton('SPCAR', imgui.ImVec2(105, 30)) then
                sampSendChat('/re_next')
            end
            imgui.PopFont()
            imgui.End()
        end
    -- Нижнее меню рекона
    if recmenu.v then
        local x, y = ToScreen(552, 230)
        local w, h = ToScreen(638, 330)
        local m, a = ToScreen(200, 410)
        imgui.SetNextWindowPos(imgui.ImVec2(m, a), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(537, 70), imgui.Cond.FirstUseEver)
        imgui.Begin(u8"RECON MENU", recmenu, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)
        local bet = imgui.ImVec2(70, 25)
        if imgui.AnimatedButton(u8'<< BACK', bet) then
           sampSendChat('/re_prev')
        end imgui.SameLine()
        if imgui.AnimatedButton(u8'STATS', bet) then
            sampSendChat('/check '..tostring(plID))
        end imgui.SameLine()
        if imgui.AnimatedButton(u8'ONLINE', bet) then
            sampSendChat('/online '..tostring(plID))
        end imgui.SameLine()
        if imgui.AnimatedButton(u8'LICENSES', bet) then
            sampSendChat('/checklic '..tostring(plID))
        end imgui.SameLine()
        if imgui.AnimatedButton(u8'FREEZE', bet) then
            sampSendChat('/freeze '..tostring(plID))
        end imgui.SameLine()
        if imgui.AnimatedButton(u8'UNFREEZE', bet) then
            sampSendChat('/unfreeze '..tostring(plID))
        end imgui.SameLine()
        if imgui.AnimatedButton(u8'NEXT >>', bet) then
            sampSendChat('/re_next')
        end
        if imgui.AnimatedButton(u8'GOTO', bet) then
            lua_thread.create(function()
                gotoId = tostring(plID)
                sampSendChat('/reoff')
                wait(10)
                sampSendChat('/goto '..gotoId)
            end)
        end imgui.SameLine()
        if imgui.AnimatedButton(u8'AZ', bet) then
            lua_thread.create(function()
                AzId = tostring(plID)
                sampSendChat('/reoff')
                wait(1000)
                sampSendChat('/tp')
                wait(100)
                sampSendDialogResponse(sampGetCurrentDialogId(), 1, 0, nil)
                sampCloseCurrentDialogWithButton(0)
                wait(1000)
                sampSendChat('/gethere '..AzId)
            end)
        end imgui.SameLine()
        if imgui.AnimatedButton(u8'GETHERE', bet) then
            lua_thread.create(function()
                gethereId = tostring(plID)
                sampSendChat('/reoff')
                wait(1000)
                sampSendChat('/gethere '..gethereId)
            end)
        end imgui.SameLine()
        if imgui.AnimatedButton(u8'SET HP', bet) then
             sampSetChatInputEnabled(true)
            sampSetChatInputText('/sethp '..tostring(plID)..' 100')
        end imgui.SameLine()
        if imgui.AnimatedButton(u8'WEAP', bet) then
            sampSendChat('/weap '..tostring(plID))
        end imgui.SameLine()
        if imgui.AnimatedButton(u8'SLAP', bet) then
            sampSendChat('/slap '..tostring(plID))
        end imgui.SameLine()
        if imgui.AnimatedButton(u8'IP', bet) then
            sampSendChat('/getip '..tostring(plID))
        end
        imgui.End()
    end
end


-- Отключение окна рекона при выходе из него
function sampev.onSendCommand(param)
  cmdforma = param
    if param:find('reoff') or param:find('goto') then
    pns.v = false
    imgui.ShowCursor = false
    cursorstate.v = false
  end
  if param == ('re %d+') then
   spec_id.v = param:match('re (%d+)')
   if sampIsPlayerConnected(spec_id.v) then
   name = sampGetPlayerNickname(spec_id.v)
   sampAddChatMessage(string.format("[Слежка] Вы начали следить за ".. name .. "[".. spec_id.v .. "]"), 0x8B0000)
   cursorstate.v = true
   end
  end
end


-- Тема
function theme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2

    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 10.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    colors[clr.Text]                   = ImVec4(0.95, 0.96, 0.98, 1.00);
    colors[clr.TextDisabled]           = ImVec4(0.29, 0.29, 0.29, 1.00);
    colors[clr.WindowBg]               = ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[clr.ChildWindowBg]          = ImVec4(0.95, 0.96, 0.98, 0.00);
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94);
    colors[clr.Border]                 = ImVec4(0.95, 0.96, 0.98, 1.00);
    colors[clr.BorderShadow]           = ImVec4(1.00, 1.00, 1.00, 0.10);
    colors[clr.FrameBg]                = ImVec4(0.22, 0.22, 0.22, 1.00);
    colors[clr.FrameBgHovered]         = ImVec4(0.18, 0.18, 0.18, 1.00);
    colors[clr.FrameBgActive]          = ImVec4(0.09, 0.12, 0.14, 1.00);
    colors[clr.TitleBg]                = ImVec4(0.14, 0.14, 0.14, 0.81);
    colors[clr.TitleBgActive]          = ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51);
    colors[clr.MenuBarBg]              = ImVec4(0.20, 0.20, 0.20, 1.00);
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.39);
    colors[clr.ScrollbarGrab]          = ImVec4(0.36, 0.36, 0.36, 1.00);
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.18, 0.22, 0.25, 1.00);
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.24, 0.24, 0.24, 1.00);
    colors[clr.ComboBg]                = ImVec4(0.24, 0.24, 0.24, 1.00);
    colors[clr.CheckMark]              = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.SliderGrab]             = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.SliderGrabActive]       = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.Button]                 = ImVec4(0.73, 0.36, 0.00, 0.40)
    colors[clr.ButtonHovered]          = ImVec4(0.73, 0.36, 0.00, 1.00)
    colors[clr.ButtonActive]           = ImVec4(1.00, 0.50, 0.00, 1.00)
    colors[clr.Header]                 = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.HeaderHovered]          = ImVec4(1.00, 0.39, 0.39, 1.00);
    colors[clr.HeaderActive]           = ImVec4(1.00, 0.21, 0.21, 1.00);
    colors[clr.ResizeGrip]             = ImVec4(1.00, 0.28, 0.28, 1.00);
    colors[clr.ResizeGripHovered]      = ImVec4(1.00, 0.39, 0.39, 1.00);
    colors[clr.ResizeGripActive]       = ImVec4(1.00, 0.19, 0.19, 1.00);
    colors[clr.CloseButton]            = ImVec4(0.40, 0.39, 0.38, 0.16);
    colors[clr.CloseButtonHovered]     = ImVec4(0.40, 0.39, 0.38, 0.39);
    colors[clr.CloseButtonActive]      = ImVec4(0.40, 0.39, 0.38, 1.00);
    colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00);
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00);
    colors[clr.PlotHistogram]          = ImVec4(1.00, 0.21, 0.21, 1.00);
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.18, 0.18, 1.00);
    colors[clr.TextSelectedBg]         = ImVec4(1.00, 0.32, 0.32, 1.00);
    colors[clr.ModalWindowDarkening]   = ImVec4(0.26, 0.26, 0.26, 0.60);
end
theme()


-- Цветной текст в ImGUI
function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end
    render_text(text)
end


-- Центрирование текста в ImUI
function imgui.CenterText(text)
  local style = imgui.GetStyle()
  local colors = style.Colors
  local ImVec4 = imgui.ImVec4
  local explode_argb = function(argb)
      local a = bit.band(bit.rshift(argb, 24), 0xFF)
      local r = bit.band(bit.rshift(argb, 16), 0xFF)
      local g = bit.band(bit.rshift(argb, 8), 0xFF)
      local b = bit.band(argb, 0xFF)
      return a, r, g, b
  end
  local getcolor = function(color)
      if color:sub(1, 6):upper() == 'SSSSSS' then
          local r, g, b = colors[1].x, colors[1].y, colors[1].z
          local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
          return ImVec4(r, g, b, a / 255)
      end
      local color = type(color) == 'string' and tonumber(color, 16) or color
      if type(color) ~= 'number' then return end
      local r, g, b, a = explode_argb(color)
      return imgui.ImColor(r, g, b, a):GetVec4()
  end
  local render_text = function(text_)
      for w in text_:gmatch('[^\r\n]+') do
          local text, colors_, m = {}, {}, 1
          w = w:gsub('{(......)}', '{%1FF}')
          while w:find('{........}') do
              local n, k = w:find('{........}')
              local color = getcolor(w:sub(n + 1, k - 1))
              if color then
                  text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                  colors_[#colors_ + 1] = color
                  m = n
              end
              w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
          end
          if text[0] then
              for i = 0, #text do
                  imgui.TextColored(colors_[i] or colors[1], (text[i]))
                  imgui.SameLine(nil, 0)
              end
              imgui.NewLine()
          else imgui.Text(w) end
      end
  end
  if text:match('%{.+%}(.*)') then 
    textdermo = text:match('%{.+%}(.*)')
    imgui.SetCursorPosX(imgui.GetWindowSize().x/2 - imgui.CalcTextSize(textdermo).x / 2)
  else 
    imgui.SetCursorPosX(imgui.GetWindowSize().x/2 - imgui.CalcTextSize(text).x / 2)
  end
  render_text(text)
end

-- Центрирование текста в ImGUI Column Text
function imgui.CenterColumnText(text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
end


--function sampev.onShowTextDraw(id,data)
  --  if id == 2063 then 
    --    plname = data.text
    --end
    --if id == 2064 then 
      --  plID = data.text:match('ID:%s+(%d+)')
    --end
    --if id == 2064 then
     --   plHP = data.text:match('n~HP:%s+(%d*.%d*)')
    --end
    --if id == 2064 then
      --  plARM = data.text:match('.+Arm:%s+(%d*.%d*)') or data.text:match('.+Armour:%s+(%d*.%d*)')
    --end
    --if id == 2065 then
      --  plLVL = data.text:match('LVL:%s+(%d+)')
    --end
    --if id == 2065 then
      --  plWRNS = data.text:match('Warn:%s+(%d*)')
    --end
    --if id == 2064 then
     --   vehHP = data.text:match('n~vHP:%s+(%d+)')
    --end
    --if id == 2064 then 
      --  vehENG = data.text:match('~g~eng (.+)~w~') or data.text:match('~r~eng (.+)~w~')
    --end
    --if id == 2064 then
      --  vehSP = data.text:match('n~vSpeed:%s+(%d*)')
    --end
--end


-- Кнопки с анимацией
function imgui.AnimatedButton(label, size, speed, rounded)
    local size = size or imgui.ImVec2(0, 0)
    local bool = false
    local text = label:gsub('##.+$', '')
    local ts = imgui.CalcTextSize(text)
    speed = speed and speed or 0.4
    if not AnimatedButtons then AnimatedButtons = {} end
    if not AnimatedButtons[label] then
        local color = imgui.GetStyle().Colors[imgui.Col.ButtonHovered]
        AnimatedButtons[label] = {circles = {}, hovered = false, state = false, time = os.clock(), color = imgui.ImVec4(color.x, color.y, color.z, 0.2)}
    end
    local button = AnimatedButtons[label]
    local dl = imgui.GetWindowDrawList()
    local p = imgui.GetCursorScreenPos()
    local c = imgui.GetCursorPos()
    local CalcItemSize = function(size, width, height)
        local region = imgui.GetContentRegionMax()
        if (size.x == 0) then
            size.x = width
        elseif (size.x < 0) then
            size.x = math.max(4.0, region.x - c.x + size.x);
        end
        if (size.y == 0) then
            size.y = height;
        elseif (size.y < 0) then
            size.y = math.max(4.0, region.y - c.y + size.y);
        end
        return size
    end
    size = CalcItemSize(size, ts.x+imgui.GetStyle().FramePadding.x*2, ts.y+imgui.GetStyle().FramePadding.y*2)
    local ImSaturate = function(f) return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f) end
    if #button.circles > 0 then
        local PathInvertedRect = function(a, b, col)
            local rounding = rounded and imgui.GetStyle().FrameRounding or 0
            if rounding <= 0 or not rounded then return end
            local dl = imgui.GetWindowDrawList()
            dl:PathLineTo(a)
            dl:PathArcTo(imgui.ImVec2(a.x + rounding, a.y + rounding), rounding, -3.0, -1.5)
            dl:PathFillConvex(col)

            dl:PathLineTo(imgui.ImVec2(b.x, a.y))
            dl:PathArcTo(imgui.ImVec2(b.x - rounding, a.y + rounding), rounding, -1.5, -0.205)
            dl:PathFillConvex(col)

            dl:PathLineTo(imgui.ImVec2(b.x, b.y))
            dl:PathArcTo(imgui.ImVec2(b.x - rounding, b.y - rounding), rounding, 1.5, 0.205)
            dl:PathFillConvex(col)

            dl:PathLineTo(imgui.ImVec2(a.x, b.y))
            dl:PathArcTo(imgui.ImVec2(a.x + rounding, b.y - rounding), rounding, 3.0, 1.5)
            dl:PathFillConvex(col)
        end
        for i, circle in ipairs(button.circles) do
            local time = os.clock() - circle.time
            local t = ImSaturate(time / speed)
            local color = imgui.GetStyle().Colors[imgui.Col.ButtonActive]
            local color = imgui.GetColorU32(imgui.ImVec4(color.x, color.y, color.z, (circle.reverse and (255-255*t) or (255*t))/255))
            local radius = math.max(size.x, size.y) * (circle.reverse and 1.5 or t)
            imgui.PushClipRect(p, imgui.ImVec2(p.x+size.x, p.y+size.y), true)
            dl:AddCircleFilled(circle.clickpos, radius, color, radius/2)
            PathInvertedRect(p, imgui.ImVec2(p.x+size.x, p.y+size.y), imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.WindowBg]))
            imgui.PopClipRect()
            if t == 1 then
                if not circle.reverse then
                    circle.reverse = true
                    circle.time = os.clock()
                else
                    table.remove(button.circles, i)
                end
            end
        end
    end
    local t = ImSaturate((os.clock()-button.time) / speed)
    button.color.w = button.color.w + (button.hovered and 0.8 or -0.8)*t
    button.color.w = button.color.w < 0.2 and 0.2 or (button.color.w > 1 and 1 or button.color.w)
    color = imgui.GetStyle().Colors[imgui.Col.Button]
    color = imgui.GetColorU32(imgui.ImVec4(color.x, color.y, color.z, 0.2))
    dl:AddRectFilled(p, imgui.ImVec2(p.x+size.x, p.y+size.y), color, rounded and imgui.GetStyle().FrameRounding or 0)
    dl:AddRect(p, imgui.ImVec2(p.x+size.x, p.y+size.y), imgui.GetColorU32(button.color), rounded and imgui.GetStyle().FrameRounding or 0)
    local align = imgui.GetStyle().ButtonTextAlign
    imgui.SetCursorPos(imgui.ImVec2(c.x+(size.x-ts.x)*align.x, c.y+(size.y-ts.y)*align.y))
    imgui.Text(text)
    imgui.SetCursorPos(c)
    if imgui.InvisibleButton(label, size) then
        bool = true
        table.insert(button.circles, {animate = true, reverse = false, time = os.clock(), clickpos = imgui.ImVec2(getCursorPos())})
    end
    button.hovered = imgui.IsItemHovered()
    if button.hovered ~= button.state then
        button.state = button.hovered
        button.time = os.clock()
    end
    return bool
end

function getCarNamebyModel(model)
    local names = {
      [400] = 'Landstalker',
      [401] = 'Bravura',
      [402] = 'Buffalo',
      [403] = 'Linerunner',
      [404] = 'Perennial',
      [405] = 'Sentinel',
      [406] = 'Dumper',
      [407] = 'Firetruck',
      [408] = 'Trashmaster',
      [409] = 'Stretch',
      [410] = 'Manana',
      [411] = 'Infernus',
      [412] = 'Voodoo',
      [413] = 'Pony',
      [414] = 'Mule',
      [415] = 'Cheetah',
      [416] = 'Ambulance',
      [417] = 'Leviathan',
      [418] = 'Moonbeam',
      [419] = 'Esperanto',
      [420] = 'Taxi',
      [421] = 'Washington',
      [422] = 'Bobcat',
      [423] = 'Mr. Whoopee',
      [424] = 'BF Injection',
      [425] = 'Hunter',
      [426] = 'Premier',
      [427] = 'Enforcer',
      [428] = 'Securicar',
      [429] = 'Banshee',
      [430] = 'Predator',
      [431] = 'Bus',
      [432] = 'Rhino',
      [433] = 'Barracks',
      [434] = 'Hotknife',
      [435] = 'Article Trailer',
      [436] = 'Previon',
      [437] = 'Coach',
      [438] = 'Cabbie',
      [439] = 'Stallion',
      [440] = 'Rumpo',
      [441] = 'RC Bandit',
      [442] = 'Romero',
      [443] = 'Packer',
      [444] = 'Monster',
      [445] = 'Admiral',
      [446] = 'Squallo',
      [447] = 'Seaspamrow',
      [448] = 'Pizzaboy',
      [449] = 'Tram',
      [450] = 'Article Trailer 2',
      [451] = 'Turismo',
      [452] = 'Speeder',
      [453] = 'Reefer',
      [454] = 'Tropic',
      [455] = 'Flatbed',
      [456] = 'Yankee',
      [457] = 'Caddy',
      [458] = 'Solair',
      [459] = 'Topfun Van',
      [460] = 'Skimmer',
      [461] = 'PCJ-600',
      [462] = 'Faggio',
      [463] = 'Freeway',
      [464] = 'RC Baron',
      [465] = 'RC Raider',
      [466] = 'Glendale',
      [467] = 'Oceanic',
      [468] = 'Sanchez',
      [469] = 'Spamrow',
      [470] = 'Patriot',
      [471] = 'Quad',
      [472] = 'Coastguard',
      [473] = 'Dinghy',
      [474] = 'Hermes',
      [475] = 'Sabre',
      [476] = 'Rustler',
      [477] = 'ZR-350',
      [478] = 'Walton',
      [479] = 'Regina',
      [480] = 'Comet',
      [481] = 'BMX',
      [482] = 'Burrito',
      [483] = 'Camper',
      [484] = 'Marquis',
      [485] = 'Baggage',
      [486] = 'Dozer',
      [487] = 'Maverick',
      [488] = 'News Maverick',
      [489] = 'Rancher',
      [490] = 'FBI Rancher',
      [491] = 'Virgo',
      [492] = 'Greenwood',
      [493] = 'Jetmax',
      [494] = 'Hotring Racer',
      [495] = 'Sandking',
      [496] = 'Blista Compact',
      [497] = 'Police Maverick',
      [498] = 'Boxville',
      [499] = 'Benson',
      [500] = 'Mesa',
      [501] = 'RC Goblin',
      [502] = 'Hotring Racer A',
      [503] = 'Hotring Racer B',
      [504] = 'Bloodring Banger',
      [505] = 'Rancher',
      [506] = 'Super GT',
      [507] = 'Elegant',
      [508] = 'Journey',
      [509] = 'Bike',
      [510] = 'Mountain Bike',
      [511] = 'Beagle',
      [512] = 'Cropduster',
      [513] = 'Stuntplane',
      [514] = 'Tanker',
      [515] = 'Roadtrain',
      [516] = 'Nebula',
      [517] = 'Majestic',
      [518] = 'Buccaneer',
      [519] = 'Shamal',
      [520] = 'Hydra',
      [521] = 'FCR-900',
      [522] = 'NRG-500',
      [523] = 'HPV1000',
      [524] = 'Cement Truck',
      [525] = 'Towtruck',
      [526] = 'Fortune',
      [527] = 'Cadrona',
      [528] = 'FBI Truck',
      [529] = 'Willard',
      [530] = 'Forklift',
      [531] = 'Tractor',
      [532] = 'Combine',
      [533] = 'Feltzer',
      [534] = 'Remington',
      [535] = 'Slamvan',
      [536] = 'Blade',
      [537] = 'Train',
      [538] = 'Train',
      [539] = 'Vortex',
      [540] = 'Vincent',
      [541] = 'Bullet',
      [542] = 'Clover',
      [543] = 'Sadler',
      [544] = 'Firetruck',
      [545] = 'Hustler',
      [546] = 'Intruder',
      [547] = 'Primo',
      [548] = 'Cargobob',
      [549] = 'Tampa',
      [550] = 'Sunrise',
      [551] = 'Merit',
      [552] = 'Utility Van',
      [553] = 'Nevada',
      [554] = 'Yosemite',
      [555] = 'Windsor',
      [556] = 'Monster A',
      [557] = 'Monster B',
      [558] = 'Uranus',
      [559] = 'Jester',
      [560] = 'Sultan',
      [561] = 'Stratum',
      [562] = 'Elegy',
      [563] = 'Raindance',
      [564] = 'RC Tiger',
      [565] = 'Flash',
      [566] = 'Tahoma',
      [567] = 'Savanna',
      [568] = 'Bandito',
      [569] = 'Train',
      [570] = 'Train',
      [571] = 'Kart',
      [572] = 'Mower',
      [573] = 'Dune',
      [574] = 'Sweeper',
      [575] = 'Broadway',
      [576] = 'Tornado',
      [577] = 'AT400',
      [578] = 'DFT-30',
      [579] = 'Huntley',
      [580] = 'Stafford',
      [581] = 'BF-400',
      [582] = 'Newsvan',
      [583] = 'Tug',
      [584] = 'Petrol Trailer',
      [585] = 'Emperor',
      [586] = 'Wayfarer',
      [587] = 'Euros',
      [588] = 'Hotdog',
      [589] = 'Club',
      [590] = 'Train',
      [591] = 'Article Trailer 3',
      [592] = 'Andromada',
      [593] = 'Dodo',
      [594] = 'RC Cam',
      [595] = 'Launch',
      [596] = 'Police Car LS',
      [597] = 'Police Car SF',
      [598] = 'Police Car LV',
      [599] = 'Police Ranger',
      [600] = 'Picador',
      [601] = 'S.W.A.T.',
      [602] = 'Alpha',
      [603] = 'Phoenix',
      [604] = 'Glendale',
      [605] = 'Sadler',
      [606] = 'Baggage Trailer',
      [607] = 'Baggage Trailer',
      [608] = 'Tug Stairs Trailer',
      [609] = 'Boxville',
      [610] = 'Farm Trailer',
      [611] = 'Utility Traileraw '
    }
    return names[model]
end


-- Крутое вау меню
HeaderButton = function(bool, str_id)
    local DL = imgui.GetWindowDrawList()
    local ToU32 = imgui.ColorConvertFloat4ToU32
    local result = false
    local label = string.gsub(str_id, "##.*$", "")
    local duration = { 0.5, 0.3 }
    local cols = {
        idle = imgui.GetStyle().Colors[imgui.Col.TextDisabled],
        hovr = imgui.GetStyle().Colors[imgui.Col.Text],
        slct = imgui.GetStyle().Colors[imgui.Col.ButtonActive]
    }

    if not AI_HEADERBUT then AI_HEADERBUT = {} end
     if not AI_HEADERBUT[str_id] then
        AI_HEADERBUT[str_id] = {
            color = bool and cols.slct or cols.idle,
            clock = os.clock() + duration[1],
            h = {
                state = bool,
                alpha = bool and 1.00 or 0.00,
                clock = os.clock() + duration[2],
            }
        }
    end
    local pool = AI_HEADERBUT[str_id]

    local degrade = function(before, after, start_time, duration)
        local result = before
        local timer = os.clock() - start_time
        if timer >= 0.00 then
            local offs = {
                x = after.x - before.x,
                y = after.y - before.y,
                z = after.z - before.z,
                w = after.w - before.w
            }

            result.x = result.x + ( (offs.x / duration) * timer )
            result.y = result.y + ( (offs.y / duration) * timer )
            result.z = result.z + ( (offs.z / duration) * timer )
            result.w = result.w + ( (offs.w / duration) * timer )
        end
        return result
    end

    local pushFloatTo = function(p1, p2, clock, duration)
        local result = p1
        local timer = os.clock() - clock
        if timer >= 0.00 then
            local offs = p2 - p1
            result = result + ((offs / duration) * timer)
        end
        return result
    end

    local set_alpha = function(color, alpha)
        return imgui.ImVec4(color.x, color.y, color.z, alpha or 1.00)
    end

    imgui.BeginGroup()
        local pos = imgui.GetCursorPos()
        local p = imgui.GetCursorScreenPos()
      
        imgui.TextColored(pool.color, label)
        local s = imgui.GetItemRectSize()
        local hovered = imgui.IsItemHovered()
        local clicked = imgui.IsItemClicked()
      
        if pool.h.state ~= hovered and not bool then
            pool.h.state = hovered
            pool.h.clock = os.clock()
        end
      
        if clicked then
            pool.clock = os.clock()
            result = true
        end

        if os.clock() - pool.clock <= duration[1] then
            pool.color = degrade(
                imgui.ImVec4(pool.color),
                bool and cols.slct or (hovered and cols.hovr or cols.idle),
                pool.clock,
                duration[1]
            )
        else
            pool.color = bool and cols.slct or (hovered and cols.hovr or cols.idle)
        end

        if pool.h.clock ~= nil then
            if os.clock() - pool.h.clock <= duration[2] then
                pool.h.alpha = pushFloatTo(
                    pool.h.alpha,
                    pool.h.state and 1.00 or 0.00,
                    pool.h.clock,
                    duration[2]
                )
            else
                pool.h.alpha = pool.h.state and 1.00 or 0.00
                if not pool.h.state then
                    pool.h.clock = nil
                end
            end

            local max = s.x / 2
            local Y = p.y + s.y + 3
            local mid = p.x + max

            DL:AddLine(imgui.ImVec2(mid, Y), imgui.ImVec2(mid + (max * pool.h.alpha), Y), ToU32(set_alpha(pool.color, pool.h.alpha)), 3)
            DL:AddLine(imgui.ImVec2(mid, Y), imgui.ImVec2(mid - (max * pool.h.alpha), Y), ToU32(set_alpha(pool.color, pool.h.alpha)), 3)
        end

    imgui.EndGroup()
    return result
end

-- Кликабельные ссылки
function imgui.Link(link, text)
    text = text or link
    local tSize = imgui.CalcTextSize(text)
    local p = imgui.GetCursorScreenPos()
    local DL = imgui.GetWindowDrawList()
    local col = { 0xFFFF7700, 0xFFFF9900 }
    if imgui.InvisibleButton("##" .. link, tSize) then os.execute("explorer " .. link) end
    local color = imgui.IsItemHovered() and col[1] or col[2]
    DL:AddText(p, color, text)
    DL:AddLine(imgui.ImVec2(p.x, p.y + tSize.y), imgui.ImVec2(p.x + tSize.x, p.y + tSize.y), color)
end

-- Автообновление
function check_update()
    downloadUrlToFile(update_url, update_path, function(id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            updateIni = inicfg.load(nil, update_path)
            if tonumber(updateIni.info.vers) > script_vers then 
                sampAddChatMessage("{FFFFFF}Имеется {32CD32}новая {FFFFFF}версия скрипта. Версия: {32CD32}"..updateIni.info.vers_text..". {FFFFFF}/update что-бы обновить", 0xFF0000) -- Сообщаем о новой версии.
                update_found = true
            end
            os.remove(update_path)
        end
    end)
end