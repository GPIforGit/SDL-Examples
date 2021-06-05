EnableExplicit

DeclareModule SDL_Config
  #UseImage = #True
  #UseTTF = #True  
EndDeclareModule

XIncludeFile #PB_Compiler_Home + "Include/sdl2/SDL.pbi"


#TITLE = "Floslectum"
#field_width = 25
#field_height = 14
#BaseScreen_width = #field_width * 32 +32
#BaseScreen_height = #field_height * 32 +32
#RenderScale = 2

#Flower_max = 10
#ConId_Max = #field_width*#field_height / 4

#animation_Rate = 1000.0/60.0 ; we need floats here!

;-structures
Prototype.l pMenuCallback(value.i)
Structure sMenuItem
  size.l
  *texture.sdl::texture
  pos.sdl::Rect
  callback.pMenuCallback
  w.l
  h.l
  flag.l
  value.i
EndStructure

Structure sMenu
  List items.sMenuItem()
  background.sdl::Rect
  innerWidth.l
  callbackEscape.pMenuCallback
  valueEscape.i
EndStructure

Structure sScreen
  Display.sdl::rect
  FieldPixelWidth.l
  FieldPixelHeight.l
  FieldOffset.sdl::point
  ScreenWidth.l
  ScreenHeight.l
  FlowerSize.l
  FlowerPlace.SDL::Rect  
  scale.f
  *texture.sdl::Texture
  *window.SDL::Window
  *renderer.SDL::Renderer
EndStructure

Structure sGameControl
  DoGame.l
  DoMenu.l
  Quit.l
  GameRule.l
  
  count.d
  rate.d
  count2.d
  rate2.d
 
  maxFlower.l
  Flower.l
  
EndStructure

Structure sAnimation
  x.f
  y.f
  dx.f
  dy.f
  gravitation.f
  Angle.d
  dAngle.d
  *texture.sdl::Texture
EndStructure

Structure sPlace
  x.l
  y.l
  FlowerColor.l  
  Direction.l
EndStructure

Structure sSwap
  x.l
  y.l
  Direction.l
EndStructure

Structure sMouse
  x.l
  y.l
  StartX.l
  StartY.l
  ButtonDown.l
  
  FieldX.l
  FieldY.l
  Direction.l
  moveX.l
  moveY.l
  SwapX.l
  SwapY.l
  
EndStructure

Structure sFlower
  FlowerColor.l
  Flags.l
  ConId.l
  angle.d
  Animation.d
