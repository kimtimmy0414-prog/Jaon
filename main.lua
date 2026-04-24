-- ============================================================
--  FFA Hub | Executor Script
--  구조: 로딩 → 키 인증 → 메인 GUI
-- ============================================================

local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService      = game:GetService("RunService")
local LocalPlayer     = Players.LocalPlayer

-- ============================================================
-- [ 0 ] 유틸리티
-- ============================================================

local function tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function easeTween(obj, t, props, style, dir)
    style = style or Enum.EasingStyle.Quart
    dir   = dir   or Enum.EasingDirection.Out
    return tween(obj, TweenInfo.new(t, style, dir), props)
end

-- 드래그 함수 (재사용)
local function makeDraggable(handle, root)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = root.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            root.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- 호버 / 클릭 애니메이션
local function addHover(btn, normalColor, hoverColor)
    btn.MouseEnter:Connect(function()
        easeTween(btn, 0.15, {BackgroundColor3 = hoverColor})
    end)
    btn.MouseLeave:Connect(function()
        easeTween(btn, 0.15, {BackgroundColor3 = normalColor})
    end)
    btn.MouseButton1Down:Connect(function()
        easeTween(btn, 0.08, {Size = UDim2.new(
            btn.Size.X.Scale, btn.Size.X.Offset - 4,
            btn.Size.Y.Scale, btn.Size.Y.Offset - 4
        )})
    end)
    btn.MouseButton1Up:Connect(function()
        easeTween(btn, 0.1, {Size = UDim2.new(
            btn.Size.X.Scale, btn.Size.X.Offset + 4,
            btn.Size.Y.Scale, btn.Size.Y.Offset + 4
        )})
    end)
end

-- ============================================================
-- [ 1 ] ScreenGui 생성
-- ============================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "FFAHUB"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- executor 환경에 따라 CoreGui 또는 PlayerGui 사용
local ok = pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)
if not ok then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ============================================================
-- [ 2 ] 색상 팔레트
-- ============================================================

local C = {
    BG        = Color3.fromRGB(15, 15, 20),
    Panel     = Color3.fromRGB(22, 22, 30),
    TopBar    = Color3.fromRGB(28, 28, 38),
    Tab       = Color3.fromRGB(30, 30, 42),
    TabActive  = Color3.fromRGB(100, 60, 200),
    Accent    = Color3.fromRGB(120, 70, 220),
    AccentHov = Color3.fromRGB(140, 90, 240),
    Green     = Color3.fromRGB(0, 200, 130),
    Red       = Color3.fromRGB(220, 60, 60),
    Text      = Color3.fromRGB(230, 230, 240),
    SubText   = Color3.fromRGB(150, 150, 170),
    CheckOff  = Color3.fromRGB(40, 40, 55),
    CheckOn   = Color3.fromRGB(100, 60, 200),
    Input     = Color3.fromRGB(30, 30, 45),
    Stroke    = Color3.fromRGB(60, 60, 90),
}

-- ============================================================
-- [ 3 ] 알림 시스템
-- ============================================================

local notifQueue = 0

local function notify(title, msg, color)
    notifQueue = notifQueue + 1
    local yOff = (notifQueue - 1) * 75

    local N = Instance.new("Frame", ScreenGui)
    N.Size             = UDim2.new(0, 280, 0, 60)
    N.Position         = UDim2.new(1, 10, 1, -(70 + yOff))
    N.BackgroundColor3 = C.Panel
    N.BorderSizePixel  = 0
    N.ZIndex           = 20

    local stroke = Instance.new("UIStroke", N)
    stroke.Color     = color or C.Accent
    stroke.Thickness = 1.5

    Instance.new("UICorner", N).CornerRadius = UDim.new(0, 8)

    local bar = Instance.new("Frame", N)
    bar.Size             = UDim2.new(0, 4, 1, -16)
    bar.Position         = UDim2.new(0, 8, 0, 8)
    bar.BackgroundColor3 = color or C.Accent
    bar.BorderSizePixel  = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)

    local tTitle = Instance.new("TextLabel", N)
    tTitle.Size               = UDim2.new(1, -30, 0, 20)
    tTitle.Position           = UDim2.new(0, 20, 0, 8)
    tTitle.Text               = title
    tTitle.TextColor3         = C.Text
    tTitle.Font               = Enum.Font.GothamBold
    tTitle.TextSize           = 13
    tTitle.BackgroundTransparency = 1
    tTitle.TextXAlignment     = Enum.TextXAlignment.Left
    tTitle.ZIndex             = 21

    local tMsg = Instance.new("TextLabel", N)
    tMsg.Size               = UDim2.new(1, -30, 0, 18)
    tMsg.Position           = UDim2.new(0, 20, 0, 30)
    tMsg.Text               = msg
    tMsg.TextColor3         = C.SubText
    tMsg.Font               = Enum.Font.Gotham
    tMsg.TextSize           = 11
    tMsg.BackgroundTransparency = 1
    tMsg.TextXAlignment     = Enum.TextXAlignment.Left
    tMsg.ZIndex             = 21

    -- 슬라이드 인
    easeTween(N, 0.35, {Position = UDim2.new(1, -(290), 1, -(70 + yOff))})

    task.delay(3, function()
        easeTween(N, 0.3, {Position = UDim2.new(1, 10, 1, -(70 + yOff))}).Completed:Wait()
        N:Destroy()
        notifQueue = notifQueue - 1
    end)
