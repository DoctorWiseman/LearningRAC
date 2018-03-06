//
//  ViewController.m
//  RACTestDemo
//
//  Created by Wiseman on 2018/3/2.
//  Copyright © 2018年 Wiseman. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveObjC/ReactiveObjC.h>

@interface ViewController ()

@property (nonatomic,strong) RACCommand *command;

//Channel
@property (nonatomic,strong) UITextField *textField;
@property (nonatomic,copy) NSString *stringText;

//双向绑定的测试
@property (nonatomic,copy) NSString *valueA;
@property (nonatomic,copy) NSString *valueB;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self testRetry];
}

/**
 用来封装网路请求
 */
- (void)testRACCommand {
    if (!_command) {
        _command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
            return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
                NSLog(@"开始请求网络");
                [subscriber sendNext:@"sendData"];
                //请求完成
                [subscriber sendCompleted];
                return [RACDisposable disposableWithBlock:^{
                    NSLog(@"订阅过程完成");
                }];
            }];
        }];
        
        //监控是否执行中
        [_command.executing subscribeNext:^(NSNumber * _Nullable x) {
            NSNumber *executing = (NSNumber *)x;
            NSString *stateStr = executing.boolValue? @"请求状态":@"未请求状态";
            NSLog(@"%@", stateStr);
        }];
        
        //监控请求成功的状态
        [_command.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
            NSLog(@"请求成功,数据:%@", x);
        }];
        
        //监控请求失败的状态
        [_command.errors subscribeNext:^(NSError * _Nullable x) {
            NSLog(@"请求失败: %@", x);
        }];
    }
    
    [_command execute:nil];
}

/**
 RAC的集合类型
 */
- (void)testRACSequence{
    NSArray *numbers = @[@1,@2,@3,@4];
    [numbers.rac_sequence.signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    NSDictionary *dict = @{@"name":@"abc", @"age":@22};
    [dict.rac_sequence.signal subscribeNext:^(id  _Nullable x) {
        //解包元组
        RACTupleUnpack(NSString *key,NSString *value) = x;
        NSLog(@"%@ %@",key,value);
    }];
}

/**
 RAC的双向绑定
 */
- (void)testRACChannel {
    UITextField *textF = [[UITextField alloc] init];
    textF.placeholder = @"输入文字";
    textF.frame = CGRectMake(100, 100, 200, 40);
    self.textField = textF;
    [self.view addSubview:textF];
    
    RACChannelTerminal *textFieldChannelT = self.textField.rac_newTextChannel;
    // 输入框文本变化反应到stringText属性上
    RAC(self, stringText) = textFieldChannelT;
    // stringText属性对应的文字订阅到输入框上  这样就实现了双向绑定
    [RACObserve(self, stringText) subscribe:textFieldChannelT];
}


/**
 RAC封装KVO
 */
- (void)testRACOberve {
    //测试RAC的KVO
    [RACObserve(self, stringText) subscribeNext:^(id  _Nullable x) {
        NSLog(@"new value is %@", x);
    }];
}


/**
 双向绑定终端
 */
- (void)testRACChannelTo:(id)sender {
    RACChannelTerminal *channeA = RACChannelTo(self, valueA);
    RACChannelTerminal *channeB = RACChannelTo(self, valueB);
    [[channeA map:^id _Nullable(id  _Nullable value) {
        if ([value isEqualToString:@"西"]) {
            return @"东";
        }
        return value;
    }] subscribe:channeB];
    
    [[channeB map:^id _Nullable(id  _Nullable value) {
        if ([value isEqualToString:@"左"]) {
            return @"右";
        }
        return value;
    }] subscribe:channeA];
    
    [[RACObserve(self, valueA) filter:^BOOL(id  _Nullable value) {
        return value ? YES : NO;
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"你向%@",x);
    }];
    [[RACObserve(self, valueB) filter:^BOOL(id  _Nullable value) {
        return value ? YES : NO;
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"他向%@",x);
    }];
    self.valueA = @"西";
    self.valueB = @"左";
}


/**
 转换信号
 */
- (void)testMap {
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@"十"];
        return nil;
    }] map:^id _Nullable(id  _Nullable value) {
        if ([value isEqualToString:@"十"]) {
            return @"进";
        }
        return value;
    }];
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
}


/**
 相当于添加了fiflter方法
 */
- (void)testFiflter {
    [[[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@(15)];
        [subscriber sendNext:@(12)];
        [subscriber sendNext:@(13)];
        [subscriber sendNext:@(16)];
        [subscriber sendNext:@(19)];
        [subscriber sendNext:@(23)];
        [subscriber sendNext:@(23)];
        [subscriber sendNext:@(26)];
        return nil;
    }] filter:^BOOL(NSNumber *value) {
        return value.integerValue >= 18;
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
}


/**
 转换成新的信号
 */
- (void)testFlattenMap {
    [[[[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@"蛋液"];
        [subscriber sendCompleted];
        return nil;
    }] flattenMap:^__kindof RACSignal * _Nullable(id  _Nullable value) {
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            NSLog(@"把%@倒进锅里面煎",value);
            [subscriber sendCompleted];
            return nil;
        }];
    }] flattenMap:^__kindof RACSignal * _Nullable(id  _Nullable value) {
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            NSLog(@"把%@装进盘里",value);
            [subscriber sendNext:@"上菜"];
            [subscriber sendCompleted];
            return nil;
        }];
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
}


