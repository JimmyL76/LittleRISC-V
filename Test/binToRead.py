import argparse
import os
import struct

def main():
    parser = argparse.ArgumentParser(description="Convert RISC-V .bin to Vivado .mem format (32-bit Little Endian fix).")
    parser.add_argument("input", help="Path to the source .bin file")
    parser.add_argument("-o", "--output", help="Path to the output .mem file", required=True)
    
    args = parser.parse_args()

    if not os.path.exists(args.input):
        print(f"Error: File '{args.input}' not found.")
        return

    with open(args.input, 'rb') as f:
        data = f.read()

    # Pad data with 0s if it's not a multiple of 4 bytes
    remainder = len(data) % 4
    if remainder != 0:
        padding = 4 - remainder
        data += b'\x00' * padding
        print(f"Note: Padded input with {padding} zero-bytes to align to 32-bits.")

    with open(args.output, 'w') as f:
        # Process 4 bytes at a time
        for i in range(0, len(data), 4):
            chunk = data[i:i+4]
            # unpack as Little Endian unsigned int ('<I')
            # format as 8-char Hex string
            val = struct.unpack('<I', chunk)[0]
            f.write(f"{val:08x}\n")

    print(f"Success! formatted {len(data)//4} words to {args.output}")

if __name__ == "__main__":
    main()