end

-- ============================================================
-- [ 4 ] 로딩 UI
-- ============================================================

local function createLoader(labelText)
    local Loader = Instance.new("Frame", ScreenGui)
    Loader.Size             = UDim2.new(1, 0, 1, 0)
    Loader.BackgroundColor3 = C.BG
    Loader.BorderSizePixel  = 0
    Loader.ZIndex           = 10

    -- 로고
    local Logo = Instance.new("TextLabel", Loader)
    Logo.Size               = UDim2.new(0, 300, 0, 50)
    Logo.Position           = UDim2.new(0.5, -150, 0.38, 0)
    Logo.Text               = "FFA HUB"
    Logo.TextColor3         = C.Accent
    Logo.Font               = Enum.Font.GothamBold
    Logo.TextSize           = 36
    Logo.BackgroundTransparency = 1
    Logo.ZIndex             = 11

    local SubLabel = Instance.new("TextLabel", Loader)
    SubLabel.Size               = UDim2.new(0, 300, 0, 25)
    SubLabel.Position           = UDim2.new(0.5, -150, 0.48, 0)
    SubLabel.Text               = labelText or "Loading..."
    SubLabel.TextColor3         = C.SubText
    SubLabel.Font               = Enum.Font.Gotham
    SubLabel.TextSize           = 13
    SubLabel.BackgroundTransparency = 1
    SubLabel.ZIndex             = 11

    -- 프로그레스 바 배경
    local BarBG = Instance.new("Frame", Loader)
    BarBG.Size             = UDim2.new(0, 300, 0, 6)
    BarBG.Position         = UDim2.new(0.5, -150, 0.56, 0)
    BarBG.BackgroundColor3 = C.Tab
    BarBG.BorderSizePixel  = 0
    BarBG.ZIndex           = 11
    Instance.new("UICorner", BarBG).CornerRadius = UDim.new(1, 0)

    local Bar = Instance.new("Frame", BarBG)
    Bar.Size             = UDim2.new(0, 0, 1, 0)
    Bar.BackgroundColor3 = C.Accent
    Bar.BorderSizePixel  = 0
    Bar.ZIndex           = 12
    Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)

    -- 스피너
    local Spinner = Instance.new("Frame", Loader)
    Spinner.Size             = UDim2.new(0, 28, 0, 28)
    Spinner.Position         = UDim2.new(0.5, -14, 0.62, 0)
    Spinner.BackgroundColor3 = C.Accent
    Spinner.BorderSizePixel  = 0
    Spinner.ZIndex           = 11
    Instance.new("UICorner", Spinner).CornerRadius = UDim.new(1, 0)

    -- 스피너 회전
    task.spawn(function()
        while Loader and Loader.Parent do
            local t = TweenService:Create(
                Spinner,
                TweenInfo.new(0.7, Enum.EasingStyle.Linear),
                {Rotation = Spinner.Rotation + 180}
            )
            t:Play()
            t.Completed:Wait()
        end
    end)

    -- 페이드 인
    Loader.BackgroundTransparency = 1
    easeTween(Loader, 0.4, {BackgroundTransparency = 0})

    -- 프로그레스 바 채우기
    easeTween(Bar, 2.2, {Size = UDim2.new(1, 0, 1, 0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    return Loader
end

-- [ 첫 번째 로딩 표시 ]
local FirstLoader = createLoader("FFA Hub Loading...")
task.wait(2.5)

-- 페이드 아웃
easeTween(FirstLoader, 0.4, {BackgroundTransparency = 1}).Completed:Wait()
FirstLoader:Destroy()

-- ============================================================
-- [ 5 ] 키 시스템 UI
-- ============================================================

-- HWID 가져오기 (없으면 대체)
local you_hwid = ""
pcall(function() you_hwid = gethwid() end)
if you_hwid == "" then you_hwid = tostring(game:GetService("RbxAnalyticsService"):GetClientId()) end

local function domain_control(x)
    return game:HttpGet(
        "https://s" .. math.random(1,4) ..
        ".ntt-system.xyz/?type=data&domain=ffa-hub&hwid=" .. x
    )
end

-- 키 UI 로더 표시
local KeyLoader = createLoader("Preparing Key System...")
task.wait(1.5)
easeTween(KeyLoader, 0.35, {BackgroundTransparency = 1}).Completed:Wait()
KeyLoader:Destroy()

-- 키 패널
local KeyPanel = Instance.new("Frame", ScreenGui)
KeyPanel.Size             = UDim2.new(0, 340, 0, 220)
KeyPanel.Position         = UDim2.new(0.5, -170, 0.5, -110)
KeyPanel.BackgroundColor3 = C.Panel
KeyPanel.BorderSizePixel  = 0
KeyPanel.ZIndex           = 5
Instance.new("UICorner", KeyPanel).CornerRadius = UDim.new(0, 12)

local kStroke = Instance.new("UIStroke", KeyPanel)
kStroke.Color     = C.Stroke
kStroke.Thickness = 1.5

-- 탑바
local KTopBar = Instance.new("Frame", KeyPanel)
KTopBar.Size             = UDim2.new(1, 0, 0, 40)
KTopBar.BackgroundColor3 = C.TopBar
KTopBar.BorderSizePixel  = 0
KTopBar.ZIndex           = 6
Instance.new("UICorner", KTopBar).CornerRadius = UDim.new(0, 12)

-- 탑바 하단 모서리 가림
local KTopFix = Instance.new("Frame", KTopBar)
KTopFix.Size             = UDim2.new(1, 0, 0.5, 0)
KTopFix.Position         = UDim2.new(0, 0, 0.5, 0)
KTopFix.BackgroundColor3 = C.TopBar
KTopFix.BorderSizePixel  = 0
KTopFix.ZIndex           = 6

local KTitle = Instance.new("TextLabel", KTopBar)
KTitle.Size               = UDim2.new(1, 0, 1, 0)
KTitle.Text               = "🔐  FFA Hub  —  Key System"
KTitle.TextColor3         = C.Text
KTitle.Font               = Enum.Font.GothamBold
KTitle.TextSize           = 14
KTitle.BackgroundTransparency = 1
KTitle.ZIndex             = 7

makeDraggable(KTopBar, KeyPanel)

-- TextBox
local KBox = Instance.new("TextBox", KeyPanel)
KBox.Size               = UDim2.new(1, -40, 0, 38)
KBox.Position           = UDim2.new(0, 20, 0, 58)
KBox.PlaceholderText    = "Enter your key..."
KBox.Text               = ""
KBox.BackgroundColor3   = C.Input
KBox.TextColor3         = C.Text
KBox.PlaceholderColor3  = C.SubText
KBox.Font               = Enum.Font.Gotham
KBox.TextSize           = 13
KBox.BorderSizePixel    = 0
KBox.ClearTextOnFocus   = false
KBox.ZIndex             = 6
Instance.new("UICorner", KBox).CornerRadius = UDim.new(0, 8)
local kbStroke = Instance.new("UIStroke", KBox)
kbStroke.Color     = C.Stroke
kbStroke.Thickness = 1

-- Get Key 버튼
local GetKeyBtn = Instance.new("TextButton", KeyPanel)
GetKeyBtn.Size             = UDim2.new(0, 140, 0, 36)
GetKeyBtn.Position         = UDim2.new(0, 20, 0, 112)
GetKeyBtn.Text             = "Get Key"
GetKeyBtn.BackgroundColor3 = C.Tab
GetKeyBtn.TextColor3       = C.Text
GetKeyBtn.Font             = Enum.Font.GothamBold
GetKeyBtn.TextSize         = 13
GetKeyBtn.BorderSizePixel  = 0
GetKeyBtn.ZIndex           = 6
Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 8)
addHover(GetKeyBtn, C.Tab, C.TopBar)

-- Verify 버튼
local VerifyBtn = Instance.new("TextButton", KeyPanel)
VerifyBtn.Size             = UDim2.new(0, 140, 0, 36)
VerifyBtn.Position         = UDim2.new(1, -160, 0, 112)
VerifyBtn.Text             = "Verify Key"
VerifyBtn.BackgroundColor3 = C.Accent
VerifyBtn.TextColor3       = C.Text
VerifyBtn.Font             = Enum.Font.GothamBold
VerifyBtn.TextSize         = 13
VerifyBtn.BorderSizePixel  = 0
VerifyBtn.ZIndex           = 6
Instance.new("UICorner", VerifyBtn).CornerRadius = UDim.new(0, 8)
addHover(VerifyBtn, C.Accent, C.AccentHov)

-- 상태 텍스트
local KStatus = Instance.new("TextLabel", KeyPanel)
KStatus.Size               = UDim2.new(1, -40, 0, 20)
KStatus.Position           = UDim2.new(0, 20, 0, 162)
KStatus.Text               = ""
KStatus.TextColor3         = C.SubText
KStatus.Font               = Enum.Font.Gotham
KStatus.TextSize           = 12
KStatus.BackgroundTransparency = 1
KStatus.TextXAlignment     = Enum.TextXAlignment.Left
KStatus.ZIndex             = 6

local KVersion = Instance.new("TextLabel", KeyPanel)
KVersion.Size               = UDim2.new(1, 0, 0, 18)
KVersion.Position           = UDim2.new(0, 0, 1, -22)
KVersion.Text               = "FFA Hub v2.0  |  ntt-system.xyz"
KVersion.TextColor3         = C.SubText
KVersion.Font               = Enum.Font.Gotham
KVersion.TextSize           = 10
KVersion.BackgroundTransparency = 1
KVersion.ZIndex             = 6

-- 등장 애니메이션
KeyPanel.Position = UDim2.new(0.5, -170, 0.5, -130)
KeyPanel.BackgroundTransparency = 1
easeTween(KeyPanel, 0.4, {
    Position = UDim2.new(0.5, -170, 0.5, -110),
    BackgroundTransparency = 0
})

-- ============================================================
-- [ 6 ] 메인 GUI (키 인증 후 표시)
-- ============================================================

local MainGui = Instance.new("Frame", ScreenGui)
MainGui.Size             = UDim2.new(0, 580, 0, 380)
MainGui.Position         = UDim2.new(0.5, -290, 0.5, -190)
MainGui.BackgroundColor3 = C.Panel
MainGui.BorderSizePixel  = 0
MainGui.Visible          = false
MainGui.ZIndex           = 3
Instance.new("UICorner", MainGui).CornerRadius = UDim.new(0, 12)

local mStroke = Instance.new("UIStroke", MainGui)
mStroke.Color     = C.Stroke
mStroke.Thickness = 1.5

-- 그림자 효과
local Shadow = Instance.new("ImageLabel", MainGui)
Shadow.Size               = UDim2.new(1, 30, 1, 30)
Shadow.Position           = UDim2.new(0, -15, 0, -15)
Shadow.BackgroundTransparency = 1
Shadow.Image              = "rbxassetid://5028857084"
Shadow.ImageColor3        = Color3.new(0, 0, 0)
Shadow.ImageTransparency  = 0.5
Shadow.ScaleType          = Enum.ScaleType.Slice
Shadow.SliceCenter        = Rect.new(24, 24, 276, 276)
Shadow.ZIndex             = 2

-- 상단 바
local MTopBar = Instance.new("Frame", MainGui)
MTopBar.Size             = UDim2.new(1, 0, 0, 38)
MTopBar.BackgroundColor3 = C.TopBar
MTopBar.BorderSizePixel  = 0
MTopBar.ZIndex           = 4
Instance.new("UICorner", MTopBar).CornerRadius = UDim.new(0, 12)

local MTopFix = Instance.new("Frame", MTopBar)
MTopFix.Size             = UDim2.new(1, 0, 0.5, 0)
MTopFix.Position         = UDim2.new(0, 0, 0.5, 0)
MTopFix.BackgroundColor3 = C.TopBar
MTopFix.BorderSizePixel  = 0
MTopFix.ZIndex           = 4

local MTitle = Instance.new("TextLabel", MTopBar)
MTitle.Size               = UDim2.new(1, -80, 1, 0)
MTitle.Position           = UDim2.new(0, 16, 0, 0)
MTitle.Text               = "⚡  FFA Hub"
MTitle.TextColor3         = C.Text
MTitle.Font               = Enum.Font.GothamBold
MTitle.TextSize           = 14
MTitle.BackgroundTransparency = 1
MTitle.TextXAlignment     = Enum.TextXAlignment.Left
MTitle.ZIndex             = 5

-- 닫기 버튼
local CloseBtn = Instance.new("TextButton", MTopBar)
CloseBtn.Size             = UDim2.new(0, 26, 0, 26)
CloseBtn.Position         = UDim2.new(1, -32, 0.5, -13)
CloseBtn.Text             = "✕"
CloseBtn.BackgroundColor3 = C.Red
CloseBtn.TextColor3       = Color3.new(1,1,1)
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 12
CloseBtn.BorderSizePixel  = 0
CloseBtn.ZIndex           = 5
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

makeDraggable(MTopBar, MainGui)

-- ============================================================
-- [ 7 ] 좌측 탭 사이드바
-- ============================================================

local Sidebar = Instance.new("Frame", MainGui)
Sidebar.Size             = UDim2.new(0, 120, 1, -38)
Sidebar.Position         = UDim2.new(0, 0, 0, 38)
Sidebar.BackgroundColor3 = C.Tab
Sidebar.BorderSizePixel  = 0
Sidebar.ZIndex           = 4

local SideCorner = Instance.new("UICorner", Sidebar)
SideCorner.CornerRadius = UDim.new(0, 12)

-- 오른쪽 모서리 가림
local SideFix = Instance.new("Frame", Sidebar)
SideFix.Size             = UDim2.new(0.5, 0, 1, 0)
SideFix.Position         = UDim2.new(0.5, 0, 0, 0)
SideFix.BackgroundColor3 = C.Tab
SideFix.BorderSizePixel  = 0
SideFix.ZIndex           = 4

local SideList = Instance.new("UIListLayout", Sidebar)
SideList.Padding         = UDim.new(0, 4)
SideList.SortOrder       = Enum.SortOrder.LayoutOrder
SideList.HorizontalAlignment = Enum.HorizontalAlignment.Center

local SidePad = Instance.new("UIPadding", Sidebar)
SidePad.PaddingTop    = UDim.new(0, 10)
SidePad.PaddingLeft   = UDim.new(0, 8)
SidePad.PaddingRight  = UDim.new(0, 8)

-- ============================================================
-- [ 8 ] 콘텐츠 영역
-- ============================================================

local ContentArea = Instance.new("Frame", MainGui)
ContentArea.Size             = UDim2.new(1, -128, 1, -46)
ContentArea.Position         = UDim2.new(0, 124, 0, 42)
ContentArea.BackgroundTransparency = 1
ContentArea.ZIndex           = 4

-- ============================================================
-- [ 9 ] 탭 / 체크박스 빌더
-- ============================================================

local tabs = {}
local activeTab = nil

-- 탭 버튼 생성
local function createTabButton(name, icon, order)
    local Btn = Instance.new("TextButton", Sidebar)
    Btn.Size             = UDim2.new(1, 0, 0, 38)
    Btn.Text             = icon .. "  " .. name
    Btn.BackgroundColor3 = C.Tab
    Btn.TextColor3       = C.SubText
    Btn.Font             = Enum.Font.GothamBold
    Btn.TextSize         = 12
    Btn.BorderSizePixel  = 0
    Btn.LayoutOrder      = order
    Btn.ZIndex           = 5
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)

    -- 좌측 강조 바
    local Indicator = Instance.new("Frame", Btn)
    Indicator.Size             = UDim2.new(0, 3, 0.6, 0)
    Indicator.Position         = UDim2.new(0, 0, 0.2, 0)
    Indicator.BackgroundColor3 = C.TabActive
    Indicator.BorderSizePixel  = 0
    Indicator.Visible          = false
    Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)

    return Btn, Indicator
