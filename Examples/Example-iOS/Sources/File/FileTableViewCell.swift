//
//  FileTableViewCell.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

class FileCell: UITableViewCell {
  @IBOutlet var fileId: UILabel?
  @IBOutlet var fileName: UILabel?
  @IBOutlet var fileSize: UILabel?
  @IBOutlet var fileStatus: UIImageView?
}
