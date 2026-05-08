import { apiBibleClient } from '../client';
import type {
  ApiBibleTranslation,
  ApiBibleBook,
  ApiBibleChapter,
  ApiBibleVerse,
  ApiBibleSearchResult,
} from './apiBible.types';

class ApiBibleService {
  async listTranslations(languageCode?: string): Promise<ApiBibleTranslation[]> {
    const params: Record<string, string> = {};
    if (languageCode) params.language = languageCode;

    const res = await apiBibleClient.get<{ data: ApiBibleTranslation[] }>('/bibles', { params });
    return res.data.data;
  }

  async listBooks(translationId: string): Promise<ApiBibleBook[]> {
    const res = await apiBibleClient.get<{ data: ApiBibleBook[] }>(
      `/bibles/${translationId}/books`
    );
    return res.data.data;
  }

  async getChapter(translationId: string, chapterId: string): Promise<ApiBibleChapter> {
    const res = await apiBibleClient.get<{ data: ApiBibleChapter }>(
      `/bibles/${translationId}/chapters/${chapterId}`,
      {
        params: {
          'content-type': 'text',
          includeNotes: false,
          includeVerseNumbers: true,
          includeVerseSpans: false,
        },
      }
    );
    return res.data.data;
  }

  async getVerse(translationId: string, verseId: string): Promise<ApiBibleVerse> {
    const res = await apiBibleClient.get<{ data: ApiBibleVerse }>(
      `/bibles/${translationId}/verses/${verseId}`,
      { params: { 'content-type': 'text', includeVerseNumbers: false } }
    );
    return res.data.data;
  }

  async search(
    translationId: string,
    query: string,
    limit = 20,
    offset = 0
  ): Promise<ApiBibleSearchResult> {
    const res = await apiBibleClient.get<{ data: ApiBibleSearchResult }>(
      `/bibles/${translationId}/search`,
      { params: { query, limit, offset } }
    );
    return res.data.data;
  }
}

export const apiBibleService = new ApiBibleService();
