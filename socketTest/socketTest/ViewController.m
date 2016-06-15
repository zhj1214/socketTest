//
//  ViewController.m
//  socketTest
//
//  Created by apple on 16/3/11.
//  Copyright © 2016年 HangZhouBenHu. All rights reserved.
//

#import "ViewController.h"
#import "ReactiveCocoa.h"
#import "GCDAsyncSocket.h"//导入socket框架
@interface ViewController ()<UITextFieldDelegate,GCDAsyncSocketDelegate>
{
    GCDAsyncSocket *_socket;
}
@property (weak, nonatomic) IBOutlet UITextField *Textfiled;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inputkeybordHeight;
@property (nonatomic, strong) NSMutableArray *chatMsgs;//聊天消息数组

@end
@implementation ViewController
-(NSMutableArray *)chatMsgs{
    if (!_chatMsgs) {
        _chatMsgs = [NSMutableArray array];
    }
    return _chatMsgs;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //监听键盘高度
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardWillChangeFrameNotification object:nil] subscribeNext:^(NSNotification* info) {
        NSLog(@"键盘将要弹出");
        CGFloat view_H = [UIScreen mainScreen].bounds.size.height;
        CGRect Keybord_f = [info.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGFloat Kyebore_y = Keybord_f.origin.y;
        _inputkeybordHeight.constant = view_H - Kyebore_y;
    }];
}
#pragma mark - 连接服务器
- (IBAction)LianJieFWQ:(id)sender {
    NSString *host_IP =@"127.0.0.1";
    int port_DK = 12345;
    _socket =[[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    NSError *error;
    [_socket connectToHost:host_IP onPort:port_DK error:&error];//建立连接
    if (error) {
        NSLog(@"连接错误信息：%@",error);
    }
}
#pragma mark - 登录
- (IBAction)DengLu:(id)sender {
    NSString*login_name = @"iam:zhj";
    NSData *login_data = [login_name dataUsingEncoding:NSUTF8StringEncoding];
    [_socket writeData:login_data withTimeout:-1 tag:101];//登录发送数据
}
#pragma mark - UITextFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    NSString *text = textField.text;
    
    NSLog(@"textFieldShouldReturn--%@",text);
    // 聊天信息
    NSString *msgStr = [NSString stringWithFormat:@"我说:%@",text];
    
    //把Str转成NSData
    NSData *data = [msgStr dataUsingEncoding:NSUTF8StringEncoding];
    
    
    
    // 发送数据
    //    [_outputStream write:data.bytes maxLength:data.length];
    NSLog(@"nadata--%@",data);
    [_socket writeData:data withTimeout:-1 tag:11];
    // 刷新表格
    [self reloadDataWithText:msgStr];
    // 发送完数据，清空textField
    textField.text = nil;
    
    return YES;
}

#pragma mark - custom method
/**
 *  刷新表格数据
 */
-(void)reloadDataWithText:(NSString *)text{
    
    [self.chatMsgs addObject:text];
    
    //UI刷新要在主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_TableView reloadData];
        
        // 数据多，应该往上滚动
        NSIndexPath *lastPath = [NSIndexPath indexPathForRow:self.chatMsgs.count - 1 inSection:0];
        [_TableView scrollToRowAtIndexPath:lastPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    });
    
}

#pragma mark tableView数据源
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.chatMsgs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *ID = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:1 reuseIdentifier:ID];
    }
    
    cell.textLabel.text = self.chatMsgs[indexPath.row];
    
    return cell;
}

#pragma mark - GCDAsyncSocketDelegate，所有代理方法都在子线程执行
#pragma mark - 连接主机成功
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"连接主机成功");
}
#pragma mark - 与主机断开连接
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if (err) {
        NSLog(@"断开连接:%@",err);
    }
}

#pragma mark -  数据成功发送到服务器
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"数据成功发送到服务器-----%ld",tag);
    
    //数据发送成功后，自己调用以下读取数据的方法，接着_socket才会调用下面的代理方法
    [sock readDataWithTimeout:-1 tag:tag];
    
}

#pragma mark - 服务器有数据，会调用这个方法
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    // 从服务器接收到的数据
    NSLog(@"数——————————————————%@——————————",data);
    NSString *recStr =  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSLog(@"%@ %ld %@",[NSThread currentThread],tag,recStr);
    
    //    if (tag == 101) {//如果是登录返回的数据，不应该把数据添加到表格里
    //        //不做任何操作
    //    }else if (tag == 102){//聊天返回的数据
    //        //刷新表格
    //        [self reloadDataWithText:recStr];
    //    }
    
    if (tag == 11){//聊天返回的数据
        //刷新表格
        [self reloadDataWithText:recStr];
    }
    
}




#pragma mark tableView代理
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    
    [self.view endEditing:YES];
}









- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
