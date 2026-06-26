-- <3 pedro
--!nocheck
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local StarterGui = game:GetService("StarterGui")

pcall(function(...)
	StarterGui:SetCore("ResetButtonCallback", false)
end)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

local Interface: ScreenGui = PlayerGui:WaitForChild("Interface")
local HomeFrame: Frame = Interface:FindFirstChild("HomeFrame")
local RenderFrame: Frame = Interface:FindFirstChild("RenderFrame")

local SoundService = game:GetService("SoundService")
local Bass = SoundService.Bass

local Render = RenderFrame.Render

local Template = Render.Template
local Bar: Frame = Template.Bar

local InformationFrame = RenderFrame.InformationFrame

-- RenderFrame
local ArraySuccesses = InformationFrame.ArraySuccesses
local InternalDelay = InformationFrame.InternalDelay
local InfoAlgorithmType = InformationFrame.InfoAlgorithmType
local InfoBarQuantity = InformationFrame.InfoBarQuantity
local ComparisonCount = InformationFrame.ComparisonCount
local SwapCount = InformationFrame.SwapCount

-- HomeFrame
local DropdownValues = HomeFrame.DropdownValues
local AlgorithmType = DropdownValues.AlgorithmType

local BarQuantityInput = HomeFrame.BarQuantityInput
local DelayInput = HomeFrame.DelayInput
local RenderButton = HomeFrame.RenderButton

-- CONST
local SETTINGS = {}

local PREVIOUS_BARS = {}
local ALL_BARS = {}

local INTERNAL_DELAY = 1.0 -- Milliseconds
local SELECTED_ALGORITHM = ""

-- Statistics
local COMPARISON_COUNT = 0
local ARRAY_SUCCESSES = 0
local SWAP_COUNT = 0

--> Here you can add any algorithm you want
local SORTING_ALGORITHMS = {
	["Insertion"] = function(Bars: { Frame })
		local total = #Bars

		for bar_idx: number = 2, total do
			ARRAY_SUCCESSES += 1
			local current_frame = Bars[bar_idx]
			local current_value = size(current_frame)
			local comparison_index = bar_idx - 1

			while comparison_index > 0 and current_value < size(Bars[comparison_index]) do
				COMPARISON_COUNT += 1
				SwapBar(Bars[comparison_index + 1], Bars[comparison_index])
				task.wait(INTERNAL_DELAY / 10 ^ 3)
				Bars[comparison_index + 1], Bars[comparison_index] = Bars[comparison_index], Bars[comparison_index + 1]
				comparison_index = comparison_index - 1
			end
		end
	end,
	["Bubble"] = function(Bars)
		local n = #Bars
		for i = 1, n - 1 do
			local swapped = false

			for j = 1, n - i do
				COMPARISON_COUNT += 1
				local left = Bars[j]
				local right = Bars[j + 1]

				if size(left) > size(right) then
					SwapBar(Bars[j], Bars[j + 1])
					Bars[j], Bars[j + 1] = Bars[j + 1], Bars[j]
					swapped = true
					task.wait(INTERNAL_DELAY / 10 ^ 3)
				end
			end
			ARRAY_SUCCESSES += 1

			if not swapped then
				break
			end
		end
	end,
	["Bogo"] = function(Bars: { Frame })
		repeat
			shuffle(Bars)
			task.wait(INTERNAL_DELAY / 10 ^ 3)
		until is_sorted(Bars)
	end,
	["Selection"] = function(Bars: { Frame })
		local total = #Bars

		for i = 1, total - 1 do
			local minimumIndex = i

			for j = i + 1, total do
				if size(Bars[j]) < size(Bars[minimumIndex]) then
					minimumIndex = j
				end
			end

			if minimumIndex ~= i then
				task.wait(INTERNAL_DELAY / 10 ^ 3)

				SwapBar(Bars[i], Bars[minimumIndex])
				Bars[i], Bars[minimumIndex] = Bars[minimumIndex], Bars[i]
			end
		end
	end,
	["Heap"] = function(Bars: { Frame })
		local n = #Bars

		local function siftDown(i, heapSize)
			while true do
				local largest = i
				local left = 2 * i
				local right = 2 * i + 1

				if left <= heapSize and size(Bars[left]) > size(Bars[largest]) then
					largest = left
				end
				if right <= heapSize and size(Bars[right]) > size(Bars[largest]) then
					largest = right
				end

				if largest == i then
					break
				end

				COMPARISON_COUNT += 1
				SwapBar(Bars[i], Bars[largest])
				Bars[i], Bars[largest] = Bars[largest], Bars[i]
				task.wait(INTERNAL_DELAY / 10 ^ 3)

				i = largest
			end
		end

		for i = math.floor(n / 2), 1, -1 do
			siftDown(i, n)
		end

		for heapSize = n, 2, -1 do
			SwapBar(Bars[1], Bars[heapSize])
			Bars[1], Bars[heapSize] = Bars[heapSize], Bars[1]
			task.wait(INTERNAL_DELAY / 10 ^ 3)
			ARRAY_SUCCESSES += 1

			siftDown(1, heapSize - 1)
		end
	end,
}

