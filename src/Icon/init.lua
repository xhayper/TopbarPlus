--[[
	
	The majority of this code is an interface designed to make it easy for you to
	work with TopbarPlus (most methods for instance reference :modifyTheme()).
	The processing overhead mainly consists of applying themes and calculating 
	appearance (such as size and width of labels) which is handled in about
	200 lines of code here and the Widget UI module. This has been achieved
	in v3 by outsourcing a majority of previous calculations to inbuilt Roblox
	features like UIListLayouts.


	v3 provides inbuilt support for controllers (simply press DPadUp),
	touch devices (phones, tablets , etc), localization (automatic resizing
	of widgets, autolocalize for relevant labels), backwards compatability
	with the old topbar, and more.


	My primary goals for the v3 re-write have been to:
		
	1. Improve code readability and organisation (reduced lines of code within
	   Icon+IconController from 3200 to ~950, separated UI elements, etc)
		
	2. Improve ease-of-use (themes now actually make sense and can account
	   for any modifications you want, converted to a package for
	   quick installation and easy-comparisons of new updates, etc)
	
	3. Provide support for all key features of the new Roblox topbar
	   while improving performance of the module (deferring and collecting
	   changes then calling as a singular, utilizing inbuilt Roblox features
	   such as UILIstLayouts, etc)

--]]

--!strict

-- SERVICES
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local Typing = require(script.Typing)

type Icon = Typing.Icon

-- REFERENCE HANDLER
-- Multiple Icons packages may exist at runtime (for instance if the developer additionally uses HD Admin)
-- therefore this ensures that the first required package becomes the dominant and only functioning module

local iconModule = script
local Reference = require(iconModule.Reference)
local referenceObject = Reference.getObject()
local leadPackage = referenceObject and referenceObject.Value

if leadPackage and leadPackage ~= iconModule then
	return require(leadPackage)
end

if not referenceObject then
	Reference.addToReplicatedStorage()
end

-- MODULES

require(iconModule.Attribute)

local Signal = require(iconModule.Packages.GoodSignal) :: Typing.GoodSignal
local Janitor = require(iconModule.Packages.Janitor) :: Typing.Janitor
local Utility = require(iconModule.Utility)
local Themes = require(iconModule.Features.Themes)
local Gamepad = require(iconModule.Features.Gamepad)
local Overflow = require(iconModule.Features.Overflow)

local Icon = ({} :: any) :: Typing.StaticIcon
Icon.ClassName = "Icon";
(Icon :: any).__index = Icon

--- LOCAL
local localPlayer = Players.LocalPlayer
local themes = iconModule.Features.Themes
local playerGui = localPlayer:WaitForChild("PlayerGui")
local iconsDict: { [string]: Icon } = {}
local anyIconSelected = Signal.new() :: Typing.GoodSignal<Icon, string?, Icon?>
local elements = iconModule.Elements
local totalCreatedIcons = 0

-- PRESETUP
-- This is only used to determine if we need to apply the old topbar theme
-- I'll be removing this and associated functions once all games have
-- fully transitioned over to the new topbar
if GuiService.TopbarInset.Height == 0 then
	GuiService:GetPropertyChangedSignal("TopbarInset"):Wait()
end

-- PUBLIC VARIABLES
Icon.baseDisplayOrderChanged = Signal.new()
Icon.baseDisplayOrder = 10
Icon.baseTheme = require(themes.Default)

Icon.isOldTopbar = GuiService.TopbarInset.Height == 36

Icon.iconsDictionary = iconsDict

Icon.container = require(elements.Container)(Icon)

Icon.topbarEnabled = true

Icon.iconAdded = Signal.new() :: Typing.GoodSignal<Icon>
Icon.iconRemoved = Signal.new() :: Typing.GoodSignal<Icon>
Icon.iconChanged = Signal.new() :: Typing.GoodSignal<Icon>

-- PUBLIC FUNCTIONS

function Icon.getIcons(): { [string]: Icon }
	return Icon.iconsDictionary
end

function Icon.getIconByUID(UID: string): Icon?
	local match = Icon.iconsDictionary[UID]

	if match then
		return match
	end

	return
end

function Icon.getIcon(nameOrUID: string): Icon?
	local match = Icon.getIconByUID(nameOrUID)
	if match then
		return match
	end

	for _, icon in iconsDict do
		if icon.name == nameOrUID then
			return icon
		end
	end

	return
end

function Icon.setTopbarEnabled(bool: boolean, isInternal: boolean): ()
	if typeof(bool) ~= "boolean" then
		bool = Icon.topbarEnabled
	end

	if not isInternal then
		Icon.topbarEnabled = bool
	end

	for _, screenGui in Icon.container do
		screenGui.Enabled = bool
	end
end

