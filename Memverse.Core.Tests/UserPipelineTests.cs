using FluentAssertions;
using MemverseApp.Core.Data;
using Xunit;
using System.Threading.Tasks;
using System.Linq;
using System;

namespace MemverseApp.Core.Tests;

public class UserPipelineTests
{
    private readonly MemoryOfflineOperations database = new();

    private static Task FailureTask()
    {
        var source = new TaskCompletionSource<object>();
        source.SetException(new Exception());
        return source.Task;
    }

    [Fact]
    public void AuthenticateUserTaskShouldRunIfNecessary()
    {
        var task = new AuthenticateUserTask(FailureTask);
        task.ExecuteAsync(database).Status.Should().Be(TaskStatus.Faulted);

        database.CreateUser(new User() { Name = "a" });
        task.ExecuteAsync(database).Status.Should().Be(TaskStatus.RanToCompletion);
    }

    [Fact]
    public void ChooseTranslationTaskShouldRunIfNecessary()
    {
        database.CreateUser(new User() { Name = "a" });
        var task = new ChooseTranslationTask(FailureTask);
        task.ExecuteAsync(database).Status.Should().Be(TaskStatus.Faulted);

        database.CreateUser(new User() { Name = "a", Translation = "niv" });
        task.ExecuteAsync(database).Status.Should().Be(TaskStatus.RanToCompletion);
    }

    [Fact]
    public void AddVersesTaskShouldRunIfNecessary()
    {
        var task = new AddVersesTask(FailureTask);
        task.ExecuteAsync(database).Status.Should().Be(TaskStatus.Faulted);

        database.AddMemverse(new Memverse());
        task.ExecuteAsync(database).Status.Should().Be(TaskStatus.RanToCompletion);
    }
}
