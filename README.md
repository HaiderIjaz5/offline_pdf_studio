# Offline PDF Studio

Offline PDF Studio is a versatile, privacy-focused Flutter application designed for managing and editing PDF files completely offline. 

## Features
- **Offline Processing:** All PDF operations are performed locally on your device, ensuring complete privacy and security for your documents. No internet connection is required.
- **Image to PDF:** Convert one or more images into a single PDF document.
- **PDF to Image:** Extract images from your PDF files or convert pages to images.
- **Merge PDFs:** Combine multiple PDF documents into one.
- **Split PDFs:** Separate a single PDF into multiple documents or extract specific pages.
- **PDF Viewer:** View your documents quickly with an integrated, fast PDF reader.

## Getting Started

To build and run this project, ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.

1. **Clone the repository:**
   ```bash
   git clone https://github.com/HaiderIjaz5/offline_pdf_studio.git
   cd offline_pdf_studio
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## Security & Privacy
This app is designed with a privacy-first approach. Because all operations are local, sensitive files are never uploaded to any cloud service. 

Additionally, the repository is configured to exclude sensitive keys (`key.properties`, `.keystore`, `.env`, `google-services.json`) from version control to prevent accidental leaks.

## License
© 2026 ABH Softworks. All Rights Reserved.
