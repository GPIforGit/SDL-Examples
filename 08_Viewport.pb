;
; Viewport
;
; Can be used for splitscreen, minimaps and so on.
; note that the internal resolution of a viewport is the same as the full screen!
;

EnableExplicit

;we need the SDL_IMG - library
DeclareModule SDL_Config
  #UseImage = #True
EndDeclareModule

XIncludeFile #PB_Compiler_Home + "Include/sdl2/SDL.pbi"

#SCREEN_WIDTH = 640
#SCREEN_HEIGHT = 480
#TITLE = "Viewport"

;- Texture-Managment
Global NewList *_textures.SDL::Texture()
; load a texture and store the id in the list
Procedure.i LoadTex( *renderer.SDL::Renderer, path.s )
  Protected.SDL::Surface *loaded
  Protected.SDL::Texture *ret
    
  *loaded = SDL::IMG_Load( path )
  If Not *loaded
    Debug "Can't load "+path
    ProcedureReturn #Null
  EndIf
  
  
  *ret = SDL::CreateTextureFromSurface(*renderer, *loaded)  
  If *ret
    AddElement(*_textures())
    *_textures() = *ret
  EndIf
  
  SDL::FreeSurface(*loaded)
  
  ProcedureReturn *ret
EndProcedure

; free all textures stored in the list and clear the list
Procedure FreeTexs()
  ForEach *_textures()
    SDL::DestroyTexture( *_textures() )
  Next
  ClearList( *_textures())
EndProcedure

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
  freeTexs()
  
  CompilerIf Defined(SDL_Config::UseImage, #PB_Constant)
    SDL::IMG_Quit()
  CompilerEndIf
  
  SDL::Quit()
EndProcedure
  
;- Main
; Initalize SDL 
If Not Init(SDL::#INIT_VIDEO | SDL::#INIT_EVENTS, SDL::#IMG_INIT_PNG)
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

;Set RenderColor
SDL::SetRenderDrawColor( *Renderer, $FF, $FF, $FF, $FF )

; Load Images
Define.SDL::Texture *tex

*tex = loadTex(*renderer, "./resources/texture.png")

If Not *tex
  MessageRequester( #TITLE, "Can't load bitmaps")
  SDL::DestroyWindow( *window)
  Quit()
  End
EndIf

; Mainloop
Define exit.l = #False
Define e.SDL::Event

; define some Viewports
Define viewportLeftTop.sdl::Rect
viewportLeftTop\x = 1
viewportLeftTop\y = 1
viewportLeftTop\w = #SCREEN_WIDTH / 2 -2
viewportLeftTop\h = #SCREEN_HEIGHT / 2 -2
  
Define viewportLeftBottom.sdl::Rect
viewportLeftBottom\x = 1
viewportLeftBottom\y = #SCREEN_HEIGHT / 2 +1
viewportLeftBottom\w = #SCREEN_WIDTH / 2 -2
viewportLeftBottom\h = #SCREEN_HEIGHT / 2 -2

Define viewportRight.sdl::Rect
viewportRight\x = #SCREEN_WIDTH / 2 +1
viewportRight\y = 1
viewportRight\w = #SCREEN_WIDTH / 2 -2
viewportRight\h = #SCREEN_HEIGHT -2

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
  
  ; Reset Viewport
  SDL::RenderSetViewport( *renderer, #Null )
  
  ; Clear the renderer
  SDL::RenderClear( *Renderer )
  
  
  ; Display the Texture
  SDL::RenderSetViewport( *renderer, viewportLeftTop )
  SDL::RenderCopy( *Renderer, *Tex, #Null, #Null )
  
  SDL::RenderSetViewport( *renderer, viewportLeftBottom )
  SDL::RenderCopy( *Renderer, *Tex, #Null, #Null )
  
  SDL::RenderSetViewport( *renderer, viewportRight )
  SDL::RenderCopy( *Renderer, *Tex, #Null, #Null )  
   
  ; Update the window / Flip buffers
  SDL::RenderPresent( *Renderer )
  
Until exit

; Free Image
FreeTexs()

; Destroy Renderer
SDL::DestroyRenderer( *renderer ) : *renderer = #Null

; Close Window
SDL::DestroyWindow( *window ) : *window = #Null


; And close SDL
Quit()
; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 14
; Folding = --
; EnableXP