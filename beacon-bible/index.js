import 'react-native-gesture-handler';
import { registerRootComponent } from 'expo';
import TrackPlayer from 'react-native-track-player';
import { playbackService } from './src/lib/audio/AudioService';
import App from './App';

TrackPlayer.registerPlaybackService(() => playbackService);

registerRootComponent(App);
