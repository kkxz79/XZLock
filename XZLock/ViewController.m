//
//  ViewController.m
//  XZLock
//
//  Created by kkxz on 2018/11/22.
//  Copyright © 2018 kkxz. All rights reserved.

//https://www.jianshu.com/p/938d68ed832c
//https://www.jb51.net/article/127573.htm

#import "ViewController.h"
#import "pthread.h"
#import <libkern/OSAtomic.h>

@interface ViewController ()
@property(nonatomic,assign)NSInteger lockType;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _lockType = 8;
    switch (_lockType) {
        case 1:
        {
            
            //[self synchronizedLock];
            [self synchronizedNestLock];
        }
            break;
        case 2:
        {
//            [self nsLockOne];
//            [self nsLockTwo];
//            [self nsLockThree];
            [self nsLockFour];
        }
            break;
        case 3:
        {
            [self recursiveLock];
        }
            break;
        case 4:
        {
            [self conditionLock];
        }
            break;
        case 5:
        {
            [self condition];
        }
            break;
        case 6:
        {
            [self dispatch_semophore];
        }
            break;
        case 7:
        {
//            [self pthread_mutex];
            [self pthread_mutex_recursive];
        }
            break;
        case 8:
        {
            [self osspinLock];
        }
            break;
        default:
            break;
    }
}

//TODO:@synchronized

/**
 @synchronized 指令实现锁
 */
-(void)synchronizedLock
{
    NSObject *obj = [[NSObject alloc] init];
    //并行队列 异步函数 加锁后 顺序执行
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized (obj) {
            NSLog(@"需要线程同步操作1 开始");
            sleep(3);
            NSLog(@"需要线程同步操作1 结束");
        }
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        @synchronized (obj) { //此处如果改为self，那么线程操作2就不会被阻塞
            NSLog(@"需要线程同步操作2");
        }
    });
    
}


/**
 @synchronized 指令实现锁 - 嵌套
 */
-(void)synchronizedNestLock
{
    NSObject *obj = [[NSObject alloc] init];
    @synchronized (obj) {
        NSLog(@"1st sync");
        sleep(2);
        @synchronized (obj) {
            NSLog(@"2nd sync");
        }
    }
}

//TODO:NSLock - 基本互斥锁
/*NSLocking,NSLock 实现了最基本的互斥锁，遵循了 NSLocking 协议，
 通过 lock 和 unlock 来进行锁定和解锁。
 */
-(void)nsLockOne
{
    //由于是互斥锁，当一个线程进行访问的时候，该线程获得锁，其他线程进行访问的时候将被操作系统挂起，
    //直到该线程释放锁，其他线程才能对其进行访问，从而确保了线程安全。
    NSLock * xzLock = [[NSLock alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [xzLock lock];
        NSLog(@"线程1加锁成功");
//        [xzLock lock];//如果连续锁定两次，则会造成死锁。
        sleep(2);
        [xzLock unlock];
        NSLog(@"线程1解锁成功");
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        [xzLock lock];
        NSLog(@"线程2加锁成功");
        [xzLock unlock];
        NSLog(@"线程2解锁成功");
    });
}

-(void)nsLockTwo
{
    NSLock * xzLock = [[NSLock alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"1-当前线程%@",[NSThread currentThread]);
        [xzLock lock];
        NSLog(@"线程1加锁成功");
        sleep(2);
        [xzLock unlock];
        NSLog(@"线程1解锁成功");
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //tryLock 并不会阻塞线程，[xzLock tryLock] 能加锁返回 YES，不能加锁返回 NO，然后都会执行后续代码。
        //当前线程锁失败，也可以继续其它任务，用 trylock 合适；
        //当前线程只有锁成功后，才会做一些有意义的工作，那就 lock，没必要轮询 trylock。
        NSLog(@"2-当前线程%@",[NSThread currentThread]);
        if([xzLock tryLock]){
            NSLog(@"线程3加锁成功");
            [xzLock unlock];
            NSLog(@"线程3解锁成功");
        }
        else{
            NSLog(@"线程3加锁失败");
        }
    });
}

