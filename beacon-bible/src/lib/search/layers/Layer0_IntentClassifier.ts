export type IntentType = 'reference' | 'phrase' | 'emotional' | 'thematic' | 'question' | 'entity' | 'unknown';

export interface Intent {
  type: IntentType;
  topicSlug?: string;
  confidence: number;
  normalizedQuery: string;
}

// Question prefixes that signal thematic search
const QUESTION_PREFIXES = [
  'what does the bible say about',
  'what does god say about',
  'what does scripture say about',
  'bible verses about',
  'verses about',
  'scripture about',
];

// Emotional state keywords → topic slugs
const EMOTIONAL_MAPPINGS: Record<string, string> = {
  anxious: 'anxiety', anxiety: 'anxiety', worried: 'anxiety', worry: 'anxiety',
  scared: 'fear', afraid: 'fear', fearful: 'fear', fear: 'fear',
  depressed: 'depression', sad: 'grief', grieving: 'grief', grief: 'grief',
  lonely: 'loneliness', alone: 'loneliness', isolated: 'loneliness',
  angry: 'anger', anger: 'anger', frustrated: 'anger',
  hopeless: 'hope', lost: 'hope', hopeful: 'hope', hope: 'hope',
  grateful: 'gratitude', thankful: 'gratitude', gratitude: 'gratitude',
  forgiveness: 'forgiveness', forgive: 'forgiveness', unforgiven: 'forgiveness',
  healing: 'healing', sick: 'healing', illness: 'healing', heal: 'healing',
  love: 'love', marriage: 'marriage', divorce: 'divorce',
  death: 'death', dying: 'death', mourning: 'grief',
  strength: 'strength', weak: 'strength', tired: 'strength',
  peace: 'peace', calm: 'peace', troubled: 'peace',
  faith: 'faith', doubt: 'doubt', believe: 'faith',
  prayer: 'prayer', praying: 'prayer', pray: 'prayer',
  money: 'money', finances: 'money', debt: 'money', wealth: 'money',
  wisdom: 'wisdom', wise: 'wisdom', foolish: 'wisdom',
  purpose: 'purpose', calling: 'purpose', direction: 'purpose',
  identity: 'identity', worth: 'identity', value: 'identity',
};

// Reference patterns — presence of any signals Layer 1 routing
const REFERENCE_PATTERN = /\b\d?\s?[a-zA-Z]+\s+\d+:\d+/;
const CHAPTER_ONLY_PATTERN = /\b\d?\s?[a-zA-Z]+\s+\d+$/;

export function classifyIntent(rawQuery: string): Intent {
  const q = rawQuery.trim().toLowerCase();

  if (!q) {
    return { type: 'unknown', confidence: 1, normalizedQuery: q };
  }

  // Layer 1 routing — reference detected
  if (REFERENCE_PATTERN.test(q) || CHAPTER_ONLY_PATTERN.test(q)) {
    return { type: 'reference', confidence: 0.95, normalizedQuery: q };
  }

  // Question form — strip prefix and recurse as thematic
  for (const prefix of QUESTION_PREFIXES) {
    if (q.startsWith(prefix)) {
      const topic = q.replace(prefix, '').trim();
      const slug = EMOTIONAL_MAPPINGS[topic] ?? topic;
      return { type: 'question', topicSlug: slug, confidence: 0.9, normalizedQuery: topic };
    }
  }

  // Single-word emotional/thematic keyword
  const words = q.split(/\s+/);
  for (const word of words) {
    const slug = EMOTIONAL_MAPPINGS[word];
    if (slug) {
      return { type: 'emotional', topicSlug: slug, confidence: 0.85, normalizedQuery: q };
    }
  }

  // Multi-word thematic (e.g. "new baby", "job loss", "wedding")
  const thematicPhrases: Record<string, string> = {
    'new baby': 'new-life', 'job loss': 'work', 'wedding': 'marriage',
    'funeral': 'death', 'baptism': 'baptism', 'addiction': 'addiction',
    'abuse': 'healing', 'prison': 'redemption', 'retirement': 'purpose',
    'graduation': 'new-beginnings', 'moving': 'trust', 'illness': 'healing',
  };
  for (const [phrase, slug] of Object.entries(thematicPhrases)) {
    if (q.includes(phrase)) {
      return { type: 'thematic', topicSlug: slug, confidence: 0.8, normalizedQuery: q };
    }
  }

  // Named entity hints
  const entityHints = ['jesus', 'paul', 'david', 'moses', 'mary', 'abraham',
    'jerusalem', 'israel', 'egypt', 'bethlehem', 'nazareth'];
  if (entityHints.some(e => q.includes(e))) {
    return { type: 'entity', confidence: 0.75, normalizedQuery: q };
  }

  return { type: 'phrase', confidence: 0.6, normalizedQuery: q };
}
