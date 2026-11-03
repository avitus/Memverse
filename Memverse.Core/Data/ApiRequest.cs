using System;
using System.Collections.Generic;
using System.Text;

namespace MemverseApp.Core.Data;

enum ApiRequestKind
{
    DeleteMemverse,
    RateMemverse,
    UpdateUser
}

class ApiRequest
{
    public int Id { get; set; }
    public ApiRequestKind Kind { get; set; }
    public string? Json { get; set; }
    public int RetryCount { get; set; }
}
