//
//  GCDUtilities.swift
//  Virtual Tourist
//
//  Created by Adland Lee on 5/12/16.
//  Copyright © 2016 Adland Lee. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
