//
//  ViewController.swift
//  Flower IdentifierML
//
//  Created by Mohamed Jaber on 20/12/2020.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var descriptionLabel: UILabel!
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    @IBOutlet weak var imageView: UIImageView!
    var pickedImage: UIImage?
    let imagePicker=UIImagePickerController()
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        //if u want to allow user to edit like crop it, so make it allowsEditing=true
        imagePicker.sourceType = .camera
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //in case allowsEditig=true,info[UIImagePickerController.InfoKey.editedImage ]
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage ] as? UIImage{
            pickedImage = userPickedImage
            guard let ciimage = CIImage(image: userPickedImage)else{
                fatalError("Can't convert Image to CoreImageImage")
            }
            detect(image: ciimage)
            imagePicker.dismiss(animated: true, completion: nil)        }
    }
    func detect(image: CIImage){
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model)else{
            fatalError("Loading CoreML Model failed")
        }
        let request=VNCoreMLRequest(model: model) { (request, error) in
            guard let results=request.results as? [VNClassificationObservation] else {
                fatalError("Model Failed to process image")
            }
            if let firstResult=results.first{
                self.navigationItem.title="\(firstResult.identifier.capitalized)"
                self.requestInfo(flowerName: firstResult.identifier)
            }
        }
        let handler=VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        }catch{
            print(error)
        }
    }
    func requestInfo(flowerName: String){
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500",
            
        ]
        //https://en.wikipedia.org/w/api.php?format=json&action=query&prop=extracts|pageimages&exintro=&explaintext=&titles=barberton%20daisy&redirects=1&pithumbsize=500&indexpageids
                
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess{
                let flowerJSON : JSON = JSON(response.result.value!)
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                self.descriptionLabel.text=flowerDescription
                //Text to Speech
                let utTerance = AVSpeechUtterance(string: "\(flowerDescription)")
                utTerance.voice = AVSpeechSynthesisVoice(language: "en-gb")
                let Synthesizer = AVSpeechSynthesizer()
                Synthesizer.speak(utTerance)
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
            }else {
                self.imageView.image=self.pickedImage
                self.descriptionLabel.text="Connection Issues"
            }
        }
    }
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
}

