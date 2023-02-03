//
//  CourseCheckoutViewController.swift
//  payments with stripe
//
//  Created by Shivam Maggu on 30/01/23.
//

import UIKit
@_spi(STP) import Stripe

typealias VoidClosure = (() -> Void)

class CourseCheckoutViewController: UIViewController {
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Cart".uppercased()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .black
        label.numberOfLines = 1
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var courseImage: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.image = UIImage(named: "books")
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var courseLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Beginners guide to 2D animation"
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .black
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var amountLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "$1400.00"
        label.textAlignment = .right
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .black
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var totalLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Total"
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 20)
        label.textColor = .black
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var payButton: UIButton = {
        let button = UIButton(type: .custom)
        button.isEnabled = true
        button.setTitle("Address", for: .normal)
        button.backgroundColor = .blue
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        button.addTarget(self, action: #selector(pay), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(frame: .zero)
        view.color = .black
        view.hidesWhenStopped = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let viewModel: CourseCheckoutViewModel
    
    private var paymentSheet: PaymentSheet?
    private var address: AddressViewController.AddressDetails?
    
    var presentAddressVC: VoidClosure?
    
    init(viewModel: CourseCheckoutViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.setupView()
    }
    
    private func setupView() {
        self.view.backgroundColor = .white
        
        self.view.addSubview(titleLabel)
        self.view.addSubview(courseImage)
        self.view.addSubview(courseLabel)
        self.view.addSubview(totalLabel)
        self.view.addSubview(amountLabel)
        self.view.addSubview(payButton)
        self.view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            self.titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            self.titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            self.courseImage.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 36),
            self.courseImage.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            self.courseImage.widthAnchor.constraint(equalToConstant: 100),
            self.courseImage.heightAnchor.constraint(equalToConstant: 100),
            
            self.courseLabel.topAnchor.constraint(equalTo: courseImage.topAnchor),
            self.courseLabel.bottomAnchor.constraint(equalTo: courseImage.bottomAnchor),
            self.courseLabel.leadingAnchor.constraint(equalTo: courseImage.trailingAnchor, constant: 24),
            self.courseLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            self.totalLabel.topAnchor.constraint(equalTo: courseImage.bottomAnchor, constant: 56),
            self.totalLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            self.totalLabel.trailingAnchor.constraint(equalTo: amountLabel.leadingAnchor, constant: 16),
            
            self.amountLabel.topAnchor.constraint(equalTo: totalLabel.topAnchor),
            self.amountLabel.leadingAnchor.constraint(equalTo: totalLabel.trailingAnchor),
            self.amountLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            self.payButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            self.payButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            self.payButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            self.loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            self.loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func createPaymentSheet() {
        var configuration = PaymentSheet.Configuration()
        
        configuration.shippingDetails = { [weak self] in
            return self?.address
        }
        
        configuration.applePay = .init(merchantId: "com.example.appname",
                                       merchantCountryCode: "US")
        
        configuration.savePaymentMethodOptInBehavior = .requiresOptIn
        configuration.returnURL = "payments-with-stripe://stripe-redirect"
        configuration.primaryButtonColor = .blue
        configuration.merchantDisplayName = "Dummy Corp Inc"
        configuration.allowsDelayedPaymentMethods = true
        
        if let customer = self.viewModel.getCustomer() {
            configuration.customer = customer
        }
        
        if let paymentIntentClientSecret = self.viewModel.getPaymentIntentClientSecret() {
            self.paymentSheet = PaymentSheet(paymentIntentClientSecret: paymentIntentClientSecret,
                                            configuration: configuration)
        }
    }
    
    private func presentPaymentSheet() {
        guard let paymentSheet = paymentSheet else { return }
        
        DispatchQueue.main.async {
            paymentSheet.present(from: self) { [weak self] (paymentResult) in
                
                guard let self = self else { return }
                
                switch paymentResult {
                case .completed:
                    self.displayAlert(title: "Payment complete!")
                case .canceled:
                    self.displayAlert(title: "Payment canceled!")
                case .failed(let error):
                    self.displayAlert(title: "Payment failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func togglePayButton(status: Bool) {
        DispatchQueue.main.async {
            self.payButton.isEnabled = status
            self.payButton.backgroundColor = status ? .blue : .gray
        }
    }
    
    @objc private func pay() {
        
        guard self.address != nil else {
            self.presentAddressVC?()
            return
        }
        
        self.loadingIndicator.startAnimating()
        self.togglePayButton(status: false)

        self.viewModel.fetchPaymentIntent { [weak self] (status, error) in

            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
            }

            guard error == nil else {
                self.displayAlert(title: "Error", message: error)
                self.togglePayButton(status: true)
                return
            }

            guard status == true else {
                self.displayAlert(title: "Error", message: error)
                self.togglePayButton(status: true)
                return
            }

            self.createPaymentSheet()
            self.presentPaymentSheet()
            self.togglePayButton(status: true)
        }
    }
}

extension CourseCheckoutViewController {
    
    private func displayAlert(title: String, message: String? = nil) {
        DispatchQueue.main.async {
            let alertController = Helper.displayAlert(title: title, message: message)
            self.present(alertController, animated: true)
        }
    }
}

extension CourseCheckoutViewController: AddressViewControllerDelegate {
    
    func addressViewControllerDidFinish(_ addressViewController: Stripe.AddressViewController, with address: Stripe.AddressViewController.AddressDetails?) {
        addressViewController.dismiss(animated: true) {
            debugPrint(address as Any)
            
            guard address != nil else { return }
            
            self.address = address
            self.payButton.setTitle("Pay now", for: .normal)
        }
    }
}
