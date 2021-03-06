//
//  Play.m
//  AudioTest
//
//  Created by webseat2 on 13-10-22.
//  Copyright (c) 2013年 WebSeat. All rights reserved.
//

#import "Play.h"

@interface Play()
{
//    Byte *audioByte;
    NSUInteger audioDataIndex;
//    long audioDataLength;
    BOOL isStart;
}
@end

@implementation Play

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.tempData = [NSMutableData data];
        isStart = false;
    }
    return self;
}

//回调函数(Callback)的实现
static void BufferCallback(void *inUserData,AudioQueueRef inAQ,AudioQueueBufferRef buffer){
    
//    NSLog(@"processAudioData :%u", (unsigned int)buffer->mAudioDataByteSize);
    
    Play* player=(__bridge Play*)inUserData;
    
    [player FillBuffer:inAQ queueBuffer:buffer];
}

//缓存数据读取方法的实现
-(void)FillBuffer:(AudioQueueRef)queue queueBuffer:(AudioQueueBufferRef)buffer
{
//    const void* data = [self.tempData bytes];
    if(audioDataIndex + EVERY_READ_LENGTH <= self.tempData.length)
    {
        NSData *thisTempData = [self.tempData subdataWithRange:NSMakeRange(audioDataIndex, EVERY_READ_LENGTH)];
//        char tempBuffer[EVERY_READ_LENGTH];
//        [self.tempData getBytes:tempBuffer range:NSMakeRange(audioDataIndex, EVERY_READ_LENGTH)];
//        memcpy(buffer->mAudioData, [tempData bytes], EVERY_READ_LENGTH);
        memcpy(buffer->mAudioData, [thisTempData bytes], EVERY_READ_LENGTH);
        audioDataIndex += EVERY_READ_LENGTH;
        buffer->mAudioDataByteSize =EVERY_READ_LENGTH;
        AudioQueueEnqueueBuffer(queue, buffer, 0, NULL);
    } else {
//        NSAssert(false, @"错误");
//        char tempBuffer[EVERY_READ_LENGTH] = {0};
//        bzero(tempBuffer, sizeof(tempBuffer));
//        NSData *emptyData = [NSData dataWithBytes:tempBuffer length:10240];
//        [emptyData getBytes:tempBuffer range:NSMakeRange(0, EVERY_READ_LENGTH)];
//                memcpy(buffer->mAudioData, [tempData bytes], EVERY_READ_LENGTH);
        
        audioDataIndex -= EVERY_READ_LENGTH;
        NSData *thisTempData = [self.tempData subdataWithRange:NSMakeRange(audioDataIndex, EVERY_READ_LENGTH)];
        memcpy(buffer->mAudioData, [thisTempData bytes], EVERY_READ_LENGTH);
        
        
        buffer->mAudioDataByteSize =EVERY_READ_LENGTH;
        AudioQueueEnqueueBuffer(queue, buffer, 0, NULL);
    }
    
}

-(void)SetAudioFormat
{
    ///设置音频参数
    audioDescription.mSampleRate  = kSamplingRate;//采样率
    audioDescription.mFormatID    = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags =  kAudioFormatFlagIsSignedInteger;//|kAudioFormatFlagIsNonInterleaved;
    audioDescription.mChannelsPerFrame = kNumberChannels;
    audioDescription.mFramesPerPacket  = 1;//每一个packet一侦数据
    audioDescription.mBitsPerChannel   = kBitsPerChannels;//av_get_bytes_per_sample(AV_SAMPLE_FMT_S16)*8;//每个采样点16bit量化
    audioDescription.mBytesPerFrame    = kBytesPerFrame;
    audioDescription.mBytesPerPacket   = kBytesPerFrame;
    
    [self CreateAudioQueue];
}

-(void)CreateAudioQueue
{
    [self Cleanup];
    //使用player的内部线程播
    AudioQueueNewOutput(&audioDescription, BufferCallback, (__bridge void *)(self), nil, nil, 0, &audioQueue);
    if(audioQueue)
    {
        ////添加buffer区
        for(int i=0;i<QUEUE_BUFFER_SIZE;i++)
        {
            int result =  AudioQueueAllocateBuffer(audioQueue, EVERY_READ_LENGTH, &audioQueueBuffers[i]);
            ///创建buffer区，MIN_SIZE_PER_FRAME为每一侦所需要的最小的大小，该大小应该比每次往buffer里写的最大的一次还大
            NSLog(@"AudioQueueAllocateBuffer i = %d,result = %d",i,result);
        }
    }
}

-(void)Cleanup
{
    if(audioQueue)
    {
        NSLog(@"Release AudioQueueNewOutput");
        
        [self Stop];
        for(int i=0; i < QUEUE_BUFFER_SIZE; i++)
        {
            AudioQueueFreeBuffer(audioQueue, audioQueueBuffers[i]);
            audioQueueBuffers[i] = nil;
        }
        audioQueue = nil;
    }
}

-(void)Stop
{
    NSLog(@"Audio Player Stop");
    
    AudioQueueFlush(audioQueue);
    AudioQueueReset(audioQueue);
    AudioQueueStop(audioQueue,TRUE);
}

-(void)initAudio
{
    [self Stop];
//    audioByte = byte;
//    audioDataLength = 0;
    
    NSLog(@"Audio Play Start >>>>>");
    
    [self SetAudioFormat];
    
    AudioQueueReset(audioQueue);
    audioDataIndex = 0;
    for(int i=0; i<QUEUE_BUFFER_SIZE; i++)
    {
        [self FillBuffer:audioQueue queueBuffer:audioQueueBuffers[i]];
    }
    AudioQueueStart(audioQueue, NULL);
}

- (void)appendData:(NSData *)data {
    
    [self.tempData appendData:data];
//    NSLog(@"%@",@(self.tempData.length));
    if (self.tempData.length >= 50000) {
        if (isStart == false) {
            [self initAudio];
            isStart = true;
        }
    }
    
    
//    if (isStart == false) {
//    [self.tempData appendData:data];
//    NSLog(@"%@",@(data.length));
//    }
    
    
}

- (void)play {
//            if (isStart == false) {
//                [self initAudio];
//                isStart = true;
//            }
}

@end
