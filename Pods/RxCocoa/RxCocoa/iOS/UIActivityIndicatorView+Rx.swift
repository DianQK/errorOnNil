//
//  UIActivityIndicatorView+Rx.swift
//  RxCocoa
//
//  Created by Ivan Persidskiy on 02/12/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
import RxSwift

extension Reactive where Base: UIActivityIndicatorView {

    /// Bindable sink for `startAnimating()`, `stopAnimating()` methods.
    public var isAnimating: Binder<Bool> {
        return Binder(self.base) { refreshControlActivityIndicator, active in
            if active {
                refreshControlActivityIndicator.startAnimating()
            } else {
                refreshControlActivityIndicator.stopAnimating()
            }
        }
    }

}

#endif
