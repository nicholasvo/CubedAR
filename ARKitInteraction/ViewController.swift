/*

Abstract:
Main view controller for the AR experience.
*/

import ARKit
import SceneKit
import UIKit
import Combine
import RealityKit

class ViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: IBOutlets
    
    @IBOutlet var sceneView: VirtualObjectARView!
    
    @IBOutlet weak var addObjectButton: UIButton!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var upperControlsView: UIView!
    
    @IBOutlet weak var titleTextField: UITextField!
    
    @IBOutlet weak var userView: UIView!
    
    // Drawing
    @IBOutlet weak var drawButton: UIButton!
    var buttonHighlighted = false
    @IBAction func buttonClicked(_ sender: Any) {
        DispatchQueue.main.async {

            if self.buttonHighlighted == false{
                self.drawButton.isHighlighted = true
                self.buttonHighlighted = true
                self.drawButton.backgroundColor = UIColor.systemBlue
            }else{
                self.drawButton.isHighlighted = false
                self.buttonHighlighted = false
                self.drawButton.backgroundColor = UIColor.clear
            }
         }
        
    }
    
    // panning
    var lastPanPosition: SCNVector3?
    var panningNode: SCNNode?
    var panStartZ: CGFloat?
    
    // Annotation
    @IBOutlet weak var addAnnotationView: UIView!
    @IBAction func annotateButton(_ sender: Any) {
        if addAnnotationView.isHidden {
            addAnnotationView.isHidden = false
        } else {
            addAnnotationView.isHidden = true
        }
    }
    @IBOutlet weak var annotationTextField: UITextField!
    @IBAction func addAnnotationButton(_ sender: Any) {

        let text = SCNText(string: annotationTextField.text, extrusionDepth: 2)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        text.materials = [material]
        text.flatness = 0
        
        let node = SCNNode()
        guard let pointOfView = sceneView.pointOfView else { return }
        
        let mat = pointOfView.transform
        let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
        let currentPosition = pointOfView.position + (dir )
        node.position = currentPosition
        node.scale = SCNVector3(x:0.005, y:0.005, z:0.005)
        node.geometry = text
        
        sceneView.scene.rootNode.addChildNode(node)
        
        addAnnotationView.isHidden = true
    }
    @IBAction func addPhoto(_ sender: Any) {
        let plane = SCNPlane(width: 1.0, height: 1.0)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "Bike")
        plane.materials = [material]
        
        guard let pointOfView = sceneView.pointOfView else { return }
        
        let mat = pointOfView.transform
        let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
        let currentPosition = pointOfView.position + (dir)
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = currentPosition
        planeNode.scale = SCNVector3(x:0.5, y:0.5, z:0.5)
        
        sceneView.scene.rootNode.addChildNode(planeNode)
    }
    
  
    @IBAction func addShape(_ sender: Any) {
        let plane = SCNPlane(width: 1.0, height: 1.0)
        plane.firstMaterial?.diffuse.contents = UIColor.systemBlue
        
        guard let pointOfView = sceneView.pointOfView else { return }
        
        let mat = pointOfView.transform
        let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
        let currentPosition = pointOfView.position + (dir * 2.0)
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = currentPosition
        planeNode.scale = SCNVector3(x:0.5, y:0.5, z:0.5)
        
        sceneView.scene.rootNode.addChildNode(planeNode)
    }
    
    
    // MARK: - UI Elements
    
    let coachingOverlay = ARCoachingOverlayView()
    
    var focusSquare = FocusSquare()
    
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    /// The view controller that displays the virtual object selection menu.
    var objectsViewController: VirtualObjectSelectionViewController?
    
    var sharedWithUser:Bool = false
    
    
    // MARK: - DRAWING
    var previousPoint: SCNVector3?
    var lineColor = UIColor.white

    // MARK: - ARKit Configuration Properties
    
    /// A type which manages gesture manipulation of virtual content in the scene.
    lazy var virtualObjectInteraction = VirtualObjectInteraction(sceneView: sceneView, viewController: self)
    
    /// Coordinates the loading and unloading of reference nodes for virtual objects.
    let virtualObjectLoader = VirtualObjectLoader()
    
    /// Marks if the AR experience is available for restart.
    var isRestartAvailable = true
    
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "com.example.apple-samplecode.arkitexample.serialSceneKitQueue")
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let value = UIInterfaceOrientation.landscapeLeft.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Set up variables
        self.titleTextField.delegate = self
        self.annotationTextField.delegate = self
        addAnnotationView.isHidden = true
        userView.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(functionName), name: Notification.Name("NewFunctionName"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(restoreFunc), name: Notification.Name("restore"), object: nil)
        
        // Set up coaching overlay.
        setupCoachingOverlay()

        // Set up scene content.
        sceneView.scene.rootNode.addChildNode(focusSquare)

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
        
        //let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showVirtualObjectSelectionViewController))
        // Set the delegate to ensure this gesture is only used when there are no virtual objects in the scene.
        //tapGesture.delegate = self
        //sceneView.addGestureRecognizer(tapGesture)
        
        // panning
        let panRecognizer = UIPanGestureRecognizer(target: self,
                                                action: #selector(handleThePan(gestureRecognizer:)))
        panRecognizer.delegate = self
        sceneView.addGestureRecognizer(panRecognizer)
        
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Prevent the screen from being dimmed to avoid interuppting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true
        
        print(sharedWithUser)
        // Start the `ARSession`.
        resetTracking()
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        session.pause()
    }
    
    // MARK: - Outlet Management
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @objc func functionName (notification: NSNotification){
        userView.isHidden = false
    }
    
    @objc func restoreFunc (notification: NSNotification){
        restartExperience()
    }
    
    // MARK: - Session management
    
    /// Creates a new AR configuration to run on the `session`.
    func resetTracking() {
        virtualObjectInteraction.selectedObject = nil
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        if #available(iOS 12.0, *) {
            configuration.environmentTexturing = .automatic
        }
        
        //Collaboration
        configuration.isCollaborationEnabled = true
        
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        statusViewController.scheduleMessage("FIND A SURFACE TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .planeEstimation)
    }

    // MARK: - Focus Square

    func updateFocusSquare(isObjectVisible: Bool) {
        if isObjectVisible || coachingOverlay.isActive {
            focusSquare.hide()
        } else {
            focusSquare.unhide()
            statusViewController.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
        }
        
        // Perform ray casting only when ARKit tracking is in a good state.
        if let camera = session.currentFrame?.camera, case .normal = camera.trackingState,
            let query = sceneView.getRaycastQuery(),
            let result = sceneView.castRay(for: query).first {
            
            updateQueue.async {
                self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
                self.focusSquare.state = .detecting(raycastResult: result, camera: camera)
            }
            if !coachingOverlay.isActive {
                addObjectButton.isHidden = false
            }
            statusViewController.cancelScheduledMessage(for: .focusSquare)
        } else {
            updateQueue.async {
                self.focusSquare.state = .initializing
                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
            }
            //addObjectButton.isHidden = true
            objectsViewController?.dismiss(animated: false, completion: nil)
        }
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Blur the background.
        blurView.isHidden = false
        
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.blurView.isHidden = true
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - PANNING
    @objc func handleThePan(gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            let location = gestureRecognizer.location(in: sceneView)
            guard let hitNodeResult = sceneView.hitTest(location, options: nil).first else { return }
            lastPanPosition = hitNodeResult.worldCoordinates
            panningNode = hitNodeResult.node
            panStartZ = CGFloat(sceneView.projectPoint(lastPanPosition!).z)
        case .changed:
            guard lastPanPosition != nil, panningNode != nil, panStartZ != nil else { return }
            let location = gestureRecognizer.location(in: sceneView)

            // the touch has moved and worldTouchPosition is the new position in 3d space that the touch is at.
            // We use the panStartZ and never change it because panning should never change the z position (relative to the camera)
            // This is similar to getting the hitTest location of the gesture again,
            // but does not require the gesture to still intersect with the dragging object.
            let worldTouchPosition = sceneView.unprojectPoint(SCNVector3(location.x, location.y, panStartZ!))

            let movementVector = SCNVector3(worldTouchPosition.x - lastPanPosition!.x,
                                            worldTouchPosition.y - lastPanPosition!.y,
                                            worldTouchPosition.z - lastPanPosition!.z)
            panningNode?.localTranslate(by: movementVector)

            self.lastPanPosition = worldTouchPosition
        case .ended:
            (lastPanPosition, panningNode, panStartZ) = (nil, nil, nil)
        default:
            return
        }
    }
    
}
