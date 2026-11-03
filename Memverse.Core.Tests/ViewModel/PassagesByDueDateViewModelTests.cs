using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using FluentAssertions;
using MemverseApp.Core.Data;
using MemverseApp.Core.Services;
using MemverseApp.Core.ViewModels;
using Moq;
using Xunit;

namespace MemverseApp.Core.Tests.ViewModel;

public class PassagesByDueDateViewModelTests
{
    [Fact]
    public void CheckDueDates()
    {
        var sunday = new DateTime(2017, 6, 25);
        var verses = Enumerable.Range(0, 11).Select(i => new Memverse { DueDate = sunday.AddDays(i) }).ToList();

        var today = sunday;
        verses[0].GetDueDate(today).Should().Be(Due.Today);
        verses[1].GetDueDate(today).Should().Be(Due.Tomorrow);
        verses[2].GetDueDate(today).Should().Be(Due.Tuesday);
        verses[3].GetDueDate(today).Should().Be(Due.Wednesday);
        verses[4].GetDueDate(today).Should().Be(Due.Thursday);
        verses[5].GetDueDate(today).Should().Be(Due.Friday);
        verses[6].GetDueDate(today).Should().Be(Due.Saturday);
        verses[7].GetDueDate(today).Should().Be(Due.NextWeek);

        today = sunday.AddDays(3); // wednesday
        verses[3].GetDueDate(today).Should().Be(Due.Today);
        verses[4].GetDueDate(today).Should().Be(Due.Tomorrow);
        verses[5].GetDueDate(today).Should().Be(Due.Friday);
        verses[6].GetDueDate(today).Should().Be(Due.Saturday);
        verses[7].GetDueDate(today).Should().Be(Due.Sunday2);
        verses[8].GetDueDate(today).Should().Be(Due.Monday2);
        verses[9].GetDueDate(today).Should().Be(Due.Tuesday2);
        verses[10].GetDueDate(today).Should().Be(Due.NextWeek);
    }

    [Fact]
    public void HomeGroupsActivePassagesInDueOrder()
    {
        var today = new DateTime(2026, 1, 7);
        Memverse Verse(int chapter, int number, int dueDays, string status = "Learning") => new()
        {
            Book = 0,
            Chapter = chapter,
            VerseNumber = number,
            Translation = "KJV",
            Status = status,
            DueDate = today.AddDays(dueDays).AddHours(18)
        };
        var verses = new[]
        {
            Verse(1, 1, 7),
            Verse(2, 1, 6),
            Verse(3, 1, 0),
            Verse(3, 2, -1, "Pending"),
            Verse(4, 1, 1),
            Verse(5, 1, 2),
            Verse(6, 1, 28),
            Verse(7, 1, 0, "Pending")
        };
        var model = new PassagesByDueDateViewModel();

        model.Refresh(verses, today);

        model.Passages.Select(group => group.DueDate).Should().Equal(
            "Today", "Tomorrow", "Friday", "Tuesday", "One Week", "Later");
        model.Passages.Single(group => group.DueDate == "Today")
            .Passages.Select(passage => passage.Reference)
            .Should().Equal("Genesis 3:1-2");

        model.Refresh(new[] { Verse(7, 1, 0, "Pending") }, today);
        model.Passages.Should().BeEmpty();
    }
}
