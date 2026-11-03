using MemverseApp.Core;
using MemverseApp.Core.Data;

namespace MemverseApp.Core.Services;

sealed class OnlineOperations(
    MemverseState state,
    IMemverseClient client,
    BackgroundSynchronizer synchronizer,
    ITelemetryService telemetry) : IOnlineOperations
{
    public string? LastError => synchronizer.LastError;

    public async Task SignInAsync(
        string code,
        string codeVerifier,
        string redirectUri)
    {
        OAuthTokens tokens;
        using (telemetry.TrackRequest("MemversePkceLogin"))
            tokens = await client.ExchangeAuthorizationCodeAsync(
                code, codeVerifier, redirectUri);
        var profile = await client.GetIdentityAsync();
        var verses = await client.GetMemversesAsync();
        await state.SignInAsync(tokens, profile);
        await state.SaveVersesAsync(verses);
    }

    public Task FlushBackgroundTasksAsync() => synchronizer.SyncAsync();

    public async Task<Memverse> AddMemverseAsync(Verse verse)
    {
        var added = await client.AddMemverseAsync(verse);
        state.Verses.Add(added);
        await state.SaveVersesAsync(state.Verses);
        return added;
    }

    public Task<Verse> GetVerseAsync(long id) =>
        client.GetVerseAsync(id);

    public Task<Verse> GetVerseAsync(int book, int chapter, int verse) =>
        client.GetVerseAsync(book, chapter, verse);

    public Task<IReadOnlyList<Verse>> GetChapterAsync(
        string translation,
        string book,
        int chapter) =>
        client.GetChapterAsync(translation, book, chapter);

    public async Task<IReadOnlyList<Language>> GetAvailableTranslationsAsync() =>
        await client.GetAvailableTranslationsAsync();
}
