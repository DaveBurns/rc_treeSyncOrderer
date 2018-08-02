--[[
        TreeSyncOrdererExport.lua
--]]


local TreeSyncOrdererExport, dbg, dbgf = Export:newClass{ className = 'TreeSyncOrdererExport' }



--[[
        To extend special export class, which as far as I can see,
        would never be necessary, unless this came from a template,
        and plugin author did not want to change it, but extend instead.
--]]
function TreeSyncOrdererExport:newClass( t )
    return Export.newClass( self, t )
end



--[[
        Called to create a new object to handle the export dialog box functionality.
--]]        
function TreeSyncOrdererExport:newDialog( t )

    local o = Export.newDialog( self, t )
    return o
    
end



--[[
        Called to create a new object to handle the export functionality.
--]]        
function TreeSyncOrdererExport:newExport( t )

    local o = Export.newExport( self, t )
    return o
    
end



--   E X P O R T   D I A L O G   B O X   M E T H O D S


--[[
        Export parameter change handler. This would be in base property-service class.
        
        Note: can not be method, since calling sequence is fixed.
        Probably best if derived class just overwrites this if property
        change handling is desired
--]]        
function TreeSyncOrdererExport:propertyChangeHandlerMethod( props, name, value )
    app:call( Call:new{ name = "expPropChgHdlr", guard = App.guardSilent, main = function( context, props, name, value )
        Export.propertyChangeHandlerMethod( self, props, name, value )
        dbg( "Extended export property changed" )
    end }, props, name, value )
end



--[[
        Called when dialog box is opening.
        
        Maybe derived type just overwrites this one, since property names must be hardcoded
        per export.
        
        Another option would be to just add all properties to the change handler, then derived
        function can just ignore changes, or not.
--]]        
function TreeSyncOrdererExport:startDialogMethod( props )
	Export.startDialogMethod( self, props ) -- @8/Jan/2012 this is a no-op, but that may change.
	--view:setObserver( props, 'noname', TreeSyncOrdererExport, Export.propertyChangeHandler )
end



--[[
        Called when dialog box is closing.
--]]        
function TreeSyncOrdererExport:endDialogMethod( props, why )
    Debug.pauseIf( why==nil, "why?" )
    Export.endDialogMethod( self, props, why )
end



--[[
        Fetch top sections of export dialog box.
        
        Base export class replicates plugin manager top section.
        Override to change or add to sections.
--]]        
function TreeSyncOrdererExport:sectionsForTopOfDialogMethod( vf, props )
    local sections = Export.sectionsForTopOfDialogMethod( self, vf, props )
    
    local s1 = {
        -- title
        -- synopsis...
    }
    
    --s1[#s1 + 1] = vf:row {
    --}
    
	if not tab:isEmpty( sections ) then
	    if not tab:isEmpty( s1 ) then
    	    tab:appendArray( sections, { s1 } ) -- append in place.
    	    return sections
    	else
    	    return sections
    	end
	elseif not tab:isEmpty( s1 ) then
	    return { s1 }
	else
	    return {}
	end
    
end



--[[
        Fetch bottom sections of export dialog box.
        
        Base export class returns nothing.
        Override to change or add to sections.
--]]        
function TreeSyncOrdererExport:sectionsForBottomOfDialogMethod( vf, props )
    local sections = Export.sectionsForBottomOfDialogMethod( self, vf, props )
    
    local s1 = {
        -- title
        -- synopsis...
    }
    
    --s1[#s1 + 1] = vf:row {
    --}
    
	if not tab:isEmpty( sections ) then
	    if not tab:isEmpty( s1 ) then
    	    tab:appendArray( sections, { s1 } ) -- append in place.
    	    return sections
    	else
    	    return sections
    	end
	elseif not tab:isEmpty( s1 ) then
	    return { s1 }
	else
	    return {}
	end
    
end



--   E X P O R T   M E T H O D S



--[[
        Called immediately after creating the export object which assigns
        function-context and export-context member variables.
        
        This is the one to override if you want to change everything about
        the rendering process (preserving nothing from the base export class).
--]]        
function TreeSyncOrdererExport:processRenderedPhotosMethod()
    Export.processRenderedPhotosMethod( self ) -- note: photo rend & photo fail methods are overridden to circumvent errors due to skipped rendering.
end



