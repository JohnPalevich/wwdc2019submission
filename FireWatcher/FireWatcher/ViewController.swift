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
    }
    
    func setUpWorld(){
        numTrees = 20
        forest = Array(repeating: Array(repeating: SCNNode(), count: numTrees!), count: numTrees!)
        isBurning = Array(repeating: Array(repeating: false, count: numTrees!), count: numTrees!)
        particles = Array(repeating: Array(repeating: 0, count: numTrees!), count: numTrees!)
        rainParticles = Array(repeating: Array(repeating: SCNNode(), count: numTrees!), count: numTrees!)
        //        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,
        //                                  ARSCNDebugOptions.showWorldOrigin/*,
        //             .showBoundingBoxes,
        //             .showWireframe,
        //             .showSkeletons,
        //             .showPhysicsShapes,
        //             .showCameras*/
        //        ]
        // a camera
        rootNode = SCNNode()
        initializeNodes()
        igniteTree()
        //igniteSpecifiedTree(x: 0, y: 0)
        //isBurning![0][0] = true
        timer =  Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { (t) in
            self.updateGame()}
    }
    
    func updateGame(){
        updateParticles()
        spreadFire()
        igniteTree()
    }
    
    func initializeNodes(){
        tree = treeNode()
        let rainNode = SCNNode()
        //rainNode = rainNode()
        for i in -numTrees!/2..<numTrees!/2{
            for j in -numTrees!/2..<numTrees!/2{
                let newRain = rainNode.clone()
                newRain.simdPosition = float3(1 * Float(i), 10, 1 * Float(j))
                let newTree = tree!.clone()
                newTree.name = "tree"
                newTree.simdPosition = float3(1 * Float(i), 0.5, 1*Float(j))
                newTree.simdScale = float3(0.1,0.1,0.1)
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
                    rainParticles![i][j].removeAllParticleSystems()
                }
            }
        }
    }
    
    func igniteSpecifiedTree(x:Int, y:Int){
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
        let newTree = tree!.clone()
        let rainParticle = rainParticleSystem()
        rainParticle.emitterShape = rainParticles![x][y].geometry
        rainParticle.particleSize = 0.01
        newTree.name = "tree"
        newTree.simdPosition = savedTree.simdPosition
        rainParticles![x][y].addParticleSystem(rainParticle)
        newTree.simdScale = savedTree.simdScale
        particles![x][y] = 4
        isBurning![x][y] = false
        rootNode!.replaceChildNode(savedTree, with: newTree)
        forest![x][y] = newTree
        burningTrees.remove(at: burningTrees.firstIndex(of: savedTree)!)
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
    
    func fireParticleSystem() -> SCNParticleSystem{
        let particleSystem = SCNParticleSystem(named: "Fire.scnp", inDirectory: nil)
        return particleSystem!
    }
    
    func rainParticleSystem() -> SCNParticleSystem{
        let particleSystem = SCNParticleSystem(named: "Rain.scnp", inDirectory: nil)
        return particleSystem!
    }
    
    func smokeParticleSystem() -> SCNParticleSystem{
        let particleSystem = SCNParticleSystem(named: "Smoke.scnp", inDirectory: nil)
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
        
        // No object was touch? Try feature points
        let hitResultsFeaturePoints: [ARHitTestResult]  = sceneView.hitTest(location, types: .featurePoint)
        
        if let hit = hitResultsFeaturePoints.first {
            
            // Get the rotation matrix of the camera
            let rotate = simd_float4x4(SCNMatrix4MakeRotation(sceneView.session.currentFrame!.camera.eulerAngles.y, 0, 1, 0))
            
            // Combine the matrices
            let finalTransform = simd_mul(hit.worldTransform, rotate)
            sceneView.session.add(anchor: ARAnchor(transform: finalTransform))
            //sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
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
        let plane = SCNPlane(width: 5, height: 5)
        
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
