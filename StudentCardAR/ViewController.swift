//
//  ViewController.swift
//  StudentCardAR
//
//  Created by Marlon Lückert on 22.06.20.
//  Copyright © 2020 Marlon Lückert. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var placeholderImage: UIImageView!
    
    var hawModelNode: SCNNode!
    var lecturesModelNode: SCNNode!
    var cafeteriaModelNode: SCNNode!
    var textModelNode: SCNNode!
    var gelaendeModelNode: SCNNode!
    var planeNode: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false

        let hawModelScene = SCNScene(named: "art.scnassets/HAW.scn")!
        hawModelNode =  hawModelScene.rootNode.childNode(withName: "HAW", recursively: true)
        lecturesModelNode =  hawModelScene.rootNode.childNode(withName: "lectures", recursively: true)
        cafeteriaModelNode = hawModelScene.rootNode.childNode(withName: "cafeteria", recursively: true)
        textModelNode = hawModelScene.rootNode.childNode(withName: "Text", recursively: true)
        gelaendeModelNode = hawModelScene.rootNode.childNode(withName: "Gelaende", recursively: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let configuration = ARImageTrackingConfiguration()

        guard let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            // failed to read them – crash immediately!
            fatalError("Couldn't load tracking images.")
        }

        configuration.trackingImages = trackingImages
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // make sure this is an image anchor, otherwise bail out
        guard let imageAnchor = anchor as? ARImageAnchor else { return nil }
        guard let imageName = imageAnchor.referenceImage.name else { return nil }
        
        DispatchQueue.main.async {
            self.placeholderImage.isHidden = true
        }
                
        let node = SCNNode()
        
        if imageName == "studentid" {
            hawModelNode.scale = SCNVector3(x: 0, y: 0, z: 0)
            hawModelNode.position.y = 0.015
            node.addChildNode(hawModelNode)
            
            textModelNode.scale = SCNVector3(x: 0.04, y: 0.04, z: 0.04)
            textModelNode.position.y = 0.01
            textModelNode.position.z = -0.045
            textModelNode.opacity = 0
            node.addChildNode(textModelNode)
            
            lecturesModelNode.scale = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
            lecturesModelNode.eulerAngles.y = -.pi / 2
            lecturesModelNode.position.y = 0.005
            lecturesModelNode.position.x = 0.08
            lecturesModelNode.opacity = 0
            node.addChildNode(lecturesModelNode)
            
            cafeteriaModelNode.scale = SCNVector3(x: 0.045, y: 0.045, z: 0.045)
            cafeteriaModelNode.eulerAngles.y = .pi / 2
            cafeteriaModelNode.position.y = 0.005
            cafeteriaModelNode.position.x = -0.08
            cafeteriaModelNode.opacity = 0
            node.addChildNode(cafeteriaModelNode)
            
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width,
                                 height: imageAnchor.referenceImage.physicalSize.height)
            planeNode = SCNNode(geometry: plane)
            planeNode.opacity = 0
            planeNode.eulerAngles.x = -.pi / 2
            
            node.addChildNode(planeNode)
        } else {
            gelaendeModelNode.scale = SCNVector3(x: 0.12, y: 0.12, z: 0.12)
            gelaendeModelNode.position.y = 0.01
            node.addChildNode(gelaendeModelNode)
        }
        
        let spotLight = createSpotLight()
        
        node.addChildNode(spotLight)

        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        
        if (!imageAnchor.isTracked) {
            hawModelNode.scale = SCNVector3(x: 0, y: 0, z: 0)
            return
        }
        
        
        if hawModelNode.scale.x == 0 {
            lecturesModelNode.opacity = 0
            cafeteriaModelNode.opacity = 0
            textModelNode.opacity = 0
            let scaleAction = SCNAction.scale(to: 0.05, duration: 0.3)
            scaleAction.timingMode = SCNActionTimingMode.easeInEaseOut
            hawModelNode.runAction(scaleAction)
        }
        
        let (min, max) = planeNode.boundingBox
        let bottomLeft = SCNVector3(min.x, min.y, 0)
        let topRight = SCNVector3(max.x, max.y, 0)

        let topLeft = SCNVector3(min.x, max.y, 0)
        let bottomRight = SCNVector3(max.x, min.y, 0)
        
        let worldBottomLeft = planeNode.convertPosition(bottomLeft, to: sceneView.scene.rootNode)
        let worldTopRight = planeNode.convertPosition(topRight, to: sceneView.scene.rootNode)

        let worldTopLeft = planeNode.convertPosition(topLeft, to: sceneView.scene.rootNode)
        let worldBottomRight = planeNode.convertPosition(bottomRight, to: sceneView.scene.rootNode)
        
        let screenTopLeft = renderer.projectPoint(worldTopLeft)
        let screenTopRight = renderer.projectPoint(worldTopRight)
        let screenBottomRight = renderer.projectPoint(worldBottomRight)
        let screenBottomLeft = renderer.projectPoint(worldBottomLeft)
        
        
        let fadeIn = SCNAction.sequence([SCNAction.wait(duration: 0.4),  SCNAction.fadeOpacity(to: 1, duration: 0.2)])
        let fadeOut = SCNAction.fadeOpacity(to: 0, duration: 0.2)

        if (screenTopRight.y > screenBottomLeft.y) {
            //left
            hawModelNode.runAction(SCNAction.rotateTo(x: 0, y: .pi / 2, z: 0, duration: 0.3))
            lecturesModelNode.runAction(fadeOut)
            cafeteriaModelNode.runAction(fadeIn)
            textModelNode.runAction(fadeOut)
        } else if (screenTopLeft.y > screenBottomRight.y) {
            // right
            hawModelNode.runAction(SCNAction.rotateTo(x: 0, y: -.pi / 2, z: 0, duration: 0.3))
            lecturesModelNode.runAction(fadeIn)
            cafeteriaModelNode.runAction(fadeOut)
            textModelNode.runAction(fadeOut)
        } else {
            // top
            hawModelNode.runAction(SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.3))
            lecturesModelNode.runAction(fadeOut)
            cafeteriaModelNode.runAction(fadeOut)
            textModelNode.runAction(fadeIn)
        }
            

    }
    
    func createSpotLight() -> SCNNode {
        let spotLight = SCNNode()
        spotLight.light = SCNLight()
        spotLight.scale = SCNVector3(1,1,1)
        spotLight.light?.intensity = 600
        spotLight.light?.shadowMode = .deferred
        spotLight.light?.shadowColor = UIColor.black.withAlphaComponent(0.75)
        spotLight.light?.automaticallyAdjustsShadowProjection = true
        spotLight.castsShadow = true
        spotLight.position = SCNVector3Zero
        spotLight.eulerAngles.x = -.pi / 2
        spotLight.light?.type = SCNLight.LightType.directional
        spotLight.light?.color = UIColor.white
        
        return spotLight
    }
    
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