-(void)nsLockThree
{
    NSLock * xzLock = [[NSLock alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"1-当前线程%@",[NSThread currentThread]);
        [xzLock lock];
        NSLog(@"线程1加锁成功");
        sleep(2);
        [xzLock unlock];
        NSLog(@"线程1解锁成功");
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(3);
        NSLog(@"2-当前线程%@",[NSThread currentThread]);
        if([xzLock tryLock]){
            NSLog(@"线程4加锁成功");
            [xzLock unlock];
            NSLog(@"线程4解锁成功");
        }else{
            NSLog(@"线程4加锁失败");
        }
    });
}

-(void)nsLockFour
{
    NSLock * xzLock = [[NSLock alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [xzLock lock];
        NSLog(@"线程1加锁成功");
        sleep(2);
        [xzLock unlock];
        NSLog(@"线程1解锁成功");
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(3);
        //lockBeforeDate: 方法会在所指定 Date 之前尝试加锁，会阻塞线程，
        //如果在指定时间之前都不能加锁，则返回 NO，指定时间之前能加锁，则返回 YES。
        if([xzLock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:10]]){
            NSLog(@"线程5加锁成功");
            [xzLock unlock];
            NSLog(@"线程5解锁成功");
        }else{
            NSLog(@"线程5加锁失败");
        }
    });
}

//TODO:NSRecursiveLock  递归锁  NSLocking
//NSRecursiveLock是递归锁，可以被一个线程多次获得，而不会引起死锁。
//它记录了成功获得锁的次数，每一次成功的获得锁，必须有一个配套的释放锁和其对应，这样才不会引起死锁。
//NSRecursiveLock会记录上锁和解锁的次数，当二者平衡的时候，才会释放锁，其它线程才可以上锁成功。
-(void)recursiveLock
{
    NSRecursiveLock * xzLock = [[NSRecursiveLock alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        static void (^RecursiveBlock)(int);
        RecursiveBlock = ^(int value){
            [xzLock lock];
            NSLog(@"%d加锁成功",value);
            if(value > 0){
                NSLog(@"value:%d",value);
                RecursiveBlock(value -1);
            }
            [xzLock unlock];
            NSLog(@"%d解锁成功",value);
        };
        RecursiveBlock(3);
    });
    /*如果使用NSLock的话，zkLock先上锁，但未执行解锁的时候，就会进入递归的下一层，
     而再次请求上锁，阻塞了该线程，线程被阻塞了，自然后面的解锁代码不会执行，而形成了死锁。
     而递归锁就是为了解决这个问题。
     */
    
}

//TODO:NSConditionLock 条件锁
//NSConditionLock 对象所定义的互斥锁可以在使得在某个条件下进行锁定和解锁，它和 NSLock 类似，都遵循 NSLocking 协议，方法都类似，只是多了一个 condition 属性，以及每个操作都多了一个关于 condition 属性的方法，例如 tryLock、tryLockWhenCondition:，所以 NSConditionLock 可以称为条件锁。
//只有 condition 参数与初始化时候的 condition 相等，lock 才能正确进行加锁操作。
//unlockWithCondition: 并不是当 condition 符合条件时才解锁，而是解锁之后，修改 condition 的值。
-(void)conditionLock
{
    NSConditionLock * xzLock = [[NSConditionLock alloc] initWithCondition:0];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [xzLock lock];
        NSLog(@"线程1加锁成功");
        sleep(1);
        [xzLock unlock];
        NSLog(@"线程1解锁成功");
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //在线程 1 解锁成功之后，线程 2 并没有加锁成功，而是继续等了 1 秒之后线程 3 加锁成功，这是因为线程 2 的加锁条件不满足，初始化时候的 condition 参数为 0，而线程 2加锁条件是 condition 为 1，所以线程 2 加锁失败。
        //lockWhenCondition 与 lock 方法类似，加锁失败会阻塞线程，所以线程 2 会被阻塞着。
        sleep(1);
        [xzLock lockWhenCondition:1];
        NSLog(@"线程2加锁成功");
        [xzLock unlock];
        NSLog(@"线程2解锁成功");
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(2);
        //tryLockWhenCondition: 方法就算条件不满足，也会返回 NO，不会阻塞当前线程。
        if([xzLock tryLockWhenCondition:0]){
            NSLog(@"线程3加锁成功");
            sleep(2);
            [xzLock unlockWithCondition:2]; //线程3解锁，并修改condition值为2
            NSLog(@"线程3解锁成功");
        }
        else{
            NSLog(@"线程3尝试加锁失败");
        }
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //lockWhenCondition:beforeDate:方法会在约定的时间内一直等待 condition 变为 2，并阻塞当前线程，直到超时后返回 NO。
        //锁定和解锁的调用可以随意组合，也就是说 lock、lockWhenCondition:与unlock、unlockWithCondition: 是可以按照自己的需求随意组合的。
        if([xzLock lockWhenCondition:2 beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]]){
            NSLog(@"线程4加锁成功");
            [xzLock unlockWithCondition:1];//线程4解锁，并修改condition值为1
            NSLog(@"线程4解锁成功");
        }else{
            NSLog(@"线程4尝试加锁失败");
        }
    });
}

