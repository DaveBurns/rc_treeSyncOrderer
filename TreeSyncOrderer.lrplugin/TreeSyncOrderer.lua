--[[
        TreeSyncOrderer.lua
--]]


local TreeSyncOrderer, dbg, dbgf = Object:newClass{ className = "TreeSyncOrderer", register = true }



--- Constructor for extending class.
--
function TreeSyncOrderer:newClass( t )
    return Object.newClass( self, t )
end


--- Constructor for new instance.
--
function TreeSyncOrderer:new( t )
    local o = Object.new( self, t )
    return o
end



-- reminder, this is only called in manual export mode, not auto-ordering publish mode.
function TreeSyncOrderer:checkSel()
    local srcs = catalog:getActiveSources()
    if tab:isArray( srcs ) then
        -- note: theoretically, ordering could be done via a subset, but there is hardly any reason to, since this is a very quick operation.
        -- also: it's conceivable that 
        local targetPhotos = catalog:getTargetPhotos() -- selected OR visible.
        if #targetPhotos > 1 then
            local vis = cat:getVisiblePhotos()
            local sel = cat:getSelectedPhotos() -- note: it could be that none are selected
            if #sel == 0 then -- all are being exported.
                app:logV( "No photos are selected, so all visible photos in filmstrip are weighing in - good." )
            elseif #sel < #vis then
                app:log( "*** Some photos are not selected (^1 selected, ^2 not selected), if unselected photos will be subsequently published/exported and ordered, their ordering may not be correct.", #sel, #vis - #sel )
            elseif #sel == #vis then
                app:logV( "All visible photos are selected - good." )
            else
                Debug.pause( "More photos are selected than are visible - how is that possible?" )
                app:logV( "*** More photos are selected than are visible - how is that possible?" )
            end
        else
            -- note: the bizarre phenomenon of one photo being targeted when nothing in multi-photo filmstrip selected has gone away following restart,
            -- but this whacked out code here is being kept as a reminder (and it doen't hurt in case problem returns..).
            local sel = cat:getSelectedPhotos()
            if #sel == 1 then
                if autoMode then
                    app:logV( "*** Only 1 photo is selected - hmm..." )
                    return true
                else
                    return nil, str:fmtx( "Not much point assessing relative ordering of photos if only ^1 selected - run again with multiple photos selected (e.g. all in collection or folder), or no photos selected (to do whole filmstrip).", #targetPhotos )
                end
            elseif #sel == #targetPhotos then -- both 0
                if autoMode then
                    app:logV( "*** No photos are selected - hmm..." )
                    return true
                else
                    Debug.pause( "No photos selected?" )
                    return nil, str:fmtx( "Not much point assessing relative ordering of photos if no photos are selected - run again with multiple photos selected (e.g. all in collection or folder), or no photos selected (to do whole filmstrip)." )
                end
            elseif #sel == 0 then -- targ=1
                -- ###4 should only be true for a 1-photo filmstrip but is being true now when nothing selected (get-target-photos is not returning filmstrip!).
                app:logV( "*** Only one target (none selected): ^1", cat:getPhotoNameDisp( targetPhotos[1], true ) ) -- no cache.
                -- return true
            else
                Debug.pause( "Not sure why target photo count not jiving with selected photo count." )
                app:logV( "Targets: ^1, selected: ^2", #targetPhotos, #sel )
                -- return true -- I guess.
            end
        end
    else -- probably never happens
        return false, "Select one or more photo sources (folder or collection), then try again."
    end            
    return true
end


return TreeSyncOrderer