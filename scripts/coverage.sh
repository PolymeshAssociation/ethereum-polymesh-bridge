#!/usr/bin/env bash

rm -rf flat

COVERAGE=true POLYMATH_NATIVE_SOLC=false scripts/test.sh
