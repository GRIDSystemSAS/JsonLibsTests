@SET BDS=E:\Emb\Studio\23.0
@SET BDSINCLUDE=E:\Emb\Studio\23.0\include
@SET BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\23.0
@SET FrameworkDir=C:\Windows\Microsoft.NET\Framework\v4.0.30319
@SET FrameworkVersion=v4.5
@SET FrameworkSDKDir=
@SET PATH=%FrameworkDir%;%FrameworkSDKDir%;E:\Emb\Studio\23.0\bin;E:\Emb\Studio\23.0\bin64;E:\Emb\Studio\23.0\cmake;%PATH%
@SET LANGDIR=EN
@SET PLATFORM=
@SET PlatformSDK=

msbuild /t:build /p:config=debug .\VSoft.YAML.Tests.dproj
