using MemverseApp.Core.Data;

namespace MemverseApp.Core.ViewModels;

sealed class PassagesByDueDateViewModel
{
    public List<Grouping> Passages { get; private set; } = [];

    public void Refresh(IEnumerable<Memverse> verses, DateTime today)
    {
        Passages = PassageLogic.Consolidate(verses)
            .Where(passage => passage.Verses.Any(Passage.IsActive))
            .GroupBy(passage => passage.Verses
                .Where(Passage.IsActive)
                .Min(verse => verse.GetDueDate(today)))
            .OrderBy(group => group.Key)
            .Select(group => new Grouping(group.Key, group.ToList()))
            .ToList();
    }

    public sealed class Grouping(Due due, IReadOnlyList<Passage> passages)
    {
        public string DueDate { get; } = DueDateGroups.GetLabel(due);
        public IReadOnlyList<Passage> Passages { get; } = passages;
    }
}

static class DueDateGroups
{
    public static string GetLabel(Due dueDate) => dueDate switch
    {
        Due.Today => "Today",
        Due.Tomorrow => "Tomorrow",
        Due.Sunday or Due.Sunday2 => "Sunday",
        Due.Monday or Due.Monday2 => "Monday",
        Due.Tuesday or Due.Tuesday2 => "Tuesday",
        Due.Wednesday or Due.Wednesday2 => "Wednesday",
        Due.Thursday or Due.Thursday2 => "Thursday",
        Due.Friday or Due.Friday2 => "Friday",
        Due.Saturday or Due.Saturday2 => "Saturday",
        Due.NextWeek => "One Week",
        Due.TwoWeeks => "Two Weeks",
        Due.ThreeWeeks => "Three Weeks",
        Due.Later => "Later",
        _ => throw new ArgumentOutOfRangeException(nameof(dueDate))
    };
}
