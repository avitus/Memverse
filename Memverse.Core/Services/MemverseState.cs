using MemverseApp.Core.Data;
using MemverseRecord = MemverseApp.Core.Data.Memverse;

namespace MemverseApp.Core.Services;

sealed class MemverseState(IDatabase database)
{
    private Task? loadTask;

    public User? User { get; private set; }
    public string? AccessToken { get; private set; }
    public string? RefreshToken { get; private set; }
    public List<MemverseRecord> Verses { get; private set; } = [];
    public List<ApiRequest> Mutations { get; private set; } = [];
    public bool IsSignedIn =>
        User is not null &&
        !string.IsNullOrWhiteSpace(AccessToken) &&
        !string.IsNullOrWhiteSpace(RefreshToken);

    public Task LoadAsync() => loadTask ??= LoadCoreAsync();

    private async Task LoadCoreAsync()
    {
        var snapshot = await database.LoadAsync();
        User = snapshot.User;
        AccessToken = snapshot.AccessToken;
        RefreshToken = snapshot.RefreshToken;
        Verses = snapshot.Memverses;
        Mutations = snapshot.Mutations;
    }

    public async Task SignInAsync(OAuthTokens tokens, User profile)
    {
        User = profile;
        await database.SaveUserAsync(User);
        await SaveTokensAsync(tokens);
    }

    public async Task SaveTokensAsync(OAuthTokens tokens)
    {
        AccessToken = tokens.AccessToken;
        RefreshToken = tokens.RefreshToken;
        await database.SaveTokensAsync(tokens);
    }

    public Task SaveUserAsync() =>
        User is null ? Task.CompletedTask : database.SaveUserAsync(User);

    public async Task SignOutAsync()
    {
        await database.ClearAsync();
        User = null;
        AccessToken = null;
        RefreshToken = null;
        Verses = [];
        Mutations = [];
    }

    public async Task SaveVersesAsync(IEnumerable<MemverseRecord> verses)
    {
        Verses = verses.ToList();
        await database.ReplaceMemversesAsync(Verses);
    }

    public async Task SaveVersesAndEnqueueMutationAsync(
        IEnumerable<MemverseRecord> verses,
        ApiRequest request)
    {
        Verses = verses.ToList();
        await database.ReplaceMemversesAndSaveMutationAsync(Verses, request);
        AddMutation(request);
    }

    public async Task SaveUserAndEnqueueMutationAsync(ApiRequest request)
    {
        if (User is null)
            return;

        await database.SaveUserAndMutationAsync(User, request);
        AddMutation(request);
    }

    private void AddMutation(ApiRequest request)
    {
        if (Mutations.All(item => item.Id != request.Id))
            Mutations.Add(request);
    }

    public async Task RemoveMutationAsync(int id)
    {
        Mutations.RemoveAll(item => item.Id == id);
        await database.DeleteMutationAsync(id);
    }

    public async Task SaveMutationsAsync()
    {
        foreach (var request in Mutations)
            await database.SaveMutationAsync(request);
    }
}
