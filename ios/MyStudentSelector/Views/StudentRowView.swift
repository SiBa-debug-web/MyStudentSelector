import SwiftUI

struct StudentRowView: View {
    let student: Student

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(borderColor, lineWidth: 2)
                    .background(Circle().fill(student.calledThisRound ? AnyShapeStyle(LinearGradient.brand) : AnyShapeStyle(Color.clear)))
                    .frame(width: 24, height: 24)
                if student.calledThisRound {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(student.name)
                    .font(.body.weight(.semibold))
                Text(student.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(student.isAbsent ? 0.5 : 1)
    }

    private var borderColor: Color {
        student.calledThisRound ? .clear : Color.secondary.opacity(0.35)
    }
}

#Preview {
    List {
        StudentRowView(student: Student(name: "Jordan Lee", timesCalled: 2, calledThisRound: true))
        StudentRowView(student: Student(name: "Alex Kim"))
        StudentRowView(student: Student(name: "Sam Patel", isAbsent: true))
    }
}