//TODO:NSConditon 基本的条件锁
/*
 NSCondition 是一种特殊类型的锁，通过它可以实现不同线程的调度。
 一个线程被某个条件所阻塞，知道另一个线程满足该条件从而发送信号给该线程使得该线程可以正确的执行。
 比如：你可以开启一个线程下载图片，一个线程处理图片。
 这样的话，需要处理图片的线程由于没有图片会阻塞，当下载线程下载完成后，
 则满足了需要处理图片的线程的需求，这样可以给定一个信号，让处理图片的线程恢复运行
 */
/*
 NSCondition 的对象实际上作为一个锁和一个线程检查器，
 锁上之后其它线程也能上锁，而之后可以根据条件决定是否继续运行线程，
 即线程是否要进入 waiting 状态，如果进入 waiting 状态，
 当其它线程中的该锁执行 signal 或者 broadcast 方法时，线程被唤醒，继续运行之后的方法。
 NSConditon可以手动控制线程的挂起与唤醒，可以利用这个特性设置依赖。
 */
-(void)condition
{
    NSCondition * xzCondition = [[NSCondition alloc] init];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [xzCondition lock];
        NSLog(@"线程1线程加锁");
        [xzCondition wait];
        NSLog(@"线程1线程唤醒");
        [xzCondition unlock];
        NSLog(@"线程1线程解锁");
    });
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [xzCondition lock];
        NSLog(@"线程2线程加锁");
        if ([xzCondition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]]) {
            NSLog(@"线程2线程唤醒");
            [xzCondition unlock];
            NSLog(@"线程2线程解锁");
        }
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(2);
        //[xzCondition signal];
        [xzCondition broadcast];
        /*
         在加上锁之后，调用条件对象的 wait 或 waitUntilDate: 方法来阻塞线程，
         直到条件对象发出唤醒信号或者超时之后，再进行之后的操作。
         signal 和 broadcast 方法的区别在于，signal 只是一个信号量，只能唤醒一个等待的线程，
         想唤醒多个就得多次调用，而 broadcast 可以唤醒所有在等待的线程。
         */
    });
}

//TODO:dispatch_semaphore 信号量
/*
 dispatch_semaphore 使用信号量机制实现锁，等待信号和发送信号
 dispatch_semaphore 是GCD用来同步的一种方式，与它相关的只有三个函数，一个是创建信号量，一个是等待信号，一个是发送信号
 dispatch_semophore的机制就是当有多个线程进行访问的时候，只要有一个获得了信号，其他线程就必须等待该信号释放
 相关的API：
 dispatch_semaphore_create(long value);
 dispatch_semaphore_wait(dispatch_semaphore_t _Nonnull dsema, dispatch_time_t timeout);
 dispatch_semaphore_signal(dispatch_semaphore_t _Nonnull dsema);
 */

/**
 信号量实现锁
 */
