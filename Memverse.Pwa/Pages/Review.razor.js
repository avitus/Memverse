export function preventRatingInput(element) {
    element.addEventListener("keydown", event => {
        if (element.dataset.ratingEnabled === "true" && /^[1-5]$/.test(event.key))
            event.preventDefault();
    });
}

export function scrollToBottom(element) {
    element.scrollTop = element.scrollHeight;
}
