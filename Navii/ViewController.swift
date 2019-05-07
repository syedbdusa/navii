/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import UIKit
import SceneKit
import ARKit
import GoogleSignIn



class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, UITextFieldDelegate, GIDSignInUIDelegate{
    
    // MARK: - IBOutlets
    @IBOutlet weak var toggle: UISwitch!
    @IBOutlet weak var GoButton: UIButton!
    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var saveExperienceButton: UIButton!
    @IBOutlet weak var loadExperienceButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    //@IBOutlet weak var StartNode: UITextField!
    @IBOutlet weak var EndNode: UITextField!
    @IBOutlet weak var addCup: UISwitch!
    @IBOutlet weak var addLine: UISwitch!
    @IBOutlet weak var rmLine: UISwitch!
    @IBOutlet weak var rmCup: UISwitch!
    @IBOutlet var editingMapLabels: [UILabel]!
    @IBOutlet var editingMapButtons: [UISwitch]!
    @IBOutlet weak var cupNameDecider: UITextField!
    @IBOutlet weak var saveName: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var SignIn: GIDSignInButton!
    
    @IBOutlet weak var SignInTest: GIDSignInButton!
    @IBAction func addCupClicked(_ sender: UISwitch) {
        addCup.setOn(true, animated: true)
        addLine.setOn(false, animated: true)
        rmLine.setOn(false, animated: true)
        rmCup.setOn(false, animated: true)
    }
    @IBAction func addLineClicked(_ sender: UISwitch) {
        prevSelectedCup = nil
        addCup.setOn(false, animated: true)
        addLine.setOn(true, animated: true)
        rmLine.setOn(false, animated: true)
        rmCup.setOn(false, animated: true)
    }
    
    @IBAction func rmLineClicked(_ sender: UISwitch) {
        prevSelectedCup = nil
        addCup.setOn(false, animated: true)
        addLine.setOn(false, animated: true)
        rmLine.setOn(true, animated: true)
        rmCup.setOn(false, animated: true)
    }
    @IBAction func rmCupClicked(_ sender: UISwitch) {
        addCup.setOn(false, animated: true)
        addLine.setOn(false, animated: true)
        rmLine.setOn(false, animated: true)
        rmCup.setOn(true, animated: true)
    }
    
    var previousPoint: SCNVector3?
    var lineColor = UIColor.white
    var path: [Int] = []
    var neighbors: [[Int]] = []
    var anchorNodes: [SCNNode] = []
    var anchors: [ARAnchor?] = []
    var rendered: [Bool] = []
    var counter = 0
    var flag = false;
    var prevSelectedCup: ARAnchor?
    var dict: [String : Int] = [:]
    var count = 0
    var flip = true
    var added_neighbors = false
    var lineNodes: [SCNNode] = []
    // MARK: - View Life Cycle
    
