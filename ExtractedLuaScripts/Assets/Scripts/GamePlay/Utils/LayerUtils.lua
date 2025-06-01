
local UnityHelper = CS.Common.Utils.UnityHelper;

local LayerUtils = {}

LayerUtils.UNITY_LAYER_WILD_MARCHING_OBJ_ENEMY = 9
LayerUtils.UNITY_LAYER_WILD_MARCHING_OBJ_ME = 10
LayerUtils.UNITY_LAYER_WILD_MARCHING_OBJ_ALLY = 11
LayerUtils.UNITY_LAYER_WILD_TERRAIN = 12
LayerUtils.UNITY_LAYER_WILD_MARCHING_LINE = 13

function LayerUtils:SetGOLayerRecursively(go, layer)
    UnityHelper.SetGameObjectLayerRecursively(go, layer)
end

return LayerUtils