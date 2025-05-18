// This file intentionally left blank after removing duplicate view definitions. 

import SwiftUI

struct RoutineCard: View {
    let routine: Routine
    
    var body: some View {
        VStack(alignment: .leading) {
                Text(routine.name)
                    .font(.headline)
            Text(routine.description)
                .font(.subheadline)
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct UnlockRequirementView: View {
    let requirement: String
    
    var body: some View {
        Text(requirement)
                            .font(.caption)
                            .foregroundColor(.gray)
    }
} 