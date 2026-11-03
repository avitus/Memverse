using System;
using System.Collections.Generic;
using System.Text;
using MemverseApp.Core.Data;

namespace MemverseApp.Core.Services;

interface ITelemetryService
{
    void TrackException(Exception exception);
    IDisposable? TrackRequest(string name);
    void TrackEvent(string name);
    void TrackMetric(string name, double value);
}

class DefaultTelemetry : ITelemetryService
{
    public static readonly ITelemetryService Instance = new DefaultTelemetry();
    public void TrackException(Exception exception) { }
    public IDisposable? TrackRequest(string name) { return null; }
    public void TrackEvent(string name) { }
    public void TrackMetric(string name, double value) { }
}