end

-- 탭 콘텐츠 프레임 생성
local function createTabFrame()
    local F = Instance.new("ScrollingFrame", ContentArea)
    F.Size                 = UDim2.new(1, 0, 1, 0)
    F.BackgroundTransparency = 1
    F.BorderSizePixel      = 0
    F.ScrollBarThickness   = 4
    F.ScrollBarImageColor3 = C.Accent
    F.Visible              = false
    F.ZIndex               = 4

    local List = Instance.new("UIListLayout", F)
    List.Padding    = UDim.new(0, 8)
    List.SortOrder  = Enum.SortOrder.LayoutOrder
    List.FillDirection = Enum.FillDirection.Vertical

    local Pad = Instance.new("UIPadding", F)
    Pad.PaddingTop   = UDim.new(0, 8)
    Pad.PaddingLeft  = UDim.new(0, 4)
    Pad.PaddingRight = UDim.new(0, 8)

    -- 스크롤 자동 캔버스 높이
    List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        F.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 16)
    end)

    return F
end

-- 탭 등록
local function registerTab(name, icon, order)
    local btn, ind = createTabButton(name, icon, order)
    local frame     = createTabFrame()

    local entry = {btn = btn, frame = frame, ind = ind}
    tabs[name]  = entry

    btn.MouseButton1Click:Connect(function()
        -- 이전 탭 비활성화
        if activeTab then
            easeTween(activeTab.btn, 0.15, {
                BackgroundColor3 = C.Tab,
                TextColor3       = C.SubText
            })
            activeTab.ind.Visible    = false
            activeTab.frame.Visible  = false
        end
        -- 새 탭 활성화
        easeTween(btn, 0.15, {
            BackgroundColor3 = C.TabActive,
            TextColor3       = C.Text
        })
        ind.Visible    = true
        frame.Visible  = true
        activeTab      = entry
    end)

    return frame
