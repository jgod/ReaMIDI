local LGUI=dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\el gui.lua")
dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\event-process.lua")

-- MIDI Console for selecting and/or changing events

-- helpfile in ReaMIDI\docs, type 'h' or 'help' in console to view it

---[[


LGUI.init("Event Console", 870, 100, false)

function execute(txt)
  --reaper.ShowConsoleMsg("Edit Box: "..txt.."\n")
  reaper.Undo_BeginBlock()
  processStr(txt)
  reaper.Undo_EndBlock("Event Console", -1)
  LGUI.exit_script=true
end

function button_click(args)
  n=tonumber(args)>0 and tonumber(args) or 0 
  reaper.ShowConsoleMsg("Button click!"..n.."\n")
  local ok, fn=reaper.GetUserFileNameForRead("", "Select preset file", 
                 ".reamidi")
  if ok then reaper.ShowConsoleMsg(fn) end
end


function createItem()
  dofile(reaper.GetResourcePath().."/Scripts/ReaMIDI/Create Item from Selected Notes.lua")
end


function init()
  editbox=LEditBox(20,40,750,20,20,100,true)
  function editbox:onEnter() execute(self.state.text) end
  LGUI.addControl(editbox)
  button=LButton(780,20,80,25,"Load Preset",button_click,"1")
  LGUI.addControl(button)
  button2=LButton(780,50,80,25,"Save Preset",button_click,"2")
  LGUI.addControl(button2)
  label=LLabel(20,70,100,20,[[type 'h' for help]])
  LGUI.addControl(label)
  combo=LComboBox(20,10,100,20,{"one","two","three"})
  LGUI.addControl(combo)
  create_button=LButton(250,10,150,20,"Create Item from Notes",createItem)
  LGUI.addControl(create_button)
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
        eventProcess(str,"","",true)
      else
        if str=="h" or str=="help" then
          os.execute("\""..reaper.GetResourcePath().."/Scripts/ReaMIDI/docs/event console.html\"")
        else
          eventProcess(str,"","",true)
        end
      end        
    end
    if #sections==2 then
      if sections[1]=="" then sections[1]="all" end
      if sections[2]:find('^[cmd]+$')==nil then -- 2 sections, but second is really third - [c]opy/[m]ove/[d]elete command
        eventProcess(sections[1],sections[2],"",true)
      else
        eventProcess(sections[1],"",sections[2],"",true)
      end
    end
    if #sections==3 then
        eventProcess(sections[1],sections[2],sections[3],true)
    end
  else
    exit=true 
  end
end
