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
    var burningTrees:[SCNNode] = []
    var rootNode: SCNNode?
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
        igniteTree()
    }
    
    func createTrees(){
        tree = treeNode()
        for i in -10..<10{
            for j in -10..<10{
                let newTree = tree!.clone()
                newTree.name = "tree"
                newTree.simdPosition = float3(1 * Float(i), -10, 1*Float(j))
                newTree.simdScale = float3(0.1,0.1,0.1)
                rootNode!.addChildNode(newTree)
                forest.append(newTree)
            }
        }

    }
    
    func igniteTree(){
        let number = Int.random(in: 0 ..< forest.count)
        let oldTree = forest[number]
        let ignitedTree = fireTreeNode()
        ignitedTree.simdPosition = oldTree.simdPosition
        ignitedTree.simdScale = oldTree.simdScale
        oldTree.removeFromParentNode()
        rootNode!.addChildNode(ignitedTree)
        forest.remove(at: number)
        burningTrees.append(ignitedTree)
    }
    
    func saveTree(savedTree:SCNNode){
        let newTree = tree!.clone()
        newTree.name = "tree"
        newTree.simdPosition = savedTree.simdPosition
        newTree.simdScale = savedTree.simdScale
        savedTree.removeFromParentNode()
        rootNode!.addChildNode(newTree)
        burningTrees.remove(at: burningTrees.firstIndex(of: savedTree)!)
        forest.append(newTree)
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
