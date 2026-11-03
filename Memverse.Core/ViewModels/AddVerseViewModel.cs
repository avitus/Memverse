using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MemverseApp.Core.Data;
using MemverseApp.Core.Services;

namespace MemverseApp.Core.ViewModels;

class AddVerseViewModel
{
    private readonly IOnlineOperations? apiClient;
    private readonly IOfflineOperations? database;
    private readonly ITelemetryService? telemetry;
    private IReadOnlyList<Memverse> existing = new List<Memverse>();
    private Book? selectedBook;
    private int? selectedChapter;
    private IList<object>? selectedVerses;
    private AddVerseStage stage;

    public AddVerseViewModel()
    {
        this.stage = AddVerseStage.ChooseBook;
    }

    public AddVerseViewModel(
        IOnlineOperations apiClient,
        IOfflineOperations? database,
        object? eventAggregator,
        ITelemetryService? telemetry)
    {
        this.apiClient = apiClient;
        this.database = database;
        this.telemetry = telemetry;
        this.stage = AddVerseStage.ChooseBook;
        _ = apiClient.FlushBackgroundTasksAsync();
    }

    public void ChooseBook() { this.Stage = AddVerseStage.ChooseBook; }
    public void ChooseChapter() { this.Stage = AddVerseStage.ChooseChapter; }
    public bool CanChooseChapter { get { return this.SelectedBook != null; } }
    public bool CanAddSelectedVerses
    {
        get
        {
            return this.selectedVerses != null && this.selectedVerses.Any() ||
                this.SelectedIds.Any();
        }
    }

    public IList<Book> Books { get { return Bible.Books; } }
    public IEnumerable<int>? Chapters { get; private set; }
    public List<Verse>? Verses { get; private set; }

    public Book? SelectedBook
    {
        get { return selectedBook; }
        set
        {
            this.selectedBook = value;
            if (value != null) this.Stage = AddVerseStage.ChooseChapter;
        }
    }

    public int? SelectedChapter
    {
        get { return selectedChapter; }
        set
        {
            this.selectedChapter = value;
            if (value != null) this.Stage = AddVerseStage.ChooseVerses;
        }
    }

    public IList<object>? SelectedVerses
    {
        get { return this.selectedVerses; }
        set { this.selectedVerses = value; }
    }

    public bool SelectAllEnabled { get; private set; }
    public bool AddVersesInProgress { get; private set; }
    public bool ShowProgress { get; private set; }
    public bool HasMissingVerses { get; private set; }
    public bool ShowMissingVersesWarning { get; private set; }

    public AddVerseStage Stage
    {
        get { return stage; }
        set
        {
            switch (value)
            {
            case AddVerseStage.ChooseBook:
                this.selectedBook = null;
                this.selectedChapter = null;
                this.SelectedVerses = null;
                this.Chapters = null;
                this.SelectAllEnabled = false;
                this.HasMissingVerses = false;
                this.ShowMissingVersesWarning = false;
                this.Verses = null;
                break;
            case AddVerseStage.ChooseChapter:
                this.Verses = null;
                this.SelectedVerses = null;
                this.SelectAllEnabled = false;
                this.HasMissingVerses = false;
                this.ShowMissingVersesWarning = false;
                this.Chapters = Enumerable.Range(1, this.SelectedBook!.ChapterEndings.Length);
                if (this.selectedBook!.ChapterEndings.Length == 1)
                {
                    this.selectedChapter = 1;
                    this.Stage = AddVerseStage.ChooseVerses;
                    return;
                }
                else
                {
                    this.selectedChapter = null;
                }
                break;
            case AddVerseStage.ChooseVerses:
                if (apiClient != null)
                    LoadVersesAsync();
                break;
            }

            this.stage = value;
        }
    }

    private async void LoadVersesAsync()
    {
        this.ShowProgress = true;
        this.Verses = new List<Verse>();
        for (int i = 1; i <= this.SelectedBook!.ChapterEndings[this.SelectedChapter!.Value - 1]; i++)
        {
            try
            {
                this.Verses!.Add(await apiClient!.GetVerseAsync(
                    this.SelectedBook!.Id, this.SelectedChapter!.Value, i));
            }
            catch (MemverseException)
            {
                this.HasMissingVerses = true;
            }
        }
        this.ShowMissingVersesWarning = !this.Verses!.Any();
        this.SelectAllEnabled = true;
        this.ShowProgress = false;
    }

    public HashSet<long> SelectedIds { get; } = new HashSet<long>();
    public string? Translation { get; set; } = "NIV";
    public bool Busy { get; private set; }
    public string? Error { get; private set; }
    public bool AllSelected
    {
        get
        {
            var available = (Verses ?? new List<Verse>())
                .Where(verse => !Exists(verse)).ToList();
            return available.Count > 0 &&
                available.All(verse => SelectedIds.Contains(verse.Id));
        }
    }

    public void Initialize(User? user, IEnumerable<Memverse> existingVerses)
    {
        Translation = user == null ? "NIV" : user.Translation;
        existing = existingVerses.ToList();
    }

    public void BeginLoading()
    {
        Busy = true;
        Error = null;
        Verses = new List<Verse>();
        SelectedIds.Clear();
        SelectAllEnabled = false;
        HasMissingVerses = false;
        ShowMissingVersesWarning = false;
    }

    public void SetChapter(IEnumerable<Verse> verses)
    {
        Verses = verses.ToList();
        SelectAllEnabled = Verses.Count > 0;
        HasMissingVerses =
            SelectedBook != null &&
            SelectedChapter.HasValue &&
            Verses.Count < SelectedBook.ChapterEndings[SelectedChapter.Value - 1];
        ShowMissingVersesWarning = Verses.Count == 0;
        Busy = false;
        if (Verses.Count == 0)
            Error = "No verses were returned for this chapter and translation.";
    }

    public void SetError(string error)
    {
        Error = error;
        Busy = false;
    }

    public bool Exists(Verse verse)
    {
        return existing.Any(item =>
            item.Book == verse.Book - 1 &&
            item.Chapter == verse.Chapter &&
            item.VerseNumber == verse.VerseNumber);
    }

    public void Toggle(long id, bool selected)
    {
        if (selected)
            SelectedIds.Add(id);
        else
            SelectedIds.Remove(id);
    }

    public void ToggleAll(bool selected)
    {
        SelectedIds.Clear();
        if (!selected)
            return;

        foreach (var verse in Verses!.Where(verse => !Exists(verse)))
            SelectedIds.Add(verse.Id);
    }

    public IReadOnlyList<Verse> BeginAdding()
    {
        Busy = true;
        Error = null;
        return Verses!.Where(verse => SelectedIds.Contains(verse.Id)).ToList();
    }

    public void Added(Verse verse, Memverse added)
    {
        SelectedIds.Remove(verse.Id);
        existing = existing.Append(added).ToList();
    }

    public void CompleteAdding(IEnumerable<string> failures)
    {
        var errors = failures.ToList();
        Error = errors.Count == 0
            ? null
            : "Some verses were not added: " + string.Join("; ", errors);
        Busy = false;
    }
}

enum AddVerseStage
{
    ChooseBook,
    ChooseChapter,
    ChooseVerses
}
