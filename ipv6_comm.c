#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <time.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <pthread.h>
#define MAXLINE 1024
#define TRUE    1
void *server() {
     int sockfd, fd, n, m;
     char line[MAXLINE + 1];
     struct sockaddr_in6 servaddr, cliaddr;
     time_t t0 = time(NULL);
     printf("time #: %ld\n", t0);
     fputs(ctime(&t0), stdout);
     if((sockfd = socket(AF_INET6, SOCK_STREAM, 0)) < 0)
         perror("socket error");
    bzero(&servaddr, sizeof(servaddr));
    servaddr.sin6_family = AF_INET6;
    servaddr.sin6_port = htons(20000);
    servaddr.sin6_addr = in6addr_any;
    if(bind(sockfd, (struct sockaddr*)&servaddr, sizeof(servaddr)) == -1)
         perror("bind error");
    if(listen(sockfd, 5) == -1)
         perror("listen error");
    while(TRUE) {
        printf("> Waiting clients ...\r\n");
        socklen_t clilen = sizeof(struct sockaddr);
        fd = accept(sockfd, (struct sockaddr*)&cliaddr, &clilen);
         if(fd == -1)  {
             perror("accept error");
         }
        printf("> Accepted.\r\n");
        while((n = read(fd, line, MAXLINE)) > 0) {
		line[n] = 0;
		printf(">>");
             if(fputs(line, stdout) == EOF)
                 perror("fputs error");
	      if(strcmp(line,"END\n")==0)
		                           exit(0); 
         }
         close(fd);
     }
    if(n < 0) perror("read error");
 }
void *client(){
    int sockfd, n, m;
    char line[MAXLINE + 1];
    char targetIP[] ="2001:da8:d800:790:e59a:a8e7:523f:38e9";
    struct sockaddr_in6 servaddr;
    if((sockfd = socket(AF_INET6, SOCK_STREAM, 0)) < 0)
        perror("socket error");
    bzero(&servaddr, sizeof(servaddr));
    servaddr.sin6_family = AF_INET6;
    servaddr.sin6_port = htons(20000);
    printf("%s",targetIP);
    if(inet_pton (AF_INET6, targetIP, &servaddr.sin6_addr) <= 0){
        perror("inet_pton error");
    }
    while(connect(sockfd, (struct sockaddr*)&servaddr, sizeof(servaddr)) < 0){
        perror("connect error");
	sleep(3);
    }
    while(fgets(line, MAXLINE, stdin) != NULL) {
         send(sockfd, line, strlen(line), 0);
	 if(strcmp(line,"END\n")==0)
		              exit(0);
     }
}
int main(int argc, char **argv){
    pthread_t tid_server,tid_client;
    pthread_create(&tid_server,NULL,server,NULL);
    pthread_create(&tid_client,NULL,client,NULL);
    pthread_exit(NULL);

}

