-- Transpose
-- does not tranpose names notes and does not transpose if any notes will
-- be moved to a named notes
-- channel 1 named notes are used, so it won't tranpose channel 14 to a named note
-- in channel 1 even if there are no named notes in channel 14
-- you can change this by changing 0 on line 24 and 31 to
-- n.chan for note channel or whatever you like

dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\midi.lua")
dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\strings.lua")


local target, notes=getTargetNotes(false,false)

local nn_error_list={} -- named notes
local ta_error_list={} -- transpose amount
local error=false


local note_names={
  ["C"]=0,  ["C#"]=1, ["Db"]=1, ["D"]=2,  ["D#"]=3, ["Eb"]=3, ["E"]=4,  ["F"]=5,  
  ["F#"]=6,  ["Gb"]=6, ["G"]=7,  ["G#"]=8,  ["Ab"]=8,  ["A"]=9,  ["A#"]=10,  ["Bb"]=10
}


function transpose(str)
  local trans_amount
  local spec_note=nil
  if str~="" then
    local sections=str:split(",")
    trans_amount=tonumber(sections[1])
    if trans_amount==nil then return end
    if #sections>1 then
      spec_note=note_names[string.upper(sections[2])]
      if spec_note==nil then return end
    end
  end
  
  if #notes>0 then
    local n
    for i=1,#notes,1 do 
      n=notes[i]
      if (spec_note~=nil and n.pitch%12==spec_note) or spec_note==nil then 
        if reaper.GetTrackMIDINoteName(n.tr_num-1,n.pitch,0)==nil then
          if n.pitch+trans_amount<0 or n.pitch+trans_amount>127 then
            if #ta_error_list==0 or (#ta_error_list>0 and ta_error_list[#ta_error_list]~=n.tr) then
              ta_error_list[#ta_error_list+1]=n.tr
            end
            error=true
          end
          if reaper.GetTrackMIDINoteName(n.tr_num-1,n.pitch+trans_amount,0)==nil then
            n.pitch=n.pitch+trans_amount
          else
            if #nn_error_list==0 or (#nn_error_list>0 and nn_error_list[#nn_error_list]~=n.tr) then
              nn_error_list[#nn_error_list+1]=n.tr
            end
            error=true
          end
        end
      end  
    end
    if error==false then
      setNotes(notes)
    else
      local tae=""
      if #ta_error_list>0 then
        tae="Notes out of range on tracks:\n\n"
        for i=1,#ta_error_list,1 do
          local _,t_name=reaper.GetSetMediaTrackInfo_String(ta_error_list[i], "P_NAME", "", false)
          tae=tae.."Track: "..t_name.."\n"
        end
      end
      local nne=""
      if #nn_error_list>0 then
        nne="\n\n\nCannot transpose into named notes on tracks:\n\n"
        for i=1,#nn_error_list,1 do
          local _,t_name=reaper.GetSetMediaTrackInfo_String(nn_error_list[i], "P_NAME", "", false)
          nne=nne.."Track: "..t_name.."\n"
        end
      end
      reaper.ShowMessageBox(tae..nne, "Did not transpose", 0) --type 0 = OK
    end
  end
end

ok,retvals=""
ok, retvals=reaper.GetUserInputs("MIDI Transpose",1,"Amount: ","")
retvals=trimWs(retvals)

reaper.Undo_BeginBlock()
transpose(retvals)
reaper.Undo_EndBlock("Transpose MIDI", -1)
reaper.UpdateArrange()

