--[[
        TreeSyncOrdererManager.lua
--]]


local TreeSyncOrdererManager, dbg, dbgf = Manager:newClass{ className='TreeSyncOrdererManager' }



--[[
        Constructor for extending class.
--]]
function TreeSyncOrdererManager:newClass( t )
    return Manager.newClass( self, t )
end



--[[
        Constructor for new instance object.
--]]
function TreeSyncOrdererManager:new( t )
    return Manager.new( self, t )
end



--- Initialize global preferences.
--
function TreeSyncOrdererManager:_initGlobalPrefs()
    -- Instructions: delete the following line (or set property to nil) if this isn't an export plugin.
    --fprops:setPropertyForPlugin( _PLUGIN, 'exportMgmtVer', "2" ) -- a little add-on here to support export management. '1' is legacy (rc-common-modules) mgmt.
    -- Instructions: uncomment to support these external apps in global prefs, otherwise delete:
    -- app:initGlobalPref( 'exifToolApp', "" )
    -- app:initGlobalPref( 'mogrifyApp', "" )
    -- app:initGlobalPref( 'sqliteApp', "" )
    -- app:registerPreset( "My Preset", 2 )
    Manager._initGlobalPrefs( self )
end



--- Initialize local preferences for preset.
--
--  @usage **** Prefs defined here will overwrite like-named prefs if defined via system-settings.
--
function TreeSyncOrdererManager:_initPrefs( presetName )
    -- Instructions: uncomment to support these external apps in local (preset) prefs, otherwise delete:
    -- app:initPref( 'imageMagickDir', "", presetName ) -- for Image Magick support.
    -- app:initPref( 'exifToolApp', "", presetName )
    -- app:initPref( 'mogrifyApp', "", presetName ) - deprecated.
    -- app:initPref( 'sqliteApp', "", presetName )
    -- *** Instructions: delete this line if no async init or continued background processing:
    --app:initPref( 'background', false, presetName ) -- true to support on-going background processing, after async init (auto-update most-sel photo).
    -- *** Instructions: delete these 3 if not using them:
    --app:initPref( 'processSelectedPhotosInBackground', false, presetName )
    --app:initPref( 'processVisiblePhotosInBackground', false, presetName )
    --app:initPref( 'processAllPhotosInBackground', false, presetName )
    --app:initPref( 'backgroundPeriod', .1, presetName ) -- hard-wired to base background class.
    Manager._initPrefs( self, presetName )
end



--- Start of plugin manager dialog.
-- 
function TreeSyncOrdererManager:startDialogMethod( props )
    -- *** Instructions: uncomment if you use these apps and their exe is bound to ordinary property table (not prefs).
    Manager.startDialogMethod( self, props ) -- adds observer to all props.

    --[[ ###3 restore this if using general help.
    app:call( Call:new{ name="Welcome", async=true, guard=App.guardSilent, main=function( call )
        app:show{ info="Welcome to ^1.\n \nFor general plugin help - see \"Help (menu) -> Plugin Extras -> ^2 -> General Help\".\n \nTo quit showing this and other suppressible dialog boxes, check the 'Don't show again' box. To show this and other suppressed dialog boxes again, click the 'Reset Prompt Dialogs' button in top section of plugin manager.",
            subs = { app:getAppName(), app:getPluginName() },
            actionPrefKey = "Welcome - general help...",
        }
    end } )
    --]]
    
end



--- Preference change handler.
--
--  @usage      Handles preference changes.
--              <br>Preferences not handled are forwarded to base class handler.
--  @usage      Handles changes that occur for any reason, one of which is user entered value when property bound to preference,
--              <br>another is preference set programmatically - recursion guarding is essential.
--
function TreeSyncOrdererManager:prefChangeHandlerMethod( _id, _prefs, key, value )
    Manager.prefChangeHandlerMethod( self, _id, _prefs, key, value )
end



