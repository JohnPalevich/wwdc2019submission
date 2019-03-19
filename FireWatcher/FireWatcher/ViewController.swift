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

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var tree: SCNNode?
    var forest:[SCNNode] = []
    var isBurning: [[Bool]] = Array(repeating: Array(repeating: false, count: 20), count: 20)
    var numTrees: Int?
    var burningTrees:[SCNNode] = []
    var spreadTrees: [Int] = []
    var rootNode: SCNNode?
    var timer: Timer?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        //named: "art.scnassets/TreeModel.dae"
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        
        numTrees = 20
//        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,
//                                  ARSCNDebugOptions.showWorldOrigin/*,
//             .showBoundingBoxes,
//             .showWireframe,
//             .showSkeletons,
//             .showPhysicsShapes,
//             .showCameras*/
//        ]
        // a camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
        scene.rootNode.addChildNode(cameraNode)
        rootNode = scene.rootNode
        createTrees()
        timer =  Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { (t) in
            self.updateGame()}
    }
    
    func updateGame(){
        spreadFire()
        igniteTree()
    }
    
    func createTrees(){
        tree = treeNode()
        for i in -numTrees!/2..<numTrees!/2{
            for j in -numTrees!/2..<numTrees!/2{
                let newTree = tree!.clone()
                newTree.name = "tree"
                newTree.simdPosition = float3(1 * Float(i), -10, 1*Float(j))
                newTree.simdScale = float3(0.1,0.1,0.1)
                rootNode!.addChildNode(newTree)
                forest.append(newTree)
            }
        }

    }
    
    func spreadFire(){
        for i in 0..<numTrees!{
            for j in 0..<numTrees!{
                if isBurning[i][j]{
                    if i+1 < numTrees! && !isBurning[i+1][j]{
                        igniteSpecifiedTree(pos: (i+1)*10 + j, x:(i+1)*10, y: j)
                        spreadTrees.append(i+1)
                        spreadTrees.append(j)
                    }
                    if i-1 >= 0 && !isBurning[i-1][j]{
                        igniteSpecifiedTree(pos: (i-1)*10 + j, x:(i-1)*10, y: j)
                        spreadTrees.append(i-1)
                        spreadTrees.append(j)
                    }
                    if j+1 < numTrees! && !isBurning[i][j+1]{
                        igniteSpecifiedTree(pos: i*10 + j+11, x:i*10, y: j+1)
                        spreadTrees.append(i)
                        spreadTrees.append(j+1)
                    }
                    if j-1 >= 0 && !isBurning[i][j-1]{
                        igniteSpecifiedTree(pos: i*10 + j-1, x:i*10, y: j-1)
                        spreadTrees.append(i)
                        spreadTrees.append(j-1)
                    }
                }
            }
        }
        while spreadTrees.count > 0{
            isBurning[spreadTrees[0]][spreadTrees[1]] = true
            spreadTrees.remove(at: 1)
            spreadTrees.remove(at: 0)
        }
    }
    
    func igniteSpecifiedTree(pos:Int, x:Int, y:Int){
        let oldTree = forest[pos]
        let ignitedTree = fireTreeNode()
        ignitedTree.simdPosition = oldTree.simdPosition
        ignitedTree.simdScale = oldTree.simdScale
        rootNode!.replaceChildNode(oldTree, with: ignitedTree)
        burningTrees.append(ignitedTree)
    }
    
    func igniteTree(){
        var number = Int.random(in: 0 ..< forest.count)
        var oldTree = forest[number]
        var x = Int(oldTree.simdPosition.x + Float(numTrees!/2))
        var z = Int(oldTree.simdPosition.z + Float(numTrees!/2))
//        while(isBurning[x][z]){
//            number = Int.random(in: 0 ..< forest.count)
//            oldTree = forest[number]
//            x = Int(oldTree.simdPosition.x + Float(numTrees!/2))
//            z = Int(oldTree.simdPosition.z + Float(numTrees!/2))
//        }
        let ignitedTree = fireTreeNode()
        ignitedTree.simdPosition = oldTree.simdPosition
        ignitedTree.simdScale = oldTree.simdScale
        
        isBurning[x][z] = true
        rootNode!.replaceChildNode(oldTree, with: ignitedTree)
        burningTrees.append(ignitedTree)
    }
    
    func saveTree(savedTree:SCNNode){
        let newTree = tree!.clone()
        newTree.name = "tree"
        newTree.simdPosition = savedTree.simdPosition
        newTree.simdScale = savedTree.simdScale
        isBurning[Int(newTree.simdPosition.x + Float(numTrees!/2))][Int(newTree.simdPosition.z + Float(numTrees!/2))] = false
        rootNode!.replaceChildNode(savedTree, with: newTree)
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
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
                saveTree(savedTree: hit.node.parent!)
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
