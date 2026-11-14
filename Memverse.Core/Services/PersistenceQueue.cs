namespace MemverseApp.Core.Services;

sealed class PersistenceQueue
{
    private readonly Queue<(Func<Task> Operation, TaskCompletionSource Completion)> pending = new();
    private bool running;

    public Task Enqueue(Func<Task> operation)
    {
        var completion = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        bool startWorker;
        lock (pending)
        {
            pending.Enqueue((operation, completion));
            startWorker = !running;
            running = true;
        }
        if (startWorker)
            _ = ProcessAsync();
        return completion.Task;
    }

    public Task FlushAsync() => Enqueue(() => Task.CompletedTask);

    private async Task ProcessAsync()
    {
        while (true)
        {
            (Func<Task> Operation, TaskCompletionSource Completion) item;
            lock (pending)
            {
                if (!pending.TryDequeue(out item))
                {
                    running = false;
                    return;
                }
            }
            try
            {
                await item.Operation();
                item.Completion.SetResult();
            }
            catch (Exception exception)
            {
                item.Completion.SetException(exception);
            }
        }
    }
}
