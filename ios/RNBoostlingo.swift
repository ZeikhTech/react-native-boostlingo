import Boostlingo
import React
import Foundation

@objc(RNBoostlingo)
class RNBoostlingo: RCTEventEmitter, BLCallDelegate, BLChatDelegate {

    private var boostlingo: Boostlingo?
    private var hasListeners: Bool = false
    
    @objc
    override func supportedEvents() -> [String] {
        return ["callDidConnect", "callDidDisconnect", "callDidFailToConnect", "chatConnected", "chatDisconnected", "chatMessageRecieved"]
    }
    
    @objc
    override func startObserving() {
        hasListeners = true
    }
    
    @objc
    override func stopObserving() {
        hasListeners = false
    }
    
    @objc
    public func initialize(_ config: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        DispatchQueue.main.async {
            self.initialize(config, resolver: resolve, rejecter: reject)
        }
    }
    
    @objc
    public func getCallDictionaries(resolver resolve: @escaping RCTPromiseResolveBlock, reßjecter reject: @escaping RCTPromiseRejectBlock) {
        do {
            self.boostlingo!.getCallDictionaries() { [weak self] (callDictionaries, error) in
                guard let self = self else {
                    return
                }
                
                if error == nil {
                    let result = try! self.callDictionariesAsDictionary(callDictionaries: callDictionaries!)
                    resolve(result)
                }
                else {
                    let message: String
                    switch error! {
                    case BLError.apiCall(_, let statusCode):
                        message = "\(error!.localizedDescription), statusCode: \(statusCode)"
                        break
                    default:
                        message = error!.localizedDescription
                        break
                    }
                    reject("error", "Encountered an error: \(message)", error)
                }
            }
        } catch let error as NSError {
            reject("error", error.domain, error)
        } catch let error {
            reject("error", "Error running Boostlingo SDK", error)
            return
        }
    }
    
    @objc
    public func makeVoiceCall(_ request: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        do {
            let callRequest = CallRequest(languageFromId: request["languageFromId"] as! Int, languageToId: request["languageToId"] as! Int, serviceTypeId: request["serviceTypeId"] as! Int, genderId: request["genderId"] as? Int, isVideo: false)

            self.boostlingo!.chatDelegate = self
            self.boostlingo!.makeVoiceCall(callRequest: callRequest, delegate: self) { [weak self] call, error in
                guard let self = self else {
                    return
                }
                
                DispatchQueue.main.async {
                    if let error = error {
                        let message = error.localizedDescription
                        reject("error", "Encountered an error: \(message)", error)
                        return
                    }
                    let result = self.callAsDictionary(call: call!)
                    resolve(result)
                }
            }
        } catch let error as NSError {
            reject("error", error.domain, error)
        } catch let error {
            reject("error", "Error running Boostlingo SDK", error)
            return
        }
    }
    
    @objc
    public func hangUp(resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        do {
            boostlingo!.hangUp() { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        let message = error.localizedDescription
                       reject("error", "Encountered an error: \(message)", error)
                       return
                    } else {
                         resolve(nil)
                    }
                }
            }
        } catch let error as NSError {
            reject("error", error.domain, error)
        } catch let error {
            reject("error", "Error running Boostlingo SDK", error)
            return
        }
    }
    
    @objc
    public func dispose() {
        boostlingo?.chatDelegate = nil
        boostlingo = nil
    }
    
    private func initialize(config: NSDictionary,
                     resolver resolve: @escaping RCTPromiseResolveBlock,
                     rejecter reject: @escaping RCTPromiseRejectBlock) {
        do {
            let authToken: String = config["authToken"] as! String
            let region: String = config["region"] as! String
            
            self.boostlingo = Boostlingo(authToken: authToken, region: region, logLevel: .debug)
            self.boostlingo!.initialize() { [weak self] error in
                guard let self = self else {
                    return
                }
                
                guard error == nil else {
                    let message: String
                    switch error! {
                    case BLError.apiCall(_, let statusCode):
                        message = "\(error!.localizedDescription), statusCode: \(statusCode)"
                        break
                    default:
                        message = error!.localizedDescription
                        break
                    }
                    reject("error", "Encountered an error: \(message)", error)
                    return
                }
                
                resolve(nil)
            }
        } catch let error as NSError {
            reject("error", error.domain, error)
        } catch let error {
            reject("error", "Error running Boostlingo SDK", error)
            return
        }
    }
    
    private func callDictionariesAsDictionary(callDictionaries: CallDictionaries) throws -> [String: Any] {
        let data = try JSONEncoder().encode(callDictionaries)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
    
    private func callAsDictionary(call: BLCall) -> [String: Any] {
        var response = [String: Any]()
        response["callId"] = call.callId
        response["isVideo"] = call.isVideo
        response["isInProgress"] = call.isInProgress
        // TODO
        return response
    }
    
    // MARK: - BLCallDelegate
    func callDidConnect(_ call: BLCall) {
        if (hasListeners) {
            DispatchQueue.main.async {
                // TODO
                self.sendEvent(withName: "callDidConnect", body: self.callAsDictionary(call: call))
            }
        }
    }
    
    func callDidDisconnect(_ error: Error?) {
        if (hasListeners) {
            DispatchQueue.main.async {
                 self.sendEvent(withName: "callDidDisconnect", body: error != nil ? error!.localizedDescription : nil)
            }
        }
    }
    
    func callDidFailToConnect(_ error: Error?) {
        if (hasListeners) {
            DispatchQueue.main.async {
                self.sendEvent(withName: "callDidFailToConnect", body: error != nil ? error!.localizedDescription : nil)
            }
        }
    }
    
    // MARK: - BLChatDelegate
    func chatConnected() {
        if (hasListeners) {
            DispatchQueue.main.async {
                self.sendEvent(withName: "chatConnected", body: nil)
            }
        }
    }
    
    func chatDisconnected() {
        if (hasListeners) {
            DispatchQueue.main.async {
                self.sendEvent(withName: "chatDisconnected", body: nil)
            }
        }
    }
    
    func chatMessageRecieved(message: ChatMessage) {
        if (hasListeners) {
            DispatchQueue.main.async {
                // TODO
                self.sendEvent(withName: "chatDisconnected", body: message.text)
            }
        }
    }
}
