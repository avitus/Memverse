# Memverse PWA

A Blazor WebAssembly progressive web app for memorizing Bible verses with
[Memverse](https://www.memverse.com/).

## Run locally

Install the .NET 10 SDK, then run:

```powershell
dotnet run --project .\Memverse.Pwa\Memverse.Pwa.csproj
```

Open the local URL printed by the application.

## GitHub Pages

The deployment workflow publishes the app to
<https://avitus.github.io/Memverse/> with the `/Memverse/` base path and a
`404.html` fallback for direct links.
