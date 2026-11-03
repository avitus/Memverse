using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Components;

namespace MemverseApp.Pwa.Services;

sealed class PkceAuthenticationService(
    BrowserDatabase database,
    NavigationManager navigation,
    IOnlineOperations online)
{
    public async Task BeginSignInAsync()
    {
        var verifier = MemverseOAuth.CreateRandomValue(64);
        var state = MemverseOAuth.CreateRandomValue(32);
        await database.SavePendingSignInAsync(state, verifier);

        var authorizationUrl = MemverseOAuth.CreateAuthorizationUrl(
            GetRedirectUri(), state, verifier);
        navigation.NavigateTo(authorizationUrl, forceLoad: true);
    }

    public async Task CompleteSignInAsync(string code, string state)
    {
        var pending = await database.TakePendingSignInAsync();

        if (pending is null ||
            string.IsNullOrWhiteSpace(pending.State) ||
            string.IsNullOrWhiteSpace(pending.Verifier) ||
            !CryptographicOperations.FixedTimeEquals(
                Encoding.UTF8.GetBytes(pending.State),
                Encoding.UTF8.GetBytes(state)))
        {
            throw new InvalidOperationException(
                "The sign-in response could not be verified. Start sign-in again.");
        }

        await online.SignInAsync(code, pending.Verifier, GetRedirectUri());
    }

    private string GetRedirectUri() =>
        new Uri(
            new Uri(navigation.BaseUri),
            "authentication/login-callback").AbsoluteUri;
}
