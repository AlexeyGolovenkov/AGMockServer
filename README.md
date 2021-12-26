# AGMockServer

[![codebeat badge](https://codebeat.co/badges/ab4b3050-bad3-423d-b658-68dd3c572a5b)](https://codebeat.co/projects/github-com-alexeygolovenkov-agmockserver-master)

This framework is a small and simple implementation of HTTP server mock. You may use it to debug and unit test parsers and even more complex logic in your applications (both mac and iOS). The most common applications:
1. Unit testing of logic with server-based data
2. UI testing on mocked data
3. Debugging of rare cases
4. Implement client code while server side is not ready

## Installation
This is a [Swift Package](https://www.swift.org/package-manager/), so you can add it just as an SPM dependency in your Package.swift:
```swift
    dependencies: [
        .package(url: "https://github.com/AlexeyGolovenkov/AGMockServer.git", .upToNextMinor(from: "0.0.1"))
    ]
```

## Usage
In your code:
1. Import the framework
   ```swift
    import AGMockServer 
   ```
2. Create a session you'll be using to get data from Network
    ```swift
    let session: URLSession = AGMockServer.shared.hackedSession(for: URLSession.shared)
    ```
3. Write a class that implements AGMRequestHandler protocol
4. Register this class in AGMockServer object
    ```swift
    AGMockServer.shared.registerHandler(FeedHandler())
    ```
    
Now all the requests to url that can be handled in your handler will be sent not to Network, but to your class.

For more details please take a look at [demo application](https://github.com/AlexeyGolovenkov/AGMockServerDemo): 
