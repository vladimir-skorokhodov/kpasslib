#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"

cargo build --release

echo "Built libkreepto at target/release/"
