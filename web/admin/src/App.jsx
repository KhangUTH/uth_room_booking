import { BrowserRouter } from "react-router-dom";
import AppRouters from "./routers/AppRouters.jsx";
import AuthProvider from "./contexts/AuthProvider.jsx";

function App() {
    return (
      <>
        <BrowserRouter>
          <AuthProvider>
            <AppRouters />
          </AuthProvider>
        </BrowserRouter>
      </>
    )
}

export default App;
