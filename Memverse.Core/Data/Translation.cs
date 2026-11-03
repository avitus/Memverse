using System.Diagnostics;

namespace MemverseApp.Core.Data;

[DebuggerDisplay("{DebuggerDisplay}")]
class Translation
{
    public string? Name { get; set; }
    public string? Abbreviation { get; set; }
    private string DebuggerDisplay { get { return Abbreviation + " " + Name; } }
}

[DebuggerDisplay("{DebuggerDisplay}")]
class Language
{
    public string Name { get; set; } = null!;
    public string? Abbreviation { get; set; }
    public Translation[] Translations { get; set; } = null!;

    private string DebuggerDisplay { get { return Abbreviation + " " + Name; } }
}
