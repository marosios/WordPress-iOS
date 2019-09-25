import UIKit
import XCTest
import Nimble

@testable import WordPress

class PostCoordinatorTests: XCTestCase {

    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = TestContextManager().newDerivedContext()
    }

    override func tearDown() {
        super.tearDown()
        context = nil
    }

    func testDoNotUploadAPostWithFailedMedia() {
        let postServiceMock = PostServiceMock()
        let post = PostBuilder(context)
            .with(image: "test.jpeg", status: .failed)
            .with(remoteStatus: .local)
            .build()
        let mediaCoordinatorMock = MediaCoordinatorMock(media: post.media.first!, mediaState: .failed(error: NSError()))
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock, mediaCoordinator: mediaCoordinatorMock)

        postCoordinator.save(post)

        expect(postServiceMock.didCallMarkAsFailedAndDraftIfNeeded).toEventually(beTrue())
        expect(postServiceMock.didCallUploadPost).to(beFalse())
    }

    func testUploadAPostWithNoFailedMedia() {
        let postServiceMock = PostServiceMock()
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)
        let post = PostBuilder(context)
            .with(image: "test.jpeg")
            .build()

        postCoordinator.save(post)

        expect(postServiceMock.didCallUploadPost).to(beTrue())
    }

    func testEventuallyMarkThePostRemoteStatusAsUploading() {
        let postServiceMock = PostServiceMock()
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)
        let post = PostBuilder(context)
            .with(image: "test.jpeg")
            .build()

        postCoordinator.save(post)

        expect(post.remoteStatus).toEventually(equal(.pushing))
    }

    func testAutoSavePost() {
        let postServiceMock = PostServiceMock()
        let failedPostsFetcherMock = FailedPostsFetcherMock(context)
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock, failedPostsFetcher: failedPostsFetcherMock)
        let post = PostBuilder(context)
            .with(status: .draft)
            .build()
        failedPostsFetcherMock.postsAndActions = [post: .autoSave]

        postCoordinator.resume()

        expect(postServiceMock.didCallAutoSave).to(beTrue())
    }
}

private class PostServiceMock: PostService {
    private(set) var didCallUploadPost = false
    private(set) var didCallMarkAsFailedAndDraftIfNeeded = false
    private(set) var didCallAutoSave = false

    override func uploadPost(_ post: AbstractPost, success: ((AbstractPost) -> Void)?, failure: @escaping (Error?) -> Void) {
        didCallUploadPost = true
    }

    override func autoSave(_ post: AbstractPost, success: ((AbstractPost, String) -> Void)?, failure: @escaping (Error?) -> Void) {
        didCallAutoSave = true
    }

    override func markAsFailedAndDraftIfNeeded(post: AbstractPost) {
        didCallMarkAsFailedAndDraftIfNeeded = true
    }
}

private class MediaCoordinatorMock: MediaCoordinator {
    var media: Media
    var mediaState: MediaState

    init(media: Media, mediaState: MediaState) {
        self.media = media
        self.mediaState = mediaState
    }

    override func addObserver(_ onUpdate: @escaping MediaCoordinator.ObserverBlock, for media: Media? = nil) -> UUID {
        return UUID()
    }

    override func addObserver(_ onUpdate: @escaping MediaCoordinator.ObserverBlock, forMediaFor post: AbstractPost) -> UUID {
        onUpdate(self.media, mediaState)
        return UUID()
    }

    override func retryMedia(_ media: Media, automatedRetry: Bool = false, analyticsInfo: MediaAnalyticsInfo? = nil) {
        // noop
    }
}

private class FailedPostsFetcherMock: PostCoordinator.FailedPostsFetcher {
    var postsAndActions: [AbstractPost : PostAutoUploadInteractor.AutoUploadAction] = [:]

    override func postsAndRetryActions(result: @escaping ([AbstractPost : PostAutoUploadInteractor.AutoUploadAction]) -> Void) {
        result(postsAndActions)
    }
}
