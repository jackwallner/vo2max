import SwiftUI

struct AgeWheelPicker: View {
    @Binding var age: Int
    let range: ClosedRange<Int>
    /// Explicit row text color. Onboarding renders the wheel on a fixed navy
    /// card, so it passes white; Settings keeps the adaptive default.
    let textColor: Color?

    init(age: Binding<Int>, range: ClosedRange<Int> = 18...90, textColor: Color? = nil) {
        _age = age
        self.range = range
        self.textColor = textColor
    }

    var body: some View {
        Picker("Age", selection: $age) {
            ForEach(range, id: \.self) { value in
                Text("\(value)")
                    .foregroundColor(textColor)
                    .tag(value)
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
