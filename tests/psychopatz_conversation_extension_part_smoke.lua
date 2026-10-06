local ROOT =
    "Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local function part(kind)
    return {
        kind = kind,
        initialise = function(self) self.initialised = true end,
        instantiate = function(self) self.instantiated = true end,
        setVisible = function(self, value) self.visible = value end,
    }
end

local function class(kind)
    return {
        new = function() return part(kind) end,
    }
end

local capturedOptions
local extension = part("extension")

PsychopatzConversationView = {
    Internal = {
        Layout = {
            Resolve = function(partID)
                return {
                    x = partID == "llmInput" and 10 or 0,
                    y = 20,
                    width = 300,
                    height = 80,
                }
            end,
        },
        screenVariantFor = function() return "clean" end,
    },
}
PsychopatzConversationPortrait = class("portrait")
PsychopatzConversationChat = class("history")
PsychopatzConversationChoices = class("choices")

dofile(ROOT .. "PsychopatzConversationView_Parts.lua")

local view = {
    width = 1000,
    height = 800,
    spec = {
        portrait = {},
        extensionParts = {
            {
                partID = "llmInput",
                visible = true,
                factory = function(bounds, options)
                    assertEqual(bounds.x, 10, "extension layout bounds")
                    capturedOptions = options
                    return extension
                end,
            },
        },
    },
    addChild = function(self, child)
        self.children = self.children or {}
        self.children[#self.children + 1] = child
    end,
}

PsychopatzConversationView.Internal.buildParts(view)

assertEqual(capturedOptions.partID, "llmInput",
    "extension factory receives its stable part id")
assertEqual(capturedOptions.owner, view,
    "extension factory receives the owning view")
assertEqual(view.extensionParts.llmInput, extension,
    "extension part is mounted under its stable id")
assertEqual(extension.visible, true, "extension visibility is applied")

print("psychopatz_conversation_extension_part_smoke: ok")
