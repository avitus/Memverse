using Xunit;
using FluentAssertions;
using System;
using System.Net.Http;
using System.Linq;

namespace MemverseApp.Core.Tests;

[Trait("Category", "Integration")]
public class ApiTests(ApiFixture fixture) : IClassFixture<ApiFixture>
{
    [Fact(Explicit = true)]
    public async Task AuthenticateWithCredentials()
    {
        var client = await fixture.GetClientAsync();
        var me = await client.GetIdentityAsync();
        me.Name.Should().Contain("Kayle");
    }

    [Fact(Explicit = true)]
    public async Task UpdateUserTranslationShouldSucceed()
    {
        var client = await fixture.GetClientAsync();
        var me = await client.GetIdentityAsync();
        var newTimeAllocation = me.TargetVersesPerDay == 5 ? 10 : 5;
        var newTranslation = me.Translation == "NIV" ? "NNV" : "NIV";
        me.TargetVersesPerDay = newTimeAllocation;
        me.Translation = newTranslation;

        await client.UpdateUserAsync(me);

        me = await client.GetIdentityAsync();
        me.TargetVersesPerDay.Should().Be(newTimeAllocation);
        me.Translation.Should().Be(newTranslation);
    }

    [Fact(Explicit = true)]
    public async Task AddingUpdatingAndDeletingVersesShouldSucceed()
    {
        var client = await fixture.GetClientAsync();
        await DeleteAllMemverses(client);

        var verse = await client.GetVerseAsync(42, 3, 17);
        var memverse = await client.AddMemverseAsync(verse);
        memverse.IterationNumber.Should().Be(1);
        memverse.DueDate.Should().BeOnOrBefore(DateTime.Today);
        memverse.Status.Should().Be("Learning");
        memverse.Reference.Should().Be("John 3:17");
        memverse.TestInterval.Should().Be(TimeSpan.FromDays(1));
        (await client.GetMemversesAsync()).Should().HaveCount(1);

        (await client.RateMemverseAsync(memverse, 3)).Should().Be(memverse);
        memverse.LastTest.Should().Be(DateTime.Today);
        memverse.DueDate.Should().BeAfter(DateTime.Today);
        memverse.IterationNumber.Should().Be(2);
        memverse.TestInterval.Should().Be(TimeSpan.FromDays(4));

        await client.AddMemverseAsync(await client.GetVerseAsync(42, 3, 16));
        (await client.GetMemversesAsync()).Should().HaveCount(2);

        await DeleteAllMemverses(client);
    }

    private static async Task DeleteAllMemverses(MemverseApiClient client)
    {
        var memverses = (await client.GetMemversesAsync()).ToList();
        foreach (var memverse in memverses)
        {
            await client.DeleteMemverseAsync(memverse.Id);
        }

        (await client.GetMemversesAsync()).Should().HaveCount(0);
    }

    [Fact(Explicit = true)]
    public async Task LookupVerseByReferenceShouldSucceed()
    {
        var client = await fixture.GetClientAsync();
        var verse = await client.GetVerseAsync(42, 3, 16);
        verse.Book.Should().Be(43);
        verse.Chapter.Should().Be(3);
        verse.VerseNumber.Should().Be(16);

        var user = await client.GetIdentityAsync();
        verse.Translation.Should().Be(user.Translation);
    }

    [Fact(Explicit = true)]
    public async Task GetAvailableTranslationsShouldReturnAllTranslations()
    {
        var client = await fixture.GetClientAsync();
        var translations = (await client.GetAvailableTranslationsAsync()).SelectMany(l => l.Translations).ToList();

        translations.Should().Match(ts => ts.Any(t =>
            t.Name!.Equals("New International Version (1984)", StringComparison.OrdinalIgnoreCase) &&
            t.Abbreviation!.Equals("NIV", StringComparison.OrdinalIgnoreCase)));

        translations.Should().Match(ts => ts.Any(t =>
            t.Name!.Equals("English Standard Version (2011)", StringComparison.OrdinalIgnoreCase) &&
            t.Abbreviation!.Equals("ESV", StringComparison.OrdinalIgnoreCase)));
    }
}

public sealed class ApiFixture : IDisposable
{
    private HttpClient? http;
    private Task<MemverseApiClient>? clientTask;

    internal Task<MemverseApiClient> GetClientAsync() => clientTask ??= CreateClientAsync();

    private async Task<MemverseApiClient> CreateClientAsync()
    {
        var accessToken = Environment.GetEnvironmentVariable("MEMVERSE_ACCESS_TOKEN")
            ?? await PkceTestLogin.GetAccessTokenAsync();
        http = new HttpClient
        {
            BaseAddress = new Uri("https://www.memverse.com/api/v1/")
        };
        var client = new MemverseApiClient(http);
        client.SetAccessToken(accessToken);
        return client;
    }

    public void Dispose() => http?.Dispose();
}
