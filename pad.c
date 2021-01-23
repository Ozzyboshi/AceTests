#include <stdio.h>
#include <string.h>

#include <stdlib.h>
#include <sys/stat.h>

#define byteRef 0x00
//#define firstChunk 0x2

#define VERBOSE

void printhelp();
unsigned int getFileSize(const char*);

int main(int argc,char** argv)
{
    char* fileInput;
    unsigned char padder;
    unsigned int newFileSize;
    unsigned int fileSize;
    unsigned int secondChunk;
    unsigned int paddingChunk;
    unsigned int firstChunk; 
    char* fileOutput;
    
    FILE* fd;
    FILE* fd2;
    unsigned char* memTmp;
    int tmp;
    
    if (argc<4) 
    {
        printhelp();
    }
    
    // Input params
    fileInput = argv[1];
    padder = (unsigned char)atoi(argv[2]);
    newFileSize = (unsigned int) atoi(argv[3]);
    firstChunk = (unsigned int) atoi(argv[4]);
    fileOutput = argv[5];
    
    // Get file and chunk sizes
    fileSize = getFileSize(fileInput);
    if (fileSize >= newFileSize)
    {
        printf("New file size must be greater that the original file size (%u)\n",fileSize);
        printhelp();
    }
    if (atoi(argv[4])<0) firstChunk=fileSize;
    if (atoi(argv[3])<0)
    {
        tmp=(int)(fileSize/512);
        tmp++;
        newFileSize = tmp*512;
    }
    
    secondChunk = fileSize - firstChunk;
    paddingChunk = newFileSize -  fileSize;
    printf("File size : %u bytes\n",fileSize);
    printf("First chunk : %u bytes\n",firstChunk);
    printf("Second chunk : %u bytes\n",secondChunk);
    printf("Padding chunk : %u bytes\n",paddingChunk);
    printf("Final size : %u bytes\n",newFileSize);
    printf("File output : %s\n",fileOutput);
    
    // Create first chunk
    printf("\n\n");
    printf("Writing first chunk...\n");
    fd = fopen(fileInput,"r");
    if (!fd)
    {
        printf("File %s not found or readable\n",fileInput);
        printhelp();
    }
    printf("Allocating....\n");
    memTmp = malloc(firstChunk);
    printf("Reading source...\n");
    fread(memTmp, firstChunk, 1 , fd);
    printf("fred done....\n");
    fd2 = fopen(fileOutput,"w");
    if (fd2==0) 
    {
        printf("Error writing\n");
        exit(1);
    }
    printf("Writing...\n");
    fwrite(memTmp,firstChunk,1,fd2);
    printf("Written...\n");
    fflush(fd2);
    printf("fflush\n");
    fclose(fd);
    fclose(fd2);
    printf("Close\n");
    
    free(memTmp);
    printf("freed\n");
    printf("First chunk written (%u bytes)!\n",firstChunk);
    
    // Padding process
    printf("Padding %u bytes\n",paddingChunk);
    memTmp = malloc(paddingChunk);
    memset(memTmp,padder,paddingChunk);
    fd2 = fopen(fileOutput,"a");
    if (fd2==0) 
    {
        printf("Error appending\n");
        exit(1);
    }
    fwrite(memTmp,paddingChunk,1,fd2);
    fflush(fd2);
    fclose(fd2);
    free(memTmp);
    printf("Padding done!\n");
    if (firstChunk>fileSize)
    {
        printf("Writing second chunk\n");
    
        // Append second chunk
        fd = fopen(fileInput,"r");
        if (!fd) printhelp();
        fseek(fd,firstChunk,SEEK_SET);
        memTmp = malloc(secondChunk);
        fread(memTmp, secondChunk, 1 , fd);
        fd2 = fopen(fileOutput,"a");
        fwrite(memTmp,secondChunk,1,fd2);
        fflush(fd2);
        fclose(fd);
        fclose(fd2);
    
        free(memTmp);
        printf("Writing second chunk done!\n");
    }
    
    printf("Padding succeded\n");
    exit(0);
}

unsigned int getFileSize(const char* fileName)
{
    struct stat st;
    stat(fileName, &st);
    return (unsigned int) st.st_size;
}

void printhelp()
{
    printf("pad fileinput padder newfilesize addrStartPadding fileoutput \n");
    printf("\n");
    printf("	- newfilesize or -1 to the nearest successive 512bytes multiple\n");
    printf("	- addrStartpadding at -1 pads to the end\n");
    exit(0);
}