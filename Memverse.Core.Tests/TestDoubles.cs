using MemverseApp.Core.Data;
using MemverseApp.Core.ViewModels;

namespace MemverseApp.Core.Tests;

sealed class MemoryDatabase(MemoryDatabaseStore? store = null) : IDatabase
{
    private readonly MemoryDatabaseStore store = store ?? new MemoryDatabaseStore();

    public Task<DatabaseSnapshot> LoadAsync() =>
        Task.FromResult(new DatabaseSnapshot(
            store.User,
            store.AccessToken,
            store.RefreshToken,
            store.Memverses.ToList(),
            store.Mutations.ToList()));

    public Task SaveUserAsync(User user)
    {
        store.User = user;
        return Task.CompletedTask;
    }

    public Task SaveTokensAsync(OAuthTokens tokens)
    {
        store.AccessToken = tokens.AccessToken;
        store.RefreshToken = tokens.RefreshToken;
        return Task.CompletedTask;
    }

    public async Task SaveMemversesAsync(
        IEnumerable<Memverse> verses,
        bool replaceAll = false,
        params ApiRequest[] mutations)
    {
        store.Memverses = replaceAll ? verses.ToList() : store.Memverses.Concat(verses)
            .GroupBy(verse => verse.Id).Select(group => group.Last()).ToList();
        foreach (var mutation in mutations)
            await SaveMutationAsync(mutation);
    }

    public Task SaveUserAndMutationAsync(User user, ApiRequest request)
    {
        store.User = user;
        return SaveMutationAsync(request);
    }

    public Task SaveMutationAsync(ApiRequest request)
    {
        if (request.Id == 0)
            request.Id = store.NextMutationId++;
        store.Mutations.RemoveAll(item => item.Id == request.Id);
        store.Mutations.Add(request);
        return Task.CompletedTask;
    }

    public Task DeleteMutationAsync(int id)
    {
        store.Mutations.RemoveAll(item => item.Id == id);
        return Task.CompletedTask;
    }

    public Task ClearAsync()
    {
        store.User = null;
        store.AccessToken = null;
        store.RefreshToken = null;
        store.Memverses.Clear();
        store.Mutations.Clear();
        store.NextMutationId = 1;
        return Task.CompletedTask;
    }
}

sealed class MemoryDatabaseStore
{
    public User? User { get; set; }
    public string? AccessToken { get; set; }
    public string? RefreshToken { get; set; }
    public List<Memverse> Memverses { get; set; } = [];
    public List<ApiRequest> Mutations { get; } = [];
    public int NextMutationId { get; set; } = 1;
}

sealed class MemoryOfflineOperations : IOfflineOperations
{
    private readonly List<Memverse> memverses = [];
    private User? user;

    public void CreateUser(User value) => user = value;
    public void AddMemverse(Memverse verse) => memverses.Add(verse);
    public IReadOnlyList<Memverse> GetMemverses() => memverses;
    public User? GetUser() => user;
    public Task DeleteMemverseAsync(Memverse verse)
    {
        memverses.Remove(verse);
        return Task.CompletedTask;
    }
    public void QueueReviewChanges(IReadOnlyList<VerseReviewChange> changes)
    {
        foreach (var change in changes)
            if (change.Rating is { } rating)
                RatingClient.RateVerse(change.Verse, rating);
    }
    public Task ToggleStatusAsync(Memverse verse)
    {
        verse.ToggleStatus();
        return Task.CompletedTask;
    }
    public Task UpdateUserAsync(User value)
    {
        user = value;
        return Task.CompletedTask;
    }
    public Task AdjustWorkLoadAsync() => Task.CompletedTask;
}
