using MemverseApp.Core.Data;

namespace MemverseApp.Core;

interface IMemverseClient : IMemverseApiClient, IMemverseMutationClient
{
    Task<OAuthTokens> ExchangeAuthorizationCodeAsync(
        string code,
        string codeVerifier,
        string redirectUri,
        CancellationToken cancellationToken = default);
    void SetAccessToken(string accessToken);
    Task<IReadOnlyList<Verse>> GetChapterAsync(
        string translation, string book, int chapter);
}

interface IMemverseMutationClient
{
    Task DeleteMemverseAsync(
        long id,
        string accessToken,
        CancellationToken cancellationToken = default);
    Task RateMemverseAsync(
        long id,
        int rating,
        string accessToken,
        CancellationToken cancellationToken = default);
    Task UpdateUserAsync(
        User user,
        string accessToken,
        CancellationToken cancellationToken = default);
}