end

-- ============================================================
-- [ 10 ] 체크박스 토글 생성 함수
-- ============================================================

local toggleStates = {}

local function createToggle(parent, label, desc, order, callback)
    local Row = Instance.new("Frame", parent)
    Row.Size             = UDim2.new(1, -8, 0, 54)
    Row.BackgroundColor3 = C.BG
    Row.BorderSizePixel  = 0
    Row.LayoutOrder      = order
    Row.ZIndex           = 5
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)
    local rStroke = Instance.new("UIStroke", Row)
    rStroke.Color     = C.Stroke
    rStroke.Thickness = 1

    -- 체크박스 (네모 칸)
    local CheckBox = Instance.new("TextButton", Row)
    CheckBox.Size             = UDim2.new(0, 22, 0, 22)
    CheckBox.Position         = UDim2.new(1, -32, 0.5, -11)
    CheckBox.Text             = ""
    CheckBox.BackgroundColor3 = C.CheckOff
    CheckBox.BorderSizePixel  = 0
    CheckBox.ZIndex           = 6
    Instance.new("UICorner", CheckBox).CornerRadius = UDim.new(0, 5)
    local cStroke = Instance.new("UIStroke", CheckBox)
    cStroke.Color     = C.Stroke
    cStroke.Thickness = 1.5

    -- 체크 표시 (V 아이콘)
    local CheckMark = Instance.new("TextLabel", CheckBox)
    CheckMark.Size               = UDim2.new(1, 0, 1, 0)
    CheckMark.Text               = "✓"
    CheckMark.TextColor3         = Color3.new(1, 1, 1)
    CheckMark.Font               = Enum.Font.GothamBold
    CheckMark.TextSize           = 14
    CheckMark.BackgroundTransparency = 1
    CheckMark.Visible            = false
    CheckMark.ZIndex             = 7

    local LabelT = Instance.new("TextLabel", Row)
    LabelT.Size               = UDim2.new(1, -50, 0, 20)
    LabelT.Position           = UDim2.new(0, 12, 0, 8)
    LabelT.Text               = label
    LabelT.TextColor3         = C.Text
    LabelT.Font               = Enum.Font.GothamBold
    LabelT.TextSize           = 13
    LabelT.BackgroundTransparency = 1
    LabelT.TextXAlignment     = Enum.TextXAlignment.Left
    LabelT.ZIndex             = 6

    if desc and desc ~= "" then
        local DescT = Instance.new("TextLabel", Row)
        DescT.Size               = UDim2.new(1, -50, 0, 16)
        DescT.Position           = UDim2.new(0, 12, 0, 30)
        DescT.Text               = desc
        DescT.TextColor3         = C.SubText
        DescT.Font               = Enum.Font.Gotham
        DescT.TextSize           = 11
        DescT.BackgroundTransparency = 1
        DescT.TextXAlignment     = Enum.TextXAlignment.Left
        DescT.ZIndex             = 6
    end

    local state = false
    toggleStates[label] = false

    local function toggle()
        state = not state
        toggleStates[label] = state

        if state then
            easeTween(CheckBox, 0.18, {BackgroundColor3 = C.CheckOn})
            cStroke.Color  = C.Accent
            CheckMark.Visible = true
            easeTween(Row, 0.18, {BackgroundColor3 = Color3.fromRGB(20, 18, 35)})
            rStroke.Color = C.Accent
            notify("기능 활성화", label .. " ON", C.Green)
        else
            easeTween(CheckBox, 0.18, {BackgroundColor3 = C.CheckOff})
            cStroke.Color  = C.Stroke
            CheckMark.Visible = false
            easeTween(Row, 0.18, {BackgroundColor3 = C.BG})
            rStroke.Color = C.Stroke
            notify("기능 비활성화", label .. " OFF", C.Red)
        end

        if callback then callback(state) end
    end

    CheckBox.MouseButton1Click:Connect(toggle)
    Row.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then toggle() end
    end)

    return Row
