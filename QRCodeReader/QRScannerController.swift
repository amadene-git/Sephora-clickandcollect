//
//  QRScannerViewController.swift
//  QRCodeApp
//
//  Created by Farukh IQBAL on 21/12/2020.
//

import UIKit
import AVFoundation

class QRScannerController: UIViewController {
    
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    var done = false

    @IBOutlet var topBar: UIView!

    private let supportedCodeTypes = [AVMetadataObject.ObjectType.upce,
                                      AVMetadataObject.ObjectType.code39,
                                      AVMetadataObject.ObjectType.code39Mod43,
                                      AVMetadataObject.ObjectType.code93,
                                      AVMetadataObject.ObjectType.code128,
                                      AVMetadataObject.ObjectType.ean8,
                                      AVMetadataObject.ObjectType.ean13,
                                      AVMetadataObject.ObjectType.aztec,
                                      AVMetadataObject.ObjectType.pdf417,
                                      AVMetadataObject.ObjectType.itf14,
                                      AVMetadataObject.ObjectType.dataMatrix,
                                      AVMetadataObject.ObjectType.interleaved2of5,
                                      AVMetadataObject.ObjectType.qr]

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        done = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Obtenir la caméra arrière pour capture des vidéos
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Échec de l'obtention de l'appareil photo")
            return
        }
        
        do {
            // Obtenir une instance de la classe AVCaptureDeviceInput à l'aide de l'objet périphérique précédent
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Définir le périphérique d'entrée sur la session de capture
            captureSession.addInput(input)
            
            // Initialiser un objet AVCaptureMetadataOutput et le définir comme périphérique de sortie pour la session de capture
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            // Définir le délégué et utiliser la file d'attente de distribution DispatchQueue par défaut pour exécuter le rappel
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
//            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            
            // Initialiser le calque d'aperçu vidéo et l'ajouter en tant que sous-calque au calque de la vue viewPreview
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            // Démarrer la capture vidéo
            captureSession.startRunning()
            
            // Déplacer la barre supérieure vers l'avant
            view.bringSubviewToFront(topBar)
            
            // Initialiser le cadre du QR code pour mettre en évidence le QR code
            qrCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.yellow.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubviewToFront(qrCodeFrameView)
            }
            
        } catch {
            // Si une erreur survient, l'imprimer simplement et ne plus continuer
            print(error)
            return
        }
    }

//    override func viewWillAppear(_ animated: Bool) {
//    super.viewWillAppear(animated)
//    // Obtenir la caméra arrière pour capture des vidéos
//    guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
//        print("Échec de l'obtention de l'appareil photo")
//        return
//    }
//    
//    do {
//        // Obtenir une instance de la classe AVCaptureDeviceInput à l'aide de l'objet périphérique précédent
//        let input = try AVCaptureDeviceInput(device: captureDevice)
//        
//        // Définir le périphérique d'entrée sur la session de capture
//        captureSession.addInput(input)
//        
//        // Initialiser un objet AVCaptureMetadataOutput et le définir comme périphérique de sortie pour la session de capture
//        let captureMetadataOutput = AVCaptureMetadataOutput()
//        captureSession.addOutput(captureMetadataOutput)
//        
//        // Définir le délégué et utiliser la file d'attente de distribution DispatchQueue par défaut pour exécuter le rappel
//        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
////            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
//        captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
//        
//        // Initialiser le calque d'aperçu vidéo et l'ajouter en tant que sous-calque au calque de la vue viewPreview
//        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
//        videoPreviewLayer?.frame = view.layer.bounds
//        view.layer.addSublayer(videoPreviewLayer!)
//        
//        // Démarrer la capture vidéo
//        captureSession.startRunning()
//        
//        // Déplacer la barre supérieure vers l'avant
//        view.bringSubviewToFront(topBar)
//        
//        // Initialiser le cadre du QR code pour mettre en évidence le QR code
//        qrCodeFrameView = UIView()
//        
//        if let qrCodeFrameView = qrCodeFrameView {
//            qrCodeFrameView.layer.borderColor = UIColor.yellow.cgColor
//            qrCodeFrameView.layer.borderWidth = 2
//            view.addSubview(qrCodeFrameView)
//            view.bringSubviewToFront(qrCodeFrameView)
//        }
//        
//    } catch {
//        // Si une erreur survient, l'imprimer simplement et ne plus continuer
//        print(error)
//        return
//    }
//}
}


extension QRScannerController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Vérifier si le tableau metadataObjects n'est pas nul et contient au moins un objet
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            return
        }

        
        // Obtenir l'objet de métadonnées
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
//        if metadataObj.type == AVMetadataObject.ObjectType.qr {
//
//        }
        
        if supportedCodeTypes.contains(metadataObj.type) {
            // Si les métadonnées trouvées sont égales aux métadonnées du QR code, mettre à jour le texte du label d'état et définir ses limites
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil && done == false {
                done = true
                self.performSegue(withIdentifier: "Scanne", sender: self)
            }
        }
    }
}
