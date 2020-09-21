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
    func getRegions(resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        resolve(Boostlingo.getRegions())
    }
    
    @objc
    func getVersion(resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        resolve(Boostlingo.getVersion())
    }
    
    @objc
    func initialize(_ config: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        DispatchQueue.main.async {
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
    }
    
    @objc
    func getCurrentCall(resolver resolve: @escaping RCTPromiseResolveBlock, reßjecter reject: @escaping RCTPromiseRejectBlock) {
        do {
            let currentCall = self.boostlingo!.currentCall
            resolve(currentCall)
        } catch let error as NSError {
            reject("error", error.domain, error)
        } catch let error {
            reject("error", "Error running Boostlingo SDK", error)
            return
        }
    }
    
    @objc
    func getCallDictionaries(resolver resolve: @escaping RCTPromiseResolveBlock, reßjecter reject: @escaping RCTPromiseRejectBlock) {
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
    func getProfile(resolver resolve: @escaping RCTPromiseResolveBlock, reßjecter reject: @escaping RCTPromiseRejectBlock) {
        do {
            self.boostlingo!.getProfile { [weak self] (profile, error) in
                guard let self = self else {
                    return
                }
                
                if error == nil {
                    resolve(self.profileAsDictionary(profile: profile!))
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
    func makeVoiceCall(_ request: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
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
    func hangUp(resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
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
    func dispose() {
        boostlingo?.chatDelegate = nil
        boostlingo = nil
    }
    
    private func callDictionariesAsDictionary(callDictionaries: CallDictionaries) throws -> [String: Any] {
        let data = try JSONEncoder().encode(callDictionaries)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
    
    private func callAsDictionary(call: BLCall) -> [String: Any] {
        var dictionary = [String: Any]()
        dictionary["callId"] = call.callId
        dictionary["isVideo"] = call.isVideo
        dictionary["isInProgress"] = call.isInProgress
        dictionary["interlocutorInfo"] = call.interlocutorInfo == nil ? nil : interlocutorInfoAsDictionary(interlocutorInfo: call.interlocutorInfo!)
        dictionary["isMuted"] = call.isMuted
        return dictionary
    }
    
    private func interlocutorInfoAsDictionary(interlocutorInfo: InterpreterInfo) -> [String: Any] {
        var dictionary = [String: Any]()
        dictionary["userAccountId"] = interlocutorInfo.userAccountId
        dictionary["firstName"] = interlocutorInfo.firstName
        dictionary["lastName"] = interlocutorInfo.lastName
        dictionary["requiredName"] = interlocutorInfo.requiredName
        dictionary["companyName"] = interlocutorInfo.companyName
        dictionary["rating"] = interlocutorInfo.rating
        dictionary["imageInfo"] = interlocutorInfo.imageInfo == nil ? nil : imageInfoAsDictionary(imageInfo: interlocutorInfo.imageInfo!)
        return dictionary
    }
    
    private func imageInfoAsDictionary(imageInfo: ImageInfo) -> [String: Any] {
        var dictionary = [String: Any]()
        dictionary["imageKey"] = imageInfo.imageKey
        dictionary["sizes"] = imageInfo.sizes
        return dictionary
    }
    
    private func profileAsDictionary(profile: Profile) -> [String: Any] {
        var dictionary = [String: Any]()
        dictionary["accountName"] = profile.accountName
        dictionary["userAccountId"] = profile.userAccountId
        dictionary["companyAccountId"] = profile.companyAccountId
        dictionary["email"] = profile.email
        dictionary["firstName"] = profile.firstName
        dictionary["lastName"] = profile.lastName
        dictionary["requiredName"] = profile.requiredName
        dictionary["imageInfo"] = profile.imageInfo == nil ? nil : imageInfoAsDictionary(imageInfo: profile.imageInfo!)
        return dictionary
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
