"""
UART communication for loading instructions and reading data
"""

import serial
import struct
import argparse

CMD_WRITE = 0x57 # 87 = W
CMD_READ = 0x52 # 82 = R 
CMD_PING = 0x50 # 80 = P

class UART:
    """Translates bit/hex values into serial UART for FPGA"""

    def __init__(self, port, baud_rate=9600, timeout=2):
        """
        Initialize UART connection
        """
        self.port = port
        self.baud_rate = baud_rate
        self.timeout = timeout # in seconds
        try: 
            self.ser = serial.Serial(
                port=self.port, 
                baudrate=self.baud_rate, 
                timeout=self.timeout)
            print(f"Opened serial port {self.port} with {self.baud_rate} baud")
        except serial.SerialException as e: # specific pyserial port connect issue
            print(f"Error: Could not open serial port {self.port} due to {e}")
            exit(1)

    def close(self):
        """Closes serial connection"""
        if self.ser and self.ser.is_open:
            self.ser.close()
            print(f"Serial port closed")

    def ping(self):
        """Send ping to test connection""" 
        if not self.ser:
            print("Not connected")
            return False

        try:
            send = struct.pack('>B', CMD_PING)
            self.ser.write(send) # write and read 1 byte
            response = self.ser.read(1)
            # response bytes type vs int type, so first index into response 
            return len(response) == 1 and response[0] == 0x41  # 65 = A
        except Exception as e:
            print(f"Error: Ping failed due to {e}")
            return False    

    def write_word(self, addr, data): 
        """Writes a 32-bit word to addr (big-endian), returns bool"""
        if not self.ser:
            print("Not connected")
            return False
        
        try:
            # command (1 byte) + addr (4 bytes) + data (4 bytes)
            # packs CMD, addr, and data into raw bytes
            send = struct.pack('>BII', CMD_WRITE, addr, data)
            self.ser.write(send)
            # wait for acknowledge
            response = self.ser.read(1)
            success = len(response) == 1 and response[0] == 0x41  # 'A'
            # don't leave this when actually running, slows program down:
            # if success: 
            #     print(f"Write successful: 0x{addr:08X} = 0x{data:08X}")
            if not success: 
                print(f"Write failed: 0x{addr:08X} = 0x{data:08X}")
            return success
        except Exception as e:
            print(f"Error: Write failed due to {e}")
            return False
        

    def read_word(self, addr):
        """Reads a 32-bit word from addr, returns 32-bit data (tuple)"""
        if not self.ser:
            print("Not connected")
            return None # not bool
        
        try:
        # command (1 byte) + addr (4 bytes)
            send = struct.pack('>BI', CMD_READ, addr)
            self.ser.write(send)
        
            # wait for FPGA's data (4 bytes)
            response = self.ser.read(4)
            if len(response) == 4:
                data = struct.unpack('>I', response)[0] # otherwise might give [...,]
                # print(f"Read successful: 0x{addr:08X} = 0x{data:08X}")
                return data
            else:
                print(f"Read failed: 0x{addr:08X} (had {len(response)} bytes)")
                return None
        except Exception as e:
            print(f"Error: Write failed due to {e}")
            return None
        
    def load_instrs(self, instrs, start_addr):
        """Load list of instrs into CPU memory, returns bool"""
        print(f"Loading {len(instrs)} instrs starting at 0x{start_addr:08X}")
        
        success = True
        for i, instr in enumerate(instrs):
            addr = start_addr + (i * 4)  # word aligned
            if not self.write_word(addr, instr):
                success = False # if any write fails
                
        # if success:
        #     print("Instrs load successful")
        if not success:
            print("Instrs load failed")
            
        return success
    
    def dump_memory(self, start_addr, word_count):
        """Dump memory contents"""
        print(f"Dumping {word_count} words from 0x{start_addr:08X}")    
        for i in range(word_count):
            addr = start_addr + (i * 4)
            word = self.read_word(addr) 
            if word is not None:
                print(f"0x{addr:08X}: 0x{word:08X}")
            else:
                print(f"Failed to read addr 0x{addr:08X}")
                break # stop before continuing

    def load_hex_file(self, filename, start_addr=0):
        """Load instrs from hex file, returns bool"""
        instrs = []
        try:
            with open(filename, 'r') as f:
                for i, instr in enumerate(f):
                    if instr and not instr.startswith('#'): # skip empty or comments
                        try:
                            instrs.append(int(instr, 16))
                        except ValueError:
                            print(f"Not valid hex {instr} on line {i}")
        
            print(f"Loaded {len(instrs)} instrs from {filename}")
            return self.load_instrs(instrs, start_addr)

        except Exception as e:
            print(f"Failed to load program due to {e}")

# main function

def main():
    parser = argparse.ArgumentParser(description='UART interface')
    parser.add_argument('--port', default='COM3',help="Serial port")
    parser.add_argument('--baud', type=int, default=9600, help='Baud rate')
    parser.add_argument('--load', help='Hex file to load')
    parser.add_argument('--addr', type=lambda x: int(x, 0), default=0x00000000, help='Load address')

    args = parser.parse_args()

    # connect with class
    uart = UART(args.port, args.baud)

    try: # if run into any errors, close file
        if args.load:
            uart.load_hex_file(args.load, args.addr)
        else:
            print("No file to load")
        
        print("\nCommands:")
        print(" w <addr> <data> - Write word")
        print(" r <addr>        - Read word") 
        print(" d <addr> <cnt>  - Dump memory")
        print(" l <filename>    - Load hex file")
        print(" p               - Ping")
        print(" q               - Quit")

        while True: # stay on this until quit
            try:
                cmd = input("\n> ").strip().split()
                if not cmd:
                    continue # if empty
                

                if cmd[0] == 'w' and len(cmd) >= 3: # write
                    addr = int(cmd[1], 0)
                    data = int(cmd[2], 0)
                    if uart.write_word(addr, data):
                        print(f"Write successful: 0x{addr:08X} = 0x{data:08X}")
                elif cmd[0] == 'r' and len(cmd) >= 2: # read
                    addr = int(cmd[1], 0)
                    data = uart.read_word(addr)
                    if data is not None:
                        print(f"Read: 0x{addr:08X} = 0x{data:08X}")
                elif cmd[0] == 'd' and len(cmd) >= 3: # dump
                    addr = int(cmd[1], 0)
                    count = int(cmd[2], 0)
                    uart.dump_memory(addr, count)
                elif cmd[0] == 'l' and len(cmd) >= 2: # load
                    filename = cmd[1]
                    addr = 0
                    if len(cmd) >= 3: # addr optional
                        addr = int(cmd[2], 0)  
                    uart.load_hex_file(filename, addr)
                elif cmd[0] == 'p':
                    if uart.ping():
                        print("Ping succeeded")
                    else:
                        print("Ping failed")
                elif cmd[0] == 'q':
                    break
                else:
                    print("Invalid command")

            except KeyboardInterrupt: # Ctrl+C
                break
            except Exception as e:
                print("Invalid command due to {e}")
                break
    
    finally:
        uart.close()

if __name__ == '__main__':
    main()
