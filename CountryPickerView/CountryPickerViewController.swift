//
//  CountryPickerViewController.swift
//  CountryPickerView
//
//  Created by Kizito Nwose on 18/09/2017.
//  Copyright © 2017 Kizito Nwose. All rights reserved.
//

import UIKit

public class CountryPickerViewController: UITableViewController {

    let searchController = UISearchController(searchResultsController: nil)
    fileprivate var searchResults = [Country]()
    fileprivate var isSearchMode = false
    fileprivate var sectionsTitles = [String]()
    fileprivate var countries = [String: [Country]]()
    fileprivate var hasPreferredSection: Bool {
        return dataSource.preferredCountriesSectionTitle != nil &&
            dataSource.preferredCountries.count > 0
    }
    fileprivate var showOnlyPreferredSection: Bool {
        return dataSource.showOnlyPreferredSection
    }
    
    internal weak var countryPickerView: CountryPickerView! {
        didSet {
            dataSource = CountryPickerViewDataSourceInternal(view: countryPickerView)
        }
    }
    
    fileprivate var dataSource: CountryPickerViewDataSourceInternal!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = UIColor(red: 239.0/255.0, green: 239.0/255.0, blue: 244.0/255.0,
                                                 alpha: 1)
        self.tableView.tableFooterView = UIView()
        self.tableView.keyboardDismissMode = .interactive
        prepareTableItems()
        prepareNavItem()
        prepareSearchBar()
    }
   
}

// UI Setup
extension CountryPickerViewController {
    
    func prepareTableItems()  {
        if !showOnlyPreferredSection {
            let countriesArray = countryPickerView.countries()
            
            var groupedData = Dictionary<String, [Country]>(grouping: countriesArray) {
                let name = $0.localizedName ?? $0.name
                return String(name.capitalized[name.startIndex])
            }
            groupedData.forEach{ key, value in
                groupedData[key] = value.sorted(by: { (lhs, rhs) -> Bool in
                    return lhs.name < rhs.name
                })
            }
            
            countries = groupedData
            sectionsTitles = groupedData.keys.sorted()
        }
        
        // Add preferred section if data is available
        if hasPreferredSection, let preferredTitle = dataSource.preferredCountriesSectionTitle {
            sectionsTitles.insert(preferredTitle, at: sectionsTitles.startIndex)
            countries[preferredTitle] = dataSource.preferredCountries
        }
        
        tableView.sectionIndexBackgroundColor = .clear
        tableView.sectionIndexTrackingBackgroundColor = .clear
    }
    
    func prepareNavItem() {
        navigationItem.title = dataSource.navigationTitle

        // Add a close button if this is the root view controller
        if navigationController?.viewControllers.count == 1 {
            let closeButton = dataSource.closeButtonNavigationItem
            closeButton.target = self
            closeButton.action = #selector(close)
            navigationItem.leftBarButtonItem = closeButton
        }
    }
    
    func prepareSearchBar() {
        let searchBarPosition = dataSource.searchBarPosition
        if searchBarPosition == .hidden  {
            return
        }
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = searchBarPosition == .tableViewHeader
        searchController.definesPresentationContext = true
        searchController.searchBar.delegate = self

        switch searchBarPosition {
        case .tableViewHeader: tableView.tableHeaderView = searchController.searchBar
        case .navigationBar:
            if #available(iOS 11.0, *) {
                navigationItem.searchController = searchController
            } else {
                navigationItem.titleView = searchController.searchBar
            }
        default: break
        }
    }
    
    @objc private func close() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}

//MARK:- UITableViewDataSource
extension CountryPickerViewController {
    
    override public func numberOfSections(in tableView: UITableView) -> Int {
        return isSearchMode ? 1 : sectionsTitles.count
    }
    
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearchMode ? searchResults.count : countries[sectionsTitles[section]]!.count + 1
    }
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = String(describing: CountryTableViewCell.self)

        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? CountryTableViewCell
            ?? CountryTableViewCell(style: .default, reuseIdentifier: identifier)
        var index = indexPath.row
        if !isSearchMode && index == 0 {
            cell.imageView?.image = nil
            cell.textLabel?.text = " " + sectionsTitles[indexPath.section]
            cell.textLabel?.font = dataSource.cellLabelFont
            if let color = dataSource.cellLabelColor {
                cell.textLabel?.textColor = color
            }
            cell.accessoryType = .none
            cell.separatorInset = .zero
            cell.backgroundColor = .clear
        } else {
            index -= 1
            cell.backgroundColor = UIColor.white
            let country = isSearchMode ? searchResults[indexPath.row]
                : countries[sectionsTitles[indexPath.section]]![index]
            
            let countryName = country.localizedName ?? country.name
            let name = dataSource.showPhoneCodeInList ? "\(countryName) (\(country.phoneCode))" : countryName
            cell.imageView?.image = country.flag
            
            cell.flgSize = dataSource.cellImageViewSize
            cell.imageView?.clipsToBounds = true
            
            cell.imageView?.layer.cornerRadius = dataSource.cellImageViewCornerRadius
            cell.imageView?.layer.masksToBounds = true
            
            cell.textLabel?.text = name
            cell.textLabel?.font = dataSource.cellLabelFont
            if let color = dataSource.cellLabelColor {
                cell.textLabel?.textColor = color
            }
            var accessoryType: UITableViewCell.AccessoryType = .none
            if let selectedCountry = countryPickerView.selectedCountry,
                country == selectedCountry {
                accessoryType = .checkmark
            }
            cell.accessoryType = accessoryType
            cell.separatorInset = .zero
        }

        return cell
    }
    
    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
