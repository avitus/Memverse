using MemverseApp.Core;

namespace MemverseApp.Pwa.Services;

static class UserSetup
{
    public static string? GetRequiredRoute(UserSetupDestination destination) =>
        destination switch
        {
            UserSetupDestination.SignIn => "login",
            UserSetupDestination.ChooseTranslation => "settings",
            UserSetupDestination.AddVerses => "add",
            UserSetupDestination.Complete => null,
            _ => throw new ArgumentOutOfRangeException(nameof(destination))
        };

    public static string GetLandingRoute(UserSetupDestination destination) =>
        GetRequiredRoute(destination) ?? "";
}