-(void)dispatch_semophore
{
    dispatch_semaphore_t semophore = dispatch_semaphore_create(1);
    dispatch_time_t overTime = dispatch_time(DISPATCH_TIME_NOW, 6*NSEC_PER_SEC);
    //上述overTime 如果设置为3，那么overTime时限到了后，也会执行后续任务。
    //异步函数 + 并发队列
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_semaphore_wait(semophore, overTime);
        NSLog(@"线程1开始");
        sleep(5);
        NSLog(@"线程1结束");
        dispatch_semaphore_signal(semophore);
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        dispatch_semaphore_wait(semophore, overTime);
        NSLog(@"线程2开始");
        dispatch_semaphore_signal(semophore);
    });
    
    /*
     dispatch_semaphore 和 NSCondition 类似，都是一种基于信号的同步方式，但 NSCondition 信号只能发送，不能保存（如果没有线程在等待，则发送的信号会失效）。而 dispatch_semaphore 能保存发送的信号。dispatch_semaphore 的核心是 dispatch_semaphore_t 类型的信号量。
     dispatch_semaphore_create(1) 方法可以创建一个 dispatch_semaphore_t 类型的信号量，设定信号量的初始值为 1。注意，这里的传入的参数必须大于或等于 0，否则 dispatch_semaphore_create 会返回 NULL。
     dispatch_semaphore_wait(semaphore, overTime); 方法会判断 semaphore 的信号值是否大于 0。大于 0 不会阻塞线程，消耗掉一个信号，执行后续任务。如果信号值为 0，该线程会和 NSCondition 一样直接进入 waiting 状态，等待其他线程发送信号唤醒线程去执行后续任务，或者当 overTime 时限到了，也会执行后续任务。
     dispatch_semaphore_signal(semaphore); 发送信号，如果没有等待的线程接受信号，则使 signal 信号值加一（做到对信号的保存）
     一个 dispatch_semaphore_wait(semaphore, overTime); 方法会去对应一个 dispatch_semaphore_signal(semaphore); 看起来像 NSLock 的 lock 和 unlock，其实可以这样理解，区别只在于有信号量这个参数，lock unlock 只能同一时间，一个线程访问被保护的临界区，而如果 dispatch_semaphore 的信号量初始值为 x ，则可以有 x 个线程同时访问被保护的临界区。
     */
}


//TODO:pthread_mutex 与 pthread_mutex(recursive) 互斥锁
/*
 pthread 表示 POSIX thread，定义了一组跨平台的线程相关的 API，POSIX 互斥锁是一种超级易用的互斥锁。
 使用的时候：
 只需要使用 pthread_mutex_init 初始化一个 pthread_mutex_t
 pthread_mutex_lock 或者 pthread_mutex_trylock 来锁定
 pthread_mutex_unlock 来解锁
 当使用完成后，记得调用 pthread_mutex_destroy 来销毁锁。
 */
/*
 pthread_mutex_init(pthread_mutex_t *restrict _Nonnull, const pthread_mutexattr_t *restrict _Nullable);
 pthread_mutex_lock(pthread_mutex_t * _Nonnull);
 pthread_mutex_trylock(pthread_mutex_t * _Nonnull);
 pthread_mutex_unlock(pthread_mutex_t * _Nonnull);
 pthread_mutex_destroy(pthread_mutex_t * _Nonnull);
 */
-(void)pthread_mutex
{
    __block pthread_mutex_t xzLock;
    pthread_mutex_init(&xzLock, NULL);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        pthread_mutex_lock(&xzLock);
        NSLog(@"线程1开始");
        sleep(3);
        NSLog(@"线程1结束");
        pthread_mutex_unlock(&xzLock);
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        pthread_mutex_lock(&xzLock);
        NSLog(@"线程2");
        pthread_mutex_unlock(&xzLock);
    });
    /*
     它的用法和 NSLock 的 lock unlock 用法一致，而它也有一个 pthread_mutex_trylock 方法，
     pthread_mutex_trylock 和 tryLock 的区别在于，tryLock 返回的是 YES 和 NO，
     pthread_mutex_trylock 加锁成功返回的是 0，失败返回的是错误提示码。
     */
}

//pthread_mutex(recursive)  互斥锁(递归形式)
-(void)pthread_mutex_recursive
{
    __block pthread_mutex_t xzLock;
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init(&xzLock, &attr);
    pthread_mutexattr_destroy(&attr);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        static void (^RecursiveBlock)(int);
        RecursiveBlock = ^(int value) {
            pthread_mutex_lock(&xzLock);
            NSLog(@"%d加锁成功",value);
            if (value > 0) {
                NSLog(@"value = %d", value);
                sleep(1);
                RecursiveBlock(value - 1);
            }
            NSLog(@"%d解锁成功",value);
            pthread_mutex_unlock(&xzLock);
        };
        RecursiveBlock(3);
        /*
         pthread_mutex(recursive) 作用和 NSRecursiveLock 递归锁类似。
         如果使用 pthread_mutex_init(&theLock, NULL);
         初始化锁的话，上面的代码的第二部分会出现死锁现象，使用递归锁就可以避免这种现象。
         */
    });
}


