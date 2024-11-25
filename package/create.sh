#!/bin/bash

SIZE=$1

sui client ptb \
    --move-call $PACKAGE_ID::grid::new $SIZE @$REGISTRY_ID @0x8 \
    --gas-budget 10000000000 \
    --json
