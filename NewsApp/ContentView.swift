//
//  ContentView.swift
//  NewsApp
//
//  Created by SAGAR THUKRAL on 25/05/21.
//

import SwiftUI
import SwiftyJSON
import SDWebImageSwiftUI
import WebKit

struct ContentView: View {
    @ObservedObject var list = getData()
    @ObservedObject var monitor = NetworkMonitor()
    init() {
        //Use this if NavigationBarTitle is with Large Font
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.red]

        //Use this if NavigationBarTitle is with displayMode = .inline
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.red]
    }
    var body: some View {

        NavigationView {
            
            List {
                
                Section() {
                    VStack {
                        Divider().background(Color.black)
                        Marque(text:list.datas.map({$0.desc + ": " + $0.source}).joined(separator: "  ||  ")).padding(.bottom, 10)
                        
                        Divider().background(Color.black)

                    }
                }
                Section() {
                    ForEach(list.datas) { i in
                        
                        NavigationLink(
                            destination: webView(url: i.url)
                                .navigationBarTitle("", displayMode: .inline)) {
                            HStack(spacing:15){
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(i.title).fontWeight(.heavy)
                                    Text(i.desc).lineLimit(2)
                                }
                                if !i.image.isEmpty {
                                    WebImage(url: URL(string: i.image), options: .highPriority, context: nil).resizable().frame(width: 100, height: 120).cornerRadius(15)
                                }
                                
                            }.padding(.vertical, 15)
                        }
                        
                    }
                }
                
            }.navigationBarTitle("Live News")
            
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct dataType : Identifiable {
    var id : String
    var title : String
    var desc: String
    var url : String
    var image : String
    var source : String
}

class getData : ObservableObject {
    
    @Published var datas = [dataType]()
    
    init() {
//        let source = "https://newsapi.org/v2/top-headlines?country=in&apiKey=107eb5a09ea54056811251591e605896"
        let source = "http://api.mediastack.com/v1/news?access_key=8d874469f1dd8b80559af4923e3cf14f&countries=us"
        let url = URL(string: source)!
        let session = URLSession(configuration: .default)
        session.dataTask(with: url) { (data, _ , error) in
            if  error != nil {
                print((error?.localizedDescription)!)
                return
            }
            let json = try! JSON(data: data!)
            let dataArr = json["data"]
            for i in dataArr {
                let title = i.1["title"].stringValue
                let des = i.1["description"].stringValue
                let url = i.1["url"].stringValue
                let urlToImage = i.1["image"].stringValue
                let id = i.1["published_at"].stringValue
                let source = i.1["source"].stringValue
//                let category = i.1["category"].stringValue
                DispatchQueue.main.async {
                    self.datas.append(dataType(id: id, title: title, desc: des, url: url, image: urlToImage,source: source))
                }

            }
        }.resume()
    }
}

struct webView : UIViewRepresentable {
    var url : String
    func makeUIView(context: UIViewRepresentableContext<webView>) -> WKWebView {
        let view = WKWebView()
        view.load(URLRequest(url: URL(string: url)!))
        return view
    }
    func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<webView>) {
        
    }
}

// view animation
struct Marque: View {
    let text: String
    @State private var moveView = false
    @State private var stopAnimation = false
    @State private var textFrame: CGRect = CGRect()
    public init(text: String) {
        self.text = text
    }
    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal, showsIndicators: false, content: {
                Text(text)
                    .lineLimit(1).foregroundColor(.red)
                    .background(GeometryGetter(rect: $textFrame)).offset(moveView ? CGSize(width: -1 * textFrame.width, height: 0) : CGSize(width: proxy.size.width, height: 0))
                .onAppear() {
                    self.stopAnimation = false
                    animateView()
                    moveViewOnAnimationEnd()///scrollViewProxy.scrollTo("Identifier") /// does not animate
                }.onDisappear() {
                    self.stopAnimation = true
                }
            })
            .padding([.top, .bottom], 5)
        }
    }
    private func animateView() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1, execute: { //after 0.5 sec
            withAnimation(Animation.linear(duration: Double(textFrame.width) * 0.01)) {
                moveView = true
            }
        })
    }
    private func moveViewOnAnimationEnd() {
        let timeToAnimate = (Double(textFrame.width) * 0.01) + 0.2
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeToAnimate, execute: { //after 0.5 sec
            moveView = false
            if stopAnimation == false {
                animateView()
                moveViewOnAnimationEnd()
            }
        })
    }
}
struct GeometryGetter: View {
    @Binding var rect: CGRect

    var body: some View {
        GeometryReader { (proxy) -> Path in
            DispatchQueue.main.async {
                self.rect = proxy.frame(in: .global)
            }
            return Path()
        }
    }
}

