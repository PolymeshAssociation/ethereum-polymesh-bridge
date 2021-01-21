#!/usr/bin/env bash

rm -rf flat

NODE_OPTIONS="--max-old-space-size=8192" POLYMATH_NATIVE_SOLC=true truffle run coverage
