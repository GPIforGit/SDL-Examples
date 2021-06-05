DeclareModule SDL_Config
  #UseImage = #True
  #UseMixer = #True
  #UseTTF = #True
  #UseNet = #True
EndDeclareModule

XIncludeFile #PB_Compiler_Home + "Include/sdl2/SDL.pbi"

Define.sdl::version version
Define.sdl::version *version
Define ver
Define.s message


message = "SDL "+ sdl::#MAJOR_VERSION + "." + sdl::#MINOR_VERSION + "." + sdl::#PATCHLEVEL + #LF$

sdl::GetVersion(version)
message + "  linked version: " + version\major + "." + version\minor + "." + version\patch +" - "
ver = sdl::VERSIONNUM(version\major,version\minor,version\patch)
If ver < sdl::#COMPILEDVERSION
  message + "outdated" + #LF$ + #LF$
Else
  message + "ok" + #LF$ + #LF$
EndIf


CompilerIf Defined(SDL_Config::USEMIXER,#PB_Constant)
  message + "SDL_mixer "+ sdl::#MIX_MAJOR_VERSION + "." + sdl::#MIX_MINOR_VERSION + "." + sdl::#MIX_PATCHLEVEL + #LF$
  
  *version = sdl::Mix_Linked_Version()
  ver = sdl::VERSIONNUM(*version\major,*version\minor,*version\patch)
  message + "  linked version: " + *version\major + "." + *version\minor + "." + *version\patch +" - "
  If ver < sdl::#MIXER_COMPILEDVERSION
    message + "outdated" + #LF$ + #LF$
  Else
    message + "ok" + #LF$ + #LF$
  EndIf
CompilerEndIf

CompilerIf Defined(SDL_Config::USEIMAGE,#PB_Constant)
  message + "SDL_image "+ sdl::#IMAGE_MAJOR_VERSION + "." + sdl::#IMAGE_MINOR_VERSION + "." + sdl::#IMAGE_PATCHLEVEL + #LF$
  
  *version = sdl::Img_Linked_Version()
  ver = sdl::VERSIONNUM(*version\major,*version\minor,*version\patch)
  message + "  linked version: " + *version\major + "." + *version\minor + "." + *version\patch +" - "
  If ver < sdl::#IMAGE_COMPILEDVERSION
    message + "outdated" + #LF$ + #LF$
  Else
    message + "ok" + #LF$ + #LF$
  EndIf
CompilerEndIf

CompilerIf Defined(SDL_Config::USETTF,#PB_Constant)
  message + "SDL_image "+ sdl::#TTF_MAJOR_VERSION + "." + sdl::#TTF_MINOR_VERSION + "." + sdl::#TTF_PATCHLEVEL + #LF$
  
  *version= sdl::ttf_Linked_Version()
  ver = sdl::VERSIONNUM(*version\major,*version\minor,*version\patch)
  message + "  linked version: " + *version\major + "." + *version\minor + "." + *version\patch +" - "
  If ver < sdl::#TTF_COMPILEDVERSION
    message + "outdated" + #LF$ + #LF$
  Else
    message + "ok" + #LF$ + #LF$
  EndIf
CompilerEndIf

CompilerIf Defined(SDL_Config::USENET,#PB_Constant)
  message+ "SDL_net "+ sdl::#NET_MAJOR_VERSION + "." + sdl::#NET_MINOR_VERSION + "." + sdl::#NET_PATCHLEVEL + #LF$
  
  *version= sdl::Net_Linked_Version()
  ver = sdl::VERSIONNUM(*version\major,*version\minor,*version\patch)
  message + "  linked version: " + *version\major + "." + *version\minor + "." + *version\patch +" - "
  If ver < sdl::#NET_COMPILEDVERSION
    message + "outdated" + #LF$ + #LF$
  Else
    message + "ok" + #LF$ + #LF$
  EndIf
CompilerEndIf

MessageRequester("SDL-TestVersion",message)
; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 8
; Folding = -
; EnableXP
; DisableDebugger