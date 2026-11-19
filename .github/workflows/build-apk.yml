name: Build diubangNASServer Android Debug APK
on:
  push:
    branches: [ main ]
  workflow_dispatch:
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '11'
      - run: chmod +x gradlew
      - run: |
          sed -i 's/mavenCentral()/maven { url "https://maven.aliyun.com/repository/public" }\nmavenCentral()/g' build.gradle
          sed -i 's/google()/maven { url "https://maven.aliyun.com/repository/google" }\ngoogle()/g' build.gradle
      - run: ./gradlew assembleDebug
      - uses: actions/upload-artifact@v4
        with:
          name: diubangNASServer-debug-apk
          path: app/build/outputs/apk/debug/app-debug.apk
