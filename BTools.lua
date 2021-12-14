script_name("[B] Recon Menu")
script_author("biscuit")

require("lib.moonloader")
local imgui = require 'imgui'
local inicfg = require 'inicfg'
local sampev = require 'lib.samp.events'
local vkeys = require 'vkeys'
local rkeys = require 'rkeys'
local fa = require 'fAwesome5'
local bNotf, notf = pcall(import, "imgui_notf.lua")
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

imgui.ToggleButton = require('imgui_addons').ToggleButton
imgui.HotKey = require('imgui_addons').HotKey
local AFBind = {
    v = {vkeys.VK_NUMPAD5}
}
local OTBind = {
    v = {vkeys.VK_NUMPAD6}
}
local AFBindID = 0
local OTBindID = 0

local fa_font = nil
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })

local NRtag = '{d49a2f}[REPORT] {ffffff}'
local Rtag = '{d49a2f}[ANSWER] {ffffff}'
local tag = '{d49a2f}[BTools] {ffffff}'

local sethp = imgui.ImInt(100)

-- Автообновление
local dlstatus = require('moonloader').download_status
update_state = true -- Если переменная == true, значит начнётся обновление.
update_found = false -- Если будет true, будет доступна команда /update.

local script_vers = 9.0
local script_vers_text = "Beta 9.0" -- Название нашей версии. В будущем будем её выводить ползователю.

local update_url = 'https://raw.githubusercontent.com/Decadans1001/BTools-update/main/update.ini' -- Путь к ini файлу. Позже нам понадобиться.
local update_path = getWorkingDirectory() .. "/update.ini"

local script_url = '#' -- Путь скрипту.
local script_path = thisScript().path

-- Окно настроек
local settingsw = imgui.ImBool(false)
-- Окно наказаний
local pns = imgui.ImBool(false)
-- Окно информации об игроке
local plinfo = imgui.ImBool(false)
local vehinfo = imgui.ImBool(false)
-- Нижнее меню рекона
local recmenu = imgui.ImBool(false)

local mypass = imgui.ImBuffer(30)
local admpass = imgui.ImBuffer(30)


local ToScreen = convertGameScreenCoordsToWindowScreenCoords
local font = nil

local aforms = imgui.ImBool(false)
local afsound = imgui.ImBool(false)
local acclog = imgui.ImBool(false)
local admlog = imgui.ImBool(false)


function sampev.onTogglePlayerSpectating(state)
    pns.v = state
    recmenu.v = state
    plinfo.v = state
    imgui.ShowCursor = false
end


-- Главная функция (main)
function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(0) end
    check_update()
    notf.addNotification(string.format('BTools загружен!\nМеню настроек: /rset\n\nВерсия: '..script_vers_text), 7, 2)
    if update_found then 
        update_state = true
    else
        notf.addNotification(string.format('BTools: Обновления не найдены!'), 7, 3)
    end
    while true do
        wait(0)
        if update_state then
            downloadUrlToFile(script_url, script_path, function(id, status)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    notf.addNotification(string.format('BTools: Скрипт успешно обновлён'), 7, 2)
                end
            end)
            break
        end
    end 
    sampRegisterChatCommand('rset', function() settingsw.v = not settingsw.v end)
    AFBindID = rkeys.registerHotKey(AFBind.v, true, function ()
        sampAddChatMessage(tag..' админ форма принята!', -1)
    end)
    OTBindID = rkeys.registerHotKey(OTBind.v, true, function ()
        sampAddChatMessage('report picked up', -1)
    end)
    --sampRegisterChatCommand('tdi', get_textdraws)
    while true do
        wait(0)
        imgui.Process = settingsw.v
        if pns.v then imgui.Process = true end
    end
end

