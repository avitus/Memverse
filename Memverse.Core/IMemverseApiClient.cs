using System;
using System.Linq;
using System.Threading.Tasks;
using MemverseApp.Core.Data;
using System.Collections.Generic;

namespace MemverseApp.Core;

interface IMemverseApiClient
{
    Task<User> GetIdentityAsync();
    Task UpdateUserAsync(User user);

    Task<Language[]> GetAvailableTranslationsAsync();

    Task<Verse> GetVerseAsync(long id);
    Task<Verse> GetVerseAsync(int book, int chapter, int verse);

    Task<IEnumerable<Memverse>> GetMemversesAsync();
    Task<Memverse> AddMemverseAsync(Verse verse);
    Task DeleteMemverseAsync(long id);
    Task<Memverse> RateMemverseAsync(Memverse memverse, int rating);
}
