#!/bin/bash

# Define the filenames
ASM_FILE=$(ls *.asm | head -n 1)
OBJ_FILE="${ASM_FILE%.asm}.o"
EXEC_FILE="${ASM_FILE%.asm}"
PYTHON_FILE="harness.py"

# Assemble the ASM file
nasm -f elf32 $ASM_FILE -o $OBJ_FILE
if [ $? -ne 0 ]; then
    echo "Assembly failed!"
    exit 1
fi

# Link the object file to create an executable
ld -m elf_i386 -o $EXEC_FILE $OBJ_FILE
if [ $? -ne 0 ]; then
    echo "Linking failed!"
    exit 1
fi

# Extract the shellcode bytes using objdump
SHELLCODE=$(objdump -d $OBJ_FILE | grep '[0-9a-f]:' | grep -oP '\s\K[0-9a-f]{2}' | tr -d '\n' | sed 's/\(..\)/\\x\1/g')

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

# Run the Python harness to test the shellcode using Python 2.7
python2.7 $PYTHON_FILE
if [ $? -ne 0 ]; then
    echo "Running Python harness failed!"
    exit 1
fi

echo "Shellcode test completed successfully!"
