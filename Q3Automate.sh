#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <ASM_FILE> <SHELLCODE_SERVER>"
    exit 1
fi

ASM_FILE=$1
SHELLCODE_SERVER=$2

# Verify if the ASM file exists
if [ ! -f "$ASM_FILE" ]; then
    echo "Error: ASM file '$ASM_FILE' not found!"
    exit 1
fi

# Verify if the shellcode server exists
if [ ! -f "$SHELLCODE_SERVER" ]; then
    echo "Error: Shellcode server '$SHELLCODE_SERVER' not found!"
    exit 1
fi

# Define the filenames
BASENAME=$(basename "$ASM_FILE" .asm)
OBJ_FILE="${BASENAME}.o"
EXEC_FILE="${BASENAME}"
PYTHON_FILE="harness.py"

# Assemble the ASM file
echo "Assembling $ASM_FILE to $OBJ_FILE"
nasm -f elf32 "$ASM_FILE" -o "$OBJ_FILE"
if [ $? -ne 0 ]; then
    echo "Assembly failed!"
    exit 1
fi

# Link the object file to create an executable
echo "Linking $OBJ_FILE to create $EXEC_FILE"
ld -m elf_i386 -o "$EXEC_FILE" "$OBJ_FILE"
if [ $? -ne 0 ]; then
    echo "Linking failed!"
    exit 1
fi

# Extract the shellcode bytes using objdump
SHELLCODE=$(objdump -d "$EXEC_FILE" | grep '[0-9a-f]:' | grep -oP '\s\K[0-9a-f]{2}' | tr -d '\n' | sed 's/\(..\)/\\x\1/g')

# Check if shellcode extraction was successful
if [ -z "$SHELLCODE" ]; then
    echo "Shellcode extraction failed!"
    exit 1
fi

echo "Extracted Shellcode: $SHELLCODE"

# Escape backslashes for Python string literal
ESCAPED_SHELLCODE=$(printf '%s\n' "$SHELLCODE" | sed 's/\\/\\\\/g')

# Replace the shellcode in the Python harness dynamically
sed -i "s/shellcode = \".*\"/shellcode = \"$ESCAPED_SHELLCODE\"/" $PYTHON_FILE
if [ $? -ne 0 ]; then
    echo "Updating shellcode in Python harness failed!"
    exit 1
fi

# Start the shellcode server in the background
echo "Starting shellcode server $SHELLCODE_SERVER"
"$SHELLCODE_SERVER" &
SERVER_PID=$!

# Wait a bit for the server to start
sleep 2

# Run the Python harness to test the shellcode using Python 2.7
echo "Running Python harness $PYTHON_FILE"
python2.7 "$PYTHON_FILE"
if [ $? -ne 0 ]; then
    echo "Running Python harness failed!"
    kill $SERVER_PID
    exit 1
fi

echo "Shellcode test completed successfully!"

# Stop the shellcode server
kill $SERVER_PID
