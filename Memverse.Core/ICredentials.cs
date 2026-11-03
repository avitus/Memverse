using System.Buffers.Text;
using System.Security.Cryptography;
using System.Text;

namespace MemverseApp.Core;

static class MemverseOAuth
{
    internal const string ClientId = "memverse-pwa";
    internal const string AuthorizationEndpoint =
        "https://www.memverse.com/oauth/authorize";
    internal const string TokenEndpoint =
        "https://www.memverse.com/oauth/token";
    internal const string Scope = "public read write";

    internal static string CreateRandomValue(int byteCount) =>
        Base64Url.EncodeToString(RandomNumberGenerator.GetBytes(byteCount));

    internal static string CreateAuthorizationUrl(
        string redirectUri,
        string state,
        string verifier) =>
        $"{AuthorizationEndpoint}" +
        $"?response_type=code" +
        $"&client_id={Uri.EscapeDataString(ClientId)}" +
        $"&redirect_uri={Uri.EscapeDataString(redirectUri)}" +
        $"&scope={Uri.EscapeDataString(Scope)}" +
        $"&code_challenge={Base64Url.EncodeToString(SHA256.HashData(Encoding.ASCII.GetBytes(verifier)))}" +
        $"&code_challenge_method=S256" +
        $"&state={Uri.EscapeDataString(state)}";
}
