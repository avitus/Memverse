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

public class ReviewVerseViewModelTests
{
    [Fact]
    public void TestFeedbackRegex()
    {
        // words should be split with leading whitespace and hyphens
        var words = Feedback.Split(@"""Quote - hyphen a ");
        words.Should().HaveCount(4);
        words[0].Should().Be(@"""Quote");
        words[1].Should().Be(@" - hyphen");
        words[2].Should().Be(@" a");
        words[3].Should().Be(@" ");

        // except for the last word which can have trailing hyphens
        Feedback.Split(@"The end - ").Last().Should().Be(" end - ");
    }

    [Fact]
    public void ExtraWordsShouldBeErrors()
    {
        var feedback = Feedback.ClassifyText("1 2 3 4", @"1 2 3", revealAnswer: false);
        feedback.Correct.Should().BeFalse();
        feedback.Words.Last().Kind.Should().Be(MatchKind.Error);
    }

    [Fact]
    public void EmptyGuessShouldShowPrompt()
    {
        var feedback = Feedback.ClassifyText(" ", @"1 2 3", revealAnswer: false);
        feedback.Correct.Should().BeFalse();
        feedback.Words.First().Text.Should().Be("Waiting for you to begin typing...");
    }

    [Fact]
    public void RevealAnswerShouldShowActual()
    {
        var feedback = Feedback.ClassifyText(" ", @"1 2 3", revealAnswer: true);
        feedback.Correct.Should().BeFalse();
        GetFeedbackString(feedback).Should().Be("1 2 3");
    }

    [Fact]
    public void TestFeedbackMnenomicNoSpaces()
    {
        var feedback = Feedback.ClassifyText("qh1", @"""Quote - hyphen - 123,000 bar?", revealAnswer: false);
        feedback.Correct.Should().BeFalse();
        feedback.Words.All(w => w.Kind == MatchKind.Correct).Should().BeTrue();

        feedback = Feedback.ClassifyText("qh1b", @"""Quote - hyphen - 123,000 bar?", revealAnswer: false);
        feedback.Correct.Should().BeTrue();
    }

    [Fact]
    public void TestErrorFeedbackMnenomicNoSpaces()
    {
        var feedback = Feedback.ClassifyText("qh12", @"""Quote - hyphen - 123,000 bar?", revealAnswer: false);
        feedback.Words.Last().Kind.Should().Be(MatchKind.Error);

        feedback = Feedback.ClassifyText("qo", @"""Quote - hyphen - 123,000 bar?", revealAnswer: false);
        feedback.Words.Should().HaveCount(2);
        feedback.Words.Last().Kind.Should().Be(MatchKind.Error);
        feedback.Words.Last().Text.Should().Be(" o...");
    }

    [Fact]
    public void TestFeedbackMnenomicWithSingleLettersAndSpaces()
    {
        var feedback = Feedback.ClassifyText("q h 1", @"""Quote - hyphen - 123,000 bar?", revealAnswer: false);
        feedback.Correct.Should().BeFalse();
        feedback.Words.All(w => w.Kind == MatchKind.Correct).Should().BeTrue();

        feedback = Feedback.ClassifyText("q h 1 b", @"""Quote - hyphen - 123,000 bar?", revealAnswer: false);
        feedback.Correct.Should().BeTrue();
    }

    private static string GetFeedbackString(Feedback feedback)
    {
        return string.Join("", feedback.Words.Select(w => w.Text));
    }

    [Fact]
    public void FeedbackShouldNotAssumeMnemonicIfPreviousWordWasSingleLetter()
    {
        var feedback = Feedback.ClassifyText("and i w", @"And I want to", revealAnswer: false);
        GetFeedbackString(feedback).Should().Be("And I w");

        feedback = Feedback.ClassifyText("and i w ", @"And I want to", revealAnswer: false);
        GetFeedbackString(feedback).Should().Be("And I want");

        feedback = Feedback.ClassifyText("a i", @"And I want to", revealAnswer: false);
        GetFeedbackString(feedback).Should().Be("And I");

        feedback = Feedback.ClassifyText("and i w t", @"And I want to", revealAnswer: false);
        GetFeedbackString(feedback).Should().Be("And I want to");

        feedback = Feedback.ClassifyText("a x", @"And I want to", revealAnswer: false);
        GetFeedbackString(feedback).Should().Be("And x");
        feedback.Words.Last().Kind.Should().Be(MatchKind.Error);

        feedback = Feedback.ClassifyText("a i x", @"And I want to", revealAnswer: false);
        GetFeedbackString(feedback).Should().Be("And I x");
        feedback.Words.Last().Kind.Should().Be(MatchKind.Error);
    }

    [Fact]
    public void TestErrorFeedbackMnenomicWithSingleLettersAndSpaces()
    {
        var feedback = Feedback.ClassifyText("i w ", @"I want to", revealAnswer: false);
        GetFeedbackString(feedback).Should().Be("I want");
    }

    [Fact]
    public void TestErrorFeedbackMnenomicWithSingleLettersAndSpaces3()
    {
        var feedback = Feedback.ClassifyText("a x", @"And I want to", revealAnswer: false);
        GetFeedbackString(feedback).Should().Be("And x");
        feedback.Words.Last().Kind.Should().Be(MatchKind.Error);
    }

    [Fact]
    public void TestFeedbackFull()
    {
        var feedback = Feedback.ClassifyText(@"""Quote - hyphen - 123,000 b", @"""Quote - hyphen - 123,000 bar?", revealAnswer: false);
        feedback.Correct.Should().BeFalse();
        feedback.Words.Any(w => w.Kind == MatchKind.Error).Should().BeFalse();
        feedback.Words.Last().Kind.Should().Be(MatchKind.Prefix);

        feedback = Feedback.ClassifyText(@"Quote hyphen 123000 bar", @"""Quote - hyphen - 123,000 bar?", revealAnswer: false);
        feedback.Correct.Should().BeTrue();
    }

    [Fact]
    public void PrefixMatching()
    {
        var feedback = Feedback.ClassifyText(@"""Quote hyp", @"""Quote - hyphen - 123,000 bar?", revealAnswer: false);
        feedback.Words.ElementAt(1).Kind.Should().Be(MatchKind.Prefix);

        feedback = Feedback.ClassifyText(@"""Quote hypp", @"""Quote - hyphen - 123,000 bar?", revealAnswer: false);
        feedback.Words.ElementAt(1).Kind.Should().Be(MatchKind.Error);

        feedback = Feedback.ClassifyText(@"""Quote hyp 123", @"""Quote - hyphen - 123,000 bar?", revealAnswer: false);
        feedback.Words.ElementAt(1).Kind.Should().Be(MatchKind.Error);
        feedback.Words.ElementAt(2).Kind.Should().Be(MatchKind.Prefix);
    }

    [Fact]
    public void FixNextWordWithoutErrors()
    {
        var input = "";
        var actual = @"""Quote - hyphen - 123,000 b";
        input = Feedback.FixNextWord(input, actual);
        input.Should().Be(@"Q");
        input = Feedback.FixNextWord(input, actual);
        input.Should().Be(@"Qh");
        input = Feedback.FixNextWord(input, actual);
        input.Should().Be(@"Qh1");
        input = Feedback.FixNextWord(input, actual);
        input.Should().Be(@"Qh1b");
    }

    [Fact]
    public void FixNextWordWithErrors()
    {
        var input = "a a a a a a";
        var actual = @"""Quote - hyphen - 123,000 b";
        input = Feedback.FixNextWord(input, actual);
        input.Should().Be(@"Q a a a a a");
        input = Feedback.FixNextWord(input, actual);
        input.Should().Be(@"Q h a a a a");
        input = Feedback.FixNextWord(input, actual);
        input.Should().Be(@"Q h 1 a a a");
        input = Feedback.FixNextWord(input, actual);
        input.Should().Be(@"Q h 1 b a a");
        input = Feedback.FixNextWord(input, actual);
        input.Should().Be(@"Q h 1 b");
    }

    [Fact]
    public void FixNextWordWithMixedErrors()
    {
        var input = "a hyphen 123,000 a";
        var actual = @"""Quote - hyphen - 123,000 be";
        input = Feedback.FixNextWord(input, actual);
        input.Should().Be(@"""Quote hyphen 123,000 a");
        input = Feedback.FixNextWord(input, actual);
        input.Should().Be(@"""Quote hyphen 123,000 be");
    }

    [Fact]
    public void FixMnemonicForMispelledFirstWord()
    {
        var input = "qa";
        var actual = @"""Quote - hyphen - 123,000 be";
        input = Feedback.FixNextWord(input, actual);
        input.Should().Be(@"qh");
    }

    [Fact]
    public void FixFullWordForPrefixMatch()
    {
        var input = "qu";
        var actual = @"""Quote - hyphen - 123,000 be";
        input = Feedback.FixNextWord(input, actual);
        input.Should().Be(@"""Quote");
    }

    [Fact]
    public void FixNextLetterForMnemonicWithoutSpaces()
    {
        var input = "Qaaaaa";
        var actual = @"""Quote - hyphen - 123,000 b";
        input = Feedback.FixNextWord(input, actual);
        input.Should().Be(@"Qhaaaa");
        input = Feedback.FixNextWord(input, actual);
        input.Should().Be(@"Qh1aaa");
        input = Feedback.FixNextWord(input, actual);
        input.Should().Be(@"Qh1baa");
        input = Feedback.FixNextWord(input, actual);
        input.Should().Be(@"Qh1b");
    }

    [Theory]
    [InlineData("x", nameof(MatchKind.Error))]
    [InlineData("q", nameof(MatchKind.Correct))]
    [InlineData("q ", nameof(MatchKind.Correct))]
    public void OneDayVerseShouldKeepFeedbackAndBlankUntypedWords(string input, string expectedKind)
    {
        var verse = CreateVerse(1, DateTime.Today);
        verse.TestInterval = TimeSpan.FromDays(1);
        verse.Text = "Quote hyphen last";
        var model = ReviewVersesViewModel.Create([verse], 15, DateTime.Today, _ => { })!;

        model.UpdateInput(input);

        model.FeedbackWords[0].Kind.ToString().Should().Be(expectedKind);
        model.FeedbackWords.Skip(1).Should().OnlyContain(word => word.Kind == MatchKind.None);
        model.FeedbackWords.Skip(1).Select(word => word.Text).Should().Equal(" hyphen", " last");
        model.IsCorrect.Should().BeFalse();
        model.UpdateInput("");
        model.FeedbackWords.Should().HaveCount(3).And.OnlyContain(word => word.Kind == MatchKind.None);
    }

    [Theory]
    [InlineData("t", 1)]
    [InlineData("th", 2)]
    [InlineData("th ", 2)]
    [InlineData("t h", 2)]
    [InlineData("tho", 3)]
    [InlineData("t h o", 3)]
    public void OneDayVerseShouldCompleteEachInitialEvenWhenItLooksLikeAWordPrefix(
        string input, int correctCount)
    {
        var verse = CreateVerse(1, DateTime.Today);
        verse.TestInterval = TimeSpan.FromDays(1);
        verse.Text = "The hand opens";
        var model = ReviewVersesViewModel.Create([verse], 15, DateTime.Today, _ => { })!;

        model.UpdateInput(input);

        model.FeedbackWords.Select(word => word.Text).Should().Equal("The", " hand", " opens");
        model.FeedbackWords.Take(correctCount).Should().OnlyContain(word => word.Kind == MatchKind.Correct);
        model.IsCorrect.Should().Be(correctCount == 3);
    }

    [Fact]
    public void OneDayHintsShouldFixAnIncorrectInitialWithoutExpandingTheInput()
    {
        var verse = CreateVerse(1, DateTime.Today);
        verse.TestInterval = TimeSpan.FromDays(1);
        verse.Text = "The hand opens";
        var model = ReviewVersesViewModel.Create([verse], 15, DateTime.Today, _ => { })!;

        model.UpdateInput("x");
        model.UseHint();
        model.InputText.Should().Be("T");
        model.FeedbackWords.Select(word => word.Kind).Should().Equal(MatchKind.Correct, MatchKind.None, MatchKind.None);
        model.UpdateInput("tx");
        model.UseHint();
        model.InputText.Should().Be("th");
        model.FeedbackWords.Select(word => word.Kind).Should().Equal(MatchKind.Correct, MatchKind.Correct, MatchKind.None);
    }

    [Fact]
    public void ReviewShouldResumePassageAfterVersesRatedToday()
    {
        var today = DateTime.Today;
        var alreadyRated = CreateVerse(1, today.AddDays(1));
        alreadyRated.LastTest = today;
        var due = CreateVerse(2, today);
        var restOfPassage = CreateVerse(3, today.AddDays(10));
        var model = ReviewVersesViewModel.Create([alreadyRated, due, restOfPassage], 15, today, _ => { })!;

        model.CurrentVerse.Should().BeSameAs(due);
        model.Sections.Single().Should().Equal(alreadyRated, due, restOfPassage);
        model.CorrectVerse.Should().BeNull();
    }

    [Fact]
    public void ReviewShouldShowAllCompletedVerses()
    {
        var today = DateTime.Today;
        var first = CreateVerse(1, today);
        var second = CreateVerse(2, today);
        var third = CreateVerse(3, today);
        var model = ReviewVersesViewModel.Create([first, second, third], 15, today, _ => { })!;
        model.Rate(2);
        model.CorrectVerse.Should().BeNull();
        model.UpdateInput(second.Text!);

        model.CurrentVerse.Should().BeSameAs(third);
        model.CurrentSection.Take(model.VerseIndex).Should().Equal(first, second);
    }

    [Fact]
    public void ReviewStartsWithSelectedPassageBeforeApplyingDailyLimit()
    {
        var today = new DateTime(2026, 1, 7);
        var earliest = CreateVerse(1, today.AddDays(-2));
        var next = CreateVerse(3, today.AddDays(-1));
        var selected = CreateVerse(1, today);
        selected.Id = 5;
        selected.Translation = "KJV";
        var model = ReviewVersesViewModel.Create([earliest, next, selected], 1, today, _ => { }, selected.Id)!;

        model.CurrentVerse.Should().BeSameAs(selected);
        model.Sections.Select(section => section[0]).Should().Equal(selected, earliest);
        model.Rate(1).Should().BeTrue();
        model.CurrentVerse.Should().BeSameAs(earliest);
    }

    [Fact]
    public void ReviewSelectedPassageSkipsVersesAlreadyRatedToday()
    {
        var today = new DateTime(2026, 1, 7);
        var other = CreateVerse(1, today.AddDays(-1));
        var alreadyRated = CreateVerse(3, today.AddDays(1));
        alreadyRated.LastTest = today;
        var due = CreateVerse(4, today);
        var restOfPassage = CreateVerse(6, today.AddDays(10));
        var ratedLater = CreateVerse(5, today.AddDays(1));
        ratedLater.LastTest = restOfPassage.LastTest = today.AddHours(12);
        var model = ReviewVersesViewModel.Create(
            [other, alreadyRated, due, restOfPassage, ratedLater], 2, today, _ => { }, alreadyRated.Id)!;

        model.CurrentVerse.Should().BeSameAs(due);
        model.PreviousVerse.Should().BeSameAs(alreadyRated);
        model.Sections[0].Should().Equal(alreadyRated, due, ratedLater, restOfPassage);
        model.Sections[1].Should().Equal(other);
        model.UpdateInput(due.Text!);
        (model.CurrentVerse, model.CorrectVerse, model.IsCorrect, model.InputText).Should().Be((restOfPassage, due, false, ""));
        model.Rate(5);
        model.GetRating(due).Should().Be(5);
    }

    [Fact]
    public void ReviewShouldKeepCompletedVerseAvailableForRating()
    {
        var first = CreateVerse(1, DateTime.Today);
        var second = CreateVerse(2, DateTime.Today);
        var third = CreateVerse(3, DateTime.Today);
        var changes = new List<VerseReviewChange>();
        var model = ReviewVersesViewModel.Create([first, second, third], 15, DateTime.Today, changes.AddRange)!;
        model.UpdateInput(first.Text!);
        (model.CurrentVerse, model.CorrectVerse, model.IsCorrect).Should().Be((second, first, false));
        changes.Should().ContainSingle().Which.Verse.Should().BeSameAs(first);
        model.Rate(5).Should().BeTrue();
        model.GetRating(first).Should().Be(5);
        model.GetRating(second).Should().BeNull();
        model.CorrectVerse.Should().BeNull();
        model.UpdateInput(second.Text!);
        model.CorrectVerse.Should().BeSameAs(second);
        model.UpdateInput("wrong");
        model.CorrectVerse.Should().BeNull();
        model.UpdateInput(third.Text!);
        (model.CorrectVerse, model.IsCorrect).Should().Be((third, true));
        model.Rate(4).Should().BeTrue();
        model.IsCorrect.Should().BeTrue();
        model.Rate(4).Should().BeFalse();
        changes.Where(change => change.Rating is not null)
            .Select(change => (change.Verse.Id, change.Rating)).Should().Equal((1L, 5), (2L, 4), (3L, 4));
    }

    [Fact]
    public async Task RatingShouldAdvanceAndCompleteWhileSavesArePending()
    {
        var verse = CreateVerse(1, DateTime.Today);
        var other = CreateVerse(3, DateTime.Today);
        var save = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var writes = new List<long>();
        var database = new Mock<IDatabase>();
        database.Setup(db => db.SaveMemversesAsync(It.IsAny<IEnumerable<Memverse>>(), false, It.IsAny<ApiRequest[]>()))
            .Returns((IEnumerable<Memverse> verses, bool replaceAll, ApiRequest[] mutations) =>
            {
                writes.Add(verses.Single().Id);
                mutations.Single().Id = writes.Count;
                return save.Task;
            });
        var state = new MemverseState(database.Object);
        var offline = new OfflineClient(state);
        var model = ReviewVersesViewModel.Create([verse, other], 15, DateTime.Today, offline.QueueReviewChanges)!;

        model.Rate(2).Should().BeTrue();
        model.CurrentVerse.Should().BeSameAs(other);
        model.Rate(2).Should().BeFalse();
        state.FlushPersistenceAsync().IsCompleted.Should().BeFalse();
        writes.Should().Equal(verse.Id);
        save.SetResult();
        await state.FlushPersistenceAsync();
        writes.Should().Equal(verse.Id, other.Id);
        state.Mutations.Should().HaveCount(2);
    }

    [Fact]
    public async Task ReviewShouldPersistProgressAndSaveToggledRatings()
    {
        var first = CreateVerse(1, DateTime.Today);
        var second = CreateVerse(2, DateTime.Today);
        first.IterationNumber = second.IterationNumber = 1;
        var other = CreateVerse(4, DateTime.Today);
        var database = new MemoryDatabase();
        var state = new MemverseState(database);
        var offline = new OfflineClient(state);
        await state.SaveVersesAsync([first, second, other], replaceAll: true);
        var model = ReviewVersesViewModel.Create(state.Verses, 15, DateTime.Today, offline.QueueReviewChanges)!;
        model.Rate(2).Should().BeTrue();
        model.ToggleRating(first, 2);
        model.GetRating(first).Should().BeNull();
        model.ToggleRating(first, 3);
        model.UpdateInput("Verse");
        model.UseHint();
        await state.FlushPersistenceAsync();
        var reloaded = new MemverseState(database);
        await reloaded.LoadAsync();
        var reloadedOffline = new OfflineClient(reloaded);
        var resumed = ReviewVersesViewModel.Create(
            reloaded.Verses, 1, DateTime.Today, reloadedOffline.QueueReviewChanges, first.Id)!;
        (resumed.CurrentVerse.Id, resumed.IsCorrect, resumed.InputText).Should().Be((second.Id, false, ""));
        resumed.Sections.Should().HaveCount(2);
        model.Rate(4).Should().BeTrue();
        ReviewVersesViewModel.Create(state.Verses, 15, DateTime.Today, offline.QueueReviewChanges)!.CurrentVerse.Should().BeSameAs(other);
        await state.FlushPersistenceAsync();
        var saved = await database.LoadAsync();
        saved.Memverses.Should().HaveCount(3).And.BeEquivalentTo(state.Verses);
        saved.Mutations.Should().Equal(state.Mutations);
        state.Mutations.Select(request => (request.Id, request.Json)).Should().Equal((1, "{\"Id\":1,\"Rating\":3}"), (2, "{\"Id\":2,\"Rating\":4}"));
    }

    private static Memverse CreateVerse(int verseNumber, DateTime dueDate) =>
        new()
        {
            Id = verseNumber,
            Book = 0,
            Chapter = 1,
            VerseNumber = verseNumber,
            Text = $"Verse {verseNumber}",
            Translation = "NIV",
            Status = "Learning",
            DueDate = dueDate
        };
}
