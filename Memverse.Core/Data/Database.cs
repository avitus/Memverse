namespace MemverseApp.Core.Data;

sealed class MemverseCollection
{
    private readonly Dictionary<BookKey, BookPassages> allVerses = [];

    private sealed class BookPassages
    {
        public readonly SortedDictionary<int, ChapterPassages> ChapterPassages = [];

        public ChapterPassages GetOrCreateChapterPassages(int chapter)
        {
            if (!ChapterPassages.TryGetValue(chapter, out var passages))
                ChapterPassages.Add(chapter, passages = new ChapterPassages());
            return passages;
        }
    }

    private sealed class ChapterPassages
    {
        public readonly List<Passage> Passages = [];

        public void AppendVerse(Memverse verse)
        {
            var currentPassage = Passages.LastOrDefault();
            if (currentPassage is null ||
                currentPassage.Verses[^1].VerseNumber != verse.VerseNumber - 1)
            {
                currentPassage = new Passage();
                Passages.Add(currentPassage);
            }

            currentPassage.Verses.Add(verse);
        }

        public Memverse? GetPreviousVerse(Memverse verse)
        {
            foreach (var passage in Passages)
            {
                if (passage.Verses[0].VerseNumber <= verse.VerseNumber &&
                    passage.Verses[^1].VerseNumber >= verse.VerseNumber)
                {
                    return passage.Verses.FirstOrDefault(
                        candidate => candidate.VerseNumber == verse.VerseNumber - 1);
                }
            }

            return null;
        }

        public void AddMemverse(Memverse verse)
        {
            var previousPassage = Passages.FirstOrDefault(
                passage => passage.Verses[^1].VerseNumber == verse.VerseNumber - 1);
            var nextPassage = Passages.FirstOrDefault(
                passage => passage.Verses[0].VerseNumber == verse.VerseNumber + 1);

            if (previousPassage is null && nextPassage is null)
            {
                AppendVerse(verse);
            }
            else if (previousPassage is not null && nextPassage is not null)
            {
                previousPassage.Verses.Add(verse);
                previousPassage.Verses.AddRange(nextPassage.Verses);
                Passages.Remove(nextPassage);
            }
            else if (previousPassage is not null)
            {
                previousPassage.Verses.Add(verse);
            }
            else
            {
                nextPassage!.Verses.Insert(0, verse);
            }
        }

        public void DeleteMemverse(Memverse verse)
        {
            var passage = Passages.Single(item => item.Verses.Contains(verse));
            if (passage.Verses.Count == 1)
            {
                Passages.Remove(passage);
            }
            else if (passage.Verses[0] == verse || passage.Verses[^1] == verse)
            {
                passage.Verses.Remove(verse);
            }
            else
            {
                var versesToMove = passage.Verses
                    .Where(item => item.VerseNumber > verse.VerseNumber)
                    .ToList();
                var newPassage = new Passage();
                newPassage.Verses.AddRange(versesToMove);
                Passages.Add(newPassage);
                passage.Verses.RemoveAll(
                    item => item.VerseNumber >= verse.VerseNumber);
            }
        }
    }

    private readonly record struct BookKey(int Book, string? Translation);

    public MemverseCollection(IEnumerable<Memverse>? verses = null)
    {
        foreach (var verse in (verses ?? [])
            .OrderBy(GetBookSortIndex)
            .ThenBy(item => item.Translation, StringComparer.OrdinalIgnoreCase)
            .ThenBy(item => item.Chapter)
            .ThenBy(item => item.VerseNumber))
        {
            GetOrCreateBookPassages(verse)
                .GetOrCreateChapterPassages(verse.Chapter)
                .AppendVerse(verse);
        }
    }

    private BookPassages GetOrCreateBookPassages(Memverse verse)
    {
        var key = GetBookKey(verse);
        if (!allVerses.TryGetValue(key, out var passages))
            allVerses.Add(key, passages = new BookPassages());
        return passages;
    }

    public IEnumerable<Passage> GetPassages() =>
        allVerses
            .OrderBy(item => item.Key.Book)
            .ThenBy(item => item.Key.Translation, StringComparer.OrdinalIgnoreCase)
            .SelectMany(item => item.Value.ChapterPassages.Values
                .SelectMany(chapter => chapter.Passages
                    .OrderBy(passage => passage.Verses[0].VerseNumber)));

    public Memverse? GetPreviousVerse(Memverse verse) =>
        allVerses.TryGetValue(GetBookKey(verse), out var passages) &&
        passages.ChapterPassages.TryGetValue(verse.Chapter, out var chapter)
            ? chapter.GetPreviousVerse(verse)
            : null;

    public void AddMemverse(Memverse verse)
    {
        ArgumentNullException.ThrowIfNull(verse);
        GetOrCreateBookPassages(verse)
            .GetOrCreateChapterPassages(verse.Chapter)
            .AddMemverse(verse);
    }

    public void DeleteMemverse(Memverse verse)
    {
        ArgumentNullException.ThrowIfNull(verse);
        GetOrCreateBookPassages(verse)
            .GetOrCreateChapterPassages(verse.Chapter)
            .DeleteMemverse(verse);
    }

    public void DeleteAll() => allVerses.Clear();

    private static BookKey GetBookKey(Memverse verse) =>
        new(verse.Book, verse.Translation);

    private static int GetBookSortIndex(Memverse verse) =>
        verse.Book;
}

sealed class Passage
{
    public List<Memverse> Verses { get; } = [];
    public Memverse First => Verses[0];
    public Memverse Last => Verses[^1];
    public string Reference =>
        First.Reference + (Verses.Count > 1 ? $"-{Last.VerseNumber}" : "");
    public string NumberReference =>
        First.NumberReference + (Verses.Count > 1 ? $"-{Last.VerseNumber}" : "");
    public string? PreviewText => First.Text;
    public DateTime DueDate =>
        Verses.Where(IsActive)
            .Select(verse => verse.DueDate)
            .DefaultIfEmpty(DateTime.MaxValue)
            .Min();

    public static bool IsActive(Memverse verse) => verse.IsActive;
}

static class PassageLogic
{
    public static List<Passage> Consolidate(IEnumerable<Memverse> source) =>
        new MemverseCollection(source).GetPassages().ToList();

    public static List<Passage> SelectReviewSections(
        IEnumerable<Memverse> source,
        int target,
        DateTime today,
        long? startingPassageId = null)
    {
        target = Math.Max(1, target);
        var limit = Math.Min(target * 2, target + 20);
        var selected = new List<Passage>();
        var count = 0;

        var candidates = Consolidate(source)
            .Where(section => section.Verses.Any(
                verse => verse.IsActive && verse.DueDate.Date <= today.Date))
            .OrderBy(section => section.DueDate)
            .ToList();

        if (startingPassageId is { } id)
        {
            var startingPassage = candidates.First(section =>
                section.Verses.Any(verse => verse.Id == id));
            candidates.Remove(startingPassage);
            candidates.Insert(0, startingPassage);
        }

        foreach (var section in candidates)
        {
            while (section.Verses.Count > 0 &&
                section.Verses[0].LastTest?.Date == today.Date)
                section.Verses.RemoveAt(0);

            if (section.Verses.Count == 0)
                continue;

            if (selected.Count > 0 && count + section.Verses.Count > limit)
                break;

            selected.Add(section);
            count += section.Verses.Count;
        }

        return selected;
    }
}
