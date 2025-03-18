//
//  ProfileViewController.swift
//
//  Project: RateMate
//  Course: CS329E
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import CoreData

protocol changeProfilePicture {
    // allows the user to update their profile image
    func changePic(newPicture: UIImage)
}

class ProfileReviewsCollectionViewCell: UICollectionViewCell {
    // class that contains all items in the cells for the collection view
    @IBOutlet weak var profileRatingsLabel: UILabel!
    @IBOutlet weak var profileReviewsTextView: UITextView!
    @IBOutlet weak var profileReviewAuthor: UILabel!
}

class ProfileViewController: UIViewController, UITextViewDelegate, UICollectionViewDelegate,
                             UICollectionViewDataSource, changeProfilePicture {

    @IBOutlet weak var overallRatingLabel: UILabel!
    @IBOutlet weak var aboutMeLabel: UILabel!
    @IBOutlet weak var profileReviewCollectionView: UICollectionView!
    @IBOutlet weak var changePhotoButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var reviewsLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var editBioButton: UIButton!
    @IBOutlet weak var saveChangesButton: UIButton!
    @IBOutlet weak var aboutMeTextView: UITextView!
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    @IBOutlet weak var profilePictureView: UIImageView!
    
    // stores all the reviews for the current user in an array from Firestore
    var personalReviews : [Review] = []
    let characterLimit = 100        // character limit for the bio
    let profileReviewsCellIdentifier = "profileReviewsCellIdentifier"
    let pfpSegue = "changeProfilePictureSegue"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // makes the profile picture round
        profilePictureView.layer.cornerRadius = profilePictureView.frame.size.width / 2
        profilePictureView.layer.masksToBounds = true
        
        // makes the change profile picture button round when edit mode is on
        changePhotoButton.layer.cornerRadius = changePhotoButton.frame.size.width / 2
        changePhotoButton.layer.masksToBounds = true
        
        // hides the edit fields when not editing
        aboutMeTextView.isEditable = false
        aboutMeTextView.isSelectable = false
        aboutMeTextView.isScrollEnabled = false
        changePhotoButton.isHidden = true
        saveChangesButton.isHidden = true
        
        aboutMeTextView.delegate = self
        profileReviewCollectionView.dataSource = self
        profileReviewCollectionView.delegate = self
        
        fetchUserData()         // sets the user's name, bio, and reviews/rating
        uploadCoreData()        // uploads the user's saved settings on color and view mode as well as their pfp
 
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
        update()
        view.backgroundColor = ThemeManager.shared.backgroundColor
        ThemeManager.shared.updateTheme = { [weak self] _ in
            self?.applyTheme()
        }
    }
    
    func applyTheme() {
        // for color theme purposes
        editBioButton.tintColor = ThemeManager.shared.secondaryColor
        saveChangesButton.tintColor = ThemeManager.shared.secondaryColor
        changePhotoButton.tintColor = ThemeManager.shared.primaryColor
        settingsButton.tintColor = ThemeManager.shared.primaryColor
        aboutMeTextView.backgroundColor = ThemeManager.shared.primaryColor.withAlphaComponent(0.25)
        profileReviewCollectionView.reloadData()
        
        // for dark mode purposes
        nameLabel.textColor = ThemeManager.shared.textColors
        reviewsLabel.textColor = ThemeManager.shared.textColors
        ratingLabel.textColor = ThemeManager.shared.textColors
        aboutMeLabel.textColor = ThemeManager.shared.textColors
        profileReviewCollectionView.backgroundColor = ThemeManager.shared.backgroundColor
        aboutMeTextView.textColor = ThemeManager.shared.textColors
        overallRatingLabel.textColor = ThemeManager.shared.textColors
        view.backgroundColor = ThemeManager.shared.backgroundColor
        
        if let tabBar = tabBarController?.tabBar {
            tabBar.tintColor = ThemeManager.shared.primaryColor
            tabBar.backgroundColor = ThemeManager.shared.backgroundColor
          }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // segues into the profile picture changing segue
        if segue.identifier == pfpSegue,
           let destination = segue.destination as? ChangePictureViewController {
            destination.delegate = self
            destination.passedImage = profilePictureView.image
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // number of items in the collection view
        return personalReviews.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: profileReviewsCellIdentifier, for: indexPath) as? ProfileReviewsCollectionViewCell
        else {
            // ensures cells are of the type ProfileReviewsCollectionViewCell
            fatalError("Cell is not of type ProfileReviewsCollectionViewCell")
        }
        // Get the review for the current index path
        let review = personalReviews[indexPath.item]
        // updates the cell appearance based on settings
        cell.backgroundColor = ThemeManager.shared.primaryColor
        cell.profileReviewsTextView.backgroundColor = ThemeManager.shared.secondaryColor
        cell.profileReviewsTextView.textColor = ThemeManager.shared.tertiaryColor
        cell.profileReviewAuthor.textColor = ThemeManager.shared.tertiaryColor
        cell.profileRatingsLabel.textColor = ThemeManager.shared.tertiaryColor
        
        // configures the cells based on the reviews
        cell.profileReviewsTextView.text = review.reviewText
        cell.profileRatingsLabel.text = "Rating: \(review.rating)"
        
        if review.isAnonymous{
            cell.profileReviewAuthor.text = "by: anonymous"
        }
        else {
            cell.profileReviewAuthor.text = "by: \(review.submitterName)"
        }
        
        return cell
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // sets a character limit on the bio
        let currentText = textView.text ?? ""
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)
        
        // Check if the updated text exceeds the character limit
        return updatedText.count <= characterLimit
    }
    
    func uploadCoreData() {
        // uploads the user's profile picture to core data
        let fetchedResult = retrieveUser()
        for user in fetchedResult {
            let profilePicture = user.value(forKey: "profileImage") as! Data?
            // converts the picture from binary to UIImage
            profilePictureView.image = convertDataToImage(data: profilePicture!)
        }
        // fills the circle icon
        profilePictureView.contentMode = .scaleAspectFill
        
        // uploads the color theme for every login
        let currentColorMode = UserDefaults.standard.string(forKey: "colorTheme") ?? "orange"   // default is orange for UT students
        let settingsVC = SettingsViewController()
        
        if currentColorMode == "red" {
            settingsVC.redThemeButtonPressed(UIButton.self)
        }
        else if currentColorMode == "orange" {
            settingsVC.orangeThemeButtonPressed(UIButton.self)
        }
        else if currentColorMode == "yellow" {
            settingsVC.yellowThemeButtonPressed(UIButton.self)
        }
        else if currentColorMode == "green" {
            settingsVC.greenThemeButtonPressed(UIButton.self)
        }
        else if currentColorMode == "blue" {
            settingsVC.blueThemeButtonPressed(UIButton.self)
        }
        else if currentColorMode == "indigo" {
            settingsVC.indigoThemeButtonPressed(UIButton.self)
        }
        else if currentColorMode == "purple" {
            settingsVC.purpleThemeButtonPressed(UIButton.self)
        }
        else if currentColorMode == "pink" {
            settingsVC.pinkThemeButtonPressed(UIButton.self)
        }
        
        // uploads the view mode every login
        let currentSwitchState = UserDefaults.standard.bool(forKey: "themeSwitchState")
        
        if currentSwitchState {
            ThemeManager.shared.backgroundColor = .black
            ThemeManager.shared.textColors = .white
        }
        else if !currentSwitchState{
            ThemeManager.shared.backgroundColor = .white
            ThemeManager.shared.textColors = .black
        }
    }
    
    func retrieveUser() -> [NSManagedObject] {
        // retrieves all the user attributes in core data by the UID
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        var fetchedResult: [NSManagedObject]?
        
        // grabs the user by their unique identifier
        if let currentUser = Auth.auth().currentUser {
            let uid = currentUser.uid
            let predicate = NSPredicate(format: "uuid == %@", uid)
            request.predicate = predicate
        } else {
            print("No user is signed in.")
        }
        
        // tries to fetch the user
        do {
            try fetchedResult = context.fetch(request) as? [NSManagedObject]
        } catch {
            print("Error occurred while retrieving data")
            abort()
        }
        return fetchedResult!
    }
    
    func fetchUserData() {
        // fetches the text data saved into firestore
        let db = Firestore.firestore()
        if let currentUser = Auth.auth().currentUser {      // gets the user's UID
            let uid = currentUser.uid
            // accesses the user collection and attempts to go into the uid documents
            let userRef = db.collection("users").document(uid)
            
            // fetches the details for the user by their uid
            userRef.getDocument { document, error in
                if let error = error {
                    print("Error fetching user details: \(error)")
                    return
                }
                // checks to see if the document exists
                guard let document = document, document.exists else {
                    print("User document does not exist")
                    return
                }
                // retrieves the user's name and their bio
                let data = document.data()
                let firstName = data?["firstName"] as? String ?? "N/A"
                let lastName = data?["lastName"] as? String ?? "N/A"
                let bio = data?["bio"] as? String ?? "N/A"
                
                // uploads them to the story board
                self.nameLabel.text = "\(firstName) \(lastName)"
                self.aboutMeTextView.text = "\(bio)"
            }
        }
    }
    
    func fetchReviews() {
        let db = Firestore.firestore()
        if let currentUser = Auth.auth().currentUser {       // gets the user's UID
            let uid = currentUser.uid

        // accesses the user's collection and their docs by their UID
        let userDocRef = db.collection("users").document(uid)
            userDocRef.getDocument { (document, error) in
                if let error = error {
                    print("Error fetching document: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists else {
                    print("Document does not exist")
                    return
                }
                // accesses the reviews field and the array
                if let reviewsData = document.data()?["reviews"] as? [[String: Any]] {
                    for reviewData in reviewsData {
                        // goes through a for loop to extract each review object
                        let review = Review(
                            reviewText: reviewData["reviewText"] as? String ?? "",
                            rating: reviewData["rating"] as? Int ?? 0,
                            isAnonymous: reviewData["isAnonymous"] as? Bool ?? false,
                            submitterUid: reviewData["submitterUid"] as? String ?? "",
                            submitterName: reviewData["submitterName"] as? String ?? "",
                            reviewID: reviewData["reviewID"] as? String ?? "")
                        
                        self.personalReviews.append(review)     // appends it to the array in the Profile VC Class
                    }
                    
                    self.profileReviewCollectionView.reloadData()                           // updates the collection view
                    self.reviewsLabel.text = "Reviews (\(self.personalReviews.count))"      // updates the review count
                    self.ratingLabel.text = "\(self.averageRating()) / 5"                   // updates the rating
                    
                    // makes it so that new reviews appear at the top of the collection view
                    self.personalReviews = self.personalReviews.reversed()
                    
                } else {
                    print("No reviews found")
                }
            }
        }
    }
    
    func changePic(newPicture: UIImage) {
        // changes the profile picture based on the new one chosen or taken and uploads it to core data
        profilePictureView.image = newPicture
        profilePictureView.contentMode = .scaleAspectFill
        
        if let currentUser = Auth.auth().currentUser {
            let uid = currentUser.uid
            // saves to the current user's Core Data
            saveUserProfileToCoreData(profilePicture: profilePictureView.image!, uid: uid)
        }
    }
    
    func saveUserProfileToCoreData(profilePicture: UIImage, uid: String) {
        // attempts to save the new picture into Core Data after converting the file to binary data
        let userObject = NSEntityDescription.insertNewObject(forEntityName: "User", into: context)
        userObject.setValue(uid, forKey: "uuid")
        userObject.setValue(convertImageToData(image: profilePicture), forKey: "profileImage")
        saveContext()
    }
        
    func saveContext () {
        // saves Core Data
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func convertImageToData(image: UIImage) -> Data? {
        // Converts a UIImage to Binary Data
        guard let imageData = image.pngData()
        else {
            print("Failed to convert image to data")
            return nil
        }
        return imageData
    }
    
    func convertDataToImage(data: Data) -> UIImage? {
        // Converts Binary Data back to UIImage
        guard let image = UIImage(data: data)
        else {
            print("Failed to convert data back to UIImage")
            return nil
        }
        return image
    }
    
    func averageRating() -> String {
        var cumulativeScore = 0
        var average = ""
        // sums up the scores of all the reviews
        for review in personalReviews {
            cumulativeScore += review.rating
        }
        // takes the average of it and returns a float
        let floatAverage = Float(cumulativeScore) / Float(personalReviews.count)
       
        // if the user has no reviews the score won't be 0
        if personalReviews.count == 0 {
            average = "N/A"
        } else {
            // sets the score to one decimal place
            average = String(format: "%.1f", floatAverage)
        }
        return average
    }
    
    func update() {
        // updates the reviews and reloads the collection view when called
        personalReviews.removeAll()
        fetchReviews()
        profileReviewCollectionView.reloadData()
    }
    
    @IBAction func saveChangesButtonPressed(_ sender: Any) {
        // updates the bio and disables editing
        aboutMeTextView.layer.borderWidth = 0.0     // removes the border to indicate editing mode is off
        saveChangesButton.isHidden = true
        editBioButton.isHidden = false
        aboutMeTextView.isEditable = false
        changePhotoButton.isHidden = true
        settingsButton.isEnabled = true             // re-enables the settings button
        
        // saves the new bio data into firebase firestore
        if let currentUser = Auth.auth().currentUser {
            let uid = currentUser.uid
            let db = Firestore.firestore()
            let bio = aboutMeTextView.text!
            
            // updates the bio field
            db.collection("users").document(uid).setData(["bio": bio], merge: true) { error in
                if let error = error {
                    print("Error uploading bio: \(error.localizedDescription)")
                } else {
                    // I didn't want to bombard the user with two consecutive alerts in a row
                    // in the case that they wanted to change their pfps too
                    print("Profile saved successfully")
                }
            }
        }
    }
    
    @IBAction func editBioButtonPressed(_ sender: Any) {
        // allows the user to edit their bio
        aboutMeTextView.layer.borderWidth = 0.5     // adds a border to indicate editing mode is on
        aboutMeTextView.layer.borderColor = UIColor.lightGray.cgColor
        settingsButton.isEnabled = false            // disables the settings button until editing is done
        editBioButton.isHidden = true
        changePhotoButton.isHidden = false
        saveChangesButton.isHidden = false
        aboutMeTextView.isEditable = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // dismisses the keyboard when the use touches anywhere outside the keyboard
        self.view.endEditing(true)
    }
}
