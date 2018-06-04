//
//  ViewController.swift
//  errorOnNil
//
//  Created by DianQK on 2018/6/4.
//  Copyright © 2018 DianQK. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxOptional
import Flix

enum NetworkError: Error, LocalizedError {
    case failed

    var errorDescription: String? {
        return "加载失败，点击重试"
    }
}

extension RxOptionalError: LocalizedError {

    public var errorDescription: String? {
        return "暂无数据，点击重试"
    }

}

class Provider: TableViewProvider {

    func configureCell(_ tableView: UITableView, cell: UITableViewCell, indexPath: IndexPath, value: Int) {
        cell.textLabel?.text = value.description
    }

    func createValues() -> Observable<[Int]> {
        return self.values.asObservable()
    }

    func refresh() -> Observable<[Int]> {
        return Observable<Int>.deferred { Observable.just(Int(arc4random_uniform(30))) }
            .map { (result) -> [Int] in
                if result < 10 {
                    return []
                } else if result < 20 {
                    throw NetworkError.failed
                } else {
                    return Array(0...result)
                }
            }
            .delaySubscription(1, scheduler: MainScheduler.instance)
            .do(onNext: { [weak self] (value) in
                self?.values.accept(value)
            })
    }

    let values = BehaviorRelay<[Int]>(value: [])

    typealias Cell = UITableViewCell
    typealias Value = Int

}

class ViewController: UIViewController {

    let refreshControl = UIRefreshControl()
    let refreshControlActivityIndicator = ActivityIndicator()

    let refreshActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    let refreshActivityIndicator = ActivityIndicator()

    let provider = Provider()

    let disposeBag = DisposeBag()

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.refreshControl = refreshControl
            tableView.sectionHeaderHeight = CGFloat.leastNonzeroMagnitude
            tableView.sectionFooterHeight = CGFloat.leastNonzeroMagnitude
        }
    }

    let errorButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshActivityIndicatorView.color = UIColor.black
        refreshActivityIndicatorView.hidesWhenStopped = true
        view.addSubview(refreshActivityIndicatorView)
        refreshActivityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        refreshActivityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        refreshActivityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        refreshActivityIndicator.asObservable()
            .bind(to: refreshActivityIndicatorView.rx.isAnimating)
            .disposed(by: disposeBag)

        errorButton.setTitleColor(UIColor.black, for: .normal)

        refreshControlActivityIndicator.asObservable()
            .bind(to: refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)

        Observable.merge([
            refreshControlActivityIndicator.asObservable().filter { $0 },
            refreshActivityIndicator.asObservable().filter { $0 }
            ])
            .subscribe(onNext: { [unowned self] (_) in
                self.tableView.backgroundView = nil
            })
            .disposed(by: disposeBag)

        Observable.merge([
            errorButton.rx.tap.asObservable().map { false },
            refreshControl.rx.controlEvent(.valueChanged).asObservable().map { true }
            ])
            .startWith(false)
            .flatMapLatest { [unowned self] isPullRefresh in
                return self.provider.refresh()
                    .trackActivity(isPullRefresh ? self.refreshControlActivityIndicator : self.refreshActivityIndicator)
                    .errorOnEmpty()
                    .catchError { (error) -> Observable<[Int]> in
                        self.tableView.backgroundView = self.errorButton
                        self.errorButton.setTitle(error.localizedDescription, for: .normal)
                        return Observable.empty()
                    }
            }
            .subscribe()
            .disposed(by: disposeBag)

        tableView.flix.build([provider])
    }

}

