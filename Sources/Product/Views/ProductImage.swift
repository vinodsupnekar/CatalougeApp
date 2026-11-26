import SwiftUI

struct ProductImage: View {
    let url: String
    var size: CGFloat = 140

    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFit()
            case .failure:
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            default:
                ProgressView()
            }
        }
        .frame(width: size, height: size)
        .padding(8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
