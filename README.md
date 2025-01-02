# A simple structured logging library written in Zig.

> [!Warning]
> Not all features are implemented!

**Szlog** is a small library to create structured and colorful logs.

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


