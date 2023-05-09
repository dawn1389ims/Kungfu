//
//  ContentView.swift
//  Kungfu
//
//  Created by zhiqiang zhu on 2023/5/8.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        VStack(spacing: 30) {
            
            Button {
                let aVc = SourcePickerViewController.init()
                let topController = UIApplication.shared.windows.first?.rootViewController
                topController?.present(aVc, animated: true, completion: nil)
            } label: {
                Text("Go")
            }

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
