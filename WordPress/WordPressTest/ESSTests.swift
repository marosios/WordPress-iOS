//
//  ESSTests.swift
//  WordPressTest
//
//  Created by Maroš Petruš on 30/11/2019.
//  Copyright © 2019 WordPress. All rights reserved.
//

import Foundation
@testable import WordPress
@testable import Aztec

class ESSTests: XCTestCase {
    
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
    
    func testGenerateTitle() {
        let post = PostBuilder().with(pathForDisplayImage: "https://wp.me/awesome.png").build()
        let title = "This is the test title from which the keywords should be generated."
        let generatedTitle = post.generateTitle(from: title)
        XCTAssertEqual(title, generatedTitle)
    }
    
    func testGenerateTitleWithStatus() {
        let post = PostBuilder().with(pathForDisplayImage: "https://wp.me/awesome.png").build()
        let title = "This is the test title from which the keywords should be generated."
        post.status = .scheduled
        let titleWithStatus = "[Scheduled] \(title)"
        let generatedTitleWithStatus = post.generateTitle(from: title)
        XCTAssertEqual(titleWithStatus, generatedTitleWithStatus)
    }
    
    func testSearchDomain() {
        let post = PostBuilder().with(pathForDisplayImage: "https://wp.me/awesome.png").build()
        let blog = Blog()
        blog.url = "https://example.com"
        blog.xmlrpc = "https://example.com/xmlrpc.php"
        post.blog = blog
        XCTAssertEqual(post.searchDomain, "https://example.com/xmlrpc.php")
    }
    
    func testIsLocalRevision() {
        let post = PostBuilder().with(pathForDisplayImage: "https://wp.me/awesome.png").build()
        let isLocalRevision = post.isLocalRevision
        XCTAssertEqual(isLocalRevision, false)
    }
    
    func testRangeContainsRange() {
        var range = NSRange(location: 0, length: 10)
        var rangeToCompare = NSRange(location: 3, length: 4)
        XCTAssertEqual(range.contains(rangeToCompare), true)
        
        range = NSRange(location: 0, length: 10)
        rangeToCompare = NSRange(location: 5, length: 10)
        XCTAssertEqual(range.contains(rangeToCompare), false)
    }
    
    func testRangeIntersect() {
        let range = NSRange(location: 5, length: 100)
        
        var rangeToCompare = NSRange(location: 6, length: 10)
        XCTAssertEqual(range.intersect(withRange: rangeToCompare), rangeToCompare)
        
        rangeToCompare = NSRange(location: 4, length: 100)
        XCTAssertEqual(range.intersect(withRange: rangeToCompare), NSRange(location: 5, length: 99))
        
        rangeToCompare = NSRange(location: 5, length: 101)
        XCTAssertEqual(range.intersect(withRange: rangeToCompare), NSRange(location: 5, length: 100))
        
        rangeToCompare = NSRange(location: 4, length: 102)
        XCTAssertEqual(range.intersect(withRange: rangeToCompare), range)
        
        rangeToCompare = NSRange(location: 1000, length: 10)
        XCTAssertEqual(range.intersect(withRange: rangeToCompare), nil)
    }
    
    func testRangeExtendedRight() {
        let range = NSRange(location: 5, length: 100)
        let extendedRange = NSRange(location: 5, length: 110)
        XCTAssertEqual(range.extendedRight(by: 10), extendedRange)
    }
    
//    ==========================================
    
    func testFeaturedImageURLForDisplay() {
        let post = PostBuilder().with(pathForDisplayImage: "https://wp.me/awesome.png").build()

        XCTAssertEqual(post.featuredImageURLForDisplay()?.absoluteString, "https://wp.me/awesome.png")
    }

