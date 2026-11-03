using System.Text.Json;

namespace MemverseApp.Core.WebApi;

internal sealed class Pagination
{
    public int Current { get; init; }
    public int? Previous { get; init; }
    public int? Next { get; init; }
    public int PerPage { get; init; }
    public int Pages { get; init; }
    public int Count { get; init; }

    public static int GetPageCount(JsonElement root)
    {
        var count = JsonApi.ReadInt(root, "page_count");
        if (count == 0 && root.TryGetProperty("pagination", out var pagination))
            count = JsonApi.ReadInt(pagination, "pages");
        return Math.Max(1, count);
    }
}

internal static class JsonApi
{
    public static JsonElement Unwrap(JsonElement root) =>
        root.TryGetProperty("response", out var response) ? response : root;

    public static bool TryGetPropertyInsensitive(
        JsonElement item,
        string name,
        out JsonElement value)
    {
        foreach (var property in item.EnumerateObject())
        {
            if (string.Equals(property.Name, name, StringComparison.OrdinalIgnoreCase))
            {
                value = property.Value;
                return true;
            }
        }

        value = default;
        return false;
    }

    public static string ReadStringInsensitive(JsonElement item, string name) =>
        TryGetPropertyInsensitive(item, name, out var value) &&
        value.ValueKind == JsonValueKind.String
            ? value.GetString() ?? ""
            : "";

    public static string ReadString(JsonElement item, params string[] names)
    {
        foreach (var name in names)
        {
            if (item.TryGetProperty(name, out var value) &&
                value.ValueKind == JsonValueKind.String)
            {
                return value.GetString() ?? "";
            }
        }

        return "";
    }

    public static long ReadLong(JsonElement item, params string[] names)
    {
        foreach (var name in names)
        {
            if (item.TryGetProperty(name, out var value) &&
                value.TryGetInt64(out var result))
            {
                return result;
            }
        }

        return 0;
    }

    public static int ReadInt(JsonElement item, params string[] names)
    {
        foreach (var name in names)
        {
            if (item.TryGetProperty(name, out var value) &&
                value.TryGetInt32(out var result))
            {
                return result;
            }
        }

        return 0;
    }

    public static DateTime ReadDate(JsonElement item, params string[] names)
    {
        foreach (var name in names)
        {
            if (item.TryGetProperty(name, out var value) &&
                value.ValueKind == JsonValueKind.String &&
                DateTime.TryParse(value.GetString(), out var result))
            {
                return result;
            }
        }

        return DateTime.Today;
    }
}
