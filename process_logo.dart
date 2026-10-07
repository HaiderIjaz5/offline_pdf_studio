import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/logo.png');
  if (!file.existsSync()) {
    print('assets/logo.png not found');
    return;
  }
  
  final bytes = file.readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) {
    print('Failed to decode image');
    return;
  }
  
  bool hasTransparency = false;
  for (final p in image) {
    if (p.a < 255) {
      hasTransparency = true;
      break;
    }
  }
  
  if (hasTransparency) {
    print('Image already has transparency');
  } else {
    print('Image has no transparency. Removing white background...');
    for (final p in image) {
      if (p.r > 240 && p.g > 240 && p.b > 240) {
        p.a = 0;
      }
    }
    File('assets/logo_transparent.png').writeAsBytesSync(img.encodePng(image));
    print('Saved to assets/logo_transparent.png');
  }
}
