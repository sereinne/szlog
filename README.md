# A simple structured logging library written in Zig.

> [!Warning]
> Not all features are implemented!

**Szlog** is a small library to create structured and colorful logs.

# installation
To install this library, you need to add this into your `build.zig.zon`.

```zon
// omitted fields ...
.dependencies = .{
    .szlog = .{
        .url = "https://github.com/sereinne/szlog/archive/refs/tags/v0.0.1.tar.gz",
        .hash = "12208940b5afe89f0d9f6720e276f199cedfce80f41559bf67d192ec55e5b21f6528",
    }
}
// omitted fields ...
````

or `zig fetch --save <url>`

To get the url, go to [tags](https://github.com/sereinne/szlog/tags), choose the available versions,.
To obtain the hash, run `zig build --fetch`  you will see the corresponding hash for that url.

# Usage
```zig 
    // options for `Szlog`.
    // const szlog_opts = .{
    //   .output = .stdout, 
    //    .formatter = .{ .text = TextFormatter.default()  
    //}
    
    // Create a new logger 
    var logger = Szlog.default(); // or Szlog.new(opts)

    // Logs message based on configuration.
    logger.log("Hello, World", null, .{ "foo", "bar" });
```