function Icon.modifyBaseTheme(modifications: Typing.ThemeModification): ()
	modifications = Themes.getModifications(modifications)

	for _, modification in modifications do
		for _, detail in Icon.baseTheme do
			Themes.merge(detail, modification)
		end
	end

	for _, icon in iconsDict do
		(icon :: Icon):setTheme(Icon.baseTheme)
	end
end

function Icon.setDisplayOrder(int: number): ()
	Icon.baseDisplayOrder = int
	Icon.baseDisplayOrderChanged:Fire(int)
end

-- SETUP
task.defer(Gamepad.start, Icon)
task.defer(Overflow.start, Icon)

for _, screenGui in Icon.container do
	screenGui.Parent = playerGui
end

if Icon.isOldTopbar then
	Icon.modifyBaseTheme(require(themes.Classic))
end

-- CONSTRUCTOR
function Icon.new(): Icon
	local self = (setmetatable({}, Icon) :: any) :: Icon

	--- Janitors (for cleanup)
	local janitor = Janitor.new()
	self.janitor = janitor
	self.themesJanitor = janitor:add(Janitor.new())
	self.singleClickJanitor = janitor:add(Janitor.new())
	self.captionJanitor = janitor:add(Janitor.new())
	self.joinJanitor = janitor:add(Janitor.new())
	self.menuJanitor = janitor:add(Janitor.new())
	self.dropdownJanitor = janitor:add(Janitor.new())

	-- Register
	local iconUID = Utility.generateUID()
	iconsDict[iconUID] = self
	janitor:add(function()
		iconsDict[iconUID] = nil
	end)

	-- Signals (events)
	self.selected = janitor:add(Signal.new())
	self.deselected = janitor:add(Signal.new())
	self.toggled = janitor:add(Signal.new())
	self.viewingStarted = janitor:add(Signal.new())
	self.viewingEnded = janitor:add(Signal.new())
	self.stateChanged = janitor:add(Signal.new())
	self.notified = janitor:add(Signal.new())
	self.noticeStarted = janitor:add(Signal.new())
	self.noticeChanged = janitor:add(Signal.new())
	self.endNotices = janitor:add(Signal.new())
	self.toggleKeyAdded = janitor:add(Signal.new())
	self.fakeToggleKeyChanged = janitor:add(Signal.new())
	self.alignmentChanged = janitor:add(Signal.new())
	self.updateSize = janitor:add(Signal.new())
	self.resizingComplete = janitor:add(Signal.new())
	self.joinedParent = janitor:add(Signal.new())
	self.menuSet = janitor:add(Signal.new())
	self.dropdownSet = janitor:add(Signal.new())
	self.updateMenu = janitor:add(Signal.new())
	self.startMenuUpdate = janitor:add(Signal.new())
	self.childThemeModified = janitor:add(Signal.new())
	self.indicatorSet = janitor:add(Signal.new())
	self.dropdownChildAdded = janitor:add(Signal.new())
	self.menuChildAdded = janitor:add(Signal.new())

	-- Properties
	self.iconModule = iconModule
	self.UID = iconUID
	self.isEnabled = true
	self.isSelected = false
	self.isViewing = false
	self.joinedFrame = false
	self.parentIconUID = false
	self.deselectWhenOtherIconSelected = true
	self.totalNotices = 0
	self.activeState = "Deselected"
	self.alignment = "Left"
	self.originalAlignment = "Left"
	self.appliedTheme = {}
	self.appearance = {}
	self.cachedInstances = {}
	self.cachedNamesToInstances = {}
	self.cachedCollectives = {}
	self.bindedToggleKeys = {}
	self.customBehaviours = {}
	self.toggleItems = {}
	self.bindedEvents = {}
	self.notices = {}
	self.menuIcons = {}
	self.dropdownIcons = {}
	self.childIconsDict = {}
	self.isOldTopbar = Icon.isOldTopbar
	self.creationTime = os.clock()

	-- Widget is the new name for an icon
	local widget = janitor:add(require(elements.Widget)(self, Icon))
	self.widget = widget

	self:setAlignment()

	-- It's important we set an order otherwise icons will not align
	-- correctly within menus
	totalCreatedIcons += 1
	local ourOrder = totalCreatedIcons
	self:setOrder(ourOrder)

	-- This applies the default them
	self:setTheme(Icon.baseTheme)

	-- Button Clicked (for states "Selected" and "Deselected")
	local clickRegion = self:getInstance("ClickRegion")

	local function handleToggle()
		if self.locked then
			return
		end

		if self.isSelected then
			self:deselect("User", self)
		else
			self:select("User", self)
		end
	end

	local isTouchTapping = false
	local isClicking = false

	clickRegion.MouseButton1Click:Connect(function()
		if isTouchTapping then
			return
		end

		isClicking = true

		task.delay(0.01, function()
			isClicking = false
		end)

		handleToggle()
	end)

	clickRegion.TouchTap:Connect(function()
		-- This resolves the bug report by @28Pixels:
		-- https://devforum.roblox.com/t/topbarplus/1017485/1104
		if isClicking then
			return
		end

		isTouchTapping = true

		task.delay(0.01, function()
			isTouchTapping = false
		end)

		handleToggle()
	end)

	-- Keys can be bound to toggle between Selected and Deselected
	janitor:add(UserInputService.InputBegan:Connect(function(input, touchingAnObject)
		if self.locked then
			return
		end

		if self.bindedToggleKeys[input.KeyCode] and not touchingAnObject then
			handleToggle()
		end
	end))

	-- Button Hovering (for state "Viewing")
	-- Hovering is a state only for devices with keyboards
	-- and controllers (not touchpads)
	local function viewingStarted(dontSetState: boolean?)
		if self.locked then
			return
		end

		self.isViewing = true
		self.viewingStarted:Fire(true)

		if not dontSetState then
			self:setState("Viewing", "User", self)
		end
	end

	local function viewingEnded()
		if self.locked then
			return
		end

		self.isViewing = false
		self.viewingEnded:Fire(true)

		self:setState(nil, "User", self)
	end

	self.joinedParent:Connect(function()
		if self.isViewing then
			viewingEnded()
		end
	end)

	clickRegion.MouseEnter:Connect(function()
		local dontSetState = not UserInputService.KeyboardEnabled
		viewingStarted(dontSetState)
	end)

	local touchCount = 0

	janitor:add(UserInputService.TouchEnded:Connect(viewingEnded))

	clickRegion.MouseLeave:Connect(viewingEnded)
	clickRegion.SelectionGained:Connect(viewingStarted)
	clickRegion.SelectionLost:Connect(viewingEnded)

	clickRegion.MouseButton1Down:Connect(function()
		if not self.locked and UserInputService.TouchEnabled then
			touchCount += 1
			local myTouchCount = touchCount

			task.delay(0.2, function()
				if myTouchCount == touchCount then
					viewingStarted()
				end
			end)
		end
	end)

	clickRegion.MouseButton1Up:Connect(function()
		touchCount += 1
	end)

	-- Handle overlay on viewing
	local iconOverlay = self:getInstance("IconOverlay")

	self.viewingStarted:Connect(function()
		iconOverlay.Visible = not self.overlayDisabled
	end)

	self.viewingEnded:Connect(function()
		iconOverlay.Visible = false
	end)

	-- Deselect when another icon is selected
	janitor:add(anyIconSelected:Connect(function(incomingIcon)
		if
			incomingIcon ~= self
			and self.deselectWhenOtherIconSelected
			and incomingIcon.deselectWhenOtherIconSelected
		then
			self:deselect("AutoDeselect", incomingIcon)
		end
	end))

	-- This checks if the script calling this module is a descendant of a ScreenGui
	-- with 'ResetOnSpawn' set to true. If it is, then we destroy the icon the
	-- client respawns. This solves one of the most asked about questions on the post
	-- The only caveat this may not work if the player doesn't uniquely name their ScreenGui and the frames
	-- the LocalScript rests within
	local source = debug.info(2, "s")
	local sourcePath = string.split(source, ".")
	local origin = game
	local originsScreenGui

	for _, sourceName in sourcePath do
		origin = origin:FindFirstChild(sourceName)
		if not origin then
			break
		end
		if origin:IsA("ScreenGui") then
			originsScreenGui = origin
		end
	end
	if origin and originsScreenGui and originsScreenGui.ResetOnSpawn == true then
		Utility.localPlayerRespawned(function()
			self:destroy()
		end)
	end

	-- Additional children behaviour when toggled (mostly notices)
	self.toggled:Connect(function(isSelected)
		self.noticeChanged:Fire(self.totalNotices)
		for childIconUID, _ in self.childIconsDict do
			local childIcon = Icon.getIconByUID(childIconUID)
			childIcon.noticeChanged:Fire(childIcon.totalNotices)
			if not isSelected and childIcon.isSelected then
				-- If an icon within a menu or dropdown is also
				-- a dropdown or menu, then close it
				for _, _ in childIcon.childIconsDict do
					childIcon:deselect("HideParentFeature", self)
				end
			end
		end
	end)

	-- This closes/reopens the chat or playerlist if the icon is a dropdown
	-- In the future I'd prefer to use the position+size of the chat
	-- to determine whether to close dropdown (instead of non-right-set)
	-- but for reasons mentioned here it's unreliable at the time of
	-- writing this: https://devforum.roblox.com/t/here/2794915
	-- I could also make this better by accounting for multiple
	-- dropdowns being open (not just this one) but this will work
	-- fine for almost every use case for now.
	self.selected:Connect(function()
		local isDropdown = #self.dropdownIcons > 0
		if isDropdown then
			if StarterGui:GetCore("ChatActive") and self.alignment ~= "Right" then
				self.chatWasPreviouslyActive = true
				StarterGui:SetCore("ChatActive", false)
			end
			if StarterGui:GetCoreGuiEnabled("PlayerList") and self.alignment ~= "Left" then
				self.playerlistWasPreviouslyActive = true
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
			end
		end
	end)

	self.deselected:Connect(function()
		if self.chatWasPreviouslyActive then
			self.chatWasPreviouslyActive = nil
			StarterGui:SetCore("ChatActive", true)
		end
		if self.playerlistWasPreviouslyActive then
			self.playerlistWasPreviouslyActive = nil
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
		end
	end)

	-- There's a rare occassion where the appearance is not
	-- fully set to deselected so this ensures the icons
	-- appearance is fully as it should be
	--print("self.activeState =", self.activeState)
	task.delay(0.1, function()
		if self.activeState == "Deselected" then
			self.stateChanged:Fire("Deselected")
			self:refresh()
		end
	end)

	-- Call icon added
	Icon.iconAdded:Fire(self)

	return self
