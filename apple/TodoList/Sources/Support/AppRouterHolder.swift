import Foundation

@MainActor
final class AppRouterHolder {
    static let shared = AppRouterHolder()
    weak var router: AppRouter?
}
