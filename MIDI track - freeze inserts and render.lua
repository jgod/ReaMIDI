_DBG=true
function DBG(str)
  if _DBG then reaper.ShowConsoleMsg(str.."\n") end
end

DBG("--------------")


local function freezeAndRender(bus,is_direct_from_VSTi,tr,trn,st)
  local tt=tr
  if not is_direct_from_VSTi then                            
    st=reaper.GetTrack(0,trn+(bus<1 and 0 or bus)-1)        
    reaper.SNM_AddReceive(st,tt,3)
  else
    reaper.SNM_AddReceive(st,tt,3)
    local send_idx
    for i=1,reaper.GetTrackNumSends(st,0),1 do
      local ok, str=reaper.GetTrackSendName(st, i-1, "")
      DBG("Send Name: "..str)
      local track=reaper.BR_GetMediaTrackSendInfo_Track(st,0, i-1, 1)
      if track==tt then send_idx=i-1 end
    end
    reaper.BR_GetSetTrackSendInfo(st, 0, send_idx, "I_SRCCHAN", true, (bus<1 and 0 or (bus-1)*2))
  end
  reaper.SetMediaTrackInfo_Value(tr, "I_SOLO", 2) --0=not, 1=solo, =SIP
        
  reaper.SetOnlyTrackSelected(tt)
  local FREEZE_TRACKS=41223
  reaper.Main_OnCommand(FREEZE_TRACKS,-1)

  reaper.SetMediaTrackInfo_Value(tr, "I_SOLO", 0)
  
  
  reaper.SNM_RemoveReceivesFrom(tt, st)
  
  reaper.Undo_EndBlock("Render and lock MIDI track", 0)
end


local function renderToNewTrack(bus,tr,trn,st)
  DBG("trn: "..trn)
  trn=trn+(bus<1 and 0 or bus)-1
  st=reaper.GetTrack(0,trn)
  reaper.SetOnlyTrackSelected(st)
  local DUPLICATE_TRACKS=40062
  reaper.Main_OnCommand(DUPLICATE_TRACKS,-1)
  local FREEZE_TRACKS=41223
  reaper.Main_OnCommand(FREEZE_TRACKS,-1)
  local temp_track=reaper.GetTrack(0,trn+1)
  DBG("temp_track#: "..trn+1)
  local orig_track_idx=reaper.GetMediaTrackInfo_Value(tr,"IP_TRACKNUMBER")
  reaper.InsertTrackAtIndex(orig_track_idx, false)
  local new_track=reaper.GetTrack(0,orig_track_idx)
  for i=1,reaper.GetTrackNumMediaItems(temp_track),1 do
    local mi=reaper.GetTrackMediaItem(temp_track,0)
    local lock=reaper.SetMediaItemInfo_Value(mi,"C_LOCK",0)
    if i==1 then reaper.SetEditCurPos(reaper.GetMediaItemInfo_Value(mi,"D_POSITION"),false,false) end
    
    reaper.MoveMediaItemToTrack(mi,new_track)
  end
  reaper.SetOnlyTrackSelected(temp_track)
  local REMOVE_TRACKS=40005
  reaper.Main_OnCommand(REMOVE_TRACKS,-1)
  reaper.SetMediaTrackInfo_Value(tr, "B_MUTE", 1)
  reaper.Undo_EndBlock("Render to new track", 0)
  
end


local function renderOrFreeze(is_direct_from_VSTi, render_to_new_track)
  local sts=reaper.CountSelectedTracks(0)

  if sts==1 then
    
    local tr=reaper.GetSelectedTrack(0,0)
    if tr~=nil then
      -- if already "frozen", restore MIDI items
      DBG("No of frozen items: "..reaper.BR_GetMediaTrackFreezeCount(tr))
      if reaper.BR_GetMediaTrackFreezeCount(tr)>0 then --we have frozen items
        local UNFREEZE_TRACKS=41644
        reaper.Main_OnCommand(UNFREEZE_TRACKS,-1)
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_SENDS5"),-1)
        reaper.Undo_EndBlock("Unrender and unlock MIDI track", 0)
        return
      end
        
      if reaper.GetTrackNumSends(tr,0)>0 then
        local ok, str=reaper.GetTrackSendName(tr, 0, "")
        DBG(str)
        -- 0s = idx, idx, tracktype
        local st=reaper.BR_GetMediaTrackSendInfo_Track(tr,0 , 0, 1)
        local bus=reaper.BR_GetSetTrackSendInfo(tr, 0, 0, "I_MIDI_DSTBUS", false, 0)
        if bus==-1 then reaper.ShowMessageBox("First send does not send MIDI","Action not performed",0) return end
        DBG("Bus: "..bus)
        local trn=reaper.GetMediaTrackInfo_Value(st,"IP_TRACKNUMBER")
        
        if not render_to_new_track then 
          freezeAndRender(bus,is_direct_from_VSTi,tr,trn,st) 
        else 
          renderToNewTrack(bus,tr,trn,st)
        end
      end
    end
  end
end

--reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
renderOrFreeze(false,true)
--reaper.PreventUIRefresh(-1)