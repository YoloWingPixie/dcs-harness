import os
import stat
import sys


def main():
    operation, path = sys.argv[1:]
    try:
        if operation == "mkdir":
            os.mkdir(path)
            print("directory")
        else:
            info = os.stat(path)
            print("directory" if stat.S_ISDIR(info.st_mode) else "file")
            print(info.st_size)
    except OSError as error:
        print("error")
        print(error.errno)


if __name__ == "__main__":
    main()
