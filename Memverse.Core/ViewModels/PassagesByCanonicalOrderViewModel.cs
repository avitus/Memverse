using MemverseApp.Core.Data;

namespace MemverseApp.Core.ViewModels;

sealed class PassagesByCanonicalOrderViewModel
{
    public List<Group> Passages { get; private set; } = [];

    public void Refresh(IEnumerable<Memverse> verses) =>
        Passages = PassageLogic.Consolidate(verses)
            .GroupBy(passage => Bible.Books[passage.First.Book].Name)
            .Select(group => new Group
            {
                Book = group.Key,
                Passages = group.ToList()
            })
            .ToList();

    public sealed class Group
    {
        public string Book { get; set; } = "";
        public IReadOnlyList<Passage> Passages { get; set; } = [];
    }
}
