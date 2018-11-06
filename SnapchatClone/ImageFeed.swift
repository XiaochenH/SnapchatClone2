//
//  imageFeed.swift
//  SnapchatProject
//
//  Created by Akilesh Bapu on 2/27/17.
//  Copyright © 2017 org.iosdecal. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseStorage

var threads: [String: [Post]] = ["Memes": [], "Dog Spots": [], "Random": []]


let threadNames = ["Memes", "Dog Spots", "Random"]

var allImages: [UIImage] = [#imageLiteral(resourceName: "cutePuppy"), #imageLiteral(resourceName: "berkAtNight"), #imageLiteral(resourceName: "meme1"), #imageLiteral(resourceName: "Campanile"), #imageLiteral(resourceName: "meme2"), #imageLiteral(resourceName: "dankMeme2"), #imageLiteral(resourceName: "amazingCutePuppy"), #imageLiteral(resourceName: "cutePuppy"), #imageLiteral(resourceName: "dirks"), #imageLiteral(resourceName: "dankMeme3")]


func getPostFromIndexPath(indexPath: IndexPath) -> Post? {
    let sectionName = threadNames[indexPath.section]
    if let postsArray = threads[sectionName] {
        return postsArray[indexPath.row]
    }
    print("No post at index \(indexPath.row)")
    return nil
}

/// Adds the given post to the thread associated with it
/// (the thread is set as an instance variable of the post)
///
/// - Parameter post: The post to be added to the model
func addPostToThread(post: Post) {
    threads[post.thread]?.append(post)
}

func clearThreads() {
    threads = ["Memes": [], "Dog Spots": [], "Random": []]
}

func addPost(postImage: UIImage, thread: String, username: String) {
    let dbRef = Database.database().reference()
    let data = UIImageJPEGRepresentation(postImage, 1.0)
    let path = "Images/\(UUID().uuidString)"

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.A"
    let dateString = dateFormatter.string(from: Date())
    let postDict: [String:AnyObject] = ["imagePath": path as AnyObject,
                                        "username": username as AnyObject,
                                        "thread": thread as AnyObject,
                                        "date": dateString as AnyObject]
    dbRef.child(firPostsNode).childByAutoId().setValue(postDict)
    store(data: data, toPath: firStorageImagesPath)
}

func store(data: Data?, toPath path: String) {
    let storageRef = Storage.storage().reference()
    storageRef.child(path).putData(data!, metadata: nil) { (metadata, error) in
        if let error = error {
            print(error)
        }
    }
}




/*
 TODO:
 
 This function should query Firebase for all posts and return an array of Post objects.
 You should use the function 'observeSingleEvent' (with the 'of' parameter set to .value) to get a snapshot of all of the nodes under "Posts".
 If the snapshot exists, store its value as a dictionary of type [String:AnyObject], where the string key corresponds to the ID of each post.
 
 Then, make a query for the user's read posts ID's. In the completion handler, complete the following:
 - Iterate through each of the keys in the dictionary
 - For each key:
 - Create a new Post object, where Posts take in a key, username, imagepath, thread, date string, and read property. For the read property, you should set it to true if the key is contained in the user's read posts ID's and false otherwise.
 - Append the new post object to the post array.
 - Finally, call completion(postArray) to return all of the posts.
 - If any part of the function fails at any point (e.g. snapshot does not exist or snapshot.value is nil), call completion(nil).
 
 Remember to use constants defined in Strings.swift to refer to the correct path!
 */
func getPosts(user: CurrentUser, completion: @escaping ([Post]?) -> Void) {
    let dbRef = Database.database().reference()
    var postArray: [Post] = []
    dbRef.child(firPostsNode).observeSingleEvent(of: .value, with: { snapshot -> Void in
        if snapshot.exists() {
            if let posts = snapshot.value as? [String:AnyObject] {
                user.getReadPostIDs(completion: { (ids) in
                    for postKey in posts.keys {
                        let post_dict = posts[postKey] as! [String: String]
                        let new_post = Post(id: postKey, username: post_dict["username"]!, postImagePath: post_dict["imagePath"]!, thread: post_dict["thread"]!, dateString: post_dict["date"]!, read: true)
                        postArray.append(new_post)
                    }
                    completion(postArray)
                })
            } else {
                completion(nil)
            }
        } else {
            completion(nil)
        }
    })
}

func getDataFromPath(path: String, completion: @escaping (Data?) -> Void) {
    let storageRef = Storage.storage().reference()
    storageRef.child(path).getData(maxSize: 5 * 1024 * 1024) { (data, error) in
        if let error = error {
            print(error)
        }
        if let data = data {
            completion(data)
        } else {
            completion(nil)
        }
    }
}

