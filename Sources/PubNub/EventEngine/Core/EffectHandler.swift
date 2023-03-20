//
//  Dispatcher.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2023 PubNub Inc.
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
/// Protocol for any type that's responsible for returning a concrete Effect according to provided `EffectInvocation`
/// This should be the only one allowed way to create a new Effect.
///
protocol EffectHandlerFactory<EffectKind, Event> {
  associatedtype EffectKind
  associatedtype Event
  
  func effect(
    for invocation: EffectInvocation<EffectKind, Event>,
    with receiver: some EventReceiver<Event>
  ) -> any EffectHandler<EffectKind, Event>
}

///
/// Protocol for any type that can perform an Effect. An effect can be returned from the factory mentioned above.
/// Concrete types are responsible to implement both `start()` and `cancel()` methods.
/// It's also required to call either `onCompletion:` or `onCancel:` on the underlying `invocation` object in order to notify that the Effect's job has been finished.
///
protocol EffectHandler<EffectKind, Event> {
  associatedtype EffectKind
  associatedtype Event
  
  var invocation: EffectInvocation<EffectKind, Event> { get }
  var receiver: any EventReceiver<Event> { get }
  var dependency: (any EffectHandler)? { get }
  
  func start(onCompletion: () -> Void)
  func cancel()
}

///
/// Base effect handler class you can inherit from.
///
/// The goal of this class is to reduce the effort in order to implement the `EffectHandler` protocol. This is done by introducing the `Template method` design pattern.
/// Subclasses are responsible to implement `performEffectTask()` and `cancelEffectTask()` methods.
///
class BaseEffectHandler<EffectKind, Event>: EffectHandler {
  let invocation: EffectInvocation<EffectKind, Event>
  let receiver: any EventReceiver<Event>
  
  // The effect handler on which the receiver depends.
  // The receiver isn't considered ready to execute until its dependent handler have finished executing.
  let dependency: (any EffectHandler)?
  
  init(
    invocation: EffectInvocation<EffectKind, Event>,
    receiver: some EventReceiver<Event>,
    dependency: (any EffectHandler)? = nil
  ) {
    self.invocation = invocation
    self.receiver = receiver
    self.dependency = dependency
  }
  
  func start(onCompletion: () -> Void) {
    if let dependency = dependency {
      dependency.start { [weak self] in
        self?.performEffectTask()
      }
    }
  }
  
  func performEffectTask() {
    debugPrint("Implement in subclasses")
  }
  
  func cancelEffectTask() {
    debugPrint("Implement in subclasses")
  }
  
  func cancel() {
    dependency?.cancel()
    cancelEffectTask()
  }
}
