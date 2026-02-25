{ pkgs, ... }:
let
  pythonWithHid = pkgs.python3.withPackages (ps: with ps; [ hidapi ]);

  qmkKeyboardSetupScript = pkgs.writeScriptBin "qmk-keyboard-setup" ''
    #!${pythonWithHid}/bin/python3
    import hid
    import sys
    import time

    KEYBOARD_IDS = [
        (0x4359, 0x0000),
        (0xFEED, 0x0001),
    ]

    def find_raw_hid_path():
        # RAW_HID is typically on interface 1 in QMK
        for vendor_id, product_id in KEYBOARD_IDS:
            devices = hid.enumerate(vendor_id, product_id)
            for d in devices:
                if d.get('interface_number') == 1:
                    return d['path']
        return None

    def send_unicode_mode_command(mode):
        raw_hid_path = find_raw_hid_path()

        if not raw_hid_path:
            print("RAW_HID interface (interface 1) not found", file=sys.stderr)
            return 1

        try:
            device = hid.device()
            device.open_path(raw_hid_path)
            device.set_nonblocking(1)

            data = bytearray(32)
            data[0] = mode

            # Send HID command to keyboard, which triggers raw_hid_receive() in QMK firmware
            bytes_written = device.write(data)
            device.close()

            mode_name = "macOS" if mode == 0x01 else "Linux"
            print(f"Successfully set keyboard to {mode_name} Unicode mode ({bytes_written} bytes written)")
            return 0
        except Exception as e:
            print(f"Error communicating with keyboard: {e}", file=sys.stderr)
            return 1

    if __name__ == "__main__":
        # Wait for USB device enumeration to complete before attempting HID communication
        time.sleep(0.1)

        # Default to Linux mode (0x02), or accept command line argument
        # Usage: qmk-keyboard-setup [0x01|0x02]
        mode = 0x02
        if len(sys.argv) > 1:
            try:
                mode = int(sys.argv[1], 16)
            except ValueError:
                print("Usage: qmk-keyboard-setup [0x01|0x02]", file=sys.stderr)
                sys.exit(1)

        sys.exit(send_unicode_mode_command(mode))
  '';

in
{
  environment.systemPackages = [
    qmkKeyboardSetupScript
  ];

  _module.args.qmkKeyboardSetupScript = qmkKeyboardSetupScript;
}
