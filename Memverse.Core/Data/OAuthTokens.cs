namespace MemverseApp.Core.Data;

sealed record OAuthTokens(
    string AccessToken,
    string RefreshToken);