end

-- METHODS
function Icon.setName(self: Icon, name: string): Icon
	self.widget.Name = name
	self.name = name
	return self
end

function Icon.setState(self: Icon, incomingStateName: Typing.IconState?, fromSource: string?, sourceIcon: Icon?): ()
	-- This is responsible for acknowleding a change in stage (such as from "Deselected" to "Viewing" when
	-- a users mouse enters the widget), then informing other systems of this state change to then act upon
	-- (such as the theme handler applying the theme which corresponds to that state).
	if not incomingStateName then
		incomingStateName = (self.isSelected and "Selected") or "Deselected"
	end

	local stateName = Utility.formatStateName((incomingStateName :: any) :: string) :: Typing.IconState
	local previousStateName = self.activeState
	if previousStateName == stateName then
		return
	end
	local currentIsSelected = self.isSelected
	self.activeState = stateName :: Typing.IconState
	if stateName == "Deselected" then
		self.isSelected = false
		if currentIsSelected then
			self.toggled:Fire(false, fromSource, sourceIcon)
			self.deselected:Fire(fromSource, sourceIcon)
		end
		self:_setToggleItemsVisible(false, sourceIcon)
	elseif stateName == "Selected" then
		self.isSelected = true
		if not currentIsSelected then
			self.toggled:Fire(true, fromSource, sourceIcon)
			self.selected:Fire(fromSource, sourceIcon)
			anyIconSelected:Fire(self, fromSource, sourceIcon)
		end
		self:_setToggleItemsVisible(true, sourceIcon)
	end
	self.stateChanged:Fire(stateName :: Typing.IconState, fromSource, sourceIcon)
