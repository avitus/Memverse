using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.CompilerServices;

namespace MemverseApp.Core.Data;

[DebuggerDisplay("{DebuggerDisplay}")]
class Memverse
{
    private string DebuggerDisplay
    {
        get { return AbbreviatedReference + " " + DueDate; }
    }

    public long Id { get; set; }
    public long VerseId { get; set; }

    public string? Status { get; set; }

    public DateTime? LastTest { get; set; }
    public DateTime DueDate { get; set; }
    public TimeSpan TestInterval { get; set; }
    public int IterationNumber { get; set; }

    public int Book { get; set; }
    public int Chapter { get; set; }
    public int VerseNumber { get; set; }
    public string? Text { get; set; }
    public string? Translation { get; set; }

    public string AbbreviatedReference { get { return Bible.Books[Book].Abbreviation + " " + NumberReference; } }
    public string Reference { get { return Bible.Books[Book].Name + " " + NumberReference; } }
    public string NumberReference { get { return Chapter + ":" + VerseNumber; } }
    public bool IsActive { get { return this.Status != "Pending"; } }

    public void ToggleStatus()
    {
        this.Status =
            IsActive
            ? "Pending"
            : this.TestInterval.Days >= 30
            ? "Memorized"
            : "Learning";
    }

    public Due GetDueDate(DateTime today)
    {
        today = today.Date;
        var dueDate = this.DueDate.Date;
        var baseWeekday = today.DayOfWeek > dueDate.DayOfWeek ? Due.Sunday2 : Due.Sunday;
        if (dueDate <= today) return Due.Today;
        else if (dueDate <= today.AddDays(1)) return Due.Tomorrow;
        else if (dueDate <= today.AddDays(6)) return (Due)(dueDate.DayOfWeek + (int)baseWeekday);
        else if (dueDate <= today.AddDays(13)) return Due.NextWeek;
        else if (dueDate <= today.AddDays(20)) return Due.TwoWeeks;
        else if (dueDate <= today.AddDays(27)) return Due.ThreeWeeks;
        else return Due.Later;
    }

    public void Apply(Verse verse)
    {
        this.VerseId = verse.Id;
        this.Book = verse.Book - 1;
        this.Chapter = verse.Chapter;
        this.Text = verse.Text;
        this.VerseNumber = verse.VerseNumber;
        this.Translation = verse.Translation;
    }

}

enum Due
{
    Today,
    Tomorrow,

    Sunday,
    Monday,
    Tuesday,
    Wednesday,
    Thursday,
    Friday,
    Saturday,
    Sunday2,
    Monday2,
    Tuesday2,
    Wednesday2,
    Thursday2,
    Friday2,
    Saturday2,

    NextWeek,
    TwoWeeks,
    ThreeWeeks,
    Later,
}
