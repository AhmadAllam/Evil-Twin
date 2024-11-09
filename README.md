# Info
Follow the instructions in the script :)
Simply, you can run the evil twin on your Android phone with NetHunter.

## Features

- It works without complications.
- It operates with the Android hotspot.
- It works in both manual and automatic modes for easy troubleshooting.

## Requirements

- Android (rooted)
- Wi-Fi adapter that supports monitor mode
- OTG
- NetHunter

## Usage

To run the script, use the following command:
```bash
./evil.sh -t <target_mac_address> -c <channel_number>
```
- `<target_mac_address>`: MAC address of the target device.
- `<channel_number>`: Channel number to be used.

## Example

- Using without default values:
```bash
./evil.sh -t 3c:84:a1:bf:17:a7 -c 7
```

- Using with default values in script:
```bash
./evil.sh
```