end

function Icon.getInstance(self: Icon, name: string): Instance?
	-- This enables us to easily retrieve instances located within the icon simply by passing its name.
	-- Every important/significant instance is named uniquely therefore this is no worry of overlap.
	-- We cache the result for more performant retrieval in the future.
	local instance = self.cachedNamesToInstances[name]

	if instance then
		return instance
	end

	local function cacheInstance(childName: string, child: Instance)
		local currentCache = self.cachedInstances[child]
		if not currentCache then
			local collectiveName = child:GetAttribute("Collective")
			local cachedCollective = collectiveName and self.cachedCollectives[collectiveName]
			if cachedCollective then
				table.insert(cachedCollective, child)
			end
			self.cachedNamesToInstances[childName] = child
			self.cachedInstances[child] = true
			child.Destroying:Once(function()
				self.cachedNamesToInstances[childName] = nil
				self.cachedInstances[child] = nil
			end)
		end
	end

	local widget = self.widget

	cacheInstance("Widget", widget)

	if name == "Widget" then
		return widget
	end

	local returnChild
	local function scanChildren(parentInstance: Instance)
		for _, child in parentInstance:GetChildren() do
			local widgetUID = child:GetAttribute("WidgetUID")
			if widgetUID and widgetUID ~= self.UID then
				-- This prevents instances within other icons from being recorded
				-- (for instance when other icons are added to this icons menu)
				continue
			end

			-- If the child is a fake placeholder instance (such as dropdowns, notices, etc)
			-- then its important we scan the real original instance instead of this clone
			local realChild = Themes.getRealInstance(child)
			if realChild then
				child = realChild
			end

			-- Finally scan its children
			scanChildren(child)
			if child:IsA("GuiBase") or child:IsA("UIBase") or child:IsA("ValueBase") then
				local childName = child.Name
				cacheInstance(childName, child)
				if childName == name then
					returnChild = child
				end
			end
		end
	end

	scanChildren(widget)

	return returnChild
