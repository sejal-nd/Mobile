//
//  NewNetworkUtility.swift
//  Mobile
//
//  Created by Joseph Erlandson on 10/16/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation

// fetch account lists


// we can simplify this code by using semaphores, then we do not need to nest calls

// 1.  Fetch maintenance mode

// 2. fetch account details

// 3. fetch usage data

// 4.  fetch outage


// Notes:

// toggle for showing or not showing loading indicator

// All Screens must get the updates on completion: Notification center?

// polling reload every 15 mins

// pass from app delegate as opposed to singleton

// two public methods: Load Data & loadAccountList

// Unsure where in the app we will load data as this does not return a callback, rather it triggers notification center items
