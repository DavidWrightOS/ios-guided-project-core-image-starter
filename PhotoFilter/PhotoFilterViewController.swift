import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Photos

class PhotoFilterViewController: UIViewController {

	@IBOutlet weak var brightnessSlider: UISlider!
	@IBOutlet weak var contrastSlider: UISlider!
	@IBOutlet weak var saturationSlider: UISlider!
	@IBOutlet weak var imageView: UIImageView!
	
    var originalImage: UIImage? {
        didSet {
            guard let originalImage = originalImage else { return }
            
            var scaledSize = imageView.bounds.size
            let scale: CGFloat = UIScreen.main.scale
            
            scaledSize = CGSize(width: scaledSize.width*scale,
                                height: scaledSize.height*scale)
            
            guard let scaledUIImage = originalImage.imageByScaling(toSize: scaledSize) else { return }
            
            scaledImage = CIImage(image: scaledUIImage)
        }
    }
    
    var scaledImage: CIImage? {
        didSet {
            updateImage()
        }
    }
    
	override func viewDidLoad() {
		super.viewDidLoad()
        
//        let filter = CIFilter.gaussianBlur() // built-in filter from Apple
//        // Used to need to call this:
//        // let filter = CIFilter(name: "CIGaussianBlur")
//
//        print(filter)
//        print(filter.attributes)
        
        originalImage = imageView.image
	}
    
    private let context = CIContext() // For better performance, only create one CIContext and reuse it throughout the class
    private let filter = CIFilter.colorControls()
    
    private func updateImage() {
        if let originalImage = scaledImage {
            imageView.image = image(byFiltering: originalImage)
        } else {
            imageView.image = nil
        }
    }
    
    private func image(byFiltering inputImage: CIImage) -> UIImage {
                
        filter.inputImage = inputImage
        filter.saturation = saturationSlider.value
        filter.brightness = brightnessSlider.value
        filter.contrast = contrastSlider.value
        
        guard let outputImage = filter.outputImage else { return originalImage! }
        
        guard let renderedImage = context.createCGImage(outputImage, from: outputImage.extent) else { return originalImage! }
        
        return UIImage(cgImage: renderedImage)
    }
    
    private func presentImagePickerController() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            print("The photo library is not available")
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        
        present(imagePicker, animated: true, completion: nil)
    }
	
	// MARK: Actions
	
	@IBAction func choosePhotoButtonPressed(_ sender: Any) {
		presentImagePickerController()
	}
	
	@IBAction func savePhotoButtonPressed(_ sender: UIButton) {
        guard let originalImage = originalImage?.flattened, let ciImage = CIImage(image: originalImage) else { return }
        
        let processedImage = self.image(byFiltering: ciImage)
        
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetCreationRequest.creationRequestForAsset(from: processedImage)
            }) { (success, error) in
                if let error = error {
                    print("Error saving photo: \(error)")
                    return
                }
                
                DispatchQueue.main.async {
                    self.presentSuccessfulSaveAlert()
                }
            }
        }
	}
    
    private func presentSuccessfulSaveAlert(){
        let alert = UIAlertController(title: "Photo Saved!", message: "The photo has been saved to your Photo Library!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
	

	// MARK: Slider events
	
	@IBAction func brightnessChanged(_ sender: UISlider) {
        updateImage()
	}
	
	@IBAction func contrastChanged(_ sender: Any) {
        updateImage()
	}
	
	@IBAction func saturationChanged(_ sender: Any) {
        updateImage()
	}
}

extension PhotoFilterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.editedImage] as? UIImage {
            originalImage = image
        } else if let image = info[.originalImage] as? UIImage {
            originalImage = image
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
