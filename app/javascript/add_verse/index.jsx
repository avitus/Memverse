import React, { useEffect, useRef, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { addChapter, addVerse, createVerse, keyFor, reference, searchVerses } from './scripture';

const suggestions = [['John 3:16', 'God’s love'], ['Psalm 23', 'The Lord is my shepherd'], ['Psalm 46:1', 'Strength in trouble']];

function SearchBox({ query, setQuery, translation, setTranslation, translations, composing, busy }) {
  const [open, setOpen] = useState(false);
  return <form className="mv-discovery" aria-label="Find Scripture" role="search" onSubmit={e => e.preventDefault()}>
    <label htmlFor="verse-query">Reference or words from a verse</label>
    <input id="verse-query" type="text" autoComplete="off" placeholder="e.g. John 3:16 or “my shepherd”" value={query}
      aria-describedby="search-hint" onChange={e => setQuery(e.target.value)}
      onCompositionStart={() => composing(true)} onCompositionEnd={() => composing(false)} />
    <div className="mv-discovery-meta"><span id="search-hint">{busy ? 'Searching…' : 'Verses appear as you type.'}</span>
      <button type="button" onClick={() => setOpen(!open)} aria-expanded={open} aria-controls="translation-options">
        <strong>{translation}</strong> · {open ? 'Close' : 'Change'}
      </button>
    </div>
    {open && <div id="translation-options"><label>Bible translation
      <select value={translation} onChange={e => setTranslation(e.target.value)}>
        {Object.entries(translations).map(([group, options]) => <optgroup key={group} label={group}>
          {options.map(([name, code]) => <option key={code} value={code}>{name}</option>)}
        </optgroup>)}
      </select></label></div>}
    <p>One verse, a passage (John 3:16–18), or a chapter (Psalm 23).</p>
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

function Guidance({ searching }) {
  return <aside className={'av-guide' + (searching ? ' quiet' : '')}>
    {!searching && <span className="eyebrow">Your first verse</span>}
    <h2>{searching ? 'Make it your own.' : <>A small beginning.<br />A lasting habit.</>}</h2>
    <details key={String(searching)} open={!searching}><summary>A little guidance</summary><ol>
      <li><strong>Find words that matter.</strong><p>Search a reference you know or a few words you remember.</p></li>
      <li><strong>Read, then add.</strong><p>Check the wording and translation before adding it to your verses.</p></li>
      <li><strong>Make time to practice.</strong><p>Memverse helps you review your verses over time.</p></li>
    </ol></details>
    <p className="av-tip">There’s no need to build your whole list today. Start with one or two verses.</p>
  </aside>;
}

function Results({ result, query, translation, owned, markOwned, practice }) {
  const [page, setPage] = useState(0);
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
    {message && <div role="status" className="av-notice"><div><strong>✓ {message}</strong><small>Begin now, or keep adding verses.</small></div><a href={practice}>Start practicing →</a></div>}
    {verses.length > 0 ? <section aria-label="Search results">
      <div className="av-results-head"><div><span className="eyebrow">{translation} · {verses.length} {verses.length === 1 ? 'verse' : 'verses'}</span>
        <h2>{result.chapter ? query : verses.length === 1 ? 'Your verse' : query}</h2></div>
        {result.chapterParams && <AddAction scope="chapter" added={!pending.length} disabled={saving} expanded={confirm} onClick={() => setConfirm(!confirm)} />}
      </div>
      {confirm && !!pending.length && <div id="chapter-confirmation">
        <strong>Add {pending.length} {translation} {pending.length === 1 ? 'verse' : 'verses'} to your practice?</strong>
        <p>Verses already in your list will be skipped.</p>
        <button type="button" className="mv-add-action" disabled={saving} onClick={() => save(async () => {
          await addChapter(result.chapterParams);
          markOwned(verses);
          setConfirm(false);
          setMessage(query + ' is in your verses.');
        })}>Add {pending.length} {pending.length === 1 ? 'verse' : 'verses'}</button>
        <button type="button" disabled={saving} onClick={() => setConfirm(false)}>Cancel</button>
      </div>}
      <div className="av-verses">{verses.slice(page * 10, page * 10 + 10).map(verse =>
        <article key={verse.id}><div className="av-verse-top"><h3>{reference(verse)}</h3>
          <AddAction label={'Add ' + reference(verse)} disabled={saving} added={owned.has(keyFor(verse))} onClick={() => save(() => saveVerse(verse))} />
        </div><p>{verse.text}</p></article>
      )}</div>
      {verses.length > 10 && <div className="av-pagination"><button disabled={!page} onClick={() => setPage(page - 1)}>← Previous</button>
        <span>{page * 10 + 1}–{Math.min((page + 1) * 10, verses.length)} of {verses.length}</span>
        <button disabled={(page + 1) * 10 >= verses.length} onClick={() => setPage(page + 1)}>Next →</button></div>}
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
    </form> : <section><h2>No matching verses</h2><p>Try another reference or a few words from the verse.</p></section>}
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
    <header className="av-heading"><div><span className="eyebrow">Build your practice</span><h1>Add a verse</h1>
      <p>Start with words you want to carry with you.</p></div><a href={config.collection}>My verses →</a></header>
    <div className="av-layout"><div>
      <SearchBox query={query} setQuery={setQuery} composing={setComposing} translation={translation} setTranslation={setTranslation}
        translations={JSON.parse(config.translations)} busy={!!term && !current && !composing} />
      {!term ? <section className="av-start"><span className="eyebrow">A place to begin</span><h2>One verse is a good start.</h2>
        <p>Choose a familiar verse, or explore one of these passages.</p><div className="av-suggestions">
          {suggestions.map(([ref, caption]) => <button key={ref} onClick={() => setQuery(ref)}><span><strong>{ref}</strong><small>{caption}</small></span><span aria-hidden="true">→</span></button>)}
        </div><a href="/popular_verses">Browse popular verses →</a></section>
        : !current ? <p role="status">Finding your verses…</p>
        : current.error ? <p role="alert">We couldn’t search right now. <button onClick={() => setRetry(r => r + 1)}>Search again</button></p>
        : <Results key={searchKey} result={current.result} query={term} translation={translation} owned={owned} practice={config.practice}
            markOwned={items => setOwned(existing => new Set([...existing, ...items.map(keyFor)]))} />}
    </div><Guidance searching={!!term} /></div>
  </>;
}

const root = document.getElementById('heritage-add-verse');
if (root) createRoot(root).render(<AddVerses config={root.dataset} />);