--- Property change handler.
--
--  @usage      Properties handled by this method, are either temporary, or
--              should be tied to named setting preferences.
--
function TreeSyncOrdererManager:propChangeHandlerMethod( props, name, value, call )
    if app.prefMgr and (app:getPref( name ) == value) then -- eliminate redundent calls.
        -- Note: in managed cased, raw-pref-key is always different than name.
        -- Note: if preferences are not managed, then depending on binding,
        -- app-get-pref may equal value immediately even before calling this method, in which case
        -- we must fall through to process changes.
        return
    end
    -- *** Instructions: strip this if not using background processing:
    if name == 'background' then
        app:setPref( 'background', value )
        if value then
            local started = background:start()
            if started then
                app:show( "Auto-update started." )
            else
                app:show( "Auto-update already started." )
            end
        elseif value ~= nil then
            app:call( Call:new{ name = 'Stop Background Task', async=true, guard=App.guardVocal, main=function( call )
                local stopped
                repeat
                    stopped = background:stop( 10 ) -- give it some seconds.
                    if stopped then
                        app:logVerbose( "Auto-update was stopped by user." )
                        app:show( "Auto-update is stopped." ) -- visible status wshould be sufficient.
                    else
                        if dialog:isOk( "Auto-update stoppage not confirmed - try again? (auto-update should have stopped - please report problem; if you cant get it to stop, try reloading plugin)" ) then
                            -- ok
                        else
                            break
                        end
                    end
                until stopped
            end } )
        end
    -- *** and strip this if not using Image Magick.
    elseif name == 'imageMagickDir' then
        if gbl:getValue( 'imageMagick' ) then 
            imageMagick:processDirChange( value )
        else
            app:showBezel( { dur=1, holdoff=0 }, "Image Magick global variable not defined." )
        end
    else
        -- Note: preference key is different than name.
        Manager.propChangeHandlerMethod( self, props, name, value, call )
        -- Note: properties are same for all plugin-manager presets, but the prefs were they get saved changes with the preset.
    end
end



