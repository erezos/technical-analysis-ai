# Trading Tip Generator AI - Automated Device Testing Suite

This testing suite provides automated layout validation across multiple iOS device sizes to prevent App Store rejections due to layout issues.

## Overview

The testing suite captures screenshots of your Trading Tip Generator app running on different iOS simulators to validate that the UI renders correctly across various screen sizes and device types.

## Features

- **Multi-device testing**: iPad Air, iPhone 15, iPhone 13 mini
- **Intelligent app detection**: Waits for app to fully load before capturing screenshots
- **Automated simulator management**: Boots simulators as needed
- **Comprehensive reporting**: Generates detailed test reports with file sizes and status
- **Flexible configuration**: JSON-based configuration for easy customization
- **Single device testing**: Quick testing for specific devices

## Files

- `automated_device_testing.sh` - Main comprehensive testing script
- `test_single_device.sh` - Quick single device testing
- `device_test_config.json` - Configuration file for customization
- `TESTING_README.md` - This documentation

## Quick Start

### 1. Make scripts executable
```bash
chmod +x automated_device_testing.sh
chmod +x test_single_device.sh
```

### 2. Run full device testing
```bash
./automated_device_testing.sh
```

### 3. Test a single device
```bash
./test_single_device.sh iphone_13_mini
```

## Available Devices

| Device Key | Device Name | Screen Size | Status |
|------------|-------------|-------------|---------|
| `ipad_air` | iPad Air (5th generation) | 1180x820 | ✅ Enabled |
| `iphone_15` | iPhone 15 | 393x852 | ✅ Enabled |
| `iphone_13_mini` | iPhone 13 mini | 375x812 | ✅ Enabled |
| `iphone_15_pro` | iPhone 15 Pro | 393x852 | ⚪ Available |
| `ipad_pro_12_9` | iPad Pro (12.9-inch) | 1024x1366 | ⚪ Available |

## How It Works

### Intelligent App Detection
The testing suite uses a smart detection mechanism:

1. **Screenshot Analysis**: Takes test screenshots and analyzes file size
2. **Size Threshold**: Screenshots >1MB typically indicate app content vs. home screen
3. **Retry Logic**: Waits up to 75 seconds (15 attempts × 5 seconds) for app to load
4. **Fallback**: Captures screenshot even if app detection fails

### Testing Process
For each device:
1. Check if simulator exists
2. Boot simulator if needed
3. Launch Flutter app in release mode
4. Wait for app to load using intelligent detection
5. Capture final screenshot
6. Stop Flutter processes
7. Move to next device

## Output

### Screenshots
Screenshots are saved in `device_test_screenshots/` directory with naming format:
- `{device_key}_{timestamp}.png`
- Example: `iphone_13_mini_1750078533.png`

### Test Report
A detailed report is generated: `test_report_{timestamp}.txt`

Example report:
```
Trading Tip Generator AI - Device Testing Report
Generated: Wed Jan 15 10:30:45 PST 2025
Timestamp: 1750078533

Tested Devices:
- iPad Air (5th generation) (1180x820)
  Screenshot: ipad_air_1750078533.png (2MB)
  Status: SUCCESS

- iPhone 15 (393x852)
  Screenshot: iphone_15_1750078533.png (1MB)
  Status: SUCCESS

- iPhone 13 mini (375x812)
  Screenshot: iphone_13_mini_1750078533.png (1MB)
  Status: SUCCESS
```

## Configuration

Edit `device_test_config.json` to customize:

### Enable/Disable Devices
```json
"iphone_15_pro": {
  "name": "iPhone 15 Pro",
  "size": "393x852",
  "enabled": true,  // Change to true to enable
  "priority": 4
}
```

### Adjust Timing
```json
"test_settings": {
  "max_wait_attempts": 15,        // Number of detection attempts
  "wait_interval_seconds": 5,     // Seconds between attempts
  "screenshot_size_threshold_mb": 1 // MB threshold for app detection
}
```

## Troubleshooting

### Common Issues

**Simulator not found**
```bash
# List available simulators
xcrun simctl list devices
```

**App not launching**
- Ensure you're in the Flutter project directory
- Check that `pubspec.yaml` exists
- Verify Flutter is properly installed: `flutter doctor`

**Screenshots showing home screen**
- Increase `max_wait_attempts` in config
- Check if app builds successfully: `flutter build ios`
- Manually test app launch: `flutter run -d "iPhone 13 mini"`

**Permission errors**
```bash
# Make scripts executable
chmod +x *.sh
```

### Debug Mode

For debugging, you can:
1. Run single device tests: `./test_single_device.sh iphone_13_mini`
2. Check Flutter logs during testing
3. Manually verify simulator state: `xcrun simctl list devices`

## Integration with CI/CD

### GitHub Actions Example
```yaml
- name: Run Device Tests
  run: |
    chmod +x automated_device_testing.sh
    ./automated_device_testing.sh
    
- name: Upload Screenshots
  uses: actions/upload-artifact@v3
  with:
    name: device-screenshots
    path: device_test_screenshots/
```

### Pre-release Validation
Add to your release workflow:
```bash
# Run tests before building release
./automated_device_testing.sh

# Check if all tests passed
if [ $? -eq 0 ]; then
  echo "All device tests passed - proceeding with release"
  flutter build ipa
else
  echo "Device tests failed - blocking release"
  exit 1
fi
```

## Best Practices

1. **Run before each release** to catch layout issues early
2. **Test on actual problem devices** (especially iPhone 13 mini for small screens)
3. **Review screenshots manually** - automated detection isn't perfect
4. **Keep simulators updated** to match App Store review environment
5. **Test with release builds** (`--release` flag) for accurate performance

## Support

If you encounter issues:
1. Check the generated test report for specific error details
2. Verify simulator availability with `xcrun simctl list devices`
3. Test manual app launch with `flutter run`
4. Review Flutter doctor output: `flutter doctor -v`

## Version History

- **v1.0** - Initial release with iPad Air, iPhone 15, iPhone 13 mini support
- **v1.1** - Added intelligent app detection and comprehensive reporting
- **v1.2** - Added single device testing and JSON configuration 