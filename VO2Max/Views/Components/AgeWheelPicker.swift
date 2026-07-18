import SwiftUI

struct AgeWheelPicker: View {
    @Binding var age: Int
    let range: ClosedRange<Int>

    init(age: Binding<Int>, range: ClosedRange<Int> = 18...90) {
        _age = age
        self.range = range
    }

    var body: some View {
        Picker("Age", selection: $age) {
            ForEach(range, id: \.self) { value in
                Text("\(value)").tag(value)
            }
        }
        #if os(iOS) || os(watchOS)
        .pickerStyle(.wheel)
        #else
        .pickerStyle(.menu)
        #endif
        .frame(height: 132)
        .clipped()
        .accessibilityLabel("Age")
        .accessibilityValue("\(age) years")
    }
}
