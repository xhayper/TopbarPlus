--!strict

-- GoodSignalConnection

type GoodSignalConnectionImpl<Variant... = ...any> = {
	__index: GoodSignalConnectionImpl<Variant...>,

	new: (signal: GoodSignal<Variant...>, fn: (Variant...) -> ()) -> GoodSignalConnection<Variant...>,

	Disconnect: (self: GoodSignalConnection<Variant...>) -> (),
}

type GoodSignalConnectionProto<Variant... = ...any> = {
	_connected: boolean,
	_signal: GoodSignal<Variant...>,
	_fn: (Variant...) -> (),
	_next: false | GoodSignalConnection<Variant...>,
}

export type GoodSignalConnection<Variant... = ...any> = typeof(setmetatable(
	{} :: GoodSignalConnectionProto<Variant...>,
	{} :: GoodSignalConnectionImpl<Variant...>
))

-- GoodSignal

type GoodSignalImpl<Variant... = ...any> = {
	__index: GoodSignalImpl<Variant...>,

	-- TODO: Implement below when luau supports this kind of recursive type
	-- TODO: <T...>() -> Signal<T...>
	new: () -> GoodSignal<Variant...>,

	Connect: (self: GoodSignal<Variant...>, func: (Variant...) -> ()) -> GoodSignalConnection<Variant...>,
	DisconnectAll: (self: GoodSignal<Variant...>) -> (),

	Fire: (self: GoodSignal<Variant...>, Variant...) -> (),
	Wait: (self: GoodSignal<Variant...>) -> Variant...,
	Once: (self: GoodSignal<Variant...>, func: (Variant...) -> ()) -> GoodSignalConnection<Variant...>,
}

type GoodSignalProto<Variant... = ...any> = {
	_handlerListHead: false | GoodSignalConnection<Variant...>,
}

export type GoodSignal<Variant... = ...any> = typeof(setmetatable(
	{} :: GoodSignalProto<Variant...>,
	{} :: GoodSignalImpl<Variant...>
))

------------ Janitor ------------

export type Janitor = {
	ClassName: "Janitor",
	CurrentlyCleaning: boolean,
	SuppressInstanceReDestroy: boolean,

	new: () -> Janitor,

	--------------------------------------

	Is: (obj: unknown) -> boolean,

	Add: <T>(self: Janitor, Object: T, MethodName: (boolean | string)?, Index: any?) -> T,
	AddPromise: <T>(self: Janitor, PromiseObject: T) -> T,
	AddObject: <T>(self: Janitor, Object: T) -> T,

	Give: <T>(self: Janitor, Object: T, MethodName: (boolean | string)?, Index: any?) -> T,
	GivePromise: <T>(self: Janitor, PromiseObject: T) -> T,
	GiveObject: <T>(self: Janitor, Object: T) -> T,

	Remove: (self: Janitor, Index: any) -> Janitor,
	Get: (self: Janitor, Index: any) -> { [any]: any },

	Clean: (self: Janitor) -> (),
	Cleanup: (self: Janitor) -> (),
	Destroy: (self: Janitor) -> (),

	LinkToInstance: (self: Janitor, Object: Instance, AllowMultiple: boolean?) -> RBXScriptConnection,
	LinkToInstances: (self: Janitor, ...Instance) -> Janitor,

	-------------------------------------

	is: (obj: unknown) -> boolean,

	add: <T>(self: Janitor, Object: T, MethodName: (boolean | string)?, Index: any?) -> T,
	addPromise: <T>(self: Janitor, PromiseObject: T) -> T,
	addObject: <T>(self: Janitor, Object: T) -> T,

	give: <T>(self: Janitor, Object: T, MethodName: (boolean | string)?, Index: any?) -> T,
	givePromise: <T>(self: Janitor, PromiseObject: T) -> T,
	giveObject: <T>(self: Janitor, Object: T) -> T,

	remove: (self: Janitor, Index: any) -> Janitor,
	get: (self: Janitor, Index: any) -> any,

	clean: (self: Janitor) -> (),
	cleanup: (self: Janitor) -> (),
	destroy: (self: Janitor) -> (),

	linkToInstance: (self: Janitor, Object: Instance, AllowMultiple: boolean?) -> RBXScriptConnection,
	linkToInstances: (self: Janitor, ...Instance) -> Janitor,
}