function sampev.onServerMessage(color, text)
    _, myID = sampGetPlayerIdByCharHandle(PLAYER_PED)
    myname = sampGetPlayerNickname(myID)
    if text:find('%[A] Вы успешно авторизовались как%s.+}(.+)') then
        admlvlname = text:match('%[A] Вы успешно авторизовались как .+}(.+)')
        notf.addNotification('Вы авторизовались как:\n'..admlvlname, 4, 1)
        return false
    end
    if text:find('%[%/ot]%s'..tostring(myname)..'%['..tostring(myID)..'].+%s(%w+_%w+)(%[%d*]):%s{FFFFFF}(.+)') then
        otNick, otID, otText = text:match('%[%/ot]%s'..tostring(myname)..'%['..tostring(myID)..'].+%s(%w+_%w+)(%[%d*]):%s{FFFFFF}(.+)')
        sampAddChatMessage(Rtag..'Вы ответили '..otNick..''..otID..': '..otText, -1)
        return false
    end
    if text:find('%[Жалоба] от (%w+_%w+)%[(%d*)]:{FFFFFF}%s(.+) Уже (%d+).+') then
        repNick, repID, repText, repCount = text:match('%[Жалоба] от (%w+_%w+)%[(%d*)]:{FFFFFF}%s(.+) Уже (%d+).+')
        sampAddChatMessage(NRtag..'Жалоба от игрока '..repNick..'['..repID..']: '..repText..' Жалоб: '..repCount..'.', -1)
        return false
    end
    if text:find('%[Ошибка] {FFFFFF}Сейчас нет вопросов в репорт!') then
        text:match('%[Ошибка] {FFFFFF}Сейчас нет вопросов в репорт!')
        notf.addNotification('Сейчас нет вопросов в репорт!', 4, 1)
        return false
    end
    if text:find('Приветствуем нового игрока нашего сервера: {FF9900}(%w+_%w+) {FFFFFF}%(ID: (%d*).+') then
        regName, regID = text:match('Приветствуем нового игрока нашего сервера: {FF9900}(%u%w+_%u%w+) {FFFFFF}%(ID: (%d+).+')
        sampAddChatMessage('{d49a2f}[REG] {ffffff}'..regName..'['..regID..'] зарегистрировался.', -1)
        return false 
    end
    --if text:find('Приветствуем нового игрока нашего сервера: {FF9900}(%w+) {FFFFFF}%(ID: (%d*).+') then
      --  nrpregName, nrpregID = text:match('Приветствуем нового игрока нашего сервера: {FF9900}(%w+) {FFFFFF}%(ID: (%d+).+')
        --sampAddChatMessage('{d49a2f}[REG] {ffffff}'..nrpregName..'['..nrpregID..'] зарегистрировался с NRP ником.', -1)
        --return false
    --end
    if text:find('<Warning>%s(%w+_%w+)%[(%d+)]:(.+)') then
        warnNick, warnID, warnReas = text:match('<Warning>%s(%w+_%w+)%[(%d+)]:(.+)')
        sampAddChatMessage('{f7205d}[WARNING] {ffffff}Игрок '..warnNick..'['..warnID..']:'..warnReas, -1)
        return false
    end
    if text:find('{.+}Вы простояли в AFK {.+}(%w+:%w+).+') then
        afktime = text:match('{.+}Вы простояли в AFK {.+}(%w+:%w+).+')
        notf.addNotification('Вы простояли в AFK '..afktime, 4, 1)
        return false
    end
end

