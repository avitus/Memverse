import React, { useEffect, useRef, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { addChapter, addVerse, createVerse, keyFor, reference, searchVerses } from './scripture';

function SearchBox({ query, setQuery, translation, setTranslation, translations, composing, searching }) {
  return <form className="av-search" role="search" aria-label="Find Scripture" onSubmit={e => e.preventDefault()}>
    <label className="av-visually-hidden" htmlFor="verse-query">Reference or words from a verse</label>
    <input id="verse-query" type="search" autoComplete="off" placeholder="Enter a reference or phrase" value={query}
      onChange={e => setQuery(e.target.value)}
      onCompositionStart={() => composing(true)} onCompositionEnd={() => composing(false)} />
    <span role="status" className="av-visually-hidden">{searching ? 'Searching…' : ''}</span>
    <label className="av-translation" data-searching={searching || undefined}>
      <span aria-hidden="true">{translation}</span>
      <span className="av-translation-icon" aria-hidden="true" />
      <select aria-label="Bible translation" value={translation} onChange={e => setTranslation(e.target.value)}>
        {Object.entries(translations).map(([group, options]) => <optgroup key={group} label={group}>
          {options.map(([name, code]) => <option key={code} value={code}>{name}</option>)}
        </optgroup>)}
      </select>
    </label>
  </form>;
}

function AddAction({ scope = 'verse', added, disabled, onClick, label, expanded }) {
  return added
    ? <span className="mv-add-status">✓ In your verses</span>
    : <button type="button" className="mv-add-action" disabled={disabled} aria-label={label}
        aria-expanded={expanded} aria-controls={expanded === undefined ? undefined : 'chapter-confirmation'} onClick={onClick}>
        <span aria-hidden="true">+</span> Add {scope}
      </button>;
}

function Results({ result, query, translation, owned, markOwned, practice }) {
  const [confirm, setConfirm] = useState(false);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [text, setText] = useState('');
  const [created, setCreated] = useState(null);
  const inFlight = useRef(false);
  const verses = created ? [created] : result.verses;
  const pending = verses.filter(v => !owned.has(keyFor(v)));

  async function save(operation) {
    if (inFlight.current) return;
    inFlight.current = true;
    setSaving(true);
    setError('');
    setMessage('');
    try {
      await operation();
    } catch (e) {
      setError('Could not save. Please try again.');
    } finally {
      inFlight.current = false;
      setSaving(false);
    }
  }

  async function saveVerse(verse) {
    const outcome = await addVerse(verse.id);
    markOwned([verse]);
    setMessage(reference(verse) + (outcome === 'Added' ? ' added to your practice.' : ' is already in your verses.'));
  }

  return <>
    {error && <p role="alert" className="av-error">{error}</p>}
    {message && <div role="status" className="av-notice"><div><strong>✓ {message}</strong></div><a href={practice}>Start practicing →</a></div>}
    {verses.length > 0 ? <section className="av-results">
      <div className="av-results-head"><h2 id="results-label">{verses.length} {verses.length === 1 ? 'verse' : 'verses'}</h2>
        {result.chapterParams && <AddAction scope="chapter" added={!pending.length} disabled={saving} expanded={confirm} onClick={() => setConfirm(!confirm)} />}
      </div>
      {confirm && !!pending.length && <div id="chapter-confirmation">
        <strong>Add {pending.length} {translation} {pending.length === 1 ? 'verse' : 'verses'} to your practice?</strong>
        <button type="button" className="mv-add-action" disabled={saving} onClick={() => save(async () => {
          await addChapter(result.chapterParams);
          markOwned(verses);
          setConfirm(false);
          setMessage(query + ' is in your verses.');
        })}>Add {pending.length} {pending.length === 1 ? 'verse' : 'verses'}</button>
        <button type="button" disabled={saving} onClick={() => setConfirm(false)}>Cancel</button>
      </div>}
      <div className="av-verses" role="region" aria-labelledby="results-label" tabIndex={0}>{verses.map(verse =>
        <article key={verse.id}><div className="av-verse-top"><h3>{reference(verse)}</h3>
          <AddAction label={'Add ' + reference(verse)} disabled={saving} added={owned.has(keyFor(verse))} onClick={() => save(() => saveVerse(verse))} />
        </div><p>{verse.text}</p></article>
      )}</div>
    </section> : result.missing ? <form className="av-manual" onSubmit={event => {
      event.preventDefault();
      if (text.trim()) save(async () => {
        const verse = await createVerse(result.missing, translation, text);
        setCreated(verse);
        await saveVerse(verse);
      });
    }}><h2>Enter the verse text</h2><p>{query} · {translation}</p>
      <label htmlFor="missing-text">Copy the exact wording from your selected Bible.</label>
      <textarea id="missing-text" required rows={5} value={text} onChange={e => setText(e.target.value)} />
      <button className="mv-add-action" disabled={saving}>Create and add verse</button>
    </form> : <section><p role="status">No matching verses.</p></section>}
  </>;
}

function AddVerses({ config }) {
  const [query, setQuery] = useState('');
  const [translation, setTranslation] = useState(config.translation);
  const [owned, setOwned] = useState(() => new Set(JSON.parse(config.owned)));
  const [composing, setComposing] = useState(false);
  const [response, setResponse] = useState(null);
  const [retry, setRetry] = useState(0);
  const term = query.trim();
  const searchKey = JSON.stringify([term, translation, retry]);
  const current = !composing && response?.key === searchKey ? response : null;
  useEffect(() => {
    if (!term || composing) return;
    const controller = new AbortController();
    const timer = setTimeout(async () => {
      try {
        const result = await searchVerses(term, translation, controller.signal);
        if (!controller.signal.aborted) setResponse({ key: searchKey, result });
      } catch {
        if (!controller.signal.aborted) setResponse({ key: searchKey, error: true });
      }
    }, 200);
    return () => { clearTimeout(timer); controller.abort(); };
  }, [term, translation, composing, searchKey]);
  return <>
    <header className="av-heading"><h1>Add a verse</h1><a href={config.collection}>My verses →</a></header>
    <SearchBox query={query} setQuery={setQuery} composing={setComposing} translation={translation}
      searching={Boolean(term && !composing && !current)} setTranslation={setTranslation} translations={JSON.parse(config.translations)} />
    {!term || !current ? null
        : current.error ? <p role="alert">We couldn’t search right now. <button onClick={() => setRetry(r => r + 1)}>Search again</button></p>
        : <Results key={searchKey} result={current.result} query={term} translation={translation} owned={owned} practice={config.practice}
            markOwned={items => setOwned(existing => new Set([...existing, ...items.map(keyFor)]))} />}
  </>;
}

const root = document.getElementById('heritage-add-verse');
if (root) createRoot(root).render(<AddVerses config={root.dataset} />);