-----------------------------------------------------------------------------------------------------

-- THEME

export type ThemeModification = { any }
export type ThemeData = { ThemeModification }

-----------------------------------------------------------------------------------------------------

export type IconState = "Selected" | "Deselected" | "Viewing"
export type IconAlignment = "Left" | "Center" | "Right"

export type IconStateGroup = { any }

export type StaticIconImpl = {
	__index: IconImpl,

	getIcons: () -> { [string]: Icon },
	getIconByUID: (UID: string) -> Icon?,
	getIcon: (nameOrUID: string) -> Icon?,
	setTopbarEnabled: (bool: boolean, isInternal: boolean) -> (),
	modifyBaseTheme: (modifications: ThemeModification) -> (),
	setDisplayOrder: (int: number) -> (),

	new: () -> Icon,
}

export type StaticIconProto = {
	ClassName: "Icon",

	baseDisplayOrderChanged: GoodSignal<number>,
	baseDisplayOrder: number,
	baseTheme: ThemeData,

	isOldTopbar: boolean,

	iconsDictionary: { [string]: Icon },

	-- TODO: Type this
	container: { [unknown]: ScreenGui },

	topbarEnabled: boolean,

	iconAdded: GoodSignal<Icon>,
	iconRemoved: GoodSignal<Icon>,
	iconChanged: GoodSignal<Icon>,
}