end

-- 섹션 헤더
local function createSection(parent, text, order)
    local S = Instance.new("Frame", parent)
    S.Size             = UDim2.new(1, -8, 0, 28)
    S.BackgroundTransparency = 1
    S.LayoutOrder      = order
    S.ZIndex           = 5

    local Line = Instance.new("Frame", S)
    Line.Size             = UDim2.new(1, 0, 0, 1)
    Line.Position         = UDim2.new(0, 0, 0.5, 0)
    Line.BackgroundColor3 = C.Stroke
    Line.BorderSizePixel  = 0
    Line.ZIndex           = 5

    local SLabel = Instance.new("TextLabel", S)
    SLabel.Size               = UDim2.new(0, 100, 1, 0)
    SLabel.Position           = UDim2.new(0, 8, 0, 0)
    SLabel.Text               = "  " .. text .. "  "
    SLabel.TextColor3         = C.Accent
    SLabel.Font               = Enum.Font.GothamBold
    SLabel.TextSize           = 11
    SLabel.BackgroundColor3   = C.Panel
    SLabel.BackgroundTransparency = 0
    SLabel.BorderSizePixel    = 0
    SLabel.ZIndex             = 6
    SLabel.AutomaticSize      = Enum.AutomaticSize.X

    return S
end

-- ============================================================
-- [ 11 ] 탭 콘텐츠 등록
-- ============================================================

