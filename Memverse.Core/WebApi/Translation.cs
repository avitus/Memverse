using System.Text.Json;
using MemverseApp.Core.Data;

namespace MemverseApp.Core.WebApi;

internal sealed class TranslationsResponse
{
    public static IReadOnlyList<Language> Parse(JsonElement root)
    {
        var result = new List<Language>();
        foreach (var language in JsonApi.Unwrap(root).EnumerateArray())
        {
            var translationsForLanguage = new List<Translation>();
            if (JsonApi.TryGetPropertyInsensitive(
                language, "Translations", out var translations))
            {
                foreach (var translation in translations.EnumerateArray())
                {
                    translationsForLanguage.Add(new Translation
                    {
                        Name = JsonApi.ReadStringInsensitive(translation, "Name"),
                        Abbreviation =
                            JsonApi.ReadStringInsensitive(translation, "Abbreviation")
                    });
                }
            }
            result.Add(new Language
            {
                Name = JsonApi.ReadStringInsensitive(language, "Name"),
                Abbreviation = JsonApi.ReadStringInsensitive(language, "Abbreviation"),
                Translations = translationsForLanguage.ToArray()
            });
        }

        return result;
    }
}