EndStructure
Structure sLine
  x.sFlower[#field_width]
EndStructure
Structure sField
  y.sLine[#field_height]
EndStructure

Structure sTextures
  *background.sdl::Texture
  Array *Flowers.SDL::Texture(#Flower_max)
EndStructure

EnumerationBinary FlowerFlags
  #Flower_delete
  #Flower_loose
  #Flower_isDeath
EndEnumeration
#Flower_Animation = #Flower_isDeath

EnumerationBinary Dir
  #stay = 0
  #left
  #right
  #up
  #down    
EndEnumeration
EnumerationBinary menuflags
  #menu_header
  #menu_highlight
  #menu_center
  #menu_left
  #menu_right
  #menu_hold
  #menu_escape
EndEnumeration
Enumeration GameRule
  #noGame
  #Endless
EndEnumeration
;-globals

Global textures.sTextures
Global Field.sField
Global NewList *_textures.SDL::Texture()
Global NewList _fields.sField()
Global NewList Places.sPlace()
Global NewList Swaps.sSwap()
Global mouse.smouse
Global NewList Animation.sAnimation()
Global screen.sScreen
Global AnimationOnHold
Global GameControl.sGameControl
Global menu.sMenu
Global *TextFont.SDL::ttf_font

Procedure menu_ClearItem()
  If menu\items()\texture
    sdl::DestroyTexture( menu\items()\texture )
  EndIf
  DeleteElement(menu\items())
  menu\callbackEscape = #Null
EndProcedure

Procedure menu_Clear()
  ForEach menu\items()
    menu_ClearItem()
  Next
EndProcedure

Procedure menu_SetItem(text.s, size.l,callback.pMenuCallback,value.l=#Null,flag.l=#Null)
  If menu\items()\texture
    sdl::DestroyTexture( menu\items()\texture )
    menu\items()\texture = #Null
  EndIf
  
  Protected.sdl::color color
  Protected.l none
  color\r = $ff
  color\g = $ff
  color\b = $ff
  color\a = $ff
  menu\items()\size = size
  menu\items()\callback = callback
  menu\items()\flag = flag
  menu\items()\value = value
    
  If flag & #menu_escape
    menu\callbackEscape = callback
    menu\valueEscape = value
  EndIf
    
  Protected *surface= SDL::TTF_RenderText_Blended( *TextFont, text, color)
  menu\items()\texture = sdl::CreateTextureFromSurface( screen\renderer, *surface)
  sdl::FreeSurface(*surface)
  
  If menu\items()\texture
    sdl::QueryTexture(menu\items()\texture, #Null, #Null, @menu\items()\w,@menu\items()\h)
    sdl::SetTextureScaleMode( menu\items()\texture, sdl::#ScaleModeBest)
    ProcedureReturn #True
  EndIf
    
  ProcedureReturn #False  
EndProcedure

Procedure menu_AddItem(text.s, size.l,callback.pMenuCallback,value.l=#Null,flag.l=#Null)
  AddElement(menu\items())
  menu_SetItem(text.s, size.l,callback.pMenuCallback,value,flag)
  ProcedureReturn @menu\items()
EndProcedure

Procedure menu_Calc()
  Protected.l y
  Protected.l spacewidth
  Protected.l border,innerBorder
  sdl::TTF_SizeText(*TextFont," ",@spacewidth,#Null)
  
  ; calculate width/height
  menu\background\w = 0
  menu\background\h = 0
  menu\innerWidth = 0
  
  ForEach menu\items()
    menu\items()\pos\h = menu\items()\size * screen\ScreenHeight / #BaseScreen_height
    menu\items()\pos\w = menu\items()\w * menu\items()\pos\h / menu\items()\h
    
    innerBorder + menu\items()\pos\w
    If innerBorder > menu\innerWidth
      menu\innerWidth = innerBorder
    EndIf
    border + menu\items()\pos\w + 2 * spacewidth * menu\items()\pos\h / menu\items()\h
    If border > menu\background\w
      menu\background\w = border
    EndIf
    
    If Not menu\items()\flag & #menu_hold 
      menu\background\h + menu\items()\pos\h
      border = 0
      innerBorder = 0
    EndIf    
    
  Next
  
  ;position all elements
  y = (screen\ScreenHeight - menu\background\h) / 3
  menu\background\x = (screen\ScreenWidth - menu\background\w) / 2
  menu\background\y = y
  ForEach menu\items()
    If menu\items()\flag & #menu_left
      menu\items()\pos\x = (screen\ScreenWidth - menu\innerWidth) / 2
    ElseIf menu\items()\flag & #menu_right
      menu\items()\pos\x = (screen\ScreenWidth + menu\innerWidth) / 2 - menu\items()\pos\w
    Else
      menu\items()\pos\x = (screen\ScreenWidth - menu\items()\pos\w) / 2
    EndIf
    menu\items()\pos\y = y
    If Not menu\items()\flag & #menu_hold 
      y + menu\items()\pos\h    
    EndIf
  Next
EndProcedure

Procedure menu_mouse(x.l,y.l,doClick.l)
  ForEach menu\items()
    If menu\items()\pos\x <= x And menu\items()\pos\y <= y And
       x < menu\items()\pos\x + menu\items()\pos\w And y < menu\items()\pos\y + menu\items()\pos\h
      menu\items()\flag | #menu_highlight
      If doClick And menu\items()\callback
        menu\items()\callback( menu\items()\value )
      EndIf
    Else
      menu\items()\flag & (~#menu_highlight)
    EndIf
  Next
EndProcedure

Procedure menu_doEscape()
  If menu\callbackEscape
    menu\callbackEscape( menu\valueEscape )
  EndIf
EndProcedure

Procedure menu_Draw()
  sdl::SetRenderDrawColor(screen\renderer, 0,0,0,128)
  sdl::SetRenderDrawBlendMode(screen\renderer, sdl::#BLENDMODE_BLEND)
  
  sdl::RenderFillRect(screen\renderer, menu\background)
  
  sdl::SetRenderDrawBlendMode(screen\renderer, sdl::#BLENDMODE_NONE)
  
  ForEach menu\items()
    If menu\items()\flag & #menu_header
      sdl::SetTextureColorMod( menu\items()\texture, $ff,$ff,$00)
    ElseIf menu\items()\callback = #Null
      sdl::SetTextureColorMod( menu\items()\texture, $b0,$b0,$b0)
    ElseIf menu\items()\flag & #menu_highlight
      sdl::SetTextureColorMod( menu\items()\texture, $ff,$00,$00)
    Else
      sdl::SetTextureColorMod( menu\items()\texture, $ff,$ff,$ff)
    EndIf
      
    sdl::RenderCopy(screen\renderer, menu\items()\texture, #Null, menu\items()\pos)
  Next
EndProcedure
    
;- Timer
Structure sTimer
  startTime.q
  lastCallDifference.q
EndStructure

Procedure.q timer_GetElapsed(*timer.sTimer)
  Protected.q difStart,dif
  
  If *timer\startTime = 0
    *timer\startTime = ElapsedMilliseconds()
    *timer\lastCallDifference = 0
  EndIf
  
  difStart = ElapsedMilliseconds() - *timer\startTime
  dif = difStart - *timer\lastCallDifference
  *timer\lastCallDifference = difStart
  
  ; don't skip to many frames! 
  If dif > 40 
    dif = 40
  EndIf 
  
  ProcedureReturn dif
EndProcedure

;- screen
Procedure.l UpdateScreenScale()
  SDL::GetRendererOutputSize(screen\renderer, @screen\ScreenWidth, @screen\ScreenHeight)
  screen\Flowersize = (screen\ScreenWidth + 1) / #field_width
  If screen\Flowersize * #field_height > screen\ScreenHeight
    screen\Flowersize = (screen\ScreenHeight + 1) / #field_height
  EndIf
  
  screen\FieldOffset\x = screen\Flowersize /2
  screen\FieldOffset\y = screen\Flowersize /2
  
  screen\Display\w = #field_width * screen\Flowersize + screen\FieldOffset\x
  screen\Display\h = #field_height * screen\FlowerSize + screen\FieldOffset\y
  
  screen\display\x = (screen\ScreenWidth - screen\Display\w) / 2
  screen\display\y = (screen\ScreenHeight - screen\display\h) / 2
    
  screen\FlowerSize * #RenderScale
  screen\FieldPixelWidth = screen\Display\w * #RenderScale 
  screen\FieldPixelHeight = screen\display\h * #RenderScale
   
  screen\FlowerPlace\w = screen\FlowerSize
  screen\FlowerPlace\h = screen\FlowerSize     
  
  If screen\texture
    sdl::DestroyTexture(screen\texture)
    screen\texture = #Null
  EndIf
  screen\texture = sdl::CreateTexture(screen\renderer, sdl::#PIXELFORMAT_RGBA32, SDL::#TEXTUREACCESS_TARGET,screen\FieldPixelWidth,screen\FieldPixelHeight)
  
  If #RenderScale > 1
    sdl::SetTextureScaleMode( screen\texture, sdl::#ScaleModeLinear)
  Else
    sdl::SetTextureScaleMode( screen\texture, sdl::#ScaleModeNearest)
  EndIf
  
  
EndProcedure
Procedure Mouse_Calc()
  Protected.l dx,dy
      
  If mouse\ButtonDown
    mouse\FieldX = (mouse\StartX - screen\FieldOffset\y) / screen\FlowerSize
    mouse\fieldy = (mouse\StartY - screen\FieldOffset\y) / screen\FlowerSize
    mouse\SwapX = mouse\FieldX
    mouse\Swapy = mouse\FieldY
    mouse\moveX = 0
    mouse\moveY = 0
    mouse\Direction = #stay
    
    dx = mouse\StartX - mouse\x
    dy = mouse\starty - mouse\y
    
    If Abs(dx) > Abs(dy)
      If dx < 0
        mouse\Direction = #right
        mouse\SwapX +1
        If dx < -screen\FlowerSize
          mouse\moveX = -screen\FlowerSize
        Else
          mouse\moveX = dx
        EndIf
        
      ElseIf dx > 0
        mouse\Direction = #left
        mouse\SwapX -1
        If dx > screen\FlowerSize
          mouse\movex = screen\FlowerSize
        Else
          mouse\movex = dx
        EndIf
        
      EndIf
    Else
      
      If dy < 0
        mouse\Direction = #down
        mouse\SwapY +1
        If dy < -screen\FlowerSize
          mouse\moveY = -screen\FlowerSize
        Else
          mouse\moveY = dy
        EndIf
        
      ElseIf dy > 0
        mouse\Direction = #up
        mouse\SwapY -1        
        If dy > screen\FlowerSize
          mouse\movey = screen\FlowerSize
        Else
          mouse\movey = dy
        EndIf
      EndIf
    EndIf
    
    If Not (mouse\FieldX >= 0 And mouse\FieldX < #field_width And mouse\FieldY >= 0 And mouse\FieldY < #field_height And Field\y[mouse\FieldY]\x[mouse\FieldX]\FlowerColor > 0 ) Or
       Not (mouse\SwapX >= 0 And mouse\SwapX < #field_width And mouse\SwapY >= 0 And mouse\SwapY < #field_height And Field\y[mouse\SwapY]\x[mouse\SwapX]\FlowerColor > 0 )
      mouse\Direction = #stay
      mouse\SwapX = -1
      mouse\Swapy = -1
    EndIf
    
  Else
    mouse\Direction = #stay
    mouse\FieldX = (mouse\X - screen\FieldOffset\y) / screen\FlowerSize
    mouse\fieldy = (mouse\Y - screen\FieldOffset\y) / screen\FlowerSize
    
    mouse\SwapX = -1
    mouse\Swapy = -1
  EndIf
  
  If mouse\FieldX < 0 
    mouse\FieldX = 0
  ElseIf mouse\FieldX > #field_width - 1
    mouse\FieldX = #field_width - 1
  EndIf
  If mouse\FieldY < 0
    mouse\FieldY = 0 
  ElseIf mouse\FieldY > #field_height - 1
    mouse\FieldY = #field_height - 1
  EndIf  
  
EndProcedure

;- Fieldstuff
Procedure.l Field_ClearFlags(mask.l=-1)
  Protected.l x,y
  For x=0 To #field_width-1
    For y=0 To #field_height-1
      field\y[y]\x[x]\Flags & mask
    Next
  Next
EndProcedure

Procedure.l Field_Clear()
  Protected.l x,y
  For x=0 To #field_width-1
    For y=0 To #field_height-1
      field\y[y]\x[x]\FlowerColor = 0
      field\y[y]\x[x]\Flags = 0
    Next
  Next
EndProcedure

Procedure.l Field_AllDelete()
  Protected.l x,y
  For y=0 To #field_height-1
    For x=0 To #field_width-1
      Field\y[y]\x[x]\Flags | #Flower_delete
    Next
  Next
EndProcedure
    
Procedure.l Field_FindDelete(xmin.l =0, ymin.l =0, xmax.l = #field_width-1, ymax.l = #field_height-1)
  Protected.l x,y,count
  If xmin<0:xmin=0:EndIf
  If ymin<0:ymin=0:EndIf
  If xmax>#field_width-1:xmax=#field_width-1:EndIf
  If ymax>#field_height-1:ymax=#field_height-1:EndIf
  For y=ymin To ymax
    For x=xmin To xmax
      If field\y[y]\x[x]\FlowerColor > 0 And Not (field\y[y]\x[x]\Flags & #Flower_isDeath)
        If x < #field_width-1 And field\y[y]\x[x+1]\FlowerColor = field\y[y]\x[x]\FlowerColor And Not (field\y[y]\x[x+1]\Flags & #Flower_isDeath)
          field\y[y]\x[x+1]\Flags | #Flower_delete
          field\y[y]\x[x]\Flags | #Flower_delete
          count + 1
        EndIf
        If y< #field_height-1 And field\y[y+1]\x[x]\FlowerColor = field\y[y]\x[x]\FlowerColor And Not (field\y[y+1]\x[x]\Flags & #Flower_isDeath)
          field\y[y+1]\x[x]\Flags | #Flower_delete
          field\y[y]\x[x]\Flags | #Flower_delete
          count + 1
        EndIf
      EndIf
    Next    
  Next
  ProcedureReturn count
EndProcedure

Procedure.l Field_CountEmpty()
  Protected.l x,y,count
  For y=0 To #field_height - 1
    For x=0 To #field_width - 1
      If field\y[y]\x[x]\FlowerColor = 0
        count +1
      EndIf
    Next
  Next
  ProcedureReturn count
EndProcedure

Procedure.l Field_CountFlowers()
  Protected.l x,y,count
  For y=0 To #field_height - 1
    For x=0 To #field_width - 1
      If field\y[y]\x[x]\FlowerColor > 0 And Not (field\y[y]\x[x]\Flags & #Flower_isDeath)
        count +1
      EndIf
    Next
  Next
  ProcedureReturn count
EndProcedure

Procedure.l Field_DoDelete()
  Protected.l x,y,count
  For x=0 To #field_width-1
    For y=0 To #field_height-1
      If field\y[y]\x[x]\Flags & #Flower_delete
        count+1
        field\y[y]\x[x]\FlowerColor = 0
        field\y[y]\x[x]\Flags = 0 
      EndIf
    Next
  Next
  ProcedureReturn count
EndProcedure

Procedure.l Field_Push()
  AddElement(_fields())
  CopyStructure(Field, _fields(), sField)
EndProcedure

Procedure.l Field_Pop()
  If ListIndex(_fields()) >= 0 
    CopyStructure(_fields(), Field, sField)
    DeleteElement(_fields())
  Else
    Debug "Filed_Pop without Field_Push"
  EndIf
EndProcedure

Procedure.l field_CheckNeightbor(x.l, y.l, color.l)
  If x>0 And Field\y[y]\x[x-1]\FlowerColor = color And Not (Field\y[y]\x[x-1]\Flags & #Flower_isDeath)
    ProcedureReturn #True
  ElseIf x<#field_width-1 And Field\y[y]\x[x+1]\FlowerColor = color And Not (Field\y[y]\x[x+1]\Flags & #Flower_isDeath)
    ProcedureReturn #True
  ElseIf y>0 And Field\y[y-1]\x[x]\FlowerColor = color And Not (Field\y[y-1]\x[x]\Flags & #Flower_isDeath)
    ProcedureReturn #True
  ElseIf y<#field_height-1 And Field\y[y+1]\x[x]\FlowerColor = color And Not (Field\y[y+1]\x[x]\Flags & #Flower_isDeath)
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure.l field_CheckAnyNeightbor(x.l, y.l)
  If x>0 And Field\y[y]\x[x-1]\FlowerColor > 0 And Not (Field\y[y]\x[x-1]\Flags & #Flower_isDeath)
    ProcedureReturn #True
  ElseIf x<#field_width-1 And Field\y[y]\x[x+1]\FlowerColor > 0 And Not (Field\y[y]\x[x+1]\Flags & #Flower_isDeath)
    ProcedureReturn #True
  ElseIf y>0 And Field\y[y-1]\x[x]\FlowerColor > 0 And Not (Field\y[y-1]\x[x]\Flags & #Flower_isDeath)
    ProcedureReturn #True
  ElseIf y<#field_height-1 And Field\y[y+1]\x[x]\FlowerColor > 0 And Not (Field\y[y+1]\x[x]\Flags & #Flower_isDeath)
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure.l Flower_Swap(*Flower1.sFlower, *Flower2.sFlower)
  Protected.sFlower save
  CopyStructure(*Flower2,save, sFlower)
  CopyStructure(*Flower1,*Flower2,sFlower)
  CopyStructure(save,*Flower1,sFlower)
EndProcedure

Procedure.l Flower_SwapDirection(x.l,y.l,dir.l)
  If field\y[y]\x[x]\FlowerColor > 0 And Not (field\y[y]\x[x]\Flags & #Flower_isDeath)
    If dir = #left And x > 0 And Field\y[y]\x[x-1]\FlowerColor > 0 And Not (field\y[y]\x[x-1]\Flags & #Flower_isDeath)
      Flower_Swap( Field\y[y]\x[x], Field\y[y]\x[x-1] )
      ProcedureReturn #True
    ElseIf dir = #right And x < #field_width-1 And Field\y[y]\x[x+1]\FlowerColor > 0 And Not (field\y[y]\x[x+1]\Flags & #Flower_isDeath)
      Flower_Swap( field\y[y]\x[x], Field\y[y]\x[x+1] )
      ProcedureReturn #True
    ElseIf dir = #up And y > 0 And Field\y[y-1]\x[x]\FlowerColor > 0 And Not (field\y[y-1]\x[x]\Flags & #Flower_isDeath)
      Flower_Swap( Field\y[y]\x[x], Field\y[y-1]\x[x] )
      ProcedureReturn #True
    ElseIf dir = #down And y < #field_height-1 And Field\y[y+1]\x[x]\FlowerColor > 0 And Not (field\y[y+1]\x[x]\Flags & #Flower_isDeath)
      Flower_Swap( field\y[y]\x[x], field\y[y+1]\x[x] )
      ProcedureReturn #True
    EndIf
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure Flower_CheckSwapDirection(x.l,y.l,dir.l)
  Protected.l count = -1
  If Flower_SwapDirection(x,y,dir)
    count = Field_FindDelete(x-2, y-2, x+2, y+2)
    ;Field_ClearFlags(~#Flower_delete)    
    Flower_SwapDirection(x,y,dir)
  EndIf
  ProcedureReturn count
EndProcedure



Procedure Field_Draw()
  Protected.l x,y
  Protected.l mx,my,sx,sy,dx,dy,dir
  Static.sTimer timer
  Protected.q dif
  Static.d count
 
  
  dif = timer_GetElapsed(timer)
  
  ;random rotate flowers
  count + 2.0 * dif / #animation_Rate
  While count > 1.0  
    x=Random(#field_width-1)
    y=Random(#field_height-1)
    field\y[y]\x[x]\angle + 0.1
    count -1.0
  Wend
  
  screen\FlowerPlace\x = screen\FieldOffset\x
  screen\FlowerPlace\y = screen\FieldOffset\y
    
  For y=0 To #field_height -1    
    For x=0 To #field_width -1
      If mouse\Direction = #stay Or (Not (x = mouse\FieldX And y = mouse\FieldY) And Not (x = mouse\SwapX And y = mouse\SwapY))
        If field\y[y]\x[x]\FlowerColor >= 0 And field\y[y]\x[x]\FlowerColor <= #Flower_max
          
          
          If field\y[y]\x[x]\Flags & #Flower_Animation
            field\y[y]\x[x]\Animation + 2.0 * dif / #animation_Rate
            If field\y[y]\x[x]\Animation > 255.0
              field\y[y]\x[x]\Animation = 255.0
            EndIf
                          
            If field\y[y]\x[x]\Flags & #Flower_isDeath
              sdl::SetTextureColorMod(textures\Flowers( field\y[y]\x[x]\FlowerColor ), 
                                      255-field\y[y]\x[x]\Animation,
                                      255-field\y[y]\x[x]\Animation, 
                                      255-field\y[y]\x[x]\Animation)
              field\y[y]\x[x]\angle + 0.5 * dif / #animation_Rate
            EndIf
          EndIf
          
          sdl::RenderCopyEx( screen\renderer, textures\Flowers( field\y[y]\x[x]\FlowerColor ), #Null, screen\FlowerPlace,field\y[y]\x[x]\angle, #Null, #Null )
          
          If field\y[y]\x[x]\Flags & #Flower_Animation
            sdl::SetTextureColorMod(textures\Flowers( field\y[y]\x[x]\FlowerColor ), 255, 255, 255)
          EndIf
          
          ;field\y[y]\x[x]\angle + 0.1* dif / #animation_Rate
          
          
          
        EndIf
      EndIf
      screen\FlowerPlace\x + screen\FlowerSize
    Next
    screen\FlowerPlace\y + screen\FlowerSize     
    screen\FlowerPlace\x = screen\FieldOffset\x
  Next
  
  ;Draw mouse mousemovement
  If mouse\Direction <> #stay; And mx < #field_width And my >= 0 And my < #field_height
    Protected.d rotate =  360 * (-mouse\moveX - mouse\moveY ) / screen\FlowerSize
    screen\FlowerPlace\x = mouse\SwapX * screen\FlowerSize + mouse\moveX + screen\FieldOffset\x
    screen\FlowerPlace\y = mouse\SwapY * screen\FlowerSize + mouse\moveY + screen\FieldOffset\y
    sdl::RenderCopyEx( screen\renderer, textures\Flowers( field\y[mouse\SwapY]\x[mouse\SwapX]\FlowerColor ), #Null, screen\FlowerPlace, field\y[mouse\SwapY]\x[mouse\SwapX]\angle - rotate , #Null, #Null )
    
    screen\FlowerPlace\x = mouse\FieldX * screen\FlowerSize - mouse\moveX + screen\FieldOffset\x
    screen\FlowerPlace\y = mouse\FieldY * screen\FlowerSize - mouse\moveY + screen\FieldOffset\y
    sdl::RenderCopyEx( screen\renderer, textures\Flowers( field\y[mouse\FieldY]\x[mouse\FieldX]\FlowerColor ), #Null, screen\FlowerPlace, field\y[mouse\FieldY]\x[mouse\FieldX]\angle + rotate, #Null, #Null )
    
  EndIf
  
  
EndProcedure

Procedure.l Field_PlaceFlower(x.l,y.l,color.l,dir.l)
  If dir = #right
    field\y[y]\x[x]\FlowerColor = color
    field\y[y]\x[x+1]\FlowerColor = color
    field\y[y]\x[x]\angle=Random(3600)/10.0
    field\y[y]\x[x+1]\angle=Random(3600)/10.0
  Else
    field\y[y]\x[x]\FlowerColor = color
    field\y[y+1]\x[x]\FlowerColor = color
    field\y[y]\x[x]\angle=Random(3600)/10.0
    field\y[y+1]\x[x]\angle=Random(3600)/10.0    
  EndIf
EndProcedure

Procedure.l Field_SearchAddPosition(color.l, xmin.l =0 , ymin.l = 0, xmax.l = #field_width-1, ymax.l = #field_height-1)
  Protected.l x,y
  ClearList( Places() )
  For y=0 To #field_height-1 
    If y >= ymin And y <= ymax
      For x=0 To #field_width-1 Step 2
        If x >= xmin And x+1 <= xmax           
          If field\y[y]\x[x]\FlowerColor = 0 And field\y[y]\x[x+1]\FlowerColor = 0
            If (field_CheckAnyNeightbor(x,y) Or field_CheckAnyNeightbor(x+1,y)) And
               Not (field_CheckNeightbor(x,y,color) Or field_CheckNeightbor(x+1,y,color) )
              AddElement( Places() )
              Places()\x = x
              Places()\y = y
              Places()\Direction = #right
              Places()\FlowerColor = color
            EndIf                          
          EndIf
        EndIf
      Next
    EndIf
  Next
  
  For y=0 To #field_height-1 Step 2 
    If y >= ymin And y+1 <= ymax
      For x=0 To #field_width-1 
        If x >= xmin And x <= xmax           
          If field\y[y]\x[x]\FlowerColor = 0 And field\y[y+1]\x[x]\FlowerColor = 0
            If (field_CheckAnyNeightbor(x,y) Or field_CheckAnyNeightbor(x,y+1)) And
               Not (field_CheckNeightbor(x,y,color) Or field_CheckNeightbor(x,y+1,color) )
              AddElement( Places() )
              Places()\x = x
              Places()\y = y
              Places()\Direction = #down
              Places()\FlowerColor = color
            EndIf                          
          EndIf
        EndIf
      Next
    EndIf
  Next
  
  ProcedureReturn ListSize( Places() )
EndProcedure

Procedure.l Field_SearchSwap(xmin.l =0, ymin.l =0, xmax.l = #field_width-1, ymax.l = #field_height-1)
  Protected.l x,y
  If xmin<0:xmin=0:EndIf
  If ymin<0:ymin=0:EndIf
  If xmax>#field_width-1:xmax=#field_width-1:EndIf
  If ymax>#field_height-1:ymax=#field_height-1:EndIf
  ClearList( Swaps() )
  For y=ymin To ymax
    For x=xmin To xmax
      If Flower_CheckSwapDirection(x,y,#right) = 0
        AddElement( Swaps() )
        Swaps()\x = x
        Swaps()\y = y
        Swaps()\Direction = #right
      EndIf
      If Flower_CheckSwapDirection(x,y,#down) = 0
        AddElement( Swaps() )
        Swaps()\x = x
        Swaps()\y = y
        Swaps()\Direction = #down
      EndIf
    Next
  Next
  ProcedureReturn ListSize( swaps() )
EndProcedure
Procedure.l field_PlaceRandomFlower(Flower.l,nx.l=-10,ny.l=-10)
  Protected.l count,a,scount,i
  
  count = Field_SearchAddPosition(Flower);,0,(#field_height /2),#field_width-1,(#field_height /2))
                                            ;Debug "i:"+i+" c:"+count+" s:"+Flower
  Repeat
    If count > 0 
      ; Select a random place and set Flower
      a=Random(count-1)        
      SelectElement( Places(), a )
      ;Debug ">>"+a+": "+ places()\x+"x"+Places()\y+" c:"+places()\FlowerColor+" d:"+places()\Direction
      
      ;Debug " "+Places()\x+"x"+places()\y+" "+nx+"x"+ny+" "+Str(places()\x-nx) +"x"+Str(places()\y-ny)
      
      If places()\x-nx >-5 And places()\x-nx <5 And
         places()\y-ny >-5 And places()\y-ny <5
        ;near mouse cursor
        count - 1
        DeleteElement( places() )
      Else
        
        Field_PlaceFlower( places()\x, Places()\y, Places()\FlowerColor, places()\Direction)
        ; Search for shuffel
        scount = Field_SearchSwap(places()\x-2, Places()\y-2,places()\x+2, Places()\y+2)
        If scount > 0
          a=Random(scount-1)
          SelectElement( Swaps(), a )
          ;Debug ">> SWAP "+ Swaps()\x+"x"+Swaps()\y+" d:"+Swaps()\Direction
          Flower_SwapDirection( Swaps()\x, Swaps()\y, Swaps()\Direction)    
          
          For i=1 To 2
            scount = Field_SearchSwap(places()\x-2, Places()\y-2,places()\x+2, Places()\y+2)
            If scount > 0
              a=Random(scount-1)
              SelectElement( Swaps(), a )
              ;Debug ">> SWAP "+ Swaps()\x+"x"+Swaps()\y+" d:"+Swaps()\Direction
              Flower_SwapDirection( Swaps()\x, Swaps()\y, Swaps()\Direction)
            Else 
              Break
            EndIf
          Next
          
          
          ProcedureReturn #True
        Else
          ; can't swap - so can't place the Flower here!
          ;Debug ">> Redirect, can't swap!"
          Field_PlaceFlower( places()\x, Places()\y, 0, places()\Direction)
          DeleteElement( places() )
          count -1
        EndIf
        
      EndIf
      
      
    Else
      ProcedureReturn #False
    EndIf
  ForEver
  
EndProcedure
Procedure Field_Init(maxFlower.l,AddFlower.l,Shuffle.l)
  Protected.l x,y,a,scount
  Protected.l Flower,error
  
  Field_Clear() 
  
  x = (#field_width /2) & (~1) ; only even fields
  y = (#field_height /2)       ; & (~1); only even fields
  
  Flower=1
  Field_PlaceFlower(x,y,Flower,#right)
  
  Repeat
    If AddFlower>0
      
      Flower = (Flower % maxFlower) +1
      
      If field_PlaceRandomFlower(flower)
        AddFlower - 1
        error = 0
      Else
        error+1
        If error>maxFlower
          If maxFlower < #Flower_max
            maxFlower+1          
            flower = maxFlower
          Else
            AddFlower = 0
          EndIf
        EndIf
      EndIf
      
      
    ElseIf Shuffle > 0
      scount = Field_SearchSwap()
      If scount > 0
        a=Random(scount-1)
        SelectElement( Swaps(), a )
        ;Debug ">> SWAP "+ Swaps()\x+"x"+Swaps()\y+" d:"+Swaps()\Direction
        Flower_SwapDirection( Swaps()\x, Swaps()\y, Swaps()\Direction)     
      Else
        Debug "CAN'T Shuffle"
        shuffle = 1
      EndIf
      Shuffle -1
    Else
      Break
    EndIf
  ForEver 
EndProcedure

Procedure.l Field_CheckSolveable()
  Protected.l conid,x,y,c,cc
  Static Dim translate(#ConId_Max)
  Static Dim count(#ConId_max,#Flower_max)
  
  ;Reset counter and translate-array
  For x = 0 To #ConId_Max
    translate(x)=x
    For y=0 To #Flower_max 
      count(x,y)=0
    Next
  Next
  
  ; Reset conid in field
  For y=0 To #field_height -1
    For x=0 To #field_width -1
      field\y[y]\x[x]\ConId = 0
    Next
  Next
  
  ; find connected Flowers and set a conid
  For y=0 To #field_height -1
    For x=0 To #field_width -1
      If field\y[y]\x[x]\FlowerColor > 0 And Not (field\y[y]\x[x]\Flags & #Flower_isDeath)
        If field\y[y]\x[x]\ConId = 0
          conid +1 
          field\y[y]\x[x]\ConId = ConId
        EndIf
        c = translate(field\y[y]\x[x]\ConId)
        
        If x<#field_width-1 And field\y[y]\x[x+1]\FlowerColor > 0 And Not (field\y[y]\x[x+1]\Flags & #Flower_isDeath)
          cc = translate(field\y[y]\x[x+1]\ConId)
          If cc = 0
            field\y[y]\x[x+1]\ConId = c
            
          ElseIf cc < c
            translate(c) = cc
            
          ElseIf cc > c
            translate(cc) = c
            
          EndIf
        EndIf
        If y<#field_height-1 And field\y[y+1]\x[x]\FlowerColor > 0 And Not (field\y[y+1]\x[x]\Flags & #Flower_isDeath)
          cc = field\y[y+1]\x[x]\ConId
          If cc = translate(0)
            field\y[y+1]\x[x]\ConId = c
            
          ElseIf cc < c
            translate(c) = cc
            
          ElseIf cc > c
            translate(cc) = c
            
          EndIf
        EndIf
      EndIf
    Next
  Next
  
  ; optimize translate
  For x=1 To conid
    y = translate(x)
    While translate(y)<>y
      y=translate(y)
    Wend      
    translate(x)=y    
  Next  
  
  ; count Flower-types for conids
  For y=0 To #field_height-1
    For x=0 To #field_width-1
      count( translate(field\y[y]\x[x]\ConId), field\y[y]\x[x]\FlowerColor) +1
    Next
  Next
  
  ; check, if in a block is an uniqe Flower
  Protected.l ret = #True
  For x=1 To conid
    count(x,0)=#False
    For y=1 To #Flower_max
      If count(x,y) = 1
        ret = #False
        count(x,0)=#True
        Break
      EndIf
    Next
  Next
  
  ;set deleteflag to unsolvable parts
  For y=0 To #field_height-1
    For x=0 To #field_width-1
      If translate(field\y[y]\x[x]\ConId) > 0 And count ( translate(field\y[y]\x[x]\ConId) ,0)
        field\y[y]\x[x]\Flags | #Flower_loose
      Else
        field\y[y]\x[x]\Flags & ~#Flower_loose
      EndIf
    Next
  Next
  
  ProcedureReturn ret
EndProcedure

Procedure Animation_AddDelete()
  Protected.l x.l,y.l
  For y=0 To #field_height-1
    For x=0 To #field_width-1
      If Field\y[y]\x[x]\Flags & #Flower_delete
        AddElement( Animation() )
        animation()\x = (x * screen\FlowerSize + screen\FieldOffset\x) / screen\FieldPixelWidth 
        animation()\y = (y * screen\FlowerSize + screen\FieldOffset\y) / screen\FieldPixelHeight 

        animation()\Angle = field\y[y]\x[x]\angle
        
        animation()\dx = ((Random(30)-15) /10.0) /(32*#field_width)
        animation()\dy =  (Random(15) / 10.0 +2) /(32*#field_height)
        animation()\dAngle= (Random(30)-15) 
        animation()\gravitation = 0.5/(32*#field_height)
        animation()\texture = textures\Flowers( Field\y[y]\x[x]\FlowerColor )
      EndIf
    Next
  Next  
EndProcedure



Procedure DoAnimation()
  Static.q timer.sTimer
  Protected.l w,h,x,y
  Protected.sdl::FRect pos
  Protected.q dif
  dif=timer_GetElapsed(timer)
  
  pos\w = screen\FlowerSize
  pos\h = screen\FlowerSize
  
  ForEach Animation()
    pos\x = Animation()\x * screen\FieldPixelWidth
    pos\y = animation()\y * screen\FieldPixelHeight
    
    SDL::RenderCopyExF( screen\renderer, animation()\texture, #Null, pos, animation()\Angle, #Null,#Null)
    animation()\dy + animation()\gravitation * dif / #animation_Rate
    animation()\x + animation()\dx * dif / #animation_Rate
    animation()\y + animation()\dy * dif / #animation_Rate
    animation()\Angle + animation()\dAngle * dif / #animation_Rate
    
    If pos\x < - screen\FlowerSize*2 Or pos\x > screen\FieldPixelWidth + screen\FlowerSize*2 Or
       pos\y < - screen\FlowerSize*2 Or pos\y > screen\FieldPixelHeight + screen\FlowerSize*2
      DeleteElement(Animation())
      ;Debug "removed"
    EndIf
  Next
  
  
EndProcedure

;- Texture-Managment

; load a texture and store the id in the list
Procedure.i LoadTex( *renderer.SDL::Renderer, path.s, Colorkey.l=-1, ScaleMode.l = sdl::#ScaleModeBest )
  Protected.SDL::Surface *loaded
  Protected.SDL::Texture *ret
  
  If Colorkey <> -1
    *loaded = SDL::IMG_Load( path )
    If Not *loaded
      Debug "Can't load "+path
      ProcedureReturn #Null
    EndIf
    
    If Colorkey<>-1
      SDL::SetColorKey( *loaded, #True, SDL::MapRGB( *loaded\format, Red(Colorkey), Green(Colorkey), Blue(Colorkey) ) )
    EndIf
    
    *ret = SDL::CreateTextureFromSurface(*renderer, *loaded)  
    SDL::FreeSurface(*loaded)
  Else
    *ret = sdl::IMG_LoadTexture(*renderer, path)
  EndIf
        
  If *ret
    AddElement(*_textures())
    *_textures() = *ret
  EndIf
  sdl::SetTextureScaleMode( *ret, ScaleMode)
  
  
  
  
  ProcedureReturn *ret
EndProcedure

; remove a texture from the list and free it
Procedure FreeTex(*texture.SDL::Texture)
  ForEach *_textures()
    If *_textures() = *texture
      DeleteElement( *_textures() )
      Break
    EndIf
  Next
  SDL::DestroyTexture( *texture )
EndProcedure

; free all textures stored in the list and clear the list
Procedure FreeTexs()
  ForEach *_textures()
    SDL::DestroyTexture( *_textures() )
  Next
  ClearList( *_textures())
EndProcedure

Procedure.l LoadMedia()
  Protected.l i, ret=#True
  For i=1 To #Flower_max 
    textures\Flowers(i) = LoadTex( screen\renderer, "./Flower" + i +".png",-1,sdl::#ScaleModeBest )
    If Not textures\Flowers(i)
      ret = #False
    EndIf
  Next
  
  Textures\background = LoadTex( screen\renderer, "./background.png",-1,sdl::#ScaleModeBest)
  If Not textures\background
    ret = #False
  EndIf
  
  *TextFont = sdl::TTF_OpenFont("./aAsalkan.ttf",160 * screen\scale)
  If Not *TextFont 
    ret = #False
  EndIf
  
  ;sdl::TTF_SetFontStyle( *TextFont, sdl::#TTF_STYLE_BOLD )
  
  ProcedureReturn ret
EndProcedure

;- Init & Quit

Procedure Quit()
  freeTexs()
  
  menu_Clear()
  
  If *TextFont
    sdl::TTF_CloseFont(*TextFont)
    *TextFont = #Null
  EndIf
  
  If screen\renderer
    sdl::DestroyRenderer( screen\renderer ) : screen\renderer = #Null
  EndIf
  
  If screen\window
    sdl::DestroyWindow(screen\window) : screen\window = #Null
  EndIf
    
  CompilerIf Defined(SDL_Config::UseTTF, #PB_Constant)
    SDL::TTF_Quit()
  CompilerEndIf
  
  CompilerIf Defined(SDL_Config::UseImage, #PB_Constant)
    SDL::IMG_Quit()
  CompilerEndIf
    
  SDL::Quit()
EndProcedure

Procedure.l Init(sdl_init.l, sdl_image_init.l = #Null)
  ; Init SDL
  If SDL::Init( sdl_init) <0
    MessageRequester(#TITLE,"SDL could not initialize! SDL_Error: "+ SDL::GetError() )
    ProcedureReturn #False
  EndIf
  
  ; Init SDL-Image
  CompilerIf Defined(SDL_Config::UseImage, #PB_Constant)
    If (SDL::IMG_Init( sdl_image_init ) & sdl_image_init) <> sdl_image_init      
      MessageRequester(#TITLE,"SDL-Image could not initialize! SDL_Error: "+ SDL::IMG_GetError() )
      SDL::Quit()
      ProcedureReturn #False
    EndIf
  CompilerEndIf
  
  CompilerIf Defined(SDL_Config::UseTTF, #PB_Constant)
    If SDL::TTF_Init() <0
      MessageRequester(#TITLE,"SDL-TTF could not initialize! SDL_Error: "+ sdl::TTF_GetError() )
      sdl::Quit()
      ProcedureReturn #False
    EndIf
  CompilerEndIf
  
  ; Get Scale-Factor
  sdl::GetDisplayDPI(0,@screen\scale,#Null,#Null)
  screen\scale / 96.0  
  
  ; Create a window, centred and visible  
  screen\window = SDL::CreateWindow( #TITLE, SDL::#WINDOWPOS_CENTERED, SDL::#WINDOWPOS_CENTERED, #BASESCREEN_WIDTH * screen\scale, #BASESCREEN_HEIGHT * screen\scale, SDL::#WINDOW_ALLOW_HIGHDPI | SDL::#WINDOW_RESIZABLE  )
  If Not screen\window 
    MessageRequester(#TITLE,"SDL could not open a window! SDL_Error: "+ sdl::GetError() )
    Quit()
    ProcedureReturn #False
  EndIf
  
  
  ; We create a renderer for the window
  screen\renderer = SDL::CreateRenderer( screen\window, -1, SDL::#RENDERER_ACCELERATED| sdl::#RENDERER_PRESENTVSYNC ) ; -1 means use a renderer which fit the flags.
  If Not screen\renderer
    MessageRequester(#Title,"SDL could not open a renderer! SDL_Error: "+ SDL::GetError() )
    Quit()
    ProcedureReturn #False
  EndIf
  UpdateScreenScale()
  
  ; load Textures
  If Not LoadMedia()
    MessageRequester(#TITLE, "Could not load Textures!")
    Quit()
    ProcedureReturn #False
  EndIf
  
  
  ProcedureReturn #True
EndProcedure

;- game

Procedure game_init()
  Select GameControl\GameRule
    Case #Endless    
      GameControl\DoGame = #True
      GameControl\count = 0
      GameControl\rate = 1.0 /(1000.0 * 5)
      GameControl\count2 = 0
      GameControl\rate2 = 1.0 /(1000.0 * 5)
      GameControl\maxFlower = 5
      GameControl\Flower = 0
      Field_Clear()
      field_init(5,10,10)
  EndSelect
  
EndProcedure

Procedure game_exit()
  Select GameControl\GameRule
    Case #Endless  
      
  EndSelect
  
EndProcedure

Procedure game_do()
  Static.sTimer timer
  Protected.q dif
  
  dif = timer_GetElapsed(timer)
  
  If GameControl\DoGame
    Select GameControl\GameRule
      Case #Endless    
        GameControl\count + GameControl\rate * dif
                
        While GameControl\count > 1.0 
          GameControl\Flower = (GameControl\Flower % GameControl\maxFlower) +1
          If field_PlaceRandomFlower( GameControl\Flower, mouse\FieldX, mouse\Fieldy)
            GameControl\count - 1.0
          Else
            Break
          EndIf          
        Wend
        
        GameControl\count2 + GameControl\rate2 * dif
        
        While GameControl\count2 > 1.0
          GameControl\count2 - 1.0
          GameControl\rate + (1.0 / (1000.0 * 6))
          ;Debug "speed up"
        Wend
        
    EndSelect
  EndIf
  
EndProcedure

Procedure game_click()
  Protected.l x,y
  If GameControl\DoGame
    If mouse\Direction <> #stay            
      If mouse\moveX > screen\FlowerSize/2 Or mouse\moveX < -screen\FlowerSize/2 Or
         mouse\moveY > screen\FlowerSize/2 Or mouse\moveY < -screen\FlowerSize/2
        Field_Push()              
        Flower_SwapDirection( mouse\FieldX, mouse\FieldY, mouse\Direction)
        Field_ClearFlags(~#Flower_delete)
        Field_FindDelete()
        Animation_AddDelete()
        Field_DoDelete()
        
        If Field_CheckSolveable()
          Select GameControl\GameRule 
            Case #Endless
              
          EndSelect
          
        Else
          ;Field_AllDelete()
          ;Animation_AddDelete()
          ;Field_DoDelete()
          ;GameControl\DoGame = #False
          For y=0 To #field_height -1
            For x=0 To #field_width -1
              If field\y[y]\x[x]\Flags & #Flower_loose
                field\y[y]\x[x]\Flags | #Flower_isDeath
              EndIf
            Next
          Next
        EndIf
        
      EndIf
    EndIf          
  EndIf
EndProcedure

;- menu

Procedure do_quit(*value)
  GameControl\Quit = #True
  GameControl\DoMenu = #False
  menu_Clear()
EndProcedure

Procedure do_start(*value) 
  GameControl\DoMenu = #False
  GameControl\GameRule = #Endless
  menu_Clear()
  game_init()
EndProcedure

Procedure do_continue(*value)
  menu_Clear()  
  GameControl\DoGame = Field_CheckSolveable()
  GameControl\DoMenu = #False
EndProcedure

Procedure do_undo(*value)
  menu_clear()
  Field_Pop()
  GameControl\DoGame = Field_CheckSolveable()
  GameControl\DoMenu = #False
EndProcedure

Procedure do_Fullscreen(force = -1)
  Static ToogleFullscreen
  If force = -1
    ToogleFullscreen = ~ToogleFullscreen
  Else
    ToogleFullscreen = Bool(force)
  EndIf
  
  If ToogleFullscreen
    sdl::SetWindowFullscreen(screen\window, sdl::#WINDOW_FULLSCREEN_DESKTOP)
  Else
    sdl::SetWindowFullscreen(screen\window, #False)
  EndIf
  UpdateScreenScale()
  menu_mouse(-1,-1,#False)
  menu_Calc()  
EndProcedure

Procedure Create_MainMenu(none=#Null)
  menu_Clear()  
  menu_AddItem(" ",10,#Null)
  menu_AddItem(#TITLE+"_",64,#Null,#Null,#menu_header)
  menu_AddItem(" ",10,#Null)
  menu_AddItem("Start",32,@do_start(),99)
  menu_AddItem("Toggle Fullscreen",32,@do_Fullscreen(),-1)
  menu_AddItem("Quit",32,@do_quit(),#Null,#menu_escape)  
  menu_Calc()
  GameControl\DoGame = #False
  GameControl\DoMenu = #True
  GameControl\GameRule = #noGame
EndProcedure

Procedure Create_PauseMenu(none=#Null)
  menu_Clear()
  menu_AddItem(" ",10,#Null)
  menu_AddItem("Pause_",64,#Null,#Null,#menu_header)
  menu_AddItem(" ",10,#Null)
  menu_AddItem("Undo",32,@do_undo(),#Null)
  menu_AddItem("Continue",32,@do_continue(), #Null, #menu_escape)
  menu_AddItem("Toggle Fullscreen",32,@do_Fullscreen(),-1)
  menu_AddItem("Main Menu",32,@Create_MainMenu())
  menu_Calc()
  GameControl\DoMenu = #True
  GameControl\DoGame = #False
EndProcedure
  



;- main
; Initalize SDL 
If Not Init(SDL::#INIT_VIDEO | SDL::#INIT_EVENTS, SDL::#IMG_INIT_PNG)
  End
EndIf


; Mainloop
Define.SDL::Event e

Field_Init(10,50,30)

Create_MainMenu()

Repeat
  
  ; Query all avaible events   
  While SDL::PollEvent( e ) <> 0 
    
    Select e\type 
      Case SDL::#QUIT        
        GameControl\Quit = #True
        
      Case SDL::#KEYDOWN    
        Select e\key\keysym\sym
          Case sdl::#K_ESCAPE
            If GameControl\DoMenu
              menu_doEscape()
              Debug "MenuEscape"
            ElseIf GameControl\GameRule > #noGame
              Create_PauseMenu()
            EndIf
            
          Case sdl::#K_RETURN, sdl::#K_RETURN2
            If e\key\keysym\mod & sdl::#KMOD_ALT
              do_Fullscreen()
            EndIf
        EndSelect
        
      Case SDL::#MOUSEMOTION
        mouse\x = (e\motion\x - screen\Display\x) * #RenderScale
        mouse\y = (e\motion\y - screen\Display\y) * #RenderScale
        ;Debug "m:"+mouse\x+" "+mouse\y
        Mouse_Calc()
        menu_mouse(e\motion\x, e\motion\y, #False)
        
      Case SDL::#MOUSEBUTTONDOWN 
        If GameControl\DoGame
          If e\button\button = sdl::#BUTTON_LEFT
            mouse\StartX = mouse\x
            mouse\StartY = mouse\y
            mouse\ButtonDown = #True
            Mouse_Calc()
          EndIf
        EndIf
        
      Case sdl::#WINDOWEVENT
        Select e\window\event 
          Case SDL::#WINDOWEVENT_LEAVE
            mouse\ButtonDown = #False
            Mouse_Calc() 
            menu_mouse(-1,-1,#False)
            
          Case sdl::#WINDOWEVENT_RESIZED
            UpdateScreenScale()
            mouse\ButtonDown = #False
            Mouse_Calc()
            menu_Calc()
            
        EndSelect
        
        
      Case SDL::#MOUSEBUTTONUP  
        If e\button\button = sdl::#BUTTON_LEFT
          
          game_click()
          
          
          mouse\ButtonDown = #False
          Mouse_Calc()
          
          If GameControl\DoMenu
            menu_mouse(e\button\x, e\button\y, #True)
          EndIf
          
        ElseIf e\button\button = sdl::#BUTTON_RIGHT
          Field_Pop()
          GameControl\DoGame = Field_CheckSolveable()
        EndIf
        
        
    EndSelect
    
  Wend
  
  Select GameControl\GameRule
    Case #Endless
      
  EndSelect
      
  game_do()
  
  sdl::SetRenderDrawColor(screen\renderer,0,$20,0,$ff)
  sdl::RenderClear( screen\renderer)
  
  sdl::SetRenderTarget(screen\renderer, screen\texture)
  
  sdl::SetRenderDrawColor(screen\renderer,$d0,$ff,$d0,$ff)
  sdl::RenderClear(screen\renderer)
  sdl::RenderCopy(screen\renderer, textures\background, #Null, #Null)
  
  
  DoAnimation()
    
  ;draw the playfield
  Field_Draw()
  
  ;draw scaled
  sdl::SetRenderTarget(screen\renderer, #Null)
  sdl::RenderCopy(screen\renderer, screen\texture, #Null, screen\Display)
  
  If GameControl\DoMenu
    menu_Draw()
  EndIf
  
  ; Update the window / Flip buffers
  SDL::RenderPresent( screen\renderer )
  ;Debug "draw"+ElapsedMilliseconds()
  ;Delay(100)
   
  
Until GameControl\Quit 

; And close SDL
Quit()

; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 7
; Folding = ------------
; EnableXP
; DPIAware