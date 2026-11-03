using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MemverseApp.Core.Data;

class User
{
    public long Id { get; set; }
    public string? Name { get; set; }
    public string? Email { get; set; }
    public string? Translation { get; set; }
    public int TargetVersesPerDay { get; set; }
    public DateTime? LastActivityDate { get; set; }
}