end

function Icon.getCollective(self: Icon, name: string): { Instance }
	-- A collective is an array of instances within the Widget that have been
	-- grouped together based on a given name. This just makes it easy
	-- to act on multiple instances at once which share similar behaviours.
	-- For instance, if we want to change the icons corner size, all corner instances
	-- with the attribute "Collective" and value "WidgetCorner" could be updated
	-- instantly by doing Themes.apply(icon, "WidgetCorner", newSize)
	local collective = self.cachedCollectives[name]
	if collective then
		return collective
	end

	local collective: { Instance } = {}

	for instance, _ in self.cachedInstances do
		if instance:GetAttribute("Collective") == name then
			table.insert(collective, instance)
		end
	end

	self.cachedCollectives[name] = collective

	return collective
end

function Icon.getInstanceOrCollective(self: Icon, collectiveOrInstanceName: string): { Instance }
	-- Similar to :getInstance but also accounts for 'Collectives', such as UICorners and returns
	-- an array of instances instead of a single instance
	local instances = {}
	local instance = self:getInstance(collectiveOrInstanceName)

	if instance then
		table.insert(instances, instance)
	end

	if #instances == 0 then
		instances = self:getCollective(collectiveOrInstanceName)
	end

	return instances
end

function Icon.getStateGroup(self: Icon, iconState: Typing.IconState?): Typing.IconStateGroup
	local chosenState: Typing.IconState = (iconState or self.activeState) :: Typing.IconState
	local stateGroup = self.appearance[chosenState]

	if not stateGroup then
		stateGroup = {}
		self.appearance[chosenState] = stateGroup
	end

	return stateGroup
end

function Icon.refreshAppearance(self: Icon, instance: Instance, specificProperty: string?): Icon
	Themes.refresh(self, instance, specificProperty)
	return self
end

function Icon.refresh(self: Icon): Icon
	self:refreshAppearance(self.widget)
	self.updateSize:Fire()
	return self
end

function Icon.updateParent(self: Icon): ()
	local parentIcon = Icon.getIconByUID(self.parentIconUID)
	if parentIcon then
		parentIcon.updateSize:Fire()
	end
end

function Icon.setBehaviour(
	self: Icon,
	collectiveOrInstanceName: string,
	property: string,
	callback: (...any) -> (),
	refreshAppearance: boolean?
): ()
	-- You can specify your own custom callback to handle custom logic just before
	-- an instances property is changed by using :setBehaviour()
	local key = `{collectiveOrInstanceName}-{property}`
	self.customBehaviours[key] = callback
	if refreshAppearance then
		local instances = self:getInstanceOrCollective(collectiveOrInstanceName)
		for _, instance in instances do
			self:refreshAppearance(instance, property)
		end
	end
end

function Icon.modifyTheme(self: Icon, modifications: Typing.ThemeModification, modificationUID: string?): (Icon, string)
	local modificationUID = Themes.modify(self, modifications, modificationUID)
	return self, modificationUID
end

function Icon.modifyChildTheme(self: Icon, modifications: Typing.ThemeModification, modificationUID: string): Icon
	-- Same as modifyTheme except for its children (i.e. icons
	-- within its dropdown or menu)
	self.childModifications = modifications
	self.childModificationsUID = modificationUID
	for childIconUID, _ in self.childIconsDict do
		local childIcon = Icon.getIconByUID(childIconUID)
		childIcon:modifyTheme(modifications, modificationUID)
	end
	self.childThemeModified:Fire()
	return self
end

function Icon.removeModification(self: Icon, modificationUID: string): Icon
	Themes.remove(self, modificationUID)
	return self
end

function Icon.removeModificationWith(self: Icon, instanceName: string, property: string, state: Typing.IconState): Icon
	Themes.removeWith(self, instanceName, property, state)
	return self
end

function Icon.setTheme(self: Icon, theme: Typing.ThemeData): Icon
	Themes.set(self, theme)
	return self
end

function Icon.setEnabled(self: Icon, bool: boolean): Icon
	self.isEnabled = bool
	self.widget.Visible = bool
	self:updateParent()
	return self
end

function Icon.select(self: Icon, fromSource: string, sourceIcon: Icon): Icon
	self:setState("Selected", fromSource, sourceIcon)
	return self
end

function Icon.deselect(self: Icon, fromSource: string, sourceIcon: Icon): Icon
	self:setState("Deselected", fromSource, sourceIcon)
	return self
end

