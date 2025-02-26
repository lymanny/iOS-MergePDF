//
//  MergePDFVC.swift
//  MergePDF
//
//  Created by lymanny on 25/2/25.
//

import UIKit
import PDFKit
import UniformTypeIdentifiers

class MergePDFVC: UIViewController {
    
    //MARK: - Properties & Variable
    let pdfView = PDFView()
    var mergedPDF: PDFDocument? = nil
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationItems()
    }
    
    //MARK: - Function
    func setupUI() {
        view.backgroundColor = .white
        
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.autoScales = true
        
        view.addSubview(pdfView)
        
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func setupNavigationItems() {
        // Left: A system Add button that calls selectFiles.
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                           target: self,
                                                           action: #selector(selectFiles))
        // Right: Delete and Save PDF buttons.
        let deleteButton = UIBarButtonItem(barButtonSystemItem: .trash,
                                           target: self,
                                           action: #selector(deletePDFTapped))
        
        let saveButton = UIBarButtonItem(title: "Save PDF",
                                         style: .plain,
                                         target: self,
                                         action: #selector(savePDFTapped))
        
        navigationItem.rightBarButtonItems = [deleteButton, saveButton]
    }
    
    func mergeFiles(urls: [URL]) {
        let newPDF = PDFDocument()
        var pageIndex = 0
        for url in urls {
            if let pdf = PDFDocument(url: url) {
                for i in 0..<pdf.pageCount {
                    if let page = pdf.page(at: i) {
                        newPDF.insert(page, at: pageIndex)
                        pageIndex += 1
                    }
                }
            } else {
                print("Could not load PDF at \(url)")
            }
        }
        appendPDFPages(from: newPDF)
    }
    
    func appendPDFPages(from newPDF: PDFDocument) {
        if mergedPDF == nil {
            mergedPDF = PDFDocument()
        }
        
        let currentCount = mergedPDF!.pageCount
        for i in 0..<newPDF.pageCount {
            if let page = newPDF.page(at: i) {
                mergedPDF?.insert(page, at: currentCount + i)
            }
        }
        
        pdfView.document = mergedPDF
    }
    
    //MARK: - OBJC
    @objc func deletePDFTapped() {
        let alert = UIAlertController(title: "Delete Merged PDF",
                                      message: "Are you sure you want to delete the merged PDF?",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Delete",
                                      style: .destructive,
                                      handler: { _ in
            self.mergedPDF = nil
            self.pdfView.document = nil
            self.showAlert(title: "Deleted", message: "Merged PDF has been deleted.")
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    @objc func savePDFTapped() {
        guard let document = mergedPDF else {
            showAlert(title: "No PDF", message: "Please merge some files first.")
            return
        }
        sharePDF(document: document)
    }
    
    func sharePDF(document: PDFDocument) {
        if let data = document.dataRepresentation() {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("merged.pdf")
            do {
                try data.write(to: tempURL)
                let activityVC = UIActivityViewController(activityItems: [tempURL],
                                                          applicationActivities: nil)
                present(activityVC, animated: true)
            } catch {
                showAlert(title: "Error", message: "Error writing PDF file: \(error)")
            }
        }
    }
    
}


//MARK: - UIDocumentPickerDelegate
extension MergePDFVC: UIDocumentPickerDelegate {
    @objc func selectFiles() {
        // Only allow selection of PDF files.
        let supportedTypes: [UTType] = [UTType.pdf]
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes,
                                                            asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        mergeFiles(urls: urls)
    }
    
}
