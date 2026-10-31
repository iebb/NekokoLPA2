import asyncio
from bleak import BleakScanner, BleakClient

DEVICE_NAME = "9eSIM123456"
# Nordic UART Service UUIDs
UART_SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
UART_WRITE_CHAR_UUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
UART_NOTIFY_CHAR_UUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

async def main():
    print(f"Scanning for {DEVICE_NAME}...")
    device = await BleakScanner.find_device_by_filter(
        lambda d, ad: d.name and d.name == DEVICE_NAME
    )

    if not device:
        print("Device not found.")
        return

    print(f"Found {device.name}, connecting...")
    async with BleakClient(device) as client:
        print("Connected.")
        
        await client.start_notify(UART_NOTIFY_CHAR_UUID, lambda sender, data: print(f"RX: {data.hex()}"))
        print("Notifications started.")
        print("Done.")

if __name__ == "__main__":
    asyncio.run(main())