--- Sections for bottom of plugin manager dialog.
-- 
function TreeSyncOrdererManager:sectionsForBottomOfDialogMethod( vf, props)

    local appSection = {}
    if app.prefMgr then
        appSection.bind_to_object = props
    else
        appSection.bind_to_object = prefs
    end
    
	appSection.title = app:getAppName() .. " Settings"
	appSection.synopsis = bind{ key='presetName', object=prefs }

	appSection.spacing = vf:label_spacing()
	
	appSection[#appSection + 1] = vf:row {
	    vf:static_text { -- ###0: consider replacing with something more appropriate..
	        --title = "There is nothing to configure here, but consider perusing the \"advanced settings\" in 'Preset Manager' section.\n \nReminder: visit Help (Lr menu) -> Plugin Extras for more info..."
	        title = [[
There are two ways to use this plugin: If mirroring a publish collection set, you can just
insert TreeSync Orderer export filter (post-process action) in mirrored publish service settings,
and then use the automatic ordering feature of TreeSync Publisher - recommended.. If however,
you're mirroring folders, or a non-publish collection set, then you have to use the manual method:

Select a source of photos (e.g. folder or collection) and all photos in the
filmstrip, or just those that you plan to export/publish using TreeSync Publisher, then export -
but note: TreeSync Orderer filter (post-process action) must be inserted prior to exporting and
the easiest way to make sure of that is to choose the 'TreeSync Orderer' export preset that comes
with the plugin. While not strictly necessary, it may make life easier and reduce the potential
for error.

If you lose track of that preset or whatever, you can also use in conjunction with hard drive
export service - make sure you insert TreeSync Orderer export filter (post-process action). I
recommend setting "Existing Files" to "Overwrite WITHOUT WARNING" - nothing will actually be
exported/overwritten AS LONG AS YOU HAVE THE AFOREMENTIONED POST-PROCESS ACTION
inserted. Set 'Export To' to 'Specific folder' and set folder to anywhere - it shouldn't matter, but
safest to set to some temp/junk location. 'Add to this catalog' should be unchecked. The rest of
the settings don't matter.

Note: since nothing gets rendered, the export will happen very quickly. As always, you can check
the (optionally verbose) log to find out what it did.

*If* you want to maintain sort order via file date or metadata in a TSP exported tree, then this
plugin must be used diligently as part of your export/publish workflow procedure. If you don't
care about photo order, then this plugin can be ignored or removed...

(see plugin's web page for more detailed and up-to-date documentation).]]
	    }
	}
	
	if false and gbl:getValue( 'background' ) then
	
	    -- *** Instructions: tweak labels and titles and spacing and provide tooltips, delete unsupported background items,
	    --                   or delete this whole clause if never to support background processing...
	    -- PS - One day, this may be handled as a conditional option in plugin generator.
	
        appSection[#appSection + 1] =
            vf:row {
                bind_to_object = props,
                vf:static_text {
                    title = "Auto-update control",
                    width = share 'label_width',
                },
                vf:checkbox {
                    title = "Automatically update most selected photo.",
                    value = bind( 'background' ),
    				--tooltip = "",
                    width = share 'data_width',
                },
            }
            
        if app:getPref( 'processSelectedPhotosInBackground' ) ~= nil then
            appSection[#appSection + 1] =
                vf:row {
                    bind_to_object = props,
                    vf:static_text {
                        title = "Auto-update selected photos",
                        width = share 'label_width',
                    },
                    vf:checkbox {
                        title = "Automatically update selected photos.",
                        value = bind( 'processSelectedPhotosInBackground' ),
                        enabled = bind( 'background' ),
        				-- tooltip = "",
                        width = share 'data_width',
                    },
                }
        else
            appSection[#appSection + 1] =
                vf:row {
                    bind_to_object = props,
                    vf:static_text {
                        title = "Auto-update selected photos",
                        width = share 'label_width',
                    },
                    vf:checkbox {
                        title = "Automatically update selected photos.",
                        value = bind( 'processTargetPhotosInBackground' ),
                        enabled = bind( 'background' ),
        				-- tooltip = "",
                        width = share 'data_width',
                    },
                }
        end
        
        if app:getPref( 'processVisiblePhotosInBackground' ) ~= nil then
            appSection[#appSection + 1] =
                vf:row {
                    bind_to_object = props,
                    vf:static_text {
                        title = "Auto-update visible photos",
                        width = share 'label_width',
                    },
                    vf:checkbox {
                        title = "Automatically update photos visible in filmstrip.",
                        value = bind( 'processVisiblePhotosInBackground' ),
                        enabled = bind( 'background' ),
        				-- tooltip = "",
                        width = share 'data_width',
                    },
                }
        else -- *** NOT RECOMMENDED UNLESS NECESSARY FOR BACKWARD COMPATIBILITY:
            appSection[#appSection + 1] =
                vf:row {
                    bind_to_object = props,
                    vf:static_text {
                        title = "Auto-update filmstrip photos",
                        width = share 'label_width',
                    },
                    vf:checkbox {
                        title = "Automatically update photos in filmstrip.",
                        value = bind( 'processFilmstripPhotosInBackground' ),
                        enabled = bind( 'background' ),
        				-- tooltip = "",
                        width = share 'data_width',
                    },
                }
        end
        
        appSection[#appSection + 1] =
            vf:row {
                bind_to_object = props,
                vf:static_text {
                    title = "Auto-update whole catalog",
                    width = share 'label_width',
                },
                vf:checkbox {
                    title = "Automatically update all photos in catalog.",
                    value = bind( 'processAllPhotosInBackground' ),
                    enabled = bind( 'background' ),
    				-- tooltip = "",
                    width = share 'data_width',
                },
            }
        appSection[#appSection + 1] =
            vf:row {
                vf:static_text {
                    title = "Auto-update status",
                    width = share 'label_width',
                },
                vf:static_text {
                    bind_to_object = prefs,
                    title = app:getGlobalPrefBinding( 'backgroundState' ),
                    width_in_chars = 70,--share 'data_width',
                    tooltip = 'auto-update status',
                },
            }
        appSection[#appSection + 1] =
            vf:row {
                vf:static_text {
                    title = "Auto-update interval",
                    width = share 'label_width',
                },    
                vf:edit_field {
                    value = bind 'backgroundPeriod',
                    width_in_digits = 5,
                    precision = 2,
                    min = .01, -- consider increasing this ###0.
                    max = math.huge, -- consider reducing this ###0.
                    tooltip = "If updating too slowly, reduce this number; if background process is using too much CPU - increase it.",
                },
                vf:static_text {
                    title = "Update one photo every this many seconds in the background." -- ###0 if background is not photo-based, this should be changed.
                },
            }
        
    end
    
    if gbl:isDeclared( 'imageMagick' ) then
      	appSection[#appSection + 1] = 
            vf:row {
                vf:static_text {
                    title = "Image Magick Directory",
                },
                vf:edit_field {
                    value = bind 'imageMagickDir',
                    width_in_chars = 40,
                },
                vf:push_button {
                    title = "Browse",
                    action = function()
                        dia:selectFolder( {
                            title = "Image Magick Application Directory",
                        }, props, 'imageMagickDir' )
                    end,
                },
            }	
    end


    --  A D D I T I O N A L   S E T T I N G S
    local addlSection = {
        bind_to_object = nil, -- addl-binding is hard-coded to prefs.
        title = app:getAppName() .. " Additional Settings",
        -- no synopsis
    }
    local addlSection = appSection -- ###0
    if false then -- "uncomment" this to have additional view items inline, if there are any defined in "Settings" file.
        app:pcall { name = "Additional View Items for Bottom of Plugin Manager Dialog", main= function( call )
            local viewItems, viewLookup, errm = systemSettings:getViewItemsAndLookup( call )
    
            if tab:isNotEmpty( viewItems ) then
                if addlSection == appSection then
                    addlSection[#addlSection + 1] = vf:spacer{ height=5 }
                    addlSection[#addlSection + 1] = vf:separator{ fill_horizontal=.9 }
                    addlSection[#addlSection + 1] = vf:row {
                        vf:spacer{ width=share'label_width' }, -- used in 'Settings' class.
                        vf:static_text {
                            title = "Additional Settings",
                            width = share'addl_sets_lbl_wid',
                        },
                    }
                    addlSection[#addlSection + 1] = vf:row {
                        vf:spacer{ width=share'label_width' }, -- used in 'Settings' class.
                        vf:separator {
                            width = share'addl_sets_lbl_wid',
                        },
                    }
                    addlSection[#addlSection + 1] = vf:spacer{ height=10 }
                end
                for i, v in ipairs( viewItems ) do
                    addlSection[#addlSection + 1] = v
                end
            else
                Debug.pause( "Thee are no settings view items." )
            end
        end }
    end

    if false and true then -- "uncomment" this to have additional settings as a button.
        appSection[#appSection + 1] = vf:spacer{ height=10 }
        appSection[#appSection + 1] = vf:row {
            vf:push_button {
                title = "View/Edit Additional Settings",
                action = function( button )
    			    app:call( Call:new{ name=button.title, async=true, guard=App.guardVocal, main=function( call )
    
                        local viewItems, viewLookup, errm = systemSettings:getViewItemsAndLookup( call ) -- note: this tosses error since it's the "root" items, if none.
                
                        if tab:isNotEmpty( viewItems ) then
                        
                            --Debug.lognpp( viewItems, viewLookup )
                        
                            local button = app:show{ info="Additional Settings",
                                viewItems = viewItems,
                            }
                
                            if button == 'ok' then
                                -- ok
                            else
                                call:cancel()
                                return
                            end
                            
                        else
                            app:show{ warning="no view items" }
                            call:cancel()
                            return
                        end
                        
                    end, finale=function( call )
                        if not call:isCanceled() then
                            --Debug.showLogFile()
                        end
                    end } )
                
                end,
            },
            vf:static_text {
                title = "Miscellaneous settings, defined initially by me, can be refined by you...",
            },
        }
    end
    
    if false and true and ( not app:isRelease() or app:isAdvDbgEna() ) then
    	appSection[#appSection + 1] = vf:push_button {
    	    title = "Evaluate Additional Settings",
    	    action = function( button )
    	        app:service{ name=button.title, async=true, guard=App.guardVocal, main=function( call )
    	            app:log()
    	            app:log( "Evaluating prefs/settings:" )
    	            call:initStats{ 'eval', 'keys' }
    	            call:setStat( 'keys', tab:countItems( systemSettings.lookup ) )
    	            local evaluated = {}
    	            local function eval( key, spec )
        	            local v1, v2
        	            if spec.dataType ~= 'array' then
            	            v1 = app:getPref( spec.id )
            	            v2 = systemSettings:getValue( key )
            	            -- [ [ works for simple test functions, but otherwise may not be such a good idea:
            	            if type( v1 ) == 'function' then
            	                v1 = v2{ paramOne="ValueOne", paramTwo="ValueTwo\netc..." }
            	            else -- assertion holds true if proxied function, but not on-the-fly compilation of text function.
            	                app:assert( v1==v2, "pref/setting value mismatch for '^1' (^2), pref: ^3, setting: ^4", spec.id, key, v1, v2 )
            	            end
            	            -- ] ]
        	                call:incrStat( 'eval' )
            	            app:log( "^1: ^2", spec.id, str:to( v1 ) )
            	        else
            	            v1 = app:getPref( arrName )
            	            Debug.pause( spec.id, arrName, v1 )
            	        end
    	            end
    	            local function evalArray( key, spec )
    	                app:log()
            	        local va1 = app:getPref( spec.id ) -- selected array item only, unless 'whole' is specified in spec itself.
            	        Debug.pauseIf( type( va1 ) ~= 'table' )
            	        local va2
            	        if not spec.whole then
    	                    app:log( "Evaluating array (selection) setting" )
            	            local va = systemSettings:getValue( spec.id ) -- not whole
            	            app:assert( tab:isEquivalent( va1, va ), "va1(sel) ~= va2(sel)" )
                	        for i, x in ipairs{ va } do
            	                Debug.pauseIf( type( x ) ~= 'table', type( x ) )
                    	        for k, v in pairs( x ) do
                    	            app:log( "^1: ^2", k, v )
                    	        end
                    	    end
                	        va2 = systemSettings:getValue( spec.id, nil, { whole=true } )
            	        else
    	                    app:log( "Evaluating array (whole) setting" )
                	        va2 = systemSettings:getValue( spec.id, nil, { whole=true } )
                	        app:assert( tab:isEquivalent( va1, va2 ), "va1(whole) ~= va2(whole)" )
          	                Debug.pauseIf( type( va2 ) ~= 'table', type( va2 ) )
                	        for i, x in ipairs( va2 ) do
            	                Debug.pauseIf( type( x ) ~= 'table', type( x ) )
                    	        for k, v in pairs( x ) do
                    	            app:log( "^1: ^2", k, v )
                    	        end
                    	    end
            	        end
       	                Debug.pauseIf( type( va2 ) ~= 'table', type( va2 ) )
              	        for i, x in ipairs( va2 ) do
            	            if type( x ) == 'table' then
                    	        for k, v in pairs( x ) do
                    	            evaluated[k] = true
            	                    call:incrStat( 'eval' )
                    	        end
                        	else
                        	    app:logV( "Array value not table: ^1, spec-id: ^1, assuming valid..", type( x ), spec.id )
                    	    end
                            call:incrStat( 'eval' )
                    	end
    	                app:log()
    	            end
    	            for key, spec in pairs( systemSettings.lookup ) do
    	                if spec.dataType == 'array' then
        	                local s, m = LrTasks.pcall( evalArray, key, spec )
        	                if not s then
        	                    app:logE( "Problem evaluating array, key: ^1, spec.id: ^2 - ^3", key, spec.id, m )
        	                end
        	            end
        	        end
    	            for key, spec in pairs( systemSettings.lookup ) do
    	                if spec.dataType ~= 'array' and not evaluated[spec.id] then
        	                local s, m = LrTasks.pcall( eval, key, spec )
        	                if not s then
        	                    app:logE( "Problem evaluating (non-array) setting, key: ^1, spec.id: ^2 - ^3", key, spec.id, m )
        	                end
        	            end
        	        end
    	        end, finale=function( call )
    	            app:log()
      	            app:log( "^1.", str:nItems( call:getStat( 'keys' ), "high-level setting keys" ) )
      	            app:log( "^1 evaluated.", str:nItems( call:getStat( 'eval' ), "setting elements" ) )
    	            app:log()
    	        end }
    	    end,
    	}
    end
        
    if not app:isRelease() then
    	appSection[#appSection + 1] = vf:spacer{ height = 20 }
    	appSection[#appSection + 1] = vf:static_text{ title = 'For plugin author only below this line:' }
    	appSection[#appSection + 1] = vf:separator{ fill_horizontal = 1 }
    	appSection[#appSection + 1] = 
    		vf:row {
    			vf:edit_field {
    				value = bind( "testData" ),
    			},
    			vf:static_text {
    				title = str:format( "Test data" ),
    			},
    		}
    	appSection[#appSection + 1] = 
    		vf:row {
    			vf:push_button {
    				title = "Test",
    				action = function( button )
    				    app:pcall{ name=button.title, async=true, guard=App.guardVocal, main=function( call )
                            --app:show( { info="^1: ^2" }, str:to( app:getGlobalPref( 'presetName' ) or 'Default' ), app:getPref( 'testData' ) )
                            --app:show{ info="^1", #catalog:getTargetPhotos() }
                            
                            
                            
                        end }
    				end
    			},
    			vf:static_text {
    				title = str:format( "Perform tests." ),
    			},
    		}
    end

    local sections = Manager.sectionsForBottomOfDialogMethod ( self, vf, props ) -- fetch base manager sections.
    if #appSection > 0 then
        local otherSection = addlSection and addlSection ~= appSection and addlSection or nil -- in other words, other section is nill unless defined and distinct from app section.
        tab:appendArray( sections, { appSection, otherSection } ) -- put app-specific prefs after.
    end
    return sections
end



return TreeSyncOrdererManager
-- the end.