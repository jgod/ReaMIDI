dofile(reaper.GetResourcePath().."/Scripts/ReaMIDI/requires/midi-process.lua")

-- MIDI Console for selecting and/or changing notes

-- helpfile in ReaMIDI\docs, type 'h' or 'help' in console to view it

local exit=false

function getValues()
  ok,retvals=""
  
  ok, retvals=reaper.GetUserInputs("MIDI Console",1,"Search:Action (h for help)","")
  if not ok then exit=true end
  local str=string.lower(retvals)
  
  if str~="" then
    local sections=str:split(":")
    if #sections==1 then
      if str=="" then 
        str="all"
        midiProcess(str,"","",true)
      else
        if str=="h" or str=="help" then
          os.execute(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\docs\\help.html")
        else
          midiProcess(str,"","",true)
        end
      end        
    end
    if #sections==2 then
      if sections[1]=="" then sections[1]="all" end
      if sections[2]:find('^[cmd]+$')==nil then -- 2 sections, but second is really third - [c]opy/[m]ove/[d]elete command
        midiProcess(sections[1],sections[2],"",true)
      else
        midiProcess(sections[1],"",sections[2],"",true)
      end
    end
    if #sections==3 then
        midiProcess(sections[1],sections[2],sections[3],true)
    end
  else
    exit=true 
  end
end


reaper.Undo_BeginBlock()
if exit==false then getValues() end
reaper.UpdateArrange()
reaper.Undo_EndBlock("MIDI Console", -1)
