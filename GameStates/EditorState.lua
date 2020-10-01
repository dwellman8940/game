local addonName, envTable = ...
setfenv(1, envTable)

LevelEditorStateMixin = CreateFromMixins(GameStateMixin)