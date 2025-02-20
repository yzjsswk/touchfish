import AppKit

actor RecipeExecutionContext {
    
    struct ExecuteResult {
        
        private let _contextUid: UUID
        
        private var _lock = NSLock()
        private var _version = Date()
        
        private var _executeUid: String? = nil
        private var _viewInfo: DynamicRecipeViewInfo? = nil
        private var _timeCost: Int? = nil
        
        init(contextUid: UUID) {
            self._contextUid = contextUid
        }
        
        var version: Date {
            return _version
        }
        
        var executeUid: String? {
            return _executeUid
        }
        
        var viewInfo: DynamicRecipeViewInfo? {
            return _viewInfo
        }
        
        var timeCost: Int? {
            return _timeCost
        }
        
        mutating func update(version: Date, executeUid: String?, viewInfo: DynamicRecipeViewInfo?, timeCost: Int?) {
            self._lock.lock()
            defer {
                self._lock.unlock()
            }
            if version >= self.version {
                self._version = version
                self._executeUid = executeUid
                self._viewInfo = viewInfo
                self._timeCost = timeCost
                let group = _contextUid.uuidString
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .RecipeExecutionContextChanged.group(group), object: nil)
                }
            }
        }
        
    }
    
    private let _uid: UUID
    
    private var _recipe: Recipe? = nil
    private var _query: String = ""
    private var _parameters: [String:String] = [:]
    
    private var _executeResult: ExecuteResult
    
    init() {
        let uid = UUID()
        self._uid = uid
        self._executeResult = ExecuteResult(contextUid: uid)
    }
    
    var uid: UUID {
        return _uid
    }
    
    var activeRecipe: Recipe? {
        return _recipe
    }
    
    var query: String {
        return _query
    }
    
    var arguments: [String:String] {
        return _parameters
    }
    
    var parsedArguments: [String:[String]] {
        var ret: [String:[String]] = [:]
        guard let args = activeRecipe?.parameters else {
            return ret
        }
        for arg in args {
            if let value = arguments[arg.name] {
                if let separator = arg.separator {
                    ret[arg.name] = value.split(separator: separator).map{ String($0) }
                } else {
                    ret[arg.name] = [value]
                }
            }
        }
        return ret
    }
    
    var orderedArguments: [(String, String)] {
        var ret: [(String, String)] = []
        if let recipe = activeRecipe {
            for para in recipe.parameters {
                if let value = arguments[para.name] {
                    ret.append((para.name, value))
                }
            }
        }
        return ret
    }
    
    var executeResult: ExecuteResult {
        return _executeResult
    }
 
    func switchRecipe(_ bundleId: String?) {
        if let bundleId = bundleId {
            if let targetRecipe = RecipeManager.recipes[bundleId] {
                if let curRecipe = self.activeRecipe, targetRecipe.bundleId == curRecipe.bundleId  {
                    return
                }
                self._recipe = targetRecipe
                self._parameters.removeAll()
                self._executeResult.update(version: Date(), executeUid: nil, viewInfo: nil, timeCost: nil)
            }
        } else {
            self._recipe = nil
            self._parameters.removeAll()
            self._executeResult.update(version: Date(), executeUid: nil, viewInfo: nil, timeCost: nil)
        }
    }
    
    func modifyQuery(_ query: String) {
        if self.query != query {
            self._query = query
        }
    }
    
    func addOrModifyArg(key: String, value: String) {
        if self.arguments.keys.contains(key) {
            self._parameters[key] = value
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .RecipeExecutionContextChanged.group(self.uid.uuidString), object: nil)
            }
            return
        }
        if let validParas = self.activeRecipe?.parameters.map({$0.name}), validParas.contains(key) {
            self._parameters[key] = value
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .RecipeExecutionContextChanged.group(self.uid.uuidString), object: nil)
            }
        }
    }
    
    func delArg(key: String) {
        if self.arguments.keys.contains(key) {
            self._parameters.removeValue(forKey: key)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .RecipeExecutionContextChanged.group(self.uid.uuidString), object: nil)
            }
        }
    }
    
    func delLastArg() {
        if let recipe = self.activeRecipe {
            for para in recipe.parameters.reversed() {
                if self.arguments.keys.contains(para.name) {
                    self._parameters.removeValue(forKey: para.name)
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .RecipeExecutionContextChanged.group(self.uid.uuidString), object: nil)
                    }
                    break
                }
            }
        }
    }
    
    func clearArg() {
        if self.arguments.count > 0 {
            self._parameters.removeAll()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .RecipeExecutionContextChanged.group(self.uid.uuidString), object: nil)
            }
        }
    }
    
    func executeIfAutomatic() {
        if let recipe = self.activeRecipe, recipe.autoExecute {
            self.execute()
        }
    }
    
    func execute() {
        guard let recipe = self.activeRecipe else {
            return
        }
        for action in recipe.actions {
            Log.debug("execute: \(action)")
            self.executeAction(action: action)
        }
    }
    
    func executeAction(action: RecipeAction) {
        guard let recipe = self.activeRecipe else {
            return
        }
        switch action {
        case .RunShellCommand(let command, let arguments, let refreshView):
            Task {
                let commitTime = Date()
                let result = await RecipeService(host: recipe.host, port: recipe.port).executeRecipe(
                    bundleId: recipe.bundleId,
                    command: command,
                    arguments: arguments,
                    query: self.query,
                    parameters: self.arguments,
                    settings: Config.recipeSettings[recipe.bundleId, default: [:]]
                )
                var executeUid: String? = nil
                var viewInfo: DynamicRecipeViewInfo
                switch result {
                case .success(let resp):
                    if !resp.isOk() {
                        Log.error("request recipe server to execute shell recipe action - fail: resp is not ok, resp.code=\(resp.code), host=\(recipe.host), port=\(recipe.port), bundleId=\(recipe.bundleId), command=\(command)")
                        viewInfo = DynamicRecipeViewInfo.error(
                            title: "Commit Recipe Failed",
                            detail: "response from server is not ok, host=\(recipe.host), port=\(recipe.port), resp.code=\(resp.code) \n resp.msg=\(resp.msg)"
                        )
                        return
                    }
                    if resp.data != nil {
                        executeUid = resp.data
                        viewInfo = DynamicRecipeViewInfo.empty()
                    } else {
                        viewInfo = DynamicRecipeViewInfo.error(
                            title: "Lose Recipe Task",
                            detail: "server did not return a recipe execute uid"
                        )
                    }
                case .failure(let err):
                    Log.error("request recipe server to execute shell recipe action - fail: request recipe server failed, host=\(recipe.host), port=\(recipe.port), err=\(err), bundleId=\(recipe.bundleId), command=\(command)")
                    viewInfo = DynamicRecipeViewInfo.error(
                        title: "Network Error",
                        detail: "failed to request recipe server when commiting recipe task, host=\(recipe.host), port=\(recipe.port) \n err=\(err)"
                    )
                }
                if viewInfo.items.count > 0 {
                    self._executeResult.update(version: commitTime, executeUid: executeUid, viewInfo: viewInfo, timeCost: 0)
                }
                if let executeUid = executeUid {
                    Task {
                        await fetchExecuteResult(host: recipe.host, port: recipe.port, executeUid: executeUid, version: commitTime, refreshView: refreshView, fetchCount: 0)
                    }
                }
            }
        case .CopyToClipboard(let content):
            if let data = content.data(using: .utf8) {
                Functions.copyDataToClipboard(data: data, type: .Text)
            } else {
                Log.warning("execute recipe action - skipped copy action: got copy data=nil, recipe=\(recipe.bundleId)")
            }
        case .BackToMenu:
            self.switchRecipe(nil)
        case .HideWindow:
            Task {
                await TouchFishApp.quickExecutionWindow.hide()
            }
        case .OpenUrl(let url):
            // todo: browser config
            AppleScriptRunner.openWebUrl(with: "Google Chrome", url: url)
        case .ActiveExternalApp(let bundleId):
            AppleScriptRunner.showApplication(app: bundleId)
        case .SetParameter(let name, let value):
            self.addOrModifyArg(key: name, value: value)
        }

    }
    
    private func fetchExecuteResult(host: String, port: String, executeUid: String, version: Date, refreshView: Bool, fetchCount: Int) async {
        if version < self._executeResult.version {
            return
        }
        let info: DynamicRecipeViewInfo
        var timeCost: Int? = nil
        var refresh = true
        let result = await RecipeService(host: host, port: port).fetchExecuteResult(executeUid: executeUid)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                info = DynamicRecipeViewInfo.error(
                        title: "Fetch Result Failed",
                        detail: "response from server is not ok, host=\(host), port=\(port), executeUid=\(executeUid), resp.code=\(resp.code) \n resp.msg=\(resp.msg)"
                )
            } else {
                if let data = resp.data {
                    timeCost = data.timeCost
                    if data.status == .Fail {
                        info = DynamicRecipeViewInfo.error(
                                title: "Execute Failed",
                                detail: "recipe executing failed, host=\(host), port=\(port), executeUid=\(executeUid) \n stderr=\(data.stderr.prefix(3000))"
                        )
                    } else {
                        info = DynamicRecipeViewInfoJsonText.parse(from: data.stdout)
                    }
                    if data.status == .Running {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            Task {
                                await self.fetchExecuteResult(host: host, port: port, executeUid: executeUid, version: version, refreshView: refreshView, fetchCount: fetchCount+1)
                            }
                        }
                        if fetchCount % 5 == 0 {
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
                                NotificationCenter.default.post(name: .ShouldRefreshTopic, object: nil)
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
                            NotificationCenter.default.post(name: .ShouldRefreshTopic, object: nil)
                        }
                    }
                } else {
                    if fetchCount < 300 {
                        info = DynamicRecipeViewInfo.empty()
                        refresh = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + getRefreshInterval(fetchCount: fetchCount)) {
                            Task {
                                await self.fetchExecuteResult(host: host, port: port, executeUid: executeUid, version: version, refreshView: refreshView, fetchCount: fetchCount+1)
                            }
                        }
                    } else {
                        info = DynamicRecipeViewInfo.error(
                            title: "Fetch Result Failed",
                            detail: "there is still no data in response after trying 300 times, host=\(host), port=\(port), executeUid=\(executeUid) \n resp.msg=\(resp.msg)"
                        )
                    }
                }
            }
        case .failure(let err):
            Log.error("request recipe server to fetch execute result - fail: request recipe server failed, host=\(host), port=\(port), err=\(err), executeUid=\(executeUid)")
            info = DynamicRecipeViewInfo.error(
                title: "Network Error",
                detail: "failed to request recipe server whening fetch execute result, host=\(host), port=\(port) executeUid=\(executeUid) \n err=\(err)"
            )
        }
        if !refresh || !refreshView {
            return
        }
        self._executeResult.update(version: version, executeUid: executeUid, viewInfo: info, timeCost: timeCost)
    }

    private func getRefreshInterval(fetchCount: Int) -> Double {
        if fetchCount < 6 {
            return 0.05 // 50 ms * 6, 300ms
        }
        if fetchCount < 10 {
            return 0.1 // 100 ms * 4, 1s
        }
        if fetchCount < 15 {
            return 0.2 // 200 ms * 5, 2s
        }
        if fetchCount < 31 {
            return 0.5 // 500 ms * 16, 10s
        }
        if fetchCount < 81 {
            return 1 // 1s * 50, 1min
        }
        return 2
    }
    
}