//        return isSearchMode ? nil : sectionsTitles[section]
    }
    
    override public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if isSearchMode {
            return nil
        } else {
            if hasPreferredSection {
                return Array<String>(sectionsTitles.dropFirst())
            }
            return sectionsTitles
        }
    }
    
    override public func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return sectionsTitles.firstIndex(of: title)!
    }
}

//MARK:- UITableViewDelegate
extension CountryPickerViewController {

    override public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.font = dataSource.sectionTitleLabelFont
            if let color = dataSource.sectionTitleLabelColor {
                header.textLabel?.textColor = color
            }
        }
    }
    
    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var index = indexPath.row
        if !isSearchMode , index == 0 {
            return
        }
        index -= 1
        let country = isSearchMode ? searchResults[indexPath.row]
            : countries[sectionsTitles[indexPath.section]]![index]

        if dataSource.searchBarPosition != .hidden  {
            searchController.dismiss(animated: false, completion: nil)
        }
        
        let completion = {
            self.countryPickerView.selectedCountry = country
            self.countryPickerView.delegate?.countryPickerView(self.countryPickerView, didSelectCountry: country)
        }
        // If this is root, dismiss, else pop
        if navigationController?.viewControllers.count == 1 {
            navigationController?.dismiss(animated: true, completion: completion)
        } else {
            navigationController?.popViewController(animated: true, completion: completion)
        }
    }
}

// MARK:- UISearchResultsUpdating
extension CountryPickerViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        isSearchMode = false
        if let text = searchController.searchBar.text, text.count > 0 {
            isSearchMode = true
            searchResults.removeAll()
            
            var indexArray = [Country]()
            
            if showOnlyPreferredSection && hasPreferredSection,
                let array = countries[dataSource.preferredCountriesSectionTitle!] {
                indexArray = array
            } else if let array = countries[String(text.capitalized[text.startIndex])] {
                indexArray = array
            }

            searchResults.append(contentsOf: indexArray.filter({
                let countryName = $0.localizedName ?? $0.name
                return countryName.lowercased().hasPrefix(text.lowercased())
            }))
        }
        tableView.reloadData()
    }
}

extension CountryPickerViewController: UISearchBarDelegate {
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    // MARK: - UISearchBar Delegate
    public func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        updateSearchResults(for: searchController)
    }
}

// MARK:- CountryTableViewCell.
class CountryTableViewCell: UITableViewCell {
    
    var flgSize: CGSize = .zero
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView?.frame.size = flgSize
        imageView?.center.y = contentView.center.y
    }
}


// MARK:- An internal implementation of the CountryPickerViewDataSource.
// Returns default options where necessary if the data source is not set.
class CountryPickerViewDataSourceInternal: CountryPickerViewDataSource {
    
    private unowned var view: CountryPickerView
    
    init(view: CountryPickerView) {
        self.view = view
    }
    
    var preferredCountries: [Country] {
        return view.dataSource?.preferredCountries(in: view) ?? preferredCountries(in: view)
    }
    
    var preferredCountriesSectionTitle: String? {
        return view.dataSource?.sectionTitleForPreferredCountries(in: view)
    }
    
    var showOnlyPreferredSection: Bool {
        return view.dataSource?.showOnlyPreferredSection(in: view) ?? showOnlyPreferredSection(in: view)
    }
    
    var sectionTitleLabelFont: UIFont {
        return view.dataSource?.sectionTitleLabelFont(in: view) ?? sectionTitleLabelFont(in: view)
    }

    var sectionTitleLabelColor: UIColor? {
        return view.dataSource?.sectionTitleLabelColor(in: view)
    }
    
    var cellLabelFont: UIFont {
        return view.dataSource?.cellLabelFont(in: view) ?? cellLabelFont(in: view)
    }
    
    var cellLabelColor: UIColor? {
        return view.dataSource?.cellLabelColor(in: view)
    }
    
    var cellImageViewSize: CGSize {
        return view.dataSource?.cellImageViewSize(in: view) ?? cellImageViewSize(in: view)
    }
    
    var cellImageViewCornerRadius: CGFloat {
        return view.dataSource?.cellImageViewCornerRadius(in: view) ?? cellImageViewCornerRadius(in: view)
    }
    
    var navigationTitle: String? {
        return view.dataSource?.navigationTitle(in: view)
    }
    
    var closeButtonNavigationItem: UIBarButtonItem {
        guard let button = view.dataSource?.closeButtonNavigationItem(in: view) else {
            return UIBarButtonItem(title: "Close", style: .done, target: nil, action: nil)
        }
        return button
    }
    
    var searchBarPosition: SearchBarPosition {
        return view.dataSource?.searchBarPosition(in: view) ?? searchBarPosition(in: view)
    }
    
    var showPhoneCodeInList: Bool {
        return view.dataSource?.showPhoneCodeInList(in: view) ?? showPhoneCodeInList(in: view)
    }
    
}
