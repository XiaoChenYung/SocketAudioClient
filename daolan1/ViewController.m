//
//  ViewController.m
//  daolan1
//
//  Created by tm on 2017/3/15.
//  Copyright © 2017年 tm. All rights reserved.
//

#import "ViewController.h"
#include<stdio.h>
#include<unistd.h>
#include<strings.h>
#include<sys/types.h>
#include<sys/socket.h>
#include<netinet/in.h>
#include<netdb.h>
#define BUFFER_SIZE 1024

@interface ViewController (){
    int toServerSocket;
}
@property (weak, nonatomic) IBOutlet UITextField *ipAddress;
@property (weak, nonatomic) IBOutlet UITextField *portAddress;
@property (weak, nonatomic) IBOutlet UITextField *msgTextField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)connect:(UIButton *)sender {
    NSLog(@"conn server...");
    
    if(toServerSocket !=0){
        [self sendToServer:@"-"];
        close(toServerSocket);
    }
    
    struct hostent *he;
    struct sockaddr_in server;
    
    NSString *ip = self.ipAddress.text;
    NSString *port = self.portAddress.text;
    
    if((he = gethostbyname([ip cStringUsingEncoding:NSUTF8StringEncoding])) == NULL)
    {
        printf("gethostbyname error/n");
        //exit(1);
    }
    if((toServerSocket = socket(AF_INET, SOCK_STREAM, 0)) == -1)
    {
        printf("socket() error /n");
        //exit(1);
    }
    bzero(&server, sizeof(server));
    
    server.sin_family = AF_INET;
    server.sin_port = htons([port intValue]);
    server.sin_addr = *((struct in_addr *)he->h_addr);
    
    if(connect(toServerSocket, (struct sockaddr *)&server, sizeof(server)) == -1)
    {
        printf("\n connetc() error ");
        // exit(1);
    }
    
    
    
    
    [self startListenAndNewThread];

}

// 在新线程中监听客户端
-(void) startListenAndNewThread{
    [NSThread detachNewThreadSelector:@selector(initServer)
                             toTarget:self withObject:nil];
}

-(void)initServer {
    char buffer[BUFFER_SIZE];
    int result = recv(toServerSocket, &buffer, BUFFER_SIZE, 0);
    NSString * mystring = [NSString stringWithUTF8String:buffer];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.msgTextField.text = mystring;
    });
    
    
}

//// 读客户端数据
//-(void) readData:(NSNumber*) clientSocket{
//    char buffer[BUFFER_SIZE];
//    int intSocket = [clientSocket intValue];
//    
//    while(buffer[0] != '-'){
//        
//        bzero(buffer,BUFFER_SIZE);
//        //接收客户端发送来的信息到buffer中
//        recv(intSocket,buffer,BUFFER_SIZE,0);
//        NSString * mystring = [NSString stringWithUTF8String:buffer];
//        self.msgTextField.text = mystring;
//        printf("client:%s\n",buffer);
//    }
//    //关闭与客户端的连接
//    printf("client:close\n");
//    close(intSocket);
//    
//}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.ipAddress resignFirstResponder];
    [self.msgTextField resignFirstResponder];
    [self.portAddress resignFirstResponder];
}

- (IBAction)send:(UIButton *)sender {
    [self sendToServer:self.msgTextField.text];
}

-(void) sendToServer:(NSString*) message{
    NSLog(@"send message to server...");
    
    char mychar[1024];
    strcpy(mychar,(char *)[message UTF8String]);

    
    char buffer[BUFFER_SIZE];
    bzero(buffer, BUFFER_SIZE);
    //Byte b;
//    const char* talkData =
//    [ message cStringUsingEncoding:NSUTF8StringEncoding];
    
    //发送buffer中的字符串到new_server_socket,实际是给客户端
    send(toServerSocket,mychar,1024,0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
