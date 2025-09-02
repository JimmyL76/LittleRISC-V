import serial
import struct

CMD_WRITE = 1
CMD_READ = 2

class UARTLoader:
    """
    Translates bit/hex values into serial UART for FPGA 
    """
    def __init__(self, port, baud_rate=9600):
        """
        Initialize UARTLoader
        """
        self.port = port
        self.baud_rate = baud_rate
        try: 
            self.ser = serial.Serial(self.port, self.baud_rate, timeout=2)
            print(f"Opened serial port {self.port} with {self.baud_rate} baud")
        except serial.SerialException as e:
            print(f"Error: Could not open serial port {self.port} due to {e}")
            exit(1)

    def close(self):
        """
        Closes serial connection
        """
        if self.ser and self.ser.is_open:
            self.ser.close()
            print("Serial port closed")

    def write_word(self, address, data):
        """
        Writes a 32-bit word to addr (big-endian)
        """
        # command (1 byte) + addr (4 bytes) + data (4 bytes)
        # packs CMD, addr, and data into raw bytes
        payload = struct.pack('>BII', CMD_WRITE, address, data)
        self.ser.write(payload)
        # don't leave this when actually running, slows program down:
        # print(f"Write: Addr=0x{address:08X}, data=0x{data:08X}")

    def read_word(self, address):
        """
        Reads a 32-bit word from addr, returns int
        """
        # command (1 byte) + addr (4 bytes)
        payload = struct.pack('>BI', CMD_READ, address)
        self.ser.write(payload)
        
        # wait for FPGA's data (4 bytes)
        response = self.ser.read(4)
        if len(response) < 4:
            raise TimeoutError("Timeout: <4 bytes from FPGA")
            
        data = struct.unpack('>I', response)[0]
        # print(f"Read: Addr=0x{address:08X}, data=0x{data:08X}")
        return data