function Icon.notify(self: Icon, customClearSignal: Typing.GoodSignal | RBXScriptSignal, noticeId: string): Icon
	-- Generates a notification which appears in the top right of the icon. Useful for example for prompting
	-- users of changes/updates within your UI such as a Catalog
	-- 'customClearSignal' is a signal object (e.g. icon.deselected) or
	-- Roblox event (e.g. Instance.new("BindableEvent").Event)
	local notice = self.notice
	if not notice then
		notice = require(elements.Notice)(self, Icon)
		self.notice = notice
	end
	self.noticeStarted:Fire(customClearSignal, noticeId)
	return self
end

function Icon.clearNotices(self: Icon): Icon
	self.endNotices:Fire()
	return self
end

function Icon.disableOverlay(self: Icon, bool: boolean): Icon
	self.overlayDisabled = bool
	return self
end
Icon.disableStateOverlay = Icon.disableOverlay

function Icon.setImage(self: Icon, imageId: string, iconState: Typing.IconState?): Icon
	self:modifyTheme({ "IconImage", "Image", imageId, iconState })
	return self
end

function Icon.setLabel(self: Icon, text: string, iconState: Typing.IconState?): Icon
	self:modifyTheme({ "IconLabel", "Text", text, iconState })
	return self
end

function Icon.setOrder(self: Icon, int: number, iconState: Typing.IconState?): Icon
	self:modifyTheme({ "Widget", "LayoutOrder", int, iconState })
	return self
end

function Icon.setCornerRadius(self: Icon, udim: UDim, iconState: Typing.IconState?): Icon
	self:modifyTheme({ "IconCorners", "CornerRadius", udim, iconState })
	return self
end

-- Just ignore this function

function Icon.align(
	self: Icon,
	leftCenterOrRight: ("Left" | "Mid" | "Center" | "Centre" | "Right")?,
	isFromParentIcon: boolean?
): Icon
	-- Determines the side of the screen the icon will be ordered
	local direction = tostring(leftCenterOrRight):lower()
	if direction == "mid" or direction == "centre" then
		direction = "center"
	end
	if direction ~= "left" and direction ~= "center" and direction ~= "right" then
		direction = "left"
	end
	local screenGui = (direction == "center" and Icon.container.TopbarCentered) or Icon.container.TopbarStandard
	local holders = screenGui.Holders
	local finalDirection = `{string.upper(string.sub(direction, 1, 1))}{string.sub(direction, 2)}`
	if not isFromParentIcon then
		self.originalAlignment = finalDirection
	end
	local joinedFrame = self.joinedFrame
	local alignmentHolder = holders[finalDirection]
	self.screenGui = screenGui
	self.alignmentHolder = alignmentHolder
	if not self.isDestroyed then
		self.widget.Parent = joinedFrame or alignmentHolder
	end
	self.alignment = finalDirection
	self.alignmentChanged:Fire(finalDirection)
	Icon.iconChanged:Fire(self)
	return self
end
Icon.setAlignment = Icon.align

function Icon.setLeft(self: Icon): Icon
	self:setAlignment("Left")
	return self
end

function Icon.setMid(self: Icon): Icon
	self:setAlignment("Center")
	return self
end

function Icon.setRight(self: Icon): Icon
	self:setAlignment("Right")
	return self
end

function Icon.setWidth(self: Icon, offsetMinimum: number, iconState: Typing.IconState?): Icon
	-- This sets a minimum X offset size for the widget, useful
	-- for example if you're constantly changing the label
	-- but don't want the icon to resize every time
	local newSize = UDim2.fromOffset(offsetMinimum, self.widget.Size.Y.Offset)
	self:modifyTheme({ "Widget", "Size", newSize, iconState })
	self:modifyTheme({ "Widget", "DesiredWidth", offsetMinimum, iconState })
	return self
end

function Icon.setImageScale(self: Icon, number: number, iconState: Typing.IconState?): Icon
	self:modifyTheme({ "IconImageScale", "Value", number, iconState })
	return self
end

function Icon.setImageRatio(self: Icon, number: number, iconState: Typing.IconState?): Icon
	self:modifyTheme({ "IconImageRatio", "AspectRatio", number, iconState })
	return self
end

function Icon.setTextSize(self: Icon, number: number, iconState: Typing.IconState?): Icon
	self:modifyTheme({ "IconLabel", "TextSize", number, iconState })
	return self
end

function Icon.setTextFont(
	self: Icon,
	font: number | Enum.Font | string,
	fontWeight: Enum.FontWeight?,
	fontStyle: Enum.FontStyle?,
	iconState: Typing.IconState?
): Icon
	fontWeight = fontWeight or Enum.FontWeight.Regular
	fontStyle = fontStyle or Enum.FontStyle.Normal
	local fontFace
	if typeof(font) == "number" then
		fontFace = Font.fromId(font, fontWeight, fontStyle)
	elseif typeof(font) == "EnumItem" then
		fontFace = Font.fromEnum(font)
	elseif typeof(font) == "string" then
		if not font:match("rbxasset") then
			fontFace = Font.fromName(font, fontWeight, fontStyle)
		end
	end
	if not fontFace then
		fontFace = Font.new(font :: any, fontWeight, fontStyle)
	end
	self:modifyTheme({ "IconLabel", "FontFace", fontFace, iconState })
	return self