-- Determine if requisite filter is inserted and is at position #1.
-- (no way to tell if filters from *other* plugins are below it).
function TreeSyncOrdererExport:isReqFiltered( settings )
    local filterIdOrd = settings.LR_exportFiltersFromThisPlugin
    if not tab:is( filterIdOrd ) then return false, "no filters" end
    if tab:countItems( filterIdOrd ) > 1 then return false, "only one filter should be inserted" end
    if filterIdOrd.TreeSyncOrdererExportFilter then
        if filterIdOrd.TreeSyncOrdererExportFilter == 1 then
            return true
        else
            return false, "filter is not at top - it must be - remove all other filters."
        end
    else
        Debug.pause( "Wrong filter inserted - bug?" )
        return false, "Wrong filter inserted - bug?"
    end
end



--[[
        Remove photos not to be rendered, or whatever.
        
        Default behavior is to do nothing except assume
        all exported photos will be rendered. Override
        for something different...
--]]
function TreeSyncOrdererExport:checkBeforeRendering()
    -- reminder: new instance is created (with check-status nil) for each invocation.
    
    local go, noGo = tso:checkSel()
    if go then -- go
        -- some msg may have been logged.
    elseif go == nil then -- unsure
        app:logW( noGo ) -- log warning and keep on truckin'
    else -- go is false
        app:logW( noGo )
        self:cancelExport() -- remove all photos to export from export session.
        return
    end
    
    local sts, err = self:isReqFiltered( self.exportParams or error( "no export params" ) )
    if sts then
        app:logV( "Requisite filter is present." )
    else
        app:logW( "Filter config not copacetic - ^1 - export will do nothing. To remedy, use preset provided with plugin, or insert 'TreeSync Orderer' filter (post-process action) and remove all others.", err or "no errm" )
        self:cancelExport() -- remove all photos to export from export session.
    end
    return
    
end



--[[
        Process one rendered photo.
        
        Called in the renditions loop. This is the method to override if you
        want to do something different with the photos being rendered...
--]]
function TreeSyncOrdererExport:processRenderedPhoto( rendition, photoPath )
    Debug.pause( rendition, photoPath, rendition.wasSkipped ) -- exp-path.
    --Export.processRenderedPhoto( self, rendition, photoPath )
    app:logW( "Photo was rendered - it shouldn't be. Seems the export filter isn't, well, filtering..." )
end



--[[
        Process one rendering failure.
        
        process-rendered-photo or process-rendering-failure -
        one or the other will be called depending on whether
        the photo was successfully rendered or not.
        
        Default behavior is to log an error and keep on truckin'...
--]]
function TreeSyncOrdererExport:processRenderingFailure( rendition, message )
    --Export.processRenderingFailure( self, rendition, message ) - dont do this (failed rendering is the norm for this plugin)
    -- note: although rendition was skipped the was-skipped flag won't be set - dunno why not.
    -- message will typically be nil
    Debug.pauseIf( message ~= nil, "hm - got msg", message )
    -- could log something, but what's the point? ###2
end



--[[
        Handle special export service...
        
        Note: The base export service method essentially divides the export
        task up and calls individual methods for doing the pieces. This is
        the one to override to change what get logged at the outset of the
        service, or you the partitioning into sub-tasks is not to your liking...
--]]
function TreeSyncOrdererExport:service()
    Export.service( self )
end



--[[
        Handle special export finale...
--]]
function TreeSyncOrdererExport:finale( service, status, message )
    app:log( str:format( "^1 finale, ^2 rendered.", service.name, str:plural( self.nPhotosRendered, "photo" ) ) )
    Export.finale( self, service, status, message )
end



-----------------------------------------------------------------------------------------



--   E X P O R T   S E T T I N G S


TreeSyncOrdererExport.showSections = {}--'exportLocation', 'fileNaming', 'fileSettings', 'imageSettings', 'outputSharpening', 'metadata', 'video', 'watermarking' }
--TreeSyncOrdererExport.hideSections = { 'exportLocation', 'fileNaming', 'fileSettings', 'imageSettings', 'outputSharpening', 'metadata', 'video', 'watermarking' } -- the same as positive form.
-- TreeSyncOrdererExport.allowFileFormats = { 'JPEG' }
-- TreeSyncOrdererExport.allowColorSpaces = { 'sRGB' }
local exportParams = {}
exportParams[#exportParams + 1] = { key = 'one', default = false }
TreeSyncOrdererExport.exportPresetFields = exportParams


-- Direct inheritance so extended function members are recognized by Lightroom.
TreeSyncOrdererExport:inherit( Export )


return TreeSyncOrdererExport
