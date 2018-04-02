//
//  GCDViewController.m
//  OC
//
//  Created by apple on 2017/11/29.
//  Copyright © 2017年 shanlq. All rights reserved.
//

/*
 参考：http://www.jianshu.com/p/2d57c72016c6
 */

#import "GCDViewController.h"

@interface GCDViewController ()

@end

@implementation GCDViewController

static GCDViewController *shareVC;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    //GCD基础组合
//    [self GCDGroup1];
//    [self GCDGroup2];
//    [self GCDGroup3];
//    [self AsyncMain];
//    [self GCDGroup4];
//    [self GCDGroup5];
//    [self GCDGroup6];
    
    //GCD线程通讯
//    [self ThreadCommunication];
//    [self ThreadGroupCommunication];
    
    //其他功能
    [self fence];
}

/*
并行队列、串行队列、主队列（组合任务:同步执行、异步执行）共6种组合（全局并行对列与并行队列相同）
同步执行：不创建新线程，在当前线程中执行且任务是立即执行的，即优先级高于该线程的其他任务。
异步执行：创建新线程，在新线程中执行且任务不是立即执行的，即优先级低于该线程的其他任务。
并行队列：（异步）根据队列中的任务数创建多个并行的线程（系统允许的线程数范围内），且任务同时执行。（同步）不会创建新线程，任务在当前线程中执行。
串行队列：队列中的任务按照顺序依次执行
组合：
             |          并行队列         |          串行队列             |        主队列
 同步(sync)   | 没有开启新线程，串行执行任务  | 没有开启新线程，串行执行任务     |  没有开启新线程，串行执行任务
 异步(async)  |  有开启新线程，并行执行任务   | 有开启新线程(1条)，串行执行任务  | 没有开启新线程，串行执行任务
*/
//1、同步并行队列
-(void)GCDGroup1
{
    NSLog(@"主线程任务一, %@", [NSThread currentThread]);
    dispatch_queue_t queue = dispatch_queue_create("concurrent", DISPATCH_QUEUE_CONCURRENT);
    dispatch_sync(queue, ^{                    //同步：任务优先级高，会在“主线程任务二”之前执行（下同）
        for(int i = 0; i < 2; i++)
        {
            NSLog(@"同步并行一 任务%d, %@", i, [NSThread currentThread]);
        }
    });
    dispatch_sync(queue, ^{
        for(int i = 0; i < 2; i++)
        {
            NSLog(@"同步并行二 任务%d, %@", i, [NSThread currentThread]);
        }
    });
    NSLog(@"主线程任务二, %@", [NSThread currentThread]);
}
//2、同步串行队列
-(void)GCDGroup2
{
    NSLog(@"主线程任务一, %@", [NSThread currentThread]);
    dispatch_queue_t queue = dispatch_queue_create("concurrent", DISPATCH_QUEUE_CONCURRENT);
    dispatch_sync(queue, ^{
        for(int i = 0; i < 2; i++)
        {
            NSLog(@"同步串行一 任务%d, %@", i, [NSThread currentThread]);
        }
    });
    dispatch_sync(queue, ^{
        for(int i = 0; i < 2; i++)
        {
            NSLog(@"同步串行二 任务%d, %@", i, [NSThread currentThread]);
        }
    });
    NSLog(@"主线程任务二, %@", [NSThread currentThread]);
}
//3、同步主队列(死锁：相互等待)：同步执行线程下的任务是立即执行的，即将第一个线程加入到主队列后应该在主队列中立即执行该同步线程的第一个任务，但是此时主线程正在处理它里面的任务（即该方法中的内容，因为该方法中的代码都是写在主线程上的），所以原来主线程上的任务就和添加到主队列中的同步线程的任务形成相互等待造成死锁。
-(void)GCDGroup3
{
    NSLog(@"主线程任务一, %@", [NSThread currentThread]);
    dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_sync(queue, ^{
        for(int i = 0; i < 2; i++)
        {
            NSLog(@"同步主队列一 任务%d, %@", i, [NSThread currentThread]);
        }
    });
    dispatch_sync(queue, ^{
        for(int i = 0; i < 2; i++)
        {
            NSLog(@"同步主队列二 任务%d, %@", i, [NSThread currentThread]);
        }
    });
    NSLog(@"主线程任务二, %@", [NSThread currentThread]);
}
//将GCDGroup3即同步主队列放在一个新线程中就可解决死锁问题。因为这样GCDGroup3中的代码整体（任务）就相对于是放在这个新线程中执行，这样主线程就只会执行被添加到主队列中的同步线程的任务，也就是将两个相互等待的线程任务中的其中一个分离到另一个线程上，这就解决了死锁问题。
-(void)AsyncMain
{
//    dispatch_queue_t queue = dispatch_queue_create("test", DISPATCH_QUEUE_CONCURRENT);     //使用gcd创建异步线程
//    dispatch_async(queue, ^{
//        [self GCDGroup3];
//    });
    
    NSThread *thread = [[NSThread alloc] initWithBlock:^{                   //使用NSThread创建线程
        [self GCDGroup3];
    }];
    [thread start];
}
//4、异步并行队列
-(void)GCDGroup4
{
    NSLog(@"主线程任务一, %@", [NSThread currentThread]);
    dispatch_queue_t queue = dispatch_queue_create("concurrent", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{               //异步：任务优先级低，会在主线程任务结束后执行。（下同）
        for(int i = 0; i < 2; i++)
        {
            NSLog(@"异步并行一 任务%d, %@", i, [NSThread currentThread]);
        }
    });
    dispatch_async(queue, ^{
        for(int i = 0; i < 2; i++)
        {
            NSLog(@"异步并行二 任务%d, %@", i, [NSThread currentThread]);
        }
    });
    NSLog(@"主线程任务二, %@", [NSThread currentThread]);
}
//5、异步串行队列
-(void)GCDGroup5
{
    NSLog(@"主线程任务一, %@", [NSThread currentThread]);
    dispatch_queue_t queue = dispatch_queue_create("concurrent", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{               //创建新线程且在新线程上的任务是串行执行（依次）的
        for(int i = 0; i < 2; i++)
        {
            NSLog(@"异步串行一 任务%d, %@", i, [NSThread currentThread]);
        }
    });
    dispatch_async(queue, ^{
        for(int i = 0; i < 2; i++)
        {
            NSLog(@"异步串行二 任务%d, %@", i, [NSThread currentThread]);
        }
    });
    NSLog(@"主线程任务二, %@", [NSThread currentThread]);
}
//6、异步主队列
-(void)GCDGroup6
{
    NSLog(@"主线程任务一, %@", [NSThread currentThread]);
    dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_async(queue, ^{
        for(int i = 0; i < 2; i++)
        {
            NSLog(@"异步线程一 任务%d, %@", i, [NSThread currentThread]);
        }
    });
    dispatch_async(queue, ^{
        for(int i = 0; i < 2; i++)
        {
            NSLog(@"异步线程二 任务%d, %@", i, [NSThread currentThread]);
        }
    });
    NSLog(@"主线程任务二, %@", [NSThread currentThread]);
}

