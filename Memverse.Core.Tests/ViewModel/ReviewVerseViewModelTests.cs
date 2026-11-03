using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using FluentAssertions;
using MemverseApp.Core.Data;
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

    [Fact]
    public void ReviewShouldResumePassageAfterVersesRatedToday()
    {
        var today = DateTime.Today;
        var alreadyRated = CreateVerse(1, today.AddDays(1));
        alreadyRated.LastTest = today;
        var due = CreateVerse(2, today);
        var restOfPassage = CreateVerse(3, today.AddDays(10));
        var model = new ReviewVersesViewModel();

        model.Initialize([alreadyRated, due, restOfPassage], 15, today);

        model.CurrentVerse.Should().BeSameAs(due);
        model.Sections.Single().Should().Equal(due, restOfPassage);
    }

    [Fact]
    public void ReviewShouldShowOnlyTheImmediatelyPreviousVerse()
    {
        var today = DateTime.Today;
        var first = CreateVerse(1, today);
        var second = CreateVerse(2, today);
        var third = CreateVerse(3, today);
        var model = new ReviewVersesViewModel();
        model.Initialize([first, second, third], 15, today);
        model.BeginRating(1).Should().BeTrue();
        model.CompleteRating();
        model.BeginRating(1).Should().BeTrue();
        model.CompleteRating();

        model.CurrentVerse.Should().BeSameAs(third);
        model.PreviousVerse.Should().BeSameAs(second);
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
        var model = new ReviewVersesViewModel();

        model.Initialize([earliest, next, selected], 1, today, selected.Id);

        model.CurrentVerse.Should().BeSameAs(selected);
        model.Sections.Select(section => section[0]).Should().Equal(selected, earliest);
        model.BeginRating(1).Should().BeTrue();
        model.CompleteRating();
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
        var restOfPassage = CreateVerse(5, today.AddDays(10));
        var model = new ReviewVersesViewModel();

        model.Initialize([other, alreadyRated, due, restOfPassage], 15, today, alreadyRated.Id);

        model.CurrentVerse.Should().BeSameAs(due);
        model.PreviousVerse.Should().BeSameAs(alreadyRated);
        model.Sections[0].Should().Equal(due, restOfPassage);
        model.Sections[1].Should().Equal(other);
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
