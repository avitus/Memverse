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

public class AddVerseViewModelTests
{
    private static AddVerseViewModel CreateViewModel()
    {
        var mock = new Mock<IOnlineOperations>();
        mock.Setup(o => o.GetVerseAsync(It.IsAny<int>(), It.IsAny<int>(), It.IsAny<int>())).Returns(
            Task.FromResult(new Verse() { }));
        return new AddVerseViewModel(mock.Object, null, null, DefaultTelemetry.Instance);
    }

    [Fact]
    public void VerifyDefaults()
    {
        var vm = CreateViewModel();

        vm.Books.Count.Should().Be(66);
        vm.Chapters.Should().BeNull();
        vm.Stage.Should().Be(AddVerseStage.ChooseBook);
        vm.SelectedBook.Should().BeNull();
        vm.SelectedChapter.Should().NotHaveValue();

        vm.CanAddSelectedVerses.Should().BeFalse();
        vm.CanChooseChapter.Should().BeFalse();
        vm.SelectAllEnabled.Should().Be(false);
        vm.SelectedVerses.Should().BeNull();
        vm.Verses.Should().BeNull();
    }

    [Fact]
    public void StageShouldChangeWhenBookIsSelected()
    {
        var vm = CreateViewModel();

        vm.SelectedBook = vm.Books.First();

        vm.Stage.Should().Be(AddVerseStage.ChooseChapter);
        vm.Chapters!.Count().Should().Be(vm.SelectedBook!.ChapterEndings.Length);
        vm.SelectedChapter.Should().NotHaveValue();
        vm.CanChooseChapter.Should().BeTrue();
    }

    [Fact]
    public void StageShouldChangeWhenChapterIsSelected()
    {
        var vm = CreateViewModel();

        vm.SelectedBook = vm.Books.First();
        vm.SelectedChapter = 1;

        vm.Stage.Should().Be(AddVerseStage.ChooseVerses);
        vm.SelectAllEnabled.Should().Be(true);
        vm.Verses.Should().NotBeEmpty();
    }

    [Fact]
    public void ValuesShouldResetWhenStageSwitchesBackToChooseBook()
    {
        var vm = CreateViewModel();

        vm.SelectedBook = vm.Books.First();
        vm.SelectedChapter = 1;
        vm.SelectedVerses = new List<object>() { 1 };
        vm.Stage = AddVerseStage.ChooseBook;

        vm.Chapters.Should().BeNull();
        vm.SelectedBook.Should().BeNull();
        vm.SelectedChapter.Should().NotHaveValue();


        vm.CanAddSelectedVerses.Should().BeFalse();
        vm.CanChooseChapter.Should().BeFalse();
        vm.SelectAllEnabled.Should().Be(false);
        vm.SelectedVerses.Should().BeNull();
        vm.Verses.Should().BeNull();
    }

    [Fact]
    public void SelectingBookWithSingleChapterShouldAlsoSetSelectedChapter()
    {
        var vm = CreateViewModel();

        vm.SelectedBook = vm.Books.First(b => b.ChapterEndings.Length == 1);

        vm.SelectedChapter.Should().Be(1);
        vm.Stage.Should().Be(AddVerseStage.ChooseVerses);
    }

    [Fact]
    public void SelectingBookWithSingleChapterShouldAlwaysSetStageToChapterSelected()
    {
        var vm = CreateViewModel();

        vm.SelectedBook = vm.Books.First(b => b.ChapterEndings.Length == 1);
        vm.Stage = AddVerseStage.ChooseChapter;

        vm.Stage.Should().Be(AddVerseStage.ChooseVerses);
    }
}
