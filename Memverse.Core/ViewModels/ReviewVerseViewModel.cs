using System.Text.RegularExpressions;

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
    private readonly List<IReadOnlyList<MemverseApp.Core.Data.Memverse>> sections = [];
    private MemverseApp.Core.Data.MemverseCollection allVerses = new();

    public IReadOnlyList<IReadOnlyList<MemverseApp.Core.Data.Memverse>> Sections => sections;
    public IReadOnlyList<MemverseApp.Core.Data.Memverse>? CurrentSection { get; private set; }
    public MemverseApp.Core.Data.Memverse? CurrentVerse { get; private set; }
    public int SectionIndex { get; private set; }
    public int VerseIndex { get; private set; }
    public string InputText { get; private set; } = "";
    public bool IsCorrect { get; private set; }
    public bool ShowAnswer { get; private set; }
    public bool Submitting { get; private set; }
    public int HintLevel { get; private set; }
    public IReadOnlyList<Word> FeedbackWords =>
        Feedback.ClassifyText(InputText, CurrentVerse?.Text ?? "", revealAnswer: false).Words;

    public MemverseApp.Core.Data.Memverse? PreviousVerse =>
        CurrentVerse is null ? null : allVerses.GetPreviousVerse(CurrentVerse);

    public void Initialize(
        IEnumerable<MemverseApp.Core.Data.Memverse> verses,
        int targetVersesPerDay,
        DateTime today,
        long? startingPassageId = null)
    {
        var source = verses.ToList();
        allVerses = new MemverseApp.Core.Data.MemverseCollection(source);
        sections.Clear();
        sections.AddRange(MemverseApp.Core.Data.PassageLogic.SelectReviewSections(
            source, targetVersesPerDay, today, startingPassageId)
            .Select(passage => passage.Verses));
        SectionIndex = 0;
        VerseIndex = 0;
        SelectCurrentVerse();
    }

    public void UpdateInput(string value)
    {
        if (HintLevel < 3)
            HintLevel = 0;
        InputText = value;
        IsCorrect = Feedback.ClassifyText(
            InputText, CurrentVerse?.Text ?? "", revealAnswer: false).Correct;
        if (IsCorrect)
            ShowAnswer = false;
    }

    public void UseHint()
    {
        if (CurrentVerse is null || IsCorrect)
            return;

        HintLevel++;
        if (HintLevel >= 3)
        {
            ShowAnswer = true;
            return;
        }

        InputText = Feedback.FixNextWord(InputText, CurrentVerse.Text!);
        IsCorrect = Feedback.ClassifyText(
            InputText, CurrentVerse.Text!, revealAnswer: false).Correct;
    }

    public bool BeginRating(int rating)
    {
        if (Submitting || CurrentVerse is null || rating >= 3 && !IsCorrect)
            return false;

        Submitting = true;
        return true;
    }

    public void CompleteRating()
    {
        VerseIndex++;
        if (CurrentSection is not null && VerseIndex >= CurrentSection.Count)
        {
            SectionIndex++;
            VerseIndex = 0;
        }

        SelectCurrentVerse();
        Submitting = false;
    }

    public void CancelRating() => Submitting = false;

    private void SelectCurrentVerse()
    {
        if (SectionIndex >= sections.Count)
        {
            CurrentSection = null;
            CurrentVerse = null;
            return;
        }

        CurrentSection = sections[SectionIndex];
        CurrentVerse = CurrentSection[VerseIndex];
        InputText = "";
        IsCorrect = false;
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
