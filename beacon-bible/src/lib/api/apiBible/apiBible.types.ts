export interface ApiBibleTranslation {
  id: string;
  dblId: string;
  abbreviation: string;
  abbreviationLocal: string;
  copyright: string;
  language: {
    id: string;
    name: string;
    nameLocal: string;
    script: string;
    scriptCode: string;
    scriptDirection: 'LTR' | 'RTL';
    ldml: string;
    iso6393: string;
    dblCode: string;
  };
  countries: { id: string; name: string; nameLocal: string }[];
  name: string;
  nameLocal: string;
  description: string;
  descriptionLocal: string;
  info: string;
  type: string;
  updatedAt: string;
  relatedDbl?: string;
  audioBibles: { id: string; name: string; nameLocal: string; description: string }[];
}

export interface ApiBibleBook {
  id: string;
  bibleId: string;
  abbreviation: string;
  name: string;
  nameLong: string;
}

export interface ApiBibleChapter {
  id: string;           // e.g. "JHN.3"
  bibleId: string;
  bookId: string;
  number: string;
  content: string;      // HTML or plain text
  verseCount: number;
  next?: { id: string; bookId: string; number: string };
  previous?: { id: string; bookId: string; number: string };
  copyright: string;
}

export interface ApiBibleVerse {
  id: string;           // e.g. "JHN.3.16"
  orgId: string;
  bibleId: string;
  bookId: string;
  chapterId: string;
  content: string;
  reference: string;
  verseCount: number;
  copyright: string;
}

export interface ApiBibleSearchResult {
  query: string;
  limit: number;
  offset: number;
  total: number;
  verseCount: number;
  verses: {
    id: string;
    orgId: string;
    bibleId: string;
    bookId: string;
    chapterId: string;
    text: string;
    reference: string;
  }[];
}
