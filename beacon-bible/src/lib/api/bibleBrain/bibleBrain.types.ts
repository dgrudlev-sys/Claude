export interface BibleBrainFilesetType {
  id: string;
  type: string; // 'audio_drama' | 'audio' | 'text_plain' | 'text_format'
  size: string; // 'NT' | 'OT' | 'C' (complete)
}

export interface BibleBrainBible {
  abbr: string;
  name: string;
  vname: string;
  language: string;
  language_id: number;
  iso: string;
  date: string;
  filesets: Record<string, BibleBrainFilesetType[]>;
}

export interface BibleBrainLanguage {
  id: number;
  glotto_id: string;
  iso: string;
  name: string;
  autonym: string;
  bibles: number;
  filesets: number;
}

export interface BibleBrainAudioFile {
  book_id: string;
  book_name: string;
  chapter_start: number;
  chapter_end: number | null;
  verse_start: number | null;
  verse_end: number | null;
  thumbnail: string | null;
  duration: number | null;
  path: string;
}

export interface BibleBrainAudioResponse {
  data: BibleBrainAudioFile[];
}

export interface BibleBrainBiblesResponse {
  data: BibleBrainBible[];
  meta: {
    pagination: {
      total: number;
      count: number;
      per_page: number;
      current_page: number;
      total_pages: number;
    };
  };
}

export interface ResolvedAudioTrack {
  url: string;
  bookCode: string;
  chapter: number;
  duration: number | null;
  isDrama: boolean;
}
