using System;
using System.Collections.Generic;
using System.Text;

namespace MemverseApp.Core;

class MemverseException : Exception
{
    public MemverseExceptionKind Kind { get; private set; }

    public MemverseException(MemverseExceptionKind kind)
    {
        Kind = kind;
    }
}

enum MemverseExceptionKind
{
    Unknown,
    VerseNotFound
}
