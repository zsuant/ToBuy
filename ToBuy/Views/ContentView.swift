import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Item.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.order, ascending: true)]
    ) private var items: FetchedResults<Item>
    
    @State private var newItem: String = ""

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    ZStack(alignment: .trailing) {
                        CustomTextField(text: $newItem, placeholder: "항목 추가", onCommit: {
                            checkDuplicateAndAddItem()
                            dismissKeyboard()
                        })
                        .frame(height: 40)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)

                        Button(action: {
                            newItem = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(newItem.isEmpty ? .clear : .gray)
                                .padding(.trailing, 24)
                        }
                    }

                    Button(action: {
                        checkDuplicateAndAddItem()
                        dismissKeyboard()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(newItem.isEmpty ? .gray : .blue)
                            .disabled(newItem.isEmpty)
                    }
                    .padding(.trailing)
                }
                .padding(.top)

                List {
                    ForEach(items) { item in
                        ItemRow(item: item)
                    }
                    .onDelete(perform: deleteItems)
                    .onMove(perform: moveItems)
                }
                .listStyle(InsetGroupedListStyle())
                .dismissKeyboardOnTap()
            }
            .navigationBarTitle("살 것")
        }
    }

    private func checkDuplicateAndAddItem() {
        let trimmedNewItem = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
        if items.contains(where: { $0.text == trimmedNewItem }) {
            // Handle duplicate item case
            showAlert()
        } else {
            addItem(for: trimmedNewItem)
            newItem = ""
        }
    }

    private func addItem(for itemText: String) {
        guard !itemText.isEmpty else { return }

        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.text = itemText
            newItem.timestamp = Date()
            newItem.order = (items.last?.order ?? 0) + 1
            newItem.isFavorite = false // Default to not favorite

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        var revisedItems = items.map { $0 }
        let movingItem = revisedItems.remove(at: source.first!)
        revisedItems.insert(movingItem, at: destination > source.first! ? destination - 1 : destination)

        for reverseIndex in stride(from: revisedItems.count - 1, through: 0, by: -1) {
            revisedItems[reverseIndex].order = Int64(reverseIndex)
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func showAlert() {
        // Handle alert logic for duplicate item
        // You can implement this if needed
    }
}

struct ItemRow: View {
    @ObservedObject var item: Item
    
    var body: some View {
        HStack {
            Text(item.text ?? "Untitled")
                .padding(.vertical, 8)
                .background(Color(UIColor.systemGray5).opacity(0.2))
                .cornerRadius(8)
                .padding(.vertical, 4)
            
            Spacer()
            
            Button(action: {
                toggleFavorite()
            }) {
                Image(systemName: isFavorite() ? "star.fill" : "star")
                    .foregroundColor(isFavorite() ? .yellow : .gray)
                    .padding(.trailing, 8)
            }
            .buttonStyle(PlainButtonStyle()) // 스타일 추가
        }
    }
    
    private func isFavorite() -> Bool {
        return item.isFavorite
    }
    
    private func toggleFavorite() {
        item.isFavorite.toggle()
        do {
            try item.managedObjectContext?.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct CustomTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onCommit: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.delegate = context.coordinator
        textField.returnKeyType = .done
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomTextField

        init(_ parent: CustomTextField) {
            self.parent = parent
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            parent.onCommit()
            return true
        }
    }
}

struct DismissKeyboardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        self.modifier(DismissKeyboardModifier())
    }
}