-- Удаление текстдравов рекона
function sampev.onShowTextDraw(id,data)
    if pns.v == true then
        lua_thread.create(function() 
            for i = 559,590 do  
                sampTextdrawDelete(i)
            end
            for ii = 2063, 2063 do
                sampTextdrawDelete(ii)
            end
        end) 
    end
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
    if fa_font == nil then
        local font_config = imgui.ImFontConfig()
        font_config.MergeMode = true
        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fa-solid-900.ttf', 12.0, font_config, fa_glyph_ranges)
    end
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
    local tLastKeys = {}
    -- Меню настроек    
	if settingsw.v then
        imgui.ShowCursor = true
        local sx,sy = getScreenResolution()
		imgui.SetNextWindowPos(imgui.ImVec2(sx / 2.3, sy / 1.6), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(300, 500), imgui.Cond.FirstUseEver)
        imgui.Begin(fa.ICON_FA_ID_BADGE..u8' BTools', settingsw, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoMove)
        imgui.LockPlayer = true
        imgui.BeginChild('child2', imgui.ImVec2(130, 232), true)
        if imgui.Button(fa.ICON_FA_INFO..u8" Информация", imgui.ImVec2(115, 40)) then
            selected_text = 1
        end
        if imgui.Button(fa.ICON_FA_COGS..u8" Настройки", imgui.ImVec2(115, 40)) then
            selected_text = 2
         end
        if imgui.Button(fa.ICON_FA_TERMINAL..u8" Команды", imgui.ImVec2(115, 40)) then
            selected_text = 3
        end
        if imgui.Button(fa.ICON_FA_FILE..u8" Руководства", imgui.ImVec2(115, 40)) then
            selected_text = 4
        end
        if imgui.Button(fa.ICON_FA_SYNC..u8" Обновления", imgui.ImVec2(115, 40)) then
            selected_text = 5
        end
        imgui.EndChild()
        imgui.SameLine()
        imgui.BeginChild('child3', imgui.ImVec2(329,232), true)
        if selected_text == 1 then
            imgui.PushFont(font3)
            imgui.CenterText('{d49a2f}B{ffffff}TOOLS')
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
            imgui.Text('')
            if imgui.Button(u8"Проверить обновления", imgui.ImVec2(150,25)) then
                os.execute('explorer "https://www.blast.hk/threads/105676/"')
            end
            imgui.SameLine()
            if imgui.Button(u8"Тех.Поддержка", imgui.ImVec2(150,25)) then
                os.execute('explorer "https://vk.com/im?sel=-208243482"')
            end
        end

        if selected_text == 2 then
            if imgui.CollapsingHeader(u8'Автовход') then
                imgui.TextColoredRGB('Автовход в аккаунт: ')
                imgui.SameLine()
                imgui.PushItemWidth(104)
                imgui.InputText(u8'##pass', mypass)
                imgui.PopItemWidth()
                imgui.SameLine()
                imgui.Button(u8'Сохранить', imgui.ImVec2(78, 20))
                imgui.TextColoredRGB('Автовход в админку: ')
                imgui.SameLine()
                imgui.PushItemWidth(100)
                imgui.InputText(u8'##admpass', admpass)
                imgui.PopItemWidth()
                imgui.SameLine()
                imgui.Button(u8'Сохранить', imgui.ImVec2(78, 20))
                if imgui.ToggleButton(u8'Автологин', acclog) then
                    sampAddChatMessage('auto login '.. tostring(acclog.v), -1)
                end
                imgui.SameLine()
                imgui.TextColoredRGB('Автовход в аккаунт')
                imgui.SameLine(170)
                if imgui.ToggleButton(u8'Админ логин', admlog) then
                    sampAddChatMessage('admin login '.. tostring(admlog.v), -1)
                end
                imgui.SameLine()
                imgui.TextColoredRGB('Автовход в админку')
            end
            if imgui.CollapsingHeader(u8'Репорт') then
                if imgui.HotKey("##report", OTBind, tLastKeys, 100) then
                    rkeys.changeHotKey(OTBindID, AFBind.v)
                    sampAddChatMessage(tag.."Бинд принятия репорта изменён! Старое значение: " .. table.concat(rkeys.getKeysName(tLastKeys.v), " + ") .. " | Новое: " .. table.concat(rkeys.getKeysName(OTBind.v), " + "), -1)
                end
                imgui.SameLine()
                imgui.TextColoredRGB('Бинд ответа на репорт')
                if imgui.HotKey("##report", OTBind, tLastKeys, 100) then
                    rkeys.changeHotKey(OTBindID, AFBind.v)
                    sampAddChatMessage(tag.."Бинд рекона за автором репорта изменён! Старое значение: " .. table.concat(rkeys.getKeysName(tLastKeys.v), " + ") .. " | Новое: " .. table.concat(rkeys.getKeysName(OTBind.v), " + "), -1)
                end
                imgui.SameLine()
                imgui.TextColoredRGB('Рекон за автором репорта')
                if imgui.HotKey("##report", OTBind, tLastKeys, 100) then
                    rkeys.changeHotKey(OTBindID, AFBind.v)
                    sampAddChatMessage("Успешно! Старое значение: " .. table.concat(rkeys.getKeysName(tLastKeys.v), " + ") .. " | Новое: " .. table.concat(rkeys.getKeysName(OTBind.v), " + "), -1)
                end
                imgui.SameLine()
                imgui.TextColoredRGB('Рекон за нарушителем')
            end
            if imgui.CollapsingHeader(u8'Админ Формы') then
                if imgui.HotKey("##aforms", AFBind, tLastKeys, 100) then
                    rkeys.changeHotKey(AFBindID, AFBind.v)
                    sampAddChatMessage("Успешно! Старое значение: " .. table.concat(rkeys.getKeysName(tLastKeys.v), " + ") .. " | Новое: " .. table.concat(rkeys.getKeysName(AFBind.v), " + "), -1)
                end
                imgui.SameLine()
                imgui.TextColoredRGB('Бинд принятия формы')
                if imgui.ToggleButton(u8'Принятие админ формы', aforms) then
                    sampAddChatMessage('aforms '.. tostring(aforms.v), -1)
                end
                imgui.SameLine()
                imgui.TextColoredRGB('Админ формы')
                imgui.SameLine(153)
                if imgui.ToggleButton(u8'Звуковое уведомление', afsound) then
                    sampAddChatMessage('aforms sound '.. tostring(afsound.v), -1)
                end
                imgui.SameLine()
                imgui.TextColoredRGB('Звуковое уведомление')
            end
            if imgui.CollapsingHeader(u8'Контроль АФК') then
            end
            if imgui.CollapsingHeader(u8'Оформление') then
                if imgui.Button(fa.ICON_FA_CROW..u8' Тема Village') then
                    village_style()
                end
                imgui.SameLine()
                if imgui.Button(fa.ICON_FA_SUN..u8' Светлая тема') then
                    light_style()
                end
                imgui.SameLine()
                if imgui.Button(fa.ICON_FA_MOON..u8' Тёмная тема') then
                    dark_style()
                end
            end
        end

        if selected_text == 3 then
            imgui.PushFont(font2)
            imgui.TextColoredRGB('{d49a2f}/GB {ffffff}- ВЫДАТЬ ИГРОКУ БАЙК.')
            imgui.TextColoredRGB('{d49a2f}/GB {ffffff}- ВЫДАТЬ ИГРОКУ БАЙК.')
            imgui.TextColoredRGB('{d49a2f}/GB {ffffff}- ВЫДАТЬ ИГРОКУ БАЙК.')
            imgui.TextColoredRGB('{d49a2f}/GB {ffffff}- ВЫДАТЬ ИГРОКУ БАЙК.')
            imgui.TextColoredRGB('{d49a2f}/GB {ffffff}- ВЫДАТЬ ИГРОКУ БАЙК.')
            imgui.TextColoredRGB('{d49a2f}/GB {ffffff}- ВЫДАТЬ ИГРОКУ БАЙК.')
            imgui.TextColoredRGB('{d49a2f}/GB {ffffff}- ВЫДАТЬ ИГРОКУ БАЙК.')
            imgui.TextColoredRGB('{d49a2f}/GB {ffffff}- ВЫДАТЬ ИГРОКУ БАЙК.')
            imgui.PopFont()
        end

        if selected_text == 4 then
            if imgui.CollapsingHeader(u8'Настройки скрипта') then
                imgui.Text('123')
            end
            if imgui.CollapsingHeader(u8'Автовход') then
                imgui.Text('123')
            end
            if imgui.CollapsingHeader(u8'Админ формы') then
                imgui.Text('123')
            end
            if imgui.CollapsingHeader(u8'Оформление') then
                imgui.Text('123')
            end
            if imgui.CollapsingHeader(u8'Автообновление') then
                imgui.Text('123')
            end
            if imgui.CollapsingHeader(u8'Конфеденциальность данных') then
                imgui.Text('123')
            end
        end

        if selected_text == 5 then
            imgui.PushFont(font)
            imgui.TextColoredRGB('{d49a2f}BETA {ffffff}8.0')
            imgui.PopFont()
            imgui.PushFont(font2)
            imgui.Text(u8'- Обновлена система автообновления.')
            imgui.Text(u8'- Переделан текст при получении репорта.')
            imgui.Text(u8'- Переделан текст при ответе на репорт.')
            imgui.Text(u8'- Добавлено уведомление при логине в админку.')
            imgui.Text(u8'- Переделан текст при регистрации нового игрока.')
            imgui.Text(u8'- Добавлен текст, если игрок зарегистрировался с\n НонРП ником.')
            imgui.Text(u8'- Добавлен /rmute.')
            imgui.PopFont()
        end

        imgui.EndChild()
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
        imgui.PushFont(fa_font)
        imgui.CenterText(fa.ICON_FA_USER..' '..tostring(plname).." | ID: "..tostring(plID))
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
        imgui.PushFont(fa_font)
        imgui.CenterText(fa.ICON_FA_BOMB..' GUN INFO')
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
        if imgui.AnimatedButton(fa.ICON_FA_CHEVRON_LEFT..' BACK', imgui.ImVec2(105, 30)) then
           sampSendChat('/re_prev')
        end imgui.SameLine()
        if imgui.AnimatedButton('NEXT '..fa.ICON_FA_CHEVRON_RIGHT, imgui.ImVec2(105, 30)) then
           sampSendChat('/re_next')
        end
        if imgui.AnimatedButton('REOFF '..fa.ICON_FA_SIGN_OUT_ALT, imgui.ImVec2(215, 30), 3, 30) then
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
        if imgui.AnimatedButton(u8'RMUTE', imgui.ImVec2(120, 30)) then
            sampSetChatInputText('/rmute '..plID..' ')
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
                notf.addNotification(string.format('Вы выдали IC мут игроку '..plname..'['..plID..'].\nПричина: МГ.'), 4, 1)
                --notf.addNotification(string.format('У игрока '..plname..'['..plID..'] уже есть IC мут.'), 4, 3)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'NONRP GAME', bsize) then
                sampSendChat('/muteic '..tostring(plID)..' 60 нрп')
                notf.addNotification(string.format('Вы выдали IC мут игроку '..plname..'['..plID..'].\nПричина: НРП.'), 4, 1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton('FLOOD', bsize) then
                sampSendChat('/muteic '..tostring(plID)..' 60 флуд')
                notf.addNotification(string.format('Вы выдали IC мут игроку '..plname..'['..plID..'].\nПричина: Флуд.'), 4, 1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'BINDER', bsize) then
                sampSendChat('/muteic '..tostring(plID)..' 60 биндер')
                notf.addNotification(string.format('Вы выдали IC мут игроку '..plname..'['..plID..'].\nПричина: Биндер.'), 4, 1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'FAKE ADMIN', bsize) then
                sampSendChat('/muteic '..tostring(plID)..' 120 выдача себя за адм')
                notf.addNotification(string.format('Вы выдали IC мут игроку '..plname..'['..plID..'].\nПричина: Выдача себя за адм.'), 4, 1)
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
                notf.addNotification(string.format('Вы выдали OOC мут игроку '..plname..'['..plID..'].\nПричина: Оффтоп в репорт.'), 4, 1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'VIP CHAT ADS', bsize) then
                sampSendChat('/muteooc '..tostring(plID)..' 40 реклама в /вр')
                notf.addNotification(string.format('Вы выдали OOC мут игроку '..plname..'['..plID..'].\nПричина: Рекалама в VIP.'), 4, 1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'CAPS OOC', bsize) then
                sampSendChat('/muteooc '..tostring(plID)..' 60 капс оос')
                notf.addNotification(string.format('Вы выдали OOC мут игроку '..plname..'['..plID..'].\nПричина: OOC Caps.'), 4, 1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'МАТ OOC', bsize) then
                sampSendChat('/muteiooc '..tostring(plID)..' 60 мат оос')
                notf.addNotification(string.format('Вы выдали OOC мут игроку '..plname..'['..plID..'].\nПричина: OOC Мат.'), 4, 1)
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
                notf.addNotification(string.format('Вы выдали КПЗ игроку '..plname..'['..plID..'].\nПричина: DM.'), 4, 1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'DRIVEBY', bsize) then
                sampSendChat('/kpz '..tostring(plID)..' 180 дб')
                notf.addNotification(string.format('Вы выдали КПЗ игроку '..plname..'['..plID..'].\nПричина: DB.'), 4, 1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'+C', bsize) then
                sampSendChat('/kpz '..tostring(plID)..' 120 плюс це')
                notf.addNotification(string.format('Вы выдали КПЗ игроку '..plname..'['..plID..'].\nПричина: +C.'), 4, 1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'POWER GAMING', bsize) then
                sampSendChat('/kpz '..tostring(plID)..' 180 пг')
                notf.addNotification(string.format('Вы выдали КПЗ игроку '..plname..'['..plID..'].\nПричина: PG.'), 4, 1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'TEAMKILL', bsize) then
                sampSendChat('/kpz '..tostring(plID)..' 180 тк')
                notf.addNotification(string.format('Вы выдали КПЗ игроку '..plname..'['..plID..'].\nПричина: TK.'), 4, 1)
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
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали Джаил игроку '..plname..'['..plID..'] по причине: Нонрп игра.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'NONRP /DESC', bsize) then
                sampSendChat('/jail '..tostring(plID)..' 30 нонрп /desc')
                sampAddChatMessage('{d49a2f}BTools:{ffffff} Вы выдали Джаил игроку '..plname..'['..plID..'] по причине: НонРП /desc.', -1)
                imgui.CloseCurrentPopup()
            end
            if imgui.AnimatedButton(u8'NONRP /ACTION', bsize) then
                sampSendChat('/jail '..tostring(plID)..' 30 нонрп /action')
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
            imgui.PushFont(fa_font)
            imgui.CenterText(fa.ICON_FA_CAR..' VEHICLE INFO')
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
        bsize = imgui.ImVec2(130, 30)
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
                wait(800)
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
            imgui.OpenPopup(u8'SET HP')
        end
        if imgui.BeginPopupModal(u8"SET HP", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.AlwaysAutoResize) then
            imgui.CustomSlider("Slider1", 0, 100, 250, sethp)
            if imgui.AnimatedButton(u8'ВЫДАТЬ', bsize) then
                sampAddChatMessage('hp: ' ..sethp.v, -1)
                imgui.CloseCurrentPopup()
            end
            imgui.SameLine()
            if imgui.AnimatedButton(u8'ЗАКРЫТЬ', bsize) then
                imgui.CloseCurrentPopup()
            end
            imgui.EndPopup()
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
    end
    if param:find('re %d*') then
        sampAddChatMessage('recon', -1)
    end
