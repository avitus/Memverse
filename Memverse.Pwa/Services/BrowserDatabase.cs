using MemverseApp.Core.Data;
using Microsoft.JSInterop;
using MemverseRecord = MemverseApp.Core.Data.Memverse;

namespace MemverseApp.Pwa.Services;

sealed class BrowserDatabase(IJSRuntime js) : IDatabase
{
    private const string UsersStore = "users";
    private const string MemversesStore = "memverses";
    private const string MutationsStore = "mutations";
    private const string SettingsStore = "settings";
    private const string AccessTokenKey = "accessToken";
    private const string RefreshTokenKey = "refreshToken";
    private const string PendingSignInKey = "pendingSignIn";

    public Task SavePendingSignInAsync(string state, string verifier) =>
        PutAsync(SettingsStore, new PendingSignIn(PendingSignInKey, state, verifier));

    public async Task<PendingSignIn?> TakePendingSignInAsync()
    {
        var pending = await GetAsync<PendingSignIn>(SettingsStore, PendingSignInKey);
        await DeleteAsync(SettingsStore, PendingSignInKey);
        return pending;
    }

    internal sealed record PendingSignIn(string Key, string State, string Verifier);

    public async Task<DatabaseSnapshot> LoadAsync()
    {
        var users = await GetAllAsync<User>(UsersStore);
        var accessToken = await GetAsync<DatabaseSetting>(SettingsStore, AccessTokenKey);
        var refreshToken = await GetAsync<DatabaseSetting>(SettingsStore, RefreshTokenKey);
        var memverses = await GetAllAsync<MemverseRecord>(MemversesStore);
        var mutations = await GetAllAsync<ApiRequest>(MutationsStore);
        return new DatabaseSnapshot(
            users.SingleOrDefault(),
            accessToken?.Value,
            refreshToken?.Value,
            memverses,
            mutations);
    }

    public Task SaveUserAsync(User user) =>
        ReplaceAllAsync(UsersStore, new[] { user });

    public Task SaveTokensAsync(OAuthTokens tokens) =>
        js.InvokeVoidAsync(
            "memverseDb.putAll",
            SettingsStore,
            new[]
            {
                new DatabaseSetting(AccessTokenKey, tokens.AccessToken),
                new DatabaseSetting(RefreshTokenKey, tokens.RefreshToken)
            }).AsTask();

    public Task ReplaceMemversesAsync(IEnumerable<MemverseRecord> verses) =>
        ReplaceAllAsync(MemversesStore, verses);

    public async Task ReplaceMemversesAndSaveMutationAsync(
        IEnumerable<MemverseRecord> verses,
        ApiRequest request) =>
        request.Id = await js.InvokeAsync<int>(
            "memverseDb.replaceAllAndAddMutation",
            MemversesStore,
            verses,
            request);

    public async Task SaveUserAndMutationAsync(User user, ApiRequest request) =>
        request.Id = await js.InvokeAsync<int>(
            "memverseDb.replaceAllAndAddMutation",
            UsersStore,
            new[] { user },
            request);

    public async Task SaveMutationAsync(ApiRequest request)
    {
        if (request.Id == 0)
        {
            request.Id = await js.InvokeAsync<int>(
                "memverseDb.addMutation", request);
            return;
        }
        await PutAsync(MutationsStore, request);
    }

    public Task DeleteMutationAsync(int id) =>
        DeleteAsync(MutationsStore, id);

    public Task ClearAsync() =>
        js.InvokeVoidAsync("memverseDb.clearAll").AsTask();

    private async Task<T?> GetAsync<T>(string store, object key) =>
        await js.InvokeAsync<T?>("memverseDb.get", store, key);

    private async Task<List<T>> GetAllAsync<T>(string store) =>
        await js.InvokeAsync<List<T>>("memverseDb.getAll", store) ?? [];

    private Task PutAsync<T>(string store, T value) =>
        js.InvokeVoidAsync("memverseDb.put", store, value).AsTask();

    private Task ReplaceAllAsync<T>(string store, IEnumerable<T> values) =>
        js.InvokeVoidAsync("memverseDb.replaceAll", store, values).AsTask();

    private Task DeleteAsync(string store, object key) =>
        js.InvokeVoidAsync("memverseDb.delete", store, key).AsTask();

    private sealed record DatabaseSetting(string Key, string Value);
}