/**
 take 取前几个订阅
 */
- (void)testTake {
    RACSubject *subject = [RACSubject subject];
    [[subject take:2] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    //取前两次的信号值
    [subject sendNext:@"1"];
    [subject sendNext:@"2"];
    [subject sendNext:@"3"];
    [subject sendNext:@"4"];
}


/**
 take 取后几个订阅 其余有skip，ignore
 */
- (void)testTakeLast {
    RACSubject *subject = [RACSubject subject];
    [[subject takeLast:2] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    //取后两次订阅
    [subject sendNext:@"1"];
    [subject sendNext:@"2"];
    [subject sendNext:@"3"];
    [subject sendNext:@"4"];
    [subject sendCompleted];
}


/**
 信号拼接 在SignalA后面拼接SignalB，只有signalA发送完成后，signalB才会被拼接
 */
- (void)testConcat {
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@"我吃面了"];
        [subscriber sendCompleted];
        return nil;
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@"我吃饱了"];
        [subscriber sendCompleted];
        return nil;
    }];
    
    [[signalA concat:signalB] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
}


/**
 信号的转接
 */
- (void)testThen {
    [[[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendCompleted];
        return nil;
    }] then:^RACSignal * _Nonnull{
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            [subscriber sendNext:@2];
            return nil;
        }];
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
}

- (void)testMerge {
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@"纸厂污水"];
        return nil;
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@"电镀厂污水"];
        return nil;
    }];
    [[RACSignal merge:@[signalA, signalB]] subscribeNext:^(id  _Nullable x) {
        NSLog(@"处理%@",x);
    }];
}


/**
 合并拆分信号
 */
- (void)testZip {
    RACSubject *letters = [RACSubject subject];
    RACSubject *numbers = [RACSubject subject];
    
    RACSubject *zipSignal = [RACSignal zip:@[letters, numbers] reduce:^id(NSString *letter, NSString *number) {
        return [letter stringByAppendingString:number];
    }];
    [zipSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    [letters sendNext:@"A"];
    [letters sendNext:@"B"];
    [numbers sendNext:@"1"];
    [numbers sendNext:@"2"];
    [numbers sendNext:@"3"];
    [letters sendNext:@"C"];
    
    [letters sendNext:@"D"];
    [numbers sendNext:@"4"];
}

- (void)testTakeUntil {
    [[[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [[RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSDate * _Nullable x) {
            [subscriber sendNext:@"去世界的尽头"];
        }];
        return nil;
    }] takeUntil:[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"尽头到了");
            [subscriber sendNext:@"尽头到了"];
        });
        return nil;
    }]] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
}


/**
 发送信号可以执行下一步，
 */
- (void)doNextOrCompleted {
    [[[[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendCompleted];
        return nil;
    }] doNext:^(id  _Nullable x) {
        NSLog(@"doNext");
    }] doCompleted:^{
        NSLog(@"doCompleted");
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];;
}


/**
 多次请求数据，请求全部完成后到UI刷新
 */
- (void)testLiftSelector {
    //第一部分数据
    RACSignal *section01Signal01 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        NSLog(@"section01数据请求");
        [subscriber sendNext:@"section01请求到的数据"];
        return nil;
    }];
    //第二部分数据
    RACSignal *section01Signal02 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        NSLog(@"section02数据请求");
        [subscriber sendNext:@"section02请求到的数据"];
        return nil;
    }];
    //第三部分数据
    RACSignal *section01Signal03 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        NSLog(@"section03数据请求");
        [subscriber sendNext:@"section03请求到的数据"];
        return nil;
    }];
    
    [self rac_liftSelector:@selector(refreshUI:::) withSignals:section01Signal01,section01Signal02,section01Signal03, nil];
}


/**
 刷新UI的操作

 @param str1 信号1的值
 @param str2 信号2的值
 @param str3 信号3的值
 */
- (void)refreshUI:(NSString *)str1 :(NSString *)str2 :(NSString *)str3 {
    NSLog(@"最终数据为:%@,%@,%@",str1,str2,str3);
}

- (void)testTimeOut {
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@"100"];
        return nil;
    }] timeout:1 onScheduler:[RACScheduler currentScheduler]];
    
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"一秒后会自动调用");
    }];
}


/**
 信号延迟
 */
- (void)testDelay {
    [[[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        NSLog(@"等等我，还有3秒");
        [subscriber sendNext:nil];
        [subscriber sendCompleted];
        return nil;
    }] delay:3] subscribeNext:^(id  _Nullable x) {
        NSLog(@"我到了");
    }];
}

/**
 打包信号传递给订阅者
 */
- (void)testReplay {
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        return nil;
    }] replay];
    
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"第一个订阅者%@",x);
    }];
    
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"第二个订阅者%@",x);
    }];
}

/**
 重试
 */
- (void)testRetry {
    __block int failedCount = 0;
    [[[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        if (failedCount < 5) {
            failedCount++;
            NSLog(@"我失败了");
            [subscriber sendError:nil];
        } else {
            NSLog(@"经历了五次失败后");
        }
        return nil;
    }] retry] subscribeNext:^(id  _Nullable x) {
        NSLog(@"终于成功了");
    }];
}
@end
