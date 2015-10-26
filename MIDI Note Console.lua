dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\el gui.lua")
dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\midi-process.lua")

-- MIDI Console for selecting and/or changing notes

-- helpfile in ReaMIDI\docs, type 'h' or 'help' in console to view it

---[[


LGUI.init("MIDI Note Console", 800, 100, false)

function test(txt)
  --reaper.ShowConsoleMsg("Edit Box: "..txt.."\n")
  reaper.Undo_BeginBlock()
  processStr(txt)
  reaper.Undo_EndBlock("MIDI Console", -1)
  LGUI.exit_script=true
end


function init()
  editbox=LEditBox(20,40,780,20,20,100,true)
  function editbox:onEnter() test(self.state.text) end
  LGUI.addControl(editbox)
end


function main() 
   LGUI.process(gfx.getchar(),main)
end

local exit=false
init()
main()
--]]


function processStr(str)
  str=string.lower(str)
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
        midiProcess(sections[1],"",sections[2],true)
      end
    end
    if #sections==3 then
        midiProcess(sections[1],sections[2],sections[3],true)
    end
  else
    exit=true 
  end
end