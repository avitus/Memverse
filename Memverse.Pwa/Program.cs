using Microsoft.AspNetCore.Components.Web;
using Microsoft.AspNetCore.Components.WebAssembly.Hosting;
using MemverseApp.Pwa;
using MemverseApp.Pwa.Services;
using MemverseApp;
using MemverseApp.Core.WebApi;

var builder = WebAssemblyHostBuilder.CreateDefault(args);
builder.RootComponents.Add<App>("#app");
builder.RootComponents.Add<HeadOutlet>("head::after");

builder.Services.AddScoped(sp => new HttpClient
{
    BaseAddress = new Uri("https://www.memverse.com/api/v1/")
});
builder.Services.AddScoped<BrowserDatabase>();
builder.Services.AddScoped<IDatabase>(
    services => services.GetRequiredService<BrowserDatabase>());
builder.Services.AddScoped<MemverseState>();
builder.Services.AddScoped<MemverseApiClient>();
builder.Services.AddScoped<IMemverseApiClient>(
    services => services.GetRequiredService<MemverseApiClient>());
builder.Services.AddScoped<IMemverseClient>(
    services => services.GetRequiredService<MemverseApiClient>());
builder.Services.AddScoped<IMemverseMutationClient>(
    services => services.GetRequiredService<MemverseApiClient>());
builder.Services.AddScoped<BackgroundSynchronizer>();
builder.Services.AddScoped<PkceAuthenticationService>();
builder.Services.AddScoped<IOfflineOperations, OfflineClient>();
builder.Services.AddScoped<IOnlineOperations, OnlineOperations>();
builder.Services.AddSingleton(DefaultTelemetry.Instance);

await builder.Build().RunAsync();
