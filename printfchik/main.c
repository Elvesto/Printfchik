void PrintfChik(const char* format, ...);

int main() {
    PrintfChik("tralalelo %o tralala\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n", -1, -1, "love", 3802, 100, 33, 127, -1, "love", 3802, 100, 33, 127);
}