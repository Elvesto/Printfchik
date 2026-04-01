CC = g++
CFLAGS = -Wall -Wextra -no-pie
ASM = nasm
ASMFLAGS = -f elf64

TARGET = printfchik.out
OBJS = main.o printfchik.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o $(TARGET)

main.o: main.c
	$(CC) $(CFLAGS) -c main.c -o main.o

printfchik.o: printfchik.asm
	$(ASM) $(ASMFLAGS) printfchik.asm -o printfchik.o

clean:
	rm -f $(OBJS) $(TARGET) a.out

re: clean all