function size(bar: Frame)
	return bar.Size.Y.Scale
end

function is_sorted(bars: {})
	local previous = nil
	local sorted = true

	for _, bar in bars do
		if previous then
			if size(previous) > size(bar) then
				sorted = false
				break
			end
		end

		previous = bar
	end

	return sorted
end

function SwapBar(Bar1, Bar2)
	SWAP_COUNT += 1
	local Pos1, Pos2 = Bar1.Position, Bar2.Position
	Bar1.Position = Pos2
	Bar2.Position = Pos1

	if #PREVIOUS_BARS >= 2 then
		for _, BAR in PREVIOUS_BARS do
			BAR.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		end
	end

	--> Prevent loud noises because bogo do be like that
	if SELECTED_ALGORITHM ~= "Bogo" then
		local newBass = Bass:Clone()
		newBass.Parent = game.Workspace
		newBass.PlaybackSpeed = 1 + Bar2.Size.Y.Scale
		newBass.PlayOnRemove = true
		newBass:Remove()
	end

	Bar1.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	Bar2.BackgroundColor3 = Color3.fromRGB(0, 255, 0)

	PREVIOUS_BARS[1] = Bar1
	PREVIOUS_BARS[2] = Bar2
end

function shuffle(t)
	for i = #t, 2, -1 do
		local j = math.random(i)

		SwapBar(t[i], t[j])
		t[i], t[j] = t[j], t[i]
	end
end

function UpdateInformation()
	InternalDelay.Text = "internal delay - " .. INTERNAL_DELAY .. "ms"
	InfoAlgorithmType.Text = "algorithm type - " .. AlgorithmType.Value
	InfoBarQuantity.Text = "bar count - " .. SETTINGS.BAR_N
	ArraySuccesses.Text = "array successes - " .. ARRAY_SUCCESSES
	ComparisonCount.Text = "comparison count - " .. COMPARISON_COUNT
	SwapCount.Text = "swap count - " .. SWAP_COUNT
end

function Startrender()
	--> Set up everything accordingly to the provided settings
	SETTINGS = {
		BAR_N = tonumber(BarQuantityInput.Text),
		ALGO_TYPE = AlgorithmType.Value,
		INT_DELAY_MS = tonumber(DelayInput.Text),
	}

	if SETTINGS.BAR_N < 5 then
		return warn("err: There is a strict requirement of at least 5 bars for a renderization.")
	end

	local F_ALGO_TYPE = SETTINGS.ALGO_TYPE:gsub(" ", "")
	SELECTED_ALGORITHM = F_ALGO_TYPE

	INTERNAL_DELAY = SETTINGS.INT_DELAY_MS

	local PreviousBar = nil
	for i = 1, SETTINGS.BAR_N do
		local newBar = Bar:Clone()

		ALL_BARS[i] = newBar
		newBar.Visible = true
		newBar.BorderSizePixel = 0
		newBar.Name = i
		newBar.Size = UDim2.new((1 / SETTINGS.BAR_N) * 0.97, 0, (i / SETTINGS.BAR_N), 0)
		newBar.Position = (
			if not PreviousBar
				then UDim2.new(0.0125, 0, 0, 0)
				else PreviousBar.Position + UDim2.new(PreviousBar.Size.X, 0, 0, 0)
		)
		newBar.Parent = Render

		PreviousBar = newBar
	end

	--> upd
	coroutine.resume(coroutine.create(function()
		while task.wait(1 / 60) do
			UpdateInformation()
		end
	end))

	HomeFrame.Visible = false
	RenderFrame.Visible = true
	shuffle(ALL_BARS)

	task.wait(3)
	SORTING_ALGORITHMS[F_ALGO_TYPE](ALL_BARS)
