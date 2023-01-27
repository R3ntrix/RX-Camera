

--[[

	Made By: R3ntrix
	Last Updated: 26 1 2023
	
	Public Methods
	
	:Enable()
	:SetLockEnabled(boolean) -- acts like shift lock
	:SetMouseLocked(boolean)  -- lockes the mouse to center of the screen
	:Disable()
	
]]


--// Services -----------------------------------------------------------------
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local PlayersService = game:GetService("Players")
local RunService = game:GetService("RunService")

--// Player -------------------------------------------------------------------
local Player = PlayersService.LocalPlayer

--// Singleton ----------------------------------------------------------------
local RXCamera = {}
RXCamera.__index = RXCamera

--// Constructor --------------------------------------------------------------
function RXCamera.new()
	local self = setmetatable({

		--// Update keys
		_updateKeyCamera = "CUSTOM_CAMERA_CFRAME_UPDATE",
		_updateKeyInput = "CUSTOM_CAMERA_INPUT_UPDATE",

		--// Latest input delta
		_inputDeltaX = 0,
		_inputDeltaY = 0,

		--// Mode
		_lockEnabled = false,
		_mouseLocked = true,
		_angleLimitsY = NumberRange.new(-75, 75),

		--// Camera settings
		_settings = {

			DEFAULT_OFFSET = Vector3.new(0, 2, 8),
			LOCKED_OFFSET = Vector3.new(2, 2, 8),
			SENSITIVITY = 0.5,

		},

	}, RXCamera)
	return self
end

--// Private ------------------------------------------------------------------
function RXCamera:_updateInputDelta(inputObject: InputObject)
	local inputDelta = inputObject.Delta * self._settings.SENSITIVITY
	self._inputDeltaX -= inputDelta.X
	self._inputDeltaY = math.clamp(self._inputDeltaY - inputDelta.Y, self._angleLimitsY.Min, self._angleLimitsY.Max)
end

function RXCamera:_update(rootPart: Part)

	--// Adress presets
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	UserInputService.MouseBehavior = if self._mouseLocked then Enum.MouseBehavior.LockCenter else Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = not self._mouseLocked

	--// Adress camera position and orientation
	local startCFrame = CFrame.new(rootPart.Position) *
		CFrame.Angles(0, math.rad(self._inputDeltaX), 0) *
		CFrame.Angles(math.rad(self._inputDeltaY), 0, 0)
	local cameraOffset = if self._lockEnabled then self._settings.LOCKED_OFFSET else self._settings.DEFAULT_OFFSET
	local cameraPosition = startCFrame:ToWorldSpace(CFrame.new(cameraOffset)).Position
	local cameraLookAt = startCFrame:ToWorldSpace(CFrame.new(cameraOffset.X, cameraOffset.Y, -10^6)).Position
	local cameraCFrame = CFrame.new(cameraPosition, cameraLookAt)

	--// Raycast for obstructions
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {rootPart.Parent}
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	local rayResults = workspace:Raycast(rootPart.Position, cameraCFrame.Position - rootPart.Position, rayParams)

	--// Address obstructions
	if (rayResults ~= nil) then
		local obstructionDisplacement = (rayResults.Position - rootPart.Position)
		local obstructionPosition = rootPart.Position + (obstructionDisplacement.Unit * (obstructionDisplacement.Magnitude - 0.1))
		local x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22 = cameraCFrame:components()
		cameraCFrame = CFrame.new(obstructionPosition.x, obstructionPosition.y, obstructionPosition.z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
	end; workspace.CurrentCamera.CFrame = cameraCFrame

	--// Adress character alignment
	if self._lockEnabled then
		local rootLookAt = rootPart.Position + workspace.CurrentCamera.CFrame.LookVector * Vector3.new(1, 0, 1) * 10^3
		rootPart.CFrame = CFrame.new(rootPart.Position, rootLookAt)			
	end

end

--// Public -------------------------------------------------------------------
function RXCamera:Enable()

	--// Update input delta
	ContextActionService:BindAction(self._updateKeyInput, function(actionName, inputState, inputObject)
		if inputState == Enum.UserInputState.Change then
			self:_updateInputDelta(inputObject)
		end
	end, false, Enum.UserInputType.MouseMovement, Enum.UserInputType.Touch)

	--// Update settings and camera
	RunService:BindToRenderStep(self._updateKeyCamera, Enum.RenderPriority.Camera.Value - 10, function()
		local character = Player.Character
		local rootPart = if (character ~= nil) then character:FindFirstChild("HumanoidRootPart") else nil
		if (rootPart ~= nil) then
			self:_update(rootPart)
		else
			self:Disable()
			warn("RX Camera Disabled: HumanoidRootPart not found!")
		end	
	end)

end

function RXCamera:SetLockEnabled(toggle: boolean)
	assert(typeof(toggle) == "boolean", "[-] RX Camera Error: Toggle must be a boolean!")
	self._lockEnabled = toggle
end

function RXCamera:SetMouseLocked(toggle: boolean)
	assert(typeof(toggle) == "boolean", "[-] RX Camera Error: Toggle must be a boolean!")
	self._mouseLocked = toggle
end

function RXCamera:Disable()

	--// Disable input update
	ContextActionService:UnbindAction(self._updateKeyInput)
	self._inputDeltaX = 0
	self._inputDeltaY = 0

	--// Disable camera update
	RunService:UnbindFromRenderStep(self._updateKeyCamera)

	--// Postsets
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
end

return RXCamera.new()
