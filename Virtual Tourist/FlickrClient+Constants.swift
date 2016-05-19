//
//  FlickrClient+Constants.swift
//  Virtual Tourist
//
//  Created by Adland Lee on 5/18/16.
//  Copyright © 2016 Adland Lee. All rights reserved.
//

extension FlickrClient {
    
    // MARK: API
    
    struct API {
        static let Key = "6623dc3039aaa921037bf3ea4d50d66e"
        static let Scheme = "https"
        static let Host = "api.flickr.com"
        static let Path = "/services/rest"
    }
    
    // MARK: - Config
    
    struct Config {
        static let SearchBBoxHalfWidth = 1.0
        static let SearchBBoxHalfHeight = 1.0
        static let SearchLatRange = (-90.0, 90.0)
        static let SearchLonRange = (-180.0, 180.0)
        static let ResponseFormat = "json"
    }
    
    
    // MARK: - Resources
    
    struct Methods {
        struct Photos {
            static let Search = "flickr.photos.search"
        }
    }
    
    
    
    // MARK: - ParameterKeys
    
    struct ParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let GalleryID = "gallery_id"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let SafeSearch = "safe_search"
        static let Text = "text"
        static let BoundingBox = "bbox"
        static let Page = "page"
    }
    
    
    // MARK: - ParameterValues
    
    struct ParameterValues {
//        static let SearchMethod = "flickr.photos.search"
        static let APIKey = API.Key
        static let ResponseFormat = Config.ResponseFormat
        static let DisableJSONCallback = "1" /* 1 means "yes" */
        static let GalleryPhotosMethod = "flickr.galleries.getPhotos"
        static let GalleryID = "5704-72157622566655097"
        static let MediumURL = "url_m"
        static let UseSafeSearch = "1"
    }
    
    // MARK: - ResponseKeys
    struct ResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let MediumURL = "url_m"
        static let Pages = "pages"
        static let Total = "total"
    }
    
    // MARK: - Response Values
    struct ResponseValues {
        static let OKStatus = "ok"
    }

}