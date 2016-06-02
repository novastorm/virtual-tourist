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
        static let SearchBBoxHalfWidth = 0.1
        static let SearchBBoxHalfHeight = 0.1
        static let SearchLatRange = (-90.0, 90.0)
        static let SearchLonRange = (-180.0, 180.0)
        static let ResponseFormat = "json"
        static let PerPage = 60
        static let SearchRadius = 5
    }
    
    
    // MARK: - Resources
    
    struct Methods {
        struct Photos {
            static let Search = "flickr.photos.search"
        }
        struct Galleries {
            static let GalleryPhotosMethod = "flickr.galleries.getPhotos"
        }
    }
    
    
    
    // MARK: - ParameterKeys
    
    struct ParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let BoundingBox = "bbox"
        static let Extras = "extras"
        static let Format = "format"
        static let GalleryID = "gallery_id"
        static let HasGeo = "has_geo"
        static let Media = "media"
        static let NoJSONCallback = "nojsoncallback"
        static let Page = "page"
        static let PerPage = "per_page"
        static let Radius = "radius"
        static let SafeSearch = "safe_search"
        static let Text = "text"
    }
    
    
    // MARK: - ParameterValues
    
    struct ParameterValues {
        static let APIKey = API.Key
        static let ResponseFormat = Config.ResponseFormat

        static let IsGeoTagged = 1
        static let NotGeoTagged = 0
        static let DisableJSONCallback = "1" /* 1 means "yes" */
        static let GalleryID = "5704-72157622566655097"
        static let MediumURL = "url_m"
        static let UseSafeSearch = "1"
        static let PerPage = Config.PerPage
        static let MediaTypeAll = "all"
        static let MediaTypePhotos = "photos"
        static let MediaTypeVideos = "videos"
    }
    
    // MARK: - ResponseKeys
    struct ResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
    }
    
    // MARK: - Response Values
    struct ResponseValues {
        static let OKStatus = "ok"
    }
    
    // MARK: - Photos Object Keys
    struct Photos {
        static let Photo = "photo"
        static let Pages = "pages"
        static let Total = "total"
    }
    
    // MARK: - Photo Keys
    struct Photo {
        static let Title = "title"
        static let MediumURL = "url_m"
    }
}