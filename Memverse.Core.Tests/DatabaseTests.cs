using Xunit;
using FluentAssertions;
using FluentAssertions.Common;
using System;
using System.Net.Http;
using System.Collections.Generic;
using System.Linq;
using MemverseApp.Core.Data;

namespace MemverseApp.Core.Tests;

public class DatabaseTests
{
    private readonly MemoryDatabase database = new();

    [Fact]
    public async Task CreatedUserShouldBePersisted()
    {
        User user = new User()
        {
            Name = "a",
            Email = "b",
            Id = 1,
            Translation = "d"
        };

        await this.database.SaveUserAsync(user);
        (await this.database.LoadAsync()).User.Should().BeEquivalentTo(user);
    }

    [Fact]
    public async Task CreatedUserShouldBePersistedAcrossSessions()
    {
        User user = new User()
        {
            Name = "a",
            Email = "b",
            Id = 1,
            Translation = "d"
        };
        var store = new MemoryDatabaseStore();

        var database = new MemoryDatabase(store);
        await database.SaveUserAsync(user);
        (await database.LoadAsync()).User.Should().BeEquivalentTo(user);

        database = new MemoryDatabase(store);
        (await database.LoadAsync()).User.Should().BeEquivalentTo(user);
    }

    [Fact]
    public async Task EmptyDatabaseShouldNotHaveUser()
    {
        (await this.database.LoadAsync()).User.Should().Be(null);
    }
}
