--[[
        Info.lua
--]]

return {
    appName = "TreeSync Orderer",
    shortAppName = "TSO",
    author = "Rob Cole",
    authorsWebsite = "www.robcole.com",
    donateUrl = "http://www.robcole.com/Rob/Donate",
    platforms = { 'Windows', 'Mac' },
    pluginId = "com.robcole.lightroom.TreeSyncOrderer",
    xmlRpcUrl = "http://www.robcole.com/Rob/_common/cfpages/XmlRpc.cfm",
    LrPluginName = "rc TreeSync Orderer",
    LrSdkMinimumVersion = 3.0,
    LrSdkVersion = 5.0,
    LrPluginInfoUrl = "http://www.robcole.com/Rob/ProductsAndServices/TreeSyncOrdererLrPlugin",
    LrPluginInfoProvider = "TreeSyncOrdererManager.lua",
    LrToolkitIdentifier = "com.robcole.TreeSyncOrderer",
    LrInitPlugin = "Init.lua",
    LrShutdownPlugin = "Shutdown.lua",
    LrExportServiceProvider = {
        title = "TreeSync Orderer",
        file = "TreeSyncOrdererExport.lua",
        builtInPresetsDir = "Export Presets",
    },
    LrExportFilterProvider = {
        title = "TreeSync Orderer",
        file = "TreeSyncOrdererExportFilter.lua",
        id = "TreeSyncOrdererExportFilter",
    },
--    LrMetadataTagsetFactory = "Tagsets.lua", - can't see the need for this..
    --[[ ###3 consider having general help for this plugin, but note: TSP doesn't have it.
    LrHelpMenuItems = {
        {
            title = "General Help",
            file = "mHelp.lua",
        },
    },
    --]]
    LrLibraryMenuItems = {
        {
            title = "Auto-order, Plan &B..",
            file = "mAutoOrderPlanB.lua",
        },
    },
    VERSION = { display = "4.0    Build: 2014-07-08 04:56:35" },
}
