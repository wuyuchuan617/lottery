import { ThirdwebProvider } from "@thirdweb-dev/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { ThemeProvider } from "@/components/theme-provider";
import { createThirdwebClient, getContract } from "thirdweb";
import { defineChain } from "thirdweb/chains";
import { Sepolia } from "@thirdweb-dev/chains";

import "../styles/globals.css";
import Layout from "../components/layout";

// This is the chain your dApp will work on.
// Change this to the chain your app is built for.
// You can also import additional chains from `@thirdweb-dev/chains` and pass them directly.
const activeChain = "sepolia";

// Create a client
const queryClient = new QueryClient();

// create the client with your clientId, or secretKey if in a server environment
export const client = createThirdwebClient({
  clientId: "1f5fdeb6015d0d4995ab738e5b1461a4",
});

// connect to your contract
export const contract = getContract({
  client,
  chain: defineChain(11155111),
  address: "0x43232320cbf64edD36278D515F01f2E96e167804",
});

function MyApp({ Component, pageProps }) {
  return (
    <ThirdwebProvider
      activeChain={Sepolia}
      clientId="1f5fdeb6015d0d4995ab738e5b1461a4"
    >
      <QueryClientProvider client={queryClient}>
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          <Layout>
            <Component {...pageProps} />
          </Layout>
        </ThemeProvider>
      </QueryClientProvider>
    </ThirdwebProvider>
  );
}

export default MyApp;
