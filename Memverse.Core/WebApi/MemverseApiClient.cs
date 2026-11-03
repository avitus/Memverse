using System.Text.Json;
using MemverseApp.Core.Data;
using MemverseApp.Core.Services;

namespace MemverseApp.Core;

sealed class MemverseApiClient(HttpClient http, MemverseState? state = null) : IMemverseClient
{
    private string? accessToken;
    private readonly SemaphoreSlim refreshLock = new(1, 1);

    public Task<OAuthTokens> ExchangeAuthorizationCodeAsync(
        string code,
        string codeVerifier,
        string redirectUri,
        CancellationToken cancellationToken = default) =>
        RequestTokensAsync(
            new Dictionary<string, string>
            {
                ["grant_type"] = "authorization_code",
                ["code"] = code,
                ["redirect_uri"] = redirectUri,
                ["code_verifier"] = codeVerifier
            },
            cancellationToken);

    private Task<OAuthTokens> RefreshTokensAsync(
        string refreshToken,
        CancellationToken cancellationToken = default) =>
        RequestTokensAsync(
            new Dictionary<string, string>
            {
                ["grant_type"] = "refresh_token",
                ["refresh_token"] = refreshToken
            },
            cancellationToken);

    public void SetAccessToken(string accessToken) => this.accessToken = accessToken;

    public async Task<IEnumerable<Memverse>> GetMemversesAsync()
    {
        var accessToken = GetAccessToken();
        var passages = new List<Memverse>();
        var page = 1;
        var pageCount = 1;

        do
        {
            using var response = await SendAsync(
                HttpMethod.Get, $"memverses?page={page}", null, accessToken, default);
            using var json = await ReadJsonAsync(response);
            var root = json.RootElement;
            passages.AddRange(WebApi.MemversesResponse.Parse(root));
            pageCount = WebApi.Pagination.GetPageCount(root);
            page++;
        }
        while (page <= pageCount);

        return passages;
    }

    public async Task<User> GetIdentityAsync()
    {
        var accessToken = GetAccessToken();
        using var response = await SendAsync(HttpMethod.Get, "me", null, accessToken, default);
        using var json = await ReadJsonAsync(response);
        return WebApi.UserResponse.Parse(json.RootElement);
    }

    public async Task<Memverse> RateMemverseAsync(
        Memverse passage,
        int rating)
    {
        var accessToken = GetAccessToken();
        using var response = await SendAsync(
            HttpMethod.Patch, $"memverses/{passage.Id}",
            new Dictionary<string, string>
            {
                ["q"] = rating.ToString()
            }, accessToken, default);
        using var json = await ReadJsonAsync(response);
        var item = WebApi.JsonApi.Unwrap(json.RootElement);

        passage.DueDate = WebApi.JsonApi.ReadDate(item, "next_test", "due_date");
        passage.IterationNumber = WebApi.JsonApi.ReadInt(item, "rep_n");
        passage.TestInterval = TimeSpan.FromDays(
            Math.Max(1, WebApi.JsonApi.ReadInt(item, "test_interval")));
        var status = WebApi.JsonApi.ReadString(item, "status");
        if (!string.IsNullOrWhiteSpace(status))
            passage.Status = status;
        passage.LastTest = DateTime.Today;
        return passage;
    }

    public Task RateMemverseAsync(long id, int rating, string accessToken,
        CancellationToken cancellationToken = default) =>
        SendMutationAsync(HttpMethod.Patch, $"memverses/{id}",
            new Dictionary<string, string> { ["q"] = rating.ToString() },
            accessToken, cancellationToken);

    public async Task DeleteMemverseAsync(long id, string accessToken,
        CancellationToken cancellationToken = default)
    {
        using var response = await SendAsync(HttpMethod.Delete, $"memverses/{id}", null,
            accessToken, cancellationToken);
        if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
            return;
        await EnsureSuccessAsync(response, cancellationToken);
    }

    public Task UpdateUserAsync(User user) =>
        UpdateUserAsync(user, GetAccessToken());

    public Task UpdateUserAsync(User user, string accessToken,
        CancellationToken cancellationToken = default) =>
        SendMutationAsync(HttpMethod.Put, $"users/{user.Id}",
            new Dictionary<string, string>
            {
                ["user[translation]"] = user.Translation!,
                ["user[time_allocation]"] = user.TargetVersesPerDay.ToString()
            }, accessToken, cancellationToken);

    public async Task<Language[]> GetAvailableTranslationsAsync()
    {
        var accessToken = GetAccessToken();
        using var response = await SendAsync(HttpMethod.Get, "translations", null,
            accessToken, default);
        using var json = await ReadJsonAsync(response);
        return WebApi.TranslationsResponse.Parse(json.RootElement).ToArray();
    }

    public async Task<IReadOnlyList<Verse>> GetChapterAsync(string translation,
        string book, int chapter)
    {
        var accessToken = GetAccessToken();
        var result = new List<Verse>();
        var page = 1;
        var pages = 1;
        do
        {
            var path = $"verses/chapter?tl={Uri.EscapeDataString(translation)}&bk={Uri.EscapeDataString(book)}&ch={chapter}&page={page}";
            using var response = await SendAsync(
                HttpMethod.Get, path, null, accessToken, default);
            using var json = await ReadJsonAsync(response);
            var root = json.RootElement;
            var items = WebApi.JsonApi.Unwrap(root);
            foreach (var verse in items.EnumerateArray())
                result.Add(WebApi.VersesResponse.Parse(verse));
            pages = WebApi.Pagination.GetPageCount(root);
            page++;
        } while (page <= pages);
        return result.OrderBy(v => v.VerseNumber).ToList();
    }

