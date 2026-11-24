(async () => {
    if ("serviceWorker" in navigator) {
        try {
            const registration = await navigator.serviceWorker.register("service-worker.js", { updateViaCache: "none" });
            window.memverseGetLastUpdateCheck = () => localStorage.getItem("memverse-last-update-check");
            window.memverseSetLastUpdateCheck = value => localStorage.setItem("memverse-last-update-check", value);
            window.memverseCheckForUpdate = async () => {
                if (!registration.waiting && !registration.installing) {
                    await registration.update();
                }
                const worker = registration.installing;
                if (worker) await new Promise((resolve, reject) => {
                    const onStateChange = () => {
                        if (!["installed", "activated", "redundant"].includes(worker.state)) return;
                        worker.removeEventListener("statechange", onStateChange);
                        if (worker.state === "redundant") reject(new Error("The new version could not be installed."));
                        else resolve();
                    };
                    worker.addEventListener("statechange", onStateChange);
                    onStateChange();
                });
                return Boolean(navigator.serviceWorker.controller && registration.waiting);
            };
            window.memverseApplyUpdate = () => {
                const waitingWorker = registration.waiting;
                if (!waitingWorker) {
                    throw new Error("The update is no longer available. Check for updates again.");
                }

                navigator.serviceWorker.addEventListener("controllerchange", () => window.location.reload(), { once: true });
                waitingWorker.postMessage({ type: "SKIP_WAITING" });
            };
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