end

function Icon.bindToggleItem(self: Icon, guiObjectOrLayerCollector: GuiObject | LayerCollector): Icon
	if not guiObjectOrLayerCollector:IsA("GuiObject") and not guiObjectOrLayerCollector:IsA("LayerCollector") then
		error("Toggle item must be a GuiObject or LayerCollector!")
	end
	self.toggleItems[guiObjectOrLayerCollector] = true
	self:_updateSelectionInstances()
	return self
end

function Icon.unbindToggleItem(self: Icon, guiObjectOrLayerCollector: GuiObject | LayerCollector): Icon
	self.toggleItems[guiObjectOrLayerCollector] = nil
	self:_updateSelectionInstances()
	return self
end

function Icon._updateSelectionInstances(self: Icon): ()
	-- This is to assist with controller navigation and selection
	-- It converts the value true to an array
	for guiObjectOrLayerCollector, _ in self.toggleItems do
		local buttonInstancesArray = {}
		for _, instance in guiObjectOrLayerCollector:GetDescendants() do
			if (instance:IsA("TextButton") or instance:IsA("ImageButton")) and instance.Active then
				table.insert(buttonInstancesArray, instance)
			end
		end
		self.toggleItems[guiObjectOrLayerCollector] = buttonInstancesArray
	end
end

function Icon._setToggleItemsVisible(self: Icon, bool: boolean, sourceIcon: Icon?): ()
	for toggleItem, _ in self.toggleItems do
		if not sourceIcon or sourceIcon == self or sourceIcon.toggleItems[toggleItem] == nil then
			local property = "Visible"
			if toggleItem:IsA("LayerCollector") then
				property = "Enabled"
			end
			toggleItem[property] = bool
		end
	end
end

function Icon.bindEvent(self: Icon, iconEventName: string, eventFunction: (Icon, ...any) -> ()): Icon
	local event = self[iconEventName]
	assert(
		event and typeof(event) == "table" and event.Connect,
		"argument[1] must be a valid topbarplus icon event name!"
	)
	assert(typeof(eventFunction) == "function", "argument[2] must be a function!")

	self.bindedEvents[iconEventName] = event:Connect(function(...)
		eventFunction(self, ...)
	end)

	return self
end

function Icon.unbindEvent(self: Icon, iconEventName: string): Icon
	local eventConnection = self.bindedEvents[iconEventName]

	if eventConnection then
		eventConnection:Disconnect()
		self.bindedEvents[iconEventName] = nil
	end

	return self
end

function Icon.bindToggleKey(self: Icon, keyCodeEnum: Enum.KeyCode): Icon
	assert(typeof(keyCodeEnum) == "EnumItem", "argument[1] must be a KeyCode EnumItem!")
	self.bindedToggleKeys[keyCodeEnum] = true
	self.toggleKeyAdded:Fire(keyCodeEnum)
	self:setCaption("_hotkey_")
	return self
end

function Icon.unbindToggleKey(self: Icon, keyCodeEnum: Enum.KeyCode): Icon
	assert(typeof(keyCodeEnum) == "EnumItem", "argument[1] must be a KeyCode EnumItem!")
	self.bindedToggleKeys[keyCodeEnum] = nil
	return self
end

function Icon.call<A...>(self: Icon, callback: (Icon, A...) -> (), ...: A...): Icon
	local packedArgs = table.pack(...)
	task.spawn(function()
		callback(self, table.unpack(packedArgs))
	end)
	return self
end

function Icon.addToJanitor(self: Icon, callback: unknown): Icon
	self.janitor:add(callback)
	return self
end

function Icon.lock(self: Icon): Icon
	-- This disables all user inputs related to the icon (such as clicking buttons, pressing keys, etc)
	local clickRegion = self:getInstance("ClickRegion")
	clickRegion.Visible = false
	self.locked = true
	return self
end

function Icon.unlock(self: Icon): Icon
	local clickRegion = self:getInstance("ClickRegion")
	clickRegion.Visible = true
	self.locked = false
	return self
end

function Icon.debounce(self: Icon, seconds: number): Icon
	self:lock()
	task.wait(seconds)
	self:unlock()
	return self
end

function Icon.autoDeselect(self: Icon, bool: boolean?): Icon
	-- When set to true the icon will deselect itself automatically whenever
	-- another icon is selected
	if bool == nil then
		bool = true
	end
	self.deselectWhenOtherIconSelected = not not bool
	return self
end

