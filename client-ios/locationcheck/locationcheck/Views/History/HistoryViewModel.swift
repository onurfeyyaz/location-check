import Foundation

final class HistoryViewModel: ObservableObject {
    @Published var deviceDetails: [LocationData] = []
    @Published var isLoading: Bool = false
    private var isDataLoaded: Bool = false
    
    private let localRepository: LocalDBRepository
    private let socketRepository: SocketRepository
    
    init(localRepository: LocalDBRepository = LocalDBRepository(), socketRepository: SocketRepository = SocketRepository()) {
        self.localRepository = localRepository
        self.socketRepository = socketRepository
    }
    
    func loadInitialData() async {
        guard !isDataLoaded else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
        }
        
        let fetchedData = await socketRepository.getAllDevicesDetails()
    
        let sortedData = fetchedData.sorted { $0.timestamp > $1.timestamp }
        
        DispatchQueue.main.async { [weak self] in
            self?.deviceDetails = sortedData
            self?.isLoading = false
        }
        
        isDataLoaded = true
    }
    
    func reloadData() async {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
        }
        let fetchedData = await socketRepository.getAllDevicesDetails()
        
        let sortedData = fetchedData.sorted { $0.timestamp > $1.timestamp }
        
        DispatchQueue.main.async { [weak self] in
            self?.deviceDetails = sortedData
            self?.isLoading = false
        }
    }
}
