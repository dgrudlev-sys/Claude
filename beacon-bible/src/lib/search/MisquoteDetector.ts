import levenshtein from 'fast-levenshtein';

export interface MisquoteResult {
  isMisquote: true;
  misquotedText: string;
  explanation: string;
  actualVerses: ActualVerse[];
  topicSlug?: string;
}

interface ActualVerse {
  reference: string;
  text: string;
  bookCode: string;
  chapter: number;
  verse: number;
}

// Curated misquote database — expanded over time via community contribution
const MISQUOTES: Array<{
  misquoted: string;
  explanation: string;
  actualVerses: ActualVerse[];
  topicSlug?: string;
}> = [
  {
    misquoted: "god helps those who help themselves",
    explanation: "This phrase is often attributed to Benjamin Franklin, not Scripture. The Bible actually teaches that God's strength is made perfect in our weakness — the opposite of self-reliance.",
    topicSlug: 'strength',
    actualVerses: [
      { reference: "2 Corinthians 12:9", text: "My grace is sufficient for you, for my power is made perfect in weakness.", bookCode: "2CO", chapter: 12, verse: 9 },
      { reference: "Proverbs 3:5-6", text: "Trust in the Lord with all your heart and lean not on your own understanding.", bookCode: "PRO", chapter: 3, verse: 5 },
      { reference: "Psalm 121:2", text: "My help comes from the Lord, the Maker of heaven and earth.", bookCode: "PSA", chapter: 121, verse: 2 },
    ],
  },
  {
    misquoted: "money is the root of all evil",
    explanation: "The actual verse is 'the love of money is a root of all kinds of evil' (1 Timothy 6:10). Money itself is neutral — it's the obsession with it that causes harm.",
    topicSlug: 'money',
    actualVerses: [
      { reference: "1 Timothy 6:10", text: "For the love of money is a root of all kinds of evil.", bookCode: "1TI", chapter: 6, verse: 10 },
    ],
  },
  {
    misquoted: "god won't give you more than you can handle",
    explanation: "1 Corinthians 10:13 is about temptation, not general suffering. It says God won't let you be tempted beyond what you can bear — but it doesn't promise life won't be overwhelming. In fact, Paul says he was 'burdened beyond strength' (2 Cor 1:8).",
    topicSlug: 'strength',
    actualVerses: [
      { reference: "1 Corinthians 10:13", text: "No temptation has overtaken you except what is common to mankind.", bookCode: "1CO", chapter: 10, verse: 13 },
      { reference: "2 Corinthians 1:8-9", text: "We were under great pressure, far beyond our ability to endure... that we might not rely on ourselves but on God.", bookCode: "2CO", chapter: 1, verse: 8 },
    ],
  },
  {
    misquoted: "spare the rod spoil the child",
    explanation: "This is a paraphrase, not a direct quote. Proverbs 13:24 says 'Whoever spares the rod hates their children, but the one who loves their children is careful to discipline them.'",
    topicSlug: 'parenting',
    actualVerses: [
      { reference: "Proverbs 13:24", text: "Whoever spares the rod hates their children, but the one who loves their children is careful to discipline them.", bookCode: "PRO", chapter: 13, verse: 24 },
    ],
  },
  {
    misquoted: "to thine own self be true",
    explanation: "This is from Shakespeare's Hamlet (Act 1, Scene 3), spoken by Polonius — not from the Bible.",
    actualVerses: [
      { reference: "Galatians 2:20", text: "I have been crucified with Christ and I no longer live, but Christ lives in me.", bookCode: "GAL", chapter: 2, verse: 20 },
    ],
  },
  {
    misquoted: "this too shall pass",
    explanation: "This phrase comes from Persian Sufi poetry, not Scripture. The Bible does speak about the temporary nature of suffering.",
    topicSlug: 'hope',
    actualVerses: [
      { reference: "2 Corinthians 4:17", text: "For our light and momentary troubles are achieving for us an eternal glory that far outweighs them all.", bookCode: "2CO", chapter: 4, verse: 17 },
      { reference: "Psalm 30:5", text: "Weeping may stay for the night, but rejoicing comes in the morning.", bookCode: "PSA", chapter: 30, verse: 5 },
    ],
  },
  {
    misquoted: "the lion shall lie down with the lamb",
    explanation: "The actual verse says 'wolf', not 'lion'. Isaiah 11:6 reads: 'The wolf will live with the lamb, the leopard will lie down with the goat.'",
    actualVerses: [
      { reference: "Isaiah 11:6", text: "The wolf will live with the lamb, the leopard will lie down with the goat.", bookCode: "ISA", chapter: 11, verse: 6 },
    ],
  },
  {
    misquoted: "hate the sin love the sinner",
    explanation: "This phrase is commonly attributed to St. Augustine or Gandhi, not the Bible directly. The concept of hating sin while loving people is biblical, but this exact phrasing isn't Scripture.",
    topicSlug: 'love',
    actualVerses: [
      { reference: "Romans 5:8", text: "But God demonstrates his own love for us in this: while we were still sinners, Christ died for us.", bookCode: "ROM", chapter: 5, verse: 8 },
      { reference: "Jude 1:22-23", text: "Be merciful to those who doubt; save others by snatching them from the fire.", bookCode: "JUD", chapter: 1, verse: 22 },
    ],
  },
  {
    misquoted: "cleanliness is next to godliness",
    explanation: "This phrase is commonly attributed to John Wesley but does not appear in the Bible. It may have origins in ancient Hebrew writings.",
    actualVerses: [
      { reference: "Psalm 51:10", text: "Create in me a pure heart, O God, and renew a steadfast spirit within me.", bookCode: "PSA", chapter: 51, verse: 10 },
    ],
  },
];

function normalize(text: string): string {
  return text.toLowerCase().replace(/[^a-z0-9 ]/g, '').trim();
}

export function detectMisquote(query: string): MisquoteResult | null {
  const normalized = normalize(query);
  if (normalized.length < 10) return null;

  for (const entry of MISQUOTES) {
    const dist = levenshtein.get(normalized, entry.misquoted);
    const maxLen = Math.max(normalized.length, entry.misquoted.length);
    const similarity = 1 - dist / maxLen;

    if (similarity > 0.75) {
      return {
        isMisquote: true,
        misquotedText: entry.misquoted,
        explanation: entry.explanation,
        actualVerses: entry.actualVerses,
        topicSlug: entry.topicSlug,
      };
    }
  }

  return null;
}