    // Lock the orientation of the app to the orientation in which it is launched
    override var shouldAutorotate: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        GoButton.layer.cornerRadius = 4
        // Read in any already saved map to see if we can load one.
        self.EndNode.delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signInSilently()
        let signInButton = GIDSignInButton()
        signInButton.center = view.center
        if mapDataFromFile != nil {
            self.loadExperienceButton.isHidden = false
        }
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        EndNode.borderStyle = UITextField.BorderStyle.roundedRect
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }
        
        // Start the view's AR session.
        sceneView.session.delegate = self
        sceneView.session.run(defaultConfiguration)
        
        sceneView.debugOptions = [ .showFeaturePoints ]
        
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's AR session.
        sceneView.session.pause()
    }
    
    
    
    // MARK: - ARSCNViewDelegate
    
    
    
    /// - Tag: RestoreVirtualContent
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if counter <= 0 {
            return
        }
        
        if let ind = anchor.name {
            if rendered[Int(ind)!] || !toggle.isOn{
                return
            } else {
                let x: SCNNode = {
                    guard let sceneURL = Bundle.main.url(forResource: "cup", withExtension: "scn", subdirectory: "Assets.scnassets/cup"),
                        let referenceNode = SCNReferenceNode(url: sceneURL) else {
                            fatalError("can't load virtual object")
                    }
                    referenceNode.load()
                    //referenceNode.name = "yump"
                    
                    return referenceNode
                }()
                //print(node)
                node.addChildNode(x)
                anchorNodes.append(node)
                rendered[Int(anchor.name!)!] = true
            }
        } else {
            return
        }
    }
    
    
    
    
    
    
    
    
    
    
    func navigate(start: Int, end: Int) {
        var visited : [Bool] = []
        var prev : [Int] = []
        var dists : [Double] = []
        var i = 0
        while(i < counter) {
            visited.append(false)
            
            prev.append(-1)
            dists.append(99999999.9)
            i += 1
        }
        var fringe3 = NodeList(fringe: [])
        fringe3.add(newNode: Node(value: start, distance: 0.0, back: -1))
        var current = 0
        var currentNode : Node
        var traveled : SCNVector3
        
        while(fringe3.count() > 0) {
            currentNode = fringe3.pop()
            if(!visited[currentNode.value]) {
                dists[currentNode.value] = currentNode.distance
                visited[currentNode.value] = true
                prev[currentNode.value] = currentNode.back
                for neighbor in neighbors[currentNode.value] {
                    if(!visited[neighbor]) {
                        traveled = anchors[currentNode.value]!.transform.position() - anchors[neighbor]!.transform.position()
                        fringe3.add(newNode: Node(value: neighbor, distance: currentNode.distance + Double(traveled.length()), back: currentNode.value))
                    }
                }
            }
        }
        current = end
        path = []
        while(current != -1) {
            path.append(current)
            current = prev[current]
        }
    }
    
    
    
    // MARK: - ARSessionDelegate
    
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    /// - Tag: CheckMappingStatus
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Enable Save button only when the mapping status is good and an object has been placed
        switch frame.worldMappingStatus {
        case .extending, .mapped:
            saveExperienceButton.isEnabled = counter > 0
        default:
            saveExperienceButton.isEnabled = false
        }
        statusLabel.text = """
        Mapping: \(frame.worldMappingStatus.description)
        Tracking: \(frame.camera.trackingState.description)
        """
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        sessionInfoLabel.text = "Session was interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        sessionInfoLabel.text = "Session interruption ended"
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        resetTracking(nil)
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    
    
    
    //extension ended.
    
    //in your code, you can like this.
    
    // MARK: - Persistence: Saving and Loading
    lazy var mapSaveURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("map.arexperience")
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
    }()
    lazy var neighborsSaveURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("neighbors.arexperience")
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
    }()
    lazy var dictSaveURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("dict.arexperience")
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
    }()
    func debugDataURL() -> URL {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("debugSave\(self.saveNum).txt")
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
    }
    @IBAction func saveName(_ sender: UIButton) {
        self.view.endEditing(true)
        let name = cupNameDecider.text!
        dict[name] = counter - 1
        print(dict)
    }
    @IBAction func generateRoute(_ sender: UIButton) {
        self.view.endEditing(true)
        for x in sceneView.scene.rootNode.childNodes{
            if (x.name != nil) {
                x.removeFromParentNode()
            }
        }
        var i = 0
        if (flip) {
            let endString = EndNode.text!.lowercased()
            var currentPos = sceneView.session.currentFrame!.camera.transform.position()
            var minDist : Float
            minDist = 99999999.9
            var minPlace = 0
            var difference : SCNVector3
            var dist : Float
            i = 0
            while(i < neighbors.count) {
                difference = currentPos - anchors[i]!.transform.position()
                dist = difference.length()
                //print(dist)
                if(dist < minDist) {
                    minDist = dist
                    minPlace = i
                }
                i += 1
            }
            
            if let val = dict[endString] {
                navigate(start: minPlace,end: val)
            } else if let b = Int(endString){
                if b >= counter || b < 0{
                    return
                }
                navigate(start: minPlace,end: b)
            } else {
                print("enter something else")
                return
            }

            
            glLineWidth(500)
            i = 0
            while(i < path.count - 1) {
                let twoPointsNode1 = SCNNode()
                sceneView.scene.rootNode.addChildNode(twoPointsNode1.buildLineInTwoPointsWithRotation(
                    from: anchors[path[i]]!.transform.position(), to: anchors[path[i + 1]]!.transform.position(), radius: 0.05, color: .cyan))
                twoPointsNode1.geometry?.firstMaterial?.diffuse.contents = lineColor
                twoPointsNode1.name="yump"
                print("rendering path lines")
                print(twoPointsNode1)
                i+=1
            }
            currentPos.y = anchors[minPlace]!.transform.position().y
            let twoPointsNode1 = SCNNode()
            sceneView.scene.rootNode.addChildNode(twoPointsNode1.buildLineInTwoPointsWithRotation(
                from: anchors[minPlace]!.transform.position(), to: currentPos, radius: 0.05, color: .cyan))
            twoPointsNode1.geometry?.firstMaterial?.diffuse.contents = lineColor
            twoPointsNode1.name="yump"
            print("path:")
            print(path)
        }
        flip = !flip
        
    }
    
    @IBAction func toggleCups(_ sender: Any) {
        if !toggle.isOn {
            // user is using map
            for a in anchorNodes{
                a.removeFromParentNode()
            }
            for button in self.editingMapButtons {
                button.setOn(false, animated: false)
                button.isHidden = true
            }
            for label in self.editingMapLabels {
                label.isHidden = true
            }
            self.cupNameDecider.isHidden = true
            self.saveName.isHidden = true
            self.saveExperienceButton.isHidden = true
            self.resetButton.isHidden = true
        } else {
            // user is editing map
            for a in anchorNodes{
                sceneView.scene.rootNode.addChildNode(a)
            }
            for button in self.editingMapButtons {
                button.isHidden = false
            }
            for label in self.editingMapLabels {
                label.isHidden = false
            }
            self.cupNameDecider.isHidden = false
            self.saveName.isHidden = false
            self.saveExperienceButton.isHidden = false
            self.resetButton.isHidden = false
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.generateRoute(GoButton)
        self.goClearSwitch(GoButton)
        self.view.endEditing(true)
        return true
    }
    
    
    var saveNum = 0
    
    /// - Tag: GetWorldMap
    @IBAction func saveExperience(_ button: UIButton) {
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { self.showAlert(title: "Can't get current world map", message: error!.localizedDescription); return }
            
            // save anchors
            do {
                //print("BEFORE")
                //print(map.anchors)
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                try data.write(to: self.mapSaveURL, options: [.atomic])
                DispatchQueue.main.async {
                    self.loadExperienceButton.isHidden = false
                    self.loadExperienceButton.isEnabled = true
                }
            } catch {
                fatalError("Can't save map: \(error.localizedDescription)")
            }
            // save neighbors
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: self.neighbors, requiringSecureCoding: true)
                try data.write(to: self.neighborsSaveURL, options: [.atomic])
            } catch {
                fatalError("Can't save neighbors: \(error.localizedDescription)")
            }
            // save dict
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: self.dict, requiringSecureCoding: true)
                try data.write(to: self.dictSaveURL, options: [.atomic])
            } catch {
                fatalError("Can't save neighbors: \(error.localizedDescription)")
            }
            // save debug info
            
            var debugLog = LogDestination(url: self.debugDataURL())
            let date = Date()
            // try preloading txt
            do {
                try "debugInfo at \(date)".write(to: debugLog.path, atomically: true, encoding: .utf8)
                
            } catch {
                fatalError("file not found")
            }
            print("", to: &debugLog)
            self.saveNum += 1
            debugPrint("=============================WORLDMAP===============================", to: &debugLog)
            print("", to: &debugLog)
            debugPrint(map, to: &debugLog)
            print("", to: &debugLog)
            debugPrint("=============================ALL ANCHORS============================", to: &debugLog)
            print("", to: &debugLog)
            for anchor in map.anchors{
                debugPrint(anchor, to: &debugLog)
                print("", to: &debugLog)
            }
            debugPrint("=============================CUP ANCHORS============================", to: &debugLog)
            print("", to: &debugLog)
            for anchor in self.anchors{
                debugPrint(anchor!, to: &debugLog)
                print("", to: &debugLog)
            }
            debugPrint("=============================DICTIONARY=============================", to: &debugLog)
            print("", to: &debugLog)
            debugPrint(self.dict, to: &debugLog)
            print("", to: &debugLog)
            debugPrint("=============================NEIGHBORS==============================", to: &debugLog)
            print("", to: &debugLog)
            debugPrint(self.neighbors, to: &debugLog)
            print("", to: &debugLog)
            debugPrint("====================================================================", to: &debugLog)
            
        }
    }
    
    // Called opportunistically to verify that map data can be loaded from filesystem.
    var mapDataFromFile: Data? {
        return try? Data(contentsOf: mapSaveURL)
    }
    var neighborsDataFromFile: Data? {
        return try? Data(contentsOf: neighborsSaveURL)
    }
    var dictDataFromFile: Data? {
        return try? Data(contentsOf: dictSaveURL)
    }
    @IBAction func goClearSwitch(_ sender: Any) {
        if GoButton.title(for: UIControl.State.normal) == "Go" {
            GoButton.setTitle("Clear", for: UIControl.State.normal)
        } else {
            GoButton.setTitle("Go", for: UIControl.State.normal)
        }
    }
    /// - Tag: RunWithWorldMap
    @IBAction func loadExperience(_ button: UIButton) {
        rendered = []
        /// - Tag: ReadWorldMap
        let worldMap: ARWorldMap = {
            guard let data = mapDataFromFile
                else { fatalError("Map data should already be verified to exist before Load button is enabled.") }
            do {
                guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
                    else { fatalError("No ARWorldMap in archive.") }
                return worldMap
            } catch {
                fatalError("Can't unarchive ARWorldMap from file data: \(error)")
            }
        }()
        
        print("before")
        print(worldMap)
        anchors = []
        for a in worldMap.anchors{
            if (a.name != nil) {
                anchors.append(a)
            }
        }
        anchors.sort(by: {$0!.name! < $1!.name!})
        print("After")
        print(anchors)
        print("wm")
        print(worldMap)
        counter = anchors.count
        for _ in 0..<counter {
            rendered.append(false)
        }
        flag = true
        // load neighbors
        
        neighbors = {
            guard let data = neighborsDataFromFile
                else { fatalError("neighbors data should already be verified to exist before Load button is enabled.") }
            do {
                guard let neighbors = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [[Int]]
                    else { fatalError("No neighbors in archive.") }
                return neighbors
            } catch {
                fatalError("Can't unarchive neighbors from file data: \(error)")
            }
        }()
        // load neighbors
        
        dict = {
            guard let data = dictDataFromFile
                else { fatalError("dict data should already be verified to exist before Load button is enabled.") }
            do {
                guard let dict = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String : Int]
                    else { fatalError("No dict in archive.") }
                return dict
            } catch {
                fatalError("Can't unarchive dict from file data: \(error)")
            }
        }()
        
        let configuration = self.defaultConfiguration // this app's standard world tracking settings
        configuration.initialWorldMap = worldMap
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        isRelocalizingMap = false
    }

    // MARK: - AR session management
    
    var isRelocalizingMap = false

    var defaultConfiguration: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic
        return configuration
    }
    
    @IBAction func resetTracking(_ sender: UIButton?) {
        for x in sceneView.scene.rootNode.childNodes{
            if (x.name != nil) {
                x.removeFromParentNode()
            }
        }
        sceneView.session.run(defaultConfiguration, options: [.resetTracking, .removeExistingAnchors])
        isRelocalizingMap = false
        anchors = []
        rendered = []
        counter = 0
        lineNodes = []
        anchorNodes = []
        dict = [:]
        neighbors = []
    }
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch (trackingState, frame.worldMappingStatus) {
        case (.normal, .mapped),
             (.normal, .extending):
            message = ""
            GoButton.backgroundColor = UIColor.green
            
        case (.normal, _) where mapDataFromFile != nil && !isRelocalizingMap:
            message = "Move around to map the environment or tap 'Load Experience' to load a saved experience."
            
            GoButton.backgroundColor = UIColor.red
        case (.normal, _) where mapDataFromFile == nil:
            message = "Move around to map the environment."
            
            GoButton.backgroundColor = UIColor.red
        case (.limited(.relocalizing), _) where isRelocalizingMap:
            message = "Move your device to the location shown in the image."
            
            GoButton.backgroundColor = UIColor.red
        default:
            message = trackingState.localizedFeedback
            GoButton.backgroundColor = UIColor.red
        }
        
        sessionInfoLabel.text = message
