# swift-redis
An asynchronous redis client for Swift with libuv


## Requirements
* [libuv](https://github.com/libuv/libuv)
* [hiredis](https://github.com/redis/hiredis)

## Installation

### Linux
```sh
# build and install libuv
git clone https://github.com/libuv/libuv.git && cd libuv
sh autogen.sh
./configure
make
make install

# Install hiredis
git clone https://github.com/redis/hiredis && cd hiredis
make
make install
```

### Mac OS X

```sh
brew install libuv hiredis
brew link libuv --force
brew link hiredis --force
```


## Usage

```swift
import SwiftRedis
import CLibUv

let loop = uv_default_loop()

let con = try! Connection(loop: loop)

// Set the callback for socket events
con.on(.Connect) { result in
    print("connected")
}

con.on(.Disconnect) { result in
    print("disconnected")
}

// PING
Redis.command(con, command: .PING) { result in
    if case .Success(let rep) = result {
      print(rep) // => PONG
    }
}


// SET
Redis.command(con, command: .SET("test", "foobar")) { result in
    if case .Success(let rep) = result {
      print(rep) // => OK
    }

    // Close the connection
    Redis.close(con)
}

uv_run(uv_default_loop(), UV_RUN_DEFAULT)
```

## License

(The MIT License)

Copyright (c) 2016 Yuki Takei(Noppoman) yuki@miketokyo.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and marthis permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
