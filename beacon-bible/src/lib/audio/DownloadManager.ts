import * as FileSystem from 'expo-file-system';
import { getDatabase } from '@/lib/db';
import type { BookCode } from '@/constants/bible.constants';

const AUDIO_DIR = FileSystem.documentDirectory + 'audio/';

export interface DownloadProgress {
  bytesWritten: number;
  totalBytesExpectedToWrite: number;
  progress: number; // 0–1
}

type ProgressCallback = (p: DownloadProgress) => void;

async function ensureDir(): Promise<void> {
  const info = await FileSystem.getInfoAsync(AUDIO_DIR);
  if (!info.exists) {
    await FileSystem.makeDirectoryAsync(AUDIO_DIR, { intermediates: true });
  }
}

function localPath(bookCode: BookCode, chapter: number): string {
  return `${AUDIO_DIR}${bookCode}_${chapter}.mp3`;
}

function downloadKey(bookCode: BookCode, chapter: number): string {
  return `${bookCode}_${chapter}`;
}

export async function isChapterDownloaded(bookCode: BookCode, chapter: number): Promise<boolean> {
  const path = localPath(bookCode, chapter);
  const info = await FileSystem.getInfoAsync(path);
  return info.exists;
}

export async function getLocalAudioPath(bookCode: BookCode, chapter: number): Promise<string | null> {
  if (await isChapterDownloaded(bookCode, chapter)) {
    return localPath(bookCode, chapter);
  }
  return null;
}

export async function downloadChapterAudio(
  url: string,
  bookCode: BookCode,
  chapter: number,
  onProgress?: ProgressCallback,
): Promise<string> {
  await ensureDir();
  const dest = localPath(bookCode, chapter);

  if (onProgress) {
    const callback = FileSystem.createDownloadResumable(
      url,
      dest,
      {},
      ({ totalBytesWritten, totalBytesExpectedToWrite }) => {
        onProgress({
          bytesWritten: totalBytesWritten,
          totalBytesExpectedToWrite,
          progress: totalBytesExpectedToWrite > 0
            ? totalBytesWritten / totalBytesExpectedToWrite
            : 0,
        });
      },
    );
    const result = await callback.downloadAsync();
    if (!result) throw new Error('Download failed');
  } else {
    const result = await FileSystem.downloadAsync(url, dest);
    if (result.status !== 200) throw new Error(`Download HTTP ${result.status}`);
  }

  // Record in DB
  const db = await getDatabase();
  await db.runAsync(
    `INSERT OR REPLACE INTO audio_downloads
       (fileset_id, book_code, chapter, local_path, file_size_bytes, downloaded_at)
     VALUES (?, ?, ?, ?, ?, datetime('now'))`,
    [downloadKey(bookCode, chapter), bookCode, chapter, dest, 0],
  );

  return dest;
}

export async function deleteChapterAudio(bookCode: BookCode, chapter: number): Promise<void> {
  const path = localPath(bookCode, chapter);
  const info = await FileSystem.getInfoAsync(path);
  if (info.exists) {
    await FileSystem.deleteAsync(path, { idempotent: true });
  }

  const db = await getDatabase();
  await db.runAsync(
    `DELETE FROM audio_downloads WHERE book_code = ? AND chapter = ?`,
    [bookCode, chapter],
  );
}

export async function getTotalDownloadedBytes(): Promise<number> {
  await ensureDir();
  const info = await FileSystem.getInfoAsync(AUDIO_DIR);
  return info.exists && 'size' in info ? (info.size as number) : 0;
}
