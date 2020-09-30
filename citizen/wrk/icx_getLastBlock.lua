wrk.method = "POST"
wrk.headers["Content-Type"] = "application/json"
wrk.body = '{ "jsonrpc": "2.0","method": "icx_getLastBlock", "id": 1234 }}'
