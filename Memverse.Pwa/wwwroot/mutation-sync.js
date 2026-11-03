self.addEventListener("sync", event => {
    if (event.tag === "memverse-mutations") {
        event.waitUntil(replayMutationsWhenClosed());
    }
});

async function replayMutationsWhenClosed() {
    const windows = await self.clients.matchAll({
        type: "window",
        includeUncontrolled: true
    });
    if (windows.length > 0) {
        return;
    }

    let accessToken = await getAccessToken();

    const mutations = await self.memverseDb.getAll("mutations");
    mutations.sort((left, right) => left.id - right.id);
    for (const mutation of mutations) {
        try {
            try {
                await sendMutation(mutation, accessToken);
            } catch (error) {
                if (error.status !== 401) {
                    throw error;
                }
                accessToken = await refreshAccessToken();
                await sendMutation(mutation, accessToken);
            }
            await self.memverseDb.delete("mutations", mutation.id);
        } catch (error) {
            mutation.retryCount = (mutation.retryCount ?? 0) + 1;
            await self.memverseDb.put("mutations", mutation);
            throw error;
        }
    }
}

async function sendMutation(mutation, accessToken) {
    const payload = JSON.parse(mutation.json);
    const id = payload.Id;
    const headers = {
        "Authorization": `Bearer ${accessToken}`
    };
    let method;
    let path;
    let body;

    switch (mutation.kind) {
        case 0:
            method = "DELETE";
            path = `memverses/${id}`;
            break;
        case 1:
            method = "PATCH";
            path = `memverses/${id}`;
            body = new URLSearchParams({ q: payload.Rating.toString() });
            break;
        case 2:
            method = "PUT";
            path = `users/${id}`;
            body = new URLSearchParams({
                "user[translation]": payload.Translation,
                "user[time_allocation]": payload.TimeAllocation.toString()
            });
            break;
        default:
            throw new Error(`Unknown Memverse mutation kind: ${mutation.kind}`);
    }

    const response = await fetch(
        new URL(path, self.memverseConfig.apiBaseUrl),
        { method, headers, body });
    if (!response.ok && !(method === "DELETE" && response.status === 404)) {
        const error = new Error(
            `Memverse background sync failed with HTTP ${response.status}.`);
        error.status = response.status;
        throw error;
    }
}

async function getAccessToken() {
    const accessToken = await self.memverseDb.get("settings", "accessToken");
    if (!accessToken?.value) {
        throw new Error("Memverse background sync requires a saved access token.");
    }

    return accessToken.value;
}

async function refreshAccessToken() {
    const refreshToken = await self.memverseDb.get("settings", "refreshToken");
    if (!refreshToken?.value) {
        throw new Error("Memverse background sync requires sign-in.");
    }

    const body = new URLSearchParams({
        grant_type: "refresh_token",
        client_id: self.memverseConfig.clientId,
        refresh_token: refreshToken.value
    });
    const response = await fetch(
        self.memverseConfig.tokenEndpoint,
        {
            method: "POST",
            headers: {
                "Content-Type": "application/x-www-form-urlencoded"
            },
            body
        });
    if (!response.ok) {
        throw new Error(
            `Memverse token refresh failed with HTTP ${response.status}.`);
    }

    const tokens = await response.json();
    if (!tokens.access_token || !tokens.refresh_token) {
        throw new Error("Memverse returned an invalid token refresh response.");
    }

    await self.memverseDb.putAll("settings", [
        { key: "accessToken", value: tokens.access_token },
        { key: "refreshToken", value: tokens.refresh_token }
    ]);
    return tokens.access_token;
}
