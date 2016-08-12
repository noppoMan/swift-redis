//
//  Result.swift
//  SwiftRedis
//
//  Created by Yuki Takei on 8/12/16.
//
//

public enum GenericResult<T> {
    case success(T)
    case error(Error)
}

public enum Result {
    case success
    case error(Error)
}
