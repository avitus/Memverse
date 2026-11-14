using MemverseApp.Core.Data;
using MemverseRecord = MemverseApp.Core.Data.Memverse;

namespace MemverseApp.Core.Services;

sealed class MemverseState(IDatabase database)
{
    private Task? loadTask;
    private readonly PersistenceQueue persistence = new();

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

    private Task LoadCoreAsync() => persistence.Enqueue(async () =>
    {
        var snapshot = await database.LoadAsync();
        User = snapshot.User;
        AccessToken = snapshot.AccessToken;
        RefreshToken = snapshot.RefreshToken;
        Verses = snapshot.Memverses;
        Mutations = snapshot.Mutations;
    });

    public async Task SignInAsync(OAuthTokens tokens, User profile)
    {
        User = profile;
        await SaveUserAsync();
        await SaveTokensAsync(tokens);
    }

    public Task SaveTokensAsync(OAuthTokens tokens)
    {
        AccessToken = tokens.AccessToken;
        RefreshToken = tokens.RefreshToken;
        return persistence.Enqueue(() => database.SaveTokensAsync(tokens));
    }

    public Task SaveUserAsync() =>
        User is { } user
            ? persistence.Enqueue(() => database.SaveUserAsync(user))
            : Task.CompletedTask;

    public Task SignOutAsync() => persistence.Enqueue(async () =>
    {
        await database.ClearAsync();
        User = null;
        AccessToken = null;
        RefreshToken = null;
        Verses = [];
        Mutations = [];
    });

    public Task SaveVersesAsync(
        IEnumerable<MemverseRecord> verses,
        bool replaceAll = false,
        params ApiRequest[] mutations)
    {
        if (replaceAll)
            Verses = verses.ToList();
        var savedVerses = replaceAll ? Verses : verses;
        return persistence.Enqueue(async () =>
        {
            await database.SaveMemversesAsync(savedVerses, replaceAll, mutations);
            foreach (var mutation in mutations)
                AddMutation(mutation);
        });
    }

    public Task SaveUserAndEnqueueMutationAsync(ApiRequest request)
    {
        if (User is not { } user)
            return Task.CompletedTask;

        return persistence.Enqueue(async () =>
        {
            await database.SaveUserAndMutationAsync(user, request);
            AddMutation(request);
        });
    }

    private void AddMutation(ApiRequest request)
    {
        if (Mutations.All(item => item.Id != request.Id))
            Mutations.Add(request);
    }

    public Task RemoveMutationAsync(int id) => persistence.Enqueue(async () =>
    {
        Mutations.RemoveAll(item => item.Id == id);
        await database.DeleteMutationAsync(id);
    });

    public Task SaveMutationsAsync() => persistence.Enqueue(async () =>
    {
        foreach (var request in Mutations)
            await database.SaveMutationAsync(request);
    });

    public Task FlushPersistenceAsync() => persistence.FlushAsync();
}
