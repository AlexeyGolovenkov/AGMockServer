//
//  TimeoutTask.swift
//
//
//  Created by Alexey Golovenkov on 10.02.2024.
//

import Foundation

public struct TimeoutError: LocalizedError {
    public var errorDescription: String? {
        "The operation timed out."
    }
}

private actor ContinuationManipulator<Success> {
    
    var continuation: CheckedContinuation<Success, Error>?
    
    init(with continuation: CheckedContinuation<Success, Error>?) {
        self.continuation = continuation
    }
    
    func resume(returning result: Success) {
        continuation?.resume(returning: result)
        continuation = nil
    }
    
    func timeout() {
        continuation?.resume(throwing: TimeoutError())
        continuation = nil
    }
    
    func resume(throwing error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

public class TimeoutTask<Success> {
    
    let timeout: UInt64
    let operation: @Sendable () async throws -> Success
    
    private var continuationHandler: ContinuationManipulator<Success>?
    
    public var value: Success {
        get async throws {
            try await withCheckedThrowingContinuation { continuation in
                self.continuationHandler = ContinuationManipulator(with: continuation)
                Task {
                    try await Task.sleep(nanoseconds: timeout)
                    await self.continuationHandler?.timeout()
                }
                Task {
                    do {
                        let result = try await operation()
                        await self.continuationHandler?.resume(returning: result)
                    } catch {
                        await self.continuationHandler?.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    public init(
        _ nanoseconds: UInt64,
        operation: @escaping @Sendable () async throws -> Success
    ) {
        self.timeout = nanoseconds
        self.operation = operation
    }
}
