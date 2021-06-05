;
; Textures
;
; Geometry drawing with renderer
;

EnableExplicit

XIncludeFile #PB_Compiler_Home + "Include/sdl2/SDL.pbi"

#SCREEN_WIDTH = 640
#SCREEN_HEIGHT = 480
#TITLE = "Geometry drawing with renderer"

;- Init & Quit SDL
Procedure.l Init(sdl_init.l, sdl_image_init.l = #Null)
  If SDL::Init( sdl_init) <0
    ProcedureReturn #False
  EndIf
  
  CompilerIf Defined(SDL_Config::UseImage, #PB_Constant)
    If (SDL::IMG_Init( sdl_image_init ) & sdl_image_init) <> sdl_image_init
      SDL::Quit()
      ProcedureReturn #False
    EndIf
  CompilerEndIf
    
  ProcedureReturn #True
EndProcedure
Procedure Quit()
  
  CompilerIf Defined(SDL_Config::UseImage, #PB_Constant)
    SDL::IMG_Quit()
  CompilerEndIf
  
  SDL::Quit()
EndProcedure
  
;- Main
; Initalize SDL 
If Not Init(SDL::#INIT_VIDEO | SDL::#INIT_EVENTS)
  MessageRequester(#TITLE,"SDL could not initialize! SDL_Error: "+ SDL::GetError() )
  End
EndIf

; Create a window, centred and visible
Define *window.SDL::Window
*window = SDL::CreateWindow( #TITLE, SDL::#WINDOWPOS_UNDEFINED, SDL::#WINDOWPOS_UNDEFINED, #SCREEN_WIDTH, #SCREEN_HEIGHT, sdl::#WINDOW_SHOWN )
If Not *window 
  MessageRequester(#TITLE,"SDL could not open a window! SDL_Error: "+ sdl::GetError() )
  Quit()
  End
EndIf

; We create a renderer for the window
Define *renderer.SDL::Renderer
*renderer = SDL::CreateRenderer( *Window, -1, SDL::#RENDERER_ACCELERATED  ) ; -1 means use a renderer which fit the flags.
If Not *renderer
  MessageRequester(#Title,"SDL could not open a renderer! SDL_Error: "+ SDL::GetError() )
  SDL::DestroyWindow(*window)
  Quit()
  End
EndIf

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
  
  ; Clear the renderer
  SDL::SetRenderDrawColor( *Renderer, $FF, $FF, $FF, $FF ) ; color white
  SDL::RenderClear( *Renderer )
  
  ; Draw boxes
  SDL::SetRenderDrawColor( *Renderer, $FF, $00, $00, $FF ) ; color red  
  Define box.sdl::Rect
  Define i.l
  For i=0 To #SCREEN_WIDTH/2 Step 20
    box\x=i
    box\y=i * #SCREEN_HEIGHT / #SCREEN_WIDTH
    box\w = #SCREEN_WIDTH - box\x * 2
    box\h = #SCREEN_HEIGHT - box\y * 2
    SDL::RenderDrawRect( *renderer, box)
  Next
  
  ; Draw boxes
  SDL::SetRenderDrawColor( *Renderer, $00, $FF, $00, $FF ) ; color green  
  sdl::RenderDrawLine( *renderer, 0, 0, #SCREEN_WIDTH-1, #SCREEN_HEIGHT-1)
  
  ; Update the window / Flip buffers
  SDL::RenderPresent( *Renderer )
  
Until exit

; Destroy Renderer
SDL::DestroyRenderer( *renderer ) : *renderer = #Null

; Close Window
SDL::DestroyWindow( *window ) : *window = #Null


; And close SDL
Quit()
; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 8
; Folding = -
; EnableXP