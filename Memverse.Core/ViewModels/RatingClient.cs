using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using MemverseApp.Core.Data;

namespace MemverseApp.Core.ViewModels;

static class RatingClient
{
    public static void RateVerse(Memverse memverse, int rating)
    {
        if (rating == 1 || rating == 2)
        {
            UpdateMemverse(memverse, 1, 1);
        }
        else if (memverse.IterationNumber == 1)
        {
            UpdateMemverse(memverse, memverse.IterationNumber + 1, rating == 3 ? 3 : 4);
        }
        else
        {
            var multiplier =
                rating == 3 ? 1.3 :
                rating == 4 ? 1.7 :
                /* x == 5 */ 2.0;
            var newInterval = (int)(memverse.TestInterval.Days * multiplier);
            UpdateMemverse(memverse, memverse.IterationNumber + 1, newInterval);
        }
    }

    private static void UpdateMemverse(Memverse memverse, int iterationNumber, int interval)
    {
        memverse.IterationNumber = iterationNumber;
        memverse.TestInterval = TimeSpan.FromDays(interval);
        memverse.DueDate = DateTime.Today + memverse.TestInterval;
        memverse.LastTest = DateTime.Today;
    }
}