//TODO:OSSpinLock  自旋锁
/*
 OSSPinLock是一种自旋锁，和互斥锁类似，都是为了保证线程安全的锁。
 但两者的区别是不一样的，对于互斥锁，当一个线程获得这个锁之后，其他想要获得此锁的线程将会被阻塞，知道该锁被释放。
 但自旋锁不一样，当一个线程获得锁后，其他线程将会一直循环在那里查看是否该锁被释放。
 所以，此锁比较适合用于锁的持有者保存时间较短的情况下。
 只有加锁、解锁、尝试加锁三个方法
 */
/*
 typedef int32_t OSSpinLock;
 // 加锁
 void  OSSpinLockLock( volatile OSSpinLock *__lock );
 // 尝试加锁
 bool  OSSpinLockTry( volatile OSSpinLock *__lock );
 // 解锁
 void  OSSpinLockUnlock( volatile OSSpinLock *__lock );
 */
/*
 原理是一直do while忙等
 缺点是等待的时候会消耗大量的CPU资源，适合短时间的任务
 对于内存缓存的存取来说，它非常合适
 内存访问速度很快，锁占用时间少，性能高
 特点是线程等待取锁时不进内核，线程因此不挂起，直接保持空转，这样使得它的锁操作开销降得很低，性能最好。
 */

-(void)osspinLock
{
    __block OSSpinLock theLock = OS_SPINLOCK_INIT;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSSpinLockLock(&theLock);
        NSLog(@"线程1开始");
        sleep(3);
        NSLog(@"线程1结束");
        OSSpinLockUnlock(&theLock);
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSSpinLockLock(&theLock);
        sleep(1);
        NSLog(@"线程2");
        OSSpinLockUnlock(&theLock);
    });
    
    /*
     自旋锁会存在优先级反转问题，不再安全。
     如果一个低优先级的线程获得锁并访问共享资源，
     这时一个高优先级的线程也尝试获得这个锁，它会处于 spin lock 的忙等状态从而占用大量 CPU。
     此时低优先级线程无法与高优先级线程争夺 CPU 时间，从而导致任务迟迟完不成、无法释放 lock。
     */
}

//TODO:os_unfair_lock
/*
 自旋锁已经不再安全，然后苹果又整出了个os_unfair_lock，在iOS10中OSSpinLock被<os/lock.h>中的os_unfair_lock
 */
/*
 常用相关API：
 // 初始化
 os_unfair_lock_t unfairLock = &(OS_UNFAIR_LOCK_INIT);
 // 加锁
 os_unfair_lock_lock(unfairLock);
 // 尝试加锁
 BOOL b = os_unfair_lock_trylock(unfairLock);
 // 解锁
 os_unfair_lock_unlock(unfairLock);
 os_unfair_lock 用法和 OSSpinLock 基本一致，就不一一列出了。
 */


//TODO：总结
/*
 应当针对不同的操作使用不同的锁，而不能一概而论哪种锁的加锁解锁速度快。
 其实每一种锁基本上都是加锁、等待、解锁的步骤，理解了这三个步骤就可以帮你快速的学会各种锁的用法。
 @synchronized 的效率最低，不过它的确用起来最方便，所以如果没什么性能瓶颈的话，可以选择使用 @synchronized。
 当性能要求较高时候，可以使用 pthread_mutex 或者 dispath_semaphore，由于 OSSpinLock 不能很好的保证线程安全，而在只有在 iOS10 中才有 os_unfair_lock ，所以，前两个是比较好的选择。既可以保证速度，又可以保证线程安全。
 对于 NSLock 及其子类，速度来说 NSLock < NSCondition < NSRecursiveLock < NSConditionLock 。
 */

/*
 对各个锁进行1000000次的加解锁的空操作，性能如下：
 OSSpinLock: 46.15 ms   自旋锁
 dispatch_semaphore: 56.50 ms   信号量锁
 pthread_mutex: 178.28 ms   互斥锁
 NSCondition: 193.38 ms  基本条件锁
 NSLock: 175.02 ms
 pthread_mutex(recursive): 172.56 ms    一种递归锁
 NSRecursiveLock: 157.44 ms     递归锁
 NSConditionLock: 490.04 ms     条件锁
 @synchronized: 371.17 ms   同步块锁
 */

#pragma mark - lazy init
@synthesize lockType = _lockType;

@end