end


function dark_style()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4

    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 10
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

    colors[clr.Text] = ImVec4(0.80, 0.80, 0.83, 1.00)
    colors[clr.TextDisabled] = ImVec4(0.24, 0.23, 0.29, 1.00)
    colors[clr.WindowBg] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.ChildWindowBg] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.PopupBg] = ImVec4(0.07, 0.07, 0.09, 1.00)
    colors[clr.Border] = ImVec4(0.80, 0.80, 0.83, 0.88)
    colors[clr.BorderShadow] = ImVec4(0.92, 0.91, 0.88, 0.00)
    colors[clr.FrameBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.FrameBgHovered] = ImVec4(0.24, 0.23, 0.29, 1.00)
    colors[clr.FrameBgActive] = ImVec4(0.56, 0.56, 0.58, 1.00)
    colors[clr.TitleBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.TitleBgCollapsed] = ImVec4(1.00, 0.98, 0.95, 0.75)
    colors[clr.TitleBgActive] = ImVec4(0.07, 0.07, 0.09, 1.00)
    colors[clr.MenuBarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.ScrollbarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.ScrollbarGrab] = ImVec4(0.80, 0.80, 0.83, 0.31)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.ComboBg] = ImVec4(0.19, 0.18, 0.21, 1.00)
    colors[clr.CheckMark] = ImVec4(0.80, 0.80, 0.83, 0.31)
    colors[clr.SliderGrab] = ImVec4(0.80, 0.80, 0.83, 0.31)
    colors[clr.SliderGrabActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.Button] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.ButtonHovered] = ImVec4(0.24, 0.23, 0.29, 1.00)
    colors[clr.ButtonActive] = ImVec4(0.56, 0.56, 0.58, 1.00)
    colors[clr.Header] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.HeaderHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
    colors[clr.HeaderActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.ResizeGrip] = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.ResizeGripHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
    colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.CloseButton] = ImVec4(0.40, 0.39, 0.38, 0.16)
    colors[clr.CloseButtonHovered] = ImVec4(0.40, 0.39, 0.38, 0.39)
    colors[clr.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)
    colors[clr.PlotLines] = ImVec4(0.40, 0.39, 0.38, 0.63)
    colors[clr.PlotLinesHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
    colors[clr.PlotHistogram] = ImVec4(0.40, 0.39, 0.38, 0.63)
    colors[clr.PlotHistogramHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
    colors[clr.TextSelectedBg] = ImVec4(0.25, 1.00, 0.00, 0.43)
    colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
end

function light_style()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4

    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 10
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

    colors[clr.Text] = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.TextDisabled] = ImVec4(0.24, 0.24, 0.24, 1.00)
    colors[clr.WindowBg] = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.ChildWindowBg] = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.PopupBg] = ImVec4(0.92, 0.92, 0.92, 1.00)
    colors[clr.Border] = ImVec4(0.86, 0.86, 0.86, 1.00)
    colors[clr.BorderShadow] = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg] = ImVec4(0.88, 0.88, 0.88, 1.00)
    colors[clr.FrameBgHovered] = ImVec4(0.24, 0.23, 0.29, 1.00)
    colors[clr.FrameBgActive] = ImVec4(0.76, 0.76, 0.76, 1.00)
    colors[clr.TitleBg] = ImVec4(0.00, 0.45, 1.00, 0.82)
    colors[clr.TitleBgCollapsed] = ImVec4(0.00, 0.45, 1.00, 0.82)
    colors[clr.TitleBgActive] = ImVec4(0.00, 0.45, 1.00, 0.82)
    colors[clr.MenuBarBg] = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.ScrollbarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.ScrollbarGrab] = ImVec4(0.00, 0.35, 1.00, 0.78)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.00, 0.31, 1.00, 0.88)
    colors[clr.ComboBg] = ImVec4(0.92, 0.92, 0.92, 1.00)
    colors[clr.CheckMark] = ImVec4(0.80, 0.80, 0.83, 0.31)
    colors[clr.SliderGrab] = ImVec4(0.80, 0.80, 0.83, 0.31)
    colors[clr.SliderGrabActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.Button] = ImVec4(0.00, 0.49, 1.00, 0.59)
    colors[clr.ButtonHovered] = ImVec4(0.00, 0.49, 1.00, 0.78)
    colors[clr.ButtonActive] = ImVec4(0.00, 0.49, 1.00, 0.78)
    colors[clr.Header] = ImVec4(0.00, 0.49, 1.00, 0.78)
    colors[clr.HeaderHovered] = ImVec4(0.00, 0.49, 1.00, 0.78)
    colors[clr.HeaderActive] = ImVec4(0.00, 0.49, 1.00, 0.78)
    colors[clr.ResizeGrip] = ImVec4(0.00, 0.39, 1.00, 0.59)
    colors[clr.ResizeGripHovered] = ImVec4(0.00, 0.27, 1.00, 0.59)
    colors[clr.ResizeGripActive] = ImVec4(0.00, 0.25, 1.00, 0.63)
    colors[clr.CloseButton] = ImVec4(0.00, 0.35, 0.96, 0.71)
    colors[clr.CloseButtonHovered] = ImVec4(0.00, 0.31, 0.88, 0.69)
    colors[clr.CloseButtonActive] = ImVec4(0.00, 0.25, 0.88, 0.67)
    colors[clr.PlotLines] = ImVec4(0.00, 0.39, 1.00, 0.75)
    colors[clr.PlotLinesHovered] = ImVec4(0.00, 0.39, 1.00, 0.75)
    colors[clr.PlotHistogram] = ImVec4(0.00, 0.39, 1.00, 0.75)
    colors[clr.PlotHistogramHovered] = ImVec4(0.00, 0.35, 0.92, 0.78)
    colors[clr.TextSelectedBg] = ImVec4(0.00, 0.47, 1.00, 0.59)
    colors[clr.ModalWindowDarkening] = ImVec4(0.20, 0.20, 0.20, 0.35)
