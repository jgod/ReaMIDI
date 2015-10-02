dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\el gui.lua")

-- override this function to do something unique
function LListControl:onDoubleClick(x,y,m_mod)
  reaper.ShowConsoleMsg("onDoubleCLick\n")
  local ok, str=reaper.GetUserInputs("Rename",1,"Name: ","")
  y=y-self.y
  local row=math.floor((y-self.margin)/self.row_height)+self.first_vis_row
  if ok then self.state[row][1]=str end
end



local script_name="El GUI Test"
LGUI.state_name="I8bE"..script_name

--[[ --uncomment to delete state (for testing)
for i=1,10,1 do
  reaper.DeleteExtState(LGUI.state_name,i,true)
end
--]]


local editbox
function init()  
  gfx.init(script_name, 1000, 520, true)
  
  b=LButton(nil,nil,
                  false,
                  "Hello", 100,20,60,25,
                  {0.2,0.2,0.2},
                  {0.8,0.8,0.8},
                  nil
               )
  LGUI.addControl(b)
  
  b1=LButton(nil,nil,
                  true,
                  "Toggle", 100,60,60,25,
                  {0.2,0.2,0.2},
                  {0.8,0.8,0.8},
                  nil
               )
  LGUI.addControl(b1)
 
  cb=LCheckBox(250,20,150,10,"Label 1")
  LGUI.addControl(cb)
  cb:setColour(cb.colour_bg, 0,0,0)
 
  cb1=LCheckBox(250,50,150,10,"Label 2")
  LGUI.addControl(cb1)
  cb1:setColour(cb1.colour_bg, 0,0,0)
 
  llc=LListControl(20,100,400,400,10,
                      "Verdana",
                      {0.2,0.2,0.2},
                      {0.9,0.9,0.9},
                      {{"Mary",false},{"had",false},{"a",false},
                      {"little",false},{"lamb",false}} 
                )
  LGUI.addControl(llc)
  
  llc:setColour(llc.colour_fg, 0,0,0)
  
  editbox=LEditBox(20,400,500,30,50,50)
  LGUI.addControl(editbox)
end



function main() 
   gfx.x, gfx.y=0,0
   gfx.r=0xBB/255  gfx.g=0xBF/255   gfx.b=0xBF/255
   gfx.rect(0,0,780,520,true)
   gfx.x,gfx.y=250,100
   gfx.r,gfx.g,gfx.b=0,0,0
   gfx.setfont(1,"Arial", 30)--, "ub")
   gfx.printf("El GUI Testbed")
   LGUI.process(gfx.getchar(),main)
end

function onExit()
  LGUI.onExit()
end

reaper.atexit(onExit)
init()
main()
