//
//  File.swift
//  
//
//  Created by Michael Redig on 2/29/20.
//

import Foundation
import MUDCrawlerCore

let crawler = MUDCrawler()


//CoinMiner.benchMark()

if CommandLine.arguments.contains("snitchmine") {
	crawler.startSnitchMine()
} else {
	crawler.start()
}
