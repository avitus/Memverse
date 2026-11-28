import React, { Fragment, useEffect, useRef, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { flushSync } from 'react-dom';
import { PassageWord } from './PassageWord';

function VerseWords({ tokens, verseNumber, onComplete }) {
  const [answers, setAnswers] = useState({});
  const [hints, setHints] = useState([]);
  const inputs = useRef([]);
  const timer = useRef();
  const focusFrame = useRef();
  useEffect(() => () => {
    clearTimeout(timer.current);
    cancelAnimationFrame(focusFrame.current);
  }, []);

  function reveal(indices, duration) {
    clearTimeout(timer.current);
    setHints(indices);
    timer.current = setTimeout(() => setHints([]), duration);
  }

  function enter(index, value) {
    const correct = window.flexibleTextMatch(tokens[index].word, value.trim());
    const answer = { value, correct };
    setHints([]);
    if (correct) {
      // Wait until the browser finishes handling this edit before focusing
      // another input. Its native caret scroll can override preventScroll.
      flushSync(() => setAnswers(previous => ({ ...previous, [index]: answer })));
      const next = inputs.current.slice(index + 1).find(Boolean) || inputs.current.find(Boolean);
      if (next) focusFrame.current = requestAnimationFrame(() => next.focus({ preventScroll: true }));
      else onComplete();
    } else {
      setAnswers(previous => ({ ...previous, [index]: answer }));
    }
  }

  let blankNumber = 0;
  return tokens.map(({ word, blank }, i) => {
    if (blank) blankNumber++;
    return <Fragment key={i}>{i > 0 && ' '}{blank
      ? <PassageWord word={word} editing={!answers[i]?.correct}
          value={hints.includes(i) ? word : answers[i]?.value || ''}
          inputProps={{
            ref: element => { inputs.current[i] = element; },
            name: word, className: 'blank-word',
            'aria-label': `Verse ${verseNumber}, blank ${blankNumber}`,
            onChange: event => {
              if (event.nativeEvent.isComposing) {
                const value = event.target.value;
                setAnswers(previous => ({ ...previous, [i]: { value, correct: false } }));
              } else enter(i, event.target.value);
            },
            onCompositionEnd: event => enter(i, event.currentTarget.value),
            onKeyDown: event => {
              if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
                event.preventDefault();
                if (event.key === 'ArrowDown') reveal([i], 1100);
                else reveal(tokens.map((_, index) => index), 2000);
              }
            }
          }} />
      : word}</Fragment>;
  });
}

window.mountHeritageVerseWords = function (host, tokens, verseNumber, onComplete) {
  const root = createRoot(host);
  flushSync(() => root.render(<VerseWords {...{ tokens, verseNumber, onComplete }} />));
  return () => root.unmount();
};
