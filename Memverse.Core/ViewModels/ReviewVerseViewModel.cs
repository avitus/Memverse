using System.Text.RegularExpressions;
using MemverseApp.Core.Data;

namespace MemverseApp.Core.ViewModels;

sealed class Feedback
{
    private const string WhiteSpaceAndHyphens = @"(\s*[-—\s]+)";
    private const string NonWhiteSpace = @"\S+";
    private const string EndingWhiteSpaceWithHyphens = @"(\s*[-—]+\s*$)?";
    private const string NormalWordWithLeadingWhiteSpace =
        WhiteSpaceAndHyphens + "?" + NonWhiteSpace + EndingWhiteSpaceWithHyphens;
    private static readonly Regex WordPattern = new(
        "(" + NormalWordWithLeadingWhiteSpace + @")|\s+",
        RegexOptions.ExplicitCapture);

    private bool IsClassifiedAsMnemonic { get; set; }
    public int VerseNumber { get; set; }
    public IReadOnlyList<Word> Words =>
        AllWords.Where(word => !string.IsNullOrWhiteSpace(word.Text)).ToList();
    public List<Word> AllWords { get; } = [];
    public bool Correct { get; private set; }

    public static string[] Split(string text) =>
        WordPattern.Matches(text).Cast<Match>().Select(match => match.Value).ToArray();

    public static Feedback ClassifyText(string text, string actualVerse, bool revealAnswer)
    {
        var feedback = new Feedback();
        if (revealAnswer)
        {
            feedback.AllWords.Add(new Word(actualVerse, MatchKind.None));
            return feedback;
        }
        if (string.IsNullOrWhiteSpace(text))
        {
            feedback.AllWords.Add(new Word("Waiting for you to begin typing...", MatchKind.None));
            return feedback;
        }

        var words = Split(text);
        var trimmedWords = words.Select(word => word.Trim()).ToArray();
        var actual = Split(actualVerse);

        if (trimmedWords.Length == 1 &&
            trimmedWords[0].Length >= 2 &&
            IsMatch(trimmedWords[0][0], GetFirstLetter(actual[0])) &&
            GetMatchKind(trimmedWords[0], actual[0]) == MatchKind.Error)
        {
            return ClassifyMnemonic(trimmedWords[0], actual, feedback);
        }

        for (var index = 0; index < words.Length; index++)
        {
            if (index >= actual.Length || string.IsNullOrWhiteSpace(words[index]))
            {
                feedback.AllWords.Add(new Word(words[index], MatchKind.Error));
                continue;
            }

            var matchKind = IsMnemonic(trimmedWords, actual, index)
                ? IsMatch(GetFirstLetter(trimmedWords[index]), GetFirstLetter(actual[index]))
                    ? MatchKind.Correct
                    : MatchKind.Error
                : GetMatchKind(trimmedWords[index], actual[index]);
            if (matchKind == MatchKind.Prefix && index != words.Length - 1)
                matchKind = MatchKind.Error;

            feedback.AllWords.Add(new Word(
                matchKind == MatchKind.Correct ? actual[index] : words[index],
                matchKind,
                words[index]));
        }

        return feedback.CheckCorrectness(actual.Length);
    }

    public static string FixNextWord(string inputText, string actualText)
    {
        var feedback = ClassifyText(inputText, actualText, revealAnswer: false);
        var words = feedback.AllWords.Where(word => word.Kind != MatchKind.None).ToArray();
        var actual = Split(actualText);
        if (words.Length == 0)
            return GetFirstLetter(actual[0]).ToString();

        if (words.Length == 1)
        {
            var originalText = words[0].OriginalText.Trim();
            return words[0].Kind switch
            {
                MatchKind.Error => actual[0],
                MatchKind.Prefix => originalText.Length == 1
                    ? words[0].OriginalText + GetFirstLetter(actual[1])
                    : actual[0],
                MatchKind.Correct => originalText.Length == 1
                    ? words[0].OriginalText + GetFirstLetter(actual[1])
                    : words[0].OriginalText + " " + GetFirstLetter(actual[1]),
                _ => throw new ArgumentOutOfRangeException()
            };
        }

        var fixedWords = words.Select(word => word.OriginalText).ToList();
        var index = 0;
        while (index < words.Length && words[index].Kind == MatchKind.Correct)
            index++;
        if (index >= actual.Length)
            return string.Join(string.Empty, fixedWords.Take(actual.Length));

        if (feedback.IsClassifiedAsMnemonic)
        {
            if (index < words.Length)
                fixedWords[index] = GetFirstLetter(actual[index]).ToString();
            else
                fixedWords.Add(GetFirstLetter(actual[index]).ToString());
        }
        else if (index < words.Length)
        {
            var inputWords = words.Select(word => word.OriginalText.Trim()).ToList();
            inputWords[index] = GetFirstLetter(actual[index]).ToString();
            fixedWords[index] = IsMnemonic(inputWords, actual, index)
                ? (index == 0 ? string.Empty : " ") + GetFirstLetter(actual[index])
                : actual[index];
        }
        else
        {
            fixedWords.Add(" " + GetFirstLetter(actual[index]));
        }

        return string.Join(string.Empty, fixedWords);
    }

