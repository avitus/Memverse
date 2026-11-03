using MemverseApp.Core.Data;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MemverseApp.Core;

class UserSetupPipeline
{
    private readonly IOfflineOperations database;
    private readonly List<IUserSetupTask> tasks;

    public UserSetupPipeline(
        IOfflineOperations database,
        Func<Task> userSelector,
        Func<Task> translationSelector,
        Func<Task> verseSelector)
    {
        this.database = database;
        this.tasks = new List<IUserSetupTask>()
        {
            new AuthenticateUserTask(userSelector),
            new ChooseTranslationTask(translationSelector),
            new AddVersesTask(verseSelector),
        };
    }

    public async Task ExecuteAsync()
    {
        foreach (var task in this.tasks)
        {
            await task.ExecuteAsync(this.database);
        }
    }

    public static UserSetupDestination GetNextStep(
        User? user,
        string? accessToken,
        string? refreshToken,
        IEnumerable<Data.Memverse> verses)
    {
        if (user == null ||
            string.IsNullOrWhiteSpace(accessToken) ||
            string.IsNullOrWhiteSpace(refreshToken))
            return UserSetupDestination.SignIn;
        if (string.IsNullOrWhiteSpace(user.Translation))
            return UserSetupDestination.ChooseTranslation;
        if (!verses.Any())
            return UserSetupDestination.AddVerses;
        return UserSetupDestination.Complete;
    }
}

interface IUserSetupTask
{
    Task ExecuteAsync(IOfflineOperations database);
}

class AuthenticateUserTask : IUserSetupTask
{
    private readonly Func<Task> userFactory;

    public AuthenticateUserTask(Func<Task> userFactory)
    {
        this.userFactory = userFactory;
    }

    public Task ExecuteAsync(IOfflineOperations database)
    {
        if (database.GetUser() == null)
        {
            return userFactory();
        }

        return Task.FromResult(true);
    }
}

class ChooseTranslationTask : IUserSetupTask
{
    private Func<Task> translationSelector;

    public ChooseTranslationTask(Func<Task> translationSelector)
    {
        this.translationSelector = translationSelector;
    }

    public Task ExecuteAsync(IOfflineOperations database)
    {
        var user = database.GetUser()!;
        if (user.Translation == null)
        {
            return this.translationSelector();
        }

        return Task.FromResult(true);
    }
}

class AddVersesTask : IUserSetupTask
{
    private Func<Task> verseSelector;

    public AddVersesTask(Func<Task> verseSelector)
    {
        this.verseSelector = verseSelector;
    }

    public async Task ExecuteAsync(IOfflineOperations database)
    {
        while (!database.GetMemverses().Any())
        {
            await this.verseSelector();
        }
    }
}

enum UserSetupDestination
{
    SignIn,
    ChooseTranslation,
    AddVerses,
    Complete
}
