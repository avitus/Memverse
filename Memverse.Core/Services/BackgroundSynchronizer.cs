
using MemverseApp.Core;
using MemverseApp.Core.Data;

namespace MemverseApp.Core.Services;

sealed class BackgroundSynchronizer(
    MemverseState state,
    IMemverseMutationClient client)
{
    private readonly SemaphoreSlim syncLock = new(1, 1);

    public string? LastError { get; private set; }

    public async Task SyncAsync()
    {
        await syncLock.WaitAsync();
        try
        {
            LastError = null;
            foreach (var operation in state.Mutations.OrderBy(request => request.Id).ToList())
            {
                try
                {
                    await ExecuteAsync(operation);
                    await state.RemoveMutationAsync(operation.Id);
                }
                catch (Exception exception) when (exception is HttpRequestException or InvalidOperationException or System.Text.Json.JsonException)
                {
                    operation.RetryCount++;
                    LastError = $"Some offline changes still need syncing: {exception.Message}";
                    await state.SaveMutationsAsync();
                    break;
                }
            }
        }
        finally
        {
            syncLock.Release();
        }
    }

    private async Task ExecuteAsync(ApiRequest operation)
    {
        var token = state.AccessToken ?? throw new InvalidOperationException("Sign in is required.");
        using var json = System.Text.Json.JsonDocument.Parse(operation.Json!);
        var payload = json.RootElement;
        var resourceId = payload.GetProperty("Id").GetInt64();
        switch (operation.Kind)
        {
            case ApiRequestKind.RateMemverse:
                await client.RateMemverseAsync(resourceId, payload.GetProperty("Rating").GetInt32(), token);
                break;
            case ApiRequestKind.DeleteMemverse:
                await client.DeleteMemverseAsync(resourceId, token);
                break;
            case ApiRequestKind.UpdateUser:
                await client.UpdateUserAsync(
                    new User
                    {
                        Id = resourceId,
                        Translation = payload.GetProperty("Translation").GetString()!,
                        TargetVersesPerDay = payload.GetProperty("TimeAllocation").GetInt32()
                    },
                    token);
                break;
        }
    }
}
