//
//  ViewController.swift
//  FireWatcher
//
//  Created by John Palevich on 3/17/19.
//  Copyright © 2019 John Palevich. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

public class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var tree: SCNNode?
    var forest:[[SCNNode]]?
    var isBurning: [[Bool]]?
    var numTrees: Int?
    var burningTrees:[SCNNode] = []
    var particles: [[Int]]?
    var spreadTrees: [Int] = []
    var rainParticles: [[SCNNode]]?
    var rootNode: SCNNode?
    var timer: Timer?
    var fireSound = SCNAudioSource(fileNamed: "art.scnassets/Fire.wav")!
    var fireAudioPlayer: SCNAudioPlayer?
    var meadowSound = SCNAudioSource(fileNamed: "art.scnassets/Meadow.wav")!
    var meadowAudioPlayer: SCNAudioPlayer?
    var crowSound = SCNAudioSource(fileNamed: "art.scnassets/Crow.wav")!
    var crowAudioPlayer: SCNAudioPlayer?
    var rainSound = SCNAudioSource(fileNamed: "art.scnassets/Rain.wav")!
    var rainAudioPlayer: SCNAudioPlayer?
    var rainSoundPlay = false
    var fireSoundPlay = false
    var numOnFire = 0
    var counter = 0
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView = ARSCNView(frame: .zero)
        self.view = sceneView
        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        //named: "art.scnassets/TreeModel.dae"
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        // Set the view's delegate
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
        scene.rootNode.addChildNode(cameraNode)
        
        //fireAudioPlayer = SCNAudioPlayer(source: fireSound)
        fireSound.loops = true
        meadowSound.loops = true
        rainSound.loops = true
        crowSound.loops = true
    }
    
    func setUpWorld(){
        numTrees = 20
        forest = Array(repeating: Array(repeating: SCNNode(), count: numTrees!), count: numTrees!)
        isBurning = Array(repeating: Array(repeating: false, count: numTrees!), count: numTrees!)
        particles = Array(repeating: Array(repeating: 0, count: numTrees!), count: numTrees!)
        rainParticles = Array(repeating: Array(repeating: SCNNode(), count: numTrees!), count: numTrees!)
        rootNode = SCNNode()
        initializeNodes()
        //igniteTree()
        //igniteSpecifiedTree(x: 0, y: 0)
        //isBurning![0][0] = true
        timer =  Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (t) in
            self.updateGame()}
    }
    
    func updateGame(){
        if counter != 0 && counter % 15 == 0{
            spreadFire()
            
        }
        if counter >= 10 && counter % 5 == 0{
            updateParticles()
            igniteTree()
        }
        if counter == 0{
            meadowSFX()
        }
        //print(numOnFire)
        if(!fireSoundPlay && numOnFire > 0){
            fireSFX()
            stopMeadowSFX()
            fireSoundPlay = true
        }
        else if (fireSoundPlay && numOnFire == 0){
            stopFireSFX()
            meadowSFX()
            fireSoundPlay = false
        }
        counter = counter + 1
        
    }
    
    func initializeNodes(){
        tree = treeNode()
        let rainNode = SCNNode()
        //rainNode = rainNode()
        for i in -numTrees!/2..<numTrees!/2{
            for j in -numTrees!/2..<numTrees!/2{
                let newRain = rainNode.clone()
                newRain.simdPosition = float3(1 * Float(i), 20, 1 * Float(j))
                let newTree = tree!.clone()
                newTree.name = "tree"
                newTree.simdPosition = float3(1 * Float(i), 0.5, 1*Float(j))
                let randScale = Float.random(in: 1 ..< 3)
                newTree.simdScale = float3(0.1*randScale,0.1*randScale,0.1*randScale)
                rootNode!.addChildNode(newTree)
                rootNode!.addChildNode(newRain)
                rainParticles![i+numTrees!/2][j+numTrees!/2] = newRain
                forest![i+numTrees!/2][j+numTrees!/2] = newTree
            }
        }
    }
    
    func spreadFire(){
        for i in 0..<numTrees!{
            for j in 0..<numTrees!{
                if isBurning![i][j] && forest![i][j].name == "burning"{
                    if i+1 < numTrees! && !isBurning![i+1][j] && forest![i+1][j].name != "burning"{
                        igniteSpecifiedTree(x:(i+1), y: j)
                        spreadTrees.append(i+1)
                        spreadTrees.append(j)
                    }
                    if i-1 >= 0 && !isBurning![i-1][j] && forest![i-1][j].name != "burning"{
                        igniteSpecifiedTree(x:i-1, y: j)
                        spreadTrees.append(i-1)
                        spreadTrees.append(j)
                    }
                    if j+1 < numTrees! && !isBurning![i][j+1] && forest![i][j+1].name != "burning"{
                        igniteSpecifiedTree(x:i, y: j+1)
                        spreadTrees.append(i)
                        spreadTrees.append(j+1)
                    }
                    if j-1 >= 0 && !isBurning![i][j-1] && forest![i][j-1].name != "burning"{
                        igniteSpecifiedTree(x:i, y: j-1)
                        spreadTrees.append(i)
                        spreadTrees.append(j-1)
                    }
                }
            }
        }
        while spreadTrees.count > 0{
            isBurning![spreadTrees[0]][spreadTrees[1]] = true
            spreadTrees.remove(at: 1)
            spreadTrees.remove(at: 0)
        }
    }
    
    func updateParticles(){
        for i in 0..<numTrees!{
            for j in 0..<numTrees!{
                if particles![i][j] == 1{
                    particles![i][j] = 2
                    forest![i][j].removeAllParticleSystems()
                    let fire = fireParticleSystem()
                    fire.emitterShape = forest![i][j].geometry
                    fire.particleSize = 0.01
                    fire.particleVelocity = fire.particleVelocity * 0.1
                    //fire.birthRate = 0.
                    forest![i][j].addParticleSystem(fire)
                }
                else if(particles![i][j] == 2){
                    particles![i][j] = 3
                }
                else if(particles![i][j] == 3){
                    //remove tree from play field
                    let deadTree = deadTreeNode()
                    deadTree.simdPosition = forest![i][j].simdPosition
                    deadTree.simdScale = forest![i][j].simdScale
                    rootNode!.replaceChildNode(forest![i][j], with: deadTree)
                    forest![i][j] = deadTree

                }
                else if(particles![i][j] == 4){
                    particles![i][j] = 0
                    if(rainSoundPlay){
                        stopRainSFX()
                        rainSoundPlay = false
                    }
                    rootNode?.replaceChildNode(rainParticles![i][j], with: SCNNode())
                    rainParticles![i][j] = SCNNode()
                    
                }
            }
        }
    }
    
    func igniteSpecifiedTree(x:Int, y:Int){
        numOnFire = numOnFire + 1
        let oldTree = forest![x][y]
        let ignitedTree = fireTreeNode()
        let smokeParticle = smokeParticleSystem()
        smokeParticle.emitterShape = ignitedTree.geometry
        smokeParticle.particleSize = 0.1
        smokeParticle.birthRate = smokeParticle.birthRate*5
        smokeParticle.particleLifeSpan = smokeParticle.particleLifeSpan*0.5
        ignitedTree.name = "burning"
        ignitedTree.addParticleSystem(smokeParticle)
        ignitedTree.simdPosition = oldTree.simdPosition
        ignitedTree.simdScale = oldTree.simdScale
        particles![x][y] = 1;
        rootNode!.replaceChildNode(oldTree, with: ignitedTree)
        if(!burningTrees.contains(ignitedTree)){
            forest![x][y] = ignitedTree
            burningTrees.append(ignitedTree)
        }
    }
    
    func igniteTree(){
        numOnFire = numOnFire + 1
        let randX = Int.random(in: 0 ..< numTrees!)
        let randY = Int.random(in: 0 ..< numTrees!)
        let oldTree = forest![randX][randY]
//        while(isBurning[x][z]){
//            number = Int.random(in: 0 ..< forest.count)
//            oldTree = forest[number]
//            x = Int(oldTree.simdPosition.x + Float(numTrees!/2))
//            z = Int(oldTree.simdPosition.z + Float(numTrees!/2))
//        }
        let ignitedTree = fireTreeNode()
        let smokeParticle = smokeParticleSystem()
        smokeParticle.emitterShape = ignitedTree.geometry
        smokeParticle.particleSize = 0.1
        smokeParticle.birthRate = smokeParticle.birthRate*5
        smokeParticle.particleLifeSpan = smokeParticle.particleLifeSpan*0.5
        ignitedTree.name = "burning"
        ignitedTree.addParticleSystem(smokeParticle)
        ignitedTree.simdPosition = oldTree.simdPosition
        ignitedTree.simdScale = oldTree.simdScale
        particles![randX][randY] = 1
        isBurning![randX][randY] = true
        rootNode!.replaceChildNode(oldTree, with: ignitedTree)
        forest![randX][randY] = ignitedTree
        burningTrees.append(ignitedTree)
    }
    
    func saveTrees(middleTree:SCNNode){
        let x = Int(middleTree.simdPosition.x) + numTrees!/2
        let y = Int(middleTree.simdPosition.z) + numTrees!/2
        saveTree(savedTree: middleTree, x: x, y: y )
        if(x+1 < numTrees! && isBurning![x+1][y]){
            saveTree(savedTree: forest![x+1][y], x: x+1, y: y)
        }
        if(x+1 < numTrees! && y+1 < numTrees! && isBurning![x+1][y+1]){
            saveTree(savedTree: forest![x+1][y+1], x: x+1, y: y+1)
        }
        if(x+1 < numTrees! && y-1 >= 0 && isBurning![x+1][y-1]){
            saveTree(savedTree: forest![x+1][y-1], x: x+1, y: y-1)
        }
        if(x-1 >= 0 && isBurning![x-1][y]){
            saveTree(savedTree: forest![x-1][y], x: x-1, y: y)
        }
        if(x-1 >= 0 && y+1 < numTrees! && isBurning![x-1][y+1]){
            saveTree(savedTree: forest![x-1][y+1], x: x-1, y: y+1)
        }
        if(x-1 >= 0 && y-1 >= 0 && isBurning![x-1][y-1]){
            saveTree(savedTree: forest![x-1][y-1], x: x-1, y: y-1)
        }
        if(y+1 < numTrees! && isBurning![x][y+1]){
            saveTree(savedTree: forest![x][y+1], x: x, y: y+1)
        }
        if(y-1 >= 0 && isBurning![x][y-1]){
            saveTree(savedTree: forest![x][y-1], x: x, y: y-1)
        }
    }
    
    func saveTree(savedTree:SCNNode, x:Int, y:Int){
        
        if(forest![x][y].name != "burning"){
            return
        }
        if(!rainSoundPlay){
            rainSFX()
        }
        rainSoundPlay = true
        numOnFire = numOnFire - 1
        let newTree = tree!.clone()
        
        let cloud = cloudNode()
        cloud.simdPosition = rainParticles![x][y].simdPosition
        cloud.simdScale = float3(0.225, 0.225, 0.225)
        let rainParticle = rainParticleSystem()
        rainParticle.emitterShape = cloud.geometry
        rainParticle.particleSize = 0.005
        cloud.addParticleSystem(rainParticle)
        newTree.name = "tree"
        newTree.simdPosition = savedTree.simdPosition
        newTree.simdScale = savedTree.simdScale
        particles![x][y] = 4
        isBurning![x][y] = false
        rootNode!.replaceChildNode(savedTree, with: newTree)
        rootNode!.replaceChildNode(rainParticles![x][y], with: cloud)
        rainParticles![x][y] = cloud
        forest![x][y] = newTree
        burningTrees.remove(at: burningTrees.firstIndex(of: savedTree)!)
    }

    func fireSFX(){
        fireAudioPlayer = SCNAudioPlayer(source: fireSound)
        rootNode!.addAudioPlayer(fireAudioPlayer!)
    }
    
    func stopFireSFX(){
        rootNode!.removeAudioPlayer(fireAudioPlayer!)
    }

    func rainSFX(){
        rainAudioPlayer = SCNAudioPlayer(source: rainSound)
        rootNode!.addAudioPlayer(rainAudioPlayer!)
        print("lite")
    }
    
    func stopRainSFX(){
        print("stop")
        if(rainAudioPlayer == nil){
            return
        }
        rootNode!.removeAudioPlayer(rainAudioPlayer!)
    }
    
    func meadowSFX(){
        meadowAudioPlayer = SCNAudioPlayer(source: meadowSound)
        crowAudioPlayer = SCNAudioPlayer(source: crowSound)
        rootNode!.addAudioPlayer(meadowAudioPlayer!)
        rootNode!.addAudioPlayer(crowAudioPlayer!)
    }
    
    func stopMeadowSFX(){
        rootNode!.removeAudioPlayer(meadowAudioPlayer!)
        rootNode!.removeAudioPlayer(crowAudioPlayer!)
    }
    
    func treeNode() -> SCNNode {
        let treeScene = SCNScene(named: "art.scnassets/TreeModel.dae")!
        let tree = treeScene.rootNode
        return tree
    }
    
    func fireTreeNode() -> SCNNode {
        let fireTreeScene = SCNScene(named: "art.scnassets/FireTreeModel.dae")!
        let fireTree = fireTreeScene.rootNode
        return fireTree
    }
    
    func deadTreeNode() -> SCNNode{
        let deadTreeScene = SCNScene(named: "art.scnassets/DeadTreeModel.dae")
        let deadTree = deadTreeScene?.rootNode
        return deadTree!
    }
    
    func cloudNode() -> SCNNode{
        let cloudScene = SCNScene(named: "art.scnassets/CloudModel.dae")
        let cloud = cloudScene?.rootNode
        return cloud!
    }
    
    func fireParticleSystem() -> SCNParticleSystem{
        let particleSystem = SCNParticleSystem(named: "Fire.scnp", inDirectory: "art.scnassets")
        return particleSystem!
    }
    
    func rainParticleSystem() -> SCNParticleSystem{
        let particleSystem = SCNParticleSystem(named: "Rain.scnp", inDirectory: "art.scnassets")
        return particleSystem!
    }
    
    func smokeParticleSystem() -> SCNParticleSystem{
        let particleSystem = SCNParticleSystem(named: "Smoke.scnp", inDirectory: "art.scnassets")
        return particleSystem!
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let location = touches.first!.location(in: sceneView)
        
        // Let's test if a 3D Object was touch
        var hitTestOptions = [SCNHitTestOption: Any]()
        hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
        //hitTestOptions[SCNHitTestOption.ignoreChildNodes] = true
        
        let hitResults: [SCNHitTestResult]  = sceneView.hitTest(location, options: hitTestOptions)
        
        if let hit = hitResults.first {
            print("hitting a tree")
            if(burningTrees.contains(hit.node.parent!)){
                print("hitting burnt tree")
                
                saveTrees(middleTree: hit.node.parent!)
                return
            }
        }
        
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.delegate = self
        
        // Run the view's session
        sceneView.session.run(configuration)
        
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    

    // Override to create and configure nodes for anchors added to the view's session.
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // 1
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // 2
        if rootNode != nil{
            return
        }
        //let width = CGFloat(planeAnchor.extent.x)
        //let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: 2.2, height: 2.2)
        
        // 3
        plane.materials.first?.diffuse.contents = UIColor.brown
        
        // 4
        let planeNode = SCNNode(geometry: plane)
        
        // 5
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        
        // 6
        
        node.addChildNode(planeNode)
        setUpWorld()
        rootNode!.simdScale = float3(0.1,0.1,0.1)
        node.addChildNode(rootNode!)
        //node.simdScale = float3(0.1,0.1,0.1)
    }

    
    public func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    public func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    public func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
