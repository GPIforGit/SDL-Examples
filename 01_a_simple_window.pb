;
; create a simple empty window with a SDL-Event-Loop
;
EnableExplicit
XIncludeFile #PB_Compiler_Home + "Include/sdl2/SDL.pbi"

#SCREEN_WIDTH = 640
#SCREEN_HEIGHT = 480
#TITLE = "A simple window"

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

; Get the color white in the coding of the surface
Define yellow = SDL::MapRGB(  *screenSurface\format, $FF, $FF, $00 )

; Mainloop
Define exit.l = #False
Define e.SDL::Event

Repeat
  ; Query all avaible events
  While SDL::PollEvent( e ) <> 0 
    
    ; Check for the Quit-Event
    If e\type = SDL::#QUIT 
      exit = #True
    EndIf
    
  Wend
  
  ; Fill the Surface yellow, rect with #null fill the complete surface
  SDL::FillRect( *screenSurface, #Null, yellow )
  
  ; Update the surface - otherwise nothing is visible
  SDL::UpdateWindowSurface( *window )
  
Until exit

; Close Window
SDL::DestroyWindow( *window ) : *window = #Null

; And close SDL
SDL::Quit()


; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 4
; EnableXP