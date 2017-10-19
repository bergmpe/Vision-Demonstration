//
//  ViewController.swift
//  Vision Demonstration
//
//  Created by padrao on 19/10/17.
//  Copyright © 2017 padrao. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController {

    @IBOutlet weak var photoView: UIImageView!
    let image = UIImage(named: "kiko-e-chaves")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let imageData = UIImageJPEGRepresentation(image!, 1.0) else { return }
        
        photoView.image = image
        photoView.contentMode = .scaleAspectFit
        
        detectFaceRectangle(imageData: imageData)
        detectFaceLandMarks(imageData: imageData)
        detectNoseLandMark(imageData: imageData)
    }
    
    //0
    func detectFaceRectangle(imageData: Data){
        
        let faceRequest = VNDetectFaceRectanglesRequest { (request, error) in
            if let _ = error{
                print("Error while detecting faces")
            }
            else{
                guard let results = request.results as? [VNFaceObservation]
                    else { fatalError("unexpected result type") }
                
                results.forEach({ (faceObservation) in
                    DispatchQueue.main.async {
                        self.photoView.image = self.drawRectangleOnFace(originalImage: self.photoView.image!, faceRect: faceObservation.boundingBox)
                    }
                })
            }
        }
        performRequest(imageData: imageData, requests: [faceRequest] )
    }
    
    //2
    func detectFaceLandMarks(imageData: Data){
        
        let request = VNDetectFaceLandmarksRequest {
            (request, error) in
            if let error = error  {
                print("Failed to detect face landmarks",error)
                return
            }
            guard let results = request.results as? [VNFaceObservation]
                else { fatalError("unexpected result type") }
            
            print("Found \(results.count) faces")
            
            results.forEach{ faceObservation in
                
                if let landmarks = faceObservation.landmarks {//for each face detected on imagem
                    var landmarkRegions: [VNFaceLandmarkRegion2D] = []
                    
                    if let faceContour = landmarks.faceContour {
                        landmarkRegions.append(faceContour)
                        
                    }
                    if let leftEye = landmarks.leftEye {
                        landmarkRegions.append(leftEye)
                        print(leftEye.pointsInImage(imageSize: self.image!.size))
                        
                    }
                    if let rightEye = landmarks.rightEye {
                        landmarkRegions.append(rightEye)
                    }
                    
                    if let nose = landmarks.noseCrest{
                        landmarkRegions.append(nose)
                    }
                    landmarkRegions.forEach{ landMarkRegion in
                        DispatchQueue.main.async {
                            self.photoView.image = self.drawLandMarks(originalImage: self.photoView.image!, pathPoints: landMarkRegion.pointsInImage(imageSize: self.image!.size))
                        }
                    }
                    
                }
            }
        }
        performRequest(imageData: imageData, requests: [request])
    }
    
    //3
    func detectNoseLandMark(imageData: Data){
        
        let request = VNDetectFaceLandmarksRequest {
            (request, error) in
            if let error = error  {
                print("Failed to detect face landmarks",error)
                return
            }
            guard let results = request.results as? [VNFaceObservation]
                else { fatalError("unexpected result type") }
            
            print("Found \(results.count) faces")
            
            //for each face detected on imagem
            results.forEach{ faceObservation in
                
                if let landmarks = faceObservation.landmarks {
                    let faceRect = faceObservation.boundingBox
                    if let nose = landmarks.noseCrest{
                        DispatchQueue.main.async {
                            self.photoView.image = self.drawDogNose(originalImage: self.photoView.image!, nosePoints: nose.pointsInImage(imageSize: self.image!.size), faceRect: faceRect)
                        }
                    }
                }
            }
        }
        performRequest(imageData: imageData, requests: [request] )
    }
    
    //perform the requests on the image.
    func performRequest(imageData: Data,requests: [VNRequest] ){
        
        DispatchQueue.global(qos: .background).async {
            let handler = VNImageRequestHandler(data: imageData, options: [:])
            do {
                try handler.perform( requests )
            } catch let reqError {
                print("Error in req",reqError)
            }
        }
    }
    
    //draw circles on landMark points.
    func drawLandMarks( originalImage: UIImage, pathPoints: [CGPoint]) -> UIImage {
        
        let contextPoint = pathPoints.map({ point -> CGPoint in
            return CGPoint(x: point.x , y: originalImage.size.height - point.y )
        })
        // Create a context of the starting image size and set it as the current one
        UIGraphicsBeginImageContext(originalImage.size)
        
        // Draw the starting image in the current context as background
        originalImage.draw(at: CGPoint.zero)
        
        // Get the current context
        let context = UIGraphicsGetCurrentContext()!
        context.setLineWidth(0.1)
        context.setFillColor(UIColor.red.cgColor)
        
        let circleSize = CGSize(width: originalImage.size.width * 0.01, height: originalImage.size.width * 0.01)//the circle size must be proportional to image size.
        for point in contextPoint{
            context.move(to: point)
            context.addEllipse(in: CGRect.init(origin: point, size: circleSize))
            context.drawPath(using: .fill)
        }
        
        // Save the context as a new UIImage
        let myImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Return modified image
        return myImage!
    }
    
    func drawDogNose( originalImage: UIImage, nosePoints: [CGPoint], faceRect: CGRect ) -> UIImage{
        let nose = UIImage(named: "nose")
        
        // Create a context of the original image size and set it as the current one
        UIGraphicsBeginImageContext(originalImage.size)
        
        originalImage.draw(at: CGPoint.zero)// Draw the original image in the current context as background
        
        let width  = (faceRect.width  * originalImage.size.width ) * 0.3
        let height = (faceRect.height * originalImage.size.height) * 0.3
        let x = nosePoints.last!.x - width / 2
        let y = nosePoints.last!.y + height / 2
        let rect = CGRect(x: x, y: originalImage.size.height - y, width: width, height: height)
        nose?.draw(in: rect )
        
        // Save the context as a new UIImage
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!// Return modified image
    }
    
    
    func drawRectangleOnFace(originalImage: UIImage, faceRect: CGRect) -> UIImage{
        
        // Create a context of the starting image size and set it as the current one
        UIGraphicsBeginImageContext(originalImage.size)
        
        // Draw the starting image in the current context as background
        originalImage.draw(at: CGPoint.zero)
        
        // Get the current context
        let context = UIGraphicsGetCurrentContext()!
        context.setLineWidth(0.1)
        context.setFillColor(UIColor(red: 1, green: 0.0, blue: 0.0, alpha: 0.4).cgColor)
        
        let width = originalImage.size.width * faceRect.width
        let heigth = originalImage.size.height * faceRect.height
        let x = (faceRect.origin.x * originalImage.size.width) + ((originalImage.size.width * faceRect.width) - width) / 2
        let y = originalImage.size.height - (faceRect.maxY * originalImage.size.height)//y coordinate is upsidedown
        let rect = CGRect(x: x, y: y, width: width, height: heigth)
        
        context.addRect(rect)
        context.drawPath(using: .fill)
        
        // Save the context as a new UIImage
        let myImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Return modified image
        return myImage!
        
    }
}

