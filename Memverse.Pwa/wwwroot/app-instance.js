(async () => {
    if ("serviceWorker" in navigator) {
        try {
            await navigator.serviceWorker.register("service-worker.js");
        } catch (error) {
            console.error("The Memverse service worker could not be registered.", error);
        }
    }

    if (!navigator.locks) {
        document.getElementById("app").innerHTML = `
            <main class="single-instance">
                <div class="card">
                    <h1>Browser not supported</h1>
                    <p>Memverse requires Web Locks to protect its local data.</p>
                </div>
            </main>`;
        return;
    }

    const channel = "BroadcastChannel" in window
        ? new BroadcastChannel("memverse-ui-instance")
        : null;
    if (channel) {
        channel.onmessage = event => {
            if (event.data === "focus") {
                window.focus();
            }
        };
    }

    await navigator.locks.request(
        "memverse-ui-instance",
        { ifAvailable: true },
        async lock => {
            if (!lock) {
                channel?.postMessage("focus");
                document.getElementById("app").innerHTML = `
                    <main class="single-instance">
                        <div class="card">
                            <h1>Memverse is already open</h1>
                            <p>Continue in the existing Memverse window.</p>
                            <button class="btn btn-primary" onclick="location.reload()">
                                Try again
                            </button>
                        </div>
                    </main>`;
                return;
            }

            await Blazor.start();
            await new Promise(() => {});
        });
})();
