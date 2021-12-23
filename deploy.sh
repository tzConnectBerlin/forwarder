#!/bin/bash

set -e

if [ -z $ACCOUNT ]; then export ACCOUNT=tz1Memd9efwKKmmomKwuEM1aCQ5yvadS9hH9; fi
if [ -z $TEZOS_CLIENT ]; then export TEZOS_CLIENT="tezos-client -E http://vastly.tzconnect.berlin:10734"; fi
if [ -s $FORWARDER_IPFS_HASH ]; then export FORWARDER_IPFS_HASH=QmTW1YTM6MWHMHZqWJLX4BNfEBrPThmnpySVcZZvUZ7EEB; fi
if [ -s $FORWARDED_IPFS_HASH ]; then export FORWARDED_IPFS_HASH=Qmbs9nJDqDs9XfBtop1hmLC6xyfMcdBm7X6VkbdmP5oA5s; fi

cat <<EOF > storage.mligo
{
  contract = (None : address option);
  approved = (None : address option);
  owner = ("$ACCOUNT" : address);
  defunct = false
}

EOF
make

$TEZOS_CLIENT originate contract forwarder transferring 0 from $ACCOUNT running forwarder.tz --init "`cat storage.tz`" --burn-cap 0.5 --force

CONTRACT_ADDRESS=`$TEZOS_CLIENT list known contracts | grep forwarder | awk '{print $2}'`

if [ -z $CONTRACT_ADDRESS ]; then echo "Couldn't find deployed contract address, something went wrong!"; exit 1; fi

FORWARDED_IPFS_VALUE=`echo "ipfs://$FORWARDED_IPFS_HASH" | xxd -p -c 1000`

cat <<EOF > multi-asset-storage.mligo
 {
  admin = {
    admin = ("$CONTRACT_ADDRESS" : address);
    pending_admin = (None : address option);
    paused = true;
  };
  assets = {
    ledger = (Big_map.empty : ledger);
    operators = (Big_map.empty : operator_storage);
    token_total_supply = (Big_map.empty : token_total_supply);
    token_metadata = (Big_map.empty : token_metadata_storage);
  };
  metadata = Big_map.literal [
    ("", 0x$FORWARDED_IPFS_VALUE)
  ];
}

EOF

make clean && make
make multi-asset.tz
make multi-asset-storage.tz

$TEZOS_CLIENT originate contract forwarded transferring 0 from $ACCOUNT running multi-asset.tz --init "`cat multi-asset-storage.tz`" --burn-cap 1.1 --force
