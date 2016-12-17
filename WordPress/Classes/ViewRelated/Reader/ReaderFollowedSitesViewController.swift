import Foundation
import WordPressShared
import SVProgressHUD

/// Displays the list of sites a user follows in the Reader.  Provides functionality
/// for following new sites by URL, and unfollowing existing sites via a swipe
/// gesture.  Followed sites can be tapped to browse their posts.
///
class ReaderFollowedSitesViewController: UIViewController, UIViewControllerRestoration
{
    @IBOutlet var searchBar: UISearchBar!

    fileprivate var refreshControl: UIRefreshControl!
    fileprivate var isSyncing = false
    fileprivate var tableView: UITableView!
    fileprivate var tableViewHandler: WPTableViewHandler!
    fileprivate var tableViewController: UITableViewController!

    fileprivate let cellIdentifier = "CellIdentifier"

    lazy var noResultsView: WPNoResultsView = {
        let title = NSLocalizedString("No Sites", comment: "Title of a message explaining that the user is not currently following any blogs in their reader.")
        let message = NSLocalizedString("You are not following any sites yet. Why not follow one now?", comment: "A suggestion to the user that they try following a site in their reader.")
        return WPNoResultsView(title: title, message: message, accessoryView: nil, buttonTitle: nil)
    }()

    lazy var loadingView: WPNoResultsView = {
        let title = NSLocalizedString("Fetching sites...", comment:"A short message to inform the user data for their followed sites is being fetched..")
        return WPNoResultsView(title: title, message: nil, accessoryView: nil, buttonTitle: nil)
    }()


    /// Convenience method for instantiating an instance of ReaderFollowedSitesViewController
    ///
    /// - Returns: An instance of the controller
    ///
    class func controller() -> ReaderFollowedSitesViewController {
        let storyboard = UIStoryboard(name: "Reader", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "ReaderFollowedSitesViewController") as! ReaderFollowedSitesViewController
        return controller
    }


    // MARK: - State Restoration


    static func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        return controller()
    }


    // MARK: - LifeCycle Methods


    override func awakeAfter(using aDecoder: NSCoder) -> Any? {
        restorationClass = type(of: self)

        return super.awakeAfter(using: aDecoder)
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        tableViewController = segue.destination as? UITableViewController
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Manage", comment: "Page title for the screen to manage your list of followed sites.")
        setupTableView()
        setupTableViewHandler()
        configureSearchBar()

        WPStyleGuide.configureColors(for: view, andTableView: tableView)
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        syncSites()
        configureNoResultsView()
    }


    // MARK: - Setup


    fileprivate func setupTableView() {
        assert(tableViewController != nil, "The tableViewController must be assigned before configuring the tableView")

        tableView = tableViewController.tableView

        refreshControl = tableViewController.refreshControl!
        refreshControl.addTarget(self, action: #selector(ReaderStreamViewController.handleRefresh(_:)), for: .valueChanged)
    }


    fileprivate func setupTableViewHandler() {
        assert(tableView != nil, "A tableView must be assigned before configuring a handler")

        tableViewHandler = WPTableViewHandler(tableView: tableView)
        tableViewHandler.delegate = self
    }


    // MARK: - Configuration


    func configureSearchBar() {
        let placeholderText = NSLocalizedString("Enter the URL of a site to follow", comment: "Placeholder text prompting the user to type the name of the URL they would like to follow.")
        let attributes = WPStyleGuide.defaultSearchBarTextAttributes(WPStyleGuide.grey())
        let attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self, ReaderFollowedSitesViewController.self]).attributedPlaceholder = attributedPlaceholder
        let textAttributes = WPStyleGuide.defaultSearchBarTextAttributes(WPStyleGuide.greyDarken30())
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self, ReaderFollowedSitesViewController.self]).defaultTextAttributes = textAttributes

        searchBar.autocapitalizationType = .none
        searchBar.isTranslucent = false
        searchBar.tintColor = WPStyleGuide.grey()
        searchBar.barTintColor = WPStyleGuide.greyLighten30()
        searchBar.backgroundImage = UIImage()
        searchBar.returnKeyType = .done
        searchBar.setImage(UIImage(named: "icon-clear-textfield"), for: .clear, state: UIControlState())
        searchBar.setImage(UIImage(named: "icon-reader-search-plus"), for: .search, state: UIControlState())
    }


    func configureNoResultsView() {
        noResultsView.removeFromSuperview()
        loadingView.removeFromSuperview()
        if let count = tableViewHandler.resultsController.fetchedObjects?.count, count > 0 {
            return
        }

        if (isSyncing) {
            view.addSubview(loadingView)
            loadingView.centerInSuperview()
        } else {
            view.addSubview(noResultsView)
            noResultsView.centerInSuperview()
        }
    }


    // MARK: - Instance Methods


    fileprivate func syncSites() {
        if isSyncing {
            return
        }
        isSyncing = true
        let service = ReaderTopicService(managedObjectContext: managedObjectContext())
        service?.fetchFollowedSites(success: {[weak self] in
            self?.isSyncing = false
            self?.configureNoResultsView()
            self?.refreshControl.endRefreshing()
        }, failure: { [weak self] (error) in
            DDLogSwift.logError("Could not sync sites: \(error)")
            self?.isSyncing = false
            self?.configureNoResultsView()
            self?.refreshControl.endRefreshing()

        })
    }


    func handleRefresh(_ sender: AnyObject) {
        syncSites()
    }


    func refreshFollowedPosts() {
        let service = ReaderSiteService(managedObjectContext: managedObjectContext())
        service?.syncPostsForFollowedSites()
    }


    func unfollowSiteAtIndexPath(_ indexPath: IndexPath) {
        guard let site = tableViewHandler.resultsController.object(at: indexPath) as? ReaderSiteTopic else {
            return
        }

        let service = ReaderTopicService(managedObjectContext: managedObjectContext())
        service?.toggleFollowing(forSite: site, success: { [weak self] in
            self?.syncSites()
            self?.refreshFollowedPosts()
        }, failure: { [weak self] (error) in
            DDLogSwift.logError("Could not unfollow site: \(error)")
            let title = NSLocalizedString("Could not Unfollow Site", comment: "Title of a prompt.")
            let description = error?.localizedDescription
            self?.promptWithTitle(title, message: description!)
        })
    }


    func followSite(_ site: String) {
        guard let url = urlFromString(site) else {
            let title = NSLocalizedString("Please enter a valid URL", comment: "Title of a prompt.")
            promptWithTitle(title, message: "")
            return
        }

        let service = ReaderSiteService(managedObjectContext: managedObjectContext())
        service?.followSite(by: url, success: { [weak self] in
            let success = NSLocalizedString("Followed", comment: "User followed a site.")
            SVProgressHUD.showSuccess(withStatus: success)
            WPNotificationFeedbackGenerator.notificationOccurred(.success)
            self?.syncSites()
            self?.refreshPostsForFollowedTopic()

        }, failure: { [weak self] (error) in
            DDLogSwift.logError("Could not follow site: \(error)")

            WPNotificationFeedbackGenerator.notificationOccurred(.error)

            let title = NSLocalizedString("Could not Follow Site", comment: "Title of a prompt.")
            let description = error?.localizedDescription
            self?.promptWithTitle(title, message: description!)
        })
    }


    func refreshPostsForFollowedTopic() {
        let service = ReaderPostService(managedObjectContext: managedObjectContext())
        service?.refreshPostsForFollowedTopic()
    }


    func urlFromString(_ str: String) -> URL? {
        // if the string contains space its not a URL
        if str.contains(" ") {
            return nil
        }

        // if the string does not have either a dot or protocol its not a URL
        if !str.contains(".") && !str.contains("://")  {
            return nil
        }

        var urlStr = str
        if !urlStr.contains("://") {
            urlStr = "http://\(str)"
        }

        if let url = URL(string: urlStr), url.host != nil {
            return url
        }

        return nil
    }


    func showPostListForSite(_ site: ReaderSiteTopic) {
        let controller = ReaderStreamViewController.controllerWithTopic(site)
        navigationController?.pushViewController(controller, animated: true)
    }


    func promptWithTitle(_ title: String, message: String) {
        let buttonTitle = NSLocalizedString("OK", comment: "Button title. Acknowledges a prompt.")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addCancelActionWithTitle(buttonTitle)
        alert.presentFromRootViewController()
    }
}


