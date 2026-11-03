using MemverseApp.Core.Services;
using MemverseApp.Core.ViewModels;

namespace MemverseApp.Core.Data;

interface IOfflineOperations
{
    IReadOnlyList<Memverse> GetMemverses();
    User? GetUser();
    Task DeleteMemverseAsync(Memverse verse);
    Task RateMemverseAsync(Memverse verse, int rating);
    Task ToggleStatusAsync(Memverse verse);
    Task UpdateUserAsync(User user);
    Task AdjustWorkLoadAsync();
}

interface IOnlineOperations
{
    string? LastError { get; }
    Task SignInAsync(
        string code,
        string codeVerifier,
        string redirectUri);
    Task FlushBackgroundTasksAsync();
    Task<Memverse> AddMemverseAsync(Verse verse);
    Task<Verse> GetVerseAsync(long id);
    Task<Verse> GetVerseAsync(int book, int chapter, int verse);
    Task<IReadOnlyList<Verse>> GetChapterAsync(
        string translation,
        string book,
        int chapter);
    Task<IReadOnlyList<Language>> GetAvailableTranslationsAsync();
}

interface IDatabase
{
    Task<DatabaseSnapshot> LoadAsync();
    Task SaveUserAsync(User user);
    Task SaveTokensAsync(OAuthTokens tokens);
    Task ReplaceMemversesAsync(IEnumerable<Memverse> verses);
    Task ReplaceMemversesAndSaveMutationAsync(
        IEnumerable<Memverse> verses,
        ApiRequest request);
    Task SaveUserAndMutationAsync(User user, ApiRequest request);
    Task SaveMutationAsync(ApiRequest request);
    Task DeleteMutationAsync(int id);
    Task ClearAsync();
}

sealed record DatabaseSnapshot(
    User? User,
    string? AccessToken,
    string? RefreshToken,
    List<Memverse> Memverses,
    List<ApiRequest> Mutations);

sealed class OfflineClient(MemverseState state) : IOfflineOperations
{
    public IReadOnlyList<Memverse> GetMemverses() => state.Verses;

    public User? GetUser() => state.User;

    public async Task DeleteMemverseAsync(Memverse verse)
    {
        state.Verses.RemoveAll(candidate => candidate.Id == verse.Id);
        await state.SaveVersesAndEnqueueMutationAsync(state.Verses, new ApiRequest
        {
            Kind = ApiRequestKind.DeleteMemverse,
            Json = System.Text.Json.JsonSerializer.Serialize(new { verse.Id })
        });
    }

    public async Task RateMemverseAsync(Memverse verse, int rating)
    {
        RatingClient.RateVerse(verse, rating);
        await state.SaveVersesAndEnqueueMutationAsync(state.Verses, new ApiRequest
        {
            Kind = ApiRequestKind.RateMemverse,
            Json = System.Text.Json.JsonSerializer.Serialize(new { verse.Id, Rating = rating })
        });
    }

    public async Task ToggleStatusAsync(Memverse verse)
    {
        verse.ToggleStatus();
        await state.SaveVersesAsync(state.Verses);
    }

    public async Task UpdateUserAsync(User user)
    {
        if (state.User is null || state.User.Id != user.Id)
            return;

        state.User.Name = user.Name;
        state.User.Email = user.Email;
        state.User.Translation = user.Translation;
        state.User.TargetVersesPerDay = user.TargetVersesPerDay;
        state.User.LastActivityDate = user.LastActivityDate;
        await state.SaveUserAndEnqueueMutationAsync(new ApiRequest
        {
            Kind = ApiRequestKind.UpdateUser,
            Json = System.Text.Json.JsonSerializer.Serialize(new
            {
                state.User.Id,
                Translation = user.Translation,
                TimeAllocation = user.TargetVersesPerDay
            })
        });
    }

    public async Task AdjustWorkLoadAsync()
    {
        if (state.User is null)
            return;

        var workPerDay = state.Verses
            .Where(verse => verse.IsActive)
            .Sum(verse => 1.0 / Math.Max(1, verse.TestInterval.Days));
        var versesToAdd = (int)(state.User.TargetVersesPerDay - workPerDay);
        foreach (var verse in state.Verses
            .Where(verse => !verse.IsActive)
            .OrderBy(verse => verse.Id)
            .Take(Math.Max(0, versesToAdd)))
        {
            await ToggleStatusAsync(verse);
        }
    }

}
