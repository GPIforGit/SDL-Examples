;
; convert image to window-default-surface-format and stretch to fullscreen
;

EnableExplicit
XIncludeFile #PB_Compiler_Home + "Include/sdl2/SDL.pbi"

#SCREEN_WIDTH = 640
#SCREEN_HEIGHT = 480
#TITLE = "optimize and stretch"

Procedure.i loadSurface( path.s, *format.sdl::PixelFormat )
  Global.SDL::surface *loaded, *ret
    
  *loaded = SDL::LoadBMP( path )
  If Not *loaded
    Debug "Can't load "+path
    ProcedureReturn #Null
  EndIf
  
  ; convert the surface to the format and return it as new surface
  ; in this example, the loaded bitmaps are in 8Bit color, but normaly the screen-surface should be 32bit color.
  ; the operations should be faster, when the bitmap is converted to the screen-surface.
  *ret = SDL::ConvertSurface(*loaded, *format, #Null)
  
  SDL::FreeSurface(*loaded)
  
  ProcedureReturn *ret
EndProcedure

; Initalize SDL Video
If SDL::Init( SDL::#INIT_VIDEO | SDL::#INIT_EVENTS ) < 0
  MessageRequester(#TITLE,"SDL could not initialize! SDL_Error: "+ SDL::GetError() )
  End
EndIf

; Create a window, centred and visible
Define *window.SDL::Window
*window = SDL::CreateWindow( #TITLE, SDL::#WINDOWPOS_UNDEFINED, SDL::#WINDOWPOS_UNDEFINED, #SCREEN_WIDTH, #SCREEN_HEIGHT, sdl::#WINDOW_SHOWN )
If Not *window 
  MessageRequester(#TITLE,"SDL could not open a window! SDL_Error: "+ sdl::GetError() )
  SDL::Quit()
  End
EndIf

; Get the Surface of the window to paint on it
Define *screenSurface.SDL::Surface
*screenSurface = SDL::GetWindowSurface( *window )

; Load Images
Global.SDL::surface *stretch

*stretch = loadSurface("./resources/stretch.bmp", *screenSurface\format)

If Not *stretch
  MessageRequester( #TITLE, "Can't load bitmaps")
  SDL::DestroyWindow( *window)
  SDL::Quit()
  End
EndIf

; we need a destination rect

Define fullrect.SDL::Rect

fullrect\x = 0
fullrect\y = 0
fullrect\w = #SCREEN_WIDTH
fullrect\h = #SCREEN_HEIGHT


; Mainloop
Define exit.l = #False
Define e.SDL::Event

Repeat
  
  ; Query all avaible events   
  While SDL::PollEvent( e ) <> 0 
    
    Select e\type 
      Case SDL::#QUIT        
        exit = #True
        
      Case SDL::#KEYDOWN    
        Select e\key\keysym\sym
          Case sdl::#K_ESCAPE
            exit = #True
        EndSelect
        
    EndSelect
    
    
  Wend
  
  ; Paint the Bitmap on the screen
  ; instead of fullrect #null should work too
  SDL::BlitScaled(*stretch, #Null, *screenSurface, fullrect)
  
  ; Update the surface - otherwise nothing is visible
  SDL::UpdateWindowSurface( *window )
  
Until exit

; Close Window
SDL::DestroyWindow( *window ) : *window = #Null

; Free Image
SDL::FreeSurface( *stretch )

; And close SDL
SDL::Quit()


; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 5
; Folding = -
; EnableXP