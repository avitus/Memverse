using MemverseApp.Core.Data;

namespace MemverseApp.Core.ViewModels;

sealed class PassageDetailsViewModel
{
    public long? OpenId { get; private set; }
    public HashSet<long> SelectedIds { get; } = [];
    public bool Busy { get; private set; }
    public string? Message { get; private set; }
    public bool Succeeded { get; private set; }

    public void ToggleDetails(Passage passage)
    {
        OpenId = OpenId == passage.First.Id ? null : passage.First.Id;
        SelectedIds.Clear();
    }

    public void Select(long id, bool selected)
    {
        if (selected)
            SelectedIds.Add(id);
        else
            SelectedIds.Remove(id);
    }

    public IReadOnlyList<Memverse> Begin(IEnumerable<Memverse> verses)
    {
        Busy = true;
        Message = null;
        return verses.Where(verse => SelectedIds.Contains(verse.Id)).ToList();
    }

    public void Complete(string? error, bool closeDetails = false)
    {
        Busy = false;
        Message = error ?? "Changes saved.";
        Succeeded = error is null;
        if (!closeDetails)
            return;

        SelectedIds.Clear();
        OpenId = null;
    }
}
