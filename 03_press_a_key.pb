;
; Handle basic keyboard-input
;

EnableExplicit
XIncludeFile #PB_Compiler_Home + "Include/sdl2/SDL.pbi"

#SCREEN_WIDTH = 640
#SCREEN_HEIGHT = 480
#TITLE = "press a key"

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
Global.SDL::surface *up, *down, *left, *right, *info, *display
*up = SDL::LoadBMP("./resources/up.bmp")
*down = SDL::LoadBMP("./resources/down.bmp")
*left = SDL::LoadBMP("./resources/left.bmp")
*right = SDL::LoadBMP("./resources/right.bmp")
*info = SDL::LoadBMP("./resources/presskey.bmp")

If Not *up Or Not *down Or Not *left Or Not *right Or Not *info
  MessageRequester( #TITLE, "Can't load bitmaps")
  SDL::DestroyWindow( *window)
  SDL::Quit()
  End
EndIf

; Mainloop
Define exit.l = #False
Define e.SDL::Event

*display = *info

Repeat
  
  ; Query all avaible events   
  While SDL::PollEvent( e ) <> 0 
    
    Select e\type 
      Case SDL::#QUIT ; System required a program close        
        exit = #True
        
      Case SDL::#KEYDOWN ; a key is pressed
        Select e\key\keysym\sym
          Case sdl::#K_UP
            *display = *up
            
          Case sdl::#K_DOWN
            *display = *down
            
          Case sdl::#K_RIGHT
            *display = *right
            
          Case sdl::#K_LEFT
            *display = *left
            
          Case sdl::#K_ESCAPE
            exit = #True
            
          Default
            *display = *info
        EndSelect
        
    EndSelect
    
    
  Wend
  
  ; Paint the Bitmap on the screen
  ; Rect #Null means Fullscreen
  SDL::BlitSurface(*display, #Null, *screenSurface, #Null)
  
  ; Update the surface - otherwise nothing is visible
  SDL::UpdateWindowSurface( *window )
  
Until exit

; Close Window
SDL::DestroyWindow( *window ) : *window = #Null

; Free Image
SDL::FreeSurface( *up )
SDL::FreeSurface( *down )
SDL::FreeSurface( *left )
SDL::FreeSurface( *right )
SDL::FreeSurface( *info )

; And close SDL
SDL::Quit()


; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 64
; FirstLine = 61
; EnableXP