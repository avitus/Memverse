/******************************************************************************
 * Voice-specific text matching for voice review / voice practice
 *
 * Wraps the global flexibleTextMatch (from memverse_lib.js) with an
 * additional homophone check. This keeps the battle-tested typed-review
 * matching untouched while allowing the voice pipeline to accept
 * speech-to-text homophone transcriptions as correct.
 ******************************************************************************/

/******************************************************************************
 * Homophone dictionary
 *
 * Maps each word to an object of its homophones for quick lookup.
 * When speech-to-text transcribes a word as a homophone of the expected
 * word, we accept it as correct since the user spoke the right sound.
 *
 * All keys and values are lowercase.
 ******************************************************************************/
var HOMOPHONES = {
    "there": {"their": true, "they're": true},
    "their": {"there": true, "they're": true},
    "they're": {"there": true, "their": true},
    "through": {"threw": true, "thru": true},
    "threw": {"through": true, "thru": true},
    "thru": {"through": true, "threw": true},
    "know": {"no": true},
    "no": {"know": true},
    "hear": {"here": true},
    "here": {"hear": true},
    "peace": {"piece": true},
    "piece": {"peace": true},
    "soul": {"sole": true},
    "sole": {"soul": true},
    "son": {"sun": true},
    "sun": {"son": true},
    "whole": {"hole": true},
    "hole": {"whole": true},
    "holy": {"wholly": true},
    "wholly": {"holy": true},
    "altar": {"alter": true},
    "alter": {"altar": true},
    "prophet": {"profit": true},
    "profit": {"prophet": true},
    "reign": {"rain": true, "rein": true},
    "rain": {"reign": true, "rein": true},
    "rein": {"reign": true, "rain": true},
    "pray": {"prey": true},
    "prey": {"pray": true},
    "right": {"write": true, "rite": true},
    "write": {"right": true, "rite": true},
    "rite": {"right": true, "write": true},
    "way": {"weigh": true},
    "weigh": {"way": true},
    "one": {"won": true},
    "won": {"one": true},
    "see": {"sea": true},
    "sea": {"see": true},
    "him": {"hymn": true},
    "hymn": {"him": true},
    "heal": {"heel": true},
    "heel": {"heal": true},
    "night": {"knight": true},
    "knight": {"night": true},
    "born": {"borne": true},
    "borne": {"born": true},
    "die": {"dye": true},
    "dye": {"die": true},
    "great": {"grate": true},
    "grate": {"great": true},
    "flee": {"flea": true},
    "flea": {"flee": true},
    "raised": {"razed": true},
    "razed": {"raised": true},
    "hour": {"our": true},
    "our": {"hour": true},
    "knot": {"not": true},
    "not": {"knot": true},
    "be": {"bee": true},
    "bee": {"be": true},
    "by": {"buy": true, "bye": true},
    "buy": {"by": true, "bye": true},
    "bye": {"by": true, "buy": true},
    "for": {"four": true, "fore": true},
    "four": {"for": true, "fore": true},
    "fore": {"for": true, "four": true},
    "to": {"too": true, "two": true},
    "too": {"to": true, "two": true},
    "two": {"to": true, "too": true},
    "in": {"inn": true},
    "inn": {"in": true},
    "i": {"eye": true},
    "eye": {"i": true},
    "we": {"wee": true},
    "wee": {"we": true},
    "meat": {"meet": true},
    "meet": {"meat": true},
    "read": {"reed": true},
    "reed": {"read": true},
    "lead": {"led": true},
    "led": {"lead": true},
    "would": {"wood": true},
    "wood": {"would": true},
    "which": {"witch": true},
    "witch": {"which": true},
    "where": {"wear": true, "ware": true},
    "wear": {"where": true, "ware": true},
    "ware": {"where": true, "wear": true}
};

/******************************************************************************
 * Strip trailing and leading punctuation from a word for homophone comparison
 ******************************************************************************/
function voiceStripPunctuation(word) {
    return word.replace(/^[^a-zA-Z']+|[^a-zA-Z']+$/g, '');
}

/******************************************************************************
 * Check whether two words are homophones
 *
 * @param {string} wordA - first word (may include punctuation)
 * @param {string} wordB - second word (may include punctuation)
 * @returns {boolean}
 ******************************************************************************/
function isHomophone(wordA, wordB) {
    var a = voiceStripPunctuation(wordA).toLowerCase();
    var b = voiceStripPunctuation(wordB).toLowerCase();
    return !!(HOMOPHONES[a] && HOMOPHONES[a][b]);
}

/******************************************************************************
 * Voice-aware flexible text match
 *
 * Delegates to the global flexibleTextMatch first (handles case, apostrophes,
 * quotes, scrub fallback). If that fails, checks the homophone dictionary.
 *
 * @param {string} correctWord - the expected word from the verse
 * @param {string} userInput   - the word from the user's speech
 * @returns {boolean}
 ******************************************************************************/
function voiceFlexibleTextMatch(correctWord, userInput) {
    // Let the standard matcher handle the common cases
    if (flexibleTextMatch(correctWord, userInput)) {
        return true;
    }
    // Fall back to homophone check
    return isHomophone(correctWord, userInput);
}
