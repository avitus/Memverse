using System.Text.Json;

namespace MemverseApp.Core.WebApi;

internal sealed class VersesResponse
{
    public static Data.Verse Parse(JsonElement verse)
    {
        var verseNumber = JsonApi.ReadInt(verse, "versenum", "verse_number");
        return new Data.Verse
        {
            Id = JsonApi.ReadLong(verse, "id"),
            Book = JsonApi.ReadInt(verse, "book_index"),
            Chapter = JsonApi.ReadInt(verse, "chapter"),
            VerseNumber = verseNumber,
            Translation = JsonApi.ReadString(verse, "translation"),
            Text = JsonApi.ReadString(verse, "text")
        };
    }
}
