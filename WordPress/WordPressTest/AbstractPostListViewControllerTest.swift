//
//  AbstractPostListViewControllerTest.swift
//  WordPressTest
//
//  Created by Maroš Petruš on 23/11/2019.
//  Copyright © 2019 WordPress. All rights reserved.
//

import Foundation
@testable import WordPress

class AbstractPostListViewControllerTest: XCTestCase {
    
    var controller: AbstractPostListViewController?
    
    override func setUp() {
        controller = AbstractPostListViewController()
    }
    
    func testShowNoResultsView() {
        controller?.refreshNoResultsViewController = { refreshVC in
            print("Refreshing...")
        }
        // found a bug = when postListFooterView is not loaded yet, the app crashes
        controller?.setAtLeastSyncedOnce(bool: true)
        controller?.showNoResultsView()
    }
    
    func testShowNoResultsViewNoRefreshed() {
        controller?.refreshNoResultsViewController = { refreshVC in
            print("Refreshing...")
        }
        controller?.showNoResultsView()
    }
}
