;
; load a simple bitmap
;
EnableExplicit
XIncludeFile #PB_Compiler_Home + "Include/sdl2/SDL.pbi"

#SCREEN_WIDTH = 640
#SCREEN_HEIGHT = 480
#TITLE = "load a bitmap"

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

; Load a Image
Global *HelloWorld.SDL::surface
*HelloWorld = SDL::LoadBMP("./resources/HelloWorld.bmp")

If Not *HelloWorld
  MessageRequester( #TITLE, "Can't load HelloWorld.bmp")
  SDL::DestroyWindow( *window)
  SDL::Quit()
  End
EndIf

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
  
  ; Paint the Bitmap on the screen
  ; Rect #Null means fullscreen
  SDL::BlitSurface(*HelloWorld, #Null, *screenSurface, #Null)
  
  ; Update the surface - otherwise nothing is visible
  SDL::UpdateWindowSurface( *window )
  
Until exit

; Close Window
SDL::DestroyWindow( *window ) : *window = #Null

; Free Image
SDL::FreeSurface( *HelloWorld )

; And close SDL
SDL::Quit()


; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 4
; EnableXP