//        sessionInfoView.isHidden = message.isEmpty
    }
    
    // MARK: - Placing AR Content
    
    /// - Tag: PlaceObject
    @IBAction func handleSceneTap(_ sender: UITapGestureRecognizer) {
        // Disable placing objects when the session is still relocalizing
        //StartNode.resignFirstResponder()
        EndNode.resignFirstResponder()
        if isRelocalizingMap {
            return
        }
        if !toggle.isOn{
            return
        }
        // Hit test to find a place for a virtual object.
        guard let hitTestResult = sceneView
            .hitTest(sender.location(in: sceneView), types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane])
            .first
            else { return }
        
        if addCup.isOn {
            rendered.append(false)
            anchors.append(ARAnchor(name: String(counter), transform: hitTestResult.worldTransform))
            sceneView.session.add(anchor: anchors[counter]!)
            neighbors.append([])
            flag = true
            counter+=1
            print(dict)
        } else if addLine.isOn {
            let v1 = hitTestResult.worldTransform.position()
            let dist = anchors.map {(v1 - $0!.transform.position()).length()}
            print("dist to anchors")
            print(dist)
            let distMin = dist.min()
            let cup = anchors[dist.firstIndex(of: distMin!)!]
            if distMin! < 0.5 {
                if prevSelectedCup == nil {
                    prevSelectedCup = cup
                } else {
                    let twoPointsNode1 = SCNNode()
                    sceneView.scene.rootNode.addChildNode(twoPointsNode1.buildLineInTwoPointsWithRotation(
                        from: prevSelectedCup!.transform.position(), to: (cup?.transform.position())!, radius: 0.05, color: .cyan))
                    twoPointsNode1.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                    twoPointsNode1.name="lineNodeAnchor"
                    let cupInd = anchors.firstIndex(of: cup)!
                    let prevInd = anchors.firstIndex(of: prevSelectedCup)!
                    neighbors[cupInd].append(prevInd)
                    neighbors[prevInd].append(cupInd)
                    prevSelectedCup = nil
                    print(neighbors)
                }
                
            }
            
            
        } else if rmCup.isOn {
            if anchors.isEmpty {
                return
            }
            let v1 = hitTestResult.worldTransform.position()
            let dist = anchors.map {(v1 - $0!.transform.position()).length()}
            print("dist to anchors")
            print(dist)
            let distMin = dist.min()
            let cupInd = dist.firstIndex(of: distMin!)!
            let cup = anchors[cupInd]
            
            print("Before removing cup")
            print(neighbors)
            if distMin! < 0.5 {
                rendered.remove(at: cupInd)
                sceneView.session.remove(anchor: cup!)
                let rmNeighbors = neighbors.remove(at: cupInd)
                for neighbor in rmNeighbors{
                    // remove the cup in all of its neighbors' neighbor-list
                    if let index = neighbors[neighbor].index(of: cupInd) {
                        neighbors[neighbor].remove(at: index);
                    }
                }
                let names = dict.keysForValue(value: cupInd)
                for name in names{
                    dict.removeValue(forKey: name)
                }
                anchors.remove(at: cupInd)
                counter-=1
                print("after removing cup")
                print(neighbors)
            }
        } else if rmLine.isOn {
            
        }
    }
    

}

