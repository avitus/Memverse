import React, { useLayoutEffect, useRef } from 'react';

// The hidden answer sizes the slot. Both the draft and the accepted word are
// painted by the same text element, on the paragraph's own baseline.
export function PassageWord({ word, value, editing, inputProps }) {
  const ink = useRef(null);
  // A matching prefix wraps exactly like the answer, even in a narrow column.
  // For other guesses, follow the input's horizontal scroll so edits stay visible.
  const scrollDraft = editing && !word.toLowerCase().startsWith(value.toLowerCase());
  useLayoutEffect(() => {
    if (!scrollDraft) ink.current.scrollLeft = 0;
  }, [scrollDraft]);
  return <span className="passage-word recall-word" data-word={word}>
    <span className="recall-ink" aria-hidden={editing || undefined} ref={ink}
      style={scrollDraft ? { whiteSpace: 'pre' } : undefined}>{editing ? value : word}</span>
    {editing && <input {...inputProps} value={value} autoComplete="off" spellCheck={false}
      onScroll={event => { if (scrollDraft && ink.current) ink.current.scrollLeft = event.currentTarget.scrollLeft; }} />}
  </span>;
}
