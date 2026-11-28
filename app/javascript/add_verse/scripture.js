async function request(path, options) {
  const response = await fetch(path, options);
  if (!response.ok) throw new Error('Request failed');
  return response.json();
}

function lookup(path, params, signal) {
  return request(path + '?' + new URLSearchParams(params), { signal, headers: { Accept: 'application/json' } });
}

function post(path, params) {
  return request(path, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content || ''
    },
    body: JSON.stringify(params)
  });
}

export const keyFor = verse => [verse.book_index, verse.chapter, verse.versenum].join(':');
export const reference = verse => (verse.book === 'Psalms' ? 'Psalm' : verse.book) + ' ' + verse.chapter + ':' + verse.versenum;

export async function searchVerses(query, tl, signal) {
  const normalized = query.trim().replace(/[–—]/g, '-');
  const single = window.parseVerseRef(normalized);
  if (single) {
    const verse = await lookup('/lookup_verse.json', { bk: single.bk, ch: single.ch, vs: single.vs, tl }, signal);
    return verse ? { verses: [verse] } : { verses: [], missing: single };
  }
  const passage = window.parsePassageRef(normalized);
  if (!passage) {
    const matches = await lookup('/search_verse.json', { searchParams: normalized + ' ' + tl }, signal);
    return { verses: matches.filter(v => v.translation === tl) };
  }

  const params = { bk: passage.bk, ch: passage.ch, tl };
  const chapter = window.validChapterRef(normalized);
  const range = chapter ? params : { ...params, vs_start: passage.vs_start, vs_end: passage.vs_end };
  const [verses, complete] = await Promise.all([
    lookup('/lookup_passage.json', range, signal),
    chapter ? lookup('/chapter_available.json', params, signal) : false
  ]);
  return { verses: verses.filter(v => v.versenum > 0), chapter, chapterParams: complete ? params : null };
}

export async function addVerse(id) {
  const result = await post('/add/' + id, {});
  if (!['Added', 'Previously Added', 'Added in another translation'].includes(result.msg)) throw new Error('Verse could not be added');
  return result.msg;
}

export async function addChapter(params) {
  const result = await post('/add_chapter.json', params);
  if (result.msg !== 'Added Chapter') throw new Error('Chapter could not be added');
}

export async function createVerse(ref, tl, text) {
  const attributes = { book: ref.bk, book_index: ref.bi, chapter: ref.ch, versenum: ref.vs, translation: tl, text: window.cleanseVerseText(text) };
  const result = await post('/verses.json', { verse: attributes });
  if (result.msg === 'Success') return { ...attributes, id: result.verse_id };
  // Another reader may already have supplied the missing text.
  const existing = await lookup('/lookup_verse.json', { bk: ref.bk, ch: ref.ch, vs: ref.vs, tl });
  if (existing) return existing;
  throw new Error(result.errors?.join(' ') || 'The verse could not be created.');
}