-- 탭 프레임 생성
local MainFrame     = registerTab("Main",     "⚡", 1)
local VisualFrame   = registerTab("Visual",   "👁", 2)
local SettingsFrame = registerTab("Settings", "⚙", 3)

-- ── Main 탭 ──────────────────────────────────────────────

createSection(MainFrame, "Combat", 1)

createToggle(MainFrame, "Silent Aim", "조용한 에임 보정", 2, function(on)
    -- 기능 구현 영역
end)

createToggle(MainFrame, "Aimbot", "자동 에임 타겟팅", 3, function(on)
    -- 기능 구현 영역
end)

createToggle(MainFrame, "Anti-Ragdoll", "래그돌 방지", 4, function(on)
    -- 기능 구현 영역
end)

createSection(MainFrame, "Movement", 5)

createToggle(MainFrame, "Speed Hack", "이동 속도 증가", 6, function(on)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            hum.WalkSpeed = on and 32 or 16
        end
    end
end)

createToggle(MainFrame, "Infinite Jump", "무한 점프 활성화", 7, function(on)
    if on then
        _G.InfJump = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
    else
        if _G.InfJump then
            _G.InfJump:Disconnect()
            _G.InfJump = nil
        end
    end
end)

createToggle(MainFrame, "No Clip", "벽 통과 활성화", 8, function(on)
    _G.NoClip = on
    if on then
        _G.NoClipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                    v.CanCollide = false
                end
            end
        end)
    else
        if _G.NoClipConn then
            _G.NoClipConn:Disconnect()
            _G.NoClipConn = nil
        end
    end
