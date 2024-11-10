//import Foundation
//
//struct TFTask {
//    
//    static func start() {
//        autoRemoveFish()
//    }
//    
//    static func autoRemoveFish() {
//        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 3600) {
//            if Config.autoRemoveFishEnable {
//                Task {
//                    let result = await DataService.clearFish(secondDelta: Config.autoRemoveFishPastHours*3600)
//                    switch result {
//                    case .success(let resp):
//                        switch resp.code {
//                        case .success:
//                            if let clearedIdentitys = resp.data?.clearedIdentitys {
//                                Log.info("auto remove fish - remove \(clearedIdentitys.count) fish, identitys=\(clearedIdentitys)")
//                                if clearedIdentitys.count > 0 {
//                                    MessageCenter.send(level: .info, content: "removed \(clearedIdentitys.count) fish, identitys=\(clearedIdentitys)")
//                                }
//                                Cache.refresh()
//                            } else {
//                                Log.warning("auto remove fish - cleared fish identitys may lose: resp.code=success but resp.data=nil")
//                            }
//                        case .skip:
//                            Log.warning("auto remove fish - skip: resp.status=skip, resp.msg=\(resp.msg)")
//                        case .fail:
//                            Log.error("auto remove fish - fail: resp.status=fail, resp.msg=\(resp.msg)")
//                        }
//                    case .failure(let err):
//                        Log.error("auto remove fish - fail: request data service fail, err=\(err)")
//                    }
//                }
//            }
//            autoRemoveFish()
//        }
//    }
//    
//}
