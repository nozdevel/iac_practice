#!/bin/bash
set -e

LAMBDA_DIR="$(dirname "$0")"
ZIP_NAME="lambda_layer.zip"
BUILD_DIR="$LAMBDA_DIR/build"

sudo rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

cp "$LAMBDA_DIR/../../../lambda/lauch_ansible_trigger/lambda_function.py" "$BUILD_DIR/lambda_function.py"

sudo docker build -t lambda-layer-build "$LAMBDA_DIR"
sudo docker run --rm -v "$BUILD_DIR":/output lambda-layer-build -c "cp -r /var/task/* /output/"


cd "$BUILD_DIR"
zip -r "$LAMBDA_DIR/$ZIP_NAME" .
mv -f "./$ZIP_NAME" "../$ZIP_NAME"
echo "Lambda ZIPファイルを作成しました: $LAMBDA_DIR/$ZIP_NAME"