end

RenderButton.MouseButton1Click:Connect(function()
	Startrender()
end)

-- Dark and light mode (CuriousQ's suggestion)

local ThemeInfo = {
	Light = {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		TextColor3 = Color3.fromRGB(0, 0, 0),
		ButtonTextColor3 = Color3.fromRGB(255, 255, 255),
		ButtonBackgroundColor3 = Color3.fromRGB(131, 131, 131),
		DropdownOptionBackgroundColor3 = Color3.fromRGB(131, 131, 131),
		DropdownOptionBackgroundTransparency = 0.45,
		DropdownOptionTextColor3 = Color3.fromRGB(255, 255, 255),
		StatisticLabelTextColor3 = Color3.fromRGB(131, 131, 131),
		ArbitraryInfoTextColor3 = Color3.fromRGB(131, 131, 131),
		InputBoxTextColor3 = Color3.fromRGB(0, 0, 0)
	},
	Dark = {
		BackgroundColor3 = Color3.fromRGB(32, 32, 32),
		TextColor3 = Color3.fromRGB(235, 235, 235),
		ButtonTextColor3 = Color3.fromRGB(235, 235, 235),
		ButtonBackgroundColor3 = Color3.fromRGB(0, 0, 0),
		DropdownOptionBackgroundColor3 = Color3.fromRGB(45, 45, 45),
		DropdownOptionBackgroundTransparency = 0.45,
		DropdownOptionTextColor3 = Color3.fromRGB(235, 235, 235),
		StatisticLabelTextColor3 = Color3.fromRGB(244, 244, 244),
		ArbitraryInfoTextColor3 = Color3.fromRGB(189, 189, 189),
		InputBoxTextColor3 = Color3.fromRGB(235, 235, 235)
	},
}

local CurrentTheme = "Light" --> Standard setting
local _Debounce = false

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local CollectionService = game:GetService("CollectionService")

local TweenInf = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0)

UserInputService.InputBegan:Connect(function(inputObject: InputObject, chatting: boolean)
	if not chatting and inputObject.KeyCode == Enum.KeyCode.T then
		if _Debounce then return end

		_Debounce = true

		CurrentTheme = if CurrentTheme == "Light" then "Dark" else "Light"
		local ThemeInformation = ThemeInfo[CurrentTheme]

		for _, Instance in CollectionService:GetTagged("Background") do
			TweenService:Create(Instance, TweenInf, {
				BackgroundColor3 = ThemeInformation.BackgroundColor3,
			}):Play()
		end

		for _, Instance in CollectionService:GetTagged("Statistics") do
			TweenService:Create(Instance, TweenInf, {
				TextColor3 = ThemeInformation.StatisticLabelTextColor3,
			}):Play()
		end

		for _, Instance in CollectionService:GetTagged("ArbitraryInformation") do
			TweenService:Create(Instance, TweenInf, {
				TextColor3 = ThemeInformation.ArbitraryInfoTextColor3
			}):Play()
		end

		for _, Instance in CollectionService:GetTagged("DropdownOption") do
			TweenService:Create(Instance, TweenInf, {
				BackgroundColor3 = ThemeInformation.DropdownOptionBackgroundColor3,
				TextColor3 = ThemeInformation.DropdownOptionTextColor3,
				BackgroundTransparency = ThemeInformation.DropdownOptionBackgroundTransparency
			}):Play()
		end

		for _, Instance in CollectionService:GetTagged("TextButton") do
			TweenService:Create(Instance, TweenInf, {
				BackgroundColor3 = ThemeInformation.ButtonBackgroundColor3,
				TextColor3 = ThemeInformation.ButtonTextColor3
			}):Play()
		end

		for _, Instance in CollectionService:GetTagged("StandardText") do
			TweenService:Create(Instance, TweenInf, {
				TextColor3 = ThemeInformation.TextColor3
			}):Play()
		end

		for _, Instance in CollectionService:GetTagged("InputBox") do
			TweenService:Create(Instance, TweenInf, {
				TextColor3 = ThemeInformation.InputBoxTextColor3
			}):Play()
		end

		task.wait(1)
		_Debounce = false
	end
end)
