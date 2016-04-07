local function DBG(str)
  --reaper.ShowConsoleMsg(str.."\n")
end

jsfx={} --store details of helper effect
jsfx.name="Script Note Getter"
jsfx.fn="Script Note Getter"
--jsfx.body at end of script

function createJSEffect(fn,str)
  local file=io.open(reaper.GetResourcePath().."/Effects/"..fn, "w")
  file:write(str)
  file:close()
end


function deleteJSEffect(fx)
  os.remove(reaper.GetResourcePath().."/Effects/"..fx.fn)
end


function removeJSEffect(track,fx)
  local chunk,ok="",false
  ok,chunk=reaper.GetTrackStateChunk(track,chunk, false)
  local pattern="(BYPASS %d %d %d[%c%s].JS \""..fx.name..".-WAK %d)"
  local replacements
  chunk,replacements=string.gsub(chunk,pattern,"")
  if replacements>0 then
    ok=reaper.SetTrackStateChunk(tr,chunk,false)
    deleteJSEffect(fx)
    return true
  end
  return false
end


function getOrAddInputFx(track,fx,create_new)
  local idx=reaper.TrackFX_AddByName(track,fx.name,true,1)
  if idx==-1 or idx==nil then
    idx=reaper.TrackFX_AddByName(track,fx.fn,true,1)
    if (idx==nil or idx==-1) and create_new==true then
      createJSEffect(fx.fn,fx.body)
      idx=getOrAddInputFx(track,fx,false)
      return idx
    else 
      tr=nil
      return -1
    end
  end
  idx=idx|0x1000000
  reaper.TrackFX_SetEnabled(track, idx, true)
  return idx
end