function Icon.oneClick(self: Icon, bool: boolean?): Icon
	-- When set to true the icon will automatically deselect when selected, this creates
	-- the effect of a single click button
	local singleClickJanitor = self.singleClickJanitor
	singleClickJanitor:clean()
	if bool or bool == nil then
		singleClickJanitor:add(self.selected:Connect(function()
			self:deselect("OneClick", self)
		end))
	end
	self.oneClickEnabled = true
	return self
end

function Icon.setCaption(self: Icon, text: string?): Icon
	if text == "_hotkey_" and self.captionText then
		return self
	end
	local captionJanitor = self.captionJanitor
	self.captionJanitor:clean()
	if not text or text == "" then
		self.caption = nil
		self.captionText = nil
		return self
	end
	local caption = captionJanitor:add(require(elements.Caption)(self))
	caption:SetAttribute("CaptionText", text)
	self.caption = caption
	self.captionText = text
	return self
end

function Icon.setCaptionHint(self: Icon, keyCodeEnum: Enum.KeyCode): Icon
	assert(typeof(keyCodeEnum) == "EnumItem", "argument[1] must be a KeyCode EnumItem!")
	self.fakeToggleKey = keyCodeEnum
	self.fakeToggleKeyChanged:Fire(keyCodeEnum)
	self:setCaption("_hotkey_")
	return self
end

function Icon.leave(self: Icon): Icon
	local joinJanitor = self.joinJanitor
	joinJanitor:clean()
	return self
end

function Icon.joinMenu(self: Icon, parentIcon: Icon): Icon
	Utility.joinFeature(self, parentIcon, parentIcon.menuIcons, parentIcon:getInstance("Menu") :: any)
	parentIcon.menuChildAdded:Fire(self)
	return self
end

function Icon.setMenu(self: Icon, arrayOfIcons: { Icon }): Icon
	self.menuSet:Fire(arrayOfIcons)
	return self
end

function Icon.setFrozenMenu(self: Icon, arrayOfIcons: { Icon }): ()
	self:freezeMenu()
	self:setMenu(arrayOfIcons)
end

function Icon.freezeMenu(self: Icon): ()
	-- A frozen menu is a menu which is permanently locked in the
	-- the selected state (with its toggle hidden)
	self:select("FrozenMenu", self)
	self:bindEvent("deselected", function(icon)
		icon:select("FrozenMenu", self)
	end)
	self:modifyTheme({ "IconSpot", "Visible", false })
end

function Icon.joinDropdown(self: Icon, parentIcon: Icon): Icon
	parentIcon:getDropdown()
	Utility.joinFeature(self, parentIcon, parentIcon.dropdownIcons, parentIcon:getInstance("DropdownScroller") :: any)
	parentIcon.dropdownChildAdded:Fire(self)
	return self
end

function Icon.getDropdown(self: Icon): Frame
	local dropdown = self.dropdown
	if not dropdown then
		dropdown = require(elements.Dropdown)(self)
		self.dropdown = dropdown
		self:clipOutside(dropdown)
	end
	return dropdown
end

function Icon.setDropdown(self: Icon, arrayOfIcons: { Icon }): Icon
	self:getDropdown()
	self.dropdownSet:Fire(arrayOfIcons)
	return self
end

function Icon.clipOutside(self: Icon, instance: Frame): (Icon, Frame)
	-- This is essential for items such as notices and dropdowns which will exceed the bounds of the widget. This is an issue
	-- because the widget must have ClipsDescendents enabled to hide items for instance when the menu is closing or opening.
	-- This creates an invisible frame which matches the size and position of the instance, then the instance is parented outside of
	-- the widget and tracks the clone to match its size and position. In order for themes, etc to work the applying system checks
	-- to see if an instance is a clone, then if it is, it applies it to the original instance instead of the clone.
	local instanceClone = Utility.clipOutside(self, instance)
	self:refreshAppearance(instance)
	return self, instanceClone
end

function Icon.setIndicator(self: Icon, keyCode: Enum.KeyCode): ()
	-- An indicator is a direction button prompt with an image of the given keycode. This is useful for instance
	-- with controllers to show the user what button to press to highlight the topbar. You don't need
	-- to set an indicator for controllers as this is handled internally within the Gamepad module
	local indicator = self.indicator
	if not indicator then
		indicator = self.janitor:add(require(elements.Indicator)(self))
		self.indicator = indicator
	end
	self.indicatorSet:Fire(keyCode)
end

-- DESTROY/CLEANUP
function Icon.destroy(self: Icon): ()
	if self.isDestroyed then
		return
	end
	self:clearNotices()
	if self.parentIconUID then
		self:leave()
	end
	self.isDestroyed = true
	self.janitor:clean()
	Icon.iconRemoved:Fire(self)
end
Icon.Destroy = Icon.destroy

return Icon :: Typing.StaticIcon
