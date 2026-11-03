using Xunit;
using FluentAssertions;
using FluentAssertions.Common;
using System;
using System.Net.Http;
using System.Collections.Generic;
using System.Linq;
using MemverseApp.Core.Data;

namespace MemverseApp.Core.Tests;

public class MemverseCollectionTests
{
    private static MemverseCollection CreateCollection(params Memverse[] verses)
    {
        return new MemverseCollection(verses);
    }

    private static Memverse CreateVerse(int book, int chapter, int verse)
    {
        return new Memverse() { Book = book, Chapter = chapter, VerseNumber = verse };
    }

    [Fact]
    public void NewCollectionShouldBeEmpty()
    {
        var collection = CreateCollection();

        collection.GetPassages().Should().BeEmpty();
    }

    [Fact]
    public void AdjacentVersesShouldMerge1()
    {
        var collection = CreateCollection();

        collection.AddMemverse(CreateVerse(0, 1, 1));
        collection.GetPassages().Should().HaveCount(1);
        collection.AddMemverse(CreateVerse(0, 1, 2));
        collection.GetPassages().Should().HaveCount(1);
    }

    [Fact]
    public void AdjacentVersesShouldMerge2()
    {
        var collection = CreateCollection(CreateVerse(0, 1, 1), CreateVerse(0, 1, 2));

        collection.GetPassages().Should().HaveCount(1);
    }

    [Fact]
    public void SeparateVersesShouldNotMerge()
    {
        var collection = CreateCollection(CreateVerse(0, 1, 1), CreateVerse(0, 1, 3));

        collection.GetPassages().Should().HaveCount(2);
    }

    [Fact]
    public void AdjacentVersesShouldMerge3()
    {
        var collection = CreateCollection(CreateVerse(0, 1, 1), CreateVerse(0, 1, 3));

        collection.AddMemverse(CreateVerse(0, 1, 2));
        collection.GetPassages().Should().HaveCount(1);
    }

    [Fact]
    public void AdjacentVersesShouldMerge4()
    {
        var collection = CreateCollection();
        collection.AddMemverse(CreateVerse(0, 1, 2));
        collection.AddMemverse(CreateVerse(0, 1, 1));

        collection.GetPassages().Should().HaveCount(1);
    }

    [Fact]
    public void VersesShouldBeSorted()
    {
        var collection = CreateCollection();
        collection.AddMemverse(CreateVerse(2, 1, 1));
        collection.AddMemverse(CreateVerse(1, 1, 1));
        collection.AddMemverse(CreateVerse(0, 2, 1));
        collection.AddMemverse(CreateVerse(0, 1, 10));
        collection.AddMemverse(CreateVerse(0, 1, 9));
        collection.AddMemverse(CreateVerse(0, 1, 2));
        collection.AddMemverse(CreateVerse(0, 1, 1));

        var passages = collection.GetPassages().ToList();
        passages[0].Verses[0].Book.Should().Be(0);
        passages[1].Verses[0].Book.Should().Be(0);
        passages[2].Verses[0].Book.Should().Be(0);
        passages[3].Verses[0].Book.Should().Be(1);
        passages[4].Verses[0].Book.Should().Be(2);

        passages[0].Verses[0].Chapter.Should().Be(1);
        passages[1].Verses[0].Chapter.Should().Be(1);
        passages[2].Verses[0].Chapter.Should().Be(2);
        passages[3].Verses[0].Chapter.Should().Be(1);
        passages[4].Verses[0].Chapter.Should().Be(1);

        passages[0].Verses[0].VerseNumber.Should().Be(1);
        passages[1].Verses[0].VerseNumber.Should().Be(9);
        passages[2].Verses[0].VerseNumber.Should().Be(1);
        passages[3].Verses[0].VerseNumber.Should().Be(1);
        passages[4].Verses[0].VerseNumber.Should().Be(1);
    }

    [Fact]
    public void GetPreviousVerseShouldSucceed()
    {
        var collection = CreateCollection();

        var verse1 = CreateVerse(0, 1, 1);
        var verse2 = CreateVerse(0, 1, 2);
        collection.AddMemverse(verse1);
        collection.AddMemverse(verse2);

        collection.GetPreviousVerse(verse1).Should().BeNull();
        collection.GetPreviousVerse(verse2).Should().Be(verse1);
    }
}
