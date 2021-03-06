/**
	foldalbumd/main.mm
	
	FoldMusic
  	version 1.2.0, July 15th, 2012

  Copyright (C) 2012 theiostream

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

  theiostream
  matoe@matoe.co.cc
**/

// TODO: Use scoped pools where needed.
// foldalbumd! Please destroy this and start using SBMediaController!

#import <MediaPlayer/MediaPlayer.h>
#import <AppSupport/CPDistributedMessagingCenter.h>

@interface FADaemonNotificationHandler : NSObject {
	MPMusicPlayerController *iPod;
}

- (NSDictionary *)nowPlayingItem;
- (NSDictionary *)playbackState;
- (void)play;
- (void)pause;
- (void)setQuery:(NSString *)name userInfo:(NSDictionary *)dict;
@end

static FADaemonNotificationHandler *sharedInstance_ = nil;
@implementation FADaemonNotificationHandler
+ (id)sharedInstance {
	if (!sharedInstance_)
		sharedInstance_ = [[FADaemonNotificationHandler alloc] init];
	
	return sharedInstance_;
}

- (id)init {
	if ((self = [super init])) {
		iPod = [MPMusicPlayerController iPodMusicPlayer];
	}
	
	return self;
}

- (void)setQuery:(NSString *)name userInfo:(NSDictionary *)dict {
	MPMediaItemCollection *col = [NSKeyedUnarchiver unarchiveObjectWithData:[dict objectForKey:@"Collection"]];
	[iPod setQueueWithItemCollection:col];
}

- (void)setVolume:(NSString *)name userInfo:(NSDictionary *)dict {
	float volume = [[dict objectForKey:@"Volume"] floatValue];
	[iPod setVolume:volume];
}

- (void)setNowPlaying:(NSString *)name userInfo:(NSDictionary *)dict {
	MPMediaItem *mediaItem = [NSKeyedUnarchiver unarchiveObjectWithData:[dict objectForKey:@"Item"]];
	[iPod setNowPlayingItem:mediaItem];
}

- (NSDictionary *)nowPlayingItem {
	MPMediaItem *nowPlayingItem = [iPod nowPlayingItem];
	if (nowPlayingItem)
		return [NSDictionary dictionaryWithObject:[NSKeyedArchiver archivedDataWithRootObject:nowPlayingItem] forKey:@"Item"];
	
	return nil;
}

- (NSDictionary *)playbackState {
	MPMusicPlaybackState state = [iPod playbackState];
	return [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:state] forKey:@"State"];
}

- (void)play {
	[iPod play];
}

- (void)pause {
	[iPod pause];
}

- (void)stop {
	[iPod stop];
}

- (void)seekBackward {
	[iPod beginSeekingBackward];
}

- (void)seekForward {
	[iPod beginSeekingForward];
}

- (void)endSeek {
	[iPod endSeeking];
}

- (void)previousItem {
	[iPod skipToPreviousItem];
}

- (void)nextItem {
	[iPod skipToNextItem];
}

- (void)seekBeginning {
	[iPod skipToBeginning];
}

- (NSNumber *)playbackTime {
	NSInteger interval = (NSInteger)[iPod currentPlaybackTime];
	return [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:interval] forKey:@"Interval"];
}
@end

int main() {
	NSLog(@"Welcome to foldalbumd!");
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	FADaemonNotificationHandler *hdl = [FADaemonNotificationHandler sharedInstance];

	CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"am.theiostre.foldalbum.player"];
	[center registerForMessageName:@"SetQuery" target:hdl selector:@selector(setQuery:userInfo:)];
	[center registerForMessageName:@"SetVolume" target:hdl selector:@selector(setVolume:userInfo:)];
	[center registerForMessageName:@"NowPlayingItem" target:hdl selector:@selector(nowPlayingItem)];
	[center registerForMessageName:@"PlaybackState" target:hdl selector:@selector(playbackState)];
	[center registerForMessageName:@"Play" target:hdl selector:@selector(play)];
	[center registerForMessageName:@"Pause" target:hdl selector:@selector(pause)];
	[center registerForMessageName:@"Stop" target:hdl selector:@selector(stop)];
	[center registerForMessageName:@"SeekBackward" target:hdl selector:@selector(seekBackward)];
	[center registerForMessageName:@"SeekForward" target:hdl selector:@selector(seekForward)];
	[center registerForMessageName:@"EndSeeking" target:hdl selector:@selector(endSeek)];
	[center registerForMessageName:@"PreviousItem" target:hdl selector:@selector(previousItem)];
	[center registerForMessageName:@"NextItem" target:hdl selector:@selector(nextItem)];
	[center registerForMessageName:@"SeekBeginning" target:hdl selector:@selector(seekBeginning)];
	[center registerForMessageName:@"PlaybackTime" target:hdl selector:@selector(playbackTime)];
	[center registerForMessageName:@"SetNowPlaying" target:hdl selector:@selector(setNowPlaying:userInfo:)];
	
	[center runServerOnCurrentThread];
	// FIXME: Should we turn on the "KeepAlive" key instead of this? Will that work?
	CFRunLoopRun();
	
	[pool drain];
	return 0;
}