local delete_ahead=0.15 --so that notes don't sound
function _getNotes(tk,_pitch,pp_qn,check_start,l_start)
  local ni, tr, it
  local midi={}
  cnt=0
  
  local ok, sel, mute, startpos, endpos, chan, pitch, vel=reaper.MIDI_GetNote(tk, 0)
  while ok do
    if pitch==_pitch then
      startpos=reaper.MIDI_GetProjQNFromPPQPos(tk, startpos)
      endpos=reaper.MIDI_GetProjQNFromPPQPos(tk, endpos)
      if (startpos<=pp_qn+delete_ahead and endpos>=pp_qn) or 
          (check_start and startpos>=l_start and startpos<=l_start+delete_ahead) then
        local note={ type="note", idx=cnt, -- 6
                    select=sel,mute=mute, ostartpos=startpos, --12
                    startpos=startpos, endpos=endpos, len=endpos-startpos, 
                    pitch=pitch, chan=chan, vel=vel }
        midi[#midi+1]=note
      end
    end
    cnt=cnt+1
    ok, sel, mute, startpos, endpos, chan, pitch, vel=reaper.MIDI_GetNote(tk, cnt)      
  end
  return midi
end


local delete_ahead=0.15 --so that notes don't sound
function getNotes(tk,pitches,pp_qn,check_start,l_start)
  local ni, tr, it
  local midi={}
  cnt=0
  
  local ok, sel, mute, startpos, endpos, chan, pitch, vel=reaper.MIDI_GetNote(tk, 0)
  while ok do
    for i=1,#pitches,1 do
      if pitch==pitches[i] then
        startpos=reaper.MIDI_GetProjQNFromPPQPos(tk, startpos)
        endpos=reaper.MIDI_GetProjQNFromPPQPos(tk, endpos)
        if (startpos<=pp_qn+delete_ahead and endpos>=pp_qn) or 
            (check_start and startpos>=l_start and startpos<=l_start+delete_ahead) then
          local note={ type="note", idx=cnt, -- 6
                    select=sel,mute=mute, ostartpos=startpos, --12
                    startpos=startpos, endpos=endpos, len=endpos-startpos, 
                    pitch=pitch, chan=chan, vel=vel }
          midi[#midi+1]=note
        end
      end
    end
    cnt=cnt+1
    ok, sel, mute, startpos, endpos, chan, pitch, vel=reaper.MIDI_GetNote(tk, cnt)      
  end
  return midi
end


function dMdelete()
  -- tr, tk, helper_idx set in prep()
  -- get number of held notes from helper plugin
  nib=reaper.TrackFX_GetParam(tr, helper_idx, 1) --1=note in buffer
  if nib>0 then
    -- get loop points and check whether cursor is near the end
    -- so we can delete on return to start of loop without them
    -- playing
    local l_start, l_end=reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    l_start=reaper.TimeMap2_timeToQN(0, l_start)
    l_end=reaper.TimeMap2_timeToQN(0, l_end)
    local pp=reaper.GetPlayPosition()
    local pp_qn=reaper.TimeMap2_timeToQN(0, pp)
    local check_start=l_end-pp_qn<delete_ahead and true or false
    
    --get held notes from buffer in helper plugin
    local pitches={}
    for i=1,nib,1 do
      reaper.TrackFX_SetParam(tr,helper_idx,2,i-1) --set Note# to i
      pitches[#pitches+1],_,_=reaper.TrackFX_GetParam(tr, helper_idx, 3)
    end 
    local notes=getNotes(tk,pitches,pp_qn,check_start,l_start)
      
    if #notes>0 then
      DBG("Deleting notes...")
      reaper.Undo_BeginBlock() -- create undo point for these notes
      --always go backwards deleting notes
      for i=#notes,1,-1 do
        reaper.MIDI_DeleteNote(tk,notes[i].idx)
      end
      reaper.Undo_EndBlock("DM Delete - delete notes",4)
    end
    
    reaper.UpdateArrange()
  end
  reaper.defer(dMdelete)
end


function prep()
  DBG("in prep")
  local ame=reaper.MIDIEditor_GetActive()
  local mode=reaper.MIDIEditor_GetMode(ame)
  if mode > -1 then -- we are in a MIDI editor, -1 if ME not focused
    tk=reaper.MIDIEditor_GetTake(ame)
    tr=reaper.GetMediaItemTake_Track(tk)
  else -- get rec armed, selected track
    if reaper.CountSelectedTracks()>0 then
        tr=reaper.GetSelectedTrack(0,0)
        local _,t_name=reaper.GetSetMediaTrackInfo_String(tr,"P_NAME"," ",false)
        local _, ts=reaper.GetTrackState(tr)
        if ts&64==64 and ts&2==2 then -- is rec armed and selected
        local num_items=reaper.CountTrackMediaItems(tr)
        if num_items>0 then
          local l_start,l_end=reaper.GetSet_LoopTimeRange(false,true,0,0,true)
          local cur=reaper.GetCursorPosition()
          local i=1
          while i<=num_items do
            local it=reaper.GetTrackMediaItem(tr,i-1)
            local i_start=reaper.GetMediaItemInfo_Value(it,"D_POSITION")
            if math.floor(l_start*10)==math.floor(i_start*10) then
              tk=reaper.GetActiveTake(it)
              i=num_items
            end
            i=i+1
          end
        end
      end
    end
  end
  if tk~=nil and reaper.BR_IsTakeMidi(tk) then
    helper_idx=getOrAddInputFx(tr,jsfx,true)
    DBG("helper_idx="..helper_idx)
    if helper_idx>-1 then
      reaper.TrackCtl_SetToolTip("!-!-!-!-!-!  Live Delete ACTIVE  !-!-!-!-!-!", 800,20, true)
      dMdelete()
    else
      DBG("No effect added")
    end
  end
end


function cleanUp()
  if helper_idx~=nil then
    reaper.TrackCtl_SetToolTip("--- Live Delete Inactive ---", 800,20, true)
    DBG("exit")
    --removeJSEffect(tr,jsfx) --set chunk causes glitches
                              --so can't remove input FX
    reaper.TrackFX_SetEnabled(tr, helper_idx, false)
  else
    reaper.ReaScriptError("Need active take in MIDI editor!")
  end

end



jsfx.body=[[
desc:Script MIDI Monitor

slider1:0<0,1,1{On,Off}>Active (eats notes)
slider2:0<0,127,1>Notes in buffer
slider3:0<0,1000,1>Note # (for script)
slider4:0<0,127,1>Output Pitch
slider5:0<0,1,1>Trigger


@init
notebuf=0; //start pos of buffer
nb_width=3; //number of entries per note
buflen=0; //notes in buffer

function addRemoveNoteFromBuffer(m1,m2,m3)
( 
  s = m1&$xF0;
  c = m1&$xF; // channel
  n = m2;
  v = m3; // velocity
  
  init_buflen=buflen;
  
  i = -1;
  while // look for this note|channel already in the buffer
  (
    i = i+1;
    i < buflen && (notebuf[nb_width*i]|0 != n || notebuf[nb_width*i+1]|0 != c);
        );

    (s == $x90 && v > 0) ? // note-on, add to buffer
    ( 
      notebuf[nb_width*i] = n;
      notebuf[nb_width*i+1] = c;
      notebuf[nb_width*i+2] = v;
      i == buflen ? buflen = buflen+1;
    ) 
    : // note-off, remove from buffer
    (
      is_note_off=1;
      i < buflen ?
      (
         memcpy(notebuf+nb_width*i, notebuf+nb_width*(i+1),
                      nb_width*(buflen-i-1));  // delete the entry
         buflen = buflen-1;
       );
    );
    buflen==init_buflen ? -1; //return value for nothing added/removed
);


@slider
p=slider3*nb_width; //position in buffer
slider4=notebuf[p];


@block
while (midirecv(offset,msg1,msg2,msg3))
(  
  slider1 ? (
    midisend(offset,msg1,msg2,msg3);
  ):( //eating notes
    msg1|$x90==$x90 ? (
      addRemoveNoteFromBuffer(msg1,msg2,msg3);
    );
    msg1|$x80==$x80 ? (
      addRemoveNoteFromBuffer(msg1,msg2,msg3)==-1 ? (
        //no note in buffer, so allow trailing note-offs through
        midisend(offset,msg1,msg2,msg3);
      );
    );
    slider2=buflen;
  );
)
]]

script_init=true
reaper.atexit(cleanUp)
script_init=false
reaper.Undo_BeginBlock()
prep()
reaper.Undo_EndBlock("DM Delete",-1)