end)

-- ── Visual 탭 ─────────────────────────────────────────────

createSection(VisualFrame, "ESP", 1)

createToggle(VisualFrame, "Player ESP", "플레이어 하이라이트", 2, function(on)
    -- 기능 구현 영역
end)

createToggle(VisualFrame, "Box ESP", "플레이어 박스 표시", 3, function(on)
    -- 기능 구현 영역
end)

createToggle(VisualFrame, "Name ESP", "플레이어 이름 표시", 4, function(on)
    -- 기능 구현 영역
end)

createToggle(VisualFrame, "Chams", "플레이어 색상 강조", 5, function(on)
    -- 기능 구현 영역
end)

createSection(VisualFrame, "World", 6)

createToggle(VisualFrame, "Full Bright", "화면 밝기 최대화", 7, function(on)
    game:GetService("Lighting").Brightness = on and 10 or 2
    game:GetService("Lighting").ClockTime  = on and 14 or game:GetService("Lighting").ClockTime
end)

-- ── Settings 탭 ───────────────────────────────────────────

createSection(SettingsFrame, "Interface", 1)

createToggle(SettingsFrame, "Always On Top", "GUI 항상 최상위 표시", 2, function(on)
    -- 기능 구현 영역
end)

createToggle(SettingsFrame, "Notifications", "알림 표시 ON/OFF", 3, function(on)
    -- 기능 구현 영역
end)

createSection(SettingsFrame, "Account", 4)

createToggle(SettingsFrame, "Auto-Rejoin", "자동 재접속", 5, function(on)
    -- 기능 구현 영역
end)

-- 첫 번째 탭 자동 선택
do
    local firstEntry = tabs["Main"]
    if firstEntry then
        firstEntry.btn.BackgroundColor3 = C.TabActive
        firstEntry.btn.TextColor3       = C.Text
        firstEntry.ind.Visible          = true
        firstEntry.frame.Visible        = true
        activeTab = firstEntry
    end
end

-- ============================================================
-- [ 12 ] F 버튼 (토글 버튼)
-- ============================================================

local FBtn = Instance.new("TextButton", ScreenGui)
FBtn.Size             = UDim2.new(0, 44, 0, 44)
FBtn.Position         = UDim2.new(0, 16, 0.5, -22)
FBtn.Text             = "F"
FBtn.BackgroundColor3 = C.Accent
FBtn.TextColor3       = Color3.new(1, 1, 1)
FBtn.Font             = Enum.Font.GothamBold
FBtn.TextSize         = 18
FBtn.BorderSizePixel  = 0
FBtn.ZIndex           = 10
Instance.new("UICorner", FBtn).CornerRadius = UDim.new(0, 8)

