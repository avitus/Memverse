using System.Text.Json;

namespace MemverseApp.Core.WebApi;

internal sealed class UserResponse
{
    public static Data.User Parse(JsonElement root)
    {
        var user = JsonApi.Unwrap(root);
        return new Data.User
        {
            Id = JsonApi.ReadLong(user, "id"),
            Name = JsonApi.ReadString(user, "name"),
            Email = JsonApi.ReadString(user, "email"),
            Translation = JsonApi.ReadString(user, "translation"),
            TargetVersesPerDay =
                JsonApi.ReadInt(user, "time_allocation", "target_verses_per_day"),
            LastActivityDate = ReadNullableDate(user, "last_activity_date")
        };
    }

    private static DateTime? ReadNullableDate(JsonElement item, string name) =>
        item.TryGetProperty(name, out var value) &&
        value.ValueKind == JsonValueKind.String &&
        DateTime.TryParse(value.GetString(), out var result)
            ? result
            : null;
}
