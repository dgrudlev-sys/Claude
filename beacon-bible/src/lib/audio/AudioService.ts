import TrackPlayer, {
  Event,
  State,
  Capability,
  AppKilledPlaybackBehavior,
} from 'react-native-track-player';
import type { BookCode } from '@/constants/bible.constants';
import { BOOK_NAMES } from '@/constants/bible.constants';

export interface AudioChapter {
  url: string;
  bookCode: BookCode;
  chapter: number;
  duration?: number;
}

let isSetup = false;

export async function setupAudioPlayer(): Promise<void> {
  if (isSetup) return;
  try {
    await TrackPlayer.setupPlayer({
      minBuffer: 15,
      maxBuffer: 60,
      playBuffer: 2.5,
      backBuffer: 30,
    });
    await TrackPlayer.updateOptions({
      android: {
        appKilledPlaybackBehavior: AppKilledPlaybackBehavior.StopPlaybackAndRemoveNotification,
      },
      capabilities: [
        Capability.Play,
        Capability.Pause,
        Capability.SkipToNext,
        Capability.SkipToPrevious,
        Capability.SeekTo,
        Capability.Stop,
      ],
      compactCapabilities: [
        Capability.Play,
        Capability.Pause,
        Capability.SkipToNext,
      ],
      notificationCapabilities: [
        Capability.Play,
        Capability.Pause,
        Capability.SkipToNext,
        Capability.SkipToPrevious,
        Capability.SeekTo,
      ],
      progressUpdateEventInterval: 2,
    });
    isSetup = true;
  } catch {
    // Player already set up (hot reload)
    isSetup = true;
  }
}

export async function loadChapterAudio(chapter: AudioChapter): Promise<void> {
  await TrackPlayer.reset();
  await TrackPlayer.add({
    id: `${chapter.bookCode}-${chapter.chapter}`,
    url: chapter.url,
    title: `${BOOK_NAMES[chapter.bookCode]} ${chapter.chapter}`,
    artist: 'Beacon Bible',
    duration: chapter.duration ?? undefined,
    artwork: undefined,
  });
}

export async function playAudio(): Promise<void> {
  await TrackPlayer.play();
}

export async function pauseAudio(): Promise<void> {
  await TrackPlayer.pause();
}

export async function seekTo(seconds: number): Promise<void> {
  await TrackPlayer.seekTo(seconds);
}

export async function stopAudio(): Promise<void> {
  await TrackPlayer.stop();
  await TrackPlayer.reset();
}

export async function getPlayerState(): Promise<State> {
  return TrackPlayer.getState();
}

export async function getProgress(): Promise<{ position: number; duration: number }> {
  const progress = await TrackPlayer.getProgress();
  return { position: progress.position, duration: progress.duration };
}

// Called by TrackPlayer service worker (registered in index.js)
export async function playbackService() {
  TrackPlayer.addEventListener(Event.RemotePause, () => TrackPlayer.pause());
  TrackPlayer.addEventListener(Event.RemotePlay, () => TrackPlayer.play());
  TrackPlayer.addEventListener(Event.RemoteStop, () => TrackPlayer.stop());
  TrackPlayer.addEventListener(Event.RemoteNext, () => TrackPlayer.skipToNext());
  TrackPlayer.addEventListener(Event.RemotePrevious, () => TrackPlayer.skipToPrevious());
  TrackPlayer.addEventListener(Event.RemoteSeek, ({ position }) => TrackPlayer.seekTo(position));
}
