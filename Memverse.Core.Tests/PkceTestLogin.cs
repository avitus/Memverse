using System.Net;
using System.Text.RegularExpressions;
using Xunit;

namespace MemverseApp.Core.Tests;

static class PkceTestLogin
{
    public static async Task<string> GetAccessTokenAsync()
    {
        const string redirectUri = "http://localhost:5078/authentication/login-callback";
        var verifier = MemverseOAuth.CreateRandomValue(64);
        var state = MemverseOAuth.CreateRandomValue(32);
        var authorizationUrl = MemverseOAuth.CreateAuthorizationUrl(
            redirectUri, state, verifier);
        var cookies = new CookieContainer();
        using var loginHttp = new HttpClient(new HttpClientHandler
        {
            CookieContainer = cookies
        });
        var loginPage = await loginHttp.GetStringAsync(authorizationUrl);
        var csrfToken = WebUtility.HtmlDecode(Regex.Match(
            loginPage, "name=\"authenticity_token\" value=\"([^\"]+)\"").Groups[1].Value);

        using var http = new HttpClient(new HttpClientHandler
        {
            CookieContainer = cookies,
            AllowAutoRedirect = false
        });
        using var form = new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["authenticity_token"] = csrfToken,
            ["user[email]"] = Environment.GetEnvironmentVariable("MEMVERSE_TEST_EMAIL")!,
            ["user[password]"] = Environment.GetEnvironmentVariable("MEMVERSE_TEST_PASSWORD")!
        });
        using var login = await http.PostAsync("https://www.memverse.com/users/sign_in", form);
        using var authorization = await http.GetAsync(authorizationUrl);
        var callback = authorization.Headers.Location!;
        Assert.Equal(redirectUri, callback.GetLeftPart(UriPartial.Path));
        var query = callback.Query.TrimStart('?').Split('&')
            .Select(part => part.Split('=', 2))
            .ToDictionary(
                part => WebUtility.UrlDecode(part[0]),
                part => WebUtility.UrlDecode(part[1]));
        Assert.Equal(state, query["state"]);

        var tokens = await new MemverseApiClient(http).ExchangeAuthorizationCodeAsync(
            query["code"], verifier, redirectUri);
        return tokens.AccessToken;
    }
}
