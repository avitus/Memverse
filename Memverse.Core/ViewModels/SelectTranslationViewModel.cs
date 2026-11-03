using MemverseApp.Core.Data;
using MemverseApp.Core.Services;

namespace MemverseApp.Core.ViewModels;

sealed class SelectTranslationViewModel(
    IOfflineOperations offlineOperations,
    IOnlineOperations onlineOperations,
    ITelemetryService telemetry)
{
    public List<Language> Languages { get; } = [];
    public bool InProgress { get; private set; }

    public async Task PopulateTranslationsAsync()
    {
        InProgress = true;
        try
        {
            await onlineOperations.FlushBackgroundTasksAsync();
            Languages.Clear();
            Languages.AddRange(
                await onlineOperations.GetAvailableTranslationsAsync());
        }
        finally
        {
            InProgress = false;
        }
    }

    public async Task<string?> SelectTranslationAsync(
        string abbreviation,
        int targetVersesPerDay)
    {
        telemetry.TrackEvent($"SelectTranslation.{abbreviation}");
        InProgress = true;
        try
        {
            var user = offlineOperations.GetUser();
            if (user is null)
                return "Sign in is required.";
            user.Translation = abbreviation;
            user.TargetVersesPerDay = targetVersesPerDay;
            await offlineOperations.UpdateUserAsync(user);
            await onlineOperations.FlushBackgroundTasksAsync();
            return onlineOperations.LastError;
        }
        finally
        {
            InProgress = false;
        }
    }
}