export type IconImpl = {
	getIcons: () -> { [string]: Icon },
	getIconByUID: (UID: string) -> Icon?,
	getIcon: (nameOrUID: string) -> Icon?,
	setTopbarEnabled: (bool: boolean, isInternal: boolean) -> (),
	modifyBaseTheme: (modifications: ThemeModification) -> (),
	setDisplayOrder: (int: number) -> (),

	new: () -> Icon,

	------------------------------------------------------------------------------------

	__index: IconImpl,

	setName: (self: Icon, name: string) -> (),
	setState: (self: Icon, incomingStateName: IconState?, fromSource: string?, sourceIcon: Icon?) -> (),
	getInstance: (self: Icon, name: string) -> Instance?,
	getCollective: (self: Icon, name: string) -> { Instance },
	getInstanceOrCollective: (self: Icon, collectiveOrInstanceName: string) -> { Instance },
	getStateGroup: (self: Icon, iconState: IconState?) -> IconStateGroup,
	-- TODO: Double check this
	refreshAppearance: (self: Icon, instance: Instance, specificProperty: string?) -> Icon,
	refresh: (self: Icon) -> Icon,
	updateParent: (self: Icon) -> (),
	setBehaviour: (
		self: Icon,
		collectiveOrInstanceName: string,
		property: string,
		callback: (...any) -> (),
		refreshAppearance: boolean?
	) -> (),
	modifyTheme: (self: Icon, modifications: ThemeModification, modificationUID: string?) -> (Icon, string),
	modifyChildTheme: (self: Icon, modifications: ThemeModification, modificationUID: string) -> Icon,
	removeModification: (self: Icon, modificationUID: string) -> Icon,
	removeModificationWith: (self: Icon, instanceName: string, property: string, state: IconState) -> Icon,
	setTheme: (self: Icon, theme: ThemeData) -> Icon,
	setEnabled: (self: Icon, bool: boolean) -> Icon,
	select: (self: Icon, fromSource: string, sourceIcon: Icon) -> Icon,
	deselect: (self: Icon, fromSource: string, sourceIcon: Icon) -> Icon,
	notify: (self: Icon, customClearSignal: GoodSignal | RBXScriptSignal, noticeId: string?) -> Icon,
	clearNotices: (self: Icon) -> Icon,
	disableOverlay: (self: Icon, bool: boolean) -> Icon,
	disableStateOverlay: (self: Icon, bool: boolean) -> Icon,
	setImage: (self: Icon, imageId: string, iconState: IconState?) -> Icon,
	setLabel: (self: Icon, text: string, iconState: IconState?) -> Icon,
	setOrder: (self: Icon, int: number, iconState: IconState?) -> Icon,
	setCornerRadius: (self: Icon, udim: UDim, iconState: IconState?) -> Icon,
	align: (
		self: Icon,
		leftCenterOrRight: ("Left" | "Mid" | "Center" | "Centre" | "Right")?,
		isFromParentIcon: boolean?
	) -> Icon,
	setAlignment: (
		self: Icon,
		leftCenterOrRight: ("Left" | "Mid" | "Center" | "Centre" | "Right")?,
		isFromParentIcon: boolean?
	) -> Icon,
	setLeft: (self: Icon) -> Icon,
	setMid: (self: Icon) -> Icon,
	setRight: (self: Icon) -> Icon,
	setWidth: (self: Icon, offsetMinimum: number, iconState: IconState?) -> Icon,
	setImageScale: (self: Icon, number: number, iconState: IconState?) -> Icon,
	setImageRatio: (self: Icon, number: number, iconState: IconState?) -> Icon,
	setTextSize: (self: Icon, number: number, iconState: IconState?) -> Icon,
	setTextFont: (
		self: Icon,
		font: number | Enum.Font | string,
		fontWeight: Enum.FontWeight?,
		fontStyle: Enum.FontStyle?,
		iconState: IconState?
	) -> Icon,
	bindToggleItem: (self: Icon, guiObjectOrLayerCollector: GuiObject | LayerCollector) -> Icon,
	unbindToggleItem: (self: Icon, guiObjectOrLayerCollector: GuiObject | LayerCollector) -> Icon,
	_updateSelectionInstances: (self: Icon) -> (),
	_setToggleItemsVisible: (self: Icon, bool: boolean, sourceIcon: Icon?) -> (),
	bindEvent: (self: Icon, iconEventName: string, eventFunction: (Icon, ...any) -> ()) -> Icon,
	unbindEvent: (self: Icon, iconEventName: string) -> Icon,
	bindToggleKey: (self: Icon, keyCodeEnum: Enum.KeyCode) -> Icon,
	unbindToggleKey: (self: Icon, keyCodeEnum: Enum.KeyCode) -> Icon,
	call: <A...>(self: Icon, callback: (Icon, A...) -> (), A...) -> Icon,
	addToJanitor: (self: Icon, callback: unknown) -> Icon,
	lock: (self: Icon) -> Icon,
	unlock: (self: Icon) -> Icon,
	debounce: (self: Icon, seconds: number) -> Icon,
	autoDeselect: (self: Icon, bool: boolean?) -> Icon,
	oneClick: (self: Icon, bool: boolean?) -> Icon,
	setCaption: (self: Icon, text: string?) -> Icon,
	setCaptionHint: (self: Icon, keyCodeEnum: Enum.KeyCode) -> Icon,
	leave: (self: Icon) -> Icon,
	joinMenu: (self: Icon, parentIcon: Icon) -> Icon,
	setMenu: (self: Icon, arrayOfIcons: { Icon }) -> Icon,
	setFrozenMenu: (self: Icon, arrayOfIcons: { Icon }) -> (),
	freezeMenu: (self: Icon) -> (),
	joinDropdown: (self: Icon, parentIcon: Icon) -> Icon,
	getDropdown: (self: Icon) -> Frame,
	setDropdown: (self: Icon, arrayOfIcons: { Icon }) -> Icon,
	clipOutside: (self: Icon, instance: Frame) -> (Icon, Frame),
	setIndicator: (self: Icon, keyCode: Enum.KeyCode) -> (),
	destroy: (self: Icon) -> (),
	Destroy: (self: Icon) -> (),
}

