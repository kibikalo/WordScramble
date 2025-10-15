import SwiftUI

struct ContentView: View {
    
    @State private var usedWords = [String]()
    @State private var rootWord = ""
    @State private var newWord = ""
    
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    
    @State private var score = 0
    @State private var streak = 0
    
    @State private var isAnimating = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Form new words from the root", text: $newWord)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                .onSubmit(addNewWord)
                
                
                Section {
                    ForEach(usedWords, id: \.self) { word in
                        HStack {
                            Image(systemName: "\(word.count).circle")
                            Text(word)
                        }
                        .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity),
                                                removal: .opacity))
                    }
                }
            }
            .safeAreaPadding(.top, 20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack (spacing: 10){
                        Spacer()
                        Spacer()
                        VStack(alignment: .leading, spacing: 10) {
                            Text(rootWord).font(.largeTitle)
                            HStack {
                                Text("Words: \(usedWords.count) ")
                                    .font(.callout).foregroundStyle(.secondary)
                                    .animation(.easeInOut(duration: 0.5), value: usedWords.count)
                                Text("Score: \(score)")
                                    .font(.callout).foregroundStyle(.secondary)
                                    .animation(.easeInOut(duration: 0.5), value: score)
                                Text("Streak: \(streak)")
                                    .font(.callout).foregroundStyle(.secondary)
                                    .animation(.easeInOut(duration: 0.5), value: streak)
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    ZStack {
                        Circle ()
                            .fill(AngularGradient(colors: [.teal, .indigo, .blue], center: .center, angle: .degrees(isAnimating ? 360 : 0)))
                            .blur(radius: 10)
                            .frame(width: 50, height: 50)
                            .onAppear {
                                withAnimation(Animation.linear(duration: 5).repeatForever(autoreverses: false)) {
                                    isAnimating = true
                                }
                            }
                        Button(action: {
                            startGame()
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .onAppear(perform: startGame)
            .alert(errorTitle, isPresented: $showingError) { } message: {
                Text(errorMessage)
            }
        }
        
    }
    
    func startGame() {
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL, encoding: String.Encoding.utf8) {
                let allWords = startWords.components(separatedBy: "\n")
                
                rootWord = allWords.randomElement() ?? "silkworm"
                
                return
            }
        }
        
        fatalError("Could not load start.txt from bundle.")
    }
    
    func addNewWord() {
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard answer.count > 0 else { return }
        
        guard isTooShort(word: answer) else {
            wordError(title: "Word is too short", message: "Write something longer than 2 letters")
            return
        }
        
        guard isNotSameAsRoot(word: answer) else {
            wordError(title: "Word is the same as the root", message: "Be smarter than that!")
            return
        }
        
        
        guard isOriginal(word: answer) else {
            streak = 0
            wordError(title: "Word used already", message: "Be more original")
            return
        }
        
        guard isPossible(word: answer) else {
            streak = 0
            wordError(title: "Word not possible", message: "You can't spell that word from '\(rootWord)'!")
            return
        }
        
        guard isReal(word: answer) else {
            streak = 0
            wordError(title: "Word not recognized", message: "You can't just make them up, you know!")
            return
        }
        
        streak += 1
        score += calculateScore(answer)
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            usedWords.insert(answer, at: 0)
        }
        
        newWord = ""
    }
    
    func calculateScore(_ word: String) -> Int {
        return 10 * word.count * streak
    }
    
    
    // Validation Func
    func isTooShort(word: String) -> Bool {
        word.count > 2
    }
    
    func isNotSameAsRoot(word: String) -> Bool {
        word.lowercased() != rootWord.lowercased()
    }
    
    func isOriginal(word: String) -> Bool {
        !usedWords.contains(word)
    }
    
    
    func isPossible(word: String) -> Bool {
        var tempWord = rootWord
        
        for letter in word {
            if let pos = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: pos)
            } else {
                return false
            }
        }
        
        return true
    }
    
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        return misspelledRange.location == NSNotFound
    }
    
    // Error handling
    func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showingError = true
    }
}
    
#Preview {
    ContentView()
}
	
