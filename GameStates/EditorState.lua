local addonName, envTable = ...
setfenv(1, envTable)

LevelEditorStateMixin = Mixin.CreateFromMixins(GameStateMixin)