local fStroke = Instance.new("UIStroke", FBtn)
fStroke.Color     = C.AccentHov
fStroke.Thickness = 2

makeDraggable(FBtn, FBtn)

FBtn.MouseEnter:Connect(function()
    easeTween(FBtn, 0.15, {
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(
            FBtn.Position.X.Scale, FBtn.Position.X.Offset - 3,
            FBtn.Position.Y.Scale, FBtn.Position.Y.Offset - 3
        )
    })
end)
FBtn.MouseLeave:Connect(function()
    easeTween(FBtn, 0.15, {
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.new(
            FBtn.Position.X.Scale, FBtn.Position.X.Offset + 3,
            FBtn.Position.Y.Scale, FBtn.Position.Y.Offset + 3
        )
    })
end)

local guiVisible = true

FBtn.MouseButton1Click:Connect(function()
    guiVisible = not guiVisible

    if guiVisible then
        MainGui.Visible = true
        MainGui.BackgroundTransparency = 1
        easeTween(MainGui, 0.3, {BackgroundTransparency = 0})
    else
        easeTween(MainGui, 0.25, {BackgroundTransparency = 1}).Completed:Wait()
        MainGui.Visible = false
    end
end)

-- ============================================================
-- [ 13 ] 닫기 버튼
-- ============================================================

CloseBtn.MouseButton1Click:Connect(function()
    guiVisible = false
    easeTween(MainGui, 0.25, {BackgroundTransparency = 1}).Completed:Wait()
    MainGui.Visible = false
end)

-- ============================================================
-- [ 14 ] 키 버튼 로직
-- ============================================================

local function showMainGui()
    KeyPanel:Destroy()

    MainGui.Visible = true
    MainGui.BackgroundTransparency = 1
    MainGui.Position = UDim2.new(0.5, -290, 0.5, -210)

    easeTween(MainGui, 0.45, {
        BackgroundTransparency = 0,
        Position = UDim2.new(0.5, -290, 0.5, -190)
    })

    notify("FFA Hub", "스크립트가 로드되었습니다 ✔", C.Green)
end

-- Get Key
GetKeyBtn.MouseButton1Click:Connect(function()
    local url = "https://ntt-system.xyz/key.html?domain=ffa-hub&hwid=" .. you_hwid
    local ok2 = pcall(function() setclipboard(url) end)
    if ok2 then
        KStatus.TextColor3 = C.Green
        KStatus.Text = "✔  키 링크가 클립보드에 복사되었습니다!"
    else
        KStatus.TextColor3 = C.SubText
        KStatus.Text = "클립보드 미지원 환경입니다"
    end
end)

-- Verify Key
VerifyBtn.MouseButton1Click:Connect(function()
    local inputKey = KBox.Text
    if inputKey == "" then
        KStatus.TextColor3 = C.Red
        KStatus.Text = "✖  키를 입력해 주세요"
        return
    end

    KStatus.TextColor3 = C.SubText
    KStatus.Text = "🔄  확인 중..."

    local success, result = pcall(function()
        return domain_control(you_hwid)
    end)

    if success and result and string.find(result, "|") then
        local ok3, decoded = pcall(function()
            return key_decode(result, "ffa-hub")
        end)

        if ok3 and decoded then
            local parts = string.split(decoded, "|")
            if inputKey == parts[1] then
                KStatus.TextColor3 = C.Green
                KStatus.Text = "✔  인증 성공!"

                local L2 = createLoader("스크립트 로딩 중...")
                task.wait(2)
                easeTween(L2, 0.35, {BackgroundTransparency = 1}).Completed:Wait()
                L2:Destroy()

                showMainGui()
            else
                KStatus.TextColor3 = C.Red
                KStatus.Text = "✖  잘못된 키입니다"
            end
        else
            KStatus.TextColor3 = C.Red
            KStatus.Text = "✖  키 디코딩 실패"
        end
    else
        -- 개발/테스트용 우회 (배포 시 제거)
        if inputKey == "TEST-KEY-FFA" then
            KStatus.TextColor3 = C.Green
            KStatus.Text = "✔  테스트 키 승인됨"
            task.wait(0.5)
            showMainGui()
        else
            KStatus.TextColor3 = C.Red
            KStatus.Text = "✖  서버 검증 실패 — 키를 확인하세요"
        end
    end
end)

-- ============================================================
-- [ 15 ] 초기화 완료 알림
-- ============================================================

task.wait(0.2)
-- 키 패널이 표시된 상태이므로 간단한 힌트만 출력
KStatus.TextColor3 = C.SubText
KStatus.Text = "키를 입력하거나 Get Key를 눌러 주세요"