    public async Task<Verse> GetVerseAsync(long id)
    {
        using var response = await SendAsync(
            HttpMethod.Get, $"verses/{id}", null, GetAccessToken(), default);
        using var json = await ReadJsonAsync(response);
        return ParseVerse(json.RootElement);
    }

    public async Task<Verse> GetVerseAsync(int book, int chapter, int verse)
    {
        var path = $"verses/lookup?bk={Uri.EscapeDataString(Bible.Books[book].Name)}&ch={chapter}&vs={verse}";
        using var response = await SendAsync(
            HttpMethod.Get, path, null, GetAccessToken(), default);
        using var json = await ReadJsonAsync(response);
        return ParseVerse(json.RootElement);
    }

    public async Task<Memverse> AddMemverseAsync(Verse verse)
    {
        var accessToken = GetAccessToken();
        using var response = await SendAsync(HttpMethod.Post, "memverses",
            new Dictionary<string, string> { ["id"] = verse.Id.ToString() },
            accessToken, default);
        using var json = await ReadJsonAsync(response);
        var passage = WebApi.RawMemverseResponse.Parse(json.RootElement);
        passage.Book = passage.Book < 0 ? verse.Book - 1 : passage.Book;
        passage.Chapter = passage.Chapter == 0 ? verse.Chapter : passage.Chapter;
        passage.VerseNumber = passage.VerseNumber == 0 ? verse.VerseNumber : passage.VerseNumber;
        passage.Text = string.IsNullOrWhiteSpace(passage.Text) ? verse.Text : passage.Text;
        passage.Translation = string.IsNullOrWhiteSpace(passage.Translation) ? verse.Translation : passage.Translation;
        return passage;
    }

    public async Task DeleteMemverseAsync(long id) =>
        await DeleteMemverseAsync(id, GetAccessToken());

    private async Task SendMutationAsync(HttpMethod method, string path,
        Dictionary<string, string> form, string token,
        CancellationToken cancellationToken)
    {
        using var response = await SendAsync(
            method, path, form, token, cancellationToken);
        await EnsureSuccessAsync(response, cancellationToken);
    }

    private async Task<OAuthTokens> RequestTokensAsync(
        Dictionary<string, string> values,
        CancellationToken cancellationToken)
    {
        values["client_id"] = MemverseOAuth.ClientId;
        using var content = new FormUrlEncodedContent(values);
        using var response = await http.PostAsync(
            MemverseOAuth.TokenEndpoint, content, cancellationToken);
        using var json = await ReadJsonAsync(response, cancellationToken);
        var root = json.RootElement;
        var token = WebApi.JsonApi.ReadString(root, "access_token");
        var refreshToken = WebApi.JsonApi.ReadString(root, "refresh_token");
        if (string.IsNullOrWhiteSpace(token) ||
            string.IsNullOrWhiteSpace(refreshToken))
        {
            throw new JsonException(
                "The Memverse token response did not contain the required tokens.");
        }

        accessToken = token;
        return new OAuthTokens(token, refreshToken);
    }

    private async Task<HttpResponseMessage> SendAsync(HttpMethod method, string path,
        Dictionary<string, string>? form, string token,
        CancellationToken cancellationToken)
    {
        token = accessToken ?? token;
        var response = await SendOnceAsync(method, path, form, token, cancellationToken);
        if (response.StatusCode != System.Net.HttpStatusCode.Unauthorized || state is null)
            return response;

        response.Dispose();
        await refreshLock.WaitAsync(cancellationToken);
        try
        {
            if (accessToken is null || accessToken == token)
            {
                var refreshToken = state.RefreshToken;
                if (string.IsNullOrWhiteSpace(refreshToken))
                    throw new InvalidOperationException("Sign in is required.");

                var tokens = await RefreshTokensAsync(refreshToken, cancellationToken);
                await state.SaveTokensAsync(tokens);
            }
            token = GetAccessToken();
        }
        finally
        {
            refreshLock.Release();
        }
        return await SendOnceAsync(method, path, form, token, cancellationToken);
    }

    private async Task<HttpResponseMessage> SendOnceAsync(HttpMethod method, string path,
        Dictionary<string, string>? form, string token,
        CancellationToken cancellationToken)
    {
        using var request = new HttpRequestMessage(method, path);
        request.Headers.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
        if (form is not null)
            request.Content = new FormUrlEncodedContent(form);
        return await http.SendAsync(request, cancellationToken);
    }

    private static async Task EnsureSuccessAsync(HttpResponseMessage response,
        CancellationToken cancellationToken)
    {
        if (response.IsSuccessStatusCode) return;
        var details = await response.Content.ReadAsStringAsync(cancellationToken);
        throw new HttpRequestException(
            string.IsNullOrWhiteSpace(details) ? response.ReasonPhrase : details,
            null, response.StatusCode);
    }

    private static async Task<JsonDocument> ReadJsonAsync(
        HttpResponseMessage response,
        CancellationToken cancellationToken = default)
    {
        await EnsureSuccessAsync(response, cancellationToken);
        return JsonDocument.Parse(
            await response.Content.ReadAsStringAsync(cancellationToken));
    }

    private string GetAccessToken() =>
        accessToken ?? state?.AccessToken ??
        throw new InvalidOperationException("Sign in is required.");

    private static Verse ParseVerse(JsonElement root)
    {
        var response = WebApi.JsonApi.Unwrap(root);
        return WebApi.VersesResponse.Parse(
            response.ValueKind == JsonValueKind.Array
                ? response.EnumerateArray().Single()
                : response);
    }
}