    private static bool IsMnemonic(IList<string> words, string[] actual, int index)
    {
        var isLastWord = index == words.Count - 1;
        var previousWordCouldBeMnemonic =
            CouldBeMnemonic(words, index - 1) &&
            (!isLastWord || actual[index - 1].Trim().Length != 1 ||
                CouldBeMnemonic(words, index - 2));
        return words.Count >= 2 &&
            CouldBeMnemonic(words, index) &&
            (previousWordCouldBeMnemonic || CouldBeMnemonic(words, index + 1));
    }

    private static bool CouldBeMnemonic(IList<string> words, int index) =>
        index >= 0 && index < words.Count && words[index].Length == 1;

    private Feedback CheckCorrectness(int count)
    {
        Correct = Words.Count == count &&
            Words.All(word => word.Kind == MatchKind.Correct);
        return this;
    }

    private static Feedback ClassifyMnemonic(
        string word,
        string[] actual,
        Feedback feedback)
    {
        feedback.IsClassifiedAsMnemonic = true;
        for (var index = 0; index < word.Length; index++)
        {
            if (index >= actual.Length)
                feedback.AllWords.Add(new Word(word[index].ToString(), MatchKind.Error));
            else if (!IsMatch(word[index], GetFirstLetter(actual[index])))
                feedback.AllWords.Add(new Word(
                    " " + word[index] + "...", MatchKind.Error, word[index].ToString()));
            else
                feedback.AllWords.Add(new Word(
                    actual[index], MatchKind.Correct, word[index].ToString()));
        }
        return feedback.CheckCorrectness(actual.Length);
    }

    private static char GetFirstLetter(string value) =>
        value.First(char.IsLetterOrDigit);

    private static bool IsMatch(char left, char right) =>
        char.ToLowerInvariant(left) == char.ToLowerInvariant(right);

    private static MatchKind GetMatchKind(string word, string actual)
    {
        var i = 0;
        var j = 0;
        while (i < word.Length || j < actual.Length)
        {
            if (i < word.Length && !char.IsLetterOrDigit(word[i])) { i++; continue; }
            if (j < actual.Length && !char.IsLetterOrDigit(actual[j])) { j++; continue; }
            if (i == word.Length && j == actual.Length) return MatchKind.Correct;
            if (i == word.Length) return MatchKind.Prefix;
            if (j == actual.Length) return MatchKind.Error;
            if (!IsMatch(word[i++], actual[j++])) return MatchKind.Error;
        }
        return i == word.Length && j == actual.Length
            ? MatchKind.Correct
            : MatchKind.Error;
    }
}

sealed class ReviewVersesViewModel
{
    private readonly List<IReadOnlyList<Memverse>> sections;
    private readonly MemverseCollection allVerses;
    private readonly DateTime today;
    private readonly Func<IEnumerable<Memverse>, Task> saveVersesAsync;
    private readonly Dictionary<long, int> ratings = [];

    private ReviewVersesViewModel(
        List<Memverse> verses,
        List<IReadOnlyList<Memverse>> sections,
        DateTime today,
        Func<IEnumerable<Memverse>, Task> saveVersesAsync)
    {
        allVerses = new MemverseCollection(verses);
        this.sections = sections;
        this.today = today.Date;
        this.saveVersesAsync = saveVersesAsync;
        SelectVerse(0);
    }

