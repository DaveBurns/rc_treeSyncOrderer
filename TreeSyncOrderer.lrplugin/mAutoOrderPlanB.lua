local selPhotosEtc = cat:saveSelPhotos()
app:service{ name="Auto-order, Plan B..", async=true, guard=App.guardVocal, function( call )
    --local srv = PublishServices:new():getPublishService( "MyHardDrivePublishService" )
    autoMode = true -- global
    local sco = SmartCollections:new()
    local smartCollsToo
    local updCutoff
    local time = LrDate.currentTime()
    cat:clearViewFilter()
    local function doPhotos( photos, src, typ, pth )
        if #photos == 0 then
            app:log( "No photos - skipped." )
            return
        end
        local name = { typ, pth }
        local ent = fprops:getPropertyForPlugin( _PLUGIN, name )
        if ent and type( ent[1] ) == 'table' then
            local upd = ent[1].updated
            if upd then
                if upd > 0 then
                    if ( time - upd ) > updCutoff then
                        app:log( "Entry is old - updating it." )
                    else
                        app:log( "Entry is recent - ignoring it." )
                        return
                    end
                else
                    app:log( "Entry is non-existent or invalid - updating it..." )
                end
            else
                app:log( "Entry is non-existent or invalid - updating it.." )
            end
        else
            app:log( "Entry is non-existent or invalid - updating it." )
        end
        local s, m = cat:setActiveSources{ src }
        if s then
            local s, m = cat:setSelectedPhotos( photos[1], photos ) -- don't assure via folders, and no cache.
            if s then
                repeat
                    local a = app:show{ confirm="Ready?\n \nIf export dialog box is displayed, then answer 'No' and click 'Export'. If any other dialog boxes are being displayed, then answer 'No', and dismiss said dialog boxes (you'll have 3 seconds to do so). If all clear (no such dialog boxes or other obstructions..), answer 'Yes'.",
                        buttons = dia:yesNoCancel(),--{ dia:btn( "Yes", 'ok' ),   },
                    }
                    if a == 'ok' then
                        break
                    elseif a == 'other' then
                        app:sleep( 3 )
                        if call:isQuit() then return end
                    elseif a == 'cancel' then
                        call:cancel()
                        return
                    else
                        error( "bad btn" )
                    end
                until false
                if WIN_ENV then
                    app:sendWinAhkKeys( "{Ctrl Down}{Shift Down}e{Shift Up}{Ctrl Up}" )
                else
                    app:sendMacEncKeys( "CmdShift-e" )
                end
                app:sleep( 2 )
                if call:isQuit() then return end
            else
                app:logE( "Unable to order '^1' due to error selecting photos: ^2", cat:getSourceName( src ), m )          
            end
        else
            app:logE( "Unable to order '^1' due to error setting as active source: ^2", cat:getSourceName( src ), m )          
        end
    end
    local function doColl( coll )
        if call:isQuit() then return end
        local pth = collections:getFullCollPath( coll )
        app:log()
        app:log( pth )
        local photos
        if coll:isSmartCollection() then
            if smartCollsToo then
                photos = sco:getPhotos( coll )
            else
                app:log( "Not doing smart collections - skipped." )
                return
            end
        else
            photos = coll:getPhotos() -- ###1 smart colls?
        end
        doPhotos( photos, coll, cat:getSourceType( coll ), pth )
    end
    local function doSet( set )
        for i, v in ipairs( set:getChildCollections() ) do
            doColl( v )
            if call:isQuit() then return end
        end
        for i, v in ipairs( set:getChildCollectionSets() ) do
            doSet( v )
            if call:isQuit() then return end
        end
    end
    local function doFolder( fldr )
        if call:isQuit() then return end
        local pth = fldr:getPath()
        app:log()
        app:log( pth )
        local photos = fldr:getPhotos()
        doPhotos( photos, fldr, cat:getSourceType( fldr ), pth )
        for i, v in ipairs( fldr:getChildren() ) do
            doFolder( v )
            if call:isQuit() then return end
        end
    end
    local srcs = catalog:getActiveSources()
    if #srcs ~= 1 or not srcs[1].getParent then
        app:show{ warning="Before invoking this function, select any source (folder or collection or set) in hierarchy to be ordered." }
        call:cancel()
        return
    end
    local rootSrc = srcs[1]
    local topSrc
    local typSfx = rootSrc:type():sub( -3 )
    if typSfx == "Set" or typSfx == "der" then -- if collection set or folder - take as is.
        topSrc = rootSrc
    else
        repeat
            if not rootSrc.getParent or rootSrc:getParent() == nil then
                if rootSrc.getService then
                    topSrc = rootSrc:getService()
                    break
                else
                    break
                end
            else
                topSrc = rootSrc:getParent()
            end
        until true
    end
    if not topSrc then
        app:show{ warning="Invalid source selection." }
        call:cancel()
        return
    end
    app:initPref( 'updateIfOlderThan', 0 ) -- minutes.
    app:initPref( 'smartCollsToo', false )
    local vi = {}
    vi[#vi + 1] = vf:row {
        vf:static_text {
            title = "Update if older than"
        },
        vf:edit_field {
            value = app:getPrefBinding( 'updateIfOlderThan' ),
            min = 0,
            max = 9999,
            precision = 0,
            width_in_digits = 4,
            tooltip = "Enter cutoff in minutes. Newer entries, if existing, will be ignored. Older entries, or non-existent entries will be updated.\n \nMaximum of 9999 minutes is about a week; to update all entries regardless of age, enter 0.",
        },
        vf:static_text {
            title = "minutes."
        },
        vf:spacer{ width = 10 },
        LrView.conditionalItem (
            typSfx ~= "der",
            vf:checkbox {
                title = "Smart Collections Too",
                value = app:getPrefBinding( 'smartCollsToo' ),        
                tooltip = "If checked, smart collections will be ordered too (takes a little longer); if unchecked, only non-smart collections will be ordered.",
            }
        ),
    }
    local a = app:show{ confirm="Auto-order '^1' via plan B? (only do this if auto-ordering in TSP via plugin manager button does not work)",
        cat:getSourceName( topSrc ),
        viewItems = vi,
    }
    if a == 'cancel' then
        call:cancel()
        return
    end
    updCutoff = app:getPref{ name='updateIfOlderThan', default=0 } * 60
    if typSfx == 'der' then -- folder
        doFolder( topSrc )
    else
        smartCollsToo = app:getPref( 'smartCollsToo' )
        doSet( topSrc )
    end
    --doSet( topSrc )
    --doSet( topSrc )
end, finale=function( call )
    autoMode = false
    if selPhotosEtc then
        cat:restoreSelPhotos( selPhotosEtc )
    end
end }
return true