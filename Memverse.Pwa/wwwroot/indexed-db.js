const databaseName = "memverse-pwa";
const databaseVersion = 3;
const stores = ["users", "memverses", "mutations", "settings"];

function openDatabase() {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open(databaseName, databaseVersion);
        request.onupgradeneeded = () => {
            const database = request.result;
            if (request.oldVersion < 2 &&
                database.objectStoreNames.contains("mutations")) {
                database.deleteObjectStore("mutations");
            }
            if (request.oldVersion < 3 &&
                database.objectStoreNames.contains("statusOverrides")) {
                database.deleteObjectStore("statusOverrides");
            }
            for (const store of stores) {
                if (!database.objectStoreNames.contains(store)) {
                    const options = {
                        keyPath: store === "settings" ? "key" : "id"
                    };
                    if (store === "mutations") {
                        options.autoIncrement = true;
                    }
                    database.createObjectStore(store, options);
                }
            }
        };
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
        request.onblocked = () => reject(new Error("The Memverse database upgrade was blocked."));
    });
}

function requestResult(request) {
    return new Promise((resolve, reject) => {
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
    });
}

function transactionComplete(transaction) {
    return new Promise((resolve, reject) => {
        transaction.oncomplete = () => resolve();
        transaction.onerror = () => reject(transaction.error);
        transaction.onabort = () =>
            reject(transaction.error ?? new Error("The IndexedDB transaction was aborted."));
    });
}

async function registerMutationSync() {
    if (!("serviceWorker" in navigator)) {
        return;
    }

    try {
        const registration = await navigator.serviceWorker.ready;
        if ("sync" in registration) {
            await registration.sync.register("memverse-mutations");
        }
    } catch (error) {
        console.warn("Background mutation sync could not be registered.", error);
    }
}

globalThis.memverseDb = {
    async get(storeName, key) {
        const database = await openDatabase();
        try {
            const transaction = database.transaction(storeName, "readonly");
            return await requestResult(transaction.objectStore(storeName).get(key));
        } finally {
            database.close();
        }
    },

    async getAll(storeName) {
        const database = await openDatabase();
        try {
            const transaction = database.transaction(storeName, "readonly");
            return await requestResult(transaction.objectStore(storeName).getAll());
        } finally {
            database.close();
        }
    },

    async put(storeName, value) {
        const database = await openDatabase();
        try {
            const transaction = database.transaction(storeName, "readwrite");
            transaction.objectStore(storeName).put(value);
            await transactionComplete(transaction);
        } finally {
            database.close();
        }
    },

    async putAll(storeName, values) {
        const database = await openDatabase();
        try {
            const transaction = database.transaction(storeName, "readwrite");
            const store = transaction.objectStore(storeName);
            for (const value of values) {
                store.put(value);
            }
            await transactionComplete(transaction);
        } finally {
            database.close();
        }
    },

    async addMutation(value) {
        const database = await openDatabase();
        try {
            const transaction = database.transaction("mutations", "readwrite");
            const completion = transactionComplete(transaction);
            const mutation = { ...value };
            delete mutation.id;
            const id = await requestResult(
                transaction.objectStore("mutations").add(mutation));
            await completion;
            registerMutationSync();
            return id;
        } finally {
            database.close();
        }
    },

    async replaceAllAndAddMutation(storeName, values, value) {
        const database = await openDatabase();
        try {
            const transaction = database.transaction(
                [storeName, "mutations"], "readwrite");
            const completion = transactionComplete(transaction);
            const store = transaction.objectStore(storeName);
            store.clear();
            for (const item of values) {
                store.put(item);
            }
            const mutation = { ...value };
            delete mutation.id;
            const id = await requestResult(
                transaction.objectStore("mutations").add(mutation));
            await completion;
            registerMutationSync();
            return id;
        } finally {
            database.close();
        }
    },

    async replaceAll(storeName, values) {
        const database = await openDatabase();
        try {
            const transaction = database.transaction(storeName, "readwrite");
            const store = transaction.objectStore(storeName);
            store.clear();
            for (const value of values) {
                store.put(value);
            }
            await transactionComplete(transaction);
        } finally {
            database.close();
        }
    },

    async delete(storeName, key) {
        const database = await openDatabase();
        try {
            const transaction = database.transaction(storeName, "readwrite");
            transaction.objectStore(storeName).delete(key);
            await transactionComplete(transaction);
        } finally {
            database.close();
        }
    },

    async clearAll() {
        const database = await openDatabase();
        try {
            const transaction = database.transaction(stores, "readwrite");
            for (const store of stores) {
                transaction.objectStore(store).clear();
            }
            await transactionComplete(transaction);
        } finally {
            database.close();
        }
    }
};
