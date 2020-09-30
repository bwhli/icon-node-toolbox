wrk.method = "POST"
wrk.headers["Content-Type"] = "application/json"
wrk.body = '{ "jsonrpc": "2.0","method": "icx_getTransactionResult", "id": 1234, "params": { "txHash": "0xb903239f8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238" }}'
