#!/bin/bash

# Fast fail the script on failures.
set -e

echo "Downloading Flutter"

# Run doctor to download the Dart SDK that is vendored with Flutter

(cd ..; git clone https://github.com/flutter/flutter.git ; cd flutter ; ./bin/flutter doctor)

echo "Download Google OAuth Calendar"

pip install --user google-oauth2l --upgrade