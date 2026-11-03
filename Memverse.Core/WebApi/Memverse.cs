using System.Text.Json;

namespace MemverseApp.Core.WebApi;

internal sealed class MemversesResponse
{
    public static IEnumerable<Data.Memverse> Parse(JsonElement root) =>
        JsonApi.Unwrap(root).EnumerateArray().Select(RawMemverse.Parse);
}

internal sealed class RawMemverse
{
    public static Data.Memverse Parse(JsonElement item)
    {
        var verse = item.TryGetProperty("verse", out var nestedVerse) &&
            nestedVerse.ValueKind == JsonValueKind.Object
                ? nestedVerse
                : item;
        var chapter = JsonApi.ReadInt(item, "chapter");
        if (chapter == 0)
            chapter = JsonApi.ReadInt(verse, "chapter");
        var verseNumber = JsonApi.ReadInt(item, "versenum", "verse_number");
        if (verseNumber == 0)
            verseNumber = JsonApi.ReadInt(verse, "versenum", "verse_number");
        var text = JsonApi.ReadString(item, "text");
        if (string.IsNullOrWhiteSpace(text))
            text = JsonApi.ReadString(verse, "text");
        var translation = JsonApi.ReadString(item, "translation", "tl");
        if (string.IsNullOrWhiteSpace(translation))
            translation = JsonApi.ReadString(verse, "translation", "tl");
        var bookIndex = JsonApi.ReadInt(item, "book_index");
        if (bookIndex == 0)
            bookIndex = JsonApi.ReadInt(verse, "book_index");

        return new Data.Memverse
        {
            Id = JsonApi.ReadLong(item, "id"),
            Book = bookIndex - 1,
            Chapter = chapter,
            VerseNumber = verseNumber,
            Text = text,
            Translation = translation,
            Status = JsonApi.ReadString(item, "status"),
            DueDate = JsonApi.ReadDate(item, "next_test", "due_date"),
            IterationNumber = JsonApi.ReadInt(item, "rep_n"),
            TestInterval = TimeSpan.FromDays(
                Math.Max(1, JsonApi.ReadInt(item, "test_interval")))
        };
    }
}

internal sealed class RawMemverseResponse
{
    public static Data.Memverse Parse(JsonElement root) =>
        RawMemverse.Parse(JsonApi.Unwrap(root));
}
