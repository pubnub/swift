//
//  Dispatcher.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
import Foundation

///
/// Protocol for any type that's responsible to return a concrete Effect according to provided `EffectInvocation`
/// This should be the only one allowed way to create a new Effect.
///
protocol EffectHandlerFactory<Kind, Action> {
  associatedtype Kind
  associatedtype Action
  
  func effect(for invocation: EffectInvocation<Kind, Action>) -> any EffectHandler<Kind, Action>
}

///
/// Protocol for any type that can perform an Effect. Effect can be returned from the factory mentioned above.
/// Concrete types are responsible to implement both `start()` and `cancel()` methods.
/// It's also required to call either `onCompletion:` or `onCancel:` on the underlying `invocation` object in order to notify that the Effect's job has been finished.
///
protocol EffectHandler<Kind, Action> {
  associatedtype Kind
  associatedtype Action
  
  var invocation: EffectInvocation<Kind, Action> { get }
  
  func start()
  func cancel()
}
