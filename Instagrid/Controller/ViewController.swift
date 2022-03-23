//
//  ViewController.swift
//  Instagrid
//
//  Created by Rodolphe Desruelles on 11/03/2022.
//

import PhotosUI
import UIKit

class ViewController: UIViewController {
    // Layouts are numbered from 0 to 2 (stored in layoutButtons tag)
    // imagesViews are numbered from 0 to 3 (stored in imageViews tag)

    private let defaultLayoutTag = 1
    private let imagesViewHiddenAccordingToLayout = [1, 3, nil]

    // EXTERNAL CONTROLLERS //
    // ----------------------//

    private let imagePicker = UIImagePickerController()
    private var shareManager: UIActivityViewController!

    // VIEW COMPONENTS //
    // -----------------//

    @IBOutlet private var layoutButtons: [UIButton]!

    private var editedImageView: UIImageView?

    @IBOutlet private var imagesViews: [UIImageView]!
    @IBOutlet private var imagesGrid: UIView!

    @IBOutlet private var viewToAnimateWhenSwiping: UIView!

    // EVENTS //
    // --------//

    private var swipeGestureRecognizer: UISwipeGestureRecognizer!

    @IBAction private func didTapLayoutButton(_ sender: UIButton) {
        selectLayout(sender.tag)
    }

    @objc private func didTapImageView(_ sender: UITapGestureRecognizer) {
        editedImageView = (sender.view as! UIImageView)
        presentImagePicker()
    }

    @objc private func didSwipe(_: UISwipeGestureRecognizer) {
        presentShareManager()
    }

    @objc private func orientationDidChange() {
        updateSwipeDirection()
    }

    // LOGIC //
    // -------//

    // LAYOUT

    private func selectLayout(_ selectedLayoutTag: Int) {
        // Set selected layout button checked
        for button in layoutButtons {
            button.isSelected = (button.tag == selectedLayoutTag)
        }

        // Display selected layout
        for imageView in imagesViews {
            imageView.isHidden = isImageViewHidden(withTag: imageView.tag, forLayoutTag: selectedLayoutTag)
        }
    }

    private func isImageViewHidden(withTag imageViewTag: Int, forLayoutTag layoutTag: Int) -> Bool {
        imagesViewHiddenAccordingToLayout[layoutTag] == imageViewTag
    }

    // IMAGE PICKER

    private func presentImagePicker() {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary

        present(imagePicker, animated: true)
    }

    // SHARABLE IMAGE GRID

    private func exportedImagesGridAsImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: imagesGrid.bounds.size)
        let image = renderer.image { _ in
            imagesGrid.drawHierarchy(in: imagesGrid.bounds, afterScreenUpdates: true)
        }
        return image
    }

    // SHARE MANAGER

    private func presentShareManager() {
        shareManager = UIActivityViewController(activityItems: [exportedImagesGridAsImage() as Any],
                                                  applicationActivities: nil)
        // shareManager.popoverPresentationController?.sourceView = view

        shareManager.completionWithItemsHandler = { activityType, completed, _, _ in

            // For debugging
            // print("activityType=\(activityType.debugDescription), completed=\(completed), returnedItems=\(returnedItems ?? []), activityError=\(activityError.debugDescription)")

            // Condition to bring back the application UI
            if completed || (activityType == nil && !completed) {
                self.reverseSwipingAnimation()
            }
        }

        DispatchQueue.main.async {
            self.animateViewWhenSwiping()
        }
        present(shareManager, animated: true)

    }

    // VIEW TRANSLATION WHEN SWIPING

    private func reverseSwipingAnimation() {
        UIView.animate(
            withDuration: 0.3, delay: 0, options: [],
            animations: { self.viewToAnimateWhenSwiping.transform = .identity }, completion: nil
        )
    }

    private func animateViewWhenSwiping(completion: ((Bool) -> Void)? = nil) {
        let frameRelativeToScreen = viewToAnimateWhenSwiping.superview?.convert(viewToAnimateWhenSwiping.frame, to: nil) ?? view.frame

        let translation = UIDevice.current.orientation.isLandscape ?
            CGAffineTransform(translationX: -frameRelativeToScreen.maxX, y: 0)
            : CGAffineTransform(translationX: 0, y: -frameRelativeToScreen.maxY)

        UIView.animate(
            withDuration: 0.3, delay: 0, options: [],
            animations: { self.viewToAnimateWhenSwiping.transform = translation },
            completion: completion
        )
    }

    // CHANGE SWIPE DIRECTION CONSTRAINT

    private func updateSwipeDirection() {
        swipeGestureRecognizer.direction = {
            switch UIDevice.current.orientation {
            case .portrait:
                return .up
            case .landscapeLeft, .landscapeRight, .portraitUpsideDown:
                return .left
            default:
                return .up
            }
        }()
    }

    // INITIALIZATION

    override func viewDidLoad() {
        super.viewDidLoad()

        // INIT GESTURE AND ORIENTATION TRIGERRING FOR SWIPE

        swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe(_:)))
        updateSwipeDirection()
        view.addGestureRecognizer(swipeGestureRecognizer)

        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        // INIT IMAGES PICKER AND GESTURES

        imagePicker.delegate = self

        for imageView in imagesViews {
            let tap = UITapGestureRecognizer(target: self, action: #selector(didTapImageView(_:)))
            imageView.addGestureRecognizer(tap)
        }

        // SET DEFAULT LAYOUT

        selectLayout(defaultLayoutTag)
    }
}

// MANAGING INTERACIONS WITH IMAGE PICKER

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage,
           let imageView = editedImageView
        {
            imageView.contentMode = .scaleAspectFill
            imageView.image = pickedImage
        }

        dismiss(animated: true, completion: nil)
    }
}
