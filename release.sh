#!/bin/bash

VERSION=$(cat pubspec.yaml | grep version: | cut -d ' ' -f2)
echo "Version: v$VERSION"
git commit pubspec.yaml -m 'new version'
git tag "v$VERSION" HEAD
git push --tags origin