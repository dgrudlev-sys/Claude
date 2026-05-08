import { bibleBrainClient } from '@/lib/api/client';
import type {
  BibleBrainBiblesResponse,
  BibleBrainAudioResponse,
  ResolvedAudioTrack,
} from './bibleBrain.types';
import type { BookCode } from '@/constants/bible.constants';

// Maps our canonical book codes to Bible Brain's USFM book IDs
const BOOK_CODE_TO_USFM: Partial<Record<BookCode, string>> = {
  GEN: 'GEN', EXO: 'EXO', LEV: 'LEV', NUM: 'NUM', DEU: 'DEU',
  JOS: 'JOS', JDG: 'JDG', RUT: 'RUT', '1SA': '1SA', '2SA': '2SA',
  '1KI': '1KI', '2KI': '2KI', '1CH': '1CH', '2CH': '2CH', EZR: 'EZR',
  NEH: 'NEH', EST: 'EST', JOB: 'JOB', PSA: 'PSA', PRO: 'PRO',
  ECC: 'ECC', SNG: 'SNG', ISA: 'ISA', JER: 'JER', LAM: 'LAM',
  EZK: 'EZK', DAN: 'DAN', HOS: 'HOS', JOL: 'JOL', AMO: 'AMO',
  OBA: 'OBA', JON: 'JON', MIC: 'MIC', NAM: 'NAM', HAB: 'HAB',
  ZEP: 'ZEP', HAG: 'HAG', ZEC: 'ZEC', MAL: 'MAL',
  MAT: 'MAT', MRK: 'MRK', LUK: 'LUK', JHN: 'JHN', ACT: 'ACT',
  ROM: 'ROM', '1CO': '1CO', '2CO': '2CO', GAL: 'GAL', EPH: 'EPH',
  PHP: 'PHP', COL: 'COL', '1TH': '1TH', '2TH': '2TH', '1TI': '1TI',
  '2TI': '2TI', TIT: 'TIT', PHM: 'PHM', HEB: 'HEB', JAS: 'JAS',
  '1PE': '1PE', '2PE': '2PE', '1JN': '1JN', '2JN': '2JN', '3JN': '3JN',
  JUD: 'JUD', REV: 'REV',
};

export class BibleBrainService {
  async listBiblesForLanguage(iso: string): Promise<BibleBrainBiblesResponse['data']> {
    const res = await bibleBrainClient.get<BibleBrainBiblesResponse>('/bibles', {
      params: { language_code: iso, media: 'audio', limit: 50 },
    });
    return res.data.data;
  }

  async getAudioForChapter(
    filesetId: string,
    bookCode: BookCode,
    chapter: number,
  ): Promise<ResolvedAudioTrack | null> {
    const usfm = BOOK_CODE_TO_USFM[bookCode];
    if (!usfm) return null;

    try {
      const res = await bibleBrainClient.get<BibleBrainAudioResponse>('/bibles/filesets/' + filesetId, {
        params: {
          book_id: usfm,
          chapter_id: chapter,
          type: 'audio',
          limit: 1,
        },
      });

      const file = res.data.data[0];
      if (!file) return null;

      return {
        url: file.path,
        bookCode,
        chapter,
        duration: file.duration,
        isDrama: filesetId.endsWith('DA') || filesetId.includes('DRAMA'),
      };
    } catch {
      return null;
    }
  }

  // Prefer dramatized audio (DA suffix), fall back to narrated (2DA or plain)
  async getBestAudioTrack(
    filesetIds: string[],
    bookCode: BookCode,
    chapter: number,
  ): Promise<ResolvedAudioTrack | null> {
    const drama = filesetIds.find(id => id.endsWith('DA') || id.includes('DRAMA'));
    const narrated = filesetIds.find(id => id.endsWith('2DA') || id.endsWith('A'));
    const ordered = [drama, narrated, ...filesetIds].filter(Boolean) as string[];

    for (const id of ordered) {
      const track = await this.getAudioForChapter(id, bookCode, chapter);
      if (track) return track;
    }
    return null;
  }
}

export const bibleBrainService = new BibleBrainService();