    public IReadOnlyList<IReadOnlyList<Memverse>> Sections => sections;
    public IReadOnlyList<Memverse> CurrentSection => sections[SectionIndex];
    public Memverse CurrentVerse => CurrentSection[VerseIndex];
    public int SectionIndex { get; private set; }
    public int VerseIndex { get; private set; }
    public string InputText { get; private set; } = "";
    public bool IsCorrect { get; private set; }
    public bool ShowAnswer { get; private set; }
    public int HintLevel { get; private set; }
    private bool IsLastVerse => VerseIndex == CurrentSection.Count - 1;
    private bool AllVersesRated => ratings.Count == CurrentSection.Count;
    private IReadOnlyList<Memverse> RatingTargets
    {
        get
        {
            if (IsLastVerse && !AllVersesRated && ratings.ContainsKey(CurrentVerse.Id))
                return CurrentSection.Where(verse => !ratings.ContainsKey(verse.Id)).ToArray();
            var previous = VerseIndex > 0 ? CurrentSection[VerseIndex - 1] : null;
            if (string.IsNullOrWhiteSpace(InputText) && previous is not null &&
                !ratings.ContainsKey(previous.Id))
                return [previous];
            return IsLastVerse && ratings.Count == 0 ? CurrentSection : [CurrentVerse];
        }
    }
    public string PassageReference =>
        CurrentSection[0].Reference + (CurrentSection.Count > 1 ? $"-{CurrentSection[^1].VerseNumber}" : "");
    public IReadOnlyList<Word> FeedbackWords =>
        Feedback.ClassifyText(InputText, CurrentVerse.Text!, revealAnswer: false).Words;

    public Memverse? PreviousVerse => allVerses.GetPreviousVerse(CurrentVerse);

    public static ReviewVersesViewModel? Create(
        IEnumerable<Memverse> verses,
        int targetVersesPerDay,
        DateTime today,
        Func<IEnumerable<Memverse>, Task> saveVersesAsync,
        long? startingPassageId = null)
    {
        var source = verses.ToList();
        var sections = PassageLogic.SelectReviewSections(
            source, targetVersesPerDay, today, startingPassageId)
            .Select(passage => (IReadOnlyList<Memverse>)passage.Verses).ToList();
        return sections.Count == 0 ? null : new ReviewVersesViewModel(source, sections, today, saveVersesAsync);
    }

    public Task UpdateInputAsync(string value)
    {
        if (HintLevel < 3)
            HintLevel = 0;
        InputText = value;
        return UpdateFeedbackAsync();
    }

    public Task UseHintAsync()
    {
        if (IsCorrect)
            return Task.CompletedTask;

        HintLevel++;
        if (HintLevel >= 3)
        {
            ShowAnswer = true;
            return Task.CompletedTask;
        }

        InputText = Feedback.FixNextWord(InputText, CurrentVerse.Text!);
        return UpdateFeedbackAsync();
    }

    private Task UpdateFeedbackAsync()
    {
        IsCorrect = Feedback.ClassifyText(
            InputText, CurrentVerse.Text!, revealAnswer: false).Correct;
        if (IsCorrect)
        {
            var verse = CurrentVerse;
            var saveProgress = verse.LastTest != today;
            verse.LastTest = today;
            ShowAnswer = false;
            if (!IsLastVerse)
                SelectVerse(VerseIndex + 1);
            if (saveProgress)
                return saveVersesAsync([verse]);
        }
        return Task.CompletedTask;
    }

    public int? GetRating(Memverse verse) =>
        ratings.TryGetValue(verse.Id, out var rating) ? rating : null;

    public void ToggleRating(Memverse verse, int rating)
    {
        if (GetRating(verse) == rating)
            ratings.Remove(verse.Id);
        else
            ratings[verse.Id] = rating;
    }

    public async Task<bool> RateAsync(int rating, IOfflineOperations offline)
    {
        var targets = RatingTargets;
        foreach (var verse in targets)
        {
            ratings[verse.Id] = rating;
            verse.LastTest = today;
            if (!IsLastVerse && verse.Id == CurrentVerse.Id)
                SelectVerse(VerseIndex + 1);
        }

        await saveVersesAsync(targets);
        if (!AllVersesRated)
            return true;

        foreach (var verse in CurrentSection)
            await offline.RateMemverseAsync(verse, ratings[verse.Id]);

        if (SectionIndex == sections.Count - 1)
            return false;

        SectionIndex++;
        ratings.Clear();
        SelectVerse(0);
        return true;
    }

    private void SelectVerse(int verseIndex)
    {
        VerseIndex = verseIndex;
        while (!IsLastVerse && CurrentVerse.LastTest?.Date == today)
            VerseIndex++;

        IsCorrect = false;
        InputText = "";
        ShowAnswer = false;
        HintLevel = 0;
    }
}

enum MatchKind
{
    None,
    Error,
    Prefix,
    Correct
}

readonly struct Word
{
    public readonly string Text;
    public readonly MatchKind Kind;
    public readonly string OriginalText;

    public Word(string text, MatchKind kind, string? originalText = null)
    {
        Text = text;
        Kind = kind;
        OriginalText = originalText ?? text;
    }
}
