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

    public Task ReplaceMemversesAsync(IEnumerable<Memverse> verses)
    {
        store.Memverses = verses.ToList();
        return Task.CompletedTask;
    }

    public Task ReplaceMemversesAndSaveMutationAsync(
        IEnumerable<Memverse> verses,
        ApiRequest request)
    {
        store.Memverses = verses.ToList();
        return SaveMutationAsync(request);
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
    public Task RateMemverseAsync(Memverse verse, int rating)
    {
        RatingClient.RateVerse(verse, rating);
        return Task.CompletedTask;
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