//GCD线程间的通讯
//1、主线程更新UI
-(void)ThreadCommunication
{
    dispatch_queue_t queue = dispatch_queue_create(nil, DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        for(int i = 0; i < 2; i++)
            NSLog(@"子线程任务%d, %@", i, [NSThread currentThread]);
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"主线程更新UI, %@", [NSThread currentThread]);
    });
}
//2、线程组
-(void)ThreadGroupCommunication
{
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create(nil, DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_async(group, queue, ^{
        NSLog(@"线程一%@", [NSThread currentThread]);
    });
    dispatch_group_async(group, queue, ^{
        NSLog(@"线程二%@", [NSThread currentThread]);
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{    //这里获取主队列
        NSLog(@"任务完成返回主线程");
    });
}

//其他的方法
//1、只执行一次（通常用作创建单例）
-(GCDViewController *)shareObjcet
{
    static dispatch_once_t onceObject;
    dispatch_once(&onceObject, ^{
        shareVC = [[GCDViewController alloc] init];
    });
    return shareVC;
}
//2、延迟执行
-(void)YanChi
{
    //DISPATCH_TIME_NOW:表示现在的时间，NSEC_PER_SEC：用纳秒作单位，表示延迟多久。
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"延迟2秒执行");
    });
}
//3、隔离线
-(void)fence
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"任务1%@", [NSThread currentThread]);
    });
    dispatch_barrier_async(dispatch_get_main_queue(), ^{
        NSLog(@"分割线");
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"任务二");
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