extension ReaderFollowedSitesViewController : WPTableViewHandlerDelegate
{

    func managedObjectContext() -> NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }


    func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ReaderSiteTopic")
        fetchRequest.predicate = NSPredicate(format: "following = YES")

        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare))
        fetchRequest.sortDescriptors = [sortDescriptor]

        return fetchRequest
    }


    func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        guard let site = tableViewHandler.resultsController.object(at: indexPath) as? ReaderSiteTopic else {
            return
        }

        cell.accessoryType = .disclosureIndicator
        cell.imageView?.backgroundColor = WPStyleGuide.greyLighten30()

        cell.textLabel?.text = site.title
        cell.detailTextLabel?.text = URL(string: site.siteURL)?.host
        cell.imageView?.setImageWithSiteIcon(site.siteBlavatar, placeholderImage: UIImage(named: "blavatar-default"))


        WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        cell.layoutSubviews()
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? WPTableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)

        configureCell(cell, at: indexPath)
        return cell
    }


    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54.0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let count = tableViewHandler.resultsController.fetchedObjects?.count ?? 0
        if count > 0 {
            return NSLocalizedString("Followed Sites", comment: "Section title for sites the user has followed.")
        }
        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let site = tableViewHandler.resultsController.object(at: indexPath) as? ReaderSiteTopic else {
            return
        }
        showPostListForSite(site)
    }


    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }


    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        unfollowSiteAtIndexPath(indexPath)
    }


    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }


    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return NSLocalizedString("Unfollow", comment: "Label of the table view cell's delete button, when unfollowing a site.")
    }


    func tableViewDidChangeContent(_ tableView: UITableView) {
        configureNoResultsView()

        // If we're not following any sites, reload the table view to ensure the
        // section header is no longer showing.
        if tableViewHandler.resultsController.fetchedObjects?.count == 0 {
            tableView.reloadData()
        }
    }

}


extension ReaderFollowedSitesViewController : UISearchBarDelegate
{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let site =  searchBar.text?.trim(), !site.isEmpty {
            followSite(site)
        }
        searchBar.text = nil
        searchBar.resignFirstResponder()
    }
}