    func testGenerateKeywordsFromContent() {
        let post = PostBuilder().with(pathForDisplayImage: "https://wp.me/awesome.png").build()
        post.content = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean vitae risus sagittis, mattis risus bibendum, venenatis eros. Integer et leo mi. Donec sed auctor sem. Fusce consequat mauris nulla, ac vestibulum mi rutrum quis. Pellentesque gravida facilisis erat, non cursus purus iaculis non. Aenean dictum neque id ante venenatis rutrum. Duis vitae purus ac lorem maximus malesuada. Mauris nec venenatis sem, quis volutpat turpis. Cras a purus in purus suscipit porttitor. Integer facilisis dui ut sem lobortis, ut fringilla risus condimentum. Sed pulvinar mattis odio, eget scelerisque ligula laoreet vel. Proin sit amet elit eleifend risus porttitor viverra. Nullam tortor turpis, tincidunt in convallis a, auctor sit amet ex. Quisque aliquam lacus sit amet ipsum varius maximus. Vivamus vulputate malesuada aliquam. Quisque blandit urna et eros lacinia, nec placerat turpis feugiat. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Vivamus quis felis non elit aliquet interdum sit amet id eros. Duis eu orci eros. In elementum gravida elit sit amet sagittis. Donec quis varius nibh, id laoreet odio. Nullam sed suscipit risus, congue auctor libero. Sed ipsum mi, dictum nec tortor et, rhoncus elementum risus. Mauris feugiat vitae dui ut iaculis. Ut tortor dui, suscipit nec felis ut, venenatis pulvinar risus. In vitae lorem sem. Integer vel neque id mi sagittis dictum. Proin sagittis risus at dolor facilisis vestibulum. Curabitur malesuada nisi eu nulla suscipit, et feugiat leo tempor. Aenean dictum, neque ut dapibus suscipit, ex arcu porttitor turpis, aliquam sollicitudin nisl arcu sed velit. Aenean sagittis, enim sed hendrerit pretium, sapien velit molestie justo, sed facilisis elit orci non eros. Cras felis ante, fermentum id vestibulum sed, mollis sit amet purus. Phasellus ultrices lacus ut sem blandit, ac aliquam tellus lacinia. Nullam feugiat tortor sed lacinia iaculis. Fusce aliquet tellus vel ante pretium, in condimentum lorem vestibulum. Curabitur ut fringilla mauris. Sed eget odio urna. In nec interdum est, id euismod lacus. Curabitur commodo dui orci, eu iaculis nunc porta nec. Morbi eleifend, leo quis volutpat tristique, orci erat ultrices nisl, interdum pulvinar mi ligula quis urna. Nunc imperdiet, quam sed dictum pharetra, dolor nunc rutrum est, vitae sagittis magna risus in sapien. Aenean lacus nunc, fermentum sagittis arcu nec, malesuada fermentum neque. Donec ipsum tellus, ultrices in dictum et, sollicitudin sed tortor. Nulla eu justo at urna hendrerit convallis eget in libero. Vivamus faucibus magna a tellus sollicitudin sollicitudin. Sed eu ipsum ligula. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Praesent vitae tortor a tellus convallis porta."
        let contentKeywords = ["Lorem", "ipsum", "dolor", "sit", "amet,", "consectetur", "adipiscing", "elit.", "Aenean", "vitae", "risus", "sagittis,", "mattis", "risus", "bibendum,", "venenatis", "eros.", "Integer", "et", "leo", "mi.", "Donec…"]
        let generatedContentKeywords = post.generateKeywordsFromContent()
        XCTAssertEqual(contentKeywords, generatedContentKeywords)
    }

    func testGenerateKeywordsFromTitle() {
        let post = PostBuilder().with(pathForDisplayImage: "https://wp.me/awesome.png").build()
        post.postTitle = "This is the test title from which the keywords should be generated."
        let titleKeywords = ["This", "is", "the", "test", "title", "from", "which", "the", "keywords", "should", "be", "generated."]
        let generatedTitleKeywords = post.generateKeywordsFromContent()
        XCTAssertEqual(titleKeywords, generatedTitleKeywords)
    }
    
    func testRangeContainsOffet() {
        let range = NSRange(location: 0, length: 10)
        XCTAssertEqual(range.contains(offset: 5), true)
        
        XCTAssertEqual(range.contains(offset: 20), false)
    }
    
    func testRangeEndLocation() {
        let range = NSRange(location: 4, length: 20)
        XCTAssertEqual(range.endLocation, 24)
    }
    
    func testRangeOffset() {
        let range = NSRange(location: 5, length: 100)
        let offset = 5
        let offsetRange = NSRange(location: 10, length: 100)
        XCTAssertEqual(offsetRange, range.offset(by: offset))
    }
    
    func testRangeShortenedLeft() {
        let range = NSRange(location: 5, length: 100)
        let shortenedRange = NSRange(location: 15, length: 90)
        XCTAssertEqual(shortenedRange, range.shortenedLeft(by: 10))
    }
    
    func testRangeShortenedRight() {
        let range = NSRange(location: 5, length: 100)
        let shortenedRange = NSRange(location: 5, length: 90)
        XCTAssertEqual(shortenedRange, range.shortenedRight(by: 10))
    }
    
    func testRangeUnion() {
        let range = NSRange(location: 5, length: 100)
        let rangeToUnion = NSRange(location: 0, length: 100)
        XCTAssertEqual(range.union(rangeToUnion), NSUnionRange(range, rangeToUnion))
    }
}