end

-- Тема
function village_style()
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
    colors[clr.Header]                 = ImVec4(0.73, 0.36, 0.00, 0.40);
    colors[clr.HeaderHovered]          = ImVec4(0.73, 0.36, 0.00, 1.00);
    colors[clr.HeaderActive]           = ImVec4(1.00, 0.50, 0.00, 1.00);
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
village_style()


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

function imgui.TextQuestion(label, description)
    imgui.TextDisabled(label)

    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
            imgui.PushTextWrapPos(600)
                imgui.TextUnformatted(description)
            imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end

-- Автообновление
function check_update()
    downloadUrlToFile(update_url, update_path, function(id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            updateIni = inicfg.load(nil, update_path)
            if tonumber(updateIni.info.vers) > script_vers then 
                notf.addNotification(string.format('Достуна новая версия BTools: '..updateIni.info.vers_text..'\nЗапущено обновление.'), 7, 2)
                update_found = true
            end
            os.remove(update_path)
        end
    end)
end

function imgui.CustomSlider(str_id, min, max, width, int) -- by aurora
    local p = imgui.GetCursorScreenPos()
    local draw_list = imgui.GetWindowDrawList()
    local pos = imgui.GetWindowPos()
    local posx,posy = getCursorPos()
    local n = max - min
    if int.v == 0 then
        int.v = min
    end
    local col_bg_active = imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.ButtonActive])
    local col_bg_notactive = imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.ModalWindowDarkening])
    draw_list:AddRectFilled(imgui.ImVec2(p.x + 7, p.y + 12), imgui.ImVec2(p.x + (width/n)*(int.v-min), p.y + 12), col_bg_active, 5.0)
    draw_list:AddRectFilled(imgui.ImVec2(p.x + (width/n)*(int.v-min), p.y + 12), imgui.ImVec2(p.x + width, p.y + 12), col_bg_notactive, 5.0)
    for i = 0, n do
        if posx > (p.x + i*width/(max+1) ) and posx < (p.x + (i+1)*width/(max+1)) and posy > p.y + 2 and posy < p.y + 22 and imgui.IsMouseDown(0) then
            int.v = i + min
            draw_list:AddCircleFilled(imgui.ImVec2(p.x + (width/n)*(int.v-min) + 4,  p.y + 7*2 - 2), 7+2, col_bg_active)
        end
    end
    imgui.SetCursorPos(imgui.ImVec2(p.x + width - 125 - pos.x, p.y - 8 - pos.y))
    imgui.Text(tostring(int.v))
    draw_list:AddCircleFilled(imgui.ImVec2(p.x + (width/n)*(int.v-min) + 4,  p.y + 7*2 - 2), 7, col_bg_active)
    imgui.NewLine()
    return int
end