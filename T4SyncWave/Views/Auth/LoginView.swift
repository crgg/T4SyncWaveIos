import SwiftUI



struct LoginView: View {
    @EnvironmentObject var appState: AppStateManager
    
    @StateObject private var vm = AuthViewModel()
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                
                
                Spacer()
                
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                
                
                Text("Welcome Back")
                    .font(.largeTitle.bold())
                
                
                VStack(spacing: 16) {
                    TextField("Email", text: $vm.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(.roundedBorder)
                    
                    
                    SecureField("Password", text: $vm.password)
                        .textFieldStyle(.roundedBorder)
                }
                
                
                if let error = vm.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                
                Button {
                    Task { await vm.login(appState: appState) }
                } label: {
                    if vm.isLoading {
                        ProgressView()
                    } else {
                        Text("Login")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                
                
                Spacer()
                Text(KeychainManager.getAuthToken() ?? "no token")
                
                NavigationLink("Create Account", destination: RegisterView())
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
            .padding()
        }
    }
}
#Preview {
    LoginView()
    
}
#Preview {
    LoginView().blendMode(.darken)
    
}