export type IconProto = {
	ClassName: "Icon",

	baseDisplayOrderChanged: GoodSignal<number>,
	baseDisplayOrder: number,
	baseTheme: ThemeData,

	isOldTopbar: boolean,

	iconsDictionary: { [string]: Icon },

	-- TODO: Type this
	container: { [unknown]: ScreenGui },

	topbarEnabled: boolean,

	iconAdded: GoodSignal<Icon>,
	iconRemoved: GoodSignal<Icon>,
	iconChanged: GoodSignal<Icon>,

	-------------------------------------

	janitor: Janitor,
	themesJanitor: Janitor,
	singleClickJanitor: Janitor,
	captionJanitor: Janitor,
	joinJanitor: Janitor,
	menuJanitor: Janitor,
	dropdownJanitor: Janitor,

	-- Events

	-- TODO: Type these please :(
	-- (fromSource: string?, sourceIcon: Icon?)
	selected: GoodSignal<string?, Icon?>,
	-- (fromSource: string?, sourceIcon: Icon?)
	deselected: GoodSignal<string?, Icon?>,
	-- (isSelected), (fromSource: string, sourceIcon: Icon)
	toggled: GoodSignal<boolean, string?, Icon?>,
	viewingStarted: GoodSignal<boolean>,
	viewingEnded: GoodSignal<boolean>,
	-- (stateName), (fromSource: string, sourceIcon: Icon)
	stateChanged: GoodSignal<IconState, string?, Icon?>,
	-- (noticeId)
	notified: GoodSignal<string>,
	-- (customClearSignal, noticeId)
	noticeStarted: GoodSignal<GoodSignal | RBXScriptSignal, string>,
	-- totalNotices
	noticeChanged: GoodSignal<number>,
	endNotices: GoodSignal,
	-- keyCodeEnum
	toggleKeyAdded: GoodSignal<Enum.KeyCode>,
	fakeToggleKeyChanged: GoodSignal<Enum.KeyCode>,
	alignmentChanged: GoodSignal<IconAlignment>,
	updateSize: GoodSignal,
	resizingComplete: GoodSignal,
	joinedParent: GoodSignal<Icon>,
	menuSet: GoodSignal<{ Icon }>,
	dropdownSet: GoodSignal<{ Icon }>,
	updateMenu: GoodSignal,
	startMenuUpdate: GoodSignal,
	childThemeModified: GoodSignal,
	indicatorSet: GoodSignal<Enum.KeyCode>,
	dropdownChildAdded: GoodSignal<Icon>,
	-- child
	menuChildAdded: GoodSignal<Icon>,

	-- Properties

	iconModule: Icon,
	UID: string,
	isEnabled: boolean,
	isSelected: boolean,
	isViewing: boolean,
	joinedFrame: boolean,
	parentIconUID: string | boolean,
	deselectWhenOtherIconSelected: boolean,
	totalNotices: number,
	activeState: IconState,
	alignment: IconAlignment,
	originalAlignment: IconAlignment,
	appliedTheme: ThemeData,
	appearance: { [IconState]: IconStateGroup },
	cachedInstances: { [Instance]: boolean },
	cachedNamesToInstances: { [string]: Instance },
	cachedCollectives: { [string]: { Instance } },
	bindedToggleKeys: { [Enum.KeyCode]: boolean },
	customBehaviours: { [string]: () -> () },
	toggleItems: { [GuiObject | LayerCollector]: boolean | { ImageButton | TextButton } },
	bindedEvents: { [string]: RBXScriptConnection | GoodSignalConnection },
	notices: {
		[string]: {
			completeSignal: GoodSignal,
			clearNoticeEvent: GoodSignal | RBXScriptSignal,
		},
	},
	menuIcons: { Icon },
	dropdownIcons: { Icon },
	childIconsDict: { [string]: Icon },
	creationTime: number,

	widget: Frame,
	notice: Frame,
	caption: CanvasGroup?,
	dropdown: Frame,
	indicator: Frame,

	-- IDK?
	-- this is not defined in the constructor
	locked: boolean,
	name: string,
	childModifications: ThemeData,
	childModificationsUID: string,
	overlayDisabled: boolean,
	screenGui: ScreenGui,
	alignmentHolder: ScrollingFrame,
	isDestroyed: boolean,
	oneClickEnabled: boolean,
	captionText: string?,
	fakeToggleKey: Enum.KeyCode,
	chatWasPreviouslyActive: boolean?,
	playerlistWasPreviouslyActive: boolean?,
	highlightKey: Enum.KeyCode,
	highlightIcon: Icon | boolean,
	lastHighlightedIcon: Icon | boolean,
}

export type StaticIcon = typeof(setmetatable({} :: StaticIconProto, {} :: StaticIconImpl))
export type Icon = typeof(setmetatable({} :: IconProto, {} :: IconImpl))

return {}
