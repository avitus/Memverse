using MemverseApp.Core.Data;

namespace MemverseApp.Core.ViewModels;

sealed class UserSettingsViewModel
{
    public IReadOnlyList<int> Times { get; } =
        Enumerable.Range(1, 12).Select(value => value * 5).ToList();
    public List<Language> Languages { get; } = [];
    public string? Translation { get; set; } = "NIV";
    public int TargetVersesPerDay { get; set; } = 15;
    public string? Message { get; private set; }
    public bool Succeeded { get; private set; }
    public bool Busy { get; private set; }

    public void Initialize(User? user)
    {
        if (user is null)
            return;

        Translation = user.Translation;
        TargetVersesPerDay = Math.Clamp(
            5 * Math.Max(1, user.TargetVersesPerDay / 5), 5, 60);
    }

    interface IReset
    {
        void ResetState();
    }

    public void SetLanguages(IEnumerable<Language> languages)
    {
        Languages.Clear();
        Languages.AddRange(languages);
        if (Languages.SelectMany(language => language.Translations)
            .Any(item => item.Abbreviation == Translation))
            return;

        Languages.Insert(0, new Language
        {
            Name = "Current",
            Translations =
            [
                new Translation { Name = Translation, Abbreviation = Translation }
            ]
        });
    }

    public void BeginSave()
    {
        Busy = true;
        Message = null;
    }

    public void CompleteSave(string? error)
    {
        Busy = false;
        Message = error ?? "Settings saved to Memverse.";
        Succeeded = error is null;
    }

    public void SetError(string error)
    {
        Message = error;
        Succeeded = false;
    }
}
