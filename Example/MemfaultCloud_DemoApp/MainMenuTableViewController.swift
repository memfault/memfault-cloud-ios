///
/// Copyright (c) Memfault, Inc.
/// See LICENSE for details
///

import Foundation
import UIKit
import MemfaultCloud

class MainMenuTableViewController: UITableViewController {
    // Test Patterns for Chunks Endpoint from http://mflt.io/chunks-api-integration
    // See documentation in the header of the postChunks API for more information.
    let chunk1 = Data([
        0x40, 0x54, 0x31, 0xe4, 0x02, 0xa7, 0x02, 0x01, 0x03, 0x01, 0x07, 0x6a, 0x54, 0x45, 0x53, 0x54,
        0x53, 0x45, 0x52, 0x49, 0x41, 0x4c, 0x0a, 0x6d, 0x74, 0x65, 0x73, 0x74, 0x2d, 0x73, 0x6f, 0x66,
        0x74, 0x77, 0x61, 0x72, 0x65, 0x09, 0x6a, 0x31, 0x2e, 0x30, 0x2e, 0x30, 0x2d, 0x74, 0x65, 0x73,
    ])
    let chunk2 = Data([
        0x80, 0x2c, 0x74, 0x06, 0x6d, 0x74, 0x65, 0x73, 0x74, 0x2d, 0x68, 0x61, 0x72, 0x64, 0x77, 0x61,
        0x72, 0x65, 0x04, 0xa1, 0x01, 0xa1, 0x72, 0x63, 0x68, 0x75, 0x6e, 0x6b, 0x5f, 0x74, 0x65, 0x73,
        0x74, 0x5f, 0x73, 0x75, 0x63, 0x63, 0x65, 0x73, 0x73, 0x01,
    ])

    func alert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    func getDeviceInfo() -> MemfaultDeviceInfo {
        return MemfaultDeviceInfo(deviceSerial: "DEMO_SERIAL", hardwareVersion:"proto", softwareVersion:"1.0.0", softwareType:"main")
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            MemfaultApi.shared.getLatestRelease(for: self.getDeviceInfo()) { (package, isUpToDate, error) in
                if error != nil {
                    // If you get a "No records found ..." error message,
                    // make sure to create and deploy a Release first via https://app.memfault.com/
                    self.alert(title: "Error", message: error!.localizedDescription)
                } else {
                    self.alert(title: "Latest", message: package != nil ? "Update available: \(package!.description)" : "Up to date!")
                }
            }
        case 1:
            // postChunks – basic use
            MemfaultApi.shared.chunkSender(withDeviceSerial: "DEMO_SERIAL").postChunks([chunk1, chunk2])
        case 2:
            // postChunks – opportunistic batching
            for serial in ["DEMO_SERIAL_A", "DEMO_SERIAL_B"] {
                let chunkSender = MemfaultApi.shared.chunkSender(withDeviceSerial: serial)

                // Chunks will be enqueued and uploaded in batches to reduce the number of webservice requests,
                // so 3 calls to postChunks() will likely incur less than 3 webservice requests.
                chunkSender.postChunks([chunk1])
                chunkSender.postChunks([chunk2, chunk1])
                chunkSender.postChunks([chunk2, chunk1, chunk2])
            }
        default:
            assert(false)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
