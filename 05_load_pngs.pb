;
; Load a png picture using sdl_image
;

EnableExplicit

;we need the SDL_IMG - library
DeclareModule SDL_Config
  #UseImage = #True
EndDeclareModule

XIncludeFile #PB_Compiler_Home + "Include/sdl2/SDL.pbi"

#SCREEN_WIDTH = 640
#SCREEN_HEIGHT = 480
#TITLE = "load png"

;- Surface-Managment
Global NewList *_surfaces.SDL::Surface()
; load a surface and store the id in the list
Procedure.i loadSurface( path.s, *format.sdl::PixelFormat )
  Protected.SDL::surface *loaded, *ret
    
  *loaded = SDL::IMG_Load( path )
  If Not *loaded
    Debug "Can't load "+path
    ProcedureReturn #Null
  EndIf
  
  ; convert the surface to the format and return it as new surface
  ; in this example, the loaded bitmaps are in 8Bit color, but normaly the screen-surface should be 32bit color.
  ; the operations should be faster, when the bitmap is converted to the screen-surface.
  *ret = SDL::ConvertSurface(*loaded, *format, #Null)
  
  ; save the surface for easy all in one freeing
  If *ret
    AddElement(*_surfaces())
    *_surfaces() = *ret
  EndIf
  
  SDL::FreeSurface(*loaded)
  
  ProcedureReturn *ret
EndProcedure

; free all surfaces stored in the list and clear the list
Procedure FreeSurfaces()
  ForEach *_surfaces()
    SDL::FreeSurface( *_surfaces() )
  Next
  ClearList( *_surfaces())
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
  freeSurfaces()
  
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

; Get the Surface of the window to paint on it
Define *screenSurface.SDL::Surface
*screenSurface = SDL::GetWindowSurface( *window )

; Load Images
Define.SDL::surface *surface
*surface = loadSurface("./resources/png.png", *screenSurface\format)

If Not *surface
  MessageRequester( #TITLE, "Can't load bitmaps")
  SDL::DestroyWindow( *window)
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
  
  ; Paint the Bitmap on the screen
  ; Rect #Null means Fullscreen
  SDL::BlitSurface(*surface, #Null, *screenSurface, #Null)
  
  ; Update the surface - otherwise nothing is visible
  SDL::UpdateWindowSurface( *window )
  
Until exit

; Close Window
SDL::DestroyWindow( *window ) : *window = #Null

; Free Image
freeSurfaces()

; And close SDL
Quit()
; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 11
; Folding = --
; EnableXP