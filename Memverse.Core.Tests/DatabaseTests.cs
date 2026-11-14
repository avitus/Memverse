using Xunit;
using FluentAssertions;
using FluentAssertions.Common;
using System;
using System.Net.Http;
using System.Collections.Generic;
using System.Linq;
using MemverseApp.Core.Data;
using MemverseApp.Core.Services;
using Moq;

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

    [Fact]
    public async Task ServerSyncShouldWaitForQueuedReviewSaves()
    {
        var save = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var storage = new Mock<IDatabase>();
        var verse = new Memverse { Id = 1 };
        storage.Setup(db => db.LoadAsync())
            .ReturnsAsync(new DatabaseSnapshot(null, "local-test-token", null, [verse], []));
        storage.Setup(db => db.SaveMemversesAsync(It.IsAny<IEnumerable<Memverse>>(), false, It.IsAny<ApiRequest[]>()))
            .Returns((IEnumerable<Memverse> verses, bool replaceAll, ApiRequest[] mutations) =>
            {
                mutations.Single().Id = 1;
                return save.Task;
            });
        storage.Setup(db => db.DeleteMutationAsync(1)).Returns(Task.CompletedTask);
        var state = new MemverseState(storage.Object);
        await state.LoadAsync();
        var client = new Mock<IMemverseClient>();
        client.Setup(api => api.RateMemverseAsync(1, 5, "local-test-token", It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);
        var online = new OnlineOperations(state, client.Object,
            new BackgroundSynchronizer(state, client.Object), DefaultTelemetry.Instance);
        var offline = new OfflineClient(state);
        offline.QueueReviewChanges([new VerseReviewChange(verse, 5)]);

        var sync = online.FlushBackgroundTasksAsync();
        sync.IsCompleted.Should().BeFalse();
        client.Verify(api => api.RateMemverseAsync(1, 5, "local-test-token", It.IsAny<CancellationToken>()), Times.Never);
        save.SetResult();
        await sync;

        client.Verify(api => api.RateMemverseAsync(1, 5, "local-test-token", It.IsAny<CancellationToken>()), Times.Once);
        state.Mutations.Should().BeEmpty();
    }
}
