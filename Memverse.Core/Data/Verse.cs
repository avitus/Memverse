using System;

namespace MemverseApp.Core.Data;

class Verse
{
    public long Id { get;  set; }
    public int Book { get;  set; }
    public int Chapter { get;  set; }
    public int VerseNumber { get;  set; }
    public string? Text { get;  set; }
    public string? Translation { get;